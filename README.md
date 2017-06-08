# debian-arm-build-scripts

## 这是个什么玩意？
尼阔以用这个脚本来搭建一个简单的 Debian 家族的 `arm` 镜像用以在 Android 设备 `chroot/proot`。

## 如何使用？
这很简单。

尼需要保证安装 `debootstrap` `qemu-user-static`
```
$ sudo apt-get install debootstrap qemu-user-static
```

下载脚本
```
$ wget https://raw.githubusercontent.com/linxan/debian-arm-build-scripts/master/android-d.sh
```

假设尼有一台已 root 的 Android 手机，构架 armel，想要 Debian 系统，版本为 jessie，扩展文件系统为 ext3
```
$ sudo sh android-d.sh armel debian jessie ext3
```

窝想要个 arm64 的 Debian sid ext4 肿木办？
```
$ sudo sh android-d.sh arm64 debian sid ext4
```

## 构建以后如何运行这个镜像？

以 adb 或终端模拟器操控装入 `busybox` 的 Android 系统。

以 chroot 为例，这需要 root。

尼阔以将构建的如 `jessie-root.ext3.img` 放置于 `/sdcard`
在 `/data` 创建一个新的目录
```
# mkdir /data/debian
```
好戏开始
```
# busybox mount -o loop /sdcard/jessie-root.ext3.img /data/debian
# busybox chroot /data/debian /root/init.sh
```
