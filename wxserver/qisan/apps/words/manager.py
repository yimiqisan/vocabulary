#!/usr/bin/env python
# encoding: utf-8
"""
manager.py

Created by 刘 智勇 on 2013-06-02.
Copyright (c) 2013 __MyCompanyName__. All rights reserved.
"""

from __future__ import with_statement

from flask import Flask, abort, request, _app_ctx_stack
from sqlite3 import dbapi2 as sqlite3
import json
from hashlib import sha1
from lxml import etree
from StringIO import StringIO
from datetime import datetime, timedelta


# configuration
DATABASE = '/tmp/qisan.db'
USERNAME = 'qisan'
password = 'qisan'


app = Flask(__name__)
app.debug = True
app.config.from_object(__name__)


ISO_DATE_FORMAT = '%Y-%m-%d'
_sha1 = lambda x: sha1(x).hexdigest()
YESTERDAY = (datetime.today() - timedelta(days=1)).date().isoformat()
TOKEN = 'b61e7ad8c5194994903cd11be6160dc0'

def init_db():
	with app.app_context():
		db = get_db()
		with app.open_resource('schema.sql', mode='r') as f:
			db.cursor().executescript(f.read())
		db.commit()

def get_db():
	top = _app_ctx_stack.top
	if not hasattr(top, 'sqlite_db'):
		sqlite_db = sqlite3.connect(app.config['DATABASE'])
		sqlite_db.row_factory = sqlite3.Row
		top.sqlite_db = sqlite_db
	return top.sqlite_db

@app.teardown_appcontext
def close_db_connection(exception):
	"""Closes the database again at the end of the request."""
	top = _app_ctx_stack.top
	if hasattr(top, 'sqlite_db'):
		top.sqlite_db.close()

def check_xml_wf(xml):
	""" 使用lxml.etree.parse 检测xml是否符合语法规范"""
	# 参数xml是经过StringIO处理过的instance类型
	try:
		xml = etree.parse(xml)
		return xml
	except etree.XMLSyntaxError, e:
		return False

def get_message_data(xml):
	"""解析xml 提取其中数据 并存入一个dict"""
	data_dict = {}
	for node in xml.iter():
		data_dict[node.tag] = node.text
	return data_dict


def _check_signature(message):
	signature = message.pop('signature')
	keylist = list(message)
	keylist.sort()
	compare = ''.join([str(message[key]) for key in keylist])
	other_keylist = ['timestamp', 'nonce', 'token']
	other_compare = ''.join([str(message[key]) for key in other_keylist])
	return signature == _sha1(compare) or signature == _sha1(other_compare)

@app.route('/wx', methods=['GET'])
def wx_get():
	message = request.args.to_dict()
	echostr = message.pop('echostr', 'error')
	message['token'] = TOKEN
	if not _check_signature(message):
		abort(404)
	return echostr


def prepare_reply_data(from_user_name, to_user_name, content):
	"""准备消息需要返回数据"""
	reply_dict = {}
	reply_dict['ToUserName'] = from_user_name
	reply_dict['FromUserName'] = to_user_name
	reply_dict['CreateTime'] = int(time())
	db = get_db()
	cur = db.execute('select word, meaning from words order by id desc')
	entries = cur.fetchall()
	replies = [dict(entry) for entry in entries]
	reply = reply_message(reply_dict, replies)
	return reply


def reply_message(user_info, replies):
	if not replies:
		return ''
	if not isinstance(replies, list):
		replies = [replies]
	if ask.reply_type == 'text':
		user_info.update(replies[0])
		xml = TEXT_TPL.format(**user_info)
	if check_xml_wf(StringIO(xml)):
		logger.error(str(xml))
		return xml
	else:
		return ''


@app.route('/wx', methods=['POST'])
def wx_post():
	result = ''
	postStr = request.data
	xml = StringIO(postStr)
	xml_str = check_xml_wf(xml)
	if xml_str is False:
		return False
	message_dict = get_message_data(xml_str)
	try:
		to_user_name = message_dict['ToUserName']
		from_user_name = message_dict['FromUserName']
		content = message_dict.get('Content', '').strip()
		event = message_dict.get('Event', '').strip()
		event_key = message_dict.get('EventKey', '').strip()
		message_type = message_dict['MsgType']
	except KeyError, e:
		return result
	return '你好'


@app.route('/')
@app.route('/<dtime>')
def retrieve(dtime=YESTERDAY):
	try:
		load_date = datetime.strptime(dtime, ISO_DATE_FORMAT)
	except ValueError:
		return 'date format error should [year-month-day]'
	db = get_db()
	cur = db.execute('select word, meaning from words order by id desc')
	entries = cur.fetchall()
	return json.dumps([dict(entry) for entry in entries])

@app.route('/add', methods=['POST'])
def create():
	db = get_db()
	try:
		db.execute('insert into words (word, meaning) values (?, ?)',
			[request.form['word'], request.form['meaning']])
		db.commit()
	except:
		return 'err'
	return 'ok'


if __name__ == '__main__':
	init_db()
	app.run(host='0.0.0.0', port=80)

