module Duffer.Loose.Parser where

import qualified Data.ByteString      as B

import Prelude                          hiding (take)

import Data.Attoparsec.ByteString       (Parser, takeTill, anyWord8)
import Data.Attoparsec.ByteString.Char8 (anyChar, char, choice, digit, space
                                        ,string, manyTill', endOfLine
                                        ,takeByteString, many', take)
import Data.ByteString.Base16           (encode)
import Data.ByteString.UTF8             (fromString)
import Data.Set                         (fromList)
import Numeric                          (readOct)

import Duffer.Loose.Objects (GitObject(..), TreeEntry(..), PersonTime(..), Ref)

parseNull :: Parser Char
parseNull = char '\NUL'

parseHeader :: B.ByteString -> Parser String
parseHeader = (*> digit `manyTill'` parseNull) . (*> space) . string

parseRestOfLine :: Parser B.ByteString
parseRestOfLine = takeTill (==10) <* endOfLine

parseMessage :: Parser B.ByteString
parseMessage = endOfLine *> takeByteString

parseHexRef :: Parser Ref
parseHexRef = take 40

parseBinRef :: Parser Ref
parseBinRef = encode <$> take 20

parseBlob :: Parser GitObject
parseBlob = Blob <$> takeByteString

parseTree :: Parser GitObject
parseTree = Tree . fromList <$> many' parseTreeEntry

parseTreeEntry :: Parser TreeEntry
parseTreeEntry = TreeEntry <$> parsePerms <*> parseName <*> parseBinRef
    where parsePerms = toEnum . fst . head . readOct <$> digit `manyTill'` space
          parseName  = takeTill (==0)                <*  parseNull

parsePersonTime :: Parser PersonTime
parsePersonTime = PersonTime
    <$> (B.pack     <$> anyWord8 `manyTill'` string " <")
    <*> (B.pack     <$> anyWord8 `manyTill'` string "> ")
    <*> (fromString <$> digit    `manyTill'` space)
    <*> parseRestOfLine

parseCommit :: Parser GitObject
parseCommit = Commit
    <$>        ("tree"      *> space *> parseHexRef <* endOfLine)
    <*>  many' ("parent"    *> space *> parseHexRef <* endOfLine)
    <*>        ("author"    *> space *> parsePersonTime)
    <*>        ("committer" *> space *> parsePersonTime)
    <*>        parseMessage

parseTag :: Parser GitObject
parseTag = Tag
    <$> ("object" *> space *> parseHexRef <* endOfLine)
    <*> ("type"   *> space *> parseRestOfLine)
    <*> ("tag"    *> space *> parseRestOfLine)
    <*> ("tagger" *> space *> parsePersonTime)
    <*> parseMessage

parseObject :: Parser GitObject
parseObject = choice
    [ "blob"   ? parseBlob
    , "tree"   ? parseTree
    , "commit" ? parseCommit
    , "tag"    ? parseTag
    ] where (?) oType parser = parseHeader oType >> parser

parseSymRef :: Parser String
parseSymRef = string "ref:" *> space *> anyChar `manyTill'` endOfLine
