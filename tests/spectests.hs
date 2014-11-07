{-# Language OverloadedStrings #-}

import Database.KyotoCabinet.DB.Hash
import Database.KyotoCabinet.Operations
import Data.ByteString.Char8 ()
import Control.Monad

import Prelude hiding (iterate)

test1 :: IO ()
test1 = do
  -- Create the DB
  db <- makeHash "/tmp/casket.kch" defaultLoggingOptions defaultHashOptions (Writer [Create] [])

  set db "foo" "hop"
  set db "bar" "step"
  set db "baz" "jump"

  get db "foo" >>= putStrLn . show

  -- This will be done with cursors
  let visitor = \k v -> putStr (show k) >> putStr ":" >> putStrLn (show v) >>
                        return (Left NoOperation)
  iterate db visitor False

  close db

test2 :: IO ()
test2 = do
  db <- openHash "/tmp/casket.kch" defaultLoggingOptions (Reader [])

  let vfull  = \k v -> putStr (show k) >> putStr ":" >> putStrLn (show v) >>
                       return (Left NoOperation)
      vempty = \k   -> putStr (show k) >> putStrLn " is missing" >> return Nothing

  accept db "foo" vfull vempty False
  accept db "dummy" vfull vempty False

  iterate db vfull False

  close db

test3 :: IO ()
test3 = do
  db <- openHash "/tmp/casket.kch" defaultLoggingOptions (Reader [])

  res <- getBulk db ["foo", "bar", "baz"] False
  unless (lookup "foo" res == Just "hop"
       && lookup "bar" res == Just "step"
       && lookup "baz" res == Just "jump") $
    error ("test2: " ++ show res)

  close db

main :: IO ()
main = putStrLn "----------------------" >> test1 >> putStrLn "\n" >>
       putStrLn "----------------------" >> test2 >> putStrLn "\n" >>

       -- 100 times to let valgrind catch memory leaks
       putStrLn "----------------------" >> replicateM_ 100 test3 >> putStrLn "\n" >>

       return ()
