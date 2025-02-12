/-
Copyright (c) 2022 James Gallicchio.

Authors: James Gallicchio
-/

import LeanColls.Classes
import LeanColls.FoldableOps
import LeanColls.FoldableCorrect
import LeanColls.List

namespace LeanColls

/-! # View

Isomorphic to a `(Foldable C τ) × C`; a fold instantiated
at a specific collection. Used to implement inline transformations
which are only evaluated when the collection is folded into a result.
-/
structure View.{u,v} (τ : Type u) where
  fold : {β : Type v} → (β → τ → β) → β → β

namespace View

@[inline]
instance : Foldable.{max u (v+1),u,v} (View.{u,v} τ) τ where
  fold v f acc := v.fold f acc  

@[inline, simp]
instance : FoldableOps (View τ) τ := FoldableOps.defaultImpl (View τ) τ  

@[inline]
def view {F τ} (c : F) [Foldable F τ] : View τ where
  fold := λ f acc => Foldable.fold c f acc

@[inline]
def view' [Foldable' C τ M] (c : C) : View {x // M.mem x c} where
  fold foldF foldAcc :=
    Foldable'.fold' c (fun acc x i => foldF acc ⟨x,i⟩) foldAcc

@[inline]
def map {τ : Type u} {τ' : Type v} (f : τ → τ') (v : View τ) : View τ' where
  fold := λ foldF foldAcc => v.fold (λ acc t => foldF acc (f t)) foldAcc

@[inline]
def filter (f : τ → Bool) (v : View τ) : View τ where
  fold := λ foldF foldAcc =>
    v.fold (λ a x =>
      if f x then foldF a x else a
    ) foldAcc

@[inline]
def filterMap (f : τ → Option τ') (v : View τ) : View τ' where
  fold := λ foldF foldAcc =>
    v.fold (λ a x =>
      match f x with
      | none    => a
      | some x' => foldF a x'
    ) foldAcc

@[inline]
def flatten (v : View C) [Foldable C τ] : View τ where
  fold := λ foldF foldAcc =>
    v.fold (λ a c =>
      Foldable.fold c foldF a)
      foldAcc

@[inline]
def flatMap (f : τ → C) (v : View τ) [Foldable C τ'] : View τ' where
  fold := λ foldF foldAcc =>
    v.fold (λ a t =>
      Foldable.fold (f t) foldF a)
      foldAcc

@[inline]
def append (v : View τ) (v2 : View τ) : View τ where
  fold := λ foldF foldAcc =>
    v2.fold foldF
      (v.fold foldF foldAcc)

instance : Append (View τ) where
  append := append


/-! # Theorems -/

theorem view_eq_view_canonicalToList [Foldable.Correct C τ] (c : C)
  : View.view c = View.view (canonicalToList (Foldable.fold c))
  := by
  simp [view]
  funext β f acc
  simp [Foldable.fold]
  apply Foldable.Correct.foldCorrect

@[simp]
theorem map_eq_list_map (L : List τ) (f : τ → τ')
  : ((View.view L).map f)
    = View.view (List.map f L)
  := by
  simp [map, view, Foldable.fold, List.foldl_map]

@[simp]
theorem filter_eq_list_filter (L : List τ) (f : τ → Bool)
  : (View.view L).filter f
    = View.view (List.filter f L)
  := by
  simp [filter, view, Foldable.fold, List.foldl_filter]

@[simp]
theorem sum_eq_list_sum [AddMonoid τ] (L : List τ)
  : FoldableOps.sum (View.view L) = L.sum
  := by
  suffices _ by
    rw [FoldableOps.default_sum_pred_fold (view L) L this]
    apply FoldableOps.default_sum_list_eq_list_sum
  simp [view, Foldable.fold]