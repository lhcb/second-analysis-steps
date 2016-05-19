---
layout: page
title: Second steps in LHCb
subtitle: Persisted Reconstruction
minutes: 45
---

> ## Learning Objectives {.objectives}
>
> * Learn about persited reconstruction
> * Learn how to make new candidates from turbo candidate and other persisted objects
> * Learn how to make an NTuple from these new candidates.

Now we want to use the PersistReco to make something more from the candidates,
in this case a D* -> (D0 -> K pi) pi.

Create a new script, `turbo_persistreco.py`, based on `turbo_intro.py` from the
[lesson about turbo ](19-turbo.html) to contain your configuration.

There are some general options needed to configure DaVinci to recreate the
particles created in the HLT.

~~~ {.python}
# Turbo with PersistReco
from Configurables import DstConf, TurboConf
DstConf().Turbo = True
TurboConf().PersistReco = True
~~~

Then we need to get the particles that we want to create the D* from and combine
them.

> ## Persisted Particles {.challenge}
>
> Use a GaudiPython script inspired by
> [another lesson](http://lhcb.github.io/first-analysis-steps/05-interactive-dst.html)
> to find out which particles are persisted from the
> online reconstruction by exploring the transient event store.

~~~ {.python}
# Get the D0 and the pions
from PhysSelPython.Wrappers import DataOnDemand, Selection, SelectionSequence
dz = DataOnDemand(turbo_loc.format(dz_line))
pions = DataOnDemand('Phys/StdAllNoPIDsPions/Particles')

# Combine them
from GaudiConfUtils.ConfigurableGenerators import CombineParticles
dst = CombineParticles(
    DecayDescriptors = ['[D*(2010)+ -> D0 pi+]cc'],
    CombinationCut = "(ADAMASS('D*(2010)+') < 80 * MeV)",
    MotherCut = "VFASPF(VCHI2/VDOF) < 6 & ADMASS('D*(2010)+') < 60 * MeV"
    )
~~~

To run our combination, we create a selection and a selection sequence.

~~~ {.python}
dst_sel = Selection(
    'Sel_DstToD0pi',
    Algorithm = dst,
    RequiredSelections = [dz, pions]
    )

dst_selseq = SelectionSequence(
    'SelSeq_DstToD0pi',
    TopSelection = dst_sel
    )
~~~

Finally, we create the `DecayTreeTuple` for the D* and use the output of our selection
sequence as its input.

~~~ {.python}
# D* in the tuple
dtt_dst = DecayTreeTuple('TupleDstToD0pi_D0ToKpi_PersistReco')
dtt_dst.Inputs = dst_selseq.outputLocations()
dtt_dst.Decay = '[D*(2010)+ -> ^(D0 -> ^K- ^pi+) ^pi+]CC'
dtt_dst.addBranches({
    'Dst': '[D*(2010)+ -> (D0 -> K- pi+) pi+]CC',
    'Dst_pi': '[D*(2010)+ -> (D0 -> K- pi+) ^pi+]CC',
    'D0': '[D*(2010)+ -> ^(D0 -> K- pi+) pi+]CC',
    'D0_K': '[D*(2010)+ -> (D0 -> ^K- pi+) pi+]CC',
    'D0_pi': '[D*(2010)+ -> (D0 -> K- ^pi+) pi+]CC',
})

DaVinci().UserAlgorithms = [dst_selseq.sequence(), dtt_dst]
~~~

Then we run it!

```shell
lb-run DaVinci gaudirun.py turbo_persistreco.py data.py
```
