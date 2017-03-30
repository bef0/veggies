{-# LANGUAGE TupleSections #-}
{-# LANGUAGE StandaloneDeriving #-}
module Veggies.ASTUtils where

import Data.List
import Data.Maybe
import Data.Bifunctor
import Control.Arrow ((&&&))
import Data.Either
import Control.Monad.State
import Control.Monad.Writer

import Var (Var)

import Ollvm_ast

import Debug.Trace
import GHC.Stack

data TopLevelThing
    = TLAlias  Coq_alias
    | TLGlobal Coq_global
    | TLTyDef  Coq_type_decl
    | TLDecl   Coq_declaration
    | TLDef    Coq_definition

mkCoqModul :: String -> [TopLevelThing] -> Coq_modul
mkCoqModul name top_level_things
    = Coq_mk_modul name
        (TLE_Target "x86_64-pc-linux")
        (TLE_Source_filename "no data layout here")
        (map ("",) [ x | TLGlobal x <- top_level_things ])
        (map ("",) [ x | TLTyDef x  <- top_level_things ])
        (map ("",) [ x | TLDecl x   <- top_level_things ])
        (map ("",) [ x | TLDef x    <- top_level_things ])
        (map ("",) [ x | TLAlias x  <- top_level_things ])

ident id = SV (VALUE_Ident id)

noop ty val = INSTR_Op (SV (OP_Conversion Bitcast ty val ty))

getElemPtr :: Coq_typ -> Coq_ident -> [Integer] -> Coq_instr
getElemPtr t v path
    = INSTR_Op (SV (OP_GetElementPtr t (t, ident v) [(TYPE_I 32, SV (VALUE_Integer n))| n <- path]))

mallocRetTyP = TYPE_Pointer (TYPE_I 8)
mallocTy = TYPE_Function mallocRetTyP [TYPE_I 64]
mallocIdent = ID_Global (Name "malloc")

mallocDecl :: TopLevelThing
mallocDecl = TLDecl $ Coq_mk_declaration
    (Name "malloc")
    mallocTy
    ([],[[]])
    Nothing
    Nothing
    Nothing
    Nothing
    []
    Nothing
    Nothing
    Nothing

exitRetTyP = TYPE_Void
exitTy = TYPE_Function exitRetTyP [TYPE_I 64]
exitIdent = ID_Global (Name "exit")

exitDecl :: TopLevelThing
exitDecl = TLDecl $ Coq_mk_declaration
    (Name "exit")
    exitTy
    ([],[[]])
    Nothing
    Nothing
    Nothing
    Nothing
    []
    Nothing
    Nothing
    Nothing

putsRetTyP = TYPE_Void
putsTy = TYPE_Function putsRetTyP [TYPE_Pointer (TYPE_I 8)]
putsIdent = ID_Global (Name "puts")

putsDecl :: TopLevelThing
putsDecl = TLDecl $ Coq_mk_declaration
    (Name "puts")
    putsTy
    ([],[[]])
    Nothing
    Nothing
    Nothing
    Nothing
    []
    Nothing
    Nothing
    Nothing

