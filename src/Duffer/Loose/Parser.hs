module Duffer.Loose.Parser where

import Prelude                          hiding (take)

import Data.ByteString                  (ByteString, cons, pack, find)
import Control.Applicative              ((<|>))
import Data.Attoparsec.ByteString       (Parser, anyWord8, notInClass)
import Data.Attoparsec.ByteString.Char8 (anyChar, char, char8, choice, digit
                                        ,isDigit, space, string, manyTill'
                                        ,endOfLine, takeByteString, takeTill
                                        ,takeWhile1, many', take)
import Data.ByteString.Base16           (encode)
import Data.ByteString.UTF8             (fromString)
import Data.Set                         (fromList)
import Numeric                          (readOct)

import Duffer.Loose.Objects (GitObjectGeneric(..), GitObject, TreeEntry(..)
                            ,PersonTime(..), Ref)

parseNull :: Parser Char
parseNull = char '\NUL'

parseHeader :: ByteString -> Parser String
parseHeader = (*> digit `manyTill'` parseNull) . (*> space) . string

parseRestOfLine :: Parser ByteString
parseRestOfLine = takeTill (=='\n') <* endOfLine

parseMessage :: Parser ByteString
parseMessage = endOfLine *> takeByteString

parseTimeZone :: Parser ByteString
parseTimeZone = cons <$> (char8 '+' <|> char8 '-') <*> takeWhile1 isDigit

validateRef :: Monad m => ByteString -> m Ref
validateRef possibleRef = maybe
    (return possibleRef)
    (const $ fail "invalid ref")
    $ find (notInClass "0-9a-f") possibleRef

parseHexRef, parseBinRef :: Parser Ref
parseHexRef = validateRef =<< take 40
parseBinRef = validateRef =<< encode <$> take 20

parseBlob :: Parser GitObject
parseBlob = Blob <$> takeByteString

parseTree :: Parser GitObject
parseTree = Tree . fromList <$> many' parseTreeEntry

parseTreeEntry :: Parser TreeEntry
parseTreeEntry = TreeEntry <$> parsePerms <*> parseName <*> parseBinRef
    where parsePerms = toEnum . fst . head . readOct <$> digit `manyTill'` space
          parseName  = takeWhile1 (/='\NUL')         <*  parseNull

parsePersonTime :: Parser PersonTime
parsePersonTime = PersonTime
    <$> (pack       <$> anyWord8 `manyTill'` string " <")
    <*> (pack       <$> anyWord8 `manyTill'` string "> ")
    <*> (fromString <$> digit    `manyTill'` space)
    <*> parseTimeZone

parseCommit :: Parser GitObject
parseCommit = Commit
    <$>        ("tree"      *> space *> parseHexRef     <* endOfLine)
    <*>  many' ("parent"    *> space *> parseHexRef     <* endOfLine)
    <*>        ("author"    *> space *> parsePersonTime <* endOfLine)
    <*>        ("committer" *> space *> parsePersonTime <* endOfLine)
    <*>        parseMessage

parseTag :: Parser GitObject
parseTag = Tag
    <$> ("object" *> space *> parseHexRef     <* endOfLine)
    <*> ("type"   *> space *> parseType       <* endOfLine)
    <*> ("tag"    *> space *> parseRestOfLine)
    <*> ("tagger" *> space *> parsePersonTime <* endOfLine)
    <*> parseMessage
    where parseType = choice $ map string ["blob", "tree", "commit", "tag"]

parseObject :: Parser GitObject
parseObject = choice
    [ "blob"   .*> parseBlob
    , "tree"   .*> parseTree
    , "commit" .*> parseCommit
    , "tag"    .*> parseTag
    ] where (.*>) oType = (parseHeader oType *>)

parseSymRef :: Parser String
parseSymRef = string "ref:" *> space *> anyChar `manyTill'` endOfLine
