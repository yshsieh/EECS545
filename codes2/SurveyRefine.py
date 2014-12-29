# -*- coding: utf-8 -*-
# 2014/01/25 program to paerse post in histogram
# 2014/02/20 chage the collected data is a sentence based
# 2014/04/19 this file is used to reconstruct the original sentence for survey 

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
import langid

sqlName = "../Matlab/instagram.sqlite"
dataInName = "../Matlab/survey_data_sentence.txt"
dataOutName = "../Matlab/survey_data_sentence_reconstruct.txt"

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

def checkUserId(userId):
	return True


# TODO: make a filter to get only the text including moji
def textFilter(text):
	# 1. remove any tag start with @
	text = re.sub('@.*? ','',text)

	# 2. remove any tag start with #
	#text = re.sub('#.*? ','',text)

	# 3. remove dangling /
	text = text.replace('\ ',' ')

	# 4. remove any string after u'\ufe0f'
	nullString = '\\u263a\\ufe0f'
	if(text.find(nullString)!=-1):
		#print text
		text = text[:text.find(nullString)]
		#print text
		#a =raw_input()

	# 5. remove the last remaining string
	if(text.find('@')!=-1):
		text = text[:text.find("@")]
	#if(text.find('#')!=-1):
	#	text = text[:text.find("#")]

	return text

# function to parse all tags start from #
def findAllTags(text):
	# 1. add a space in the end of text for ease of parsing
	text = text+" ";
	text = text.replace('#',' #'); # also a trick to make parsing eaiser
	tags = re.findall('#.*? ',text)
	return tags

# function to remove tags
def removeAllTags(text):
	# remove any tag start with #
	text = re.sub('#.*? ','',text)

	if(text.find('#')!=-1):
		text = text[:text.find("#")]
	return text

# TODO: this function is now not concise, because other language will also make \u, such as chinese
def existEmoji(text):
	if text.find('\u')!=-1:
		return True
	else:
		return False

staTotalStringCnt = 0;
staEmojiStringCnt = 0;

def parse(userNameNow="amanda23", addUserCnt=0):
	global staTotalStringCnt, staEmojiStringCnt;
	baseUrl = "http://instagram.com/"

	br = getBrowser()

	
	targetUrl = baseUrl+userNameNow
	print targetUrl

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


	# 2. fetch out user & text
	userNameStartTag = '{"username":"'
	userNameEndTag = '","'

	userNames = []
	offset = 0
	while(1):
		if(h.find(userNameStartTag, offset) == -1):
			print '-------- reach the end of parsing user names ---------'
			break
		name = fetchText(h,offset,userNameStartTag,userNameEndTag)
		#print name
		if(name != userNameNow):
			userNames.append(name)


		offset = h.find(userNameStartTag, offset) + 1
	
	textStartTag = '"text":"'
	textEndTag = '","from":'
	texts = []
	offset = 0
	while(1):
		if(h.find(textStartTag, offset) == -1):
			print '--------- reach the end of parsing text ------------'
			break;
		text = fetchText(h,offset,textStartTag,textEndTag)
		#print text
		texts.append(text)
		offset = h.find(textStartTag,offset)+1

	# 3. check out the user uid
	uidNowSql = 'select uid from user where name = "'+userNameNow+'"'
	uidSqlResult = fetchListFromSql(uidNowSql)
	print uidSqlResult

	
	if(len(uidSqlResult) == 0):
		print '[WARN]: this user='+userNameNow+' is not in the db, adding this to db now'
		addSql = 'insert into user (name, add_time) values ("%s", "%s")' % (userNameNow,getTime())
		print addSql
		runSql(addSql)

		uidSqlResult = fetchListFromSql(uidNowSql)

	uidNow = uidSqlResult[0]
	print "uidNow = "+str(uidNow)


	# 4. update new names into the table
	userNames = list(set(userNames)) # fetch out the unique names
	print userNames

	print 'begin to updat user into table, addUserCnt = '+str(addUserCnt)
	addUserIdx = 0
	for name in userNames:
		checkSql = 'select uid from user where name = "'+name+'"'
		checkResult = fetchListFromSql(checkSql)
		if(len(checkResult) == 0):
			#print 'cant find this user = '+name+' -> add a new one to parse'
			addSql = 'insert into user (name, add_time) values ("%s", "%s")' % (name,getTime())
			runSql(addSql)

		if(addUserIdx >= addUserCnt): # reach the controled number of adding users
			break
		addUserIdx += 1
	print 'finish update user into table'

	# 5. update text into table
	for text in texts:
		staTotalStringCnt += 1;
		if(existEmoji(text)):
			# remove all "'" and '"'
			text = text.replace('"',' ').replace("'",' ')
			textFiltered = textFilter(text)
			print 'tf = '+textFiltered
			try:
				textUtf8 = json.loads('"'+textFiltered+'"')
			except ValueError, e:
				print '[WARN]: Json cant load the string, give up this thread'
				break;
			print 'tu = '+textUtf8

			emojiSql = 'select emoji from emoji'
			emojis = fetchListFromSql(emojiSql)
			eidSql = 'select rowId from emoji'
			eids = fetchListFromSql(eidSql)
			#print emojiResult

			emojiIsTarget = False

			# check if there is any text that is not emoji but it is unicode
			textUtf8EmojiRemoved = textUtf8
			for emoji in emojis:
				textUtf8EmojiRemoved = textUtf8EmojiRemoved.replace(emoji,'')
			textUtf8EmojiRemoved.replace(u'\u0fef','')


			print 'er = '+textUtf8EmojiRemoved
			try:
				textUtf8EmojiRemoved.encode('ascii')
			except UnicodeEncodeError:
				print "it was not a ascii-encoded unicode string"
				onlyEnglish = False
			else:
				print "It may have been an ascii-encoded unicode string"
				onlyEnglish = True


			

			includedEids = []
			includedEmojis = []
			for (eid,emoji) in zip(eids,emojis):
				if(textUtf8.find(emoji)!=-1):
					emojiIsTarget = True
					includedEids.append(eid)
					includedEmojis.append(emoji)
					print 'eid = '+str(eid)+', emoji = '+emoji
					#print textUtf8
					#break
			print includedEids

			# update statisitc
			if(emojiIsTarget):
				staEmojiStringCnt += 1;

			if(emojiIsTarget and onlyEnglish):
				# get tags
				tags = findAllTags(textUtf8EmojiRemoved)
				print tags
				for tag in tags:
					tag = tag.rstrip() # remove ending space
					tag = tag[1:]
					tag = tag.lower()

					#print tag
					#a = raw_input()

					for (eid,emoji) in zip(includedEids, includedEmojis):
						insertSql = "insert into emoji_tag_mapping (eid,emoji,tag) values (%d,'%s','%s')" % (eid, emoji, tag)
						runSql(insertSql)

				# remove puctuation
				punctuationSet = set(string.punctuation)
				#textEnglish = ''.join(ch for ch in textUtf8EmojiRemoved if ch not in punctuationSet)
				#textEnglish = textEnglish.lower()
				#print 'en = '+textEnglish
				
				textUtf8TagRemoved = removeAllTags(textUtf8)
				textUtf8TagRemoved = ''.join(ch for ch in textUtf8TagRemoved if ch not in punctuationSet)
				textUtf8TagRemoved = textUtf8TagRemoved.lower()

				insertSql = "insert into text (uid,text,add_time,name,text_filtered,text_utf8,text_english) values (%d,'%s','%s','%s','%s','%s','%s')" % (uidNow, text, getTime(), userNameNow, textFiltered, textUtf8, textUtf8TagRemoved)
				runSql(insertSql)

				textNow = textUtf8TagRemoved.lstrip() # removing leading space
				remainEmojis = True
				preMatchedText = ''
				while(remainEmojis):
					remainEmojis = False

					nearestTextIdx = -1
					for (eid,emoji) in zip(includedEids, includedEmojis):
						idxEmoji = textNow.find(emoji)
						if(idxEmoji >= 0):
							print 'find emoji = '+emoji+' , eid = '+str(eid)+' in position '+str(idxEmoji)
							remainEmojis = True
							if nearestTextIdx == -1 or (nearestTextIdx >= 0 and idxEmoji < nearestTextIdx):
								print 'update nearest emoji'
								nearestEmoji = emoji
								nearestEid = eid
								nearestTextIdx = idxEmoji
			
					needUpdate = False	
					if(remainEmojis):
						print 'textNow = '+textNow
						print 'nearestEmoji = '+nearestEmoji
						print 'preMatchedText = '+preMatchedText
						if(nearestTextIdx == 0 ): # no leading text, ignore
							if(preMatchedText==''):
								print 'no preMatchedText, ignore this emoji'
							else: # use the previous matched text
								needUpdate = True
								textEmoji = preMatchedText
								print 'use the previous matced text textEmoji = '+textEmoji
							
						else:
							needUpdate = True
							textEmoji = textNow[0:nearestTextIdx]
							print 'textEmoji = '+textEmoji

							preMatchedText = textEmoji
							textNow = textNow[nearestTextIdx:]

						# process the next round of test
						textNow = textNow.replace(nearestEmoji,'').lstrip()


						if(needUpdate):
							sqlUpdate = "insert into emoji_text_mapping (eid,emoji,text) values (%d,'%s','%s')" % (nearestEid, nearestEmoji, textEmoji)
							runSql(sqlUpdate)

						print "textNow for the next loop = "+textNow
						#a = raw_input()
					


				# --- deprecate: don't add the whole thread anymore -> just the subsentence ----
				#for (eid,emoji) in zip(includedEids, includedEmojis):
				#	insertSql = "insert into emoji_text_mapping (eid,emoji,text) values (%d,'%s','%s')" % (eid, emoji, textEnglish)
				#	runSql(insertSql)
				

		
	# 6. update the parse status of this user
	statusSql = 'update user set is_parsed = 1 where uid = '+str(uidNow)
	print "statusSql = "+statusSql
	runSql(statusSql)

	print "*** parse result : update %d names, %d texts ***" % (len(userNames), len(texts))


def parseController():
	MAX_TO_PARSE = 20
	EMOJI_TO_SURVEY = 100

	emojiSql = 'select count(*) as c from emoji left join emoji_text_mapping on emoji.rowid = emoji_text_mapping.eid group by emoji.rowid order by emoji.rowid'
	emojiCounts = fetchListFromSql(emojiSql)

	eidsSorted = np.argsort(emojiCounts)[::-1]+1 # eid starts from 1 rather than 0
	eidsSorted = eidsSorted[0:EMOJI_TO_SURVEY]
	#print eidsSorted

	result = ''

	#eidsSorted = [573, 576]

	for eid in eidsSorted:
		debugShow('start to parse (eid = %d)' % (eid), True, True)
		print eid
		
		emojiUtf8Sql = 'select emoji from emoji where rowid = '+str(eid)
		emojiUtf8 = fetchListFromSql(emojiUtf8Sql)
		emojiUtf8 = emojiUtf8[0]
		print emojiUtf8

		textSql = u"select text from text where text_utf8 like '%"+emojiUtf8+u"%' order by random() limit "+str(MAX_TO_PARSE*10)
		#textSql = u"select text from text where text_utf8 like '%"+emojiUtf8+u"%' limit "+str(MAX_TO_PARSE*10)
		print textSql
		texts = fetchListFromSql(textSql)
		#print texts

		#for textIdx in range(4):
		#	text = texts[textIdx]
		#	print text
		textIdx = 0
		for text in texts:		

#-----------------------------------------------------------------------
			text = text.replace('"',' ').replace("'",' ')
			text = text.replace('\r',' ').replace('\n',' ')
			textFiltered = textFilter(text)

			print 'tf = '+textFiltered
			try:
				textUtf8 = json.loads('"'+textFiltered+'"')
			except ValueError, e:
				print '[WARN]: Json cant load the string, give up this thread'
				break;
			print 'tu = '+textUtf8


			#print 'textUtf8 = '+textUtf8
			
			emojiSql = 'select emoji from emoji'
			emojis = fetchListFromSql(emojiSql)
			eidSql = 'select rowId from emoji'
			eids = fetchListFromSql(eidSql)

			# check if there is any text that is not emoji but it is unicode
			textUtf8EmojiRemoved = textUtf8
			for emoji in emojis:
				textUtf8EmojiRemoved = textUtf8EmojiRemoved.replace(emoji,'')
			textUtf8EmojiRemoved.replace(u'\u0fef','')
			
			#print 'textUtf8EmojiRemoved = '+textUtf8EmojiRemoved

			# remove puctuation
			punctuationSet = set(string.punctuation)
				
			textUtf8TagRemoved = removeAllTags(textUtf8EmojiRemoved)

			#textUtf8TagRemoved = ''.join(ch for ch in textUtf8TagRemoved if ch not in punctuationSet)
			#textUtf8TagRemoved = textUtf8TagRemoved.lower()


			textFinal = textUtf8TagRemoved.lstrip() # removing leading space
			#print 'textFinal = '+textFinal
			textFinal = textFinal.replace('\n','').replace('\r','')

			print textFinal
			# only select the sentence in certain length
			if len(textFinal) > 15 and len(textFinal) < 40:
				lan = langid.classify(textFinal)
				print lan
				if lan[0]=='en' and lan[1] > 0.3:
					print '---------------------------- this is selected --------------------'
					#a = raw_input()
					
					# build clean input for matlab processing
					textClean = ''.join(ch for ch in textFinal if ch not in punctuationSet)
					textClean = textClean.lower()

					result += '%d|%d|%s|%s\n' % (textIdx,eid, textClean, textFinal)

					textIdx += 1
					if textIdx >= MAX_TO_PARSE:
						break 
	textFile = open(dataOutName, 'w')
	textFile.write(result)
	textFile.close()

	return






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
	parseController()

	print "emoji vs. total = (%d,%d)" % (staEmojiStringCnt, staTotalStringCnt)
	print "END_OF_PROGRAM"

