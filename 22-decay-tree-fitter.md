---
layout: page
title: HowTo DecayTreeFitter
subtitle: DecayTreeFitter via LoKi functors 
minutes: 10
---

> ## Learning Objectives {.objectives}
>
> * Add a kinematic fitter to a branch in the decay tree
> * Apply a mass constraint

Let us consider the ```B0 -> J/psi(1S) K*(892)0``` decay, with ```J/psi(1S) -> e+ e-``` and ```K*(892)0 -> K+ pi-```.

We can make the assumption that the `B0` originates from the primary vertex (vertex constraint) and that the `e+` and `e-` combine to form a `J/psi(1S)` with a specific invariant mass (mass constraint). We then want to add the corresponding new best estimates of some physical variables to our ntuple, in order to be able to use it in the subsequent analysis.

First of all, we need to specify the corresponding decay descriptor and branches:

```
myDecay = '[[B0]cc -> ^(J/psi(1S) -> ^e+ ^e-) ^(K*(892)0 -> ^K+ ^pi-)]CC'
myBranches = {
"K"      : "[ [B0]cc -> (J/psi(1S) -> e+ e-) (K*(892)0 -> ^K+ pi-)]CC",
"Pi"     : "[ [B0]cc -> (J/psi(1S) -> e+ e-) (K*(892)0 -> K+ ^pi-)]CC",
"Lplus"  : "[ [B0]cc -> (J/psi(1S) -> ^e+ e-) (K*(892)0 -> K+ pi-)]CC",
"Lminus" : "[ [B0]cc -> (J/psi(1S) -> e+ ^e-) (K*(892)0 -> K+ pi-)]CC",
"Jpsi"   : "[ [B0]cc -> ^(J/psi(1S) -> e+ e-) (K*(892)0 -> K+ pi-)]CC",
"Kstar"  : "[ [B0]cc -> (J/psi(1S) -> e+ e-) ^(K*(892)0 -> K+ pi-)]CC",
"B"      : "[[B0]cc -> (J/psi(1S) -> e+ e-) (K*(892)0 -> K+ pi-)]CC"
}
```

As seen in the [first-analysis-steps](https://lhcb.github.io/first-analysis-steps/), mass constraints and kinematic fitters can be applied to the decay by using the TupleToolDecayTreeFitter. In this case, some standard information concerning the mother particle and the daughters is added to the desired branch in the decay tree. However, if the daughters are not stable particles and decay further, the daughters of the daughters have no new variables associated to them. In some cases it might be useful to make this information available too. This can done by using the `DecayTreeFitter` via `LoKi functors`, as explained below.

First of all, an instance of the `LoKi::Hybrid::TupleTool` must be created, here called `LoKi_DTF`.

```
LoKi_DTF = LoKi__Hybrid__TupleTool('LoKi_DTF')
```

At this point, the desired variables can be specified in the form of a dictionary. The keys correspond to the names of the new branches that will be added to the ntuple, while the values correspond to the physical variables identified by the keys. Each value has the following syntax:

```
"DTF_FUN(var,bool,particle)"
```

with
* `var` describing the physical variable, according to the same rules that apply to `LoKi functors`;
* `bool` being `True` or `False`, depending on whether the particle must be constrained to originate from the PV;
* `particle` describing the mass constraint.

The `CHILD` `LoKi functor` can be used to access the information of the daughters and of the daughters of the daughters. The numbering scheme starts from 1 and corresponds to what specified in the decay descriptor.
 
For example, in our case:

```
LoKi_DTF.Variables = {
# B variables
"DTF_B_M"        : "DTF_FUN(M,True,'J/psi(1S)')",
"DTF_B_PT"       : "DTF_FUN(PT,True,'J/psi(1S)')",
"DTF_B_THETA"    : "DTF_FUN(atan(PT/PZ),True,'J/psi(1S)')",
# Jpsi variables
"DTF_Jpsi_M"     : "DTF_FUN(CHILD(1,M),True,'J/psi(1S)')",
"DTF_Jpsi_PT"    : "DTF_FUN(CHILD(1,PT),True,'J/psi(1S)')",
"DTF_Jpsi_THETA" : "DTF_FUN(CHILD(1,atan(PT/PZ)),True,'J/psi(1S)')",
# Kstar variables
"DTF_Kstar_M"    : "DTF_FUN(CHILD(2,M),True,'J/psi(1S)')",
"DTF_Kstar_PT"   : "DTF_FUN(CHILD(2,PT),True,'J/psi(1S)')",
"DTF_Kstar_THETA": "DTF_FUN(CHILD(2,atan(PT/PZ)),True,'J/psi(1S)')",
# Lplus variables
"DTF_Lplus_M"     : "DTF_FUN(CHILD(1,CHILD(1,M)),True,'J/psi(1S)')",
"DTF_Lplus_PT"    : "DTF_FUN(CHILD(1,CHILD(1,PT)),True,'J/psi(1S)')",
"DTF_Lplus_THETA" : "DTF_FUN(CHILD(1,CHILD(1,atan(PT/PZ))),True,'J/psi(1S)')",
# Lminus variables
"DTF_Lminus_M"     : "DTF_FUN(CHILD(1,CHILD(2,M)),True,'J/psi(1S)')",
"DTF_Lminus_PT"    : "DTF_FUN(CHILD(1,CHILD(2,PT)),True,'J/psi(1S)')",
"DTF_Lminus_THETA" : "DTF_FUN(CHILD(1,CHILD(2,atan(PT/PZ))),True,'J/psi(1S)')",
# K variables
"DTF_K_M"     : "DTF_FUN(CHILD(2,CHILD(1,M)),True,'J/psi(1S)')",
"DTF_K_PT"    : "DTF_FUN(CHILD(2,CHILD(1,PT)),True,'J/psi(1S)')",
"DTF_K_THETA" : "DTF_FUN(CHILD(2,CHILD(1,atan(PT/PZ))),True,'J/psi(1S)')",
# Pi variables
"DTF_Pi_M"     : "DTF_FUN(CHILD(2,CHILD(2,M)),True,'J/psi(1S)')",
"DTF_Pi_PT"    : "DTF_FUN(CHILD(2,CHILD(2,PT)),True,'J/psi(1S)')",
"DTF_Pi_THETA" : "DTF_FUN(CHILD(2,CHILD(2,atan(PT/PZ))),True,'J/psi(1S)')",
}
```

where we asked to save the constrained mass, transverse momentum, and polar angle of all the particles involved in the decay.

After this, the `LoKi::Hybrid::TupleTool` must be added to one of the branches in our decay tree (generally the mother particle):

```
tuple.ToolList += ['LoKi::Hybrid::TupleTool/LoKi_DTF']
tuple.addTool(LoKi_DTF)
```

We can use a similar syntax to constrain the `e+` and `e-` to combine to form a `Psi(2S)` or another particle, if that makes sense for the analysis we are working at.