#!/bin/bash
#测试系统centos7
#检查是否存在空密码账号（ok）
echo -e "\033[32m #########################开始检测#################\033[1m"
password_no=`awk -F: '( $2 == "" ) { print $1 }' /etc/shadow`
if [ ! -n "$password_no"  ];then
    echo "系统中没有空密码账号，符合要求">>out.txt
else
    cp -p /etc/passwd /etc/passwd_bak
    cp -p /etc/shadow /etc/shadow_bak
    echo "系统中有多个可登陆账号，请确认是否与业务相关"
    echo '是否为账号设置密码：(Y/N):'
    read user_num_YorN_re
    temp=`echo ${user_num_YorN_re} | grep Y`
    temp1=`echo ${user_num_YorN_re} | grep y`
    if [ "$temp" != "" -o "$temp1" != "" ];then
        for no_password_user in $password_no
        do
                passwd $no_password_user
        done
        echo '已为账号设置密码:'$no_password_user >>out.txt
    fi
fi

#删除或锁定无关账号（ok）
no_user=`more /etc/shadow | egrep "^listen:\!|^gdm:\!|^webservd:\!|^nobody:\!|^nobody4:\!|^noaccess:\!|^lp:\!|^uucp:\!" | awk -F: '{print $1}'`
more /etc/shadow | egrep "^listen:|^gdm:|^webservd:|^nobody:|^nobody4:|^noaccess:|^lp:|^uucp:" | awk -F: '{print $1}' >> temp_no_user_3.txt
if [ -n "$no_user" ];then
    for no_user_1 in $no_user
    do
        echo "系统中存在被锁定账号:"$no_user_1
        temp_no_user_3=`grep -v $no_user_1 temp_no_user_3.txt`
        sed -i '/'$(echo $no_user_1)'/s/'$(echo $no_user_1)'//g' temp_no_user_3.txt
    done
fi
if [ -n "$temp_no_user_3" ];then
    echo "存在未锁定账户:"$temp_no_user_3
    echo "存在未锁定账户:"$temp_no_user_3 >> out.txt
    echo '是否锁定无关账号：(Y/N):'
    cp -p /etc/passwd /etc/passwd_bak
    cp -p /etc/shadow /etc/shadow_bak
    read user_num_YorN_re
    temp=`echo ${user_num_YorN_re} | grep Y`
    temp1=`echo ${user_num_YorN_re} | grep y`
    if [ "$temp" != "" -o "$temp1" != "" ];then
        for no_use_user in $temp_no_user_3
        do
                usermod -L $no_use_user
                echo 'usermod -L':$no_use_user
                temp_no_use_user=`cat /etc/passwd | grep $no_use_user| awk -F: '{ print $7 }'`
                sed -i '/'$(echo $no_use_user)'/s/'$(echo $temp_no_use_user)'/\/bin\/false/g' /etc/passwd
                echo '已锁定无关账号'$no_use_user>>out.txt
        done
    fi
else
    echo "系统中不存在未锁定账号"
fi

#不重复使用最近的口令（ok）
no_repeat_password_1=`cat /etc/pam.d/system-auth |grep 'pam_unix.so' | grep 'remember=5'`
no_repeat_password_file='/etc/security/opasswd'
if [ -n "$no_repeat_password_1" -a -e "$no_repeat_password_file" ];then
    echo "不重复使用最近的口令，符合要求">>out.txt
else
    echo '不重复使用最近的口令配置不满足要求，是否自动配置：(Y/N):'
    read user_num_YorN_re
    temp=`echo ${user_num_YorN_re} | grep Y`
    temp1=`echo ${user_num_YorN_re} | grep y`
    if [ "$temp" != "" -o "$temp1" != "" ];then
        cp -p /etc/pam.d/system-auth /etc/pam.d/system-auth_bak
        touch /etc/security/opasswd
        chown root:root /etc/security/opasswd
        chmod 600 /etc/security/opasswd
        no_repeat_password_3=`cat /etc/pam.d/system-auth |grep 'password    required        pam_unix.so'`
        if [ -n "$no_repeat_password_3" ];then
            sed -i '/password    required        pam_unix.so/a\ remember=5' /etc/pam.d/system-auth
        else
            echo 'password    required        pam_unix.so remember=5' >> /etc/pam.d/system-auth
        fi
        if [ $? -eq 0 ];then
            echo '不重复使用最近的口令已完成配置'>>out.txt
        fi
    fi
fi

#按照用户角色分配不同权限的账号
echo "请自行根据需求改账户权限" >> out.txt
echo "####################################################" >>out.txt
echo `cat /etc/passwd | awk -F: '{ print $1"---"$6"---"$7 }'` >>out.txt
echo "####################################################" >> out.txt

#禁止超级管理员账户远程登录（ok）
no_remote_root_file1='/etc/pam.d/login'
no_remote_root_file2='/etc/securetty'
no_remote_root_file3='/etc/ssh/sshd_config'
no_remote_root_file4='/etc/X11/gdm/gdm.conf'

if [  -e "$no_remote_root_file1" -a  -e "$no_remote_root_file2" -a  -e "$no_remote_root_file3" -a  -e "$no_remote_root_file4" ];then
    echo "需要配置的文件不存在，请检查是否存在/etc/pam.d/login，/etc/securetty，/etc/ssh/sshd_config，/etc/X11/gdm/gdm.conf"
else
    no_remote_root_1=`more /etc/pam.d/login |grep -v '#' |grep 'auth required pam_securetty.so'` #非空正确
    no_remote_root_2=`more /etc/securetty |grep -v '#'| grep 'console'` #非空正确
    no_remote_root_3=`more /etc/ssh/sshd_config |grep -v '#' | grep 'PermitRootLogin no'` #非空正确
    no_remote_root_4=`more /etc/X11/gdm/gdm.conf |grep -v '#' | grep -E 'AllowRoot=false|AllowRemoteRoot=false' |wc -l` #非空正确
    if [  -n "$no_remote_root_1" -a  -n "$no_remote_root_2" -a  -n "$no_remote_root_3" -a  -n "$no_remote_root_4" ];then
        echo "禁止超级管理员账户远程登录，符合要求">>out.txt
    else
        echo '禁止超级管理员账户远程登录配置不满足要求，是否自动配置：(Y/N):'
        read user_num_YorN_re
        temp=`echo ${user_num_YorN_re} | grep Y`
        temp1=`echo ${user_num_YorN_re} | grep y`
        if [ "$temp" != "" -o "$temp1" != "" ];then
            cp  /etc/pam.d/login /etc/pam.d/login_bak
            cp  /etc/securetty /etc/securetty_bak
            cp  /etc/ssh/sshd_config /etc/ssh/sshd_config_bak
            cp  /etc/X11/gdm/gdm.conf /etc/X11/gdm/gdm.conf_bak
			echo "是否已经存在需要远程登录的账号?(Y/N):"
			read remote_user
			temp=`echo ${remote_user} | grep Y`
			temp1=`echo ${remote_user} | grep y`
			if [ "$temp" != "" -o "$temp1" != "" ];then
				echo "请输入需要配置的远程账号:"
				read remote_user_yes
				remote_user_yes_check=`cat /etc/passwd | grep $remote_user_yes`
				if [ -n "$remote_user_yes_check" ];then
					passwd $remote_user_yes_check
				fi
			else
				echo "请输入需要新建的账号:"
				read new_user
				if [ -n "$new_user" ];then
					useradd $new_user
					passwd $new_user
				fi
			fi
            if [ ! -n "$no_remote_root_1" -o ! -n "$no_remote_root_2" ];then
                sed -i '/auth required pam_securetty so/s/\#//g'  /etc/pam.d/login
                echo 'auth required pam_securetty.so' >> /etc/pam.d/login
                echo 'console' >> /etc/securetty
                echo '禁止root用户远程telnet登录系统;配置完成' >>out.txt
            fi
            if [ ! -n "$no_remote_root_3"  ];then
                sed -i '/PermitRootLogin/s/#PermitRootLogin no/PermitRootLogin no/g'  /etc/ssh/sshd_config
                sed -i '/PermitRootLogin/s/#PermitRootLogin yes/PermitRootLogin no/g'  /etc/ssh/sshd_config
                sed -i '/PermitRootLogin/s/PermitRootLogin yes/PermitRootLogin no/g'  /etc/ssh/sshd_config
                service sshd stop
                if [ "$?" -eq 0 ];then
                    service sshd start
                fi
                echo '禁止root用户远程ssh登录系统,配置完成' >>out.txt
            fi
            if [ "$no_remote_root_4" -lt "2" ];then
                mkdir /etc/X11 && mkdir /etc/X11/gdm
                touch /etc/X11/gdm/gdm.conf
                sed -i '/AllowRoot/s/AllowRoot=on/AllowRoot=false/g'  /etc/X11/gdm/gdm.conf
                sed -i '/AllowRemoteRoot/s/AllowRemoteRoot=on/AllowRemoteRoot=false/g'  /etc/X11/gdm/gdm.conf
                echo 'AllowRoot=false' >> /etc/X11/gdm/gdm.conf
                echo 'AllowRemoteRoot=false' >> /etc/X11/gdm/gdm.conf
                echo '禁止root图形界面登录，配置完成' >>out.txt
            fi
            if [ "$?" -eq 0 ];then
                echo '禁止超级管理员账户远程登录已完成配置'>>out.txt
            fi
        fi
    fi
fi

#将用户账户分配到相应的账户组
echo "请自行根据需求将用户账户分配到相应的账户组:" >> out.txt
echo "############################################" >> out.txt
echo `more /etc/group` >> out.txt
echo "############################################" >> out.txt

#设置口令策略满足复杂度要求和口令有效期（ok）
password_len=`more /etc/login.defs | grep -v '#' | grep PASS_MIN_LEN |awk -F' ' '{print $2}'`
password_time=`more /etc/login.defs | grep -v '#' | grep PASS_MAX_DAYS |awk -F' ' '{print $2}'`
if [ "$password_len" = 5 -a  "$password_time" = 90 ];then
    echo "口令复杂度满足要求">>out.txt
else
    echo '口令复杂度配置不满足要求，是否自动配置：(Y/N):'
    read user_num_YorN_re
    temp=`echo ${user_num_YorN_re} | grep Y`
    temp1=`echo ${user_num_YorN_re} | grep y`
    if [ "$temp" != "" -o "$temp1" != "" ];then
        cp -p /etc/login.defs /etc/login.defs_bak
        echo $password_len
        sed -i '/PASS_MIN_LEN/s/'$(echo $password_len)'/5/g' /etc/login.defs
        sed -i '/PASS_MAX_DAYS/s/'$(echo $password_time)'/90/g' /etc/login.defs
        if [ "$?" -eq 0 ];then
            echo '口令策略已完成配置'>>out.txt
        fi
    fi
fi

#设定连续认证失败次数（ok）
auth_false_1=`cat /etc/pam.d/system-auth | grep -v '#' |grep 'auth    required     /lib/security/$ISA/pam_tally.so onerr=fail no_magic_root'`
auth_false_2=`cat /etc/pam.d/system-auth | grep -v '#' |grep 'account required     /lib/security/$ISA/pam_tally.so deny=6 no_magic_root reset'`
if [ -n "$auth_false_1" -a -n "$auth_false_2" ];then
    echo "连续认证失败次数，配置满足要求">>out.txt
else
    echo '连续认证失败次数不满足要求，是否自动配置：(Y/N):'
    read user_num_YorN_re
    temp=`echo ${user_num_YorN_re} | grep Y`
    temp1=`echo ${user_num_YorN_re} | grep y`
    if [ "$temp" != "" -o "$temp1" != "" ];then
        cp  /etc/pam.d/system-auth /etc/pam.d/system-auth_bak
        echo 'auth    required     /lib/security/$ISA/pam_tally.so onerr=fail no_magic_root' >> /etc/pam.d/system-auth
        echo 'account required     /lib/security/$ISA/pam_tally.so deny=6 no_magic_root reset' >> /etc/pam.d/system-auth
        if [ "$?" -eq 0 ];then
            echo '连续认证失败次数配置完成'>>out.txt
        fi
    fi
fi

#删除root以为UID为0的用户（ok）
root_UID_0=`awk -F: '($3 == 0) { print $1 }' /etc/passwd`
root_UID_0_line=`awk -F: '($3 == 0) { print $1 }' /etc/passwd | wc -l`
if [ "$root_UID_0" = "root" -a "$root_UID_0_line" -lt 2 ];then
    echo "只有root的UID为0，配置满足要求" >> out.txt
else
    echo '除了root有其他账号UID为0，是否自动配置：(Y/N):'
    read user_num_YorN_re
    temp=`echo ${user_num_YorN_re} | grep Y`
    temp1=`echo ${user_num_YorN_re} | grep y`
    if [ "$temp" != "" -o "$temp1" != "" ];then
        cp  /etc/passwd /etc/passwd_bak
        cp  /etc/shadow /etc/shadow_bak
        cp  /etc/group /etc/group_bak
        other_uid_0=`awk -F: '($3 == 0) { print $1 }' /etc/passwd | grep -v 'root'`
        for other_uid_0_del in $other_uid_0
        do
            userdel -f $other_uid_0_del
            echo '删除账号:'$other_uid_0_del >> out.txt
        done

        if [ "$?" -eq 0 ];then
            echo '删除root以外UID为0的账户配置完成'>>out.txt
        fi
    fi
fi

#文件权限设置（ok）
temp_1='/etc/xinetd.conf'
temp_2='/etc/grub.conf'
temp_3='/etc/lilo.conf'
if [ ! -e "$temp_1" ];then
    file_power_6="-rw-------"
else
	file_power_6=`ls -l /etc/xinetd.conf | awk '{print $1}' | sed 's/.$//'`
fi
if [ ! -e "$temp_2" ];then
    file_power_7="-rw-------"
else
	file_power_7=`ls -l /etc/grub.conf | awk '{print $1}' | sed 's/.$//'`
fi
if [ ! -e "$temp_3" ];then
    file_power_8="-rw-------"
else
	file_power_8=`ls -l /etc/lilo.conf | awk '{print $1}' | sed 's/.$//'`
fi
file_power_1=`ls -l /etc/passwd | awk '{print $1}' | sed 's/.$//'`
file_power_2=`ls -l /etc/shadow | awk '{print $1}' | sed 's/.$//'`
file_power_3=`ls -l /etc/group | awk '{print $1}' | sed 's/.$//'`
file_power_4=`ls -l /etc/securetty | awk '{print $1}' | sed 's/.$//'`
file_power_5=`ls -l /etc/services | awk '{print $1}' | sed 's/.$//'`
#不同系统查询出来有个.的处理
tmp_test=`ls -l /etc/passwd | awk '{print $1}' | grep '\.'`
if [ -n "$tmp_test" ];then
    file_power_1=`ls -l /etc/passwd | awk '{print $1}' | sed 's/.$//'`
    file_power_2=`ls -l /etc/shadow | awk '{print $1}' | sed 's/.$//'`
    file_power_3=`ls -l /etc/group | awk '{print $1}' | sed 's/.$//'` 
    file_power_4=`ls -l /etc/securetty | awk '{print $1}' | sed 's/.$//'`
    file_power_5=`ls -l /etc/services | awk '{print $1}' | sed 's/.$//'`
fi  
if [ "$file_power_1" = "-rw-r--r--" -a "$file_power_2" = "-r--------" -a "$file_power_3" = "-rw-r--r--" -a "$file_power_4" = "-rw-------" -a "$file_power_5" = "-rw-r--r--" -a "$file_power_6" = "-rw-------" -a "$file_power_7" = "-rw-------" -a "$file_power_8" = "-rw-------" ];then
    echo "文件权限配置满足要求">>out.txt
else
    echo '文件权限不满足配置，是否自动配置：(Y/N):'
    read user_num_YorN_re
    temp=`echo ${user_num_YorN_re} | grep Y`
    temp1=`echo ${user_num_YorN_re} | grep y`
    if [ "$temp" != "" -o "$temp1" != "" ];then
        cp  /etc/passwd /etc/passwd_bak
        cp  /etc/shadow /etc/shadow_bak
        cp  /etc/group /etc/group_bak
        cp  /etc/securetty /etc/securetty_bak
        cp  /etc/services /etc/services_bak
        cp  /etc/xinted.conf /etc/xinetd.conf_bak
        cp  /etc/grub.conf /etc/grub.conf_bak
        cp  /etc/lilo.conf /etc/lilo.conf_bak
		chmod 644 /etc/passwd
		chmod 400 /etc/shadow
		chmod 644 /etc/group
		chmod 644 /etc/services
		chmod 600 /etc/securetty
		chmod 600 /etc/xinetd.conf
		chmod 600 /etc/grub.conf
		chmod 600 /etc/lilo.conf
		echo '文件权限设置配置完成'>>out.txt
    fi
fi

#系统umask设置（ok）
system_umask_1=`more /etc/profile | grep '^    umask' | awk '{print $2}' |head -1`
system_umask_2=`more /etc/csh.login | grep '^    umask' | awk '{print $2}' |head -1`
system_umask_3=`more /etc/csh.cshrc | grep '^    umask' | awk '{print $2}' |head -1`
system_umask_4=`more /etc/bashrc | grep '^    umask' | awk '{print $2}' |head -1`
system_umask_5=`more /root/.bashrc | grep '^    umask' | awk '{print $2}' |head -1`
system_umask_6=`more /root/.cshrc | grep '^    umask' | awk '{print $2}' |head -1`
if [ ! -n "$system_umask_1" ];then
    system_umask_1="027"
fi
if [ ! -n "$system_umask_2" ];then
    system_umask_2="027"
fi
if [ ! -n "$system_umask_3" ];then
    system_umask_3="027"
fi
if [ ! -n "$system_umask_4" ];then
    system_umask_4="027"
fi
if [ ! -n "$system_umask_5" ];then
    system_umask_5="027"
fi
if [ ! -n "$system_umask_6" ];then
    system_umask_6="027"
fi
if [ "$system_umask_1" = "027" -a "$system_umask_2" = "027" -a "$system_umask_3" = "027" -a "$system_umask_4" = "027" -a "$system_umask_5" = "027" -a "$system_umask_6" = "027" ];then
    echo "系统umask设置配置满足要求">>out.txt
else
    echo '系统umask设置配置不满足要求，是否自动配置：(Y/N):'
    read user_num_YorN_re
    temp=`echo ${user_num_YorN_re} | grep Y`
    temp1=`echo ${user_num_YorN_re} | grep y`
    if [ "$temp" != "" -o "$temp1" != "" ];then
        cp  /etc/profile /etc/profile_bak
        cp  /etc/csh.login /etc/csh.login_bak
        cp  /etc/csh.cshrc /etc/csh.cshrc_bak
        cp  /etc/bashrc /etc/bashrc_bak
        cp  -f /root/.bashrc /root/.bashrc_bak
        cp  -f /root/.cshrc /root/.cshrc_bak
        if [ "$?" -eq 0 ];then
            sed -i '/umask/s/'$(echo $system_umask_1)'/027/g' /etc/profile
            sed -i '/umask/s/'$(echo $system_umask_2)'/027/g' /etc/csh.login
            sed -i '/umask/s/'$(echo $system_umask_3)'/027/g' /etc/csh.cshrc
            sed -i '/umask/s/'$(echo $system_umask_4)'/027/g' /etc/bashrc
            sed -i '/umask/s/'$(echo $system_umask_5)'/027/g' /root/.bashrc
            sed -i '/umask/s/'$(echo $system_umask_6)'/027/g' /root/.cshrc            
            echo '系统umask设置配置完成'>>out.txt
        fi
    fi
fi

#账号与口令安全性设置（ok）
sec_romote_user_1=`cut -d":" -f6  /etc/passwd | ls -a |grep .netrc`
sec_romote_user_2=`cut -d":" -f6  /etc/passwd | ls -a |grep .rhosts`
sec_romote_user_3=`cut -d":" -f6  /etc/passwd | ls -a |grep .equiv`
if [ ! -n "$sec_romote_user_1"  -a  ! -n "$sec_romote_user_2"  -a  ! -n "$sec_romote_user_3"  ];then
    echo "账号与口令安全性设置满足要求">>out.txt
else
    echo '账号与口令安全性设置不满足要求，是否自动配置：(Y/N):'
    read user_num_YorN_re
    temp=`echo ${user_num_YorN_re} | grep Y`
    temp1=`echo ${user_num_YorN_re} | grep y`
    if [ "$temp" != "" -o "$temp1" != "" ];then
        cp  /etc/.netrc /etc/.netrc.bak
        cp  /etc/.rhosts /etc/.rhosts.bak
        cp  /etc/.equiv /etc/.equiv.bak
        if [ "$?" -eq 0 ];then
            rm -f /etc/.netrc
            rm -f /etc/.rhosts
            rm -f /etc/.equiv
            echo '账号与口令安全性设置配置完成'>>out.txt
        fi
    fi
fi

#root用户环境变量的安全性（语句有问题）
#root_sec_1=`echo $PATH | egrep '(^|:)(\.|:|$)'`
#root_sec_2=`find `echo $PATH | tr ':' ' '` -type d \( -perm -002 -o -perm -020 \) -ls`
#if [ -n "$root_sec_1"  -a -n "$root_sec_2" ];then
#    echo "账号与口令安全性设置满足要求">>out.txt
#else
#    echo '账号与口令安全性设置不满足要求，是否自动配置：(Y/N):'
#    read user_num_YorN_re
#    temp=`echo ${user_num_YorN_re} | grep Y`
#    temp1=`echo ${user_num_YorN_re} | grep y`
#    if [ "$temp" != "" -o "$temp1" != "" ];then
#        cp -p /etc/.netrc /etc/.netrc.bak
#        cp -p /etc/.rhosts /etc/.rhosts.bak
#        cp -p /etc/.equiv /etc/.equiv.bak
#        if [ "$?" -eq 0 ];then
#            rm -f /etc/.netrc
#            rm -f /etc/.rhosts
#            rm -f /etc/.equiv
#            echo '账号与口令安全性设置配置完成'>>out.txt
#        fi
#    fi
#fi

#检查是否设置屏幕锁定（ok）
type gconftool >/dev/null 2>&1 || { echo >&2 "I require gconftool but it's not installed.  Aborting." >> gconftool_tmp.txt; }
gconftool_tmp=`grep 'gconftool' gconftool_tmp.txt`
if [ -n "$gconftool_tmp" ];then
    echo "gconftool命令不存在,进行下一项检查" >>out.txt
else
    screen_lock_1=`gconftool -2 -g /apps/gnome-screensaver/idle_activation_enabled`
    screen_lock_2=`gconftool -2 -g /apps/gnome-screensaver/lock_enabled`
    screen_lock_3=`gconftool -2 -g /apps/gnome-screensaver/mode`
    screen_lock-4=`gconftool -2 -g /apps/gnome-screensaver/idle_delay`
    if [ -n "$screen_lock_1"  -a -n "$screen_lock_2" -a -n "$screen_lock_3" -a -n "$screen_lock_4" ];then
        echo "屏幕锁定满足要求" >> out.txt
    else
        echo '屏幕锁定配置不满足要求，是否自动配置：(Y/N):'
        read user_num_YorN_re
        temp=`echo ${user_num_YorN_re} | grep Y`
        temp1=`echo ${user_num_YorN_re} | grep y`
        if [ "$temp" != "" -o "$temp1" != "" ];then
             gconftool-2 --direct \
            --config-source xml:readwrite:/etc/gconf/gconf.xml.mandatory \
            --type bool \
            --set /apps/gnome-screensaver/idle_activation_enabled true
             gconftool-2 --direct \
            --config-source xml:readwrite:/etc/gconf/gconf.xml.mandatory \
            --type bool \
            --set /apps/gnome-screensaver/lock_enabled true
             gconftool-2 --direct \
            --config-source xml:readwrite:/etc/gconf/gconf.xml.mandatory \
            --type string \
            --set /apps/gnome-screensaver/mode blank-only
             gconftool-2 --direct \
            --config-source xml:readwrite:/etc/gconf/gconf.xml.mandatory \
            --type int \
            --set /apps/gnome-screensaver/idle_delay 15
            if [ "$?" -eq 0 ];then
                echo '屏幕锁定要求设置配置完成'>>out.txt
            fi
        fi
    fi
fi

#使用PAM禁止任何人为su为root（ok）
pam_root_1=`cat /etc/pam.d/su |grep 'auth sufficient /lib/security/pam_rootok.so'`
pam_root_2=`cat /etc/pam.d/su |grep 'auth required /lib/security/pam_wheel.so group=wheel'`
if [  -n "$pam_root_1"  -a  -n "$pam_root_1" ];then
    echo "使用PAM禁止任何人为su为root满足要求">>out.txt
else
    echo '使用PAM禁止任何人为su为root不满足要求，是否自动配置：(Y/N):'
    read user_num_YorN_re
    temp=`echo ${user_num_YorN_re} | grep Y`
    temp1=`echo ${user_num_YorN_re} | grep y`
    if [ "$temp" != "" -o "$temp1" != "" ];then
        sed -i '1i\auth sufficient /lib/security/pam_rootok.so' /etc/pam.d/su
        sed -i '2i\auth required /lib/security/pam_wheel.so group=wheel' /etc/pam.d/su
        if [ "$?" -eq 0 ];then
            echo '使用PAM禁止任何人为su为root设置配置完成'>>out.txt
        fi
    fi
fi

#检查root目录权限是否为700（ok）
check_root_700=`ls -lad /root | awk '{print $1}'`
echo '当前/root权限状态为:'$check_root_700 >> out.txt
if [ "$check_root_700" = "-rwx------." -o "$check_root_700" = "drwx------." ];then
    echo "/root权限状态满足要求" >> out.txt
else
    echo 'root目录权限不满足700，是否自动配置：(Y/N):'
    read user_num_YorN_re
    temp=`echo ${user_num_YorN_re} | grep Y`
    temp1=`echo ${user_num_YorN_re} | grep y`
    if [ "$temp" != "" -o "$temp1" != "" ];then
        chown root:root /root 
        chmod 0700 /root
        if [ "$?" -eq 0 ];then
            echo 'root目录权限为700设置配置完成'>>out.txt
        fi
    fi
fi

#系统账户登录限制（ok）
system_user_login_1=`cat /etc/shadow | egrep "^daemon:|^bin:|^sys:|^adm:|^lp:|^uucp:|^nuucp:|^smmsp:" | wc -l `
system_user_login_2=`cat /etc/shadow | egrep "^daemon:NP|^bin:NP|^sys:NP|^adm:NP|^lp:NP|^uucp:NP|^nuucp:NP|^smmsp:NP" | wc -l`
if [  "$system_user_login_2" -eq "$system_user_login_1" ];then
    echo "系统账户登录限制满足要求">>out.txt
else
    echo '系统账户登录限制不满足要求，是否自动配置：(Y/N):'
    read user_num_YorN_re
    temp=`echo ${user_num_YorN_re} | grep Y`
    temp1=`echo ${user_num_YorN_re} | grep y`
    if [ "$temp" != "" -o "$temp1" != "" ];then
        cp -p /etc/shadow /etc/shadow_bak
        temp_1=`cat /etc/shadow | egrep "^daemon:NP|^bin:NP|^sys:NP|^adm:NP|^lp:NP|^uucp:NP|^nuucp:NP|^smmsp:NP" | awk -F: '{ print $1 }'`
		system_user_login_1_temp=`cat /etc/shadow | egrep "^daemon:|^bin:|^sys:|^adm:|^lp:|^uucp:|^nuucp:|^smmsp:" | awk -F: '{ print $1 }'`
		if [ ! -n "$temp_1" ];then
			for system_user_login_temp in $system_user_login_1_temp
			do
				echo $system_user_login_temp
				sed -i '/'$(echo $system_user_login_temp)'/s/'$(echo $system_user_login_temp)':\*/'$(echo $system_user_login_temp)':NP/g' /etc/shadow
			done
		else
			grep -v $temp_1 /etc/shadow | egrep "^daemon|^bin|^sys|^adm|^lp|^uucp|^nuucp|^smmsp" | awk -F: '{ print $1 }' >> temp_2.txt
			for system_user_login_temp_1 in `cat temp_2.txt`
			do
				echo $system_user_login_temp_1
				sed -i '/'$(echo $system_user_login_temp_1)'/s/'$(echo $system_user_login_temp_1)':\*/'$(echo $system_user_login_temp_1)':NP/g' /etc/shadow
			done
		fi
		if [ "$?" -eq 0 ];then
			echo '系统账户登录限制设置配置完成'>>out.txt
		fi
    fi
fi

#补充重要目录和文件的权限设置（判断系统是centos还是ubuntu,再决定）、
centos_file='/etc/redhat-release'
if [ -e "$centos_file" ];then
    echo "系统为centos系统"
    echo "########################/etc/目录#####################" >> out.txt
    echo `ls -la /etc/ | awk '{ print $1" "$3" "$4" "$9 }'` >> out.txt
    echo "########################/etc/init.d/目录#####################" >> out.txt
    echo `ls -la /etc/init.d/ | awk '{ print $1" "$3" "$4" "$9 }'` >> out.txt
    echo "########################/tmp目录#####################" >> out.txt
    echo `ls -la /tmp | awk '{ print $1" "$3" "$4" "$9 }'` >> out.txt
    echo "########################/etc/default/目录#####################" >> out.txt
    echo `ls -la /etc/default/ | awk '{print $1" "$3" "$4" "$9 }'` >> out.txt
    echo "########################/etc/rc.d/rc3.d目录#####################" >> out.txt
    echo `ls -la /etc/rc.d/rc3.d | awk '{ print $1" "$3" "$4" "$9 }'` >> out.txt
    echo "########################/etc/rc.d/rc5.d目录#####################" >> out.txt
    echo `ls -la /etc/rc.d/rc5.d | awk '{ print $1" "$3" "$4" "$9 }'` >> out.txt
    echo "########################/etc/cron* /var/spool/cron*目录#####################" >> out.txt
    echo `ls -la /etc/cron* /var/spool/cron* | awk '{ print $1" "$3" "$4" "$9 }'` >> out.txt
else
    echo "系统为ubuntu系统"
    echo '补充重要目录和文件的权限设置，是否自动配置：(Y/N):'
    read user_num_YorN_re
    temp=`echo ${user_num_YorN_re} | grep Y`
    temp1=`echo ${user_num_YorN_re} | grep y`
    if [ "$temp" != "" -o "$temp1" != "" ];then
        cp -p /etc/ /tmp/etc/
        cp -p /etc/init.d/ /tmp/etc/init.d/
        cp -p /tmp /tmp//tmp
        cp -p /etc/default/ /tmp/etc/default/
        cp -p /etc/rc.d/rc3.d /tmp/etc/rc.d/rc3.d
        cp -p /etc/rc.d/rc5.d /tmp/etc/rc.d/rc5.d
        cp -p /etc/cron* /tmp/etc/cron*
        cp -p /var/spool/cron* /tmp/var/spool/cron*
        chmod go-wx /etc/
        chmod go-wx /etc/init.d/
        chmod go-wx /tmp
        chmod go-wx /etc/default/
        chmod go-wx /etc/rc.d/rc3.d
        chmod go-wx /etc/rc.d/rc5.d
        chmod go-wx /etc/cron*
        chmod go-wx /var/spool/cron*
        if [ "$?" -eq 0 ];then
            echo '补充重要目录和文件的权限设置配置完成'>>out.txt
        fi
    fi
fi

######################################################2020-6-11##########################################################

#记录登录认证和权限变更事件（ok）
syslog_log='/etc/syslog.conf'
if [ ! -e "$syslog_log" ];then
    echo "/etc/syslog.conf不存在，进入下一项" >>out.txt
else
    syslog_log_tmp_1=`more /etc/syslog.conf | grep -v '#' | grep 'auth.info' |grep 'var/adm/authlog'`
    syslog_log_tmp_2=`more /etc/syslog.conf | grep -v '#' | grep 'authpriv.info' |grep 'var/adm/authlog'`
    if [  -n "$syslog_log_tmp_1" -a -n "$syslog_log_tmp_2" ];then
        echo "记录登录认证和权限变更事件的配置，符合要求">>out.txt
    else
        cp -p /etc/syslog.conf /etc/syslog.conf_bak
        echo '记录登录认证和权限变更事件的配置不符合要求，是否立即设置：(Y/N):'
        read user_num_YorN_re
        temp=`echo ${user_num_YorN_re} | grep Y`
        temp1=`echo ${user_num_YorN_re} | grep y`
        if [ "$temp" != "" -o "$temp1" != "" ];then
            echo "auth.info var/adm/authlog" >> /etc/syslog.conf
            echo "authpriv.info var/adm/authlog" >> /etc/syslog.conf
            if [ "$?" -eq 0 ];then
                #总会有一个执行的命令
                /etc/init.d/syslog start
                service syslog restart
                systemctl  restart syslog
                echo '记录登录认证和权限变更事件设置配置完成'>>out.txt
            fi
        fi
    fi
fi

#配置系统日志文件权限（ok）
system_log_power_1='/var/log' #（这个是个文件夹）
system_log_power_2='/var/adm/messages'
if [ ! -e "$system_log_power_1" -a ! -e "$system_log_power_2" ];then
    echo "系统/dev/sysmsg，/var/adm/messages文件均不存在" >>out.txt
else
    if [ -e "$system_log_power_1" ];then
        system_log_power_1_tmp=`ls -al /var | grep 'log$' |awk '{ print $1 }'`
        if [ "$system_log_power_1_tmp" = "drw-r-----." -o "$system_log_power_1_tmp" = "drw-r-----" ];then
            echo "/var/log 权限符合要求" >> out.txt
        else
            cp -R /var/log /var/log_bak
            echo '配置系统日志文件权限/var/log不满足要求，是否立即设置：(Y/N):'
            read user_num_YorN_re
            temp=`echo ${user_num_YorN_re} | grep Y`
            temp1=`echo ${user_num_YorN_re} | grep y`
            if [ "$temp" != "" -o "$temp1" != "" ];then
                chmod 640 /var/log
            fi
        fi
    fi
    if [ -e "$system_log_power_2" ];then
        system_log_power_2_tmp=`ls -al /var/adm/messages | awk '{ print $1 }'`
        if [ "$system_log_power_2_tmp" = "-rw-r-----." -o "$system_log_power_2_tmp" = "-rw-r-----" ];then
            echo "/var/adm/messages 权限符合要求" >> out.txt
        else
            cp /var/adm/messages /var/adm/messages_bak
            echo '配置系统日志文件权限/var/adm/messages不满足要求，是否立即设置：(Y/N):'
            read user_num_YorN_re
            temp=`echo ${user_num_YorN_re} | grep Y`
            temp1=`echo ${user_num_YorN_re} | grep y`
            if [ "$temp" != "" -o "$temp1" != "" ];then
                chmod 640 /var/adm/messages
            fi
        fi
    else
        echo "/var/adm/messages文件不存在" >> out.txt
    fi
fi

#设置日志服务器配置文件权限（OK）
syslog_log='/etc/syslog.conf'
if [ ! -e "$syslog_log" ];then
    echo "/etc/syslog.conf不存在" >>out.txt
else
    syslog_log_tmp_1=`ls -l /etc/syslog.conf | awk '{ print $1 }'`
    if [  "$syslog_log_tmp_1" = "-r--------." -o "$syslog_log_tmp_1" = "-r--------" ];then
        echo "设置日志服务器配置文件权限，符合要求">>out.txt
    else
        echo '设置日志服务器配置文件权限不符合要求，是否立即设置：(Y/N):'
        read user_num_YorN_re
        temp=`echo ${user_num_YorN_re} | grep Y`
        temp1=`echo ${user_num_YorN_re} | grep y`
        if [ "$temp" != "" -o "$temp1" != "" ];then
            cp /etc/syslog.conf /etc/syslog.conf_bak
            chmod 400 /etc/syslog.conf
            echo "设置日志服务器配置文件权限配置完成" >> out.txt
        fi
    fi
fi

#配置日志记录系统安全事件（ok）
syslog_log='/etc/syslog.conf'
if [ ! -e "$syslog_log" ];then
    echo "/etc/syslog.conf不存在" >>out.txt
else
    syslog_log_tmp_1=`more /etc/syslog.conf | grep -v '#' | grep '*.info;auth.none;authpriv.none    /var/adm/syslog'`
    if [  -n "$syslog_log_tmp_1" ];then
        echo "配置日志记录系统安全事件，符合要求">>out.txt
    else
        echo '配置日志记录系统安全事件不符合要求，是否立即设置：(Y/N):'
        read user_num_YorN_re
        temp=`echo ${user_num_YorN_re} | grep Y`
        temp1=`echo ${user_num_YorN_re} | grep y`
        if [ "$temp" != "" -o "$temp1" != "" ];then
            cp -p /etc/syslog.conf /etc/syslog.conf_bak
            echo "*.info;auth.none;authpriv.none    /var/adm/syslog" >> /etc/syslog.conf
            if [ "$?" -eq 0 ];then
                /etc/init.d/syslog start
                service syslog restart
                systemctl syslog restart
                echo "设置日志服务器配置文件权限配置完成" >> out.txt
            fi
        fi
    fi
fi

#系统应用/服务log配置（ok）
syslog_log='/etc/syslog.conf'
if [ ! -e "$syslog_log" ];then
    echo "/etc/syslog.conf不存在" >>out.txt
else
    syslog_log_tmp_1=`more /etc/syslog.conf | grep -v '#' | grep '*.err;kern.debug;daemon.notice;        /var/adm/messages'`
    syslog_log_tmp_2=`more /etc/syslog.conf | grep -v '#' | grep 'cron.*                               /var/log/cron'`
    if [  -n "$syslog_log_tmp_1" -a -n "$syslog_log_tmp_2" ];then
        echo "系统应用/服务log配置，符合要求">>out.txt
    else
        echo '系统应用/服务log配置不符合要求，是否立即设置：(Y/N):'
        read user_num_YorN_re
        temp=`echo ${user_num_YorN_re} | grep Y`
        temp1=`echo ${user_num_YorN_re} | grep y`
        if [ "$temp" != "" -o "$temp1" != "" ];then
            cp –p /etc/syslog.conf /etc/syslog.conf_bak
            echo "*.err;kern.debug;daemon.notice;        /var/adm/messages" >> /etc/syslog.conf
            echo "cron.*                               /var/log/cron" >> /etc/syslog.conf
            if [ "$?" -eq 0 ];then
                /etc/init.d/syslog start
                service syslog restart
                systemctl syslog restart
                echo "系统应用/服务log配置配置完成" >> out.txt
            fi
        fi
    fi
fi

#设置日志服务器远程功能（ok，可以加一个输入ip的）
syslog_log='/etc/syslog.conf'
if [ ! -e "$syslog_log" ];then
    echo "/etc/syslog.conf不存在" >>out.txt
else
    syslog_log_tmp_1=`more /etc/syslog.conf | grep -v '#' | grep '*.*   @192.168.0.1'`
    if [  -n "$syslog_log_tmp_1" ];then
        echo "设置日志服务器远程功能，符合要求">>out.txt
    else
        echo '设置日志服务器远程功能不符合要求，是否立即设置：(Y/N):'
        read user_num_YorN_re
        temp=`echo ${user_num_YorN_re} | grep Y`
        temp1=`echo ${user_num_YorN_re} | grep y`
        if [ "$temp" != "" -o "$temp1" != "" ];then
            cp –p /etc/syslog.conf /etc/syslog.conf_bak
            echo "*.*   @192.168.0.1" >> /etc/syslog.conf
            if [ "$?" -eq 0 ];then
                /etc/init.d/syslog start
                service syslog restart
                systemctl syslog restart
                echo "系统应用/服务log配置配置完成" >> out.txt
            fi
        fi
    fi
fi

#IP协议安全要求######################################
#远程登录取消telnet采用ssh（ok）
check_netstat=`type netstat`
if [ $? -eq 0 ];then
	ssh_open=`netstat -an | egrep '0.0.0.0:22|192.168.3.126:22'`
	telnet_close=`netstat -an | grep '0.0.0.0:23|192.168.3.126:23'`
	if [  -n "$ssh_open" -a ! -n "$telnet_close" ];then
		echo "远程登录取消telnet采用ssh，符合要求">>out.txt
	else
		echo '远程登录取消telnet采用ssh不符合要求，是否立即设置：(Y/N):'
		read user_num_YorN_re
		temp=`echo ${user_num_YorN_re} | grep Y`
		temp1=`echo ${user_num_YorN_re} | grep y`
		if [ "$temp" != "" -o "$temp1" != "" ];then
			if [ -e "/etc/xinetd.d/telnet" ];then
				cp  /etc/xinetd.d/telnet /etc/xinetd.d/telnet_bak
				sed -i '/disable = no/s/disable = no/disable = yes/g' /etc/xinetd.d/telnet
				service xinetd restart
				/etc/init.d/sshd start
				systemctl sshd restart
				echo "远程登录取消telnet采用ssh设置配置完成" >> out.txt
			fi
		fi
	fi
fi



#优化ssh的banner信息(ok)
syslog_log='/etc/syslog.conf'
if [ ! -e "$syslog_log" ];then
    echo "/etc/syslog.conf不存在" >>out.txt
else
    syslog_log_tmp_1=`more /etc/syslog.conf | grep '#Banner /etc/issue.net'`
    if [ -n "$syslog_log_tmp_1" ];then
        echo "优化ssh的banner信息，符合要求">>out.txt
    else
        echo '优化ssh的banner信息不符合要求，是否立即设置：(Y/N):'
        read user_num_YorN_re
        temp=`echo ${user_num_YorN_re} | grep Y`
        temp1=`echo ${user_num_YorN_re} | grep y`
        if [ "$temp" != "" -o "$temp1" != "" ];then
            sed -i '/Banner \/etc\/issue.net/s/^/#/g' /etc/syslog.conf
            echo "#Banner /etc/issue.net" >> /etc/syslog.conf
            echo "优化ssh的banner信息配置完成" >> out.txt
        fi
    fi
fi

#优化telnet的Banner信息（ok）
telnet_banner=`telnet localhost | grep 'Authorized users only'`
if [ - n "$telnet_banner" ];then
    echo "telnet配置满足要求" >>out.txt
else
    cp /etc/issue /etc/issue_bak
    cp /etc/issue.net /etc/issue.net_bak
    telnet_banner_tmp_1='/etc/issue'
    telnet_banner_tmp_2='/etc/issue.net'
    if [ ! -e "$telnet_banner_tmp_1" ];then
        echo "/etc/issue不存在" >> out.txt
    else
        telnet_banner_tmp_1_1=`more /etc/issue | grep ' Authorized users only'`
        if [ -n "$telnet_banner_tmp_1_1" ];then
            echo "/etc/issue优化telnet的Banner信息，符合要求">>out.txt
        else
            echo '优化telnet的Banner信息不符合要求，是否立即设置：(Y/N):'
            read user_num_YorN_re
            temp=`echo ${user_num_YorN_re} | grep Y`
            temp1=`echo ${user_num_YorN_re} | grep y`
            if [ "$temp" != "" -o "$temp1" != "" ];then
                echo "Authorized users only. All activity may be monitored and reported " >> /etc/issue
                echo "/etc/issue优化telnet的Banner信息配置完成" >> out.txt
                /etc/init.d/xinetd restart
                systemctl restart  xinetd
                service xinetd restart
            fi
        fi
    fi  
    if [ ! -e "$telnet_banner_tmp_2" ];then
        echo "/etc/issue.net不存在" >> out.txt
    else
        telnet_banner_tmp_1_2=`more /etc/issue.net | grep 'Authorized users only'`
        if [ -n "$telnet_banner_tmp_1_2" ];then
            echo "/etc/issue.net优化telnet的Banner信息，符合要求">>out.txt
        else
            echo '优化telnet的Banner信息不符合要求，是否立即设置：(Y/N):'
            read user_num_YorN_re
            temp=`echo ${user_num_YorN_re} | grep Y`
            temp1=`echo ${user_num_YorN_re} | grep y`
            if [ "$temp" != "" -o "$temp1" != "" ];then
                echo "Authorized users only. All activity may be monitored and reported " >> /etc/issue.net
                echo "/etc/issue.net优化telnet的Banner信息配置完成" >> out.txt
                /etc/init.d/xinetd restart
                systemctl restart  xinetd
                service xinetd restart
            fi
        fi
    fi  
fi

#禁止ICMP重定向（ok）
icmp_redirects=`sysctl -n net.ipv4.conf.all.accept_redirects`
if [ "$icmp_redirects" -eq 0 ];then
    echo "禁止ICMP重定向配置满足要求" >>out.txt
else
    icmp_tmp='/etc/sysctl.conf'
    if [ ! -e "$icmp_tmp" ];then
        echo "/etc/sysctl.conf文件不存在">>out.txt
    else
        echo '禁止ICMP重定向配置不满足要求，是否立即设置：(Y/N):'
        read user_num_YorN_re
        temp=`echo ${user_num_YorN_re} | grep Y`
        temp1=`echo ${user_num_YorN_re} | grep y`
        if [ "$temp" != "" -o "$temp1" != "" ];then
            cp -p /etc/sysctl.conf /etc/sysctl.conf_bak
            icmp_tmp_2=`more /etc/sysctl.conf | grep 'net.ipv4.conf.all.accept_redirects'`
            if [ -n "$icmp_tmp_2" ];then
                sysctl -w net.ipv4.conf.all.accept_redirects='0'
            else
                echo "net.ipv4.conf.all.accept_redirects=0" >> /etc/sysctl.conf
            fi
            echo "禁止ICMP重定向配置完成" >> out.txt
        fi
    fi
fi

#禁止源路由转发（ok）
route_redirects=`sysctl -n net.ipv4.conf.all.accept_source_route`
if [ "$route_redirects" -eq 0 ];then
    echo "禁止源路由转发配置满足要求" >>out.txt
else
    route_tmp='/etc/sysctl.conf'
    if [ ! -e "$route_tmp" ];then
        echo "/etc/sysctl.conf文件不存在">>out.txt
    else
        echo '禁止源路由转发配置不满足要求，是否立即设置：(Y/N):'
        read user_num_YorN_re
        temp=`echo ${user_num_YorN_re} | grep Y`
        temp1=`echo ${user_num_YorN_re} | grep y`
        if [ "$temp" != "" -o "$temp1" != "" ];then
            cp -p /etc/sysctl.conf /etc/sysctl.conf_bak
            route_tmp_2=`more /etc/sysctl.conf | grep 'net.ipv4.conf.all.accept_source_route'`
            if [ -n "$route_tmp_2" ];then
                sysctl -w net.ipv4.conf.all.accept_source_route ='1'
            else
                echo "net.ipv4.conf.all.accept_source_route=0" >> /etc/sysctl.conf
            fi
            echo "禁止源路由转发配置完成" >> out.txt
        fi
    fi
fi

#设定远程登录的IP地址范围（ok）
remote_ip_allow='/etc/hosts.allow'
remote_ip_deny='/etc/hosts.deny'
if [ -e "$remote_ip_allow"  ];then
    remote_ip_allow_tmp=`more /etc/hosts.allow | grep -v '#' |grep 'allow'`
    if [  -n "$remote_ip_allow_tmp" ];then
        echo "/etc/hosts.allow设置了允许访问的IP，配置满足要求" >>out.txt
    else
		echo '未设置允许访问的IP，是否立即设置：(Y/N):'
        read user_num_YorN_re
        temp=`echo ${user_num_YorN_re} | grep Y`
        temp1=`echo ${user_num_YorN_re} | grep y`
		if [ "$temp" != "" -o "$temp1" != "" ];then
			echo "请输入允许访问的ip:"
			read ip
			if [ -n "$ip" ];then
				echo "all:"$ip":allow" >> /etc/hosts.allow
				echo "sshd:"$ip":allow" >> /etc/hosts.allow
				echo "远程登录的IP地址范围 设置完成" >> out.txt
			else
				echo "/etc/hosts.allow 未设置允许访问的IP" >> out.txt
			fi
		fi
    fi  
fi
if [ -e "$remote_ip_deny"  ];then
    remote_ip_allow_tmp=`more /etc/hosts.deny |grep -v '#'| grep 'DENY'`
    if [  -n "$remote_ip_allow_tmp" ];then
        echo "/etc/hosts.deny设置了禁止访问的IP，配置满足要求" >>out.txt
    else
		echo '未设置禁止访问的IP，是否立即设置：(Y/N):'
        read user_num_YorN_re
        temp=`echo ${user_num_YorN_re} | grep Y`
        temp1=`echo ${user_num_YorN_re} | grep y`
		if [ "$temp" != "" -o "$temp1" != "" ];then
			echo "请输入需要禁止访问的ip:"
			read ip
			if [ -n "$ip" ];then
				echo "all:"$ip":DENY" >> /etc/hosts.deny
				echo "禁止远程登录的IP地址范围 设置完成" >> out.txt
			else
				echo "/etc/hosts.deny 未设置允许访问的IP" >> out.txt
			fi
		fi
    fi  
fi

#检查系统coredump设置 
core_tmp='/etc/profile'
if [ -e "$core_tmp"  ];then
    coredump=`ulimit -c`
    if [  "$coredump" -eq 0 ];then
        echo "coredump配置满足要求" >>out.txt
    else
		echo 'coredump配置不满足要求，是否立即设置：(Y/N):'
        read user_num_YorN_re
        temp=`echo ${user_num_YorN_re} | grep Y`
        temp1=`echo ${user_num_YorN_re} | grep y`
		if [ "$temp" != "" -o "$temp1" != "" ];then
			ulimit -S -c 0 > /dev/null 2>&1
			if [ "$?" -eq 0 ];then
				echo "设置coredump,配置完成" >> out.txt
			fi
		fi
    fi  
fi

#服务配置要求
#设置NTP服务器（ok）
NTP='/etc/ntp.conf'
if [ -e "$NTP"  ];then
    NTP_tmp=`more /etc/ntp.conf | grep 'server' | grep -E '127|10|172|192'`
    if [  -n "$NTP_tmp" ];then
        echo "/etc/ntp.conf配置NTP服务器，配置满足要求" >>out.txt
    else
        echo "/etc/ntp.conf配置NTP服务器，不满足要求，是否立即配置:(Y/N)"
        read user_num_YorN_re
        temp=`echo ${user_num_YorN_re} | grep Y`
        temp1=`echo ${user_num_YorN_re} | grep y`
        if [ "$temp" != "" -o "$temp1" != "" ];then
            cp /etc/ntp.conf /etc/ntp.conf.bak
            echo "输入需要配置的NTP的ip："
            read ip
            if [ -n "$ip" ];then
                echo "server "$ip >>/etc/ntp.conf
                echo "设置NTP服务器配置完成" >> out.txt
            else
                echo "未输入需要配置的NTP ip" >> out.txt 
            fi
        fi
    fi  
    NTP_tmp_2=`more /etc/ntp.conf | grep -v '#' | grep 'restrict' | grep -E '127|10|172|192'`
    if [  -n "$NTP_tmp_2" ];then
        echo "/etc/ntp.conf配置NTP服务器，配置满足要求" >>out.txt
    else
        echo "/etc/ntp.conf配置NTP服务器，不满足要求，是否立即配置:(Y/N)"
        read user_num_YorN_re
        temp=`echo ${user_num_YorN_re} | grep Y`
        temp1=`echo ${user_num_YorN_re} | grep y`
        if [ "$temp" != "" -o "$temp1" != "" ];then
            echo "请输入restrict的地址:"
            read restrict
            echo "请输入mask的地址:"
            read mask
            sed -i '/restrict/s/#//g' /etc/ntp.conf
            echo "restrict "$restrict "mask "$mask "nomodify notrap" >> /etc/ntp.conf
        fi
    fi  
    if [ "$?" -eq 0 ];then
        service ntp restart
        /etc/init.d/ntp start
        systemctl ntp restart
        echo "设置NTP服务器,配置完成" >> out.txt
    fi
else
    echo "/etc/ntp.conf 不存在" >> out.txt
fi

#关闭不必要的服务及端口（ok）
#port_server=`chkconfig --list |grep -E "^time|^echo|^time|^echo|^discard|^daytime|^chargen|^fs|^dtspc|^exec|^comsat|^talk|^finger|^uucp|^name|^xaudio|^netstat|^ufsd|^rexd|^systat|^sun-dr|^uuidgen|^krb5_prop|^sendmail" | awk -F' ' '{print $1}'`
port_server=`systemctl list-units |grep -E "^time|^echo|^time|^echo|^discard|^daytime|^chargen|^fs|^dtspc|^exec|^comsat|^talk|^finger|^uucp|^name|^xaudio|^netstat|^ufsd|^rexd|^systat|^sun-dr|^uuidgen|^krb5_prop|^sendmail" | awk -F' ' '{print $1}'`
if [ -n "$port_server" ];then
    for port_server_tmp in $port_server
    do
        echo "系统中未禁用的不必要服务:"$port_server_tmp
        echo "系统中未禁用的不必要服务:"$port_server_tmp >>out.txt
    done
else    
    echo "系统中不存在不必要的服务,满足要求" >> out.txt
fi
if [ -n "$port_server" ];then
    echo '是否禁用无关服务：(Y/N):'
    read user_num_YorN_re
    temp=`echo ${user_num_YorN_re} | grep Y`
    temp1=`echo ${user_num_YorN_re} | grep y`
    if [ "$temp" != "" -o "$temp1" != "" ];then
        for port_server_close in $port_server
        do
            systemctl stop $port_server_close
			systemctl disable $port_server_close
            echo '已关闭不必要服务'$port_server_close>>out.txt
        done
    fi
    if [ "$?" -eq 0 ];then
        echo "已关闭不必要的服务配置完成"
    fi
fi

#字符交互界面帐户超时自动退出（ok）
profile='/etc/profile'
if [  -e "$profile" ];then
    profile_TMOUT=`cat /etc/profile |grep -i TMOUT`
    if [ -n "$profile_TMOUT" ];then
        echo "/etc/profile文件中有TMOUT，符合要求">>out.txt
    else
        echo '/etc/profile文件中没有TMOUT不符合要求，是否立即设置：(Y/N):'
        read user_num_YorN_re
        temp=`echo ${user_num_YorN_re} | grep Y`
        temp1=`echo ${user_num_YorN_re} | grep y`
        if [ "$temp" != "" -o "$temp1" != "" ];then
            cp  /etc/profile /etc/profile_bak
            echo "TMOUT=1800000" >> /etc/profile
            echo "export TMOUT" >> /etc/profile
            echo "/etc/profile文件中有TMOUT配置完成" >> out.txt
        fi
    fi
fi
csh_file='/etc/csh.cshrc'
if [  -e "$csh_file" ];then
    csh=`cat /etc/csh.cshrc |grep -i autologout`
    if [ -n "$csh" ];then
        echo "/etc/csh.cshrc文件中有autologout，符合要求">>out.txt
    else
        echo '/etc/csh.cshrc文件中没有autologout，不符合要求，是否立即设置：(Y/N):'
        read user_num_YorN_re
        temp=`echo ${user_num_YorN_re} | grep Y`
        temp1=`echo ${user_num_YorN_re} | grep y`
        if [ "$temp" != "" -o "$temp1" != "" ];then
            cp  /etc/csh.cshrc /etc/csh.cshrc_bak
            echo "set autologout =30" >> /etc/csh.cshrc
            echo "/etc/csh.cshrc文件中有autologout，配置完成" >> out.txt
        fi
    fi
fi

#更新系统补丁（ok）
system_bug='/var/sadm/patch'
if [ -e "$system_bug" ];then
    echo "#############################################################" >> out.txt
    echo "输出系统补丁信息如下,请自行更新补丁：" >> out.txt
    echo `ls /var/sadm/patch` >> out.txt
    echo "#############################################################" >> out.txt
else
    echo "/var/sadm/patch文件不存在" >>out.txt
fi

#检查系统已安装的不必要软件包及需要更新的软件包（ok）
echo "#############################################################" >> out.txt
echo "查看版本及大补丁号，如下：" >> out.txt
echo `uname -a` >> out.txt
echo "查看系统所有安装包及补丁号，如下：" >> out.txt
echo `rpm -qa` >> out.txt
echo "#############################################################" >> out.txt

#NFS服务限制（ok）
NFS_service=`ps -ef | egrep "\[lockd\]|\[nfsd\]|\[statd\]|\[mountd\]"`
if [ -n "$NFS_service" ];then
    for NFS_service_tmp in $NFS_service
    do
        echo "系统中存在的NFS服务:"$NFS_service_tmp
        echo "系统中存在的NFS服务:"$NFS_service_tmp >>out.txt
    done
else    
    echo "系统中不存在的NFS服务,满足要求" >> out.txt
fi
NFS_service_1=`ps -ef | egrep "\[lockd\]|\[nfsd\]|\[statd\]|\[mountd\]" | awk '{ print $2 }'`
if [ -n "$NFS_service_1" ];then
    echo '是否禁用NFS服务：(Y/N):'
    read user_num_YorN_re
    temp=`echo ${user_num_YorN_re} | grep Y`
    temp1=`echo ${user_num_YorN_re} | grep y`
    if [ "$temp" != "" -o "$temp1" != "" ];then
        for NFS_service_tmp_1 in $NFS_service_1
        do
            kill -9 $NFS_service_tmp_1
            chkconfig --level 235 nfs off
            echo '已关闭不必要NFS服务pid:'$NFS_service_tmp_1>>out.txt
        done
    fi
    if [ "$?" -eq 0 ];then
        echo "NFS服务限制配置完成"
    fi
fi

#设置LILO/GRUB密码（ok）
# lilo_file='/etc/lilo.conf'
# if [  -e "$lilo_file" ];then
    # lilo_file_tmp=`cat /etc/lilo.conf |grep -v '#'|grep password`
    # if [ -n "$lilo_file_tmp" ];then
        # echo "/etc/lilo.conf文件中有password且未被注释，符合要求">>out.txt
    # else
        # echo '/etc/lilo.conf文件，不符合要求，是否立即设置：(Y/N):'
        # read user_num_YorN_re
        # temp=`echo ${user_num_YorN_re} | grep Y`
        # temp1=`echo ${user_num_YorN_re} | grep y`
        # if [ "$temp" != "" -o "$temp1" != "" ];then
            # echo "/etc/lilo.conf请输入password:"
            # read password
            # cp  /etc/lilo.conf /etc/lilo.conf_bak
            # sed -i '1i\restricted' /etc/lilo.conf
            # sed -i '2i\password='$(echo $password)'' /etc/lilo.conf
            # chown root:root /etc/lilo.conf  
            # chmod 600 /etc/lilo.conf
            # echo "/etc/lilo.conf文件，配置完成" >> out.txt
        # fi
    # fi
# fi
# grub_file='/etc/grub.conf'
# if [  -e "$grub_file" ];then
    # grub_file_tmp=`cat /etc/grub.conf |grep -v '#'|grep password`
    # if [ -n "$grub_file_tmp" ];then
        # echo "/etc/grub.conf文件中有password且未被注释，符合要求">>out.txt
    # else
        # echo '/etc/grub.conf文件，不符合要求，是否立即设置：(Y/N):'
        # read user_num_YorN_re
        # temp=`echo ${user_num_YorN_re} | grep Y`
        # temp1=`echo ${user_num_YorN_re} | grep y`
        # if [ "$temp" != "" -o "$temp1" != "" ];then
            # echo "/etc/grub.conf请输入password:"
            # read password
            # cp  /etc/grub.conf /etc/grub.conf_bak
            # sed -i '1i\password='$(echo $password)'' /etc/grub.conf
            # echo "password="$password >> /etc/grub.conf
            # chown root:root /etc/grub.conf 
            # chmod 600 /etc/grub.conf
            # echo "/etc/grub.conf文件，配置完成" >> out.txt
        # fi
    # fi
# fi

#FTP设置
#设置ftp权限及访问（ok）
grub_file_1='/etc/ftpusers'
if [  -e "$grub_file_1" ];then
    echo "检查设置FTP的/etc/ftpusers访问权限" >>out.txt
    echo `more /etc/ftpusers` >>out.txt
else
    echo "/etc/ftpusers文件不存在" >>out.txt
fi
grub_file_2='/etc/vsftpd.ftpusers'
if [  -e "$grub_file_2" ];then
    echo "检查设置FTP的/etc/vsftpd.ftpusers访问权限" >>out.txt
    echo `/etc/vsftpd.ftpusers` >>out.txt
else
    echo "/etc/vsftpd.ftpusers文件不存在" >>out.txt
fi
grub_file_3='/etc/ftpaccess'
if [  -e "$grub_file_3" ];then
    echo "检查设置FTP的/etc/ftpusers访问权限" >>out.txt
    echo `more /etc/ftpaccess` >>out.txt
else
    echo "/etc/ftpusers文件不存在" >>out.txt
fi
grub_file_4='/etc/vsftpd/vsftd.conf'
if [  -e "$grub_file_4" ];then
    echo "检查设置FTP的/etc/vsftpd/vsftd.conf访问权限" >>out.txt
    echo `more /etc/vsftpd/vsftd.conf` >>out.txt
else
    echo "/etc/vsftpd/vsftd.conf文件不存在" >>out.txt
fi

#启动FTP日志记录（ok）
vsftpd_file='/etc/vsftpd/vsftpd.conf'
if [  -e "$vsftpd_file" ];then
    vsftpd_file_tmp_1=`cat /etc/vsftpd/vsftpd.conf |grep -v '#'|grep 'xferlog_enable=YES'`
    vsftpd_file_tmp_2=`cat /etc/vsftpd/vsftpd.conf |grep -v '#'|grep 'xferlog_file=/var/log/vsftpd.log'`
    if [ -n "$vsftpd_file_tmp_1" -a -n "$vsftpd_file_tmp_2" ];then
        echo "/etc/vsftpd/vsftpd.conf配置，符合要求">>out.txt
    else
        echo '/etc/vsftpd/vsftpd.conf配置不符合要求，是否立即设置：(Y/N):'
        read user_num_YorN_re
        temp=`echo ${user_num_YorN_re} | grep Y`
        temp1=`echo ${user_num_YorN_re} | grep y`
        if [ "$temp" != "" -o "$temp1" != "" ];then
            cp  /etc/vsftpd/vsftpd.conf /etc/vsftpd/vsftpd.conf_bak
            vsftpd_file_tmp_1_1=`cat /etc/vsftpd/vsftpd.conf |grep -v '#'|grep 'xferlog_enable'`
            if [ -n "$vsftpd_file_tmp_1_1 "];then
                sed -i '/xferlog_enable/s/#//g' /etc/vsftpd/vsftpd.conf
            else
                echo "xferlog_enable=YES" >> /etc/vsftpd/vsftpd.conf
            fi
            vsftpd_file_tmp_2_1=`cat /etc/vsftpd/vsftpd.conf |grep -v '#'|grep 'xferlog_file'`
            if [ -n "$vsftpd_file_tmp_2_1 "];then
                sed -i '/xferlog_file/s/#//g' /etc/vsftpd/vsftpd.conf
            else
                echo "xferlog_file=/var/log/vsftpd.log" >> /etc/vsftpd/vsftpd.conf
            fi
            echo "/etc/vsftpd/vsftpd.conf文件，配置完成" >> out.txt
        fi
    fi
else
    echo "/etc/vsftpd/vsftpd.conf文件不存在" >> out.txt
fi

#更改FTP警告Banner（ok）
vsftpd_file='/etc/vsftpd.conf'
if [ -e "$vsftpd_file" ];then
    vsftpd_file_tmp=`cat /etc/vsftpd.conf |grep -v '#'|grep 'ftpd_banner' | grep 'users only'`
    if [ -n "$vsftpd_file_tmp" ];then
        echo "/etc/vsftpd.conf配置，符合要求">>out.txt
    else
        echo '/etc/vsftpd.conf配置不符合要求，是否立即设置：(Y/N):'
        read user_num_YorN_re
        temp=`echo ${user_num_YorN_re} | grep Y`
        temp1=`echo ${user_num_YorN_re} | grep y`
        if [ "$temp" != "" -o "$temp1" != "" ];then
            cp  /etc/vsftpd.conf /etc/vsftpd.conf_bak
            vsftpd_file_tmp_1_1=`cat /etc/vsftpd.conf |grep -v '#'|grep 'ftpd_banner'`
            if [ -n "$vsftpd_file_tmp_1_1 " ];then
                sed -i '/ftpd_banner/s/#//g' /etc/vsftpd.conf
            else
                echo "ftpd_banner='Authorized users only. All activity may be monitored and reported.'" >> /etc/vsftpd.conf  #输入不进去，不知道为啥，权限改为777过
            fi
            if [ "$?" -eq 0 ];then
                /etc/init.d/xinetd restart
                service xinetd restart
                systemctl xinetd restart
                echo "/etc/vsftpd.conf配置,配置完成"
            fi 
        fi
    fi
else    
    echo "/etc/vsftpd.conf文件不存在" >> out.txt
fi
pure_ftpd_file='/etc/pure-ftpd/pure-ftpd.conf'
if [ -e "$pure_ftpd_file" ];then
    pure_ftpd_file_tmp=`cat /etc/pure-ftpd/pure-ftpd.conf |grep -v '#'|grep 'FortunesFile' | grep '/usr/share/fortune/zippy'`
    if [ -n "$pure_ftpd_file_tmp" ];then
        echo "/etc/pure-ftpd/pure-ftpd.conf'配置，符合要求">>out.txt
    else
        echo '/etc/pure-ftpd/pure-ftpd.conf配置不符合要求，是否立即设置：(Y/N):'
        read user_num_YorN_re
        temp=`echo ${user_num_YorN_re} | grep Y`
        temp1=`echo ${user_num_YorN_re} | grep y`
        if [ "$temp" != "" -o "$temp1" != "" ];then
            cp  /etc/pure-ftpd/pure-ftpd.conf /etc/pure-ftpd/pure-ftpd.conf_bak
            pure_ftpd_file_tmp_1=`cat /etc/vsftpd/vsftpd.conf |grep -v '#'|grep 'FortunesFile'`
            if [ -n "$pure_ftpd_file_tmp_1 "];then
                sed -i '/FortunesFile/s/#//g' /etc/pure-ftpd/pure-ftpd.conf
            else
                echo "FortunesFile      /usr/share/fortune/zippy" >> /etc/pure-ftpd/pure-ftpd.conf
            fi
            if [ -e "/usr/share/fortune/zippy" ];then
                echo "ftpd_banner='Authorized users only. All activity may be monitored and reported.'" >> /usr/share/fortune/zippy
            else
                mkdir /usr/share/fortune
                cd /usr/share/fortune
                touch zippy
                echo "ftpd_banner='Authorized users only. All activity may be monitored and reported.'" >> /usr/share/fortune/zippy
            fi
            if [ "$?" -eq 0 ];then
                /etc/init.d/xinetd restart
                service xinetd restart
                systemctl xinetd restart
            fi 
        fi
    fi
else
    echo "/etc/pure-ftpd/pure-ftpd.conf文件不存在" >> out.txt
fi

#其他配置要求
#检查磁盘空间大小（ok）
echo "############################################################################" >> out.txt
echo "请自行检查磁盘空间大小" >> out.txt
echo `df -h` >> out.txt
disk=`df -h | awk '{ print $5 }' | sed 's/%//g'`
for disk_tmp in $disk
do
    if (( $disk_tmp > 80 ));then
        disk_tmp_1=`df -h | grep $disk_tmp | awk '{ print $6 }'`
        echo "磁盘不满足要求的为："$disk_tmp_1 ":" $disk_tmp "请尽快清理">>out.txt
    else
        echo "磁盘空间充足，满足要求" >> out.txt
    fi
done

#Chkrootkit安装（ok）
# chk_file=`type chkrootkit |grep "/sbin/chkrootkit"`
# if [ -n "$chk_file"  ];then
    # echo "Chkrootkit已安装" >> out.txt
# else
    # cd HW_install
    # rpm -ivh chkrootkit-0.49-9.el6.x86_64.rpm
    # if [ "$?" -eq 0 ];then
        # echo "chkrootkit安装完成" >> out.txt
    # else
        # echo "chkrootkit安装失败" >> out.txt
    # fi
# fi

#Fail2ban安装（ok）
# fail2ban=`type /bin/fail2ban-client` 
# if [ -n "$fail2ban" ];then
    # echo "Fail2ban已安装" >> out.txt
# else
    # cd HW_install
    # rpm -ivh fail2ban-*
    # if [ "$?" -eq 0 ];then
        # systemctl restart fail2ban
        # echo "Fail2ban安装成功" >> out.txt
    # fi
# fi


#检查任何人都有写权限的目录（ok）
every_user_tmp=`awk '($3 == "ext2" || $3 == "ext3") { print $2 }' /etc/fstab`
if [ -n "$every_user_tmp" ];then
    echo "检查任何人都有写权限的目录，低于安全要求" >> out.txt
    for part in $every_user_tmp
    do
        find $part -xdev -type d \( -perm -0002 -a ! -perm -1000 \) -print
        echo "低于安全要求的为"$part >> out.txt
    done
else
    echo "检查任何人都有写权限的目录,满足要求" >> out.txt
fi

#查找任何人都有写权限的文件（ok）
every_user_tmp_1=`grep -v ^# /etc/fstab | awk '($6 != "0") {print $2 }'`
if [ -n "$every_user_tmp_1" ];then
    echo "查找任何人都有写权限的文件，低于安全要求" >> out.txt
    for part in $every_user_tmp
    do
        find $part -xdev -type f \( -perm -0002 -a ! -perm -1000 \) -print
        echo "低于安全要求的为"$part >> out.txt
    done
else
    echo "查找任何人都有写权限的文件,满足要求" >> out.txt
fi

#禁止X server监听6000/TCP端口（ok）
tcp_6000='/etc/X11/xdm/Xservers'
if [ -e "$tcp_6000" ];then
    tcp_6000_tmp=`cat /etc/X11/xdm/Xservers |grep '\-nolisten tcp'`
    if [ -n "$tcp_6000_tmp" ];then
        echo "禁止X server监听6000/TCP端口。满足要求" >> out.txt
    else
        echo '禁止X server监听6000/TCP端口配置不符合要求，是否立即设置：(Y/N):'
        read user_num_YorN_re
        temp=`echo ${user_num_YorN_re} | grep Y`
        temp1=`echo ${user_num_YorN_re} | grep y`
        if [ "$temp" != "" -o "$temp1" != "" ];then
            cp  /etc/X11/xdm/Xservers /etc/X11/xdm/Xservers_bak
            cp  /etc/X11/xinit/xserverrc /etc/X11/xinit/xserverrc_bak
            tcp_6000_tmp_1=`cat /etc/X11/xdm/Xservers | grep "/usr/bin/X"`
            if [ -n "$tcp_6000_tmp_1" ];then
                sed -i '/\/usr\/bin\/X/a -nolisten tcp' /etc/X11/xdm/Xservers
            else
                echo "/usr/bin/X -nolisten tcp" >> /etc/X11/xdm/Xservers
            fi
            echo "禁止X server监听6000/TCP端口配置完成" >> out.txt
        fi
    fi
else
    echo "/etc/X11/xdm/Xservers文件不存在" >>out.txt
fi
tcp_6000_1='/etc/X11/xinit/xserverrc'
if [ -e "$tcp_6000_1" ];then
    tcp_6000_1_tmp=`cat /etc/X11/xinit/xserverrc |grep '\-nolisten tcp'`
    if [ -n "$tcp_6000_1_tmp" ];then
        echo "禁止X server监听6000/TCP端口。满足要求" >> out.txt
    else
        echo '禁止X server监听6000/TCP端口配置不符合要求，是否立即设置：(Y/N):'
        read user_num_YorN_re
        temp=`echo ${user_num_YorN_re} | grep Y`
        temp1=`echo ${user_num_YorN_re} | grep y`
        if [ "$temp" != "" -o "$temp1" != "" ];then
            cp  /etc/X11/xdm/Xservers /etc/X11/xdm/Xservers_bak
            cp  /etc/X11/xinit/xserverrc /etc/X11/xinit/xserverrc_bak
            tcp_6000_tmp_2=`cat /etc/X11/xdm/Xservers |grep '\:0'`
            if [ -n "$tcp_6000_tmp_2" ];then
                sed -i '/\:0/X/a -nolisten tcp' /etc/X11/xinit/xserverrc
            else
                echo ":0 -nolisten tcp" >> /etc/X11/xinit/xserverrc
            fi
            echo "禁止X server监听6000/TCP端口配置完成" >> out.txt
        fi
    fi
else
    echo "/etc/X11/xinit/xserverrc文件不存在" >>out.txt
fi

#修改可疑的SUID/SGID文件（后面弄）
#1.7.7
echo "#####################修改可疑的SUID/SGID文件####################################" >> out.txt

#设置系统banner（ok）
system_banner='/etc/rc.d/rc.local'
if [ -e "$system_banner" ];then
    system_banner_tmp_1=`more /etc/rc.d/rc.local | grep '#This will overwrite'`
    if [ ! -n "$system_banner_tmp_1" ];then
        echo '设置系统banner信息中，This will overwrite不符合要求，是否立即设置：(Y/N):'
        read user_num_YorN_re
        temp=`echo ${user_num_YorN_re} | grep Y`
        temp1=`echo ${user_num_YorN_re} | grep y`
        if [ "$temp" != "" -o "$temp1" != "" ];then
            sed -i '/This will overwrite/s/^/#/g' /etc/rc.d/rc.local
            echo "#This will overwrite /etc/issue at every boot. So, make any changes you want to make to /etc/issue here or you will lose them when you reboot." >> /etc/rc.d/rc.local
            echo "设置系统banner信息中，This will overwrite配置完成" >> out.txt
        fi
    fi
    
    system_banner_tmp_2=`more /etc/rc.d/rc.local | grep '#echo "" > /etc/issue'`
    if [ ! -n "$system_banner_tmp_2" ];then
        echo '设置系统banner信息中，echo \"\" > /etc/issue不符合要求，是否立即设置：(Y/N):'
        read user_num_YorN_re
        temp=`echo ${user_num_YorN_re} | grep Y`
        temp1=`echo ${user_num_YorN_re} | grep y`
        if [ "$temp" != "" -o "$temp1" != "" ];then
            sed -i '/echo "" > \/etc\/issue/s/^/#/g' /etc/rc.d/rc.local
            echo "#echo \"\" > /etc/issue" >> /etc/rc.d/rc.local
            echo "设置系统banner信息中，echo "" > /etc/issue配置完成" >> out.txt
        fi
    fi
    
    system_banner_tmp_3=`more /etc/rc.d/rc.local | grep '#echo "$R" >> /etc/issue'`
    if [ ! -n "$system_banner_tmp_3" ];then
        echo '设置系统banner信息中，echo "$R" >> /etc/issue不符合要求，是否立即设置：(Y/N):'
        read user_num_YorN_re
        temp=`echo ${user_num_YorN_re} | grep Y`
        temp1=`echo ${user_num_YorN_re} | grep y`
        if [ "$temp" != "" -o "$temp1" != "" ];then
            sed -i '/echo "$R" >> \/etc\/issue/s/^/#/catg' /etc/rc.d/rc.local
            echo "#echo \"\$R\" >> /etc/issue"  >> /etc/rc.d/rc.local
            echo "设置系统banner信息中，echo "$R" >> /etc/issue配置完成" >> out.txt
        fi
    fi
    
    system_banner_tmp_4=`more /etc/rc.d/rc.local | grep 'Kernel $(uname -r)'`
    if [ ! -n "$system_banner_tmp_4" ];then
        echo '设置系统banner信息中，echo "Kernel $(uname -r)不符合要求，是否立即设置：(Y/N):'
        read user_num_YorN_re
        temp=`echo ${user_num_YorN_re} | grep Y`
        temp1=`echo ${user_num_YorN_re} | grep y`
        if [ "$temp" != "" -o "$temp1" != "" ];then
            sed -i '/echo "Kernel $(uname -r)/s/^/#/g' /etc/rc.d/rc.local
            echo "#echo 'Kernel \$(uname -r) on \$a \$(uname -m)' >> /etc/issue" >> /etc/rc.d/rc.local
            echo "设置系统banner信息中，echo 'Kernel $(uname -r)配置完成" >> out.txt
        fi
    fi
    
    system_banner_tmp_5=`more /etc/rc.d/rc.local | grep '#cp -f /etc/issue'`
    if [ ! -n "$system_banner_tmp_5" ];then
        echo '设置系统banner信息中，cp -f /etc/issue不符合要求，是否立即设置：(Y/N):'
        read user_num_YorN_re
        temp=`echo ${user_num_YorN_re} | grep Y`
        temp1=`echo ${user_num_YorN_re} | grep y`
        if [ "$temp" != "" -o "$temp1" != "" ];then
            sed -i '/cp -f \/etc\/issue/s/^/#/g' /etc/rc.d/rc.local
            echo "#cp -f /etc/issue /etc/issue.net " >> /etc/rc.d/rc.local
            echo "设置系统banner信息中，cp -f /etc/issue配置完成" >> out.txt
        fi
    fi  
    
    system_banner_tmp_6=`more /etc/rc.d/rc.local | grep '#echo >> /etc/issue'`
    if [ ! -n "$system_banner_tmp_6" ];then
        echo '设置系统banner信息中，echo >> /etc/issue不符合要求，是否立即设置：(Y/N):'
        read user_num_YorN_re
        temp=`echo ${user_num_YorN_re} | grep Y`
        temp1=`echo ${user_num_YorN_re} | grep y`
        if [ "$temp" != "" -o "$temp1" != "" ];then
            sed -i '/echo >> \/etc\/issue/s/^/#/g' /etc/rc.d/rc.local
            echo "#echo >> /etc/issue" >> /etc/rc.d/rc.local
            echo "设置系统banner信息中，echo >> /etc/issue配置完成" >> out.txt
        fi
    fi  
    mv /etc/issue /etc/issue.bak 
    mv /etc/issue.net /etc/issue.net.bak 
    rm /etc/issue
    rm /etc/issue.net
    echo "设置系统banner配置完成" >> out.txt
fi


#安装最新的OS补丁（ok）
echo "################################################################################" >> out.txt
echo "请自行判断系统是否是最新版本" >>out.txt
echo `uname -a` >>out.txt
echo "最新版本:RedHat Linux：http://www.redhat.com/support/errata/" >>out.txt
echo "最新版本:Slackware Linux：ftp://ftp.slackware.com/pub/slackware/" >>out.txt
echo "最新版本:SuSE Linux：http://www.suse.com/us/support/security/index.html" >>out.txt
echo "最新版本:TurboLinux：http://www.turbolinux.com/security/" >>out.txt
echo "#################################################################################" >> out.txt

