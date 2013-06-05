#!/usr/bin/env python
# encoding: utf-8
"""
manager.py

Created by 刘 智勇 on 2013-06-05.
Copyright (c) 2013 __MyCompanyName__. All rights reserved.
"""

import sys
from argparse import ArgumentParser
APP_CHOICES = ['words']
PARSER_HELP = 'APP NAME %s' % str(APP_CHOICES)





def run_server(app_name):
    base_path = os.getcwd()
    app = Flask(app_name)


def main():
    parser = ArgumentParser(usage=usage_doc, description='qisan workspace')
#    parser.add_argument('-f', default=fromdate_default, type=str, \
#        help='date from [format:%s]' % ISODATE_FORMAT)
    parser.add_argument('app', type=str, \
        choices=APP_CHOICES, \
        help=PARSER_HELP)
    args = parser.parse_args()

    if args.app == 'words':
        run_server(args.app)
    else:
        print PARSER_HELP

if __name__ == '__main__':
    main()
