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

if [[ $(whoami) == "root" ]]; then
    echo -e "${Tip} 请设置ssh端口号!（默认为 22）"
    read -p "设置ssh端口号：" sshport
    sshport=${sshport:-22} # 如果用户没有输入，则使用默认值22

    echo -e "${Tip} 请设置root密码!"
    read -p "设置root密码：" passwd
    if [ -z "$passwd" ]; then
        echo -e "${Error}未输入密码，无法执行操作！"
        exit 1
    else
        password=$passwd
    fi
    echo root:$password | chpasswd root
    sed -i "s/^#\?Port.*/Port $sshport/g" /etc/ssh/sshd_config
    sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin yes/g' /etc/ssh/sshd_config
    sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication yes/g' /etc/ssh/sshd_config
    sed -i 's/^#\?RSAAuthentication.*/RSAAuthentication yes/g' /etc/ssh/sshd_config
    sed -i 's/^#\?PubkeyAuthentication.*/PubkeyAuthentication yes/g' /etc/ssh/sshd_config
    rm -rf /etc/ssh/sshd_config.d/* && rm -rf /etc/ssh/ssh_config.d/*

    # 重启SSH服务
    /etc/init.d/ssh* restart >/dev/null 2>&1

    # 输出结果
    echo
    echo -e "${Info} root密码设置 ${Green}成功${Nc}
================================
${Info} ssh端口 :      ${Red_globa} $sshport ${Nc}
================================
${Info} VPS用户名 :    ${Red_globa} root ${Nc}
================================
${Info} VPS root密码 : ${Red_globa} $password ${Nc}
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
else
    echo -e "${Error}请执行 ${Green}sudo -i${Nc} 后以${Green}root${Nc}权限执行此脚本！"
    exit 1
fi
