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
