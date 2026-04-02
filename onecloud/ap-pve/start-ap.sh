#!/bin/bash
echo "Try to start wireless AP..."

# 直接执行：nohup ./start-ap2.sh > ap-log.txt 2>&1 &
# 或者放在/etc/rc.local里开机运行
#     /root/ap/start-ap2.sh > /root/ap/ap-log.txt 2>&1 &

#无线网卡名称
export WCARD=wlp8s0

#默认有线网卡名称
#export ETH=eth0
export ETH=vmbr0

# 输出函数
function write_log() {
	echo "[`date`]:$1"
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
		sleep 5
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
	exit 0
fi

# 已经在/etc/NetworkManager/NetworkManager.conf里设置了unmanageable-devices
ifconfig ${WCARD} 192.168.66.1/24 up	#设置有线网卡IP并启动
sleep 2

# 开启AP
write_log "Starting wireless AP..."
hostapd /etc/hostapd.conf -B	#启动AP
sleep 2

# 开启DHCP服务
write_log "Starting DHCP server..."
udhcpd /etc/udhcpd_w.conf & 	#启动DHCP
sleep 2

# 开启防火墙设置
write_log "Change iptables..."
iptables -t nat -A POSTROUTING -o ${ETH} -j MASQUERADE 
iptables -A FORWARD -i ${ETH} -o ${WCARD} -m state --state RELATED,ESTABLISHED -j ACCEPT 
iptables -A FORWARD -i ${WCARD} -o ${ETH} -j ACCEPT

# 启动AP完成
write_log "Done."
exit 0
