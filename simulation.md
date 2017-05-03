---
layout: page
title: Second analysis steps
subtitle: Generating signal decays
minutes: 60
---

> ## Learning Objectives {.objectives}
>
> * Understand how a signal decay sample is produced in the LHCb framework
> * Produce generator level Monte Carlo, print the decay tree and produce nTuples
> * Read a DecFile and understand what it produces, including generator level cuts
# What is Gauss?
# Figuring out which option files to use and running it

Imagine you need to know the option files and software versions used for a simulated sample you have found in the bookkeeping, e.g.
```
/MC/2015/Beam2510GeV-2015-MagDown-Nu1.5-25ns-Pythia8/Sim09b/Trig0x4115014e/Reco15a/Turbo01aEM/Stripping22NoPrescalingFlagged/27163003/ALLSTREAMS.DST
```

# Setting up a new Decay

EvtGen is completely controlled via a specific file for each sample, known as a DecFile. These live in the DecFiles package:
https://gitlab.cern.ch/LHCb-SVN-mirrors/Gen-DecFiles/tree/master/dkfiles
To understand what is produced in any simulated sample, you need to understand these. First, how to try them out.

The procedure for testing and committing decfiles is well documented:
https://twiki.cern.ch/twiki/bin/view/LHCb/GaussDecayFiles
The TWiki page still uses the old `SetupProject` approach. Instead, we will adapt this to use the new `lb-run` and `lb-dev` approach. First we need to create a Gauss developement environment:
```shell
lb-dev --name GaussDev_ImpactKit Gauss/v49r7
cd GaussDev_ImpactKit
```
To modify or add a dec file, we need the DecFiles package which is still on svn:
```shell
getpack Gen/DecFiles head
make
```
This will populate the `./Gen/DecFiles/Options` directory with an python options file to generate events for each decfile, `(eventtype).py`. The location where the dec files are located is stored in `$DECFILESROOT` and we can check that the correct on is used by running
```shell
./run $SHELL -c 'echo $DECFILESROOT'
```
which should point `Gen/DecFiles` directory in the current development environment.

>Note that recompiling will not overwrite existing options file, it is necessary to remove by hand all of the python files in `./Gen/DecFiles/Options`.
After this, to produce some generator level events:
```shell
./run gaudirun.py '$GAUSSOPTS/Gauss-Job.py' '$GAUSSOPTS/Gauss-2016.py' '$GAUSSOPTS/GenStandAlone.py' '$DECFILESROOT/options/11164001.py' '$LBPYTHIA8ROOT/options/Pythia8.py'
```
where `$GAUSSOPTS/Gauss-Job.py'` configures Gauss to produce 5 events and `'$GAUSSOPTS/Gauss-2016.py'` sets up the nominal 2016 conditions and loads additional options files to do so.

This will output a .xgen file containing simulated events, as well as a root file containing various monitoring histograms you will probably never want to look at.  
To change the number of events generated make a local copy of Gauss-Job.py.
Note that the number of events produced is *after generator level cuts* - this is also true for production requests.

The .xgen file can be processed into something more usable with DaVinci:
```python
"""Configure the variables below with:
decay: Decay you want to inspect, using 'newer' LoKi decay descriptor syntax,
decay_heads: Particles you'd like to see the decay tree of,
datafile: Where the file created by the Gauss generation phase is, and
year: What year the MC is simulating.
"""
# https://twiki.cern.ch/twiki/bin/view/LHCb/FAQ/LoKiNewDecayFinders
decay = "[ [B0]cc => ^(D- => ^K+ ^pi- ^pi-) ^pi+]CC"
decay_heads = ["B0", "B~0"]
datafile = "Gauss-11164001-5ev-20170504.xgen"# N.B output filename includes today's date - change this!
year = 2012



from Configurables import (
    DaVinci,
    EventSelector,
    PrintMCTree,
    MCDecayTreeTuple
)
from DecayTreeTuple.Configuration import *


# For a quick and dirty check, you don't need to edit anything below here.
##########################################################################

# Create an MC DTT containing any candidates matching the decay descriptor
mctuple = MCDecayTreeTuple("MCDecayTreeTuple")
mctuple.Decay = decay
mctuple.ToolList = [
    "MCTupleToolHierarchy",
    "LoKi::Hybrid::MCTupleTool/LoKi_Photos"
]
# Add a 'number of photons' branch
mctuple.addTupleTool("MCTupleToolKinematic").Verbose = True
mctuple.addTupleTool("LoKi::Hybrid::TupleTool/LoKi_Photos").Variables = {
    "nPhotos": "MCNINTREE(('gamma' == MCABSID))"
}

# Print the decay tree for any particle in decay_heads
printMC = PrintMCTree()
printMC.ParticleNames = decay_heads

# Name of the .xgen file produced by Gauss
EventSelector().Input = ["DATAFILE='{0}' TYP='POOL_ROOTTREE' Opt='READ'".format(datafile)]

# Configure DaVinci
DaVinci().TupleFile = "DVntuple.root"
DaVinci().Simulation = True
DaVinci().Lumi = False
DaVinci().DataType = str(year)
DaVinci().UserAlgorithms = [printMC, mctuple]
```
```shell
lb-run DaVinci/v41r0 gaudirun.py DaVinciOptions.py
```
This script will attempt to build an nTuple from the xgen file it is given, using the specified decay descriptor. If everything is working correctly, this should return one entry per event, corresponding to your signal candidate. The PrintMCTree algorithm will print to screen the full decay chain for each particle in "decay_heads" e.g:
```
<--------------------------------- MCParticle --------------------------------->
                Name         E         M         P        Pt       phi        Vz
                           MeV       MeV       MeV       MeV      mrad        mm
B~0                 228676.20   5279.58 228615.24   4575.10   3122.65    -18.05
+-->D-              220232.04   1869.61 220224.11   4909.35  -2995.39     96.91
|+-->K+             150522.77    493.68 150521.97   3531.59   3092.01    120.50
|+-->pi-             12700.02    139.57  12699.26    351.94  -2113.03    120.50
|+-->pi-             57009.20    139.57  57009.03   1290.27  -2667.72    120.50
|+-->gamma               0.05      0.00      0.05      0.00      0.00    120.50
+-->pi+               8444.15    139.57   8443.00    850.25   1231.87     96.91
```
, which is extremely helpful for knowing if your decfile is producing what you think it should. Note that in addition to your signal B0, it will also print out the decay chain for any B0 in the event, so you will regularly see other random B decays.

####introduction to generator level cuts
The generator cut efficiency can be found from the GeneratorLog.xml file, which contains e.g:
<efficiency name = "generator level cut">
    <after> 5 </after>
    <before> 27 </before>
    <value> 0.18519 </value>
    <error> 0.074757 </error>
</efficiency>


```
actual decfile
```
The information in the header is not just bookkeeping, almost all of it is parsed and changes what you get out at the end. The EventType is a series of flags which controls the generation. The rules for this are described in detail at:
https://cds.cern.ch/record/855452/files/lhcb-2005-034.pdf
For example for the first digit of 1 = contains b quark, 2 = c quark, 3 = min bias...
Similarly, the document specifies the conventions for the "NickName" - which also has to be the filename.

The "Cuts" field specifies one of a set of C++ selections in:
https://gitlab.cern.ch/lhcb/Gauss/blob/master/Gen/GenCuts/
The most common example is "DaugthersInAcceptance", aka "DecProdCut" in the NickName. This requires that each "stable charged particle" is in a loose region around the LHCb acceptance (10-400 mrad in Theta). 

###python style cuts

###CPUtime

###changing particle properties


> ## Work to do {.challenge}
>  - Finish the script (the base of which can be found [here](code/06-building-decays/build_decays.py)) by adapting the basic `DaVinci` configuration from its corresponding [lesson](http://lhcb.github.io/first-analysis-steps/08-minimal-dv-job.html) and check the output ntuple.
>  - Replace the `"Combine_D0"` and `"Sel_D0"` objects by a single `SimpleSelection`.
>  - Do you know what the used LoKi functors (`AMAXDOCA`, `ADAMASS`, `MIPCHI2DV`, etc) do? 
>  - Add a `PrintSelection` in your selections and run again.
>  - Create a `graph` of the selection.

