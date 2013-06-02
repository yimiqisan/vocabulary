#! /usr/bin/env bash

. $BASE/tools/functions.sh

missing() {
    if dpkg -s $1 >/dev/null 2>/dev/null; then
        return 1
    else
        return 0
    fi
}

apt_install() {
    if missing $1; then
        echo_info "Installing $1..."
        sudo apt-get install $1 -y
    fi
}

apt_purge() {
    missing $1
    if [ $? -ne 0 ]; then
        echo_info "Uninstalling $1..."
        sudo apt-get purge $1 -y
    fi
}

pip_install() {
    if [ -z $(pip-2.7 freeze 2>/dev/null | grep $1) ]; then
        echo_info "Installing $1..."
        if [ -n "$2" ]; then
            sudo pip-2.7 install $2
        else
            sudo pip-2.7 install $1
        fi
    fi
}

dir_install() {
    if [ ! -d $1 ]; then
        echo_info "Making dir $1..."
        sudo install -d $1
    fi
}

file_install() {
    if [ ! -f $2 ]; then
        echo_info "Installing $1 to $2..."
        sudo install -TCm 0644 $1 $2
    fi
}

#apt_install gfortran
#apt_install libatlas-dev
#apt_install libatlas-base-dev
#apt_install postgresql-server-dev-9.1
#apt_install texlive-fonts-recommended
#apt_install texlive-latex-recommended

apt_install gcc

# 在数据库服务器安装下述软件
# apt_install redis-server
# apt_install postgresql-9.1
# apt_install rabbitmq-server

# 在图像服务器安装下述软件
#
#
# # JPEG 处理
# apt_install libjpeg8-dev
#
# # 文字处理
# apt_install libfreetype6-dev
#
# # GIF 缩放
# apt_install gifsicle
#
# # LaTex 公式生成器支持
# apt_install texlive-base
# apt_install texlive-latex-extra
# apt_install dvipng
# apt_install latex-cjk-chinese
#
# # 安装texlive-latex-extra时带上了这么一堆傻逼玩意
# # 700多MB还死乞白赖地要一起安装, 直接卸掉
# apt_purge texlive-latex-extra-doc
# apt_purge texlive-latex-recommended-doc
# apt_purge texlive-pictures-doc
# apt_purge texlive-pstricks-doc
#
# # Web2PNG (长微博)
# apt_install python-qt4
# apt_install libqt4-webkit
# apt_install xvfb

apt_install libpq-dev
apt_install libpcre3-dev
apt_install libyaml-0-2
apt_install libyaml-dev
apt_install libjansson4
apt_install libjansson-dev
apt_install python2.7
apt_install python2.7-dev
apt_install libxml2-dev
apt_install libxslt1-dev
apt_install zlib1g-dev
#apt_install mercurial

apt_install openjdk-7-jdk
reset_java $(java7_path)
apt_install maven2

if [ -z $(which pip-2.7) ]; then
    sudo python2.7 $BASE/tools/get-pip.py
fi

if [[ $GUOKR_ENVIRON != "PRODUCTION" ]]; then
    apt_install php5-cli  # arcanist required
    apt_install php5-curl
    apt_install nginx-extras
    dir_install /var/lib/nginx/body/
    dir_install /var/lib/nginx/fastcgi/
    dir_install /var/lib/nginx/proxy/
    dir_install /var/lib/nginx/scgi/
    dir_install /var/lib/nginx/uwsgi/
    apt_purge mercurial
    pip_install mercurial==2.5.4 $BASE/tools/python-packages/mercurial-2.5.4.tar.gz
    pip_install pep8==1.4.5 $BASE/tools/python-packages/pep8-1.4.5.tar.gz
    pip_install pyflakes==0.7.2 $BASE/tools/python-packages/pyflakes-0.7.2.tar.gz
    pip_install mccabe==0.2.1 $BASE/tools/python-packages/mccabe-0.2.1.tar.gz
    pip_install flake8==2.0 $BASE/tools/python-packages/flake8-2.0.tar.gz
    pip_install hghooks==0.5.5 $BASE/tools/python-packages/hghooks-0.5.5.tar.gz
    dir_install /etc/mercurial/hgrc.d/
    dir_install /etc/bash_completion.d/
    file_install $BASE/tools/mercurial/etc/mercurial/hgrc /etc/mercurial/hgrc
    file_install $BASE/tools/mercurial/etc/mercurial/hgrc.d/cacerts.rc /etc/mercurial/hgrc.d/cacerts.rc
    file_install $BASE/tools/mercurial/etc/mercurial/hgrc.d/mergetools.rc /etc/mercurial/hgrc.d/mergetools.rc
    file_install $BASE/tools/mercurial/etc/bash_completion.d/mercurial /etc/bash_completion.d/mercurial
    file_install $BASE/tools/mercurial/hgflow.py $(python -c "from distutils.sysconfig import get_python_lib; print(get_python_lib())")/hgflow.py
fi
pip_install virtualenv==1.9.1 $BASE/tools/python-packages/virtualenv-1.9.1.tar.gz
