# HaskellHost
 A configurable HTTP server for hosting websites
 
# How to use
Start out by making a new folder for the website inside the HaskellHost repo and clone your website
```
mkdir dist-website
cd dist-website
git pull *your website repo*
```
Once we have the website ready, we can configure the server. Open the config file and fill it out:
```bash
initialize = false
port = 8080
folder = example-website
```
Now, the `initialize = false` line tells the webserver that we do not have a startup script. If you want the server to run a script before starting the server, set this to `initialize = true` and make a shell script inside the HaskellHost repo:
```
touch initialize.sh
vim initialize -- Write the shell script
chmod +x initialize.sh
```
Now, when the server starts, it will run this script.
Finally, to start the webserver, simply run `cabal run` or build the executable.

# Using .env files - no more API-keys on the front-end
HaskellHost provides an interface to proxy http requests with API-keys safely using string interpolation in a JavaScript style. Simply make an environment file `secrets.env` and fill in the lines with `KEY=SECRET` pairs. Then from the frontend send a string `https://api.endpoint/${KEY}` and the server will return the result to the client.

## Using JavaScript on the client
Running the example website displays how this can be done. In the `secrets.env` we have `KANYE_API_KEY=kanye`, then on the front-end we can do the following:
```JS
const placeholderUrl = "https://api.${KANYE_API_KEY}.rest/";
const response = await fetch(
          `/api/proxy?url=${encodeURIComponent(placeholderUrl)}`
        );
```
Notice that this is the same syntax as JavaScript, but without the backticks. Now the client will never see our secret "kanye" keeping it hidden on the server-side. Run the example and see for yourself using the `example-website` directory.