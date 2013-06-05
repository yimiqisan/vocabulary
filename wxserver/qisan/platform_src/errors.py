# -*- coding:utf-8 -*-

import sys
import types

_self = sys.modules[__name__]

class QisanException(Exception):
    pass

class QisanEnvironError(QisanException):
    pass

class QisanConfigError(QisanException):
    '''
    服务器配置错误，阻止启动
    '''
    pass

