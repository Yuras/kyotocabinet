module Database.KyotoCabinet.Forest
       ( Forest
       , ForestOptions (..)
       , Compressor (..)
       , Options (..)
       , Comparator (..)
       , makeForest
       , openForest
       , module Database.KyotoCabinet.Operations
       )
       where

import Data.Int (Int64, Int8)
import Data.Maybe (maybeToList)

import Prelude hiding (log)

import Database.KyotoCabinet.Internal
import Database.KyotoCabinet.Operations

newtype Forest = Forest DB

instance WithDB Forest where
  getDB (Forest db) = db

data ForestOptions = ForestOptions { alignmentPow :: Maybe Int8
                                   , freePoolPow :: Maybe Int8
                                   , options :: [Options]
                                   , buckets :: Maybe Int64
                                   , maxSize :: Maybe Int64
                                   , defragInterval :: Maybe Int64
                                   , compressor :: Maybe Compressor
                                   , cipherKey :: Maybe String
                                   , pageSize :: Maybe Int64
                                   , comparator :: Maybe Comparator
                                   , pageCacheSize :: Maybe Int64
                                   }
                   deriving (Show, Read, Eq, Ord)

toTuningOptions :: ForestOptions -> [TuningOption]
toTuningOptions ForestOptions { alignmentPow = ap
                              , freePoolPow = fp
                              , options = os
                              , buckets = bs
                              , maxSize = ms
                              , defragInterval = di
                              , compressor = cmp
                              , cipherKey = key
                              , pageSize = ps
                              , comparator = cmprtr
                              , pageCacheSize = pcs
                              } =
  mtl AlignmentPow ap ++ mtl FreePoolPow fp ++ map Options os ++ mtl Buckets bs ++
  mtl MaxSize ms ++ mtl DefragInterval di ++ mtl Compressor cmp ++ mtl CipherKey key ++
  mtl PageSize ps ++ mtl Comparator cmprtr ++ mtl PageCacheSize pcs
  where
    mtl f = maybeToList .  fmap f

className :: String
className = "kcf"

makeForest :: FilePath -> LoggingOptions -> ForestOptions -> Mode -> IO Forest
makeForest fp log opts mode = makePersistent Forest toTuningOptions className fp log opts mode

openForest :: FilePath -> LoggingOptions -> Mode -> IO Forest
openForest fp log mode = openPersistent Forest className fp log mode
