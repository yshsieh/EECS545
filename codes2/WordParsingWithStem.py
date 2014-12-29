# -*- coding: utf-8 -*-
# 2014/02/08: yctung: a program to process the word freq
# 2014/03/27: yctung: add a function to "hash" to word
# 2014/04/02: yctung: add a function to "phase" an sentence
# 2014/04/24: yctung: update stem 


import os
import shlex
import re
import sqlite3 as sq
import operator
import numpy as np
import matplotlib.pyplot as plt
import word_stem 

sqlName = "./instagram_hyper.sqlite"
try:
	con=sq.connect(sqlName)
except sq.Error, e:
	print "ERROR: sqlite can't open :%s" % e.args[0]

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

ps = word_stem.PorterStemmer()
def wordHash(word):
	global ps
	# 1. remove repeated charactor
	#wordHashed = ''.join(sorted(set(word), key=word.index))
	wordHashed = re.sub(r'(.)\1+', r'\1', word)

	wordHashed = ps.stem(wordHashed, 0,len(wordHashed)-1)

	return wordHashed

# function to calculate the frequency of each words
def estimateFreq(isWord = True, wordNeedToBeHashed = True):
	#WORD_EXECLUDED_CNT = 50 # the number of word going to be excluded
	#WORD_USED_CNT = 5000 # the number of word going to be used
	WORD_USED_CNT = 90000 # the number of word going to be used
	PHRASE_USED_CNT = 3000


	#limitSuffix = ' limit 200000'
	limitSuffix = ' limit 2000000'

	if(isWord):
		SQL_FROM_TABLE_NAME = 'emoji_text_mapping'
		SQL_REFERENCE_NAME = 'text'

		if(wordNeedToBeHashed):
			SQL_TO_TABLE_NAME = 'word_hash'
			SQL_TO_PHRASE_TABLE_NAME = 'word_phrase_hash'
		else:
			SQL_TO_TABLE_NAME = 'word'
			SQL_TO_PHRASE_TABLE_NAME = 'word_phrase'

		SQL_ENTRY_NAME = 'word'
		#sSql = "SELECT text FROM emoji_text_mapping where text != ''" + limitSuffix
		#eSql = "SELECT eid FROM emoji_text_mapping where text != ''" + limitSuffix
	else:
		SQL_FROM_TABLE_NAME = 'emoji_tag_mapping'
		SQL_REFERENCE_NAME = 'tag'
		SQL_TO_TABLE_NAME = 'tag'
		SQL_ENTRY_NAME = 'tag'
		#sSql = "SELECT tag FROM emoji_tag_mapping where tag != ''" + limitSuffix
		#eSql = "SELECT eid FROM emoji_tag_mapping where tag != ''" + limitSuffix

	sSql = "SELECT "+SQL_REFERENCE_NAME+" FROM "+SQL_FROM_TABLE_NAME+" where "+SQL_REFERENCE_NAME+" != ''" + limitSuffix
	eSql = "SELECT eid FROM "+SQL_FROM_TABLE_NAME+" where "+SQL_REFERENCE_NAME+" != ''" + limitSuffix
	print sSql


	sentences = fetchListFromSql(sSql)
	eids = fetchListFromSql(eSql)
	#print sentences
	print 'sql select is finished'



	emojiTotalFreq = dict() # a map to classify emoji totoal cnt
	emojiFreq = dict()
	freq = dict()
	sentencePre = ""
	sentenceLen = len(sentences)
	sentenceIdx = 0
	progressPre = 0
	for (sentence,eid) in zip(sentences,eids):

		# manually combine "don t" back to "dont"
		sentence = sentence.replace(' t ','t ')

		progressNow = float(sentenceIdx) / float(sentenceLen)
		if progressNow - progressPre >= 0.1:
			print "single word progressNow = %f %%" % (progressNow*100)
			progressPre = progressNow

		sentenceIdx += 1

		if sentence != sentencePre: #ignore the repeated sentence because by multiple emoji in a sentence
			#print sentence
			words = shlex.split(sentence)
			#print words
			for word in words:
				# ignore word contains numbers
				if not re.search('\d+', word):

					# hash the word if need
					if wordNeedToBeHashed:
						word = wordHash(word)
					
					# updat totoal freq
					if(word in freq.keys()):
						freq[word] += 1;
					else:
						freq[word] = 1;
					# update emoji-based freq
					if(word in emojiFreq.keys()):
						if(eid in emojiFreq[word].keys()):
							emojiFreq[word][eid] += 1;
						else:
							emojiFreq[word][eid] = 1;
					else:
						emojiFreq[word] = dict();
						emojiFreq[word][eid] = 1;
					# update emoji-total freq
					if(eid in emojiTotalFreq.keys()):
						emojiTotalFreq[eid] += 1;
					else:
						emojiTotalFreq[eid] = 1;
			sentencePre = sentence;
	#print emojiFreq['to']

	print 'begin to sort freq'
	#print freq
	freqSorted = sorted(freq.iteritems(), key=operator.itemgetter(1))
	freqSorted.reverse()
	#print freqSorted

	print 'begin to sort emojiCnt'
	emojiCnt = dict()
	for word in freq.keys():
		emojiCnt[word] = len(emojiFreq[word].keys())
	emojiCntSorted = sorted(emojiCnt.iteritems(), key=operator.itemgetter(1))
	emojiCntSorted.reverse()
	#print emojiCntSorted

	print 'begin to sort weight'
	freqNormalized = dict()
	for word in freq.keys():
		freqNormalized[word] = float(freq[word])*float(emojiCnt[word])*float(emojiCnt[word])
	freqNormalizedSorted = sorted(freqNormalized.iteritems(), key=operator.itemgetter(1))
	freqNormalizedSorted.reverse()
	print freqNormalizedSorted




	# begin to write to sql table
	#wordExcluded = list() 
	#for excludedIdx in range(WORD_EXECLUDED_CNT):
	#	wordExcluded.append(freqNormalizedSorted[excludedIdx][0])
	wordExcluded = ['i','you','he','she','my','his','they','all','another','anybody','anyone','anything','both','each','other','either','everybody','everyone','everything','few','her','hers','herself','him','himself','it','its','itself','me','mine','more','myself','neither','nobody','none','another','other','others','ours','our','ourselfves','several','somebody','someone','something','that','which','their','theirs','them','themselves','these','those','this','us','we','which','whichever','whose','your','yours','yourself','yourselves','one','two','three','four','zero','five','six','seven','eight','nine','ten','is','was','are','were','do','does','did','be','has','have','had','haven','will','to','would','by','in','on','at','which','a','an','the','and','of','s','t','m','1','e','2','3','4','5','6','7','8','9','10','0','with','from','at','in','out','about','done','also','among','amount','an','another','been','behind','being','below','beside','during','inc']
	if wordNeedToBeHashed:
		wordExcluded = list(wordHash(w) for w in wordExcluded)
	

	print 'begin to exclude words'
	wordUsed = list()
	wordUsedWeight = list()
	for wordIdx in range(len(freqSorted)):

		wordNow = freqSorted[wordIdx][0]
		wordWeightNow = freqSorted[wordIdx][1]
		if(wordNow not in wordExcluded):
			wordUsed.append(wordNow)
			wordUsedWeight.append(wordWeightNow)
			
			if(len(wordUsed)>=WORD_USED_CNT):
				break
	print 'wordExcluded = \n'
	print wordExcluded

	#print 'wordUsed = \n'
	#print wordUsed		 		

	print '\nfinal selected words :'
	print wordUsed

	print 'begin to build sql back'
	
	sqlDrop = 'drop table if exists "main"."'+SQL_TO_TABLE_NAME+'"'
	runSql(sqlDrop)
	sqlCreate = 'CREATE  TABLE "main"."'+SQL_TO_TABLE_NAME+'" ("wid" INTEGER PRIMARY KEY  NOT NULL , "'+SQL_ENTRY_NAME+'" VARCHAR, "weight" INTEGER)'
	runSql(sqlCreate)
	for wordIdx in range(len(wordUsed)):
		sqlInsert = 'insert into '+SQL_TO_TABLE_NAME+' ("wid", "'+SQL_ENTRY_NAME+'", "weight") values ("%d", "%s", "%d")' % (wordIdx+1, wordUsed[wordIdx], wordUsedWeight[wordIdx])
		runSql(sqlInsert)
		


	# begin to parse phrase *** WARN: phrase can only be parsed after words because it needs to be the mentioned word ****
	print 'begin to parse phrase'

	# reuse the varible names *** WARN: need to take care of it ***
	phraseKeyWords = ['not','dont','cant','didnt','never','isnt','wont'] # only collect phrase in these phrase

	emojiTotalFreq = dict() # a map to classify emoji totoal cnt
	emojiFreq = dict()
	freq = dict()
	refWords = dict() # variable to record the 
	sentencePre = ""
	sentenceLen = len(sentences)
	sentenceIdx = 0
	progressPre = 0

	for (sentence,eid) in zip(sentences,eids):
		progressNow = float(sentenceIdx) / float(sentenceLen)
		if progressNow - progressPre >= 0.1:
			print "two word progressNow = %f %%" % (progressNow*100)
			progressPre = progressNow

		sentenceIdx += 1

		if sentence != sentencePre: #ignore the repeated sentence because by multiple emoji in a sentence
			words = shlex.split(sentence)

			phraseWords = list()
			# use the same preprocess for words
			for word in words:
				# ignore word contains numbers
				if not re.search('\d+', word):

					# hash the word if need
					if wordNeedToBeHashed:
						word = wordHash(word)
						
					if word in wordUsed:
						phraseWords.append(word)
			#print 'sentence = '+sentence
			#print phraseWords


			# begin to combine words together
			for phraseWordIdx in range(len(phraseWords)-1):
				word1 = phraseWords[phraseWordIdx]
				word2 = phraseWords[phraseWordIdx+1]
				phrase = word1+word2
				#print 'phrase %d is : %s' % (phraseWordIdx, phrase)
			
				if word1 in phraseKeyWords:
					# update refer
					if(phrase not in refWords.keys()):
						refWords[phrase] = [word1, word2]

					# updat totoal freq
					if(phrase in freq.keys()):
						freq[phrase] += 1;
					else:
						freq[phrase] = 1;
					# update emoji-based freq
					if(phrase in emojiFreq.keys()):
						if(eid in emojiFreq[phrase].keys()):
							emojiFreq[phrase][eid] += 1;
						else:
							emojiFreq[phrase][eid] = 1;
					else:
						emojiFreq[phrase] = dict();
						emojiFreq[phrase][eid] = 1;
		

			sentencePre = sentence;


	print 'begin to sort freq'
	#print freq
	freqSorted = sorted(freq.iteritems(), key=operator.itemgetter(1))
	freqSorted.reverse()
	print freqSorted

	print 'begin to sort emojiCnt'
	emojiCnt = dict()
	for word in freq.keys():
		emojiCnt[word] = len(emojiFreq[word].keys())
	emojiCntSorted = sorted(emojiCnt.iteritems(), key=operator.itemgetter(1))
	emojiCntSorted.reverse()
	print emojiCntSorted

	print 'begin to sort weight'
	freqNormalized = dict()
	for word in freq.keys():
		freqNormalized[word] = float(freq[word])*float(emojiCnt[word])*float(emojiCnt[word])
	freqNormalizedSorted = sorted(freqNormalized.iteritems(), key=operator.itemgetter(1))
	freqNormalizedSorted.reverse()
	print freqNormalizedSorted



	print 'begin to select phrases'
	phraseUsed = list()
	phraseUsedWeight = list()
	for phraseIdx in range(len(freqSorted)):

		phraseNow = freqSorted[phraseIdx][0]
		phraseWeightNow = freqSorted[phraseIdx][1]

		phraseUsed.append(phraseNow)
		phraseUsedWeight.append(phraseWeightNow)
			
		if(len(phraseUsed)>=PHRASE_USED_CNT):
			break


	print '\nfinal selected phrase :'
	print phraseUsed



	print 'begin to build sql back'

	sqlDrop = 'drop table if exists "main"."'+SQL_TO_PHRASE_TABLE_NAME+'"'
	runSql(sqlDrop)
	sqlCreate = 'CREATE  TABLE "main"."'+SQL_TO_PHRASE_TABLE_NAME+'" ("pid" INTEGER PRIMARY KEY  NOT NULL , "phrase" VARCHAR, "word1" VARCHAR, "word2" VARCHAR, "weight" INTEGER)'
	runSql(sqlCreate)
	for phraseIdx in range(len(phraseUsed)):
		phraseNow = phraseUsed[phraseIdx]
		phraseRefWords = refWords[phraseNow]
		word1 = phraseRefWords[0]
		word2 = phraseRefWords[1]
		sqlInsert = 'insert into '+SQL_TO_PHRASE_TABLE_NAME+' ("pid", "phrase", "word1", "word2", "weight") values ("%d", "%s", "%s", "%s", "%d")' % (phraseIdx+1, phraseNow, word1, word2, phraseUsedWeight[phraseIdx])
		runSql(sqlInsert)
	
	#for wordIdx = 

	#print emojiTotalFreq

	#eomjiRatio = dict()
	#for word in freq.keys():
		#ratios = np.zeros(len(emojiTotalFreq.keys()))
		#for (i,eid) in enumerate(emojiTotalFreq.keys()):
		#ratios = np.zeros(len(emojiFreq[word].keys()))
		#for (i,eid) in enumerate(emojiFreq[word].keys()):
			#if(eid in emojiFreq[word].keys()):
				#ratios[i] = float(emojiFreq[word][eid])/float(emojiTotalFreq[eid])
				#if(word == 'i'):
				#	print str(emojiFreq[word][eid])+"/"+str(emojiTotalFreq[eid])
			#else:
				#ratios[i] = 0
		#if(word == 'sad'):
			#print emojiFreq[word]
			#print ratios
			#print np.sum(ratios)
			#print np.var(ratios)	
			#print np.var(ratios)*len(emojiFreq[word])
			#plt.plot(np.sort(ratios))
			#plt.show()
	return freqSorted,emojiCntSorted

if __name__ == '__main__':

	estimateFreq()
	
	print "END OF WORD PROCESSING"


