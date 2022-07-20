import combinatorics.simple_graph.clique
import combinatorics.simple_graph.degree_sum
import data.finset.basic
import data.list.basic
import data.nat.basic
import tactic.core
import algebra.big_operators
open finset nat

open_locale big_operators 

namespace simple_graph 

variables {α : Type*}[fintype α][inhabited α][decidable_eq α]
-- basic structure for a complete (t+1)-partite graph on α
-- not actually a partition in the sense of mathlib since that would
-- require at most one empty part, while I'm happy to allow any number of
-- empty parts 
@[ext] 
structure multi_part (α : Type*)[decidable_eq α][fintype α][inhabited α][decidable_eq α]:=
(t :ℕ) (P: ℕ → finset α) (A :finset α) 
(uni: A = (range(t+1)).bUnion (λi , P i))
(disj: ∀i∈ range(t+1),∀j∈ range(t+1), i≠j → disjoint (P i) (P j)) 

-- define notion of a vertex than can be moved to increase number of edges in M
def moveable (M : multi_part α) (v :α) :Prop := ∃ i∈ range(M.t+1),∃ j ∈ range(M.t+1), v∈ M.P i ∧ (M.P j).card +2 ≤ (M.P i).card



instance (α :Type*)[decidable_eq α][fintype α][inhabited α][decidable_eq α] : inhabited (multi_part α):=
{default:={ t:=0, P:= λ i , ∅, A:=∅, uni:=rfl, 
disj:=λ i hi j hj ne, disjoint_empty_left ∅,
 }}
 
---M.disj is the same as pairwise_disjoint but without any coercion to set for range(t+1) 
lemma pair_disjoint (M : multi_part α) : ((range(M.t+1):set ℕ)).pairwise_disjoint M.P:=M.disj

-- size of A is sum of size of part
lemma card_uni  (M : multi_part α) : M.A.card = ∑i in range(M.t+1),(M.P i).card:= begin
  rw [M.uni, finset.card_eq_sum_ones, sum_bUnion (pair_disjoint M)],
  apply finset.sum_congr rfl _, intros x hx, rwa ← finset.card_eq_sum_ones,
end


-- insert new disjoint set to the partition
def insert (M : multi_part α)  {B : finset α} (h: disjoint M.A B): multi_part α :={
  t:=M.t+1,
  P:=begin intro i, exact ite (i≠M.t+1) (M.P i) (B), end,
  A:=B ∪ M.A,
  uni:= begin
    rw range_succ, rw [bUnion_insert],rw M.uni, split_ifs, contradiction,
    ext,rw [mem_union,mem_union,mem_bUnion,mem_bUnion],
    split,intro h, cases h with hb hP,left, exact hb,right, 
    obtain ⟨a1, H, H2⟩:=hP, use [a1,H],split_ifs, exact H2,   
    push_neg at h_2, exfalso, rw h_2 at H, exact not_mem_range_self H,
    intros h,cases h with hb hP,left, exact hb,right, 
    obtain ⟨a1, H, H2⟩:=hP,split_ifs at H2, use [a1,H, H2],
    push_neg at h_2, exfalso, rw h_2 at H, exact not_mem_range_self H,
  end,
  disj:= begin
    intros i hi j hj iltj, split_ifs, 
    refine M.disj i _ j _ iltj,
    exact mem_range.mpr (lt_of_le_of_ne (mem_range_succ_iff.mp hi) h_1), 
    exact mem_range.mpr (lt_of_le_of_ne (mem_range_succ_iff.mp hj) h_2), 
    rw [M.uni, disjoint_bUnion_left] at h, 
    apply h i (mem_range.mpr (lt_of_le_of_ne (mem_range_succ_iff.mp hi) h_1)),
    rw [M.uni, disjoint_bUnion_left] at h, rw disjoint.comm,
    apply h j (mem_range.mpr (lt_of_le_of_ne (mem_range_succ_iff.mp hj) h_2)),
    push_neg at h_1,push_neg at h_2, rw ← h_2 at h_1, exfalso,
    exact iltj h_1, 
  end,}


-- member of a part implies member of union
lemma mem_part{M:multi_part α} {v :α} {i :ℕ}: i∈range(M.t+1) → v ∈ M.P i → v ∈ M.A :=
  begin
    intros hi hv,rw M.uni,rw mem_bUnion, exact ⟨i,hi,hv⟩,
  end

-- every vertex in A belongs to a part
lemma inv_part {M:multi_part α} {v :α} (hA: v∈M.A): ∃ i∈ range(M.t+1), v ∈ M.P i:=
begin
  rw [M.uni,mem_bUnion] at hA, exact hA,
end

-- if v belongs to P i and P j then i = j.
lemma uniq_part {M : multi_part α}{v :α} {i j : ℕ} : i ∈ range(M.t+1)→ j ∈ range(M.t+1) → v∈M.P i → v∈ M.P j → i = j:=
begin
  intros hi hj hiv hjv, by_contra, have:=M.disj i hi j hj h, exact this (mem_inter.mpr ⟨hiv,hjv⟩),
end

-- if v belongs to part i and j≠ i and is in range then v ∉ part j
lemma uniq_part' {M : multi_part α}{v :α} {i j : ℕ} : i ∈ range(M.t+1)→ j ∈ range(M.t+1) → i≠ j→ v∈M.P i → v∉ M.P j:=
begin
  intros hi hj hiv ne, contrapose hiv,push_neg at hiv,rw not_ne_iff, exact uniq_part hi hj ne hiv,
end
-- every part is contained in A
lemma sub_part {M:multi_part α} {i : ℕ} (hi: i ∈ range(M.t+1)) : M.P i ⊆ M.A :=
begin
  rw M.uni, intros x hx,  rw  mem_bUnion,  exact ⟨i,hi,hx⟩,
end


lemma two_parts {M: multi_part α} {i j : ℕ} (hi: i ∈ range(M.t+1))  (hj: j ∈ range(M.t+1)) (hne: i≠ j) : (M.P i).card + (M.P j).card ≤ M.A.card:=
begin
  rw card_uni, rw ← sum_erase_add (range(M.t+1)) _ hj, apply (add_le_add_iff_right _).mpr,
  rw ← sum_erase_add ((range(M.t+1)).erase j) _ (mem_erase_of_ne_of_mem hne hi),
  nth_rewrite 0 ← zero_add (M.P i).card, apply (add_le_add_iff_right _).mpr,
  simp only [zero_le],
  exact has_add.to_covariant_class_right ℕ,  exact contravariant_swap_add_le_of_contravariant_add_le ℕ,
  exact has_add.to_covariant_class_right ℕ,  exact contravariant_swap_add_le_of_contravariant_add_le ℕ,
end
--A is the union of each part and the sdiff
lemma sdiff_part {M:multi_part α} {i : ℕ} (hi: i ∈ range(M.t+1)) : M.A = M.A\(M.P i)∪M.P i :=
begin
  have:= sub_part hi,
  rwa [sdiff_union_self_eq_union, left_eq_union_iff_subset] at *,
end

lemma disjoint_part {M:multi_part α} {i : ℕ} : disjoint ((M.A)\(M.P i)) (M.P i) := sdiff_disjoint

lemma card_part_uni {M:multi_part α} {i : ℕ} (hi: i ∈ range(M.t+1)):  M.A.card= (M.A\(M.P i)).card + (M.P i).card:=
begin
  nth_rewrite 0 sdiff_part hi,
  apply card_disjoint_union sdiff_disjoint,
end

-- move v ∈ P i to P j,
def move (M : multi_part α) {v : α} {i j: ℕ} (hvi: i∈ range(M.t+1) ∧ v∈ M.P i) (hj : j∈range(M.t+1) ∧ j≠i) : multi_part α :={
  t:=M.t,
  P:= begin intros k, exact ite (k ≠ i ∧ k ≠ j) (M.P k) (ite (k = i) ((M.P i).erase v) ((M.P j) ∪ {v})),end,
  A:=M.A,
  uni:=begin 
    rw M.uni,ext,split, rw [mem_bUnion,mem_bUnion],intros h,simp only [*, mem_range, ne.def, exists_prop] at *,
    by_cases hav: a=v,
      refine ⟨j,hj.1,_⟩,rw ← hav at *, split_ifs,exfalso, exact h_1.2 rfl,exfalso, push_neg at h_1,exact hj.2 h_2,
      refine mem_union_right _ (mem_singleton_self a), 
      obtain ⟨k,hk1,hk2⟩:=h,
      refine ⟨k,hk1,_⟩, split_ifs, exact hk2, refine mem_erase.mpr _,rw h_1 at hk2, exact ⟨hav,hk2⟩,
      push_neg at h, rw (h h_1) at hk2, exact mem_union_left _ hk2,
    rw [mem_bUnion,mem_bUnion],intros h,simp only [*, mem_range, ne.def, exists_prop] at *,
    by_cases hav: a=v,
      rw ← hav at hvi, exact ⟨ i,hvi⟩,
      obtain ⟨k,hk1,hk2⟩:=h, split_ifs at hk2, exact ⟨k,hk1,hk2⟩, exact ⟨i,hvi.1,(erase_subset v (M.P i)) hk2⟩,
      refine ⟨j,hj.1,_⟩, rw mem_union at hk2, cases hk2, exact hk2,exfalso, exact hav (mem_singleton.mp hk2), end,
  disj:=begin 
    intros a ha b hb ne,split_ifs, exact M.disj a ha b hb ne,
    have:=M.disj a ha i hvi.1 h.1, apply disjoint_of_subset_right _ this, exact erase_subset _ _,  
    simp only [disjoint_union_right, disjoint_singleton_right], refine ⟨M.disj a ha j hj.1 h.2,_⟩,
    intro hv, exact h.1 (uniq_part ha hvi.1 hv hvi.2),
    have:=M.disj i hvi.1 b hb  h_2.1.symm,apply disjoint_of_subset_left _ this, exact erase_subset _ _, 
    exfalso, push_neg at h, push_neg at h_2,rw [h_1,h_3] at ne, exact ne rfl,
    simp only [disjoint_union_right, disjoint_singleton_right, mem_erase, _root_.ne.def, eq_self_iff_true, not_true, false_and,
    not_false_iff, and_true],
    have:=M.disj i hvi.1 j hj.1 hj.2.symm, apply disjoint_of_subset_left _ this, exact erase_subset _ _, 
    simp only [disjoint_union_left, disjoint_singleton_right],
    refine ⟨M.disj j hj.1 b hb h_2.2.symm,_⟩, rw disjoint_singleton_left,
    intro hb2, have:= uniq_part hb hvi.1 hb2 hvi.2 , exact h_2.1 this,
    simp only [disjoint_union_left, disjoint_singleton_left, mem_erase, _root_.ne.def, eq_self_iff_true, not_true, false_and,
  not_false_iff, and_true],
    have:=M.disj j hj.1  i hvi.1 hj.2, apply disjoint_of_subset_right _ this, exact erase_subset _ _, 
    exfalso, push_neg at h_2,push_neg at h, have bj:= h_2 h_3, have aj:= h h_1,rw aj at ne, rw bj at ne, exact ne rfl,
  end,}


--- given a t+1 partition on A form the complete multi-partite graph 
def mp (M: multi_part α) : simple_graph α:={
  adj:= λ x y, (∃ i ∈ range(M.t+1), ∃ j ∈ range(M.t+1), i≠j ∧ ((x∈ M.P i ∧ y ∈ M.P j) ∨ (x ∈ M.P j ∧ y ∈ M.P i))), 
  symm:=
  begin
    intros x y hxy,
    obtain ⟨i,hi,j,hj,ne,⟨hx,hy⟩⟩:=hxy,
    refine ⟨j ,hj, i, hi, ne.symm,_ ⟩, left ,exact ⟨hy,hx⟩,
    refine ⟨i ,hi, j, hj, ne,_ ⟩, left, rwa and_comm, 
  end,
  loopless:=begin
    intro x, push_neg, intros i hi j hj ne, 
    split; intros hxi hxj, exact M.disj i hi j hj ne (mem_inter.mpr ⟨hxi,hxj⟩), 
    exact M.disj i hi j hj ne (mem_inter.mpr ⟨hxj,hxi⟩), 
end,}

lemma move_A {M : multi_part α} {v : α} {i j: ℕ} (hvi: i∈ range(M.t+1) ∧ v∈ M.P i) (hj : j∈range(M.t+1) ∧ j≠i) :(move M hvi hj).A=M.A:=
rfl

lemma move_t {M : multi_part α} {v : α} {i j: ℕ} (hvi: i∈ range(M.t+1) ∧ v∈ M.P i) (hj : j∈range(M.t+1) ∧ j≠i) :(move M hvi hj).t=M.t:=
 rfl

lemma move_P {M : multi_part α} {v : α} {i j k: ℕ} (hvi: i∈ range(M.t+1) ∧ v∈ M.P i) (hj : j∈range(M.t+1) ∧ j≠i) : k∈ range(M.t+1) → ((move M hvi hj).P k) = ite (k≠i ∧k≠j) (M.P k) (ite (k=i) ((M.P i).erase v) ((M.P j) ∪ {v})):=
begin
  intros k , refl,
end

-- how have the sizes of parts changed by moving v
lemma move_Pcard {M : multi_part α} {v : α} {i j k: ℕ} (hvi: i∈ range(M.t+1) ∧ v∈ M.P i) (hj : j∈range(M.t+1) ∧ j≠i) : k∈ range(M.t+1) → ((move M hvi hj).P k).card = ite (k≠i ∧k≠j) (M.P k).card (ite (k=i) ((M.P i).card -1) ((M.P j).card+1)):=
begin
  intros hk,rw move_P hvi hj hk,split_ifs, 
  refl,  exact card_erase_of_mem hvi.2,
  have jv:=uniq_part' hvi.1 hj.1 hj.2.symm hvi.2,
  rw ← disjoint_singleton_right at jv,
  apply card_disjoint_union jv,
end

lemma sdiff_erase {v : α} {A B :finset α} (hB: B⊆A) (hv: v ∈ B) : A\(B.erase v)=(A\B) ∪ {v} :=
begin
  ext, split, intro h, rw [mem_union,mem_sdiff] at *,rw mem_sdiff at h,rw mem_erase at h,
  push_neg at h, by_cases h': a=v,right, exact mem_singleton.mpr h',
  left, exact ⟨h.1,(h.2 h')⟩,
  intros h,rw mem_sdiff,rw mem_erase,rw [mem_union,mem_sdiff] at h, push_neg,
  cases h,exact ⟨h.1,λi,h.2⟩,by_contra h',push_neg at h',
  have ha:=hB hv,
  have:=mem_singleton.mp h, rw ← this at ha,
  have h2:=h' ha, exact h2.1 this,
end

lemma card_sdiff_erase {v : α} {A B :finset α} (hB: B⊆A) (hv: v ∈ B) : (A\(B.erase v)).card=(A\B).card+1 :=
begin
  have hv2: v∉A\B, {rw mem_sdiff,push_neg,intro i, exact hv,},
  have:=disjoint_singleton_right.mpr hv2,
  rw sdiff_erase hB hv, exact card_disjoint_union this,
end

lemma sdiff_insert {v : α} {A B :finset α} (hB: B⊆A) (hv: v ∉ B) : A\(B ∪  {v})=(A\B).erase v:= 
begin
  ext,split,intro h,
  rw mem_erase, rw mem_sdiff at *,rw mem_union at h, push_neg at h,rw mem_singleton at h,  exact ⟨h.2.2,h.1,h.2.1⟩,
  intro h,rw mem_erase at h, rw mem_sdiff, rw mem_union, push_neg,rw mem_singleton, rw mem_sdiff at h, exact ⟨h.2.1,h.2.2,h.1⟩,
end

lemma card_sdiff_insert {v : α} {A B :finset α} (hB: B⊆A) (hvB: v ∉ B) (hvA: v ∈ A) : (A\(B ∪ {v})).card=(A\B).card -1:= 
begin
  have : v∈A\B:=mem_sdiff.mpr ⟨hvA,hvB⟩,
  rw sdiff_insert hB hvB, exact card_erase_of_mem this,
end

-- how have the sizes of the complements of parts changed by moving v
lemma move_Pcard_sdiff {M : multi_part α} {v : α} {i j k: ℕ} (hvi: i∈ range(M.t+1) ∧ v∈ M.P i) (hj : j∈range(M.t+1) ∧ j≠i) :
 k∈ range(M.t+1) → (((move M hvi hj).A)\((move M hvi hj).P k)).card = ite (k≠i ∧k≠j) ((M.A)\(M.P k)).card (ite (k=i) (((M.A)\(M.P i)).card +1) (((M.A)\(M.P j)).card-1)):=
begin
  intros hk,rw move_P hvi hj hk,rw move_A hvi hj,split_ifs, refl,
  exact card_sdiff_erase (sub_part  hvi.1) hvi.2,
  exact card_sdiff_insert (sub_part  hj.1) (uniq_part' hvi.1 hj.1 hj.2.symm hvi.2) (mem_part hvi.1 hvi.2),
end
lemma move_change {a b n:ℕ} (hb: b+1<a) (hn: a+b ≤ n):  a*(n-a) +b*(n-b) < (a-1)*(n-a+1)+ (b+1)*(n-b-1):=
begin
  rw mul_add, rw add_mul,rw mul_one, rw one_mul,
  have ha:=tsub_add_cancel_of_le (by linarith [hb]: 1 ≤ a),
  have h2: a ≤ n-b:=le_tsub_of_add_le_right hn,
  have hnb:=tsub_add_cancel_of_le  (le_trans (by linarith [hb]: 1 ≤ a) h2),
  nth_rewrite 0 ← ha, nth_rewrite 0 ← hnb,
  rw [add_mul,mul_add,one_mul,mul_one ,add_assoc,add_assoc],
  apply (add_lt_add_iff_left _).mpr, rw [add_comm, ← add_assoc, add_comm (a-1), add_assoc, add_assoc],
  apply (add_lt_add_iff_left _).mpr, 
  have ab: b< a-1,{by linarith [hb],},
  have nba: (n-a)< (n-b-1),{
    have nba': (n-a)<(n-(b+1)),{
      have h3:=tsub_pos_of_lt hb,
      have h4: a ≤ n :=by linarith,
      have h6:=tsub_add_tsub_cancel (h4) (le_of_lt hb),
        linarith,}, rw add_comm at nba',
      rwa tsub_add_eq_tsub_tsub_swap at nba',},
  exact add_lt_add ab nba,
  --- why are these needed?
  exact covariant_add_lt_of_contravariant_add_le ℕ,
  exact contravariant_add_lt_of_covariant_add_le ℕ,
  exact covariant_add_lt_of_contravariant_add_le ℕ,
  exact contravariant_add_lt_of_covariant_add_le ℕ,
end

variables{M : multi_part α}
include M
instance mp_decidable_rel : decidable_rel (mp M).adj :=
λ x y, finset.decidable_dexists_finset


instance neighbor_mp_set.mem_decidable (v : α):
  decidable_pred (∈ (mp M).neighbor_set v) := 
begin
  unfold neighbor_set, apply_instance,
end

instance multi_partite_fintype  : fintype (mp M).edge_set := 
begin
  unfold edge_set, apply_instance, 
end

lemma no_nbhrs {M: multi_part α} {v w: α} (hA: v∉M.A) : ¬(mp M).adj v w:=
begin
  contrapose! hA, 
  obtain ⟨i,hi,j,hj,a,b,c⟩:=hA, exact (sub_part hi) b, 
  exact (sub_part hj) hA_h_h_h_h_right.1,
end

lemma nbhrs_imp {M: multi_part α} {v w: α} : (mp M).adj v w → v ∈ M.A:=
begin
  intros h1, by_contra, exact no_nbhrs h h1,
end


lemma mp_nbhd_compl (M : multi_part α) {v : α} (hA: v∉M.A) : (mp M).degree v = 0:= 
begin
  rw degree, rw finset.card_eq_zero,
  rw eq_empty_iff_forall_not_mem, intros x hx,rw mem_neighbor_finset at hx, exact no_nbhrs hA hx,
end

lemma mp_adj_imp {M : multi_part α} {v w: α} {i j : ℕ} (hi: i∈ range(M.t+1))(hj: j∈ range(M.t+1))(hvi: v∈M.P i) (hwj: w∈M.P j): (mp M).adj v w → i≠j:=
begin
  intros h,cases h with a ha,
  obtain ⟨har,b,hbr,abne, ab⟩:=ha, cases ab, 
  have ai:=uniq_part hi har hvi ab.1,have bj:=uniq_part hj hbr hwj ab.2,
  rwa [← ai,← bj] at abne,
  have aj:=uniq_part hj har hwj ab.2, have bi:=uniq_part hi hbr hvi ab.1,
  rw [← aj,← bi] at abne,
  exact abne.symm,
end

lemma mp_adj_imp' {M : multi_part α} {v w: α} {i : ℕ}(hi: i∈ range(M.t+1))(hvi: v∈M.P i) :(mp M).adj v w → ∃j ∈ range(M.t+1), w∈ M.P j ∧ i≠j:=
begin
  intros h,
  obtain ⟨j,hj,k,hk,ne,h1⟩:= h, cases h1, have :=uniq_part hi hj hvi h1.1, rw ← this at ne,
  use [k,hk,⟨h1.2,ne⟩],
  have :=uniq_part hi hk hvi h1.1, rw ← this at ne,
  use [j,hj,⟨h1.2,ne.symm⟩],
end


lemma mp_imp_adj {M : multi_part α} {v w: α} {i j : ℕ}(hi: i∈ range(M.t+1))(hj: j∈ range(M.t+1))(hvi: v∈M.P i) (hwj: w∈M.P j): i≠ j → (mp M).adj v w :=
begin
  intros h, refine ⟨i,hi,j,hj,h,_⟩,left ,exact ⟨hvi,hwj⟩,
end


lemma mp_adj_iff {M : multi_part α} {v w: α} {i j : ℕ}(hi: i∈ range(M.t+1))(hj: j∈ range(M.t+1))(hvi: v∈M.P i) (hwj: w∈M.P j): 
(mp M).adj v w ↔  i≠j := ⟨mp_adj_imp hi hj hvi hwj, mp_imp_adj hi hj hvi hwj⟩



lemma not_nhbr_same_part {M : multi_part α} {v w: α} {i : ℕ} (hi : i∈ range(M.t+1)) (hv: v∈ M.P i) : (mp M).adj v w → w ∉ M.P i:=
begin
  intros h1, by_contra, apply mp_adj_imp hi hi hv h h1,refl, 
end

lemma nbhr_diff_parts {M : multi_part α} {v w: α} {i : ℕ} (hi : i∈ range(M.t+1)) (hv: v∈ M.P i) (hw : w∈ M.A\M.P i) : (mp M).adj v w:=
begin
  rw mem_sdiff at hw,
  cases hw with hA hni,
  rw M.uni at hA, rw mem_bUnion at hA,
  obtain ⟨j,hj1,hj2⟩:=hA,
  refine mp_imp_adj hi hj1 hv hj2 _, by_contra, rw h at hni, exact hni hj2,
end

lemma mp_nbhd {M : multi_part α} {v:α} {i: ℕ} (hv: i∈ range(M.t+1) ∧ v ∈ M.P i) : (mp M).neighbor_finset v = (M.A)\(M.P i) :=
begin
  ext,split,rw mem_neighbor_finset,intro h, rw adj_comm at h,
  rw mem_sdiff, refine  ⟨nbhrs_imp h,_⟩, exact not_nhbr_same_part hv.1 hv.2 h.symm,
  rw mem_neighbor_finset, exact nbhr_diff_parts hv.1 hv.2,
end
   

lemma mp_deg {M : multi_part α} {v : α} {i: ℕ} (hv: i∈ range(M.t+1) ∧ v∈ M.P i) : (mp M).degree v = ((M.A)\(M.P i)).card:= 
begin
  rw degree,rwa mp_nbhd hv,
end

lemma mp_deg_diff {M : multi_part α} {v : α} {i: ℕ} (hv: i∈ range(M.t+1) ∧ v∈ M.P i) : (mp M).degree v = M.A.card -  (M.P i).card:= 
begin
  rw mp_deg hv, exact card_sdiff (sub_part hv.1),
end

lemma mp_deg_sum (M : multi_part α) : ∑ v in M.A, (mp M).degree v = ∑i in range(M.t+1),(M.P i).card * ((M.A)\(M.P i)).card :=
begin
  nth_rewrite 0 M.uni,
  rw sum_bUnion (pair_disjoint M), apply finset.sum_congr rfl _,
  intros x hx, rw [finset.card_eq_sum_ones, sum_mul, one_mul], apply finset.sum_congr rfl _,
  intros v hv, exact mp_deg ⟨hx,hv⟩,
end

lemma mp_deg_sum_sq' {M : multi_part α} : ∑ v in M.A, (mp M).degree v + ∑i in range(M.t+1), (M.P i).card^2 = M.A.card^2:=
begin
  rw mp_deg_sum M, rw pow_two, nth_rewrite 0 card_uni, rw ← sum_add_distrib, rw sum_mul, 
  refine finset.sum_congr rfl _,
  intros x hx,rw pow_two,rw ← mul_add, rw card_part_uni hx,
end



lemma mp_deg_sum_sq (M : multi_part α) : ∑ v in M.A, (mp M).degree v = M.A.card^2 - ∑i in range(M.t+1), (M.P i).card^2
:=eq_tsub_of_add_eq mp_deg_sum_sq'




 
lemma mp_deg_sum_move_help{M : multi_part α} {v : α} {i j: ℕ}  (hvi: i∈ range(M.t+1) ∧ v ∈ M.P i) (hj : j∈range(M.t+1) ∧ j≠i) (hc: (M.P j).card+1<(M.P i).card ) : 
(M.P i).card * ((M.A)\(M.P i)).card + (M.P j).card * ((M.A)\(M.P j)).card <((move M hvi hj).P i).card * (((move M hvi hj).A)\((move M hvi hj).P i)).card + ((move M hvi hj).P j).card * (((move M hvi hj).A)\((move M hvi hj).P j)).card:=
begin
  rw move_Pcard hvi hj hvi.1, rw move_Pcard hvi hj hj.1,rw move_Pcard_sdiff hvi hj hvi.1, rw move_Pcard_sdiff hvi hj hj.1,
  split_ifs,exfalso, exact h.1 rfl,exfalso, exact h.1 rfl,exfalso, exact h.1 rfl,exfalso, exact h_1.2 rfl,exfalso, exact hj.2 h_2,
  rw card_sdiff (sub_part hvi.1), rw card_sdiff (sub_part hj.1),
  exact move_change hc (two_parts hvi.1  hj.1 hj.2.symm),
end

end simple_graph

/-
lemma mp_deg_sum_move_change {M : multi_part α} {v : α} {i j: ℕ}  (hvi: i∈ range(M.t+1) ∧ v ∈ M.P i) (hj : j∈range(M.t+1) ∧ j≠i) (hc: (M.P j).card+1<(M.P i).card ) : 
∑ w in (move M hvi hj).A,  (mp (move M hvi hj)).degree w < ∑ w in M.A,  (mp M).degree w:=
begin
  rw mp_deg_sum M,rw mp_deg_sum (move M hvi hj), 
  rw (move_A hvi hj), rw (move_t hvi hj), 

  refine sum_lt_sum _ _, intros k hk, rw move_Pcard hvi hj, split_ifs,
  --- actually need CS or something similar here because terms aren't
sorry,
end

-/


--
--lemma mp_deg_sum {M : multi_part α} : 
--∑ v in (univ:finset α), (mp M).degree v  =  M.A.card^2 - ∑ i in range(M.t + 1),(M.P i).card^2:=
--begin
--  sorry, 
  --rw M.uni, unfold degree,
--end
-- extend a t+1 partite-graph on A to (t+2)-partite on A ∪ B with disjoint A B.







