## Introduction

PowerUp is a build and deployment framework, written on top of PowerShell and PSake.

PowerUp is simple, low obligation and assumes very little.
There is nothing to be installed, with the only dependency being Powershell.

PowerUp deployment is based on simple zip packages, plus a number of PowerShell scripts that make their deployment easier. It also bundles convenient tools to enable the configuration of Windows servers (e.g. create websites etc).

## Status

At Affinity ID, PowerUp is currently in high-speed-evolution mode.
The version on public NuGet is stable but significantly outdated.

We plan to release these changes to public NuGet, but at the moment we don't have a specific timeline in mind.

## Disclaimer of Background Influences

PowerUp was influenced by a number of existing tools, including proprietary ones.
In particular, many ideas are similar to the NAnt based build system used by BBC Worldwide.

The aspects where this influence shows are, in particular:  
- The idea of substituting values from a plain text settings file into template files.  
- The use of psexec to execute remote scripts, and the use of "cmd.js" (originally described here http://forum.sysinternals.com/psexec-the-pipe-has-been-ended_topic10825.html) to control standard output.  

The intention is that these are fair-use adoptions of ideas.

## Alternatives

### Bounce
https://github.com/refractalize/bounce. 

The main difference is that Bounce is C# based. We decided on Powershell for its unparalleled breath of support in Windows, flexibility across languages, and to provide a very low barrier for entry. Bounce has other strengths - more maturity, clearer semantics and testability. There is future potential for the use of Bounce within PowerUp. 

### UppercuT
http://code.google.com/p/uppercut/

Largely a build and test running framework, not a deployment one.
In theory, UppercuT could be used as an alternative to straight Nant to create PowerUp packages.
It does, however, build a package per environment which goes against the environment neutrality built into PowerUp packages.

### Pstrami
https://github.com/jhicks/pstrami

Has an attractively closer similarity to capistrano in terms of the script syntax, but has less functionality overall.
