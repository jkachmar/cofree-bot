{-# LANGUAGE NumDecimals #-}
module CofreeBot.Bot.GHCI where

import CofreeBot.Bot
import Control.Monad
import Control.Monad.Loops (whileM)
import Data.Attoparsec.Text as A
import Data.Text qualified as T
import System.Process.Typed
import System.IO
import GHC.Conc (threadDelay)
import Data.Profunctor

type GhciBot = Bot IO () T.Text [T.Text]

hGetOutput :: Handle -> IO String
hGetOutput handle =
  whileM (hReady handle) (hGetChar handle)

ghciBot' :: Process Handle Handle () -> GhciBot
ghciBot' p = mapMaybeBot (either (const Nothing) Just . parseOnly ghciInputParser) $ Bot $ \i s -> do
  hPutStrLn (getStdin p) $ T.unpack i
  hFlush (getStdin p)
  void $ threadDelay 5e5
  o <- hGetOutput (getStdout p)
  pure $ BotAction (pure $ T.pack o) s

ghciBot :: Process Handle Handle () -> GhciBot
ghciBot p = dimap (\i -> if i == "ghci: :q" then Left i else Right i) (either id id) $ pureStatelessBot (const $ ["I'm Sorry Dave"]) \/ ghciBot' p

ghciConfig :: ProcessConfig Handle Handle ()
ghciConfig = setStdin createPipe
          $ setStdout createPipe
          $ shell "docker run -i --rm haskell 2>&1"

ghciInputParser :: Parser T.Text
ghciInputParser = do
  void $ "ghci: "
  T.pack <$> many1 anyChar

