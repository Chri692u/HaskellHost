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


{- 
Todo for next time:
1. Error logging in Networking would be nice
2. A good REPL that actually is useful
3. Look at Happstack for potential things to add to the config
4. Configurable whitelist (not just localhost)
5. Encryption of .env perhaps
-}