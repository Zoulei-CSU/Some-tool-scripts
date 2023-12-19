# -*- coding: utf-8 -*-
"""
Created on  16:06:36 2022-11-16
从 http://nr.gd.gov.cn/map/atlas/#/ 上下载广东省的专题地图，并拼接成一个图片

@author: Zoulei
"""

import os
import requests
import time
import random
from bs4 import BeautifulSoup

import numpy as np
from cv2 import imread, imwrite, resize
from cv2 import INTER_LINEAR

headers = {'User-Agent':'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/78.0.3904.97 Safari/537.36', 'Accept':'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3', 'Accept-Encoding': 'gzip, deflate, br', 'Accept-Language': 'zh-CN,zh;q=0.9,en;q=0.8', 'Cache-Control': 'max-age=0', 'Connection': 'keep-alive'}


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

def getGDmaps(savePath, z):
	max_x = 32
	max_y = 32
	baseUrl = 'http://210.76.76.97/atlascache1024/112-113/{2}/{0}/{1}.png'
	baseUrl = 'http://210.76.76.97/atlascache1024/114-115/{2}/{0}/{1}.png'	 #广州城区图
	baseUrl = 'http://210.76.76.97/atlascache1024/4-5/{2}/{0}/{1}.png' #广东区位图
	baseUrl = 'http://210.76.76.97/atlascache1024/8-9/{2}/{0}/{1}.png' #广东地势图
	baseUrl = 'http://210.76.76.97/atlascache1024/10-11/{2}/{0}/{1}.png' #广东政区图
	x = 0
	while x <= max_x:
		y = 0
		while y <= max_y:
			url = baseUrl
			url = url.format(x, y, z)
			path = savePath + "{2}-{0}-{1}.png".format(x, y, z)
			# print(url, path)
			status = download(url, path)
			if status == 404:
				if y == 0:
					max_x = x	# X达到最大
					break
				else:
					max_y = y	# Y达到最大
			time.sleep(random.uniform(1,3))	#随机暂停1到3秒
			y = y + 1
		x = x + 1
	return max_x, max_y

def concatTiles(savePath, z, max_x, max_y, down_sampling = False):
	# savePath = './gd_maps/'
	# z = 4
	# max_x = 3
	# max_y = 5
	y = max_y
	img_rows = []
	while y >= 0:
		imgs = []
		for x in range(max_x + 1):
			path = savePath + "{2}-{0}-{1}.png".format(x, y, z)
			img = imread(path, -1)
			h, w = img.shape[:2]
			if h==0 or w==0:
				raise Exception("Cannot read {}".format(path))
			if down_sampling:
				img = resize(img, (int(w/2.0), int(h/2.0)), interpolation=INTER_LINEAR)  #降采样
			imgs.append(img) 
			print(path)
		img_row = np.concatenate(imgs, 1)  # 横着拼
		imgs = None
		img_rows.append(img_row)
		y = y - 1
		print('\n')

	img_total = np.concatenate(img_rows, 0)  # 竖着拼起来
	imwrite(savePath + "{}.png".format(z), img_total)
	print('Done :', savePath)

# main
savePath = './gd_maps/'
z = 5
max_x, max_y = getGDmaps(savePath, z)
# max_x = 11
# max_y = 8
print(max_x, max_y)
down_sampling = (max_x > 18 or max_y > 18)
concatTiles('./gd_maps/', z, max_x-1, max_y-1, down_sampling)
print('处理完毕，{0} x {1}，降采样：{2}'.format(max_x, max_y, down_sampling))
