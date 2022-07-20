import data.finset.basic
import data.list.basic
import data.nat.basic
import tactic.core
import algebra.big_operators
open finset nat

open_locale big_operators 
-- basic structure for a complete (t+1)-partite graph on α
-- not actually a partition in the sense of mathlib since that would
-- require at most one empty part, while I'm happy to allow any number of
-- empty parts 
namespace mpartition
variables {α : Type*}[fintype α][inhabited α][decidable_eq α]
@[ext] 
structure multi_part (α : Type*)[decidable_eq α][fintype α][inhabited α][decidable_eq α]:=
(t :ℕ) (P: ℕ → finset α) (A :finset α) 
(uni: A = (range(t+1)).bUnion (λi , P i))
(disj: ∀i∈ range(t+1),∀j∈ range(t+1), i≠j → disjoint (P i) (P j)) 

-- define notion of a vertex than can be moved to increase number of edges in M
def moveable (M : multi_part α)  :Prop := ∃ i∈ range(M.t+1),∃ j ∈ range(M.t+1), (M.P j).card +1 < (M.P i).card

def immoveable (M : multi_part α) :Prop :=∀i∈ range(M.t+1),∀j∈ range(M.t+1), (M.P i).card ≤ (M.P j).card +1

lemma immoveable_iff_not_moveable (M : multi_part α) :immoveable M ↔ ¬moveable M:=
begin
  unfold immoveable, unfold moveable,push_neg, refl,
end

-- balanced partition has almost equal parts
def balanced (t : ℕ) (P : ℕ → ℕ): Prop:= ∀ i ∈ range(t+1),∀ j∈ range(t+1), P i ≤ (P j) + 1


-- smallest part is well-defined
def min_bal {t : ℕ} {P : ℕ → ℕ} (h: balanced t P): ℕ:= begin
  have nem: ((range(t+1)).image(λi , P i)).nonempty :=(nonempty.image_iff  _).mpr (nonempty_range_succ),
  exact min' ((range(t+1)).image(λi , P i)) nem,
end

-- large parts and small parts
def large_parts {t : ℕ} {P:ℕ → ℕ} (h: balanced t P) : finset ℕ:=(range(t+1)).filter (λi, P i = min_bal h +1 )

def small_parts {t : ℕ} {P:ℕ → ℕ} (h: balanced t P) : finset ℕ:=(range(t+1)).filter (λi, P i = min_bal h)

-- in a balanced partition all parts are small or large
lemma con_sum {t :ℕ} {P :ℕ → ℕ} (h: balanced t P): ∀i∈ range(t+1), P i = min_bal h ∨ P i = min_bal h +1:=
begin
  unfold balanced at h,
  have nem: ((range(t+1)).image(λi , P i)).nonempty :=(nonempty.image_iff  _).mpr (nonempty_range_succ),
  set a:ℕ:=min' ((range(t+1)).image(λi , P i)) nem with ha,
  set b:ℕ:=max' ((range(t+1)).image(λi , P i)) nem with hb,
  intros i hi,
  have ale: a ≤ P i:= min'_le ((range(t+1)).image(λi , P i)) (P i) (mem_image_of_mem (P ) hi),
  have leb:P i ≤ b:= le_max' ((range(t+1)).image(λi , P i)) (P i) (mem_image_of_mem (P ) hi),
  have ain:= min'_mem ((range(t+1)).image(λi , P i)) nem, rw ← ha at ain,
  have bin:= max'_mem ((range(t+1)).image(λi , P i)) nem, rw ← hb at bin,
  have blea: b≤ a+1,{
    rw mem_image at *,
    obtain ⟨k,hk,hak⟩:=ain,
    obtain ⟨l,hl,hbl⟩:=bin,
    rw [← hak,←hbl],
    exact h l hl k hk,
  },
  have ple :=le_trans leb blea,
  by_contra, push_neg at h, cases h,have h1:=lt_of_le_of_ne ale h_left.symm,
  have h2:=lt_of_le_of_ne ple h_right,
  linarith,
end

lemma large_parts' {t : ℕ} {P:ℕ → ℕ} (h: balanced t P): large_parts h = (range(t+1)).filter (λi, ¬ P i = min_bal h):=
begin
  have :=con_sum h, unfold large_parts, ext,rw [mem_filter,mem_filter],split,
  intro h', refine ⟨h'.1,_⟩, intros h2, rw h2 at h', exact succ_ne_self (min_bal h) h'.2.symm,
  intros h', refine ⟨h'.1,_⟩, specialize this a h'.1,  cases this, exfalso, exact h'.2 this, exact this,
end

lemma parts_disjoint {t : ℕ}  {P :ℕ → ℕ} (h: balanced t P) : disjoint (small_parts h) (large_parts h):=
begin
  convert disjoint_filter_filter_neg (range(t+1)) (λi, P i = min_bal h),
  exact large_parts' h,
end

lemma parts_union {t : ℕ}  {P :ℕ → ℕ} (h: balanced t P) : (range(t+1)) = (small_parts h) ∪ (large_parts h):=
begin
  have :=con_sum h,
  ext,unfold small_parts, unfold large_parts, rw mem_union, split,   intro ha,
  rw [mem_filter,mem_filter],specialize this a ha, cases this, left ,exact ⟨ha,this⟩,right,exact ⟨ha,this⟩,
  rw [mem_filter,mem_filter],intros h, cases h, exact h_1.1, exact h_1.1,
end


def sum_P (t : ℕ) (P : ℕ → ℕ): ℕ:= ∑i in range(t+1), P i

def sum_sq (t : ℕ) (P: ℕ → ℕ): ℕ := ∑i in range(t+1),(P i)^2



-- sum of parts is (t+1)* smallest + number of large parts
-- need to prove all balanced partitions have same degree sum
--- then if either this is the max or there is a moveable partition that is better but then can
--- move that until can't be moved and get a better immovable partition, a contradition
--- 

instance (α :Type*)[decidable_eq α][fintype α][inhabited α][decidable_eq α] : inhabited (multi_part α):=
{default:={ t:=0, P:= λ i , ∅, A:=∅, uni:=rfl, 
disj:=λ i hi j hj ne, disjoint_empty_left ∅,
 }}

-- default mpartition of B into s+1 parts 1 x B and s x ∅
def default_mp (B:finset α) (s:ℕ)  : multi_part α:={
t:=s, 
P:= begin intro i, exact ite (i=0) (B) (∅), end, 
A:=B,
uni:= begin 
ext, split,intro ha,rw mem_bUnion,use 0, rw mem_range, exact ⟨zero_lt_succ s,ha⟩, 
rw mem_bUnion,intro h, cases h with i h2,cases h2,split_ifs at h2_h,exact h2_h,exfalso, exact h2_h,
end,
disj:= begin 
  intros i hi j hj ne,split_ifs,exfalso,rw h at ne,rw h_1 at ne, exact ne rfl, 
  exact disjoint_empty_right _,exact disjoint_empty_left _,exact disjoint_empty_left _,end,
}





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

lemma insert_AB (M: multi_part α) {B :finset α} (h: disjoint M.A B):(insert M h).A = B ∪ M.A:=rfl

-- there is always a (t+1)-partition of B
lemma exists_mpartition (B: finset α) (s:ℕ): ∃ M:multi_part α, M.A=B ∧ M.t=s:=
begin
  use default_mp B s, exact ⟨rfl,rfl⟩,
end


---M.disj is the same as pairwise_disjoint but without any coercion to set for range(t+1) 
lemma pair_disjoint (M : multi_part α) : ((range(M.t+1):set ℕ)).pairwise_disjoint M.P:=M.disj

-- size of A is sum of size of part
lemma card_uni  (M : multi_part α) : M.A.card = ∑i in range(M.t+1),(M.P i).card:= begin
  rw [M.uni, finset.card_eq_sum_ones, sum_bUnion (pair_disjoint M)],
  apply finset.sum_congr rfl _, intros x hx, rwa ← finset.card_eq_sum_ones,
end



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
end mpartition