[Linux系统将WiFi配置为AP模式 --- hostapd 和 udhcpd的使用说明](https://blog.csdn.net/wit_732/article/details/121038477)

## hostapd

### 一、功能说明

hostapd是Linux系统上的一个带加密功能的无线接入点(access point : AP)程序。hostapd能够使得无线网卡切换为master模式，模拟AP（路由器）功能，作为AP的认证服务器，负责控制管理stations的接入和认证。hostapd 是用于接入点和身份验证服务器的用户空间守护进程。它实现了IEEE 802.11接入点管理,当前版本支持Linux（Host AP、madwifi、mac80211-based驱动）和FreeBSD（net80211）。

hostapd 被设计为一个“守护进程”程序，在后台运行并充当控制身份验证的后端组件。hostapd 支持单独的前端程序，hostapd 中包含一个基于文本的使用工具hostapd_cli。(wpa_supplicant对应的是对station模式的管理，前端程序为wpa_cli)

由于hostapd的良好特性，现在已经被广泛使用，可以说是通用的AP管理工具了。这里我们只探讨该工具如何使用，不讨论其实现原理。

官网源码地址: [hostapd](http://w1.fi/cgit/hostap)

### 二、配置文件hostapd.conf

启动hostapd前需要我们写好hostapd的配置文件，因为hostapd起来前回解析这个文件来进行相关的设定。

官方文档在源码目录中，由于内容太多，这里不做粘贴，给出我们会场用到的配置说明。

hostapd.conf官方地址：[hostapd.conf](https://w1.fi/cgit/hostap/plain/hostapd/hostapd.conf)

```shell
# 选择的网口名称，我这里是ap0。具体可以ifcofnig看下当前设备下偶那些网口
interface=ap0
# 线驱动，一般有两种：wext/nl80211，wext版本较旧目前一般使用nl80211
driver=nl80211 
# iEEE802.11n
ieee80211n=1
# 802.11g,一般三个模式: a,b,g。a->5GHZ,g->2.4GHZ
hw_mode=g
# wifi工作的信道，2.4GHZ(1~14)
channel=6
# AP的名称，类似于我们的路由器名称
ssid=smartlife123456
# 选择加密方式为WPA2,常用加解密方法是有WEP、WPA、WPA2、WPA3
wpa=2
# 密码
wpa_passphrase=12345678
# 加密方式
wpa_key_mgmt=WPA-PSK
# 加密算法
rsn_pairwise=CCMP TKIP
wpa_pairwise=TKIP CCMP

```

上面给出了常用的一些配置项的说说明，下面直接给出两个可用的配置。(copy进Linux的时候注意下格式，否则hostapd回解析出错)

打开配置文件，按照自己的需要修改就好

```shell
vi /etc/hostapd.conf
# 主要修改interface、ssid、wpa_passphrase
mkdir /var/run/hostapd	#可能需要创建一个共享目录，hostapd_cli使用
```

### 三、hostapd的启动

```shell
hostapd /etc/hostapd.conf -B #-B将程序放到后台运行
```

hostapd启动中常用到的参数说明

```shell
	-h   显示帮助信息
	-d   显示更多的debug信息 (-dd 获取更多)
	-B   将hostapd程序运行在后台
	-g   全局控制接口路径，hostapd_cli使用，一般为/var/run/hostapd
	-G   控制接口组
	-P   PID 文件
	-K   调试信息中包含关键数据
	-t   调试信息中包含时间戳
	-v   显示hostapd的版本
```

成功启动后日志：

```shell
# hostapd /etc/hostapd.conf -B
wlx68ddb70184b1: interface state UNINITIALIZED->ENABLED
wlx68ddb70184b1: AP-ENABLED 
```

可以看到此时我们设备的AP模式已经开启成功了，但是我们的工作还没有结束。因为此时我们连接到此AP的设备还无法获取到IP地址。要进行IP地址的分配我们还得继续下面的工作。

### 四、排错

```shell
nl80211: Could not configure driver mode
nl80211: deinit ifname=wlx68ddb70184b1 disabled_11b_rates=0
nl80211 driver initialization failed.
wlx68ddb70184b1: interface state UNINITIALIZED->DISABLED
wlx68ddb70184b1: AP-DISABLED 
wlx68ddb70184b1: CTRL-EVENT-TERMINATING 
hostapd_free_hapd_data: Interface wlx68ddb70184b1 wasn't started
```

hostapd启动可能会失败,`nl80211: Could not configure driver mode`，有几种可能，首先是可能网卡被占用，先尝试停止。

```shell
sudo nmcli nm wifi off	#如果提示没有nm，也可以这样：sudo nmcli radio wifi off
sudo rfkill unblock wlan
sudo ifconfig wlx68ddb70184b1 192.168.32.1/24 up #这里个Wifi网卡的网址，可以根据自己的设置指定
```

之后，可以尝试再次启动hostapd。如果还是上面的报错，有可能是无线网卡驱动的问题，需要更换网卡驱动。我用的是USB的`RTL8188GU`的网卡，lsmod查看发现加载的是系统自带的`rtl8xxxu`驱动。去[github](https://github.com/lwfinger/rtl8xxxu)上找到了最新的驱动，按照提示说明，重新编译按照网卡驱动，新的驱动名称叫`rtl8xxxu_git`。

```shell
ifconfig wlx68ddb70184b1 down	#关闭无线网卡
rmmod r8188eu rtl8xxxu 8188eu	#卸载相近的网卡驱动
modprobe rtl8xxxu_git	#重新加载新网卡驱动
sleep 3
ifconfig wlx68ddb70184b1 192.168.32.1/24 up #重新打开网卡
```

再次尝试启动hostapd，基本就没问题了。

## udhcpd

### 一、功能说明

我们常用到udhcpc,对udhcpd并不熟悉，其实udhcpd是工作在server端的DHCP服务，udhcpc则是工作在client端的DHCP服务。DHCP(Dynamic Host Configuration Protocol，动态主机配置协议)。是一个局域网的网络协议，使用UDP协议工作。

udhcpc是用来获取IP地址的，而udhcpd则是用来为设备分配IP地址的。如果使用的是静态IP则不需DHCP服务的。

官方源码地址：[udhcp](https://udhcp.busybox.net/)

### 二、配置文件udhcpd.conf的使用

打开配置文件，按照自己的需要修改就好

```shell
vi /etc/udhcpd.conf
# 主要修改start、end、interface等
```

### 三、实例说明

下面是一份可以直接使用的udhcpd.conf

```shell
start 192.168.31.2	#起止IP地址
end 192.168.31.254
interface wlx68ddb70184b1	#需要进行DHCP的网卡
max_leases 234
opt router 192.168.31.1	#网关地址
opt	dns	192.168.31.1 114.114.114.114
option	subnet	255.255.255.0
```

### 四、使用示例

至此，我们所有的准备工作都已经完成，下面来启动udhcpd程序。

```shell
udhcpd /etc/udhcpd.conf &   #加‘&’是程序运行在后台
# 前面我们已经给无线网卡指定了网关IP，如果没有的话，要再次指定一下：
# ifconfig wlx68ddb70184b1 192.168.32.1/24 up 
```

现在我们已经通过hostapd和udhcpd这两个工具完成了一个WiFi热点的配置了，但是，Wifi组网完成，但是还是无法共享有线网的网络链接。

## 共享上网

首先要允许内核进行网络转发，在`/etc/sysctl.conf`中注意修改以下内容

```shell
net.ipv4.ip_forward = 1
```

然后让内核参数即时生效`sysctl -p`

配置路由表，开启转发。不过这个操作在我的系统中一直无法生效，只能换一种方法，用建立网桥的方法。

```shell
iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE 
iptables -A FORWARD -i eth0 -o wlan0 -m state --state RELATED,ESTABLISHED -j ACCEPT 
iptables -A FORWARD -i wlan0 -o eth0 -j ACCEPT
```

### 网桥

网桥的方法，就是建立一个网桥，把有线网卡和无线网卡链接在一起。

通过修改`/etc/network/interfaces`文件，创建网桥br0，并且设置为DHCP上网方式。这样做实际上物理链接网络的eth0变成了br0的一个子部分，br0可以通过插在eth0网口上的网线向路由器获得IP。

```shell
source /etc/network/interfaces.d/*

auto lo br0
iface lo inet loopback

allow-hotplug wlx68ddb70184b1
iface wlan0 inet manual

# eth0 connected to the ISP router
allow-hotplug eth0
iface eth0 inet manual

# Setup bridge
auto br0
iface br0 inet dhcp
      bridge_ports eth0 wlan0
      bridge_stp off
      bridge_maxwait 0
```

之后，开启hostapd和udhcpd就可以了。

但这里有个严重的问题，我用的是USB的网卡，而且还是需要`usb_modeswitch`的那种，如果没有插着USB网卡，貌似系统不能正常启动，卡在网络初始化那里，所以，貌似只能在系统启动后，手动执行命令去设置网桥了。当前，这些命令可以做成一个脚本文件，系统启动后，判断是否插入了USB网卡，之后自动执行。

```shell
#!/bin/bash
echo "尝试开启无线AP..."

export WCARD=wlx68ddb70184b1	#无线网卡名称

check_results=`ifconfig -a | grep ${WCARD}`
if [[ $check_results =~ "${WCARD}" ]] 
then 
    echo "已检测到指定网卡，继续..."
else 
    echo "未检测到指定无线网卡（${WCARD}），无法开启AP，请重试。"
    exit 1
fi

check_results=`ifconfig | grep br0:`
if [[ $check_results =~ "br0" ]] 
then 
    echo "网桥已经存在，AP可能已经建立，退出。"
    exit 1
fi

echo "卸载系统驱动，更换git驱动..."
ifconfig wlx68ddb70184b1 down	#先关闭网卡
rmmod r8188eu rtl8xxxu 8188eu
modprobe rtl8xxxu_git	#卸载系统自带驱动，换成git编译的驱动
sleep 2

echo "创建无线网桥..."
brctl addbr br0	#创建网桥br0
ifconfig br0 172.16.50.127 netmask 255.255.255.0	#给网桥指定IP和网关，这个根据自己的网络情况设置
route add default gw 172.16.50.1
brctl addif br0 eth0	#把有线网卡和无线网卡都加入网桥
brctl addif br0 wlx68ddb70184b1 #这里貌似会报错can't add to bridge br0，但是后面貌似又没问题
sleep 2

echo "重新启动无线网卡..."
nmcli radio wifi off	#解除系统的网卡占用
rfkill unblock wlan
ifconfig wlx68ddb70184b1 192.168.32.1/24 up	#设置有线网卡IP并启动
sleep 2

echo "添加无线网卡到网桥..."
brctl addif br0 wlx68ddb70184b1 #上面添加无线网卡到br0报错，这里再来一次
sleep 2

echo "网桥信息："
brctl show br0
ifconfig br0

echo "开启AP..."
hostapd /etc/hostapd.conf -B	#启动AP

# echo "开启DHCP服务..."
# udhcpd /etc/udhcpd.conf & 	#启动DHCP
# 由于有线网卡的上一级路由器有DHCP，建立网桥之后，接入AP的设备可以从上级路由器获取IP，所以这里就不用启动DHCP服务了

echo "启动AP完成."
```





给玩客云用的自动脚本：

```shell
#!/bin/bash
echo "Try to start wireless AP..."

# 直接执行：nohup ./start-ap.sh > ap-log.txt 2>&1 &
# 或者放在/etc/rc.local里开机运行
#     /root/ap/start-ap.sh > /root/ap/ap-log.txt 2>&1 &

#无线网卡名称
export WCARD=wlx68ddb70184b1

# 输出函数
function write_log() {
	echo "[`date`]:$1"
}

# 延迟函数，延迟的过程中驱动LED
function delay_led() {
	# sleep 10
	#一边延迟，一边驱动LED。如果设备不支持，直接延迟就行
	echo 0 > /sys/class/leds/onecloud:red:alive/brightness
	echo 0 > /sys/class/leds/onecloud:green:alive/brightness
	echo 1 > /sys/class/leds/onecloud:blue:alive/brightness
	sleep 5
	
	# echo 0 > /sys/class/leds/onecloud:red:alive/brightness
	echo 1 > /sys/class/leds/onecloud:green:alive/brightness
	echo 0 > /sys/class/leds/onecloud:blue:alive/brightness
	sleep 5
	
	echo 1 > /sys/class/leds/onecloud:red:alive/brightness
	echo 0 > /sys/class/leds/onecloud:green:alive/brightness
	#echo 0 > /sys/class/leds/onecloud:blue:alive/brightness
	sleep 5
}

# 打开全部LDE灯
function turn_on_leds() {
	echo 1 > /sys/class/leds/onecloud:red:alive/brightness
	echo 1 > /sys/class/leds/onecloud:green:alive/brightness
	echo 1 > /sys/class/leds/onecloud:blue:alive/brightness
}

# 检测无线网卡是否存在
function check_Wifi_Card() {
	check_results=`ifconfig -a | grep ${WCARD}`
	if [[ $check_results =~ "${WCARD}" ]] 
	then 
		# 已检测到指定网卡
		return 1
	else 
		# 未检测到指定无线网卡${WCARD}
		return 0
	fi
	
    return 0
}

# 循环检测无线网卡，如果没有检测到无线网卡，就循环检测，等待插入USB。
# 循环检测3分钟，如果3分钟后还是没有检测到网卡，就退出
function check_Wifi_Card_loop() {
	t=0
	while [ $t -le 12 ]
	do
		#echo $t
		check_Wifi_Card
		if [[ $? == 1 ]] 
		then 
			# 已检测到指定网卡
			return 1
		else 
			# 未检测到指定无线网卡，循环检测
			write_log "[$t] Waiting for wireless card ${WCARD} ..."
		fi
		delay_led
		let t++
	done
	
    return 0
}

# mian
# 程序入库，开始检测网卡
check_Wifi_Card_loop
if [[ $? == 1 ]] 
then 
	# 已检测到指定网卡
	write_log "Wireless adapter ${WCARD} is ready."
else 
	# 未检测到指定无线网卡，循环检测
	write_log "Unable to find the wireless adapter ${WCARD}, exit."
	turn_on_leds
	exit 0
fi

turn_on_leds

# 检测是不是已经建立了网桥
check_results=`ifconfig | grep br0:`
if [[ $check_results =~ "br0" ]] 
then 
    write_log "The bridge already exists. The AP may have been established. Exit."
    exit 0
fi

write_log "Uninstall the system driver and replace the driver from git..."
ifconfig ${WCARD} down	#先关闭网卡
rmmod r8188eu rtl8xxxu 8188eu
modprobe rtl8xxxu_git	#卸载系统自带驱动，换成git编译的驱动
sleep 2

write_log "Create bridge br0..."
brctl addbr br0	#创建网桥br0
ifconfig br0 172.16.50.127 netmask 255.255.255.0	#给网桥指定IP和网关，这个根据自己的网络情况设置
route add default gw 172.16.50.1
brctl addif br0 eth0	#把有线网卡和无线网卡都加入网桥
#brctl addif br0 wlx68ddb70184b1 #这里貌似会报错can't add to bridge br0，但是后面貌似又没问题
sleep 2

write_log "Restart the wireless card..."
nmcli radio wifi off	#解除系统的网卡占用
rfkill unblock wlan
ifconfig ${WCARD} 192.168.32.1/24 up	#设置网卡IP并启动
sleep 2

write_log "Add wireless card to br0..."
brctl addif br0 ${WCARD} #上面添加无线网卡到br0报错，这里再来一次
sleep 2

write_log "Starting wireless AP..."
hostapd /etc/hostapd.conf -B	#启动AP

write_log "Done."
exit 0
```

