# -*- coding:utf-8 -*-

import sys
import types

_self = sys.modules[__name__]

class GuokrException(Exception):
    pass

class GuokrEnvironError(GuokrException):
    pass

class GuokrConfigError(GuokrException):
    '''
    服务器配置错误，阻止启动
    '''
    pass

