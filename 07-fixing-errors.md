---
layout: page
title: Second steps in LHCb
subtitle: What to do when something fails
minutes: 10
---

> ## Learning Objectives {.objectives}
>
> * Learn how to read the logs to know where things are breaking
> * Learn how to get a glimpse of where algorithms are writing in the TES

When chaining complex workflows (building particles, combining them, etc) we find that our ntuple is not written while we don't have any errors.
The first step is to look at the logs.
Let's first go back at what we learned [when building our own decays](https://lhcb.github.io/second-analysis-steps/01-building-decays.html) and rerun again (saving the output to a log file!).

We can scroll through the log until we find our selections, where we will see something like this:

```
Sel_D0            SUCCESS Number of counters : 13
 |    Counter                                      |     #     |    sum     | mean/eff^* | rms/err^*  |     min     |     max     |
 | "# D0 -> pi-  K+ "                              |      1000 |         43 |   0.043000 |    0.20286 |      0.0000 |      1.0000 |
 | "# D~0 -> pi+  K- "                             |      1000 |         55 |   0.055000 |    0.23233 |      0.0000 |      2.0000 |
 | "# K+"                                          |      1000 |       1161 |     1.1610 |     1.9155 |      0.0000 |      21.000 |
 | "# K-"                                          |      1000 |       1135 |     1.1350 |     2.1248 |      0.0000 |      29.000 |
 | "# Phys/StdAllLooseKaons"                       |      1000 |      24448 |     24.448 |     19.363 |      1.0000 |      136.00 |
 | "# Phys/StdAllNoPIDsPions"                      |      1000 |      42328 |     42.328 |     26.566 |      3.0000 |      181.00 |
 | "# input particles"                             |      1000 |      66776 |     66.776 |     45.704 |      4.0000 |      317.00 |
 | "# pi+"                                         |      1000 |       1962 |     1.9620 |     2.3436 |      0.0000 |      26.000 |
 | "# pi-"                                         |      1000 |       1912 |     1.9120 |     2.5401 |      0.0000 |      32.000 |
 | "# selected"                                    |      1000 |         98 |   0.098000 |    0.31368 |      0.0000 |      3.0000 |
 |*"#accept"                                       |      1000 |         94 |(  9.40000 +- 0.922843 )%|   -------   |   -------   |
 |*"#pass combcut"                                 |     10403 |        254 |(  2.44160 +- 0.151318 )%|   -------   |   -------   |
 |*"#pass mother cut"                              |       254 |         98 |(  38.5827 +- 3.05439  )%|   -------   |   -------   |
Sel_Dstar         SUCCESS Number of counters : 14
 |    Counter                                      |     #     |    sum     | mean/eff^* | rms/err^*  |     min     |     max     |
 | "# D*(2010)+ -> D0  pi+ "                       |        94 |          0 |     0.0000 |     0.0000 |      0.0000 |      0.0000 |
 | "# D*(2010)- -> D~0  pi- "                      |        94 |          1 |   0.010638 |    0.10259 |      0.0000 |      1.0000 |
 | "# D0"                                          |        94 |         43 |    0.45745 |    0.49819 |      0.0000 |      1.0000 |
 | "# D~0"                                         |        94 |         55 |    0.58511 |    0.51384 |      0.0000 |      2.0000 |
 | "# Phys/Sel_D0"                                 |        94 |         98 |     1.0426 |    0.24904 |      1.0000 |      3.0000 |
 | "# Phys/StdAllNoPIDsPions"                      |        94 |       4481 |     47.670 |     25.661 |      7.0000 |      153.00 |
 | "# input particles"                             |        94 |       4579 |     48.713 |     25.705 |      8.0000 |      154.00 |
 | "# pi+"                                         |        94 |       2175 |     23.138 |     11.977 |      4.0000 |      58.000 |
 | "# pi-"                                         |        94 |       2091 |     22.245 |     12.936 |      1.0000 |      90.000 |
 | "# selected"                                    |        94 |          1 |   0.010638 |    0.10259 |      0.0000 |      1.0000 |
 |*"#accept"                                       |        94 |          1 |(  1.06383 +- 1.05816  )%|   -------   |   -------   |
 |*"#pass combcut"                                 |      2240 |        586 |(  26.1607 +- 0.928634 )%|   -------   |   -------   |
 |*"#pass mother cut"                              |       586 |          1 |( 0.170648 +- 0.170503 )%|   -------   |   -------   |
 | "Error from IParticleCombiner, skip the combinat|         6 |          6 |     1.0000 |     0.0000 |      1.0000 |      1.0000 |
```

Here we have information of the input containers, types of particles, etc, with all the counters corresponding to our run on 1000 events.

> ## Understanding the log {.challenge}
> How many $D^*$ do we expect in our ntuple? Can you check it?
> Can you change some cuts and see how he counters change? Try to free the $D^*$ mass and see if we get more of those.

Now, let's make the particle builder fail silently and see if we can debug this.
For example, imagine we forgot to add the Kaons as inputs in `Sel_D0`:

```python
d0_sel = Selection('Sel_D0',
                   Algorithm=d0,
                   RequiredSelections=[Pions])
```

Then we get

```
Sel_D0            SUCCESS Number of counters : 12
 |    Counter                                      |     #     |    sum     | mean/eff^* | rms/err^*  |     min     |     max     |
 | "# D0 -> pi-  K+ "                              |      1000 |          0 |     0.0000 |     0.0000 |      0.0000 |      0.0000 |
 | "# D~0 -> pi+  K- "                             |      1000 |          0 |     0.0000 |     0.0000 |      0.0000 |      0.0000 |
 | "# K+"                                          |      1000 |          0 |     0.0000 |     0.0000 |      0.0000 |      0.0000 |
 | "# K-"                                          |      1000 |          0 |     0.0000 |     0.0000 |      0.0000 |      0.0000 |
 | "# Phys/StdAllNoPIDsPions"                      |      1000 |      42328 |     42.328 |     26.566 |      3.0000 |      181.00 |
 | "# input particles"                             |      1000 |      42328 |     42.328 |     26.566 |      3.0000 |      181.00 |
 | "# pi+"                                         |      1000 |       1962 |     1.9620 |     2.3436 |      0.0000 |      26.000 |
 | "# pi-"                                         |      1000 |       1912 |     1.9120 |     2.5401 |      0.0000 |      32.000 |
 | "# selected"                                    |      1000 |          0 |     0.0000 |     0.0000 |      0.0000 |      0.0000 |
 |*"#accept"                                       |      1000 |          0 |(  0.00000 +- 0.100000 )%|   -------   |   -------   |
 | "#pass combcut"                                 |         0 |          0 |     0.0000 |     0.0000 | 1.7977e+308 |-1.7977e+308 |
 | "#pass mother cut"                              |         0 |          0 |     0.0000 |     0.0000 | 1.7977e+308 |-1.7977e+308 |
```

It's easy to see we have 0 input kaons and we can see we only get input pions!

Another problem: we messed up with a cut, for example in building the $D^*$,

```python
dstar_mother = (
    "(abs(M-MAXTREE('D0'==ABSID,M)-145.42) < 10*MeV)"
    '& (VFASPF(VCHI2/VDOF) < 0)'
)
```

Running this, we get

```
Sel_Dstar         SUCCESS Number of counters : 14
 |    Counter                                      |     #     |    sum     | mean/eff^* | rms/err^*  |     min     |     max     |
 | "# D*(2010)+ -> D0  pi+ "                       |        94 |          0 |     0.0000 |     0.0000 |      0.0000 |      0.0000 |
 | "# D*(2010)- -> D~0  pi- "                      |        94 |          0 |     0.0000 |     0.0000 |      0.0000 |      0.0000 |
 | "# D0"                                          |        94 |         43 |    0.45745 |    0.49819 |      0.0000 |      1.0000 |
 | "# D~0"                                         |        94 |         55 |    0.58511 |    0.51384 |      0.0000 |      2.0000 |
 | "# Phys/Sel_D0"                                 |        94 |         98 |     1.0426 |    0.24904 |      1.0000 |      3.0000 |
 | "# Phys/StdAllNoPIDsPions"                      |        94 |       4481 |     47.670 |     25.661 |      7.0000 |      153.00 |
 | "# input particles"                             |        94 |       4579 |     48.713 |     25.705 |      8.0000 |      154.00 |
 | "# pi+"                                         |        94 |       2175 |     23.138 |     11.977 |      4.0000 |      58.000 |
 | "# pi-"                                         |        94 |       2091 |     22.245 |     12.936 |      1.0000 |      90.000 |
 | "# selected"                                    |        94 |          0 |     0.0000 |     0.0000 |      0.0000 |      0.0000 |
 |*"#accept"                                       |        94 |          0 |(  0.00000 +- 1.06383  )%|   -------   |   -------   |
 |*"#pass combcut"                                 |      2240 |        586 |(  26.1607 +- 0.928634 )%|   -------   |   -------   |
 |*"#pass mother cut"                              |       586 |          0 |(  0.00000 +- 0.170648 )%|   -------   |   -------   |
 | "Error from IParticleCombiner, skip the combinat|         6 |          6 |     1.0000 |     0.0000 |      1.0000 |      1.0000 |
```

And we would get suspicious about the `MotherCut`...
