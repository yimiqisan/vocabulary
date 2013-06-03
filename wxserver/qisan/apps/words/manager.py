#!/usr/bin/env python
# encoding: utf-8
"""
manager.py

Created by 刘 智勇 on 2013-06-02.
Copyright (c) 2013 __MyCompanyName__. All rights reserved.
"""

from __future__ import with_statement

from flask import Flask, request, _app_ctx_stack
from sqlite3 import dbapi2 as sqlite3
import json
from datetime import datetime, timedelta


# configuration
DATABASE = '/tmp/qisan.db'
USERNAME = 'qisan'
password = 'qisan'


app = Flask(__name__)
app.debug = True
app.config.from_object(__name__)


ISO_DATE_FORMAT = '%Y-%m-%d'
YESTERDAY = (datetime.today() - timedelta(days=1)).date().isoformat()


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

@app.route('/')
@app.route('/<dtime>')
def retrieve(dtime=YESTERDAY):
	try:
		load_date = datetime.strptime(dtime, ISO_DATE_FORMAT)
	except ValueError:
		app.logger.error('date format error should [year-month-day]')
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
	app.run(host='0.0.0.0')

