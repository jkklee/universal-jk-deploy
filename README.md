## universal-jk-deploy
此项目的初衷是基于**Jenkins**和**Ansible**提供一套能兼容大多数应用场景的部署方案，提供一个统一的“配置界面”来完成大多数项目的部署工作，而无需关注底层脚本的实现。

具体一点来讲：将打包或编译，服务的启停，服务在反向代理的摘除和重新加入等操作在底层脚本中予以组合，但是底层脚本不涉及到具体的服务启停命令或取值等，只提供逻辑框架。而描述项目部署的各种信息均在jenkins作业的配置界面中予以设置（这是在Jenkins中设置部署作业的最外层也是最直接看到的地方）。

### 依赖
当然是Jenkins和Ansible

### 大致可以将应用部署分为两类
1. 经过反向代理的后端服务，例如：java或者python以及php等  
流程：从反向代理中踢除待更新后端 ----> 关闭后端 ----> 更新代码 ----> 启动后端 ----> url探活 ----> 后端重新加入反向代理
2. 不经过反向代理，静态文件或者通过npm打包生成静态文件的项目  
流程：关闭后端[可选] ----> 更新代码 ----> 启动后端[可选]

注：本套脚本目前仅支持采用nginx作为反向代理的场景

### 示例:
先来看一下部署界面  
![deploy-image](https://s2.51cto.com/images/20200322/1584862091865703.png)

下面是一个以jar包运行并经过nginx反向代理的java应用在jenkins上通过此套脚本的配置示例  
示例中将本套脚本的父目录定为了“/op-work/deploy/scripts”
1. 由于脚本中包含了编译打包等逻辑，所以这里只需要创建“**自由风格的软件项目**”即可
2. 接下来为构建增加参数，下图是`dest_env`和`branch`参数部分
    ![参数化构建过程](https://s2.51cto.com/images/20200322/1584862132311813.png)
3. 接下来是`action`和`batch`以及`rollback_version`参数示例
    ![action](https://s2.51cto.com/images/20200322/1584862142943339.png)
    ![batch](https://s2.51cto.com/images/20200322/1584862148256936.png)
    ![rollback](https://s2.51cto.com/images/20200322/1584862158607534.png)
4. 接下来是**主要部分**，直接跳到Jenkins作业设置界面的`Build`部分，选择`执行shell`。这里也即上文体到的“配置界面”，该项目的目标是将（描述一次项目部署）所有变的东西都定义在此处。
    ```
    # 远程仓库名
    export repository="git@gitlab.xxxxx.com:my_group/my_project.git"
    # 构建物是单个包文件的取文件名; 不是单文件的以及不需打包的[可置空]
    export package_name="my_project.jar"
    # 构建工具生成的存放构建物的目录(相对于项目根目录),可为'.'; 不需要构建[可置空]
    export build_target="target"
    # 打包命令,不需要打包的置空(目录上下文关系由下层脚本处理)[可置空]
    export build_cmd="mvn clean package -B -P $dest_env"
    # 程序或者web服务器监听的端口
    export project_port=8888
    # 远程目录: 需要打包的为包文件(或包目录)的父目录; 不需要打包的,为项目根目录
    export dest_dir="/usr/local/my_project/"
    # ansible inventory文件中该服务的反向代理nginx主机(组,按ansible中提供主机的方式)[可置空]
    export nginx_hosts_group="nginx01,nginx02"
    # nginx_upstream配置文件在本地和目标nginx的位置, 没用到upstream的(即单台后端)的[可置空]
    export nginx_upstream_conf_local=/op-work/nginx_conf/upstream.conf
    export nginx_upstream_conf_remote=/usr/local/nginx/conf/upstream.conf
    # 备份的主目录(下级目录为项目名, 由程序自动添加)
    export base_backup_dir="/op-work/deploy/package_backup"
    # 停止和启动后端服务的命令及运行用户,不需要重启后端的(如静态页面等)[可置空]
    export stop_command="\"pid=\$(ps aux | grep $package_name | grep -v grep | awk '{print \$2}');[[ -n \$pid ]] && kill \$pid && sleep 10 || /bin/true\""
    export start_command="nohup java -Xmx512M -Xms512M -jar $dest_dir/$package_name &> $dest_dir/stdout.log &"
    export run_user="work"
    # 探活url,确保后端能正常响应后再将其加回nginx upstream中
    export check_url="/isok"
    export check_url_timeout=30
    export check_url_interval=3

    # 来自jenkins的变量
    export dest_env
    export action
    export batch
    export workspace=$WORKSPACE
    export branch=$(echo $branch|sed 's/"//g')
    export rollback_version=$(echo $rollback_version|sed 's/"//g')

    # 根据构建参数灵活设定相关参数(对应的主机/组,按ansible中提供主机的方式)
    if [ "$dest_env" == "pro" ];then
        export dest_hosts="app01,app02"
    elif [ "$dest_env" == "pre" ];then
        export dest_hosts="app-pre"
    fi

    sh /op-work/deploy/scripts/main.sh
    ```
5. [可选]在`Post-build Actions`部分或者在第4步脚本的最后，可以增加发送更新通知的逻辑
