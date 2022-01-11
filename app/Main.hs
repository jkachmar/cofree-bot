{-# LANGUAGE NumDecimals #-}
module Main where

import CofreeBot
import CofreeBot.Bot.Calculator.Language
import Control.Monad
import Data.Profunctor
import Data.Text qualified as T
import GHC.Conc (threadDelay)
import Network.Matrix.Client
import Options.Applicative qualified as Opt
import OptionsParser
import System.Environment.XDG.BaseDir ( getUserCacheDir )
import System.Process.Typed

--main :: IO ()
--main = withProcessWait_ ghciConfig $ \process -> do
--  runSimpleBot (simplifySessionBot (T.intercalate "\n" . printCalcOutput) programP $ sessionize mempty $ calculatorBot) mempty
--  runSimpleBot (ghciBot process) mempty

--  let ghciBot' = ghciBot process
--      calcBot = simplifySessionBot (T.intercalate "\n" . printCalcOutput) programP $ sessionize mempty $ calculatorBot
--  runSimpleBot (rmap (\(x :& y) -> x <> y ) $ ghciBot' /\ calcBot) (mempty)

main :: IO ()
main = withProcessWait_ ghciConfig $ \process -> do
  void $ threadDelay 5e5
  void $ hGetOutput (getStdout process)
  command <- Opt.execParser parserInfo
  xdgCache <- getUserCacheDir "cofree-bot"
  let calcBot = liftSimpleBot $ simplifySessionBot (T.intercalate "\n" . printCalcOutput) programP $ sessionize mempty $ calculatorBot
      helloBot = helloMatrixBot
      coinFlipBot' = liftSimpleBot $ simplifyCoinFlipBot coinFlipBot
      ghciBot' = liftSimpleBot $ ghciBot process
      bot = rmap (\(x :& y :& z :& q) -> x <> y <> z <> q) $ calcBot /\ helloBot /\ coinFlipBot' /\ ghciBot'
  case command of
    LoginCmd cred -> do
      session <- login cred
      runMatrixBot session xdgCache bot mempty
    TokenCmd TokenCredentials{..} -> do
      session <- createSession (getMatrixServer matrixServer) matrixToken
      runMatrixBot session xdgCache bot mempty
