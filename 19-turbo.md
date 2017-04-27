---
layout: page
title: Second steps in LHCb
subtitle: Turbo Stream
minutes: 30
---

> ## Learning Objectives {.objectives}
>
> * Learn about persited reconstruction
> * Learn how to make new candidates from turbo candidate and other persisted objects
> * Learn how to make an NTuple from these new candidates.

 * Online-offline reco the same
 * Online reconstructed candidates stored in raw event
 * Tesla pulls them out puts them back in the memory

| The file used in the [lesson about the HLT ](18-hlt-intro.html) can also be used for this lesson:
| `root://eoslhcb.cern.ch//eos/lhcb/user/r/raaij/Impactkit/00051318_00000509_1.turbo.mdst`.

Python file that defines the data:

~~~ {.python}
# data.py
from GaudiConf import IOHelper
prefix = 'root://eoslhcb.cern.ch/'
fname = '/eos/lhcb/user/r/raaij/Impactkit/00051318_00000509_1.turbo.mdst'
IOHelper('ROOT').inputFiles([prefix + fname], clear=True)
~~~

Basic script for making a turbo NTuple `turbo_intro.py`

~~~ {.python}
# DaVinci configuration
from Configurables import DaVinci
DaVinci().DataType = '2016'
DaVinci().EvtMax = 1000
DaVinci().TupleFile = turbo.root'

# Turbo locations:
turbo_loc = '/Event/Turbo/{0}/Particles'
dz_line = 'Hlt2CharmHadD02KmPipTurbo'

# Make a DecayTreeTuple
from Configurables import DecayTreeTuple
from DecayTreeTuple import Configuration

dtt = DecayTreeTuple('TupleD0ToKpi')
dtt.Inputs = [turbo_loc.format(dz_line)]
dtt.Decay = '[D0 -> K- pi+]CC'
dtt.addBranches({
    'D0': '[D0 -> K- pi+]CC'
})

DaVinci().UserAlgorithms = [dtt]
~~~

Then we run it!

```shell
lb-run DaVinci gaudirun.py turbo_intro.py data.py
```
