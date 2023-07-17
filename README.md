# HaskellHost
 A configurable HTTP server for hosting websites
 
# How to use
Start out by making a new folder for the website inside the HaskellHost repo and clone your website
```
mkdir dist-website
cd dist-website
git pull *your website repo*
*build command for your website*
```
One we have the website ready, we can configure the server. Open the config file and fill it out:
```
initialize = false
port = 8000 -- What port the server will run on
RAM = 1     -- RAM quota for the webserver (in megabytes)
DISK = 20   -- Disk quota for the webserver (in megabytes)
WEBSITE = "/path/to/website/dir" -- Website directory
```
Now, the `initialize = false` line tells the webserver that we do not have a startup script. If you want the server to run a script before starting the server, set this to `initialize = true` and make a shell script inside the HaskellHost repo:
```
touch initialize.sh
vim initialize -- Write the shell script
chmod +x initialize.sh
```
Now, when the server starts, it will run this script.
Finally, to start the webserver, simply run `cabal run`
