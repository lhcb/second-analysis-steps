---
layout: page
title: First Steps in LHCb
subtitle: Building your own TupleTool
minutes: 30
---

> ## Learning Objectives {.objectives}
>
> * Compile Software Packages to use them within an LHCb project (e.g. DaVinci)

> ## SetupDaVinci instead of lb-run {.callout}
>
> When compiling your own packages, you'll encounter the subtle aspect that
> `ganga` uses `SetupDaVinci` instead of `lb-run DaVinci`. Since for
> compilations the `lb-run` and `lb-dev` commands behave a bit differently and
> assuming you want to run your self-made software on the grid, this lesson is
> written for `SetupDaVinci`.

> ## SetupDaVinci vs. SetupProject DaVinci {.callout}
>
> In almost all cases `SetupDaVinci` does exactly the same as `SetupProject
> DaVinci`. The author prefers the former, since the former works better along
> with tab-completion and can be typed `Se<tab>D<tab>`.

To create a directory where you can compile your own TupleTools (and any other
DaVinci tool and algorithm), which will then be found by `ganga` and the
`SetupDaVinci` command to run it, use

```shell
SetupDaVinci --build-env vVVrR
```

where you have to replace `vVVrR` by your desired version number. You now have
a new directory `$(HOME)/cmtuser/DaVinci_vVVrR` and also moved there.

Checking out a packages should be familiar from previous lessons (put link here)

From the top level directory of your project (i.e. the directory which just got
created) call `getpack` to obtain your local copy of the source code. (In fact
`getpack` uses `svn` to check out the software repository).

```shell
getpack Phys/DecayTreeTuple
```

`getpack` will ask you for the version number.

> ## official DaVinci packages and private packages {.callout}
>
> Usually you don't need to compile packages in the first place because they
> are already included in DaVinci. You might need to compile them yourself
> because you want to change something, in this case you're `getpack`'ing an
> official package. But there is also the possiblity that you want to add your
> own analysis package to your own DaVinci installation. In this case, DaVinci
> needs to be told that it has a new package. Easiest by adding it to the
> dependency definition of DaVinci.
>
> ```shell getpack Phys/DaVinci vVVrR cd Phys/DaVinci/cmt ls ```
>
> In this directory there is a file `requirements. You add your package (assume
> it is called `Phys/BsToKMuNu`) by adding the line
>
> ``` use   BsToKMuNu        v*    Phys ```

Once you have all the packages checked out (and added your new tools and
modified the code you want to modify), the build system needs to figure out how
your local DaVinci is composed, what needs to be compiled, etc.

```shell
cd Phys/DaVinci/cmt
cmt br cmt config
```

Now you can compile all packages at once with

```shell
cmt br cmt make
```

(compile several files in parallel with the additional option `-j4`, where `j`
means *jobs* and `4` is the number of concurrent jobs)

> ## SetupProject is funny {.callout}
>
> The environment you obtained with `SetupProject --build-env` is only good for
> compiling software, not for running it. To be on the safe side (cleaning up
> your environment), run your new DaVinci in a new shell.

Observe how `SetupProject` is now aware of your private software version.

```shell
SetupDaVinci --list-versions
```

You will observe that the version you have just built is not located in
`/afs/cern.ch/lhcb/software/releases` but in your home directory
`$HOME/cmtuser`. So now, whenever you do `SetupDaVinci vVVrR` your local
version will be used and not the official installation. Also `ganga` will now
use *your* DaVinci and will send a shared library with all your TupleTools to
the grid.
