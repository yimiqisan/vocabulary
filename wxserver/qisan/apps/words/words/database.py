#!/usr/bin/env python
# encoding: utf-8
"""
database.py

Created by 刘 智勇 on 2013-06-02.
Copyright (c) 2013 __MyCompanyName__. All rights reserved.
"""

from flask import _app_ctx_stack
from sqlite3 import dbapi2 as sqlite3

SQL_FILE = 'schema.sql'


class DataBase(object):

    def __init__(self, app, dbname, username=None, password=''):
        self.app = app
        self.dbname = dbname
        self.username = username
        self.password = password

    def init(self):
        with self.app.app_context():
            db = self.get()
            with self.app.open_resource(SQL_FILE, mode='r') as f:
                db.cursor().executescript(f.read())
            db.commit()

    def get(self):
        top = _app_ctx_stack.top
        if not hasattr(top, 'sqlite_db'):
            sqlite_db = sqlite3.connect(app.config['DATABASE'])
            sqlite_db.row_factory = sqlite3.Row
            top.sqlite_db = sqlite_db
        return top.sqlite_db

    @app.teardown_appcontext
    def close_connect(self):
        """Closes the database again at the end of the request."""
        top = _app_ctx_stack.top
        if hasattr(top, 'sqlite_db'):
            top.sqlite_db.close()
