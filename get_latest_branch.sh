#!/bin/bash
# $1: jenkins的workspace目录
# $2: gitlab上的仓库地址

project=`echo $1|awk -F'[/ .]' '{print $(NF-1)}'`
[[ -d "$workspace/.git" ]] || git clone $1 $workspace
cd $1/$project
git pull>/dev/null
git remote update origin --prune &>/dev/null
for b in $(git branch -r|grep -v HEAD);do
    echo $(git show --pretty=format:'%ct  %an  %s' $b|head -n 1) ${b#origin/}
done|sort -rn -k 1|awk '{print $NF}'|head -10


