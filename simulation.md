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
> * Filter a simulated sample to reduce disk space needed

# What is Gauss?

The LHCb simulation framework which steers the creation of simulated events and interfaces to multiple external applications. Most commonly, an event is created via the following procedure:

1. The `ProductionTool` (Pythia, GenXicc, ...) generates an event with the required signal particle. Either by generating minimum bias events until a matching particle is found or by ensuring one is produced in every event.
2. The signal particle is decayed using the `DecayTool` (EvtGen) to the desired final state, all remaining unstable particles are decayed independently.
3. The signal and its decay products might be required to pass generator level cuts implemented as a `CutTool`.
4. Particles are transported through the detector simulation.

> ## Things to remember {.callout}
>
> 1. The detector simulation is the **__by far__** most time consuming step (minutes). So make sure your generator cuts remove events you cannot possible reconstruct or select later on. Additional options are available to increase the speed, please talk to your MC liaisons!
> 2. The generator cuts are only applied to the signal that was forced to decay to the specific final state. _Any_ other true candidate is not required to pass.
> 3. The number of generated events refers to the number entering step 4 above, so those passing the generator level cuts. __Not__ the number of events produced by the `ProductionTool` in the first step.

# Figuring out which option files to use and how to run Gauss

Imagine you need to know the option files and software versions used for a simulated sample you have found in the bookkeeping, e.g.
```
/MC/2015/Beam2510GeV-2015-MagDown-Nu1.5-25ns-Pythia8/Sim09b/Trig0x4115014e/Reco15a/Turbo01aEM/Stripping22NoPrescalingFlagged/27163003/ALLSTREAMS.DST
```
First, find the ProductionID:
![FindingProductionID](img/simulation_1.png)
Search for this ID in the Transformation Monitor, right click the result and select "Show request". Right clicking and selecting "View" in the new window will open an overview about all the individual steps of the production with their application version and option files used.
> Important: the order of the option files does matter!
The production system handles the necessary settings for initial event- and runnumber and the used database tags. In a private production, you need to set these yourself in an additional options file, containing, for example:

```python
from Gauss.Configuration import GenInit

GaussGen = GenInit("GaussGen")
GaussGen.FirstEventNumber = 1
GaussGen.RunNumber = 1082

from Configurables import LHCbApp
LHCbApp().DDDBtag = 'dddb-20150724'
LHCbApp().CondDBtag = 'sim-20160623-vc-md100'
LHCbApp().EvtMax = 5
```

Assuming this is saved in a file called `Gauss-Job.py` and following the example above, the sample can then be produced by running

```shell
lb-run Gauss/v49r7 gaudirun.py '$APPCONFIGOPTS/Gauss/Beam2510GeV-md100-2015-nu1.5.py' \
'$APPCONFIGOPTS/Gauss/DataType-2015.py' \
'$APPCONFIGOPTS/Gauss/RICHRandomHits.py' \
'$DECFILESROOT/options/27163003.py' \
'$LBPYTHIA8ROOT/options/Pythia8.py' \
'$APPCONFIGOPTS/Gauss/G4PL_FTFP_BERT_EmNoCuts.py' \
'$APPCONFIGOPTS/Persistency/Compression-ZLIB-1.py' \
Gauss-Job.py
```

This would take 5 to 10 minutes due to the detector simulation, which can be turned off by adding `'$GAUSSOPTS/GenStandAlone.py'` as one of the option files.

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
./run gaudirun.py Gauss-Job.py '$GAUSSOPTS/GenStandAlone.py' '$DECFILESROOT/options/11164001.py' '$LBPYTHIA8ROOT/options/Pythia8.py'
```

This will output a .xgen file containing simulated events, as well as a root file containing various monitoring histograms you will probably never want to look at.  
As stated above, note that the number of events produced is *after generator level cuts* - this is also true for production requests.

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

# Filtering a simulated sample

For larger production requests, the amount of disk space required to store the sample becomes a problem. Therefore, a filtering of the final candidates obtained after the stripping step in the MC production can be applied. As this does not reduce the CPU requirements, filtering steps are best accompanied by a matching (but looser) set of generator cuts.

Assuming we have a sample of simulated D*+ -> D0( -> K pi ) pi which we would like to filter on the Turbo line `'Hlt2CharmHadD02KPi_XSecTurbo'`:

```python
from GaudiConf import IOHelper
IOHelper().inputFiles(
   ['root://eoslhcb.cern.ch//eos/lhcb/grid/prod/lhcb/MC/2015/ALLSTREAMS.DST/00057933/0000/00057933_00000232_3.AllStreams.dst'],
    clear=True)
```

We also do not need any events where the D0 candidate has a transverse momentum less than 3 GeV. We already know how to write the filter for this:
```python
from PhysSelPython.Wrappers import AutomaticData, SelectionSequence, Selection
from Configurables import FilterDesktop

line = 'Hlt2CharmHadD02KPi_XSecTurbo'
Dzeros = AutomaticData('/Event/Turbo/'+line+'/Particles')

decay = '[D0 --> K- pi+]CC'

pt_selection = FilterDesktop(
    'D0_PT_selector', Code="(CHILD(PT, '{0}') > 3000*MeV)".format(decay))

sel = Selection('D0_PT_selection',
                Algorithm=pt_selection,
                RequiredSelections=[Dzeros])

selseq = SelectionSequence('D0_Filtered', sel)
```
Instead of writing a ntuple, we need to write out the events to an (m)DST which pass `selseq`. The necessary configuration is basically identical in all filtering options in use and for the DST format reads
```python
from DSTWriters.Configuration import (SelDSTWriter, stripDSTStreamConf, stripDSTElements)

SelDSTWriterElements = {'default': stripDSTElements()}
SelDSTWriterConf = {'default': stripDSTStreamConf()}

dstWriter = SelDSTWriter("TurboFiltered",
                         StreamConf=SelDSTWriterConf,
                         MicroDSTElements=SelDSTWriterElements,
                         OutputFileSuffix ='',
                         SelectionSequences=[selseq]  # Only events passing selseq are written out!
                         
from Configurables import DaVinci
DaVinci().appendToMainSequence([dstWriter.sequence()])
```
Running these options (after adding the usual `DaVinci()` options like data type, tags etc) produces the file `SelD0_Filtered.dst` and you can verify that every event has a candidate passing `'Hlt2CharmHadD02KPi_XSecTurbo'` with at least 3 GeV transverse momentum.

> ## Filtering in production {.callout}
>
> 1. Option files need to be tested and checked by the MC liaisons.
> 2. Exist here: http://svnweb.cern.ch/world/wsvn/lhcb/DBASE/tags/WG Lots and lots of examples.
> 3. More details and naming conventions: https://twiki.cern.ch/twiki/bin/view/LHCbPhysics/FilteredSimulationProduction
