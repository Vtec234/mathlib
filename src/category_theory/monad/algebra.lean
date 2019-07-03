/-
Copyright (c) 2019 Scott Morrison. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Scott Morrison
-/
import category_theory.monad.basic
import category_theory.adjunction.basic

namespace category_theory
open category

universes v₁ u₁ -- declare the `v`'s first; see `category_theory.category` for an explanation

variables {C : Type u₁} [𝒞 : category.{v₁} C]
include 𝒞

namespace monad

structure algebra (T : monad.{v₁} C) : Type (max u₁ v₁) :=
(A : C)
(a : T.T.obj A ⟶ A)
(unit' : T.η.app A ≫ a = 𝟙 A . obviously)
(assoc' : (T.μ.app A ≫ a) = (T.T.map a ≫ a) . obviously)

restate_axiom algebra.unit'
restate_axiom algebra.assoc'

namespace algebra
variables {T : monad.{v₁} C}

structure hom (A B : algebra T) :=
(f : A.A ⟶ B.A)
(h' : T.T.map f ≫ B.a = A.a ≫ f . obviously)

restate_axiom hom.h'
attribute [simp] hom.h

namespace hom
@[extensionality] lemma ext {A B : algebra T} (f g : hom A B) (w : f.f = g.f) : f = g :=
by { cases f, cases g, congr, assumption }

def id (A : algebra T) : hom A A :=
{ f := 𝟙 A.A }

@[simp] lemma id_f (A : algebra T) : (id A).f = 𝟙 A.A := rfl

def comp {P Q R : algebra T} (f : hom P Q) (g : hom Q R) : hom P R :=
{ f := f.f ≫ g.f,
  h' := by rw [functor.map_comp, category.assoc, g.h, ←category.assoc, f.h, category.assoc] }

@[simp] lemma comp_f {P Q R : algebra T} (f : hom P Q) (g : hom Q R) : (comp f g).f = f.f ≫ g.f := rfl
end hom

instance EilenbergMoore : category (algebra T) :=
{ hom := hom,
  id := hom.id,
  comp := @hom.comp _ _ _ }

@[simp] lemma id_f (P : algebra T) : hom.f (𝟙 P) = 𝟙 P.A := rfl
@[simp] lemma comp_f {P Q R : algebra T} (f : P ⟶ Q) (g : Q ⟶ R) : (f ≫ g).f = f.f ≫ g.f := rfl

end algebra

variables (T : monad.{v₁} C)

def forget : algebra T ⥤ C :=
{ obj := λ A, A.A,
  map := λ A B f, f.f }

@[simp] lemma forget_map {X Y : algebra T} (f : X ⟶ Y) : (forget T).map f = f.f := rfl

def free : C ⥤ algebra T :=
{ obj := λ X,
  { A := T.T.obj X,
    a := T.μ.app X,
    assoc' := (monad.assoc T _).symm },
  map := λ X Y f,
  { f := T.T.map f,
    h' := by erw T.μ.naturality } }

@[simp] lemma free_obj_a (X) : ((free T).obj X).a = T.μ.app X := rfl
@[simp] lemma free_map_f {X Y : C} (f : X ⟶ Y) : ((free T).map f).f = T.T.map f := rfl

def adj : free T ⊣ forget T :=
adjunction.mk_of_hom_equiv
{ hom_equiv := λ X Y,
  { to_fun := λ f, T.η.app X ≫ f.f,
    inv_fun := λ f,
    { f := T.T.map f ≫ Y.a,
      h' :=
      begin
        dsimp, simp,
        conv { to_rhs, rw [←category.assoc, ←T.μ.naturality, category.assoc], erw algebra.assoc },
        refl,
      end },
    left_inv := λ f,
    begin
      ext1, dsimp,
      simp only [free_obj_a, functor.map_comp, algebra.hom.h, category.assoc],
      erw [←category.assoc, T.right_unit, id_comp],
    end,
    right_inv := λ f,
    begin
      dsimp,
      erw [←category.assoc, ←T.η.naturality, functor.id_map,
            category.assoc, Y.unit, comp_id],
    end }}

end monad

end category_theory
