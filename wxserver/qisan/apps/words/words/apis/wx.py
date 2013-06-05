#!/usr/bin/env python
# encoding: utf-8
"""
wx.py

Created by 刘 智勇 on 2013-06-02.
Copyright (c) 2013 __MyCompanyName__. All rights reserved.
"""

import time
from lxml import etree
from hashlib import sha1
from StringIO import StringIO

_sha1 = lambda x: sha1(x).hexdigest()


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
        return xml
    else:
        return ''
