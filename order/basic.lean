/-
Copyright (c) 2014 Jeremy Avigad. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Jeremy Avigad, Mario Carneiro
-/
import tactic.interactive logic.basic data.sigma data.sum data.set.basic
open function

/- TODO: automatic construction of dual definitions / theorems -/

universes u v w
variables {α : Type u} {β : Type v} {γ : Type w}

section monotone
variables [preorder α] [preorder β] [preorder γ]

def monotone (f : α → β) := ∀⦃a b⦄, a ≤ b → f a ≤ f b

theorem monotone_id : @monotone α α _ _ id := assume x y h, h

theorem monotone_const {b : β} : monotone (λ(a:α), b) := assume x y h, le_refl b

theorem monotone_comp {f : α → β} {g : β → γ} (m_f : monotone f) (m_g : monotone g) :
  monotone (g ∘ f) :=
assume a b h, m_g (m_f h)

end monotone

section increasing
variables [preorder α]

definition increasing (f : α → α) := ∀a, a ≤ f a

end increasing

section decreasing
variables [preorder α]

definition decreasing (f : α → α) := ∀a, f a ≤ a
end decreasing

/- order instances -/

def preorder_dual (o : preorder α) : preorder α :=
{ le       := λx y, y ≤ x,
  le_refl  := le_refl,
  le_trans := assume a b c h₁ h₂, le_trans h₂ h₁ }

instance preorder_fun {ι : Type u} {α : ι → Type v} [∀i, preorder (α i)] : preorder (Πi, α i) :=
{ le       := λx y, ∀i, x i ≤ y i,
  le_refl  := assume a i, le_refl (a i),
  le_trans := assume a b c h₁ h₂ i, le_trans (h₁ i) (h₂ i) }

-- instance preorder_fun [preorder β] : preorder (α → β) := by apply_instance

instance partial_order_fun {ι : Type u} {α : ι → Type v} [∀i, partial_order (α i)] : partial_order (Πi, α i) :=
{ le_antisymm := λf g h1 h2, funext (λb, le_antisymm (h1 b) (h2 b)),
  ..preorder_fun }

def partial_order_dual (wo : partial_order α) : partial_order α :=
{ le          := λx y, y ≤ x,
  le_refl     := le_refl,
  le_trans    := assume a b c h₁ h₂, le_trans h₂ h₁,
  le_antisymm := assume a b h₁ h₂, le_antisymm h₂ h₁ }

theorem le_dual_eq_le {α : Type} (wo : partial_order α) (a b : α) :
  @has_le.le _ (@preorder.to_has_le _ (@partial_order.to_preorder _ (partial_order_dual wo))) a b =
  @has_le.le _ (@preorder.to_has_le _ (@partial_order.to_preorder _ wo)) b a :=
rfl

theorem comp_le_comp_left_of_monotone [preorder α] [preorder β] [preorder γ]
  {f : β → α} {g h : γ → β} (m_f : monotone f) (le_gh : g ≤ h) : has_le.le.{max w u} (f ∘ g) (f ∘ h) :=
assume x, m_f (le_gh x)

section monotone
variables [preorder α] [preorder γ]

theorem monotone_lam {f : α → β → γ} (m : ∀b, monotone (λa, f a b)) : monotone f :=
assume a a' h b, m b h

theorem monotone_app (f : β → α → γ) (b : β) (m : monotone (λa b, f b a)) : monotone (f b) :=
assume a a' h, m h b

end monotone

/- additional order classes -/

/-- order without a top element; somtimes called cofinal -/
class no_top_order (α : Type u) [preorder α] : Prop :=
(no_top : ∀a:α, ∃a', a < a')

lemma no_top [preorder α] [no_top_order α] : ∀a:α, ∃a', a < a' :=
no_top_order.no_top

/-- order without a bottom element; somtimes called coinitial or dense -/
class no_bot_order (α : Type u) [preorder α] : Prop :=
(no_bot : ∀a:α, ∃a', a' < a)

lemma no_bot [preorder α] [no_bot_order α] : ∀a:α, ∃a', a' < a :=
no_bot_order.no_bot

class densely_ordered (α : Type u) [preorder α] : Prop :=
(dense : ∀a₁ a₂:α, a₁ < a₂ → ∃a, a₁ < a ∧ a < a₂)

lemma dense [preorder α] [densely_ordered α] : ∀{a₁ a₂:α}, a₁ < a₂ → ∃a, a₁ < a ∧ a < a₂ :=
densely_ordered.dense

lemma le_of_forall_le_of_dense [linear_order α] [densely_ordered α] {a₁ a₂ : α} (h : ∀a₃>a₂, a₁ ≤ a₃) :
  a₁ ≤ a₂ :=
le_of_not_gt $ assume ha,
  let ⟨a, ha₁, ha₂⟩ := dense ha in
  lt_irrefl a $ lt_of_lt_of_le ‹a < a₁› (h _ ‹a₂ < a›)

lemma eq_of_le_of_forall_le_of_dense [linear_order α] [densely_ordered α] {a₁ a₂ : α}
  (h₁ : a₂ ≤ a₁) (h₂ : ∀a₃>a₂, a₁ ≤ a₃) : a₁ = a₂ :=
le_antisymm (le_of_forall_le_of_dense h₂) h₁

lemma le_of_forall_ge_of_dense [linear_order α] [densely_ordered α] {a₁ a₂ : α}(h : ∀a₃<a₁, a₂ ≥ a₃) :
  a₁ ≤ a₂ :=
le_of_not_gt $ assume ha,
  let ⟨a, ha₁, ha₂⟩ := dense ha in
  lt_irrefl a $ lt_of_le_of_lt (h _ ‹a < a₁›) ‹a₂ < a›

lemma eq_of_le_of_forall_ge_of_dense [linear_order α] [densely_ordered α] {a₁ a₂ : α}
  (h₁ : a₂ ≤ a₁) (h₂ : ∀a₃<a₁, a₂ ≥ a₃) : a₁ = a₂ :=
le_antisymm (le_of_forall_ge_of_dense h₂) h₁

section
variables {r : α → α → Prop} {s : β → β → Prop} {t : γ → γ → Prop}

def is_irrefl_of_is_asymm [is_asymm α r] : is_irrefl α r :=
⟨λ a h, asymm h h⟩

def is_irrefl.swap (r) [is_irrefl α r] : is_irrefl α (swap r) :=
⟨@irrefl α r _⟩

def is_trans.swap (r) [is_trans α r] : is_trans α (swap r) :=
⟨λ a b c h₁ h₂, (trans h₂ h₁ : r c a)⟩

def is_strict_order.swap (r) [is_strict_order α r] : is_strict_order α (swap r) :=
⟨is_irrefl.swap r, is_trans.swap r⟩

@[algebra] class is_strict_total_order' (α : Type u) (lt : α → α → Prop) extends is_trichotomous α lt, is_strict_order α lt : Prop.

def is_trichotomous.swap (r) [is_trichotomous α r] : is_trichotomous α (swap r) :=
⟨λ a b, by simpa [swap, or_comm, or.left_comm] using @trichotomous _ r _ a b⟩

def is_strict_total_order'.swap (r) [is_strict_total_order' α r] : is_strict_total_order' α (swap r) :=
⟨is_trichotomous.swap r, is_strict_order.swap r⟩

instance [linear_order α] : is_strict_total_order' α (<) :=
⟨⟨lt_trichotomy⟩, ⟨lt_irrefl⟩, ⟨@lt_trans _ _⟩⟩

@[algebra] class is_order_connected (α : Type u) (lt : α → α → Prop) : Prop :=
(conn : ∀ a b c, lt a c → lt a b ∨ lt b c)

theorem is_order_connected.neg_trans (r : α → α → Prop) [is_order_connected α r]
  {a b c} (h₁ : ¬ r a b) (h₂ : ¬ r b c) : ¬ r a c :=
mt (is_order_connected.conn a b c) $ by simp [h₁, h₂]

def is_strict_weak_order_of_is_order_connected [is_asymm α r] :
  ∀ [is_order_connected α r], is_strict_weak_order α r
| ⟨H⟩ := ⟨⟨is_irrefl_of_is_asymm,
  ⟨λ a b c h₁ h₂, (H _ c _ h₁).resolve_right (asymm h₂)⟩⟩,
  ⟨λ a b c ⟨h₁, h₂⟩ ⟨h₃, h₄⟩,
    have H' : ∀ {a b c}, ¬ r a b → ¬ r b c → ¬ r a c,
    from λ a b c, by simpa [not_or_distrib] using mt (H a b c),
    ⟨H' h₁ h₃, H' h₄ h₂⟩⟩⟩

instance is_order_connected_of_is_strict_total_order'
  [is_strict_total_order' α r] : is_order_connected α r :=
⟨λ a b c h, (trichotomous _ _).imp_right (λ o,
  o.elim (λ e, e ▸ h) (λ h', trans h' h))⟩

instance is_strict_total_order_of_is_strict_total_order'
  [is_strict_total_order' α r] : is_strict_total_order α r :=
⟨by apply_instance, is_strict_weak_order_of_is_order_connected⟩

@[algebra] class is_extensional (α : Type u) (r : α → α → Prop) : Prop :=
(ext : ∀ a b, (∀ x, r x a ↔ r x b) → a = b)

instance is_extensional_of_is_strict_total_order'
  [is_strict_total_order' α r] : is_extensional α r :=
⟨λ a b H, ((@trichotomous _ r _ a b)
  .resolve_left $ mt (H _).2 (irrefl a))
  .resolve_right $ mt (H _).1 (irrefl b)⟩

@[algebra] class is_well_order (α : Type u) (r : α → α → Prop) extends is_strict_total_order' α r : Prop :=
(wf : well_founded r)

instance empty_relation.is_well_order [subsingleton α] : is_well_order α empty_relation :=
⟨⟨⟨λ a b, or.inr $ or.inl $ subsingleton.elim _ _⟩,
  ⟨λ a, id⟩, ⟨λ a b c, false.elim⟩⟩,
  ⟨λ a, ⟨_, λ y, false.elim⟩⟩⟩

instance nat.lt.is_well_order : is_well_order ℕ (<) :=
⟨by apply_instance, nat.lt_wf⟩

instance sum.lex.is_well_order [is_well_order α r] [is_well_order β s] : is_well_order (α ⊕ β) (sum.lex r s) :=
⟨⟨⟨λ a b, by cases a; cases b; simp; apply trichotomous⟩,
  ⟨λ a, by cases a; simp; apply irrefl⟩,
  ⟨λ a b c, by cases a; cases b; simp; cases c; simp; apply trans⟩⟩,
  sum.lex_wf (is_well_order.wf r) (is_well_order.wf s)⟩

instance prod.lex.is_well_order [is_well_order α r] [is_well_order β s] : is_well_order (α × β) (prod.lex r s) :=
⟨⟨⟨λ ⟨a₁, a₂⟩ ⟨b₁, b₂⟩, match @trichotomous _ r _ a₁ b₁ with
    | or.inl h₁ := or.inl $ prod.lex.left _ _ _ h₁
    | or.inr (or.inr h₁) := or.inr $ or.inr $ prod.lex.left _ _ _ h₁
    | or.inr (or.inl e) := e ▸  match @trichotomous _ s _ a₂ b₂ with
      | or.inl h := or.inl $ prod.lex.right _ _ h
      | or.inr (or.inr h) := or.inr $ or.inr $ prod.lex.right _ _ h
      | or.inr (or.inl e) := e ▸ or.inr $ or.inl rfl
      end
    end⟩,
  ⟨λ ⟨a₁, a₂⟩ h, by cases h with _ _ _ _ h _ _ _ h;
     [exact irrefl _ h, exact irrefl _ h]⟩,
  ⟨λ a b c h₁ h₂, begin
    cases h₁ with a₁ a₂ b₁ b₂ ab a₁ b₁ b₂ ab;
    cases h₂ with _ _ c₁ c₂ bc _ _ c₂ bc,
    { exact prod.lex.left _ _ _ (trans ab bc) },
    { exact prod.lex.left _ _ _ ab },
    { exact prod.lex.left _ _ _ bc },
    { exact prod.lex.right _ _ (trans ab bc) }
  end⟩⟩,
  prod.lex_wf (is_well_order.wf r) (is_well_order.wf s)⟩

theorem well_founded.has_min {α} {r : α → α → Prop} (H : well_founded r)
  (p : set α) : p ≠ ∅ → ∃ a ∈ p, ∀ x ∈ p, ¬ r x a :=
by have := classical.prop_decidable; exact
not_imp_comm.1 (λ he, set.eq_empty_iff_forall_not_mem.2 $ λ a,
acc.rec_on (H.apply a) $ λ a H IH h,
he ⟨_, h, λ y, imp_not_comm.1 (IH y)⟩)

noncomputable def well_founded.min {α} {r : α → α → Prop} (H : well_founded r)
  (p : set α) (h : p ≠ ∅) : α :=
classical.some (H.has_min p h)

theorem well_founded.min_mem {α} {r : α → α → Prop} (H : well_founded r)
  (p : set α) (h : p ≠ ∅) : H.min p h ∈ p :=
let ⟨h, _⟩ := classical.some_spec (H.has_min p h) in h

theorem well_founded.not_lt_min {α} {r : α → α → Prop} (H : well_founded r)
  (p : set α) (h : p ≠ ∅) {x} (xp : x ∈ p) : ¬ r x (H.min p h) :=
let ⟨_, h'⟩ := classical.some_spec (H.has_min p h) in h' _ xp

end
