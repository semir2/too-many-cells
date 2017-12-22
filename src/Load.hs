{- Load
Gregory W. Schwartz

Collects the functions pertaining to loading the single cell data output from
cellranger.
-}

{-# LANGUAGE BangPatterns #-}
{-# LANGUAGE OverloadedStrings #-}

module Load
    ( loadCellrangerData
    , loadMatrixData
    , loadLabelData
    ) where

-- Remote
import Data.Char (ord)
import Data.Matrix.MatrixMarket (readMatrix, Matrix(RMatrix, IntMatrix))
import Data.Maybe (fromMaybe)
import Data.Scientific (toRealFloat, Scientific)
import Data.Vector (Vector)
import Safe
import qualified Control.Lens as L
import qualified Data.ByteString.Lazy.Char8 as B
import qualified Data.Csv as CSV
import qualified Data.Map as Map
import qualified Data.Text as T
import qualified Data.Text.Read as T
import qualified Data.Vector as V
import qualified Numeric.LinearAlgebra as H

-- Local
import Types

-- | Convert a Matrix to a list of lists.
matToListOfList :: Matrix Scientific -> H.Matrix H.R
matToListOfList (RMatrix size _ _ xs) =
    H.assoc size 0
        . fmap (\(!x, !y, !z) -> ((fromIntegral x, fromIntegral y), toRealFloat z))
        $ xs
matToListOfList (IntMatrix size _ _ xs) =
    H.assoc size 0
        . fmap (\(!x, !y, !z) -> ((fromIntegral x, fromIntegral y), fromIntegral z))
        $ xs
matToListOfList _ = error "Input matrix is not a Real matrix."

-- | Load output of cellranger.
loadCellrangerData :: MatrixFile -> GeneFile -> CellFile -> IO (SingleCells MatObsRow)
loadCellrangerData mf gf cf = do
    m <- fmap matToListOfList
       . readMatrix
       . unMatrixFile
       $ mf
    g <- fmap (\ x -> either error (fmap (Gene . fst)) ( CSV.decode CSV.NoHeader x
                                       :: Either String (Vector (T.Text, T.Text))
                                        )
              )
       . B.readFile
       . unGeneFile
       $ gf
    c <- fmap (\ x -> either error (fmap (Cell . head)) ( CSV.decode CSV.NoHeader x
                                       :: Either String (Vector [T.Text])
                                        )
              )
       . B.readFile
       . unCellFile
       $ cf

    return $
        SingleCells { matrix   = MatObsRow . H.tr $ m -- We want observations as rows.
                    , rowNames = c
                    , colNames = g
                    }

-- | Load a matrix in CSV format with row names and column names.
loadMatrixData :: Delimiter -> MatrixFile -> IO (SingleCells MatObsRow)
loadMatrixData (Delimiter delim) mf = do
    let csvOpts = CSV.defaultDecodeOptions { CSV.decDelimiter = fromIntegral (ord delim) }

    all <- fmap (\ x -> either error id ( CSV.decodeWith csvOpts CSV.NoHeader x
                                       :: Either String (Vector (Vector T.Text))
                                        )
                )
         . B.readFile
         . unMatrixFile
         $ mf

    let c = fmap Cell . V.drop 1 . V.head $ all
        g = fmap (Gene . V.head) . V.drop 1 $ all
        m = fmap (fmap (either error fst . T.double) . drop 1 . V.toList)
          . drop 1
          . V.toList
          $ all

    return $
        SingleCells { matrix   = MatObsRow . H.tr . H.fromLists $ m -- We want observations as rows
                    , rowNames = c
                    , colNames = g
                    }

-- | Load a CSV containing the label of each cell.
loadLabelData :: Delimiter -> LabelFile -> IO LabelMap
loadLabelData (Delimiter delim) (LabelFile file) = do
    let csvOpts = CSV.defaultDecodeOptions { CSV.decDelimiter = fromIntegral (ord delim) }

    rows <- fmap (\ x -> either error snd ( CSV.decodeByNameWith csvOpts x
                                        :: Either String (CSV.Header, Vector (Map.Map T.Text T.Text))
                                         )
                 )
          . B.readFile
          $ file

    let toLabelMap :: Map.Map T.Text T.Text -> Map.Map Cell Label
        toLabelMap m =
            Map.singleton
                (Cell $ Map.findWithDefault (error "No \"cell\" column in label file.") "cell" m)
                (Label $ Map.findWithDefault (error "No \"label\" column in label file.") "label" m)

    return . LabelMap . Map.unions . fmap toLabelMap . V.toList $ rows
