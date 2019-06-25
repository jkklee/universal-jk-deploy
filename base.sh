log_cmd() {
    #记录命令 --> 执行命令 --> 打印执行结果, [通过--msg参数支持额外消息]
    #usage: 命令原样跟在后面
    local msg
    if [ "$1" == "--msg" ];then
        msg=$2
        shift 2
    fi

    echo "-----$msg [$*]-----"
    eval $@
    status=$?
    if [ $status -ne 0 ];then
        echo "-----$msg [failure]-----"
        exit $status
    fi
}


# 更新代码
update_code() {
    echo -e "\n===== [${FUNCNAME[0]}] ====="
    log_cmd "cd $workspace && git checkout $branch"
    log_cmd git pull
    git remote prune origin
    echo
}


# 项目第一次添加至这套流程
update_code_the_first_time() {
    echo -e "\n===== [${FUNCNAME[0]}] ====="
    log_cmd git clone $repository $workspace
    log_cmd cd $workspace
    log_cmd git checkout $branch
    log_cmd git pull
    git remote prune origin
    echo
}
    

#打包
build_pkg() {
    echo -e "\n===== [${FUNCNAME[0]}] ====="
    log_cmd cd $workspace
    log_cmd --msg "构建" $build_cmd
    echo
}


backup() {
    echo -e "\n===== [${FUNCNAME[0]}] ====="
    mkdir $backup_dir 2>/dev/null
    log_cmd cp -a $workspace/$build_target/$package_name $backup_dir/`date +%Y%m%d-%H%M%S`_"$branch"_"$dest_env"_"$package_name"
    echo
}


#超过指定天数的备份予以清除
clean_backup_dir() {
    echo -e "\n===== [${FUNCNAME[0]}] ====="
    if [ $# -ne 1 ];then
        echo '----- [function usage error] should be: "clean_up_backup_dir  expire_days" -----'
        exit 10
    fi
    log_cmd "find $backup_dir -mtime +$1 | xargs rm -rf"
    echo
}
