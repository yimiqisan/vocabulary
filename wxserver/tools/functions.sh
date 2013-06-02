echo_info() {
    echo -e "\033[0;32;1m$1\033[0m"
}

echo_error() {
    echo -e "\033[0;31;1m$1\033[0m"
}

python_lib() {
    python2.7 -c "from distutils.sysconfig import get_python_lib; print(get_python_lib())"
}

os_bit() {
    if [ -z $(uname -m | grep '_64') ]; then
        echo 'i386'
    else
        echo 'amd64'
    fi
}

java7_path() {
    java7=/usr/lib/jvm/java-7-openjdk-$(os_bit)/jre/bin/java
    if [ -f $java7 ]; then
        echo $java7
    elif [ -f /usr/bin/java ]; then
        java7=/usr/bin/java
        echo $java7
    else
        java7=/usr/lib/jvm/java-7-openjdk/jre/bin/java
        if [-f $java7]; then
            echo $java7
        else
            echo "Java 7 path is unknown"
        fi
    fi
}

reset_java() {
    if [ -f "$1" ]; then
        if [ -z "$(java -version 2>&1 | grep 1.7)" ]; then
            sudo update-alternatives --set java $1
        fi
    else
        echo_error "Could not found java 7, please update your java system manually..."
    fi
}

upgrade_java() {
    if [ -z $(java -version | grep '1.7.') ]; then
        echo_info "Java version is OK!"
    else
        reset_java $(java7_path)
    fi
}

v_install() {
    $VIRTUALENV_BIN \
        $VIRTUALENV_PATH
    v_activate
    upgrade
}

v_activate() {
    GLOBAL_PKG=$(python_lib)
    source "$VIRTUALENV_PATH/bin/activate"
    VIRT_PKG=$VIRTUALENV_PATH/lib/python2.7/site-packages
    if [ \( ! -d $VIRT_PKG/guokr/platform \) -o \
        \( "$(readlink $VIRT_PKG/guokr/platform|xargs basename 2>/dev/null)" != "platform_src" \) ]; then
        rm -rf $VIRT_PKG/guokr
        mkdir -p $VIRT_PKG/guokr
        touch $VIRT_PKG/guokr/__init__.py
        ln -s ../../../../../guokr/platform_src $VIRT_PKG/guokr/platform
    fi
    if [ \( -d $GLOBAL_PKG/PyQt4 \) -a \
         \( ! -d $VIRT_PKG/PyQt4 \) ]; then
        ln -s "$GLOBAL_PKG/PyQt4" "$VIRT_PKG"
    fi
    if [ \( -f $GLOBAL_PKG/sip.so \) -a \
         \( ! -f $VIRT_PKG/sip.so \) ]; then
        ln -s "$GLOBAL_PKG/sip.so" "$VIRT_PKG"
    fi
    if [ \( -f $GLOBAL_PKG/sipconfig.py \) -a \
         \( ! -f $VIRT_PKG/sipconfig.py \) ]; then
        ln -s "$GLOBAL_PKG/sipconfig.py" "$VIRT_PKG"
    fi
    if [ ! -f $VIRTUALENV_PATH/bin/lein ]; then
        ln -s $BASE/algo/avalon/leiningen/lein $VIRTUALENV_PATH/bin
    fi
    export PATH="$PATH:$BASE/tools/phabricator/arcanist/bin"
}

freeze() {
    v_activate
    command pip freeze > $REQUIREMENTS
    sort $REQUIREMENTS -o $REQUIREMENTS
    sort $STAGING_REQUIREMENTS -o $STAGING_REQUIREMENTS
    comm -3 $REQUIREMENTS $STAGING_REQUIREMENTS | sed s/^\\s*//g > /tmp/.requirements.txt
    cat $REQUIREMENT_EXCLUDES >> /tmp/.requirements.txt
    uniq /tmp/.requirements.txt | sort -o /tmp/.requirements.txt
    comm -3 /tmp/.requirements.txt $REQUIREMENT_EXCLUDES | sed s/^\\s*//g > $REQUIREMENTS
}

staging_freeze() {
    v_activate
    command pip freeze > $STAGING_REQUIREMENTS
    sort $REQUIREMENTS -o $REQUIREMENTS
    sort $STAGING_REQUIREMENTS -o $STAGING_REQUIREMENTS
    comm -3 $REQUIREMENTS $STAGING_REQUIREMENTS | sed s/^\\s*//g > /tmp/.requirements.txt
    cat $REQUIREMENT_EXCLUDES >> /tmp/.requirements.txt
    uniq /tmp/.requirements.txt | sort -o /tmp/.requirements.txt
    comm -3 /tmp/.requirements.txt $REQUIREMENT_EXCLUDES | sed s/^\\s*//g > $STAGING_REQUIREMENTS
}

freeze_download() {
    freeze
    command pip install -r $REQUIREMENTS \
        --download=$PYTHON_PACKAGES
}

staging_freeze_download() {
    staging_freeze
    command pip install -r $STAGING_REQUIREMENTS \
        --download=$PYTHON_PACKAGES
}

uwsgi_version() {
    uwsgi --version
}

jwsgi_install() {
    UWSGI_EMPEROR="$VIRTUALENV_PATH/etc/uwsgi/vassals"
    mkdir -p $UWSGI_EMPEROR
    pushd . > /dev/null
    cd $BASE/.py/etc/uwsgi/vassals
    if [ "$(uwsgi --plugins jvm,jwsgi 2>&1|grep 'UNABLE to load uWSGI plugin')" ]; then
        echo_info "Installing jvm and jwsgi plugins for uwsgi..."
        mkdir $BASE/build
        UWSGI_VERSION=`uwsgi_version`
        cp $BASE/tools/python-packages/uwsgi-$UWSGI_VERSION.tar.gz $BASE/build
        cd $BASE/build
        tar -xvf uwsgi-$UWSGI_VERSION.tar.gz
        cd uwsgi-$UWSGI_VERSION
        python uwsgiconfig.py --build core
        python uwsgiconfig.py --plugin plugins/jvm core
        python uwsgiconfig.py --plugin plugins/jwsgi core
        cp ./jvm_plugin.so $BASE/.py/etc/uwsgi/vassals
        cp ./jwsgi_plugin.so $BASE/.py/etc/uwsgi/vassals
        echo $UWSGI_VERSION | cat
        cd $BASE
        rm -rf $BASE/build
    fi
    popd > /dev/null
}

get_all_algo_libs() {
    for project in $(find $BASE/algo/arsenal -name "project.clj"); do
        echo $(dirname $project|xargs basename)
    done
}

get_all_algo_knights() {
    for project in $(find $BASE/algo/knights -name "project.clj"); do
        echo $(dirname $project|xargs basename)
    done
}

lein_jar() {
    lein clean
    lein javac
    lein jar 2>lein_errmsg
    if [ -z "$(cat lein_errmsg | grep 'Exception in thread')" ]; then
        echo_info "Build success!"
    else
        rm $1
        echo_error "Build failure!"
        cat lein_errmsg
    fi
    rm lein_errmsg
    lein install
}

lein_build_jar() {
    TIMESTAMPS="$VIRTUALENV_PATH/timestamps"
    LEIN_KIND=lein-jar-$1
    LEIN_LIB=$BASE/algo/arsenal/$1
    LEIN_TARGET=$BASE/algo/arsenal/$1/target
    LEIN_FAILS="$TIMESTAMPS/$LEIN_KIND.timestamp"
    mkdir -p $TIMESTAMPS
    pushd . > /dev/null
    echo_info "Building algo project: $1 ..."
    cd $BASE/algo/arsenal/$1
    if [ -n "$(python $BASE/tools/latest.py $LEIN_KIND $LEIN_LIB $TIMESTAMPS '^.*\.clj$' $LEIN_TARGET)" ]; then
        lein_jar $LEIN_FAILS
        rm -f $TIMESTAMPS/lein-uberjar-*.timestamp
    fi
    popd > /dev/null
}

lein_build_jar_all() {
    for app in $(get_all_algo_libs); do
        lein_build_jar $app
    done
}

lein_uberjar() {
    lein clean
    lein javac
    lein uberjar 2>lein_errmsg
    if [ -z "$(cat lein_errmsg | grep 'Exception in thread')" ]; then
        echo_info "Build success!"
    else
        rm $1
        echo_error "Build failure!"
        cat lein_errmsg
    fi
    rm lein_errmsg
}

lein_build_uberjar() {
    TIMESTAMPS="$VIRTUALENV_PATH/timestamps"
    LEIN_KIND=lein-uberjar-$1
    LEIN_KNIGHT=$BASE/algo/knights/$1
    LEIN_TARGET=$BASE/algo/knights/$1/target
    LEIN_FAILS="$TIMESTAMPS/$LEIN_KIND.timestamp"
    mkdir -p $TIMESTAMPS
    pushd . > /dev/null
    echo_info "Building uberjar for algo project: $1 ..."
    cd $BASE/algo/knights/$1
    if [ -n "$(python $BASE/tools/latest.py $LEIN_KIND $LEIN_KNIGHT $TIMESTAMPS '^.*\.clj$' $LEIN_TARGET)" ]; then
        lein_uberjar $LEIN_FAILS
    fi
    popd > /dev/null
}

lein_build_uberjar_all() {
    for app in $(get_all_algo_knights); do
        lein_build_uberjar $app
    done
}

upgrade() {
    v_activate
    command pip install -r $REQUIREMENTS \
        --find-links=file://$PYTHON_PACKAGES \
        --no-index
    # s=$(uwsgi --json 2>&1)
    if [ -n "$(uwsgi --json 2>&1|grep 'unrecognized')" ]; then
        command pip install -U uwsgi \
            --find-links=file://$PYTHON_PACKAGES \
            --no-index
    fi

    # 暂时不打开 jwsgi
    #jwsgi_install

    upgrade_java
    # 暂时关闭 jar 编译, 未来考虑探测是否需要重新编译, 只给提示
    #lein_build_jar_all
    #lein_build_uberjar_all
    eval $(python $BASE/tools/load_yaml.py $BASE/guokr.yaml)
}

staging_upgrade() {
    v_activate
    command pip install -r $STAGING_REQUIREMENTS \
        --find-links=file://$PYTHON_PACKAGES \
        --no-index
}

detect_environ() {
    if [ -n "${GUOKR_ENVIRON}" ]; then
        return
    fi
    if [ -n "$(echo $HOSTNAME | grep gkserver)" ]; then
        export GUOKR_ENVIRON="PRODUCTION"
    elif [ -n "$(echo $HOSTNAME | grep qaserver)" ]; then
        export GUOKR_ENVIRON="STAGING"
    else
        export GUOKR_ENVIRON="DEVELOPMENT"
    fi
}

pip() {
    if [[ $1 == "install" ]]; then
        command pip $@ \
            --index-url=http://g.pypi.python.org/simple/ \
            --download=$PYTHON_PACKAGES --no-install
        command pip $@ \
            --find-links=file://$PYTHON_PACKAGES \
            --no-index
        freeze
    elif [[ $1 == "staging_install" ]]; then
        command pip install ${@:2} \
            --index-url=http://g.pypi.python.org/simple/ \
            --download=$PYTHON_PACKAGES --no-install
        command pip install ${@:2} \
            --find-links=file://$PYTHON_PACKAGES \
            --no-index
        staging_freeze
    else
        command pip $@
    fi
}


_uwsgi_common() {
    env UWSGI_VASSAL_VIRTUALENV="$VIRTUALENV_PATH" \
        UWSGI_VASSAL_SET="base_dir=$BASE" uwsgi \
        --virtualenv="$VIRTUALENV_PATH" \
        --pidfile="$UWSGI_PIDFILE" \
        --log-maxsize="$UWSGI_LOG_MAXSIZE" \
        --cpu-affinity="$UWSGI_CPU_AFFINITY" \
        --emperor="$UWSGI_EMPEROR" \
        $@ \
        --memory-report \
        --log-zero \
        --log-slow \
        --log-4xx \
        --log-5xx \
        --log-big \
        --log-sendfile
}

uwsgi_start() {
    echo -n "Starting $UWSGI_DESC: "
    if kill -0 $(cat $UWSGI_PIDFILE 2>/dev/null) 2>/dev/null; then
        echo_error "failed."
        echo "  $UWSGI_NAME is already running."
    else
        _uwsgi_common --daemonize="$UWSGI_LOGFILE"
        echo_info "$UWSGI_NAME."
    fi
}

uwsgi_debug() {
    echo -n "Starting $UWSGI_DESC: "
    if kill -0 $(cat $UWSGI_PIDFILE 2>/dev/null) 2>/dev/null; then
        echo_error "failed."
        echo "  $UWSGI_NAME is already running."
    else
        _uwsgi_common --catch-exceptions
        echo_info "$UWSGI_NAME."
    fi
}

uwsgi_reload() {
    echo -n "Reloading $UWSGI_DESC: "
    source "$VIRTUALENV_PATH/bin/activate"
    error=$(uwsgi --reload $UWSGI_PIDFILE 2>&1 >/dev/null)
    if [ -z "$error" ]; then
        echo_info "$UWSGI_NAME."
    else
        echo_error "failed."
        echo "  $error"
    fi
}

uwsgi_stop() {
    echo -n "Stopping $UWSGI_DESC: "
    source "$VIRTUALENV_PATH/bin/activate"
    error=$(uwsgi --stop $UWSGI_PIDFILE 2>&1 >/dev/null)
    if [ -z "$error" ]; then
        echo_info "$UWSGI_NAME."
    else
        echo_error "failed."
        echo "  $error"
    fi
}

uwsgi_restart() {
    uwsgi_stop
    while kill -0 $(cat $UWSGI_PIDFILE 2>/dev/null) 2>/dev/null ; do
        echo -n '.'
    done
    uwsgi_start
}

celery_restart() {
   echo -n "Restarting $CELERY_DESC: "
   OLDPID=$(cat $CELERY_PIDFILE 2>/dev/null)
   if [ -z "$OLDPID" ]; then
       echo_error "pidfile not found, failed."
       return 1
   fi
   kill -HUP $OLDPID
       sleep 1
   while kill -0 $OLDPID 2>/dev/null ; do
       echo -n '.'
       sleep 1
   done
   echo_info "$CELERY_NAME."
}

nginx_test() {
    nginx -p $BASE/.py/etc/nginx -c $BASE/.py/etc/nginx/nginx.conf -t
}

nginx_render() {
    $BASE/tools/nginx/render.py
    nginx -p $BASE/.py/etc/nginx -c $BASE/.py/etc/nginx/nginx.conf -t
}

nginx_reload() {
    echo -n "Reloading nginx: "
    if nginx -p $BASE/.py/etc/nginx -c $BASE/.py/etc/nginx/nginx.conf -s reload 2>/dev/null; then
        echo_info "nginx."
    else
        echo_error "failed."
    fi
}

nginx_stop() {
    echo -n "Stoping nginx: "
    if nginx -p $BASE/.py/etc/nginx -c $BASE/.py/etc/nginx/nginx.conf -s stop 2>/dev/null; then
        echo_info "nginx."
    else
        echo_error "failed."
    fi
}

nginx_start() {
    echo -n "Starting nginx: "
    if nginx -p $BASE/.py/etc/nginx -c $BASE/.py/etc/nginx/nginx.conf 2>/dev/null; then
        echo_info "nginx."
    else
        echo_error "failed."
    fi
}

nginx_restart() {
    echo -n "Restarting nginx: "
    nginx -p $BASE/.py/etc/nginx -c $BASE/.py/etc/nginx/nginx.conf -s stop 2>/dev/null
    if nginx -p $BASE/.py/etc/nginx -c $BASE/.py/etc/nginx/nginx.conf 2>/dev/null; then
        echo_info "nginx."
    else
        echo_error "failed."
    fi
}

goodbye() {
    deactivate
    unset BASE
    unset VIRTUALENV_BIN
    unset REQUIREMENTS
    unset VIRTUALENV_PATH
    unset PYTHON_PACKAGES
    unset LD_RUN_PATH
    unset $(env|cut -d= -f1|egrep '^GUOKR_')
    unset -f pip
    unset -f upgrade
    unset -f freeze
    unset -f freeze_download
    unset -f staging_freeze
    unset -f staging_freeze_download
    unset -f manage
    unset -f $(typeset -F|awk '{print $3}'|egrep '^(_?uwsgi_|_manage|v_)')
    unset -f goodbye
}

v_is_install() {
    if [ -d $VIRTUALENV_PATH ]; then
        return 0
    else
        return 1
    fi
}

complete_hello() {
    COMPREPLY=()
    cur=${COMP_WORDS[COMP_CWORD]}

    method="freeze upgrade deactivate quit"

    #
    # Only complete on the first term.
    #
    if [ $COMP_CWORD -eq 1 ]; then
        COMPREPLY=( $(compgen -W "${method}" -- ${cur}) )
        return 0
    fi
}

complete -F complete_hello hello.sh

get_all_confs() {
    echo $(find $BASE/guokr/apps -name "app.yaml")
    echo $(find $BASE/guokr/services -name "app.yaml")
    #echo $(find $BASE/guokr/router -name "app.yaml")
    echo $(find $BASE/algo/knights -name "app.yaml")
}

get_all_apps() {
    for conf in $(get_all_confs); do
        echo $(dirname $conf|xargs basename)
    done
}

get_enabled_apps() {
    for vassal in $(find $UWSGI_EMPEROR -name "*.json"); do
        basename $vassal|cut -d. -f1
    done
}

get_conf() {
    for vassal in $(get_all_confs); do
        v=$(echo $vassal|grep $1/app.yaml)
        if [ -n "$v" ]; then
            echo $v
            return
        fi
    done
}

get_all_cron_confs() {
    echo $(find $BASE/guokr/apps -name "cron.yaml")
    echo $(find $BASE/algo/knights -name "cron.yaml")
}

get_cron_conf() {
    all_confs=$(get_all_cron_confs)
    for vassal in $all_confs; do
        v=$(echo $vassal|grep $1/cron.yaml)
        if [ -n "$v" ]; then
            echo $v
            return
        fi
    done
}


_manage_list() {
    APPS=$@

    if [ -z "$APPS" ]; then
        APPS=$(get_all_apps)
    fi

    for app in $APPS; do
        echo_info "${app}"
    done
}

_manage_add() {
    APPS=$@

    if [ -z "$APPS" ]; then
        APPS=$(get_all_apps)
    fi

    for app in $APPS; do
        conf=$(get_conf $app)
        if [ -z "$conf" ]; then
            echo_error "App $app not found."
            return 1
        fi
        vassal="${UWSGI_EMPEROR}/${app}.json"
        if [ ! -f $vassal ]; then
            echo_info "Adding App $app..."
            python $BASE/tools/uwsgi_conf.py $conf > $vassal
        fi
    done
}

_manage_create_tables() {
    APPS=$(get_all_apps)

    for app in $APPS;do
        old_path=$(pwd)
        conf_file_dir=$(get_conf $app)
        app_path=$(dirname $conf_file_dir)
        cd $app_path
        echo $app_path
        alembic upgrade head
        cd $old_path
    done
}

_manage_create_dbs() {
    me=`whoami`
    if [ "$me" != "postgres" ]; then
        echo '请先切换到postgres用户，运行hello脚本后，再执行此命令'
        return
    fi
    echo >/tmp/guokr_create_dbs.sql
    python $BASE/tools/db_conf.py >>/tmp/guokr_create_dbs.sql
    psql -f/tmp/guokr_create_dbs.sql
}

_manage_create_app() {
    APP=$1
    python $BASE/tools/boilerplate.py $1
    echo_info "App $APP is created"
    conf_file_dir=$(get_conf $APP)
    app_path=$(dirname $conf_file_dir)
    old_path=$(pwd)
    cd $app_path
    echo_info "Init Alembic..."
    alembic init migration &> /dev/null
    cd $old_path
}

_manage_update() {
    APPS=$@

    if [ -z "$APPS" ]; then
        APPS=$(get_enabled_apps)
    fi

    for app in $APPS; do
        conf=$(get_conf $app)
        vassal="${UWSGI_EMPEROR}/${app}.json"
        if [ -z "$conf" ]; then
            echo_info "App $app has been removed."
            rm -f "$vassal"
        elif [ ! -f "$vassal" ]; then
            echo_error "Vassal $app does not exist, ignored."
        else
            echo_info "Updating App $app..."
            rm -f "$vassal"
            python $BASE/tools/uwsgi_conf.py "$conf" > "$vassal"
        fi
    done

    $BASE/tools/make_routing_rules.py $BASE/guokr/platform_src/routing_rules.py
    $BASE/tools/inspect_static.py $BASE/guokr/platform_src/static_files.py
    if [ "$GUOKR_ENVIRON" != "PRODUCTION" ]; then
        nginx_render
    fi
}

_manage_touch() {
    APPS=$@

    if [ -z "$APPS" ]; then
        APPS=$(get_enabled_apps)
    fi

    for app in $APPS; do
        conf=$(get_conf $app)
        vassal="${UWSGI_EMPEROR}/${app}.json"
        if [ -f $vassal ]; then
            echo -n "Touching $app..."
            touch "$vassal"
            sleep 1
            echo_info "ok."
        else
            echo_warning "App $app not exist, ignored."
        fi
    done
}

_manage_remove() {
    APPS=$@
    if [ -z "$APPS" ]; then
        APPS=$(get_all_apps)
    fi

    for app in $APPS; do
        vassal="${UWSGI_EMPEROR}/${app}.json"
        if [ -e $vassal ]; then
            echo_info "Removing app $app..."
        fi
        rm -f "$vassal"
    done
}

_manage_clear() {
    find $BASE -name "*.pyc" | xargs rm &>/dev/null
    find $BASE -name "lein_errmsg" | xargs rm &>/dev/null
}

_manage_test_all() {
    APPS=$@
    if [ -z "$APPS" ]; then
        APPS=$(get_all_apps)
    fi

    for app in $APPS;do
        old_path=$(pwd)
        conf_file_dir=$(get_conf $app)
        app_path=$(dirname $conf_file_dir)
        cd $app_path
        nosetests --with-path=$app_path --with-xunit
        cd $old_path
    done
}

_manage_test_no_return() {
    APPS=$@
    if [ -z "$APPS" ]; then
        APPS=$(get_all_apps)
    fi

    for app in $APPS;do
        old_path=$(pwd)
        conf_file_dir=$(get_conf $app)
        app_path=$(dirname $conf_file_dir)
        cd $app_path
        nosetests -e ".*performance.*" --with-path=$app_path --with-xunit
        cd $old_path
    done
}

_manage_test() {
    APPS=$@
    if [ -z "$APPS" ]; then
        APPS=$(get_all_apps)
    fi

    for app in $APPS;do
        old_path=$(pwd)
        conf_file_dir=$(get_conf $app)
        app_path=$(dirname $conf_file_dir)
        cd $app_path
        if nosetests -e ".*performance.*" --with-path=$app_path --with-xunit -x ; then
            cd $old_path
            continue
        else
            rc=$?
            cd $old_path
            return $rc
        fi
    done
}

_manage_console() {
    python $BASE/tools/console.py $(get_conf $1)
}

_manage_shell() {
    python $BASE/tools/shell.py $(get_conf $1)
}

_manage_review() {
    local rev=$1
    if [ -z "$rev" ]; then
        local rev=$(hg log -r first\(branch\($(hg branch)\)\) --template {node})
    fi
    arc diff "$rev"
}

_manage_cronsync() {
    APP=$@
    if [ -z "$APP" ]; then
        echo_error "APPNAME needed"
        return 1
    fi

    conf1=$(get_conf $APP)
    if [ -z "$conf1" ]; then
        echo_error "App $APP not found"
        return 1
    fi

    conf2=$(get_cron_conf $APP)
    if [ -z "$conf2" ]; then
        echo_error "App $APP doesn't has cron.yaml."
        return 1
    fi
    python $BASE/tools/cronsync.py $conf1 $conf2
}

_manage_cronlist() {
    APP=$@
    if [ -z "$APP" ]; then
        echo_error "APPNAME needed"
        return 1
    fi

    conf=$(get_conf $APP)
    if [ -z "$conf" ]; then
        echo_error "App $APP not found"
        return 1
    fi
    python $BASE/tools/cronsync.py list $conf
}

_manage_jar() {
    for project in `find  $BASE/algo/arsenal -name "project.clj"`; do
        lein_build_jar $(dirname $project|xargs basename)
    done
}

_manage_uberjar() {
    for project in `find  $BASE/algo/knights -name "project.clj"`; do
        lein_build_uberjar $(dirname $project|xargs basename)
    done
}

_manage_log() {
    LOG_PATH=$BASE/.py/var/log/guokrplus.log
    tail -f $LOG_PATH
}

manage() {
    v_activate
    #$BASE/tools/route_conf.py
    ACTION=$1
    APPS=${@:2}
    UWSGI_EMPEROR="$VIRTUALENV_PATH/etc/uwsgi/vassals"
    UWSGI_DESC="Guokr Plus"
    UWSGI_NAME="guokrplus"
    UWSGI_PIDFILE="$VIRTUALENV_PATH/var/run/guokrplus.pid"
    UWSGI_LOGFILE="$VIRTUALENV_PATH/var/log/guokrplus.log"
    UWSGI_CPU_AFFINITY=2
    UWSGI_LOG_MAXSIZE=268435456
    CELERY_DESC="Celery"
    CELERY_NAME="celery"
    CELERY_PIDFILE="$VIRTUALENV_PATH/var/run/celery.pid"
    RC=0

    mkdir -p $UWSGI_EMPEROR
    mkdir -p $VIRTUALENV_PATH/var/run
    mkdir -p $VIRTUALENV_PATH/var/log

    case $1 in
        add)
            _manage_add $APPS
            ;;
        remove)
            _manage_remove $APPS
            ;;
        list)
            _manage_list $APPS
            ;;
        update)
            _manage_update $APPS
            ;;
        touch)
            if [ "$GUOKR_ENVIRON" != "PRODUCTION" ]; then
                nginx_reload
            fi
            _manage_touch $APPS
            ;;
        test)
            _manage_test $APPS
            RC=$?
            ;;
        test_no_return)
            _manage_test_no_return $APPS
            ;;
        test_all)
            _manage_test_all $APPS
            ;;
        start)
            if [ "$GUOKR_ENVIRON" != "PRODUCTION" ]; then
                nginx_restart
            fi
            uwsgi_start
            ;;
        debug)
            if [ "$GUOKR_ENVIRON" != "PRODUCTION" ]; then
                nginx_restart
            fi
            uwsgi_debug
            ;;
        console)
            _manage_console $2
            ;;
        shell)
            _manage_shell $2
            ;;
        stop)
            if [ "$GUOKR_ENVIRON" != "PRODUCTION" ]; then
                nginx_stop
            fi
            uwsgi_stop
            ;;
        restart|force-reload)
            if [ "$GUOKR_ENVIRON" != "PRODUCTION" ]; then
                nginx_restart
            fi
            uwsgi_restart
            ;;
        reload)
            if [ "$GUOKR_ENVIRON" != "PRODUCTION" ]; then
                nginx_reload
            fi
            uwsgi_reload
            ;;
        clear)
            _manage_clear $APPS
            ;;
        create_dbs)
            _manage_create_dbs
            ;;
        create_tables)
            _manage_create_tables
            ;;
        create_app)
            _manage_create_app $APPS
            ;;
        cronsync)
            _manage_cronsync $APPS
            ;;
        cronlist)
            _manage_cronlist $APPS
            ;;
        jar)
            _manage_jar
            ;;
        uberjar)
            _manage_uberjar
            ;;
        log)
            _manage_log
            ;;
        jenkins)
            $BASE/tools/jenkins/jenkinshelper.py ${@:2}
            ;;
        review)
            _manage_review $2
            ;;
        celery)
            case $2 in
                restart)
                    celery_restart
                    ;;
                *)
                    echo "Usage: manage celery { restart }"
                    ;;
            esac
            ;;
        nginx)
            case $2 in
                start)
                    nginx_start
                    ;;
                stop)
                    nginx_stop
                    ;;
                restart)
                    nginx_restart
                    ;;
                reload)
                    nginx_reload
                    ;;
                test)
                    nginx_test
                    ;;
                render)
                    nginx_render
                    ;;
                *)
                    echo "Usage: manage nginx { start | stop | restart | reload | test | render }"
                    ;;
            esac
            ;;
        *)
            echo "Usage: manage { add | remove | list | start | test | debug | stop | console | shell | clear | reload | touch | restart | force-reload | create_dbs | create_tables | create_app | cronsync | cronlist | jar | uberjar | celery }"
            ;;
    esac

    unset ACTION
    unset APPS
    unset $(env|cut -d= -f1|egrep '^UWSGI_')
    return $RC
}

complete_manage() {
    COMPREPLY=()
    cur=${COMP_WORDS[COMP_CWORD]}

    action="add remove list start stop clear restart force-reload reload touch debug update test test_no_return test_all console shell create_dbs create_tables create_app cronsync cronlist jar uberjar celery nginx jenkins review"
    apps="$(get_all_apps)"
    enabled="$(get_enabled_apps)"
    celery_action="restart"
    nginx_action="start stop reload restart test render"
    jenkins_action="create_pythonjob"

    if [ $COMP_CWORD -eq 1 ]; then
        COMPREPLY=( $(compgen -W "${action}" -- ${cur}) )
        return 0
    fi
    ACTION=${COMP_WORDS[1]}
    if [ \( $COMP_CWORD -ge 2 \) -a \( \( $ACTION = "add" \) -o \( $ACTION = "remove" \) \) ]; then
        COMPREPLY=( $(compgen -W "${apps}" -- ${cur}) )
        return 0
    fi
    if [ \( $COMP_CWORD -ge 2 \) -a \( $ACTION = "update" \) ]; then
        COMPREPLY=( $(compgen -W "${enabled}" -- ${cur}) )
        return 0
    fi
    if [ \( $COMP_CWORD -ge 2 \) -a \( $ACTION = "touch" \) ]; then
        COMPREPLY=( $(compgen -W "${enabled}" -- ${cur}) )
        return 0
    fi
    if [ \( $COMP_CWORD -eq 2 \) -a \( $ACTION = "console" \) ]; then
        COMPREPLY=( $(compgen -W "${apps}" -- ${cur}) )
        return 0
    fi
    if [ \( $COMP_CWORD -eq 2 \) -a \( $ACTION = "shell" \) ]; then
        COMPREPLY=( $(compgen -W "${apps}" -- ${cur}) )
        return 0
    fi
    if [ \( $COMP_CWORD -eq 2 \) -a \( $ACTION = "cronsync" \) ]; then
        COMPREPLY=( $(compgen -W "${apps}" -- ${url}) )
        return 0
    fi
    if [ \( $COMP_CWORD -eq 2 \) -a \( $ACTION = "cronlist" \) ]; then
        COMPREPLY=( $(compgen -W "${apps}" -- ${url}) )
        return 0
    fi
    if [ \( $COMP_CWORD -ge 2 \) -a \( $ACTION = "celery" \) ]; then
        COMPREPLY=( $(compgen -W "${celery_action}" -- ${cur}) )
        return 0
    fi
    if [ \( $COMP_CWORD -ge 2 \) -a \( $ACTION = "nginx" \) ]; then
        COMPREPLY=( $(compgen -W "${nginx_action}" -- ${cur}) )
        return 0
    fi
    if [ \( $COMP_CWORD -ge 2 \) -a \( $ACTION = "jenkins" \) ]; then
        COMPREPLY=( $(compgen -W "${jenkins_action}" -- ${cur}) )
        return 0
    fi
}

complete -F complete_manage manage
