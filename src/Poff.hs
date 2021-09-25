{-# LANGUAGE QuasiQuotes #-}
module Poff where

import           Data.ByteString ( ByteString, empty )
import qualified Data.ByteString as B
import qualified Data.ByteString.Internal as BI
import qualified Data.ByteString.Unsafe as BU
import           Foreign ( castPtr )
import           GHC.IO.Exception ( IOErrorType(EOF) )
import           Hoff.Serialize
import           Hoff
import qualified Prelude
import           System.Exit
import qualified System.IO as S
import           System.IO.Error ( ioeSetErrorString, mkIOError, userError )
import           System.Posix.IO.ByteString hiding (fdWrite)
import           System.Posix.Types
import           System.Process hiding (createPipe)
import           Text.InterpolatedString.Perl6
import           Yahp

pythonHEvalWithHoff :: (ConvertText t Text)
  => FilePath -> t -> [String] -> Maybe Table -> IO Table
pythonHEvalWithHoff

-- | this uses the given Python binary to execute a script which is expected to write it's result to
-- a file descriptor, whose path (i.e. "/dev/fd/X") is passed as the first arg to python
pythonEval :: (ConvertText t Text)
  => FilePath -> t -> [String] -> ByteString -> IO ByteString
pythonEval pythonBin source args stdin = do
  (outputRead, outputWrite) <- createPipe
  (scriptRead, scriptWrite) <- createPipe

  forkIO $ do fdWrite scriptWrite $ toUtf8 source
              closeFd scriptWrite

  threadWaitRead scriptRead

  let procDescr = (proc pythonBin $ [fdPath scriptRead, fdPath outputWrite] <> args) { std_in = CreatePipe }
  withCreateProcess procDescr $ \stdinH _ _ procH -> do
    forkIO $ waitForProcess procH >> closeFd outputWrite

    let writeStdin h = forkIO $ do S.hSetBinaryMode h True -- not sure if this is needed
                                   B.hPut h stdin
                                   S.hClose h
    maybe (Prelude.error "did you set std_in = CreatePipe?") writeStdin stdinH

    -- print "waiting for python output"
    output <- B.hGetContents =<< fdToHandle outputRead
    waitForProcess procH >>= \case
      ExitFailure code -> throwIO $ userError $ "python Exit code: " <> show code
      ExitSuccess -> pure output

fdPath :: Show a => a -> String
fdPath fd = "/dev/fd/" <> show fd
                                   
  
-- | Write a 'ByteString' to an 'Fd'.
fdWrite :: Fd -> ByteString -> IO ByteCount
fdWrite fd bs = BU.unsafeUseAsCStringLen bs
  $ \(buf,len) -> fdWriteBuf fd (castPtr buf) (fromIntegral len)

main :: IO ByteString
main = pythonEval "/nix/store/sz0j8k8ljh7y8qgyfxgqb3ws11bcy4gs-python3-3.10.6/bin/python" script ["arg"] "\DLE\NUL"
  where script :: Text
        script = [q|
import sys
data = sys.stdin.buffer.read()
print(sys.argv[2])
with open(sys.argv[1], 'wb') as f:
  f.write(('stdin: ' + str(data) + ', raw: ').encode())
  f.write(data)
|]
        
