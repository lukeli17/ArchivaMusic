#!/bin/zsh

cd "${0:A:h}" || exit 1
./scripts/archiva-dev.sh menu

print ""
read -r "?管理菜单已退出，按回车关闭窗口："
