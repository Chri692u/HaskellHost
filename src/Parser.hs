module Parser where

import Text.Parsec
import Text.Parsec.String
import Text.Parsec.Char
import Text.Parsec.Combinator

import Data.Text
import qualified Data.Text.IO as TIO

data Config = Config
  { initialize :: Bool,
    hport :: Int,
    ram :: Int,
    disk :: Int,
    website :: Text
  }
  deriving (Show)

parseConfigFile :: FilePath -> IO (Either ParseError Config)
parseConfigFile filePath = do
  contents <- TIO.readFile filePath
  return (parse parseConfig "<stdin>" (unpack contents))

parseConfig :: Parser Config
parseConfig = do
  initialize' <- setting "initialize" boolValue
  port' <- setting "port" intValue
  ram' <- setting "RAM" intValue
  disk' <- setting "DISK" intValue
  website' <- setting "WEBSITE" textLiteral
  return (Config initialize' port' ram' disk' website')

setting :: String -> Parser a -> Parser a
setting name valueParser = do
  _ <- string name
  _ <- spaces
  _ <- char '='
  _ <- spaces
  val <- valueParser
  newline
  return val

boolValue :: Parser Bool
boolValue = (string "true" >> return True) <|> (string "false" >> return False)

intValue :: Parser Int
intValue = read <$> many1 digit

textLiteral :: Parser Text
textLiteral = pack <$> (char '"' *> manyTill pathChar (char '"'))

pathChar :: Parser Char
pathChar = choice [try escapedChar, anyChar]

escapedChar :: Parser Char
escapedChar = do
  _ <- char '\\'
  c <- anyChar
  case c of
    '"' -> return c
    '\\' -> return c
    _ -> fail "Invalid escaped character"

