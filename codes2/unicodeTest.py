# -*- coding: utf-8 -*-

import json

x = u'台南一中'
x = u'😃'
x = u'\ufe0f'
print unicode(x)
print x.encode('utf-8')
jString = json.dumps(x)
print jString

jLoad = json.loads(jString)
print jLoad
