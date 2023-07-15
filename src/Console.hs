module Console where

import System.Console.Haskeline
import Control.Concurrent
import Control.Monad.Trans
import Happstack.Lite

start :: ServerConfig -> ServerPart Response -> IO ()
start config  router = do
    tid <- liftIO $ forkFinally run finish
    console tid
        where run = serve (Just config) router
              finish = const $ putStrLn "Server stopped."

-- Run server until stop command
console :: ThreadId -> IO ()
console tid = runInputT defaultSettings loop
  where
    loop = do
        line <- getInputLine "(server running) > "
        case line of
            Just input -> do
                if null input then loop else
                    case head $ words input of
                        ":stop" -> liftIO $ killThread tid
                        _ -> liftIO (print "To stop the server use \":stop\"") >> loop