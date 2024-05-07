#!/bin/bash

Red="\033[31m" # 红色
Green="\033[32m" # 绿色
Yellow="\033[33m" # 黄色
Blue="\033[34m" # 蓝色
Nc="\033[0m" # 重置颜色
Red_globa="\033[41;37m" # 红底白字
Green_globa="\033[42;37m" # 绿底白字
Yellow_globa="\033[43;37m" # 黄底白字
Blue_globa="\033[44;37m" # 蓝底白字
Info="${Green}[信息]${Nc}"
Error="${Red}[错误]${Nc}"
Tip="${Yellow}[提示]${Nc}"

# 检查是否为root用户
check_root(){
    if [ "$(id -u)" != "0" ]; then
        echo -e "${Error} 当前非ROOT账号(或没有ROOT权限)，无法继续操作，请更换ROOT账号或使用 ${Green_globa}sudo -i${Nc} 命令获取临时ROOT权限（执行后可能会提示输入当前账号的密码）。"
        exit 1
    fi
}

check_release(){
    if [[ -e /etc/os-release ]]; then
        . /etc/os-release
        release=$ID
    elif [[ -e /usr/lib/os-release ]]; then
        . /usr/lib/os-release
        release=$ID
    fi
    os_version=$(echo $VERSION_ID | cut -d. -f1,2)

    if [[ "${release}" == "kali" ]]; then
        echo
    elif [[ "${release}" == "centos" ]]; then
        echo
    elif [[ "${release}" == "ubuntu" ]]; then
        echo
    elif [[ "${release}" == "fedora" ]]; then
        echo
    elif [[ "${release}" == "debian" ]]; then
        echo
    elif [[ "${release}" == "almalinux" ]]; then
        echo
    elif [[ "${release}" == "rocky" ]]; then
        echo
    elif [[ "${release}" == "ol" ]]; then
        release=oracle
    elif [[ "${release}" == "alpine" ]]; then
        echo
    else
        echo -e "${Error} 抱歉，此脚本不支持您的操作系统。"
        echo -e "${Info} 请确保您使用的是以下支持的操作系统之一："
        echo -e "-${Red} Ubuntu ${Nc} "
        echo -e "-${Red} Debian ${Nc}"
        echo -e "-${Red} CentOS ${Nc}"
        echo -e "-${Red} Fedora ${Nc}"
        echo -e "-${Red} Kali ${Nc}"
        echo -e "-${Red} AlmaLinux ${Nc}"
        echo -e "-${Red} Rocky Linux ${Nc}"
        echo -e "-${Red} Oracle Linux ${Nc}"
        echo -e "-${Red} Alpine Linux ${Nc}"
        exit 1
    fi
}

check_pmc(){
    check_release
    if [[ "$release" == "debian" || "$release" == "ubuntu" || "$release" == "kali" ]]; then
        updates="apt update -y"
        installs="apt install -y"
        check_install="dpkg -s"
        apps=("net-tools")
    elif [[ "$release" == "alpine" ]]; then
        updates="apk update -f"
        installs="apk add -f"
        check_install="apk info -e"
        apps=("net-tools")
    elif [[ "$release" == "almalinux" || "$release" == "rocky" || "$release" == "oracle" ]]; then
        updates="dnf update -y"
        installs="dnf install -y"
        check_install="dnf list installed"
        apps=("net-tools")
    elif [[ "$release" == "centos" ]]; then
        updates="yum update -y"
        installs="yum install -y"
        check_install="yum list installed"
        apps=("net-tools")
    elif [[ "$release" == "fedora" ]]; then
        updates="dnf update -y"
        installs="dnf install -y"
        check_install="dnf list installed"
        apps=("net-tools")
    fi
}

install_base(){
    check_pmc
    cmds=("netstat")
    echo -e "${Info} 你的系统是${Red} $release $os_version ${Nc}"
    echo

    for g in "${!apps[@]}"; do
        if ! $check_install "${apps[$g]}" &> /dev/null; then
            CMDS+=(${cmds[g]})
            DEPS+=("${apps[$g]}")
        fi
    done
    
    if [ ${#DEPS[@]} -gt 0 ]; then
        $updates &> /dev/null
        $installs "${DEPS[@]}" &> /dev/null
    fi

    if [[ "$release" == "almalinux" || "$release" == "rocky" || "$release" == "oracle" ]]; then
        ln -sf /usr/bin/python3.11 /usr/bin/python3
    fi
}

set_port(){
    echo -e "${Tip} 请设置ssh端口号!（默认为 ${Red}22${Nc}）"
    read -p "设置ssh端口号：" sshport
    if [ -z "$sshport" ]; then
        sshport=22
    elif [[ $sshport -lt 22 || $sshport -gt 65535 || $(netstat -tuln | grep -w "$sshport") && "$sshport" != "22" ]]; then
        echo -e "${Error} 设置的端口无效或被占用，默认设置为 ${Green}22${Nc} 端口"
        sshport=22
    fi
}

set_passwd(){
    echo -e "${Tip} 请设置root密码！"
    read -p "设置root密码：" passwd
    if [ -z "$passwd" ]; then
        echo -e "${Error} 未输入密码，无法执行操作，请重新运行脚本并输入密码！"
        exit 1
    fi
}

# 重启SSH服务
restart_ssh(){
    check_release
    if [[ "$release" == "alpine" ]]; then
        rc-service ssh* restart >/dev/null 2>&1
    else
        systemctl restart ssh* >/dev/null 2>&1
    fi
}

main(){
    check_root
    install_base
    set_port
    set_passwd
    echo root:$passwd | chpasswd root
    sed -i "s/^#\?Port.*/Port $sshport/g" /etc/ssh/sshd_config
    sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin yes/g' /etc/ssh/sshd_config
    sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication yes/g' /etc/ssh/sshd_config
    sed -i 's/^#\?RSAAuthentication.*/RSAAuthentication yes/g' /etc/ssh/sshd_config
    sed -i 's/^#\?PubkeyAuthentication.*/PubkeyAuthentication yes/g' /etc/ssh/sshd_config
    rm -rf /etc/ssh/sshd_config.d/* /etc/ssh/ssh_config.d/*

    restart_ssh

    # 输出结果
    echo
    echo -e "${Info} root密码设置 ${Green}成功${Nc}
================================
${Info} ssh端口 :      ${Red_globa} $sshport ${Nc}
================================
${Info} VPS用户名 :    ${Red_globa} root ${Nc}
================================
${Info} VPS root密码 : ${Red_globa} $passwd ${Nc}
================================"
    echo

    # 终止除当前终端会话之外的所有会话
    current_tty=$(tty)
    pts_list=$(who | awk '{print $2}')
    for pts in $pts_list; do
        if [ "$current_tty" != "/dev/$pts" ]; then
            pkill -9 -t $pts
        fi
    done
}

main
