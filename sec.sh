#!/bin/bash
#测试系统centos7
#下周不用的包全部一起删完
#WPA/WPA2
echo -e "\033[32m #########################开始检测#################\033[0m"
echo "当前用户为："`whoami`
echo "当前用户为："`whoami` >> out.txt
echo "当前时间为："`date  "+%F %T"`
echo "当前时间为："`date  "+%F %T"` >> out.txt
echo "检测WPA/WPA2是否存在......"
wpa=`rpm -qa|grep ^wpa`
if [ ! -n "$wpa"  ];then
    echo "系统中不存在WPA/WPA2组件，符合要求"
    echo "系统中不存在WPA/WPA2组件，符合要求">>out.txt
else
    echo "系统中存在WPA/WPA2组件，可能存在漏洞"
	echo -e "\033[31m提示：WPA/WPA2组件被NetworkManager网络相关组件依赖，请确认是否强制删除(Y/N)：\033[0m"
    read user_num_YorN_re
    temp=`echo ${user_num_YorN_re} | grep Y`
    temp1=`echo ${user_num_YorN_re} | grep y`
    if [ "$temp" != "" -o "$temp1" != "" ];then
		rpm -e wpa_supplicant --nodeps
        if [ $? -eq 0 ];then
			wpa_path=`whereis wpa_supplicant | awk -F: '{ print $2 }' | awk -F' ' '{ print $1 }'`
			if [ -d "$wpa_path" ];then
				rm -rf $wpa_path
			fi
            echo "WPA/WPA2组件删除成功"
            echo "WPA/WPA2组件删除成功" >>out.txt
        fi
    fi
fi

#rsyslog
echo "检测rsyslog是否存在......"
rsyslog=`rpm -qa|grep ^rsyslog`
if [ ! -n "$rsyslog"  ];then
    echo "系统中不存在rsyslog组件，符合要求"
    echo "系统中不存在rsyslog组件，符合要求">>out.txt
else
    echo -e "\033[32m系统中存在rsyslog组件，可能存在漏洞，是否删除(Y/N)：\033[0m"
    read user_num_YorN_re
    temp=`echo ${user_num_YorN_re} | grep Y`
    temp1=`echo ${user_num_YorN_re} | grep y`
    if [ "$temp" != "" -o "$temp1" != "" ];then
        rpm -e rsyslog
        if [ $? -eq 0 ];then
			rsyslog_path=`whereis rsyslog | awk -F: '{ print $2 }' | awk -F' ' '{ print $1 }'`
			if [ -d "$rsyslog_path" ];then
				rm -rf $rsyslog_path
			fi
            echo "rsyslog组件删除成功"
            echo "rsyslog组件删除成功" >>out.txt
        fi
    fi
fi

#patch
echo "检测patch是否存在......"
patch=`rpm -qa| grep -v "util" |grep ^patch`
if [ ! -n "$patch"  ];then
    echo "系统中不存在patch组件，符合要求"
    echo "系统中不存在patch组件，符合要求">>out.txt
else
    echo "系统中存在patch组件，可能存在漏洞"
	echo -e "\033[31m提示：patch组件被rpm-build组件依赖，可能会造成无法bulid rpm包，请确认是否强制删除(Y/N)：\033[0m"
    read user_num_YorN_re
    temp=`echo ${user_num_YorN_re} | grep Y`
    temp1=`echo ${user_num_YorN_re} | grep y`
    if [ "$temp" != "" -o "$temp1" != "" ];then
		rpm -e intltool 
		rpm -e rpm-build
		rpm -e patch
        if [ $? -eq 0 ];then
            echo "patch组件删除成功"
            echo "patch组件删除成功" >>out.txt
        fi
    fi
fi

#blktrace
echo "检测blktrace是否存在......"
blktrace=`rpm -qa|grep ^blktrace`
if [ ! -n "$blktrace"  ];then
    echo "系统中不存在blktrace组件，符合要求"
    echo "系统中不存在blktrace组件，符合要求">>out.txt
else
	echo -e "\033[32m系统中存在blktrace组件，可能存在漏洞，是否删除(Y/N)：\033[0m"
    read user_num_YorN_re
    temp=`echo ${user_num_YorN_re} | grep Y`
    temp1=`echo ${user_num_YorN_re} | grep y`
    if [ "$temp" != "" -o "$temp1" != "" ];then
        rpm -e blktrace
        if [ $? -eq 0 ];then
			blktrace_path=`whereis blktrace | awk -F: '{ print $2 }' | awk -F' ' '{ print $1 }'`
			if [ -d "$blktrace_path" ];then
				rm -rf $blktrace_path
			fi
            echo "blktrace组件删除成功"
            echo "blktrace组件删除成功" >>out.txt
        fi
    fi
fi

#subversion
echo "检测subversion是否存在......"
subversion=`rpm -qa|grep ^subversion`
if [ ! -n "$subversion"  ];then
    echo "系统中不存在subversion组件，符合要求"
    echo "系统中不存在subversion组件，符合要求">>out.txt
else
	echo -e "\033[32m系统中存在subversion组件，可能存在漏洞，是否删除(Y/N)：\033[0m"
    read user_num_YorN_re
    temp=`echo ${user_num_YorN_re} | grep Y`
    temp1=`echo ${user_num_YorN_re} | grep y`
    if [ "$temp" != "" -o "$temp1" != "" ];then
		rpm -e subversion
		rpm -e subversion-libs
        if [ $? -eq 0 ];then
			subversion_path=`whereis subversion | awk -F: '{ print $2 }' | awk -F' ' '{ print $1 }'`
			if [ -d "$subversion_path" ];then
				rm -rf $subversion_path
			fi
            echo "subversion组件删除成功"
            echo "subversion组件删除成功" >>out.txt
        fi
    fi
fi

#emacs
echo "检测emacs是否存在......"
emacs=`rpm -qa|grep ^emacs`
if [ ! -n "$emacs"  ];then
    echo "系统中不存在emacs组件，符合要求"
    echo "系统中不存在emacs组件，符合要求">>out.txt
else
    echo "系统中存在emacs组件，可能存在漏洞"
	echo -e "\033[31m提示：emacs组件被桌面文件及索引文件组件依赖，请确认是否强制删除(Y/N)：\033[0m"
    read user_num_YorN_re
    temp=`echo ${user_num_YorN_re} | grep Y`
    temp1=`echo ${user_num_YorN_re} | grep y`
    if [ "$temp" != "" -o "$temp1" != "" ];then
		rpm -e cscope
		rpm -e pinfo
		rpm -e xdg-utils 
		rpm -e desktop-file-utils 
		rpm -e emacs-filesystem
        if [ $? -eq 0 ];then
			emacs_tmp=`whereis emacs | awk -F: '{ print $2 }' | awk -F' ' '{ print $1 }'`
			if [ ! -d "$emacs_tmp" ];then
				rm -rf $emacs_tmp
			fi
            echo "emacs组件删除成功"
            echo "emacs组件删除成功" >>out.txt
        fi
    fi
fi

#doxygen
echo "检测doxygen是否存在......"
doxygen=`rpm -qa|grep ^doxygen`
if [ ! -n "$doxygen"  ];then
    echo "系统中不存在doxygen组件，符合要求"
    echo "系统中不存在doxygen组件，符合要求">>out.txt
else
    echo -e "\033[32m系统中存在doxygen组件，可能存在漏洞，是否删除(Y/N)：\033[0m"
    read user_num_YorN_re
    temp=`echo ${user_num_YorN_re} | grep Y`
    temp1=`echo ${user_num_YorN_re} | grep y`
    if [ "$temp" != "" -o "$temp1" != "" ];then
        rpm -e doxygen
        if [ $? -eq 0 ];then
			doxygen_path=`whereis doxygen | awk -F: '{ print $2 }' | awk -F' ' '{ print $1 }'`
			if [ -d "$doxygen_path" ];
				rm -rf $doxygen_path
			fi
            echo "doxygen组件删除成功"
            echo "doxygen组件删除成功" >>out.txt
        fi
    fi
fi

#corosync（与下面那个有联系）
echo "检测corosync是否存在......"
corosync=`rpm -qa|grep ^corosync`
if [ ! -n "$corosync"  ];then
    echo "系统中不存在corosync组件，符合要求"
    echo "系统中不存在corosync组件，符合要求">>out.txt
else
    echo "系统中存在corosync组件，可能存在漏洞"
	echo -e "\033[31m提示：corosync组件被集群相关组件依赖，请确认是否强制删除(Y/N)：\033[0m"	
    read user_num_YorN_re
    temp=`echo ${user_num_YorN_re} | grep Y`
    temp1=`echo ${user_num_YorN_re} | grep y`
    if [ "$temp" != "" -o "$temp1" != "" ];then
		rpm -e corosync --nodeps
		rpm -e corosynclib --nodeps
        if [ $? -eq 0 ];then
            echo "corosync组件删除成功"
            echo "corosync组件删除成功" >>out.txt
        fi
    fi
fi

#net-snmp（后面看）
echo "检测net-snmp是否存在......"
snmp=`rpm -qa|grep ^net-snmp`
if [ ! -n "$snmp"  ];then
    echo "系统中不存在net-snmp组件，符合要求"
    echo "系统中不存在net-snmp组件，符合要求">>out.txt
else
    echo "系统中存在net-snmp组件，可能存在漏洞"
	echo -e "\033[31m提示：net-snmp组件被管理与监控服务器相关组件依赖，请确认是否强制删除(Y/N)：\033[0m"	
    read user_num_YorN_re
    temp=`echo ${user_num_YorN_re} | grep Y`
    temp1=`echo ${user_num_YorN_re} | grep y`
    if [ "$temp" != "" -o "$temp1" != "" ];then
		rpm -e  net-snmp-libs --nodeps
        if [ $? -eq 0 ];then
            echo "net-snmp组件删除成功"
            echo "net-snmp组件删除成功" >>out.txt
        fi
    fi
fi

#sssd(还有漏洞)
echo "检测sssd是否存在......"
sssd=`rpm -qa|grep ^sssd`
if [ ! -n "$sssd"  ];then
    echo "系统中不存在sssd组件，符合要求"
    echo "系统中不存在sssd组件，符合要求">>out.txt
else
    echo -e "\033[32m系统中存在sssd组件，可能存在漏洞，是否删除(Y/N)：\033[0m"
    read user_num_YorN_re
    temp=`echo ${user_num_YorN_re} | grep Y`
    temp1=`echo ${user_num_YorN_re} | grep y`
    if [ "$temp" != "" -o "$temp1" != "" ];then
		rpm -e sssd-client
        if [ $? -eq 0 ];then
            echo "sssd组件删除成功"
            echo "sssd组件删除成功" >>out.txt
        fi
    fi
fi

#jasper-libs
echo "检测jasper-libs是否存在......"
jasper=`rpm -qa|grep ^jasper`
if [ ! -n "$jasper"  ];then
    echo "系统中不存在jasper组件，符合要求"
    echo "系统中不存在jasper组件，符合要求">>out.txt
else
    echo "系统中存在jasper组件，可能存在漏洞"
	echo -e "\033[31m提示：jasper-libs组件被提供综合报告，数据分析和数据集成功能相关组件依赖，请确认是否强制删除(Y/N)：\033[0m"	
    read user_num_YorN_re
    temp=`echo ${user_num_YorN_re} | grep Y`
    temp1=`echo ${user_num_YorN_re} | grep y`
    if [ "$temp" != "" -o "$temp1" != "" ];then
		rpm -e fprintd-pam
		rpm -e fprintd
		rpm -e libfprint
		rpm -e gdk-pixbuf2
		rpm -e jasper-libs
        if [ $? -eq 0 ];then
			if [ ! -n '$jasper' ];then
				jasper_path=`whereis jasper | awk -F: '{ print $2 }' | awk -F' ' '{ print $1 }'`
				if [ -d "$jasper_path" ];
					rm -rf $jasper_path
				fi
			fi
            echo "jasper-libs组件删除成功"
            echo "jasper-libs组件删除成功" >>out.txt
        fi
    fi
fi

#samba（还有漏洞）
echo "检测samba是否存在......"
samba=`rpm -qa|grep ^samba`
if [ ! -n "$samba"  ];then
    echo "系统中不存在samba组件，符合要求"
    echo "系统中不存在samba组件，符合要求">>out.txt
else
    echo "系统中存在samba组件，可能存在漏洞"
	echo -e "\033[31m提示：samba组件被libwbclient相关组件依赖，请确认是否强制删除(Y/N)：\033[0m"	
    read user_num_YorN_re
    temp=`echo ${user_num_YorN_re} | grep Y`
    temp1=`echo ${user_num_YorN_re} | grep y`
    if [ "$temp" != "" -o "$temp1" != "" ];then
		rpm -e samba
		rpm -e samba-common-tools
		rpm -e samba-common-libs
		rpm -e samba-client-libs --nodeps
		rpm -e samba-common
		rpm -e samba-libs
        if [ $? -eq 0 ];then
			if [ ! -n '$samba' ];then
				samba_path=`whereis samba | awk -F: '{ print $2 }' | awk -F' ' '{ print $1 }'`
				if [ -d "$samba_path" ];
					rm -rf $samba_path
				fi
			fi
			echo "samba组件删除成功"
			echo "samba组件删除成功" >>out.txt
        fi
    fi
fi

#git
echo "检测git是否存在......"
git=`rpm -qa|grep ^git`
if [ ! -n "$git"  ];then
    echo "系统中不存在git组件，符合要求"
    echo "系统中不存在git组件，符合要求">>out.txt
else
    echo "系统中存在git组件，可能存在漏洞"
	echo -e "\033[31m提示：git组件被libwbclient相关组件依赖，请确认是否强制删除(Y/N)：\033[0m"	
    read user_num_YorN_re
    temp=`echo ${user_num_YorN_re} | grep Y`
    temp1=`echo ${user_num_YorN_re} | grep y`
    if [ "$temp" != "" -o "$temp1" != "" ];then
		rpm -e perl-Git --nodeps
		rpm -e intltool
		#rpm -e gettext-devel
		rpm -e git --nodeps
		if [ $? -eq 0 ];then
			if [ ! -n '$git' ];then
				git_path=`whereis git | awk -F: '{ print $2 }' | awk -F' ' '{ print $1 }'`
				if [ -d "$git_path" ];
					rm -rf $git_path
				fi
			fi
			echo "git组件删除成功"
			echo "git组件删除成功" >>out.txt
		fi
    fi
fi




