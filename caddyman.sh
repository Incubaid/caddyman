#!/bin/bash

# Dictionary with plugin name as key, URL as value
declare -A plugins_urls=(
    ["realip"]="github.com/captncraig/caddy-realip"
    ["git"]="github.com/abiosoft/caddy-git"
    ["proxyprotocol"]="github.com/mastercactapus/caddy-proxyprotocol"
    ["locale"]="github.com/simia-tech/caddy-locale"
    ["cache"]="github.com/nicolasazrak/caddy-cache"
    ["authz"]="github.com/casbin/caddy-authz"
    ["filter"]="github.com/echocat/caddy-filter"
    ["minify"]="github.com/hacdias/caddy-minify"
    ["ipfilter"]="github.com/pyed/ipfilter"
    ["ratelimit"]="github.com/xuqingfeng/caddy-rate-limit"
    ["search"]="github.com/pedronasser/caddy-search"
    ["expires"]="github.com/epicagency/caddy-expires"
    ["cors"]="github.com/captncraig/cors/caddy"
    ["nobots"]="github.com/Xumeiquer/nobots"
    ["login"]="github.com/tarent/loginsrv/caddy"
    ["reauth"]="github.com/freman/caddy-reauth"
    ["jwt"]="github.com/BTBurke/caddy-jwt"
    ["jsonp"]="github.com/pschlump/caddy-jsonp"
    ["upload"]="blitznote.com/src/caddy.upload"
    ["multipass"]="github.com/namsral/multipass/caddy"
    ["datadog"]="github.com/payintech/caddy-datadog"
    ["prometheus"]="github.com/miekg/caddy-prometheus"
    ["cgi"]="github.com/jung-kurt/caddy-cgi"
    ["filemanager"]="github.com/filebrowser/caddy"
    ["iyofilemanager"]="github.com/itsyouonline/filemanager/caddy/filemanager"
    ["webdav"]="github.com/hacdias/caddy-webdav"
    ["jekyll"]="github.com/hacdias/filemanager/caddy/jekyll"
    ["hugo"]="github.com/hacdias/filemanager/caddy/hugo"
    ["mailout"]="github.com/SchumacherFM/mailout"
    ["awses"]="github.com/miquella/caddy-awses"
    ["awslambda"]="github.com/coopernurse/caddy-awslambda"
    ["grpc"]="github.com/pieterlouw/caddy-grpc"
    ["gopkg"]="github.com/zikes/gopkg"
    ["restic"]="github.com/restic/caddy"
    ["iyo"]="github.com/itsyouonline/caddy-integration/oauth"
    ["dns"]="github.com/coredns/coredns"
    ["wsproxy"]="github.com/incubaid/wsproxy"
)

# Dictionary with plugin name as key, directive as value
# This holds directives for plugins that should have directive added to caddy!
declare -A plugins_directives=(
    ["iyo"]="oauth"
    ["dns"]="dns"
    ["wsproxy"]="wsproxy"
)

# Use $GOPATH or ~/go if not set!
check_go_path(){
    if [ -n "$GOPATH" ];
        then
            echo "Using GPATH : $GOPATH"
        else
            echo "Setting GOPATH: to ~/go/"
            export GOPATH=~/go/
       fi
}

# Update Caddy source
update_caddy(){
    CADDY_GO_PACKAGE=github.com/mholt/caddy
    echo -ne "Ensuring Caddy is up-to-date \r"
    go get $CADDY_GO_PACKAGE
    echo "Ensuring Caddy is up-to-date [SUCCESS]"
}


# List all supported plugin names and URLS
list(){
    for plugin in "${!plugins_urls[@]}"; do echo "[$plugin] ${plugins_urls[$plugin]}"; done
}


# Print usage message
show_usage(){
    echo "usage: cadyman list                                   (list available plugins)"
    echo "               install plugin_name1 plugin_name2 ...  (install plugins by their names)"
    echo "               install_url url {directive}            (install plugin by url)"
    exit 1
}


# Install plugin given its name or display error message if name not in our supported plugins
install_plugin_by_name(){
    if [ -z ${plugins_urls[$1]} ]; then
        echo "Plugin name is not recognized"
    else
         if [ -z ${plugins_directives[$1]} ]; then
            install ${plugins_urls[$1]} ""
         else
            install ${plugins_urls[$1]} ${plugins_directives[$1]}
         fi
    fi
}

# Install Hugo (only executed if user tries to install hugo plugin)
install_hugo(){

    echo -ne "Installing Hugo \r"
    go get -u github.com/gohugoio/hugo
    echo "Installing Hugo [SUCCESS]"
}

install_plugin(){
    echo -ne "Getting plugin $1 \r"
    go get $1

    if [ ! $? == 0 ]; then
        exit $?
    else
        echo -ne "Getting plugin [SUCCESS]\r"
        echo ""
    fi

    # special case :: if installing iyofilemanager plugin, make sure to checkout to master-iyo-auth branch
    if [ $1 == "github.com/itsyouonline/filemanager/caddy/filemanager" ]; then
        git -C $GOPATH/src/github.com/itsyouonline/filemanager checkout master-iyo-auth
    fi

}

update_caddy_plugin_imports_and_directives(){

    CADDY_PATH=$GOPATH/src/github.com/mholt/caddy
    PLUGINS_FILE=$CADDY_PATH/caddyhttp/httpserver/plugin.go
    MAIN_FILE=$CADDY_PATH/caddy/caddymain/run.go

    url=$1
    directive=$2

    echo -ne 'Updating plugin imports in $CADDY_PATH/caddy/caddymain/run.go\r'
    sed -i "s%This is where other plugins get plugged in (imported)%This is where other plugins get plugged in (imported)\n_ \"$url\"%g" $MAIN_FILE
    gofmt -w $MAIN_FILE
    echo -ne 'Updating plugin imports in $CADDY_PATH/caddy/caddymain/run.go [SUCCESS]\r'
    echo ""

    if [ ! $directive == "" ]; then
        echo -ne "Updating plugin directive in $PLUGINS_FILE\r"
        sed -i "/\"prometheus\",/a \"$directive\"," $PLUGINS_FILE
        gofmt -w $MAIN_FILE
        echo -ne "Updating plugin directive in $PLUGINS_FILE [SUCCESS]\r"
        echo ""
    fi

}

rebuild_caddy(){
    CADDY_PATH=$GOPATH/src/github.com/mholt/caddy

    cd $CADDY_PATH/caddy
    echo -ne "Ensure caddy build system dependencies\r"
    go get -v github.com/caddyserver/builds
    echo "Ensure caddy build system dependencies [SUCCESS]"

    echo -ne "Rebuilding caddy binary\r"
    go run build.go
    echo "Rebuilding caddy binary [SUCCESS]"

    if pgrep -x "caddy" > /dev/null

    then
        echo -ne "Caddy is Running .. Stopping process\r"
        kill -9 `pgrep -x caddy` > /dev/null
        echo "Caddy is Running .. Stopping process [SUCCESS]"
    fi
    mkdir -p /$GOPATH/bin
    cp caddy /$GOPATH/bin

    if [ ! $? == 0 ]; then

        exit $?
    else
        echo -n "Copying caddy binary to /$GOPATH/bin [SUCCESS]"
        echo ""
    fi
}

install(){
    check_go_path
    update_caddy

    url=$1
    directive=$2

    # special case :: if installing hugo plugin, make sure to install hugo 1st
    if [ $url == "github.com/hacdias/filemanager/caddy/hugo" ]; then
        install_hugo
    fi

    install_plugin $url
    update_caddy_plugin_imports_and_directives $url $directive
}

## START ##

# check proper params
if [[ $# -lt 1 || (  $1 != "list"  &&  $1 != "install" && $1 != "install_url" ) ]]; then
    show_usage
fi

# list takes no extra params
if [ $1 == "list" ]; then
    if [ $# != 1 ]; then
        show_usage
    else
        list
    fi
fi

# install takes multiple plugins names
if [ $1 == "install" ]; then
    if [ $# -lt 2 ]; then
        show_usage
    else
        for plugin_name in ${@:2}; do
            install_plugin_by_name ${plugin_name}
        done
        rebuild_caddy
    fi
fi

# Install URL
if [ $1 == "install_url" ]; then
    if [[ $# -lt 2  || ($# -gt 3) ]]; then
        show_usage
    else
        install $2 $3
        rebuild_caddy
    fi
fi
