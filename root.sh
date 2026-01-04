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

check_release(){
    if [[ -e /etc/os-release ]]; then
        . /etc/os-release
        release=$ID
    elif [[ -e /usr/lib/os-release ]]; then
        . /usr/lib/os-release
        release=$ID
    fi
    os_version=$(echo $VERSION_ID | cut -d. -f1,2)

    if [[ "${release}" == "ol" ]]; then
        release=oracle
    elif [[ ! "${release}" =~ ^(kali|centos|ubuntu|fedora|debian|almalinux|rocky|alpine)$ ]]; then
        echo -e "${Error} 抱歉，此脚本不支持您的操作系统。"
        echo -e "${Info} 请确保您使用的是以下支持的操作系统之一："
        echo -e "-${Red} Ubuntu ${Nc}"
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
    if [[ "$release" == "debian" || "$release" == "ubuntu" || "$release" == "kali" || "$release" == "armbian" ]]; then
        apps=("net-tools")
    elif [[ "$release" == "alpine" ]]; then
        apps=("net-tools")
    elif [[ "$release" == "almalinux" || "$release" == "rocky" || "$release" == "oracle" || "$release" == "centos" ]]; then
        apps=("net-tools")
    elif [[ "$release" == "fedora" || "$release" == "amzn" ]]; then
        apps=("net-tools")
    elif [[ "$release" == "arch" || "$release" == "manjaro" || "$release" == "parch" ]]; then
        apps=("net-tools")
    elif [[ "$release" == "opensuse-tumbleweed" ]]; then
        apps=("net-tools")
    fi

    updates=("apt -y update" "yum -y update --skip-broken" "apk update -f" "pacman -Sy" "dnf -y update" "zypper refresh")
    installs=("apt -y install" "yum -y install" "apk add -f" "pacman -S --noconfirm" "dnf -y install" "zypper install -y")
}

install_base(){
    check_pmc
    cmds=("netstat")
    echo

    for i in "${!cmds[@]}"; do
        if ! which "${cmds[i]}" &>/dev/null; then
            DEPS+=("${apps[i]}")
        fi
    done
    
    if [ ${#DEPS[@]} -gt 0 ]; then
        echo -e "${Tip} 安装依赖列表：${Green}${DEPS[*]}${Nc} 请稍后..."
        $updates
        $installs "${DEPS[@]}" 
    else
        echo -e "${Info} 所有依赖已存在，不需要额外安装。"
    fi
}

# 检查是否为root用户
check_root(){
    if [ "$(id -u)" != "0" ]; then
        echo -e "${Error} 当前非ROOT账号(或没有ROOT权限)，无法继续操作，请更换ROOT账号或使用 ${Green_globa}sudo -i${Nc} 命令获取临时ROOT权限（执行后可能会提示输入当前账号的密码）。"
        exit 1
    fi
}

set_port(){
    old_sshport=$(grep -E '^#?Port' /etc/ssh/sshd_config | awk '{print $2}' | head -1)
    echo -e "${Tip} 请设置ssh端口号!（默认为原本的${Green} ${old_sshport}${Nc} 端口）"
    read -p "设置ssh端口号：" sshport
    if [ -z "$sshport" ]; then
        sshport=$old_sshport
    elif [[ $sshport -lt 22 || $sshport -gt 65535 || $(netstat -tuln | grep -w "$sshport") && "$sshport" != "$old_sshport" ]]; then
        echo -e "${Error} 设置的端口无效或占用，默认设置为原本的${Green} ${old_sshport}${Nc} 端口"
        sshport=$old_sshport
    fi
}

set_passwd(){
    echo -e "${Tip} 请设置 root 密码！"
    read -p "设置 root 密码：" passwd

    if [ -z "$passwd" ]; then
        echo -e "${Error} 未输入密码，无法执行操作，请重新运行脚本并输入密码！"
        exit 1
    fi

    if type -p chpasswd &> /dev/null; then
        echo root:$passwd | chpasswd
    else
        (echo "$passwd"; sleep 1; echo "$passwd") | passwd &> /dev/null
    fi
}

# 重启SSH服务
restart_ssh(){
    check_release
    if [[ "$release" == "alpine" ]]; then
        rc-service ssh* restart &> /dev/null
    else
        systemctl restart ssh* &> /dev/null
    fi
}

main(){
    check_root
    install_base
    set_port
    set_passwd
    sed -i "0,/^#\?Port/s/^#\?Port.*/Port $sshport/g" /etc/ssh/sshd_config
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
