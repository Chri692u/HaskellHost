module Parser where

import Data.Text (Text, unpack, pack, strip)
import Data.Map (Map)
import Text.Parsec.String (Parser)
import Text.Parsec
import Control.Monad (void)
import qualified Data.Text.IO as TIO
import qualified Data.Map as M

-- ----------------------
-- Config type
-- ----------------------

data Config = Config
    { initialize :: Bool
    , hport      :: Int
    , website    :: Text
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
        , hport      = readInt (pack "port") table
        , website    = readText (pack "website") table
        }

configLine :: Parser (Text, Text)
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

readBool :: Text -> Map Text Text -> Bool
readBool k m =
    case M.lookup k m of
        Just v  -> unpack v == "true"
        Nothing -> False

readInt :: Text -> Map Text Text -> Int
readInt k m =
    case M.lookup k m of
        Just v  -> read $ unpack v
        Nothing -> error ("Missing config key: " ++ unpack k)

readText :: Text -> Map Text Text -> Text
readText k m =
    case M.lookup k m of
        Just v  -> v
        Nothing -> error ("Missing config key: " ++ unpack k)

-- ----------------------
-- Placeholder Logic
-- ----------------------

parsePlaceholders :: Map Text Text -> Text -> Either String [Either String Text]
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
