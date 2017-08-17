#!/bin/bash

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
    ["filemanager"]="github.com/hacdias/filemanager/caddy/filemanager"
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
)

declare -A plugins_directives=(
    ["iyo"]="oauth"
)



check_go_path(){
    if [ -n "$GOPATH" ];
        then
            echo "Using GPATH : $GOPATH"
        else
            echo "Setting GOPATH: to ~/go/"
            export GOPATH=~/go/
       fi
}

update_caddy(){
    CADDY_GO_PACKAGE=github.com/mholt/caddy
    echo -ne "Ensuring Caddy is up2date \r"
    go get $CADDY_GO_PACKAGE
    echo -n "Ensuring Caddy is up2date [SUCCESS]"
    echo ""
}

list(){
    for plugin in "${!plugins_urls[@]}"; do echo "[$plugin] ${plugins_urls[$plugin]}"; done
}


show_usage(){
    echo "usage: cadyman list                           (list available plugins)"
    echo "               install plugin_name            (install plugin by its name)"
    echo "               install_url url {directive}    (install plugin by url)"
    exit 1
}


install_plugin_by_name(){
    if [ -z ${plugins_urls[$1]} ]; then
        echo "Plugin name is not recognized"
    else
        check_go_path
        update_caddy
         if [ -z ${plugins_directives[$1]} ]; then
            install ${plugins_urls[$1]} ""
         else
            install ${plugins_urls[$1]} ${plugins_directives[$1]}
         fi
    fi
}

install(){
    url=$1
    directive=$2
    echo $url
    echo -ne "Getting plugin \r"
    go get $url

    if [ ! $? == 0 ]; then
        exit $?
    else
        echo -ne "Getting plugin [SUCCESS]\r"
        echo ""
    fi
    CADDY_PATH=$GOPATH/src/github.com/mholt/caddy
    PLUGINS_FILE=$CADDY_PATH/caddyhttp/httpserver/plugin.go
    MAIN_FILE=$CADDY_PATH/caddy/caddymain/run.go

    echo -ne 'Updating plugin imports in $CADDY_PATH/caddy/caddymain/run.go\r'
    sed -i "s%This is where other plugins get plugged in (imported)%This is where other plugins get plugged in (imported)\n_ \"$url\"%g" $MAIN_FILE
    echo -ne 'Updating plugin imports in $CADDY_PATH/caddy/caddymain/run.go [SUCCESS]\r'
    echo ""

    if [ ! $directive == "" ]; then
        echo -ne "Updating plugin directive in $PLUGINS_FILE\r"
        sed -i "/\"prometheus\",/a \"$directive\"," $PLUGINS_FILE
        echo -ne "Updating plugin directive in $PLUGINS_FILE [SUCCESS]\r"
        echo ""
    fi

    cd $CADDY_PATH/caddy
    echo -ne "Rebuilding caddy binary\r"
    bash build.bash
    echo -ne "Rebuilding caddy binary [SUCCESS]\r"

    if pgrep -x "caddy" > /dev/null

    then
        echo -ne "Caddy is Rnning .. Stopping process\r"
        kill -9 `pgrep -x caddy` > /dev/null
        echo -ne "Caddy is Rnning .. Stopping process [SUCCESS]\r"
        echo ""
    fi

    cp caddy /$GOPATH/bin

    if [ ! $? == 0 ]; then

        exit $?
    else
        echo -n "Copying caddy binary to /$GOPATH/bin [SUCCESS]"
        echo ""
    fi
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

# Install takes plugin name
if [ $1 == "install" ]; then
    if [ $# != 2 ]; then
        show_usage
    else
        install_plugin_by_name $2
    fi
fi

# Install URL
if [ $1 == "install_url" ]; then
    if [[ $# -lt 2  || ($# -gt 3) ]]; then
        show_usage
    else
        install $2 $3
    fi
fi
