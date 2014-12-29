# -*- coding: utf-8 -*-
# 2014/01/25 program to paerse post in histogram
# 2014/02/20 chage the collected data is a sentence based
# 2014/03/29 update it to a program save emoji pics
# WARN : this program is just used to donwload apple's emoji now

import os
import shlex
import re
import HTMLParser
import sqlite3 as sq
import numpy as np
import random
import string
import cookielib
import mechanize
import time
import json
import urllib2


sqlName = "instagram.sqlite"
try:
	con=sq.connect(sqlName)
except sq.Error, e:
	print "ERROR: sqlite can't open :%s" % e.args[0]

def log(content, fileName='h'):
	logFolder = './log/'
	logFile = open(logFolder+fileName, 'w+')
	logFile.write(content)
	logFile.close()

def getBrowser():
	br = mechanize.Browser()

	#cj = cookielib.LWPCookieJar()
	#br.set_cookiejar(cj)

	br.set_handle_equiv(True)
	br.set_handle_redirect(True)
	br.set_handle_referer(True)
	br.set_handle_robots(False)

	br.set_handle_refresh(mechanize._http.HTTPRefreshProcessor(), max_time=2)

	#br.addheaders = [('User-agent', 'Mozilla/5.0 (X11; U; Linux i686; en-US; rv:1.9.0.1) Gecko/2008071615 Fedora/3.0.1-1.fc9 Firefox/3.0.1'),('Accept-Language', 'en-US,en;q=0.8')]
	return br

def parseDataFromWeb():
	baseUrl = "http://apps.timwhitlock.info/"
	targetUrl = "http://apps.timwhitlock.info/emoji/tables/unicode#note5"
	print targetUrl
	baseFolder = 'emojiPics/'

	br = getBrowser()
	try:
		r = br.open(targetUrl)
		h = r.read()
		log(h,'hStart')
	except mechanize.HTTPError, e:
		print '[ERROR]: get mechanize http error: '
		print e.args
		return
	except urllib2.URLError, e:
		print '[ERROR]: get urllib2 error'
		print e.args
		return

	# just get apple now
	#emojiClassNames = {'naive','apple','android','symbola','phantom'};
	#emojiClassStartTags = {'<td class="preview">','<td class="preview theme-apple">','<td class="preview theme-android">','<td class="preview theme-symbola">','<td class="preview theme-phantom">'}	

	className = 'apple';
	classStartTag = '<td class="preview theme-apple">'

	picStartTag = '<img class="emoji" data-src="'
	picEndTag = '" />'
	noPicStartTag = ''

	emojiStartTag = '<tr id="emoji-'
	emojiEndTag = '">'


	emojiOffset = 0 # record the offset for each emoji
	emojiIdx = 0
	while 1:

		print'------------ read emoji_idx = %d ---------------' % (emojiIdx)

		emojiOffset = h.find(emojiStartTag, emojiOffset)
		if(emojiOffset == -1):
			print '--------- reach the end of parsing text ------------'
			break;
		else:
			emojiUnicode = fetchText(h, emojiOffset,emojiStartTag, emojiEndTag)
			print 'emojiUnicode = ' + emojiUnicode

			classOffset = h.find(classStartTag, emojiOffset)

			if(classOffset == -1):
				print 'ERROR: can find class tag = %s\n' % (emojiClassStartTag)
			else:
					 
				picUrlEnd = fetchText(h, classOffset, picStartTag, picEndTag)

				picUrl = baseUrl+picUrlEnd
				print 'picUrl = '+picUrl
				
				curlCommand = 'cd emojiPic && { curl -O %s ; cd -; }' % (picUrl)
				print curlCommand 
				os.popen(curlCommand)

		# update offset
		emojiOffset += 1
		emojiIdx += 1
		
	# 6. update the parse status of this user
	#statusSql = 'update user set is_parsed = 1 where uid = '+str(uidNow)
	#print "statusSql = "+statusSql
	#runSql(statusSql)

	#print "*** parse result : update %d names, %d texts ***" % (len(userNames), len(texts))



# function to get time in real world
def getTime():
	return time.strftime("%m/%d/%y,%H:%M:%S")


# function to fetch a piece of information encloused by startTag and endTag
def fetchText(r,startOffset,startTag,endTag):
	startIdx = r.find(startTag, startOffset)
	if startIdx == -1: # can't find startTag
		print 'ERROR: cant find startTag:'+startTag
		return -1

	endIdx = r.find(endTag,startIdx+len(startTag))
	if endIdx == -1: # can't find endTag
		print 'ERROR: cant find endTag:'+endTag
		return -1

	return r[startIdx+len(startTag):endIdx]

def debugShow(functionName, isStart=True, doubleDash = False):
	lineLen = 70
	if(isStart):
		info = 'Start of '+functionName
	else:
		info = 'End of '+functionName
	prefixLen = (lineLen - len(info))/2
	suffixLen = lineLen - len(info) - prefixLen
	if(doubleDash):
		sym = '='
	else:
		sym = '-'
	prefix = sym*(prefixLen-1)+' '
	suffix = ' '+sym*(suffixLen-1)
	print prefix+info+suffix

def fetchListFromSql(sql, idx=0, printSql = False):
	global con
	if printSql:
		print 'fetchListFromSql: fetchSql = '+sql
	listReturn = []
	try:
		cur = con.cursor()
		cur.execute(sql);
		rows = cur.fetchall()
		for row in rows:
			data = row[idx]
			listReturn.append(data)
	except sq.Error, e:
		print "ERROR: sqlite fetchList error: %s" % e.args[0]
		exit()
	return listReturn

def runSql(sql, printSql = False):
	global con
	if (printSql):
		print "runSql: sql = "+sql
	try:
		cur = con.cursor()
		cur.execute(sql);
		con.commit()
	except sq.Error, e:
		print "ERROR: sqlite run error: %s\nsql=%s" % (e.args[0],sql)
		exit()

if __name__ == '__main__':
	parseDataFromWeb()

	print "END_OF_PROGRAM"

