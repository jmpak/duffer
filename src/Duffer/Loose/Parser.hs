module Duffer.Loose.Parser where

import qualified Data.ByteString      as B

import Data.Attoparsec.ByteString.Char8 hiding (takeTill)
import Prelude                          hiding (take)

import Data.Attoparsec.ByteString
import Data.ByteString.Base16     (encode)
import Data.ByteString.UTF8       (toString)
import Data.Set                   (fromList)
import Numeric                    (readOct)

import Duffer.Loose.Objects

parseNull :: Parser Char
parseNull = char '\NUL'

parseHeader :: B.ByteString -> Parser String
parseHeader = (*> digit `manyTill` parseNull) . (*> space) . string

parseRestOfLine :: Parser String
parseRestOfLine = toString <$> takeTill (==10) <* endOfLine

parseMessage :: Parser B.ByteString
parseMessage = endOfLine *> (B.init <$> takeByteString)

parseHexRef :: Parser Ref
parseHexRef = take 40

parseBinRef :: Parser Ref
parseBinRef = encode <$> take 20

parseBlob :: Parser GitObject
parseBlob = Blob <$> takeByteString

parseTree :: Parser GitObject
parseTree = Tree . fromList <$> many' parseTreeEntry

parseTreeEntry :: Parser TreeEntry
parseTreeEntry = TreeEntry
    <$> (fst . head . readOct  <$> digit `manyTill` space)
    <*> (takeTill (==0)        <*  parseNull)
    <*> parseBinRef

parsePersonTime :: Parser PersonTime
parsePersonTime = PersonTime
    <$> (anyChar `manyTill` string " <")
    <*> (anyChar `manyTill` string "> ")
    <*> (digit   `manyTill` space)
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