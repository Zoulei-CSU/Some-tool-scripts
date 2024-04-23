#!/bin/bash
echo "Try to start wireless AP..."

# 直接执行：nohup ./start-ap2.sh > ap-log.txt 2>&1 &
# 或者放在/etc/rc.local里开机运行
#     /root/ap/start-ap2.sh > /root/ap/ap-log.txt 2>&1 &

#无线网卡名称
export WCARD=wlx502b73a40722

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

# 已经在/etc/NetworkManager/NetworkManager.conf里设置了unmanageable-devices
ifconfig ${WCARD} 192.168.32.1/24 up	#设置有线网卡IP并启动
sleep 2

# 开启AP
write_log "Starting wireless AP..."
hostapd /etc/hostapd.conf -B	#启动AP
sleep 2

# 开启DHCP服务
write_log "Starting DHCP server..."
udhcpd /etc/udhcpd.conf & 	#启动DHCP
sleep 2

# 开启防火墙设置
write_log "Change iptables..."
iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE 
iptables -A FORWARD -i eth0 -o ${WCARD} -m state --state RELATED,ESTABLISHED -j ACCEPT 
iptables -A FORWARD -i ${WCARD} -o eth0 -j ACCEPT

# 启动AP完成
write_log "Done."
exit 0
