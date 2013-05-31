# -*- coding: utf-8 -*-
'''
File: wxserver.py
Author: yimiqisan
Date: 2013-05-31 17:46:24 CST
Description: 微信七三记单词
'''


import os
import logging
from datetime import datetime
from hashlib import sha1

#生成32位随机字符串
token = 'b61e7ad8c5194994903cd11be6160dc0'

__all__ = []

logger = None
log_path = "."
_sha1 = lambda x: sha1(x).hexdigest()

def init_logger(log_level=logging.ERROR):
    global logger
    if not os.path.exists(log_path):
        os.mkdir(log_path)
    log_file_name = '%s/wx_ask_log_%s.log' % (
        log_path, datetime.now().strftime("%Y-%m-%d"))
    if logger is None:
        logger = logging.getLogger('wdlogger')
        file_handler = logging.FileHandler(log_file_name)
        file_handler.setLevel(log_level)
        format = logging.Formatter(
            '%(asctime)s %(name)-8s %(levelname)-8s %(message)s')
        file_handler.setFormatter(format)
        logger.addHandler(file_handler)

def _check_signature(message):
    signature = message.pop('signature')
    logger.error('[_check_signature]> signature: %s' % signature)
    logger.error(message)

    keylist = list(message)
    keylist.sort()
    logger.error(keylist)
    compare = ''.join([str(message[key]) for key in keylist])

    other_keylist = ['timestamp', 'nonce', 'token']
    other_compare = ''.join([str(message[key]) for key in other_keylist])
    return signature == _sha1(compare) or signature == _sha1(other_compare)

def get_message_data(xml):
    """解析xml 提取其中数据 并存入一个dict"""
    data_dict = {}

    for node in xml.iter():
        data_dict[node.tag] = node.text
    return data_dict
