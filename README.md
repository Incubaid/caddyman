## Motivation
- caddyman is a simple script to install [Caddy](https://caddyserver.com) plugins
- [Caddy](https://caddyserver.com) has no smooth way to install plugins, and we have 3 ways
    - [Download](https://caddyserver.com/download) a binary directly with the desired plugins needed
    - Use [Caddyplug](https://github.com/abiosoft/caddyplug) but this only works on linux.
    - Edit some caddy source files, adding proper imports for the desigred plugins then re-build caddy
        - Example: in oprder to add [IYO]() plugin support 

            - we have to edit some source code ```$GOPATH/src/github.com/mholt/caddy/caddy/caddymain/run.go```
        manually,then adding plugin import path before we build caddy again.i.e
            ```
                _ "github.com/mholt/caddy/caddyhttp"
            ```
            - some plugins require you also to add a directive here ```$GOPATH/src/github.com/mholt/caddy/caddyhttp/httpserver/plugin.go```
            in ```directives``` variablea as well for caddy to recognize this directive when used in caddy config file
- Caddyman does the step number 3 for you


## usage
- ```./caddyman {url} {directive}```
    - url (required) i.e ```github.com/itsyouonline/caddy-integration/oauth```
    - directive (not required unless plugin needs it) ```oauth```


## examples
```bash
chmod u+x caddyman
./caddyman.sh github.com/abiosoft/caddy-git
./caddyman.sh github.com/itsyouonline/caddy-integration/oauth oauth
```
