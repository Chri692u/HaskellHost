module Console where

import System.Console.Haskeline
import Control.Concurrent
import Control.Monad.IO.Class
import Happstack.Server

-- Run the server with your router
start :: Conf -> ServerPart Response -> IO ()
start config router = do
    tid <- forkIO $ simpleHTTP config router
    putStrLn $ "Server running on port " ++ show (port config)
    console tid
    
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