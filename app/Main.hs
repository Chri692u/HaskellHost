module Main where

import Data.Text
import Control.Monad

import Parser
import Console
import Scripting
import Secrets
import Networking

main :: IO ()
main = do
    mconfig <- parseConfigFile "config.ini"
    case mconfig of
        Left err -> print err
        Right cfg -> do
            let webPath = unpack $ website cfg
            let serverConf = createConfig cfg
            let router = createRouter webPath
            when (initialize cfg) $ runScript "initialize.sh"
            start serverConf router
