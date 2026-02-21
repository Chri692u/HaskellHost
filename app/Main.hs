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
        Left err -> do
            putStrLn "Error parsing config:"
            print err
        Right cfg -> do
            secrets <- loadSecrets
            when (initialize cfg) $ do
                putStrLn "Running initialization script..."
                runScript "initialize.sh"
            let serverConf = createConfig cfg
            putStrLn "HaskellHost starting..."
            start cfg secrets