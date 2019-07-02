#!/bin/bash

#导入公共函数
script_path=$(dirname "${BASH_SOURCE[0]}")
source $script_path/base.sh

#backup_dir的处理要慎重,因为涉及到删除动作(删除旧备份)
if [ ! -z $repository ];then
    project_name=`echo $repository | awk -F'[:/.]' '{print $(NF-1)}'`
else
    echo "Required param 'repository'"; exit 10
fi
if [ -d "$base_backup_dir" ];then
    [ ! -e $base_backup_dir/$project_name ] && mkdir $base_backup_dir/$project_name
    export backup_dir=$base_backup_dir/$project_name
else
    echo "Required param 'base_backup_dir' not set or it's not a directory"; exit 10
fi


###(空字符串无法作为playbook的外部变量文件中的值)在playbook中使用被置空的变量前要做转换
#对下面两个进行处理是为了在下文用一条命令兼容三种情况: 文件构建物/目录构建物/不需要构建
[ -z $package_name ] && export package_name='/'
[ -z $build_target ] && export build_target='.'

#判断是否指定了upstream.conf文件,并保证local和remote同时存在或不存在
if [[ ! $nginx_upstream_conf_local ]] && [[ $nginx_upstream_conf_remote ]] || [[ $nginx_upstream_conf_local ]] && [[ ! $nginx_upstream_conf_remote ]];then
    echo "Error: 'nginx_upstream_conf_local' and 'nginx_upstream_conf_remote' must both presence or not"; exit 10
fi
    

#单例执行
#[ "${FLOCKER}" != "$project_name-$branch" ] && flock -en "/tmp/$project_name-$branch" "$0" "$@" || :


if [ $action == "deploy" ];then
    #更新代码
    [ -d "$workspace/.git" ] && update_code $workspace $branch || update_code_the_first_time $workspace $repository $branch
    if [ $package_name != "/" ];then 
        #构建
        build_pkg
    fi
    backup
    clean_backup_dir 30
    
    src=$workspace/$build_target/$package_name
else  #回滚
    if [ -f "$backup_dir/$rollback_version" ];then
        src=$backup_dir/$rollback_version
    elif [ -d "$backup_dir/$rollback_version" ];then
        src=$backup_dir/$rollback_version/
    fi
fi

#设置playbook的jenkins_var_files,供后续playbook使用
jenkins_var_files="$workspace/.jenkins_var_files.yml"
echo "dest_hosts: $dest_hosts" > $jenkins_var_files
echo "project_port: $project_port" >> $jenkins_var_files
[ -n "$nginx_hosts_group" ] &&  echo "nginx_hosts_group: $nginx_hosts_group" >> $jenkins_var_files
[ -n "$nginx_upstream_conf_remote" ] && echo "nginx_upstream_conf_remote: $nginx_upstream_conf_remote" >> $jenkins_var_files
[ -n "$nginx_upstream_conf_local" ] && echo "nginx_upstream_conf_local: $nginx_upstream_conf_local" >> $jenkins_var_files
[ -n "$start_command" ] && echo "start_command: $start_command" >> $jenkins_var_files
[ -n "$stop_command" ] && echo "stop_command: $stop_command" >> $jenkins_var_files
echo "script_path: $script_path" >> $jenkins_var_files
echo "check_url: $check_url" >> $jenkins_var_files
echo "check_url_interval: `[ -n $check_url_interval ] && echo $check_url_interval || echo 5`" >> $jenkins_var_files
echo "check_url_retries: `[ -n $check_url_timeout ] && echo $((check_url_timeout/$check_url_interval)) || echo 15`" >> $jenkins_var_files
echo "src: $src" >> $jenkins_var_files
echo "dest: $dest_dir/$package_name" >> $jenkins_var_files
echo "batch: $batch" >> $jenkins_var_files
echo "run_user: $run_user" >> $jenkins_var_files
echo "dest_env: $dest_env" >> $jenkins_var_files
echo "project_name: $project_name" >> $jenkins_var_files

#滚动部署
log_cmd "ansible-playbook $script_path/steps_of_deploy_one.yml --extra-vars \"@$workspace/.jenkins_var_files.yml\""

