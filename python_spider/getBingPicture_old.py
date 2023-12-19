# -*- coding: utf-8 -*-
"""
Created on 2020
从 https://bing.ioliu.cn 爬取bing图片，以及图片描述

@author: Zoulei

Update on 2023-12-19 : 网站关闭，脚本已失效。
"""

import os
import requests
import time
import random
from bs4 import BeautifulSoup

headers = {'User-Agent':'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/78.0.3904.97 Safari/537.36', 'Accept':'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3', 'Accept-Encoding': 'gzip, deflate, br', 'Accept-Language': 'zh-CN,zh;q=0.9,en;q=0.8', 'Cache-Control': 'max-age=0', 'Connection': 'keep-alive'}

#export HTTP_PROXY="http://127.0.0.1:10809"
#export HTTPS_PROXY="http://127.0.0.1:10809"
proxies = {
  "http": "http://127.0.0.1:10809",
  "https": "http://127.0.0.1:10809",
}
proxies=None

def download(url, pic_path):
	try:
		print('开始下载：', url)
		pic = requests.get(url, headers=headers, proxies=proxies)
		f = open(pic_path,'wb')
		f.write(pic.content)
		f.close()
		print('下载完成，保存到：', pic_path)
	except Exception as e:
		print(repr(e))
		
savePath = './images/'
logFile = savePath + 'log.txt'
baseUrl = 'https://bing.ioliu.cn'
pageUrl = baseUrl + '/?p=2'
strHtml=requests.get(pageUrl, headers=headers, proxies=proxies)
soup=BeautifulSoup(strHtml.text,'lxml')
#data=soup.select('body>div.container>div>div>div.options>a.ctrl.download')
#print(data)
data=soup.select('body>div.container>div>div')

log = open(os.path.abspath(logFile),'a', encoding='utf-8')
for item in data:
	soupSub = BeautifulSoup(str(item),'lxml')
	title = soupSub.get_text()
	print(title)
	subDataTime = soupSub.select('div.description>p.calendar>em')
	subData = soupSub.select('div.options>a.ctrl.download')
	if len(subData) > 0:
		subData = subData[0]	#取第一个，一般是低分辨率的，文件没那么大
		#subData = subData[len(subData) - 1]	#有多组的时候，取最后一个，分辨率最高
		subDataTime = subDataTime[0]
		#link = baseUrl + subData.get('href')
		link = subData.get('href')	#2022更新，URL逻辑改了
		fileName = subDataTime.get_text()
		fileName = fileName.replace('-','_') + "_Bing_zh_CN.jpg"
		#print(fileName, link)
		log.write(fileName + '\t' + title + '\n')
		time.sleep(random.uniform(1,3))	#随机暂停1到3秒
		download(link, os.path.abspath(savePath + fileName))
		time.sleep(random.uniform(2,5))	#随机暂停2到5秒
	pass
log.close()

print('下载完毕')