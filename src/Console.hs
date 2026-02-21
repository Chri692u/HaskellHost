module Console where

import System.Console.Haskeline
import Control.Concurrent
import Control.Monad.IO.Class
import System.Exit (exitSuccess)
import Text.Read (readMaybe)
import Parser
import Secrets
import Networking

-- ----------------------
-- Run the server on startup
-- ----------------------
start :: Config -> Secrets -> IO ()
start cfg secrets = do
    tid <- startServer cfg secrets
    console (Just tid) cfg secrets

-- ----------------------
-- Console loop
-- ----------------------
console :: Maybe ThreadId -> Config -> Secrets -> IO ()
console mTid cfg secrets = runInputT defaultSettings (loop mTid cfg secrets)
  where
    loop :: Maybe ThreadId -> Config -> Secrets -> InputT IO ()
    loop mTid cfg secrets = do
        minput <- getInputLine "> "
        case minput of
            Nothing -> loop mTid cfg secrets
            Just input -> do
                let trimmed = dropWhile (==' ') input
                if null trimmed
                   then loop mTid cfg secrets
                   else handleCommand mTid cfg secrets trimmed >>= \newTid ->
                        loop newTid cfg secrets

-- ----------------------
-- Command handling
-- ----------------------
handleCommand :: Maybe ThreadId -> Config -> Secrets -> String -> InputT IO (Maybe ThreadId)
handleCommand mTid cfg secrets input =
    case words input of
        [":stop"] -> liftIO $ stopServer mTid
        [":start"] -> liftIO $ startServerIfNotRunning mTid cfg secrets
        [":start", portStr] -> liftIO $ startServerWithPort mTid cfg secrets portStr
        [":restart"] -> liftIO $ putStrLn "Error: :restart requires a port. Usage: :restart <port>" >> return mTid
        [":restart", portStr] -> liftIO $ restartServer mTid cfg secrets portStr
        [":status"] -> liftIO $ serverStatus mTid cfg
        [":kill"] -> liftIO $ do
            _ <- stopServer mTid
            putStrLn "HaskellHost shutting down."
            exitSuccess
        [":help"] -> liftIO $ do
            putStrLn "Available commands:"
            putStrLn "  :start            - Starts the server using the config's port if not running."
            putStrLn "  :start <port>     - Starts the server on the specified port if not running."
            putStrLn "  :stop             - Stops the server if it is running."
            putStrLn "  :restart <port>   - Restarts the server on the specified port, reloading static files."
            putStrLn "  :status           - Shows if the server is running, the port, and access URL."
            putStrLn "  :kill             - Stops the server and exits the program."
            putStrLn "  :help             - Displays this help message."
            return mTid
        _ -> liftIO $ do
            putStrLn $ "Unknown command: " ++ input ++ ". Type :help for commands."
            return mTid