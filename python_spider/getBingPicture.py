# -*- coding: utf-8 -*-
"""
Created on  14:38:09 2023-12-19
从 https://www.bimg.cc/ 上爬取bing图片, 以及图片描述
参考: https://github.com/flow2000/bing-wallpaper-api

@author: Zoulei
"""

import os
import requests
import time
import random

import json
import datetime

headers = {'User-Agent':'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/114.0.0.0 Safari/537.36', 'Cache-Control': 'max-age=0', 'Connection': 'keep-alive'}

# 设置代理
proxies = {
  "http": "http://127.0.0.1:10809",
  "https": "http://127.0.0.1:10809",
}
proxies=None	# 不用代理

# #或者设置环境变量的代理
# export HTTP_PROXY="http://127.0.0.1:10809"
# export HTTPS_PROXY="http://127.0.0.1:10809"

def download(url, pic_path):
	try:
		print('开始下载：', url)
		pic = requests.get(url, headers=headers)
		if not pic.ok:
			print('下载失败：', pic.status_code)
			return pic.status_code
		f = open(pic_path,'wb')
		f.write(pic.content)
		f.close()
		print('下载完成，保存到：', pic_path)
		return pic.status_code
	except Exception as e:
		print(repr(e))
		return -1

 
def main():
	savePath = './images/'		# 文件保存路径
	logFile = savePath + 'log.txt'	# 记录日志

	print("Start...")
	start_time_str = '2023-08-04 00:00:00'	#开始时间字符串
	start_time = datetime.datetime.strptime(start_time_str, '%Y-%m-%d %H:%M:%S')

	current_time = datetime.datetime.now()	#获取当前时间
	# current_time_str = current_time.strftime('%Y-%m-%d %H:%M:%S')	#将时间转换为字符串

	date_difference = current_time.date() - start_time.date()	#计算日期差值
	days_difference = date_difference.days	## 获取相差的天数

	row_counts = 10		#爬取列表时，每页的条数
	page_counts = 1 + days_difference // row_counts		#一共需要爬取几页

	log = open(os.path.abspath(logFile),'a', encoding='utf-8')	#打开日志文件
	for i in range(page_counts):
		page = i + 1
		url_list = 'https://api.bimg.cc/all?page={0}&order=desc&limit={1}&w=1920&h=1080&mkt=zh-CN'.format(page, row_counts)
		# print(url_list)
		json_list = requests.get(url_list, headers = headers, proxies = proxies)
		code = 0
		try:
			data = json.loads(json_list.text)
			code = data["code"]
		except Exception as e:
			print(repr(e))
		if code != 200:
			print("Error: Unable to parse :", url_list)
			return
		data = data["data"]
		for item in data:
			url_img = item["url"]
			comment = item["title"] + " " + item["copyright"]

			created_time_str = item["created_time"]
			created_time = datetime.datetime.strptime(created_time_str, '%Y-%m-%d')
			if created_time < start_time:	#早于起始时间的图片，全都跳过，不需要
				continue
		
			fileName = created_time_str
			fileName = fileName.replace('-','_') + "_Bing_zh_CN.jpg"

			print("Get: ", created_time_str, comment)

			time.sleep(random.uniform(1, 3))		# 随机暂停1到3秒
			log.write(fileName + '\t' + comment + '\n')
			_ = download(url_img, os.path.abspath(savePath + fileName))	#开始下载图片
			# time.sleep(random.uniform(2, 5))		# 随机暂停2到5秒

		log.flush()		#一组下载完了, 刷新一下日志缓冲区

	log.close()		#for循环结束，关闭日志
	print("Done.")
 
if __name__ == "__main__":
	main()
