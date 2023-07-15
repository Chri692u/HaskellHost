module Main where

import Control.Monad
import Happstack.Lite

import Console

dist :: FilePath
dist = "./dist-website"

vue :: ServerPart Response
vue = serveDirectory EnableBrowsing ["index.html"] dist

router :: ServerPart Response
router = msum [ vue ]

config :: ServerConfig
config = ServerConfig { port      = 8000
                      , ramQuota  = 1 * 10^6
                      , diskQuota = 20 * 10^6
                      , tmpDir    = "/tmp/"
                      }


main :: IO ()
main = start config router