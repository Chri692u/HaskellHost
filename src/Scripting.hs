module Scripting where

import System.Process (createProcess, waitForProcess, shell)
import System.Exit (ExitCode(ExitFailure, ExitSuccess))

-- ----------------------
-- Runs a script
-- ----------------------
runScript :: String -> IO ()
runScript path = do
  (_, _, _, processHandle) <- createProcess (shell path)
  exitCode <- waitForProcess processHandle
  case exitCode of
      ExitSuccess   -> putStrLn "Shell script executed successfully."
      ExitFailure _ -> putStrLn "Shell script failed."
