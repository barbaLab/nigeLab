# Spike Detection Code

** This code is commonly used in the Cortical Plasticity Laboratory (CPL) group. **

## Description

Primarily for Matlab R2017a. This code is integrated to run in parallel using cores on the Isilon supercluster at University of Kansas Medical Center. 
There are several different methods for the actual detection process, as well as some code for pre-processing data that has not been
virtually re-referenced. There is also adaptations of the code developed by [Quiroga (2004)](https://www2.le.ac.uk/departments/engineering/research/bioengineering/neuroengineering-lab/spike-sorting "WaveClus"). 

Typically, the automated clustering procedures produce decent separation for short recordings on clean (approximately < 15 uV RMS) multi-channel recordings. 
For most recordings used for experimental purposes, the length of recording and corresponding number of possible real and artifactual waveforms results in poor performance.
In that case, manual rejection of artifact using "cluster cutting" tools, and characterization of multi-unit activity are the recommended course of action.