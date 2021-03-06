module Hint.Annotations (
    getModuleAnnotations,
    getValAnnotations
) where

import Data.Data
import Annotations
import GHC.Serialized
import MonadUtils (concatMapM)

import Hint.Base
import HscTypes (hsc_mod_graph, ms_mod)
import qualified Hint.GHC as GHC

-- Get the annotations associated with a particular module.
getModuleAnnotations :: (Data a, MonadInterpreter m) => a -> String -> m [a]
getModuleAnnotations _ x = do
    mods <- GHC.mgModSummaries . hsc_mod_graph <$> runGhc GHC.getSession
    let x' = filter ((==) x . GHC.moduleNameString . GHC.moduleName . ms_mod) mods
    concatMapM (anns . ModuleTarget . ms_mod) x'

-- Get the annotations associated with a particular function.
getValAnnotations :: (Data a, MonadInterpreter m) => a -> String -> m [a]
getValAnnotations _ s = do
    names <- runGhc1 GHC.parseName s
    concatMapM (anns . NamedTarget) names

anns :: (MonadInterpreter m, Data a) => AnnTarget GHC.Name -> m [a]
anns = runGhc1 (GHC.findGlobalAnns deserializeWithData)
