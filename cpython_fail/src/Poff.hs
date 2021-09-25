
import qualified CPython as Py
import           CPython.Constants
import qualified CPython.Protocols.Object as PyO
import           CPython.Simple
import qualified CPython.Types.Dictionary as PyDict
import qualified CPython.Types.Exception as PyExc
import qualified CPython.Types.List as PyList
import qualified CPython.Types.Module as PyM
import qualified CPython.Types.Tuple as PyTuple
import qualified CPython.Types.Unicode as PyUnicode
import qualified CPython.Types.Bytes as B
import           Hoff.Serialize
import           Codec.Serialise
-- import           Hoff (Table(..))
import           Hoff.Table
import           Data.Maybe
import           Yahp

main :: IO ()
main = do
  initialize
  -- handle (\(e::SomeException) -> print e) $
  handle pyExceptionHandler $ do
    -- putStrLn . unlines =<< getAttribute @[Text] "sys" "path"
    df <- call "pandas" "read_pickle" [arg ("/tmp/a1.pickle" :: Text)] []
    print . deserialise @Table  =<< call "HoffSerialize" "toHoffCbor" [arg (df :: PyO.SomeObject)] []


pyExceptionHandler :: PyExc.Exception -> IO ()
pyExceptionHandler exception = do
    putStrLn =<< PyUnicode.fromUnicode =<< PyO.string (PyExc.exceptionType exception)
    putStrLn =<< PyUnicode.fromUnicode =<< PyO.string (PyExc.exceptionValue exception)
    forM_ (PyExc.exceptionTraceback exception) $ \tb -> putStrLn =<< call @Text "traceback" "print_tb" [arg tb] []

instance ToPy PyO.SomeObject where toPy = pure
instance FromPy PyO.SomeObject where fromPy = pure
instance FromPy LByteString where fromPy = fmap toS . easyFromPy B.fromBytes Proxy

