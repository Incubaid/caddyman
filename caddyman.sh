#!/bin/bash

if [ $# -lt 1 ]; then
    echo $0: usage: caddyman plugin_url plugin_directive
    exit 1
fi

CADDY_GO_PACKAGE=github.com/mholt/caddy
echo -ne "Ensuring Caddy is up2date \r"
go get $CADDY_GO_PACKAGE
echo -n "Ensuring Caddy is up2date [SUCCESS]"
echo ""


url=$1
directive=$2

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
    echo -n "Caddy is Rnning .. Stopping process"
    pkill -9 caddy
    echo -n "Caddy is Rnning .. Stopping process [SUCCESS]"
    echo ""
fi

cp caddy /$GOPATH/bin

if [ ! $? == 0 ]; then
    exit $?
else
    echo -n "Copying caddy binary to /$GOPATH/bin [SUCCESS]"
    echo ""
fi
