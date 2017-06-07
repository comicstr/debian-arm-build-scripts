#!/bin/sh

if [ $# -eq 0 ]; then
	echo "请输入信息，e.g. $0 armel debian jessie ext3"
	exit 0
fi

# 定义信息
tools="debootstrap qemu-user-static"
basedir=$(pwd)/androidd-$2
architecture="$1"
name="$3-root"
base="locales vim zsh"
service="openssh-server"
mirror="ftp.cn.debian.org"

packages="${base} ${service}"

# 第一阶段
export LC_ALL=C

mkdir -p ${basedir} && cd ${basedir}

debootstrap --foreign --arch $architecture $3 $name http://$mirror/$2/

cp /usr/bin/qemu-arm-static $name/usr/bin

LANG=C chroot $name /debootstrap/debootstrap --second-stage

# 第二阶段
cat << EOF > $name/etc/apt/sources.list
deb http://$mirror/$2/ $3 contrib main non-free
deb-src http://$mirror/$2/ $3 contrib main non-free
EOF

echo "$2" > $name/etc/hostname

cat << EOF > $name/root/.zshrc
zstyle ':completion:*:sudo:*' command-path /usr/local/sbin \
                                           /usr/local/bin  \
                                           /usr/sbin       \
                                           /usr/bin        \
                                           /sbin           \
                                           /bin            \
                                           /usr/X11R6/bin

# 开启自动补全
autoload -U compinit
compinit
# 启动使用方向键控制的自动补全
zstyle ':completion:*' menu select
# 启动命令行别名的自动补全
setopt completealiases
# 开启历史记录
HISTFILE="~/.zsh_history"
HISTSIZE=20000
SAVEHIST=20000
# 消除历史记录中的重复条目
setopt HIST_IGNORE_DUPS
# 锁定/解锁终端
ttyctl -f
# 命令提示符
autoload -U colors && colors
PROMPT="%{\$fg_bold[red]%}* %{\$fg[cyan]%}%d %{\$reset_color%}> "
# 刷新自动补全
zstyle ':completion:*' rehash true

if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "\$(dircolors -b ~/.dircolors)" || eval "\$(dircolors -b)"
    alias ls='ls --color=auto'
    #alias dir='dir --color=auto'
    #alias vdir='vdir --color=auto'

    alias grep='grep --color=auto'
    #alias fgrep='fgrep --color=auto'
    #alias egrep='egrep --color=auto'
fi
EOF

date=$(date "+%b.%d %Y")

cat << EOF > $name/root/init.sh
#!/bin/sh
export SHELL=/bin/zsh
export USER=root
export LOGNAME=root
export HOME=/root
export LANG=en_US.UTF-8
export LANGUAGE=en_US:en
export TERM=linux
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
echo "Welcome to Debian 8 jessie on Android!"
echo "Create by linxan at $date"
cat /etc/motd
cd && /bin/zsh
EOF

chmod +x $name/root/init.sh

# 第三阶段
cat << EOF > $name/root/build.sh
#!/bin/sh
apt-get update
apt-get -y install $packages
apt-get -y dist-upgrade
EOF

chmod +x $name/root/build.sh
LANG=C chroot $name /root/build.sh

cat << EOF > $name/root/clean.sh
#!/bin/sh
apt-get clean
rm -f /root/.bash*
rm -f /root/build.sh
rm -f /root/clean.sh
rm -f /usr/bin/qemu*
EOF

chmod +x $name/root/clean.sh
LANG=C chroot $name /root/clean.sh

# 第四阶段
dd if=/dev/zero of=${basedir}/$name.$4.img bs=512M count=4
mkfs.$4 $name.$4.img
mount -o loop $name.$4.img /mnt
rm -rf /mnt/* && cp -ar $name/* /mnt
umount -l /mnt
