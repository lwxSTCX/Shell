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
		rpm -e subversion
		rpm -e subversion-libs
		rpm -e libsss_nss_idmap --nodeps
		rpm -e libsss_idmap --nodeps
		rpm -e samba
		rpm -e samba-common-tools
		rpm -e samba-common-libs
		rpm -e samba-client-libs --nodeps
		rpm -e samba-common
		rpm -e samba-libs
		rpm -e perl-Git --nodeps
		rpm -e intltool
		rpm -e git --nodeps
		rpm -e doxygen
		rpm -e xdg-utils 
		rpm -e desktop-file-utils 
		rpm -e emacs-filesystem
		rpm -e bind-utils
		rpm -e bind-libs
		for delete_rpm in $checks
		do
			rpm -e $delete_rpm
			if [ $? -eq 0 ];then
				echo "组件已删除："$delete_rpm | tee -a out.txt
			fi
		done
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
		bash ./delete.sh
	fi
fi

