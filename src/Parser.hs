module Parser where

import Data.Text (Text, unpack, pack, strip)
import Data.Map (Map)
import Text.Parsec.String (Parser)
import Text.Parsec
import Control.Monad (void)
import qualified Data.Text.IO as TIO
import qualified Data.Map as M

-- ----------------------
-- Type aliases
-- ----------------------
type Key = Text
type Secret = Text
type URL = Text
type Secrets = Map Key Secret

-- ----------------------
-- Config type
-- ----------------------

data Config = Config
    { initialize :: Bool
    , hport      :: Int
    , folder    :: Text
    } deriving (Show)

-- ----------------------
-- Public API
-- ----------------------

parseConfigFile :: FilePath -> IO (Either ParseError Config)
parseConfigFile filePath = do
    contents <- TIO.readFile filePath
    return (parse parseConfig filePath (unpack contents))

-- ----------------------
-- Config Parser
-- ----------------------

parseConfig :: Parser Config
parseConfig = do
    spaces
    pairs <- many (configLine <* spaces)
    let table = M.fromList pairs
    return Config
        { initialize = readBool (pack "initialize") table
        , hport = readInt (pack "port") table
        , folder = readText (pack "folder") table
        }

configLine :: Parser (Key, Secret)
configLine = do
    optional comment
    spaces
    key <- many1 (letter <|> digit)
    spaces >> char '=' >> spaces
    val <- manyTill anyChar (try (void newline) <|> eof)
    return (pack key, strip $ pack val)

comment :: Parser ()
comment = do
    _ <- char '#'
    _ <- manyTill anyChar newline
    return ()

-- ----------------------
-- Conversions
-- ----------------------

readBool :: Text -> Secrets -> Bool
readBool k m =
    case M.lookup k m of
        Just v  -> unpack v == "true"
        Nothing -> False

readInt :: Text -> Secrets -> Int
readInt k m =
    case M.lookup k m of
        Just v  -> read $ unpack v
        Nothing -> error ("Missing config key: " ++ unpack k)

readText :: Text -> Secrets -> Text
readText k m =
    case M.lookup k m of
        Just v  -> v
        Nothing -> error ("Missing config key: " ++ unpack k)

-- ----------------------
-- Placeholder Logic
-- ----------------------

parsePlaceholders :: Secrets -> Key -> Either String [Either String Secret]
parsePlaceholders secrets input =
    case parse parser "" (unpack input) of
        Left err   -> Left $ "Parse error: " ++ show err
        Right parts -> Right parts
  where
    parser = many (try placeholder <|> normal)
    placeholder = do
        _ <- string "${"
        key <- manyTill anyChar (char '}')
        case M.lookup (pack key) secrets of
            Just val -> return $ Right val
            Nothing  -> return $ Left ("Missing key: " ++ key)
    normal = do
        s <- many1 (noneOf "$")
        return $ Right (pack s)
