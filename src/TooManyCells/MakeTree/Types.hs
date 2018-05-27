{- TooManyCells.MakeTree.Types
Gregory W. Schwartz

Collects the types used in the program
-}

{-# LANGUAGE StrictData #-}
{-# LANGUAGE DeriveAnyClass #-}
{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE StandaloneDeriving #-}
{-# LANGUAGE QuasiQuotes #-}
{-# LANGUAGE TemplateHaskell #-}

module TooManyCells.MakeTree.Types where

-- Remote
import BirchBeer.Types
import Data.Colour (AlphaColour)
import Data.Colour.Palette.BrewerSet (Kolor)
import Data.Colour.SRGB (Colour (..), RGB (..), toSRGB)
import Data.Map.Strict (Map)
import Data.Text (Text)
import Data.Vector (Vector)
import GHC.Generics (Generic)
import Language.R as R
import Language.R.QQ (r)
import Math.Clustering.Hierarchical.Spectral.Sparse (ShowB)
import Math.Clustering.Hierarchical.Spectral.Types (ClusteringTree, ClusteringVertex)
import Math.Modularity.Types (Q (..))
import qualified Control.Lens as L
import qualified Data.Aeson as A
import qualified Data.Aeson.TH as A
import qualified Data.Aeson.Types as A
import qualified Data.Clustering.Hierarchical as HC
import qualified Data.Graph.Inductive as G
import qualified Data.Sequence as Seq
import qualified Data.Sparse.Common as S
import qualified Numeric.LinearAlgebra as H

-- Local
import TooManyCells.Matrix.Types

-- Basic
newtype PreNormalization = PreNormalization
    { unPreNormalization :: Bool
    } deriving (Read,Show)
newtype IsLeaf = IsLeaf {unIsLeaf :: Bool} deriving (Eq, Ord, Read, Show)
newtype AdjacencyMat = AdjacencyMat
    { unAdjacencyMat :: H.Matrix H.R
    } deriving (Read,Show)
newtype L = L Double
newtype C = C Double
newtype H = H Double
newtype U = U Double
newtype V = V Double

-- Advanced
data ClusterResults = ClusterResults
    { _clusterList :: [(CellInfo, [Cluster])] -- Thanks to hierarchical clustering, we can have multiple clusters per cell.
    , _clusterDend :: HC.Dendrogram (Vector CellInfo)
    } deriving (Read,Show,Generic)

data ClusterInfo = ClusterInfo
    { _clusterId :: Cluster
    , _diversityPath :: [Int]
    , _sizePath :: [Double]
    }

data NodeInfo = NodeInfo
    { _nodeId   :: Int
    , _nodeSize :: Int
    , _nodeSplitProportion :: Maybe Double
    , _nodeModularity :: Maybe Double
    }

instance TreeItem CellInfo where
    getId = Id . unCell . _barcode

instance MatrixLike SingleCells where
    getMatrix   = unMatObsRow . _matrix
    getRowNames = fmap unCell . _rowNames
    getColNames = fmap unGene . _colNames

instance A.ToJSON Q where
    toEncoding = A.genericToEncoding A.defaultOptions
instance A.FromJSON Q

instance (A.ToJSON a) => A.ToJSON (ClusteringVertex a) where
    toEncoding = A.genericToEncoding A.defaultOptions
instance (A.FromJSON a) => A.FromJSON (ClusteringVertex a)

L.makeLenses ''ClusterResults
A.deriveJSON (A.defaultOptions {A.fieldLabelModifier = drop 1}) ''ClusterResults -- So the field does not have an underscore. Unfortunately needed for backwards compatibility.
