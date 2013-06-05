#!/usr/bin/env python
# encoding: utf-8
"""
manager.py

Created by 刘 智勇 on 2013-06-02.
Copyright (c) 2013 __MyCompanyName__. All rights reserved.
"""

from __future__ import with_statement

from flask import Flask, abort, request, Blueprint
import json
import yaml
from datetime import datetime, timedelta
from StringIO import StringIO


app = Blueprint('app', __name__)

from database import DataBase


class ConfigurationError(Exception):
    pass


def load_yaml(yamlfile):
    environ = 'STAGING'
    with open(yamlfile, 'rb') as fp:
        conf = yaml.load(fp.read())
#    host_conf = 'HOST:%s' % socket.gethostname()
#    if host_conf in conf:
#        return conf[host_conf]
    try:
        return conf[environ]
    except KeyError:
        raise ConfigurationError('The config file %s does not provide '
            'environment support of %s' % (yamlfile, environ))

CONF = load_yaml('/home/qisan/workspace/vocabulary/wxserver/qisan/apps/words/app.yaml')
app.debug = CONF['DEBUG']
app.config.from_object(__name__)
WX_TOKEN = CONF['WX_TOKEN']

DATE_FMT = CONF['DATE_FMT']
YESTERDAY = (datetime.today() - timedelta(days=1)).date().isoformat()


def main():
    db = DataBase(app, CONF['DBNAME'], CONF['USERNAME'], CONF['PASSWORD'])
    db.init()
    app.run(host='0.0.0.0')


@app.route('/wx', methods=['GET'])
def wx_get():
    message = request.args.to_dict()
    echostr = message.pop('echostr', 'error')
    message['token'] = WX_TOKEN
    if not _check_signature(message):
        abort(404)
    return echostr

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
        load_date = datetime.strptime(dtime, DATE_FMT)
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
    main()
