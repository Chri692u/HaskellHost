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
    putStrLn "Parsing config file..."
    mconfig <- parseConfigFile "config.ini"
    case mconfig of
        Left err -> do
            putStrLn "Error parsing config:"
            print err
        Right cfg -> do
            putStrLn "Config parsed successfully:"
            print cfg
            secrets <- loadSecrets
            let webPath = unpack $ folder cfg
            putStrLn $ "Directory of website path: " ++ webPath
            let serverConf = createConfig cfg
            let router = createRouter webPath secrets
            when (initialize cfg) $ do
                putStrLn "Running initialization script..."
                runScript "initialize.sh"
            putStrLn "Starting server..."
            start serverConf router
