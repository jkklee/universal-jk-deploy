#!/bin/sh
# jenkins机器上作通过git来集中管理nginx配置文件, 所有生产环境nginx的配置均由此同步过去
# 额外好处, 可做限制只有干净的git目录才能同步至远程, 强制规范nginx配置文件的修改

usage() {
    echo "Usage:"
    echo -e "  `basename $0`  upstream_name  nginx_group action nginx_group_conf\n"
    #echo "  upstream_name:         nginx的upstream.conf中配置的upstream名"
    echo "  nginx_hosts_group:        对应的nginx(组,单台,多台[按照ansible规则写,去掉空格]), 该值应和ansible的hosts文件中配置的一致"
    #echo "  action:                  执行动作(kickout: 将服务从后端集群踢除; rejoin: 将踢除的服务重新加入后端集群)"
    #echo "  host:                    待操作的业务机的IP/主机名"
    #echo "  port:                    业务端口(通过host:port定位upstream.conf中的一个后端服务)"
    echo "  nginx_upstream_conf_local:   nginx配置文件在本地的主目录(/xxx/xxx/conf)"
    echo "  nginx_upstream_conf_remote:  远程nginx配置文件主目录(/xxx/xxx/conf)"
    exit 1
}
[ $# -ne 4 ] && usage

#导入公共函数
script_path=$(dirname "${BASH_SOURCE[0]}")
source $script_path/base.sh

#-----自定义各nginx集群配置在本机的目录-----#
#declare -A NGINX_CONF
#NGINX_CONF["zy_nginx"]="/op-work/nginx_conf/zy_nginx/conf"
#NGINX_CONF["ny_nginx"]="/op-work/nginx_conf/ny_nginx/conf"
#[ -z ${NGINX_CONF[$2]}] && color_echo "nginx-group: [$2] has not configured in [$0]" && exit 1


nginx_hosts_group=$1  #这个取值要对应上ansible的hosts文件中的分组
#action=$2
nginx_upstream_conf_local=$2
nginx_upstream_conf_local_tmp=$3
nginx_upstream_conf_remote=$4
#host=$3
#port=$4

#if [ "$action" == "kickout" ];then  #踢出
#    log_cmd 'sed -i "s/\(server[ ]\+$host:$port\)/#auto_comment#\1/" $nginx_upstream_conf_local'
#elif [ "$action" == "rejoin" ];then  #重新加入
#    log_cmd 'sed -i "s/#auto_comment#\(server[ ]\+$host:$port\)/\1/" $nginx_upstream_conf_local'
#else
#    echo "----- Wrong action -----" && usage
#fi
    
diff $nginx_upstream_conf_local $nginx_upstream_conf_local_tmp
if [ $? -ne 0 ];then
    log_cmd "ansible $nginx_hosts_group -m copy -a 'src=$nginx_upstream_conf_local dest=$nginx_upstream_conf_remote'"
    log_cmd "ansible $nginx_hosts_group -m shell -a 'nginx -t && nginx -s reload'"
fi

##通过一个给定的upstream名, 得出其在upstream.conf中所配置的 [主机:端口]
# 用awk去除两行之间的内容
#filter="awk '/^[ ]*upstream[ ]+"$upstream_name"/,/^[ ]*}/ {print}' /usr/local/services/tengine/conf/upstream.conf"
#hosts_ports=$(bash -c "$filter" | egrep "[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}:[0-9]+" | egrep -v "^[ ]*#" | awk '{print $2}')
#        
#for h_p in `echo $hosts_ports`;do
#    if [ "$action" == "kickout" ];then  #踢出
#        sed -i "s/\(server[ ]\+$h_p\)/#auto_comment#\1/" $upstream_conf
#    elif [ "$action" == "rejoin" ];then  #重新加入
#        sed -i "s/#auto_comment#\(server[ ]\+$h_p\)/\1/" $upstream_conf
#    else
#        color_echo "----- Wrong action -----" && usage
#    fi
#    ansible $nginx_group -m copy -a "src=$upstream_conf dest=$nginx_group_conf_path/"
#    ansible $nginx_group -m shell -a "nginx -t && nginx -s reload"
#done
