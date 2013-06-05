# -*- coding: utf-8 -*-
from __future__ import unicode_literals
"""
配置管理模块
~~~~~~~~~~~~

从 app.yaml 中载入当前 app 的配置, 并写入对应的 app 实例中.

"""
import os
import yaml
import socket

from guokr.platform.errors import QisanException
from guokr.platform.errors import QisanEnvironError

class ConfigurationError(QisanException):
    pass

def load_yaml(yamlfile):
    try:
        environ = os.environ['GUOKR_ENVIRON']
    except KeyError:
        raise QisanEnvironError(
            'Environment variable GUOKR_ENVIRON is not provided')
    with open(yamlfile, 'rb') as fp:
        conf = yaml.load(fp.read())
    host_conf = 'HOST:%s' % socket.gethostname()

    if host_conf in conf:
        return conf[host_conf]
    try:
        return conf[environ]
    except KeyError:
        raise ConfigurationError('The config file %s does not provide '
            'environment support of %s' % (yamlfile, environ))
