module Main where

import Data.Text
import Control.Monad
import Happstack.Lite

import Parser
import Console

createRouter :: FilePath -> ServerPart Response
createRouter dist = msum [ serveDirectory EnableBrowsing ["index.html"] dist ]

createConfig :: Config -> ServerConfig
createConfig cfg = ServerConfig { port = hport cfg
                                , ramQuota = rspace
                                , diskQuota = dspace
                                , tmpDir    = "/tmp/" 
                                }
    where dspace = fromIntegral $ disk cfg * 10^6
          rspace = fromIntegral $ ram cfg * 10^6

main :: IO ()
main = do
  mconfig <- parseConfigFile "config.ini"
  case mconfig of
    Left error -> print error
    Right cfg -> do
      when (initialize cfg) $ do
        -- run script
        print "running script lol"
      let config = createConfig cfg
          router = createRouter $ unpack $ website cfg
      start config router