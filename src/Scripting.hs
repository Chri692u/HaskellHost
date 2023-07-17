module Scripting where

import System.Process
import System.Exit

runScript path = do
  (_, _, _, processHandle) <- createProcess (shell path)
  exitCode <- waitForProcess processHandle
  case exitCode of
      ExitSuccess   -> putStrLn "Shell script executed successfully."
      ExitFailure _ -> putStrLn "Shell script failed."
