module Networking where

import Happstack.Server
import Happstack.Server.RqData (look)
import Control.Concurrent
import Control.Monad.IO.Class
import Control.Monad (msum)
import Data.Text (pack, unpack)
import qualified Network.HTTP.Simple as NW
import qualified Data.ByteString.Lazy as BL
import Parser
import Secrets

-- ----------------------
-- Serve files with cache disabled
-- ----------------------
-- Adds "Cache-Control" headers to prevent the browser from caching
-- so that static files (HTML, JS, CSS) are always served fresh.
noCache :: ServerPart Response -> ServerPart Response
noCache sp = do
    r <- sp
    ok $ addHeader "Cache-Control" "no-store, no-cache, must-revalidate, max-age=0" r

-- ----------------------
-- Build a fresh router each time
-- ----------------------
-- This router handles both:
--   1. API proxying with secret replacement
--   2. Serving static files from a given directory with no-cache
-- Creating a new router each time ensures updates to files or routes are reflected
createRouter :: FilePath -> Secrets -> ServerPart Response
createRouter dist secrets = msum
    [ dir "api" $ dir "proxy" $ do
          url <- look "url"
          proxy secrets (pack url)
    , noCache $ serveDirectory EnableBrowsing ["index.html"] dist
    ]

-- ----------------------
-- Convert Config to Happstack Conf
-- ----------------------
-- Only maps the port currently. Can extend for more server options.
createConfig :: Config -> Conf
createConfig cfg = nullConf { port = hport cfg }

-- ----------------------
-- Start / Stop / Restart helpers
-- ----------------------
-- Forks the server in a new thread
startServer :: Config -> Secrets -> IO ThreadId
startServer cfg secrets = do
    let conf = createConfig cfg
        router = createRouter (unpack $ folder cfg) secrets
    forkIO $ simpleHTTP conf router

-- Start server only if it's not already running
startServerIfNotRunning :: Maybe ThreadId -> Config -> Secrets -> IO (Maybe ThreadId)
startServerIfNotRunning (Just _) _ _ = putStrLn "Server is already running." >> return (Just undefined)
startServerIfNotRunning Nothing cfg secrets = do
    tid <- startServer cfg secrets
    putStrLn $ "Server started on port " ++ show (hport cfg)
    return (Just tid)

-- Start server on a specific port if not running
startServerWithPort :: Maybe ThreadId -> Config -> Secrets -> String -> IO (Maybe ThreadId)
startServerWithPort (Just _) _ _ _ = putStrLn "Server is already running." >> return (Just undefined)
startServerWithPort Nothing cfg secrets portStr =
    case reads portStr of
        [(p, "")] -> do
            let newCfg = cfg { hport = p }
            tid <- startServer newCfg secrets
            putStrLn $ "Server started on port " ++ show p
            return (Just tid)
        _ -> putStrLn "Invalid port number." >> return Nothing

-- Stop server if running
stopServer :: Maybe ThreadId -> IO (Maybe ThreadId)
stopServer Nothing = putStrLn "Server is not running." >> return Nothing
stopServer (Just tid) = killThread tid >> putStrLn "Server stopped." >> return Nothing

-- Restart server
restartServer :: Maybe ThreadId -> Config -> Secrets -> String -> IO (Maybe ThreadId)
restartServer mTid cfg secrets portStr = do
    _ <- stopServer mTid
    let newCfg = case reads portStr of
                     [(p, "")] -> cfg { hport = p }
                     _ -> cfg
    tid <- startServer newCfg secrets
    putStrLn $ "Server restarted on port " ++ show (hport newCfg)
    return (Just tid)

-- Print server status
serverStatus :: Maybe ThreadId -> Config -> IO (Maybe ThreadId)
serverStatus mTid cfg = do
    putStrLn "Server Status:"
    putStrLn $ "  Running: " ++ maybe "No" (const "Yes") mTid
    putStrLn $ "  Port: " ++ show (hport cfg)
    putStrLn $ "  URL: http://localhost:" ++ show (hport cfg)
    return mTid

-- ----------------------
-- Proxy logic
-- ----------------------
-- Fetch an external URL using HTTP client
proxyFetch :: String -> IO BL.ByteString
proxyFetch url = do
    req <- NW.parseRequest url
    resp <- NW.httpLBS req
    return $ NW.getResponseBody resp

-- Send the fetched result back to the client
proxyPass :: BL.ByteString -> ServerPart Response
proxyPass result = ok $ toResponse result

-- Proxy endpoint with secret replacement, only localhost allowed
proxy :: Secrets -> URL -> ServerPart Response
proxy secrets url = do
    rq <- askRq
    let peer = rqPeer rq
    if not (isLocalHost peer)
      then forbidden $ toResponse ("Proxy requests only allowed from localhost")
      else case fixURL url secrets of
             Left err -> badRequest $ toResponse ("Secret replacement error: " ++ err)
             Right fixedUrl -> do
                 result <- liftIO $ proxyFetch (unpack fixedUrl)
                 proxyPass result

-- Check if the request comes from localhost
isLocalHost :: (String, Int) -> Bool
isLocalHost (host, _) = host == "127.0.0.1" || host == "::1"