#!/bin/bash
#$1: 该项目在jenkins的workspace中的目录
#$2: gitlab上的仓库地址

#project=`echo $2|awk -F'[/ .]' '{print $(NF-1)}'`
[[ -d "$1/.git" ]] || git clone $2 $1
cd $1
git pull>/dev/null
git remote update origin --prune &>/dev/null
for b in $(git branch -r|grep -v HEAD);do 
    echo $(git show --pretty=format:'%ct  %an  %s' $b|head -n 1) ${b#origin/}
done|sort -rn -k 1|awk '{print $NF}'|head -10