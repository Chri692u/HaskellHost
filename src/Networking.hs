module Networking where

import Happstack.Server
import Happstack.Server.RqData (look)
import Control.Monad.IO.Class
import Control.Monad
import qualified Network.HTTP.Simple as NW
import qualified Data.ByteString.Lazy as BL
import qualified Data.Text as T

import Secrets
import Parser

-- | Router with proxy endpoint
createRouter :: FilePath -> ServerPart Response
createRouter dist = msum
    [ dir "api" $ dir "proxy" $ do
          url <- look "url"  -- url as Text or String?
          proxy (T.pack url)
    , serveDirectory EnableBrowsing ["index.html"] dist
    ]

-- | Convert your parsed Config into Happstack-server Conf
createConfig :: Config -> Conf
createConfig cfg = nullConf { port = hport cfg }

-- | Fetch external URL as lazy ByteString
proxyFetch :: T.Text -> IO BL.ByteString
proxyFetch url = do
    req <- NW.parseRequest (T.unpack url)
    resp <- NW.httpLBS req
    return $ NW.getResponseBody resp

-- | Send the fetched result back to the client
proxyPass :: BL.ByteString -> ServerPart Response
proxyPass result = ok $ toResponse result

-- | Proxy endpoint: replace secrets, fetch URL, and return JSON
proxy :: T.Text -> ServerPart Response
proxy url = do
    secrets <- liftIO loadSecrets  -- Map Text Text

    case fixStr url secrets of
        Left err ->
            badRequest $ toResponse ("Secret replacement error: " ++ err)

        Right fixedUrl -> do
            result <- liftIO $ proxyFetch fixedUrl
            proxyPass result
