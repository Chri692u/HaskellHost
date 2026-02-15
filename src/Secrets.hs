module Secrets where

import Data.Map (Map)
import Data.Text (Text, pack, unpack)
import qualified Data.Map as M
import qualified Data.Text as T
import qualified Data.Text.IO as TIO

import Parser

-- ----------------------
-- Load secrets from "secrets.env"
-- ----------------------
loadSecrets :: IO (Map Text Text)
loadSecrets = do
    content <- TIO.readFile "secrets.env"
    let ls = map (stripLine . pack) (lines $ unpack content)
        pairs = mapMaybe parseLine ls
    return $ M.fromList pairs
  where
    parseLine line =
        case T.breakOn (pack "=") line of
            (key, val) | not (T.null val) -> Just (key, T.drop 1 val)
            _ -> Nothing
    mapMaybe f = foldr (\x acc -> case f x of
                                Just y  -> y : acc
                                Nothing -> acc) []
    stripLine = T.strip

-- ----------------------
-- Replace placeholders with secrets
-- ----------------------
fixStr :: Text -> Map Text Text -> Either String Text
fixStr input secrets =
    case parsePlaceholders secrets input of
        Left err    -> Left err
        Right parts -> concatEither parts
  where
    concatEither :: [Either String Text] -> Either String Text
    concatEither xs =
        case [e | Left e <- xs] of
            []   -> Right $ mconcat [v | Right v <- xs]
            errs -> Left $ unlines errs

