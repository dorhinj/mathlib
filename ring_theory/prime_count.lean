/-
Copyright (c) 2018 Robert Y. Lewis. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Robert Y. Lewis, Chris Hughes
-/
import data.nat.enat ring_theory.associated
import tactic.converter.interactive

variables {α : Type*}

open nat roption

/-- `prime_count a b` returns the largest natural number `n` such that
  `a ^ n ∣ b`, as an `enat` or natural with infinity. If `∀ n, a ^ n ∣ b`,
  the it return `⊤`-/
def prime_count [comm_semiring α] [decidable_rel ((∣) : α → α → Prop)] (a b : α) : enat :=
⟨∃ n : ℕ, ¬a ^ (n + 1) ∣ b, λ h, nat.find h⟩

namespace prime_count

section comm_semiring
variables [comm_semiring α] [decidable_rel ((∣) : α → α → Prop)]

@[reducible] def finite (a b : α) : Prop := (prime_count a b).dom

lemma finite_def {a b : α} : finite a b ↔ ∃ n : ℕ, ¬a ^ (n + 1) ∣ b := iff.rfl

lemma not_finite_iff_forall {a b : α} : (¬ finite a b) ↔ ∀ n : ℕ, a ^ n ∣ b :=
⟨λ h n, nat.cases_on n (one_dvd _) (by simpa [finite, prime_count] using h),
  by simp [finite, prime_count]; tauto⟩

lemma not_unit_of_finite {a b : α} (h : finite a b) : ¬is_unit a :=
let ⟨n, hn⟩ := h in mt (is_unit_iff_forall_dvd.1 ∘ is_unit_pow (n + 1)) $
λ h, hn (h b)

lemma ne_zero_of_finite {a b : α} (h : finite a b) : b ≠ 0 :=
let ⟨n, hn⟩ := h in λ hb, by simpa [hb] using hn

lemma pow_dvd_of_le_prime_count {a b : α}
  {k : ℕ} : (k : enat) ≤ prime_count a b → a ^ k ∣ b :=
nat.cases_on k (λ _, one_dvd _)
  (λ k ⟨h₁, h₂⟩, by_contradiction (λ hk, (nat.find_min _ (lt_of_succ_le (h₂ ⟨k, hk⟩)) hk)))

lemma spec {a b : α} (h : finite a b) : a ^ get (prime_count a b) h ∣ b :=
pow_dvd_of_le_prime_count (by rw enat.coe_get)

lemma is_greatest {a b : α} {m : ℕ} (hm : prime_count a b < m) : ¬a ^ m ∣ b :=
λ h, have finite a b, from enat.dom_of_le_some (le_of_lt hm),
by rw [← enat.coe_get this, enat.coe_lt_coe] at hm;
  exact nat.find_spec this (dvd.trans (pow_dvd_pow _ hm) h)

lemma is_greatest' {a b : α} {m : ℕ} (h : finite a b) (hm : get (prime_count a b) h < m) :
  ¬a ^ m ∣ b :=
is_greatest (by rwa [← enat.coe_lt_coe, enat.coe_get] at hm)

lemma unique {a b : α} {k : ℕ} (hk : a ^ k ∣ b) (hsucc : ¬a ^ (k + 1) ∣ b) :
  (k : enat) = prime_count a b :=
le_antisymm (le_of_not_gt (λ hk', is_greatest hk' hk)) $
  have finite a b, from ⟨k, hsucc⟩,
  by rw [← enat.coe_get this, enat.coe_le_coe];
    exact nat.find_min' _ hsucc

lemma unique' {a b : α} {k : ℕ} (hk : a ^ k ∣ b) (hsucc : ¬ a ^ (k + 1) ∣ b) :
  k = get (prime_count a b) ⟨k, hsucc⟩ :=
by rw [← enat.coe_inj, enat.coe_get, unique hk hsucc]

lemma le_prime_count_of_pow_dvd {a b : α}
  {k : ℕ} (hk : a ^ k ∣ b) : (k : enat) ≤ prime_count a b :=
le_of_not_gt $ λ hk', is_greatest hk' hk

lemma pow_dvd_iff_le_prime_count {a b : α}
  {k : ℕ} : a ^ k ∣ b ↔ (k : enat) ≤ prime_count a b :=
⟨le_prime_count_of_pow_dvd, pow_dvd_of_le_prime_count⟩

lemma eq_some_iff {a b : α} {n : ℕ} :
  prime_count a b = (n : enat) ↔ a ^ n ∣ b ∧ ¬a ^ (n + 1) ∣ b :=
⟨λ h, let ⟨h₁, h₂⟩ := eq_some_iff.1 h in
    h₂ ▸ ⟨spec _, is_greatest
      (by conv_lhs {rw ← enat.coe_get h₁ }; rw [enat.coe_lt_coe]; exact lt_succ_self _)⟩,
  λ h, eq_some_iff.2 ⟨⟨n, h.2⟩, eq.symm $ unique' h.1 h.2⟩⟩

lemma eq_top_iff {a b : α} :
  prime_count a b = ⊤ ↔ ∀ n : ℕ, a ^ n ∣ b :=
⟨λ h n, nat.cases_on n (one_dvd _)
  (λ n, by_contradiction (not_exists.1 (eq_none_iff'.1 h) n : _)),
   λ h, eq_none_iff.2 (λ n ⟨⟨_, h₁⟩, _⟩, h₁ (h _))⟩

@[simp] protected lemma zero (a : α) : prime_count a 0 = ⊤ :=
roption.eq_none_iff.2 (λ n ⟨⟨k, hk⟩, _⟩, hk (dvd_zero _))

lemma one_right {a : α} (ha : ¬is_unit a) : prime_count a 1 = 0 :=
eq_some_iff.2 ⟨dvd_refl _, mt is_unit_iff_dvd_one.2 $ by simpa⟩

@[simp] lemma get_one_right {a : α} (ha : finite a 1) : get (prime_count a 1) ha = 0 :=
get_eq_iff_eq_some.2 (eq_some_iff.2 ⟨dvd_refl _,
  by simpa [is_unit_iff_dvd_one.symm] using not_unit_of_finite ha⟩)

@[simp] lemma one_left (b : α) : prime_count 1 b = ⊤ := by simp [eq_top_iff]

@[simp] lemma prime_count_unit {a : α} (b : α) (ha : is_unit a) : prime_count a b = ⊤ :=
eq_top_iff.2 (λ _, is_unit_iff_forall_dvd.1 (is_unit_pow _ ha) _)

lemma prime_count_eq_zero_of_not_dvd {a b : α} (ha : ¬a ∣ b) : prime_count a b = 0 :=
eq_some_iff.2 (by simpa)

lemma finite_of_finite_mul_left {a b c : α} : finite a (b * c) → finite a c :=
λ ⟨n, hn⟩, ⟨n, λ h, hn (dvd.trans h (by simp [_root_.mul_pow]))⟩

lemma finite_of_finite_mul_right {a b c : α} : finite a (b * c) → finite a b :=
by rw mul_comm; exact finite_of_finite_mul_left

lemma eq_top_iff_not_finite {a b : α} : prime_count a b = ⊤ ↔ ¬ finite a b :=
roption.eq_none_iff'

local attribute [instance, priority 0] classical.prop_decidable

lemma prime_count_le_prime_count_iff {a b c d : α} : prime_count a b ≤ prime_count c d ↔
  (∀ n : ℕ, a ^ n ∣ b → c ^ n ∣ d) :=
⟨λ h n hab, (pow_dvd_of_le_prime_count (le_trans (le_prime_count_of_pow_dvd hab) h)),
  λ h, if hab : finite a b
    then by rw [← enat.coe_get hab]; exact le_prime_count_of_pow_dvd (h _ (spec _))
    else
    have ∀ n : ℕ, c ^ n ∣ d, from λ n, h n (not_finite_iff_forall.1 hab _),
    by rw [eq_top_iff_not_finite.2 hab, eq_top_iff_not_finite.2
      (not_finite_iff_forall.2 this)]⟩

lemma min_le_prime_count_add {p a b : α} :
  min (prime_count p a) (prime_count p b) ≤ prime_count p (a + b) :=
(le_total (prime_count p a) (prime_count p b)).elim
  (λ h, by rw [min_eq_left h, prime_count_le_prime_count_iff];
    exact λ n hn, dvd_add hn (prime_count_le_prime_count_iff.1 h n hn))
  (λ h, by rw [min_eq_right h, prime_count_le_prime_count_iff];
    exact λ n hn, dvd_add (prime_count_le_prime_count_iff.1 h n hn) hn)

lemma dvd_of_prime_count_pos {a b : α} (h : (0 : enat) < prime_count a b) : a ∣ b :=
by rw [← _root_.pow_one a]; exact pow_dvd_of_le_prime_count (enat.pos_iff_one_le.1 h)

lemma finite_nat_iff {a b : ℕ} : finite a b ↔ (a ≠ 1 ∧ 0 < b) :=
begin
  rw [← not_iff_not, not_finite_iff_forall, not_and_distrib, ne.def,
    not_not, not_lt, nat.le_zero_iff],
  exact ⟨λ h, or_iff_not_imp_right.2 (λ hb,
    have ha : a ≠ 0, from λ ha, by simpa [ha] using h 1,
    by_contradiction (λ ha1 : a ≠ 1,
      have ha_gt_one : 1 < a, from
        have ∀ a : ℕ, a ≤ 1 → a ≠ 0 → a ≠ 1 → false, from dec_trivial,
        lt_of_not_ge (λ ha', this a ha' ha ha1),
      not_lt_of_ge (le_of_dvd (nat.pos_of_ne_zero hb) (h b))
          (by simp only [nat.pow_eq_pow]; exact lt_pow_self ha_gt_one b))),
    λ h, by cases h; simp *⟩
end

lemma finite_int_iff_nat_abs_finite {a b : ℤ} : finite a b ↔ finite a.nat_abs b.nat_abs :=
begin
  rw [finite_def, finite_def],
  conv in (a ^ _ ∣ b)
    { rw [← int.nat_abs_dvd_abs_iff, int.nat_abs_pow, ← pow_eq_pow] }
end

lemma finite_int_iff {a b : ℤ} : finite a b ↔ (a.nat_abs ≠ 1 ∧ b ≠ 0) :=
begin
  have := int.nat_abs_eq a,
  have := @int.nat_abs_ne_zero_of_ne_zero b,
  rw [finite_int_iff_nat_abs_finite, finite_nat_iff, nat.pos_iff_ne_zero'],
  split; finish
end

instance decidable_nat : decidable_rel (λ a b : ℕ, (prime_count a b).dom) :=
λ a b, decidable_of_iff _ finite_nat_iff.symm

instance decidable_int : decidable_rel (λ a b : ℤ, (prime_count a b).dom) :=
λ a b, decidable_of_iff _ finite_int_iff.symm

end comm_semiring

section comm_ring

variables [comm_ring α] [decidable_rel ((∣) : α → α → Prop)]

local attribute [instance, priority 0] classical.prop_decidable

@[simp] protected lemma neg (a b : α) : prime_count a (-b) = prime_count a b :=
roption.ext' (by simp only [prime_count]; conv in (_ ∣ - _) {rw dvd_neg})
  (λ h₁ h₂, enat.coe_inj.1 (by rw [enat.coe_get]; exact
    eq.symm (unique ((dvd_neg _ _).2 (spec _))
      (mt (dvd_neg _ _).1 (is_greatest' _ (lt_succ_self _))))))

end comm_ring

section integral_domain

variables [integral_domain α] [decidable_rel ((∣) : α → α → Prop)]

@[simp] lemma prime_count_self {a : α} (ha : ¬is_unit a) (ha0 : a ≠ 0) :
  prime_count a a = 1 :=
eq_some_iff.2 ⟨by simp, λ ⟨b, hb⟩, ha (is_unit_iff_dvd_one.2
  ⟨b, (domain.mul_left_inj ha0).1 $ by clear _fun_match;
    simpa [_root_.pow_succ, mul_assoc] using hb⟩)⟩

@[simp] lemma get_prime_count_self {a : α} (ha : finite a a) :
  get (prime_count a a) ha = 1 :=
roption.get_eq_iff_eq_some.2 (eq_some_iff.2
  ⟨by simp, λ ⟨b, hb⟩,
    by rw [← mul_one a, _root_.pow_add, _root_.pow_one, mul_assoc, mul_assoc,
        domain.mul_left_inj (ne_zero_of_finite ha)] at hb;
      exact mt is_unit_iff_dvd_one.2 (not_unit_of_finite ha)
        ⟨b, by clear _fun_match; simp * at *⟩⟩)

lemma finite_mul_aux {p : α} (hp : prime p) : ∀ {n m : ℕ} {a b : α},
  ¬p ^ (n + 1) ∣ a → ¬p ^ (m + 1) ∣ b → ¬p ^ (n + m + 1) ∣ a * b
| n m := λ a b ha hb ⟨s, hs⟩,
  have p ∣ a * b, from ⟨p ^ (n + m) * s,
    by simp [hs, _root_.pow_add, mul_comm, mul_assoc, mul_left_comm]⟩,
  (hp.2.2 a b this).elim
    (λ ⟨x, hx⟩, have hn0 : 0 < n,
        from nat.pos_of_ne_zero (λ hn0, by clear _fun_match _fun_match; simpa [hx, hn0] using ha),
      have wf : (n - 1) < n, from nat.sub_lt_self hn0 dec_trivial,
      have hpx : ¬ p ^ (n - 1 + 1) ∣ x,
        from λ ⟨y, hy⟩, ha (hx.symm ▸ ⟨y, (domain.mul_left_inj hp.1).1
          $ by rw [nat.sub_add_cancel hn0] at hy;
            simp [hy, _root_.pow_add, mul_comm, mul_assoc, mul_left_comm]⟩),
      have 1 ≤ n + m, from le_trans hn0 (le_add_right n m),
      finite_mul_aux hpx hb ⟨s, (domain.mul_left_inj hp.1).1 begin
          rw [← nat.sub_add_comm hn0, nat.sub_add_cancel this],
          clear _fun_match _fun_match finite_mul_aux,
          simp [*, mul_comm, mul_assoc, mul_left_comm, _root_.pow_add] at *
        end⟩)
    (λ ⟨x, hx⟩, have hm0 : 0 < m,
        from nat.pos_of_ne_zero (λ hm0, by clear _fun_match _fun_match; simpa [hx, hm0] using hb),
      have wf : (m - 1) < m, from nat.sub_lt_self hm0 dec_trivial,
      have hpx : ¬ p ^ (m - 1 + 1) ∣ x,
        from λ ⟨y, hy⟩, hb (hx.symm ▸ ⟨y, (domain.mul_left_inj hp.1).1
          $ by rw [nat.sub_add_cancel hm0] at hy;
            simp [hy, _root_.pow_add, mul_comm, mul_assoc, mul_left_comm]⟩),
      finite_mul_aux ha hpx ⟨s, (domain.mul_left_inj hp.1).1 begin
          rw [add_assoc, nat.sub_add_cancel hm0],
          clear _fun_match _fun_match finite_mul_aux,
          simp [*, mul_comm, mul_assoc, mul_left_comm, _root_.pow_add] at *
        end⟩)

lemma finite_mul {p a b : α} (hp : prime p) : finite p a → finite p b → finite p (a * b) :=
λ ⟨n, hn⟩ ⟨m, hm⟩, ⟨n + m, finite_mul_aux hp hn hm⟩

lemma finite_mul_iff {p a b : α} (hp : prime p) : finite p (a * b) ↔ finite p a ∧ finite p b :=
⟨λ h, ⟨finite_of_finite_mul_right h, finite_of_finite_mul_left h⟩,
  λ h, finite_mul hp h.1 h.2⟩

lemma finite_pow {p a : α} (hp : prime p) : Π {k : ℕ} (ha : finite p a), finite p (a ^ k)
| 0     ha := ⟨0, by simp [mt is_unit_iff_dvd_one.2 hp.2.1]⟩
| (k+1) ha := by rw [_root_.pow_succ]; exact finite_mul hp ha (finite_pow ha)

protected lemma mul' {p a b : α} (hp : prime p)
  (h : finite p (a * b)) :
  get (prime_count p (a * b)) h =
  get (prime_count p a) ((finite_mul_iff hp).1 h).1 +
  get (prime_count p b) ((finite_mul_iff hp).1 h).2 :=
have hdiva : p ^ get (prime_count p a) ((finite_mul_iff hp).1 h).1 ∣ a, from spec _,
have hdivb : p ^ get (prime_count p b) ((finite_mul_iff hp).1 h).2 ∣ b, from spec _,
have hpoweq : p ^ (get (prime_count p a) ((finite_mul_iff hp).1 h).1 +
    get (prime_count p b) ((finite_mul_iff hp).1 h).2) =
    p ^ get (prime_count p a) ((finite_mul_iff hp).1 h).1 *
    p ^ get (prime_count p b) ((finite_mul_iff hp).1 h).2,
  by simp [_root_.pow_add],
have hdiv : p ^ (get (prime_count p a) ((finite_mul_iff hp).1 h).1 +
    get (prime_count p b) ((finite_mul_iff hp).1 h).2) ∣ a * b,
  by rw [hpoweq]; apply mul_dvd_mul; assumption,
have hsucc : ¬p ^ ((get (prime_count p a) ((finite_mul_iff hp).1 h).1 +
    get (prime_count p b) ((finite_mul_iff hp).1 h).2) + 1) ∣ a * b,
  from λ h, not_or (is_greatest' _ (lt_succ_self _)) (is_greatest' _ (lt_succ_self _))
    (succ_dvd_or_succ_dvd_of_succ_sum_dvd_mul hp (by convert hdiva)
      (by convert hdivb) h),
by rw [← enat.coe_inj, enat.coe_get, eq_some_iff];
  exact ⟨hdiv, hsucc⟩

local attribute [instance, priority 0] classical.prop_decidable

protected lemma mul {p a b : α} (hp : prime p) :
  prime_count p (a * b) = prime_count p a + prime_count p b :=
if h : finite p a ∧ finite p b then
by rw [← enat.coe_get h.1, ← enat.coe_get h.2, ← enat.coe_get (finite_mul hp h.1 h.2),
    ← enat.coe_add, enat.coe_inj, prime_count.mul' hp]
else begin
  rw [eq_top_iff_not_finite.2 (mt (finite_mul_iff hp).1 h)],
  cases not_and_distrib.1 h with h h;
    simp [eq_top_iff_not_finite.2 h]
end

protected lemma pow' {p a : α} (hp : prime p) (ha : finite p a) : ∀ {k : ℕ},
  get (prime_count p (a ^ k)) (finite_pow hp ha) = k * get (prime_count p a) ha
| 0     := by dsimp [_root_.pow_zero]; simp [one_right hp.2.1]; refl
| (k+1) := by dsimp only [_root_.pow_succ];
  erw [prime_count.mul' hp, pow', add_mul, one_mul, add_comm]

lemma pow {p a : α} (hp : prime p) : ∀ {k : ℕ},
  prime_count p (a ^ k) = add_monoid.smul k (prime_count p a)
| 0        := by simp [one_right hp.2.1]
| (succ k) := by simp [_root_.pow_succ, succ_smul, pow, prime_count.mul hp]

end integral_domain

end prime_count

section nat
open prime_count

lemma prime_count_eq_zero_of_coprime {p a b : ℕ} (hp : p ≠ 1)
  (hle : prime_count p a ≤ prime_count p b)
  (hab : nat.coprime a b) : prime_count p a = 0 :=
begin
  rw [prime_count_le_prime_count_iff] at hle,
  rw [← le_zero_iff_eq, ← not_lt, enat.pos_iff_one_le, ← enat.coe_one,
    ← pow_dvd_iff_le_prime_count],
  assume h,
  have := nat.dvd_gcd h (hle _ h),
  rw [coprime.gcd_eq_one hab, nat.dvd_one, _root_.pow_one] at this,
  exact hp this
end

end nat