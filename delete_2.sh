#!/bin/bash
#测试系统centos7
#将需要卸载的包一起卸载完
echo -e "\033[32m ######################################开始检测###################################\033[0m" | tee -a out.txt
echo "当前用户为："`whoami` | tee -a out.txt
echo "当前时间为："`date  "+%F %T"` | tee -a out.txt

checks=`rpm -qa | egrep -v "utils|bind-libs-lite|rpm-build-libs" | egrep "rsyslog|bind-utils|bind-libs|intltool|rpm-build|^patch|fprintd-pam|fprintd|libfprint|gdk-pixbuf2|blktrace|subversion-libs|subversion|libsss_nss_idmap|libsss_idmap|cscope|pinfo|xdg-utils|desktop-file-utils|emacs-filesystem|samba|samba-common-tools|samba-common-libs|samba-client-libs|samba-common|fprintd-pam|fprintd|libfprint|gdk-pixbuf2|jasper-libs|perl-Git|intltool|^git|doxygen"`

if [ ! -n "$checks"  ];then
    echo "系统中不存在危险组件，符合要求" | tee -a out.txt
else
	for check in $checks
	do
		echo "存在危险的组件为："$check | tee -a out.txt
	done

	echo -e "\033[31m请确认是否删除以上存在漏洞的组件(Y/N)：\033[0m" | tee -a out.txt
    read user_num_YorN_re
    temp=`echo ${user_num_YorN_re} | grep Y`
    temp1=`echo ${user_num_YorN_re} | grep y`
    if [ "$temp" != "" -o "$temp1" != "" ];then
		rpm -e rsyslog
		if [ $? -eq 0 ];then
			echo "删除组件：rsyslog" | tee -a out.txt
		fi
		rpm -e subversion
		if [ $? -eq 0 ];then
			echo "删除组件：subversion" | tee -a out.txt
		fi
		rpm -e subversion-libs
		if [ $? -eq 0 ];then
			echo "删除组件：subversion-libs" | tee -a out.txt
		fi
		rpm -e libsss_nss_idmap --nodeps
		if [ $? -eq 0 ];then
			echo "删除组件：libsss_nss_idmap" | tee -a out.txt
		fi
		rpm -e libsss_idmap --nodeps
		if [ $? -eq 0 ];then
			echo "删除组件：libsss_idmap" | tee -a out.txt
		fi
		rpm -e samba
		if [ $? -eq 0 ];then
			echo "删除组件：samba" | tee -a out.txt
		fi
		rpm -e samba-common-tools
		if [ $? -eq 0 ];then
			echo "删除组件：samba-common-tools" | tee -a out.txt
		fi
		rpm -e samba-common-libs
		if [ $? -eq 0 ];then
			echo "删除组件：samba-common-libs" | tee -a out.txt
		fi
		rpm -e samba-client-libs --nodeps
		if [ $? -eq 0 ];then
			echo "删除组件：samba-client-libs" | tee -a out.txt
		fi
		rpm -e samba-common
		if [ $? -eq 0 ];then
			echo "删除组件：samba-common" | tee -a out.txt
		fi
		rpm -e samba-libs
		if [ $? -eq 0 ];then
			echo "删除组件：samba-libs" | tee -a out.txt
		fi
		rpm -e perl-Git --nodeps
		if [ $? -eq 0 ];then
			echo "删除组件：perl-Git" | tee -a out.txt
		fi
		rpm -e intltool
		if [ $? -eq 0 ];then
			echo "删除组件：intltool" | tee -a out.txt
		fi
		rpm -e git --nodeps
		if [ $? -eq 0 ];then
			echo "删除组件：git" | tee -a out.txt
		fi
		rpm -e doxygen
		if [ $? -eq 0 ];then
			echo "删除组件：doxygen" | tee -a out.txt
		fi
		rpm -e cscope
		if [ $? -eq 0 ];then
			echo "删除组件：cscope" | tee -a out.txt
		fi
		rpm -e pinfo
		if [ $? -eq 0 ];then
			echo "删除组件：pinfo" | tee -a out.txt
		fi
		rpm -e xdg-utils 
		if [ $? -eq 0 ];then
			echo "删除组件：xdg-utils " | tee -a out.txt
		fi
		rpm -e desktop-file-utils 
		if [ $? -eq 0 ];then
			echo "删除组件：desktop-file-utils " | tee -a out.txt
		fi
		rpm -e emacs-filesystem
		if [ $? -eq 0 ];then
			echo "删除组件：emacs-filesystem" | tee -a out.txt
		fi
		rpm -e bind-utils
		if [ $? -eq 0 ];then
			echo "删除组件：bind-utils" | tee -a out.txt
		fi
		rpm -e bind-libs
		if [ $? -eq 0 ];then
			echo "删除组件：bind-libs" | tee -a out.txt
		fi
		rpm -e intltool 
		if [ $? -eq 0 ];then
			echo "删除组件：intltool " | tee -a out.txt
		fi
		rpm -e rpm-build
		if [ $? -eq 0 ];then
			echo "删除组件：rpm-build" | tee -a out.txt
		fi
		rpm -e patch
		if [ $? -eq 0 ];then
			echo "删除组件：patch" | tee -a out.txt
		fi
		rpm -e fprintd-pam
		if [ $? -eq 0 ];then
			echo "删除组件：fprintd-pam" | tee -a out.txt
		fi
		rpm -e fprintd
		if [ $? -eq 0 ];then
			echo "删除组件：fprintd" | tee -a out.txt
		fi
		rpm -e libfprint
		if [ $? -eq 0 ];then
			echo "删除组件：libfprint" | tee -a out.txt
		fi
		rpm -e gdk-pixbuf2
		if [ $? -eq 0 ];then
			echo "删除组件：gdk-pixbuf2" | tee -a out.txt
		fi
		rpm -e blktrace
		if [ $? -eq 0 ];then
			echo "删除组件：blktrace" | tee -a out.txt
		fi
		rpm -e fprintd-pam
		if [ $? -eq 0 ];then
			echo "删除组件：fprintd-pam" | tee -a out.txt
		fi
		rpm -e fprintd
		if [ $? -eq 0 ];then
			echo "删除组件：fprintd" | tee -a out.txt
		fi
		rpm -e libfprint
		if [ $? -eq 0 ];then
			echo "删除组件：libfprint" | tee -a out.txt
		fi
		rpm -e gdk-pixbuf2
		if [ $? -eq 0 ];then
			echo "删除组件：gdk-pixbuf2" | tee -a out.txt
		fi
		rpm -e jasper-libs
		if [ $? -eq 0 ];then
			echo "删除组件：jasper-libs" | tee -a out.txt
		fi
    fi
	echo -e "\033[32m ###################################重新检测##########################################\033[0m" | tee -a out.txt
	checks_2=`rpm -qa | egrep -v "utils|bind-libs-lite|rpm-build-libs" | egrep "rsyslog|bind-utils|bind-libs|intltool|rpm-build|^patch|fprintd-pam|fprintd|libfprint|gdk-pixbuf2|blktrace|subversion-libs|subversion|libsss_nss_idmap|libsss_idmap|cscope|pinfo|xdg-utils|desktop-file-utils|emacs-filesystem|samba|samba-common-tools|samba-common-libs|samba-client-libs|samba-common|fprintd-pam|fprintd|libfprint|gdk-pixbuf2|jasper-libs|perl-Git|intltool|^git|doxygen"`
	if [ ! -n "$checks_2" ];then
		echo "危险组件已经全部删除" | tee -a out.txt
	else
		for check_2 in $checks_2
		do
			echo "存在未删除的组件："$check_2 | tee -a out.txt
		done
		echo "请重新确认组件及卸载命令"
	fi
	bash ./delete.sh
fi

