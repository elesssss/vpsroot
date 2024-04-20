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

check_root(){
    if [ "$(id -u)" != "0" ]; then
        echo -e "${Error}请执行 ${Green}sudo -i${Nc} 后以${Green}root${Nc}权限执行此脚本！"
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
    else
        echo ""
    fi

    os_version=$(grep -i version_id /etc/os-release | cut -d \" -f2 | cut -d . -f1)

    if [[ "${release}" == "arch" ]]; then
        echo ""
    elif [[ "${release}" == "parch" ]]; then
        echo ""
    elif [[ "${release}" == "manjaro" ]]; then
        echo ""
    elif [[ "${release}" == "armbian" ]]; then
        echo ""
    elif [[ "${release}" == "centos" ]]; then
        if [[ ${os_version} -lt 7 ]]; then
            echo -e "${Error} 请使用 CentOS 7 或更高版本！" && exit 1
        fi
    elif [[ "${release}" == "ubuntu" ]]; then
        if [[ ${os_version} -lt 20 ]]; then
            echo -e "${Error} 请使用 Ubuntu 20.04 或更高版本！" && exit 1
        fi
    elif [[ "${release}" == "fedora" ]]; then
        if [[ ${os_version} -lt 36 ]]; then
            echo -e "${Error} 请使用 Fedora 36 或更高版本！" && exit 1
        fi
    elif [[ "${release}" == "debian" ]]; then
        if [[ ${os_version} -lt 10 ]]; then
            echo -e "${Error} 请使用 Debian 10 或更高版本！" && exit 1
        fi
    elif [[ "${release}" == "almalinux" ]]; then
        if [[ ${os_version} -lt 9 ]]; then
            echo -e "${Error} 请使用 AlmaLinux 9 或更高版本！" && exit 1
        fi
    elif [[ "${release}" == "rocky" ]]; then
        if [[ ${os_version} -lt 9 ]]; then
            echo -e "${Error} 请使用 Rocky Linux 9 或更高版本！" && exit 1
        fi
    elif [[ "${release}" == "oracle" ]]; then
        if [[ ${os_version} -lt 8 ]]; then
            echo -e "${Error} 请使用 Oracle Linux 8 或更高版本！" && exit 1
        fi
    elif [[ "${release}" == "alpine" ]]; then
        if [[ ${os_version} -lt 3.8 ]]; then
            echo -e "${Error} 请使用 Alpine Linux 3.8 或更高版本！" && exit 1
        fi
    else
        echo -e "${Error} 抱歉，此脚本不支持您的操作系统。"
        echo "${Info} 请确保您使用的是以下支持的操作系统之一："
        echo "- Ubuntu 20.04+"
        echo "- Debian 10+"
        echo "- CentOS 7+"
        echo "- Fedora 36+"
        echo "- Arch Linux"
        echo "- Parch Linux"
        echo "- Manjaro"
        echo "- Armbian"
        echo "- AlmaLinux 9+"
        echo "- Rocky Linux 9+"
        echo "- Oracle Linux 8+"
        echo "- Alpine Linux 3.8"
        exit 1
    fi
}

install_base(){
    check_release
    if [[ "$release" == "debian" || "$release" == "ubuntu" ]]; then
        commands=("netstat")
        apps=("net-tools")
        install=()
        for i in ${!commands[@]}; do
            [ ! $(command -v ${commands[i]}) ] && install+=(${apps[i]})
        done
        [ "${#install[@]}" -gt 0 ] && apt update -y && apt install -y ${install[@]}
    elif [[ "$release" == "centos" || "$release" == "fedora" ]]; then
        commands=("netstat")
        apps=("net-tools")
        install=()
        for i in ${!commands[@]}; do
            [ ! $(command -v ${commands[i]}) ] && install+=(${apps[i]})
        done
        [ "${#install[@]}" -gt 0 ] && dnf update -y && dnf install -y ${install[@]}
    else
        echo -e "${Error} 很抱歉，你的系统不受支持！"
        exit 1
    fi
}

set_port(){
    echo -e "${Tip} 请设置ssh端口号!（默认为 22）"
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
    if [[ "$release" == "debian" || "$release" == "ubuntu" || "$release" == "centos" || "$release" == "fedora" || "$release" == "almalinux" || "$release" == "rocky" || "$release" == "oracle" || "$release" == "manjaro" || "$release" == "parch" || "$release" == "arch" ]]; then
        systemctl restart ssh* >/dev/null 2>&1
    elif [[ "$release" == "armbian" ]]; then
        service ssh* restart >/dev/null 2>&1
    elif [[ "$release" == "alpine" ]]; then
        rc-service ssh* restart >/dev/null 2>&1
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
    rm -rf /etc/ssh/sshd_config.d/* && rm -rf /etc/ssh/ssh_config.d/*

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
