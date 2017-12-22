{- Types
Gregory W. Schwartz

Collects the types used in the program
-}

{-# LANGUAGE QuasiQuotes #-}
{-# LANGUAGE StandaloneDeriving #-}

module Types where

-- Remote
import Data.Colour.Palette.BrewerSet (Kolor)
import Data.Map.Strict (Map)
import Data.Text (Text)
import Data.Vector (Vector)
import Language.R as R
import Language.R.QQ (r)
import qualified Data.Clustering.Hierarchical as HC
import qualified Numeric.LinearAlgebra as H

-- Local

-- Basic
newtype Label = Label
    { unLabel :: Text
    } deriving (Eq,Ord,Read,Show)
newtype Cell            = Cell { unCell :: Text } deriving (Eq, Ord, Read, Show)
newtype Cluster         = Cluster { unCluster :: Int } deriving (Read, Show)
newtype Cols            = Cols { unCols :: [Double] }
newtype Delimiter       = Delimiter { unDelimiter :: Char }
newtype Gene            = Gene { unGene :: Text } deriving (Read, Show)
newtype CellFile        = CellFile { unCellFile :: FilePath }
newtype GeneFile        = GeneFile { unGeneFile :: FilePath }
newtype MatrixFile = MatrixFile
    { unMatrixFile :: FilePath
    } deriving (Read,Show)
newtype LabelFile       = LabelFile { unLabelFile :: FilePath }
newtype DendrogramFile  = DendrogramFile { unDendrogramFile :: FilePath }
newtype RMat s          = RMat { unRMat :: R.SomeSEXP s }
newtype RMatObsRow s    = RMatObsRow { unRMatObsRow :: R.SomeSEXP s }
newtype RMatFeatRow s   = RMatFeatRow { unRMatFeatRow :: R.SomeSEXP s }
newtype RMatObsRowImportant s = RMatObsRowImportant
    { unRMatObsRowImportant :: R.SomeSEXP s
    }
newtype RMatScaled s    = RMatScaled { unRMatScaled :: R.SomeSEXP s }
newtype Rows            = Rows { unRows :: [Double] }
newtype Vals            = Vals { unVals :: [Double] }
newtype AdjacencyMat = AdjacencyMat
    { unAdjacencyMat :: H.Matrix H.R
    } deriving (Read,Show)
newtype MatObsRow = MatObsRow
    { unMatObsRow :: H.Matrix H.R
    } deriving (Read,Show)
newtype MatObsRowImportant = MatObsRowImportant
    { unMatObsRowImportant :: H.Matrix H.R
    } deriving (Read,Show)
newtype LabelMap = LabelMap
    { unLabelMap :: Map Cell Label
    } deriving (Read,Show)
newtype ColorMap = ColorMap
    { unColorMap :: Map Label Kolor
    } deriving (Read,Show)

-- Advanced
data SingleCells a = SingleCells { matrix :: a
                                 , rowNames :: Vector Cell
                                 , colNames :: Vector Gene
                                 }
                     deriving (Read, Show)

data ClusterResults = ClusterResults { clusterList :: [((Cell, H.Vector H.R), Cluster)]
                                     , clusterDend :: HC.Dendrogram (Vector Cell)
                                     }
                      deriving (Read, Show)

deriving instance (Read a) => Read (HC.Dendrogram a)
