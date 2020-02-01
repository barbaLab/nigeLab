# Block #

> "Building-Block" for managing data from single recordings.

## Methods ##

| **[`Constructor`](#Constructor)** |                  **[`doMethods`](#doMethods)** |                                                     |                                            |                                               |
| --------------------------------- | ---------------------------------------------: | --------------------------------------------------: | -----------------------------------------: | --------------------------------------------: |
| **[Block](#nigeLab.Block)**       | [Auto Cluster Spikes](#Block.doAutoClustering) |              [Behavior Sync](#Block.doBehaviorSync) | [Event Detection](#Block.doEventDetection) | [Event Header](#Block.doEventHeaderDetection) |
|                                   |       [LFP Decimation](#Block.doLFPExtraction) |   **[Raw Data Conversion](#Block.doRawExtraction)** |       [Re-Reference](#Block.doReReference) |                [Spike Detection](#Block.doSD) |
|                                   |    [Unit Bandpass Filter](#Block.doUnitFilter) | [Video Info Extraction](#Block.doVidInfoExtraction) |   [Video Sync](#Block.doVidSyncExtraction) |                                               |

| **[`Utility`](#Utility)**      |      |      |      |      |
| ------------------------------ | ---- | ---- | ---- | ---- |
| [Get (Completion) Status](#Block.getStatus) |  [Link Data](#Block.linkToData)    |  [Set (Completion) Status](#Block.updateStatus)    | [Update Parameters](#Block.updateParams)     |      |

---
## `Constructor` ##
### nigeLab.Block ###
> Creates "building-Block" for managing data from single recordings.

* Associated defaults are stored in `nigelObj.Pars.Block` (at each hierarchical level)
  + Defaults can be configured in `~/+nigeLab/+defaults/Block.m`
    - **Critically**, all _**name parsing**_ is configured here. Incorrect parsing configuration is the _most-common_ source of errors in constructing/initializing a `Block`.
    - There are substantial comments and examples in the code comments, look there for more information. 
  + Other `+defaults` may influence the Block constructor:
    - `~/+nigeLab/+defaults/Animal.m` (since `Block` is constructed during `Animal` constructor)
    - `~/+nigeLab/+defaults/Tank.m` (since `Block` is constructed during `Tank` constructor)
    - `~/+nigeLab/+defaults/Video.m` (since `VidStreams` flags can affect `Block.init` during automated parsing/association of Videos and Video-related Streams with the `Block`)
    - `~/+nigeLab/+defaults/Queue.m` (depending on flags set for parallel or remote processing in combination with specifications of `Matlab` installation on your local machine)

#### Example Creation of Block Object ####

```Matlab
% Get second Block from third Animal of the Tank
animalIndex = 3;
blockIndex = 2;
blockObj = tankObj{animalIndex,blockIndex};
```

```Matlab
% Construct a Block using two UI prompts: 
% 1) Input block file
% 2) Output (Animal) folder that contains the Block
blockObj = nigeLab.Block();
blockObj = nigeLab.Block([]);
```

```Matlab
% Construct a Block, specifying save location, but select the file from UI
saveLoc = fullfile('savepath','experimentName','tankName','animalName');
blockObj = nigeLab.Block([],saveLoc);
```

```Matlab
% Construct a Block, skipping the UI
% Note that if a file path produces parsing errors,
% a UI may pop up to request the correct path.
inputFile = fullfile('inpath','tankName','animalName','blockName.rhd'); % Intan RHD
inputFile = fullfile('inpath','tankName','animalName','blockName.rhs'); % Intan RHS
inputFile = fullfile('inpath','tankName','animalName','blockName','blockName.sev'); % TDT
inputFile = fullfile('inpath','tankName','blockName','blockName.sev'); % TDT - also works
saveLoc = fullfile('savepath','experimentName','tankName','animalName');
blockObj = nigeLab.Block(inputFile,saveLoc);
```

---
## `doMethods` ##

### Block.doAutoClustering ###

> Cluster (SPC, K-Means) spikes based on extracted waveform features (PCs, Wavelet Coefficients)

* Overloads superclass method inherited from `nigeLab.nigelObj`
  + Superclass just iterates on "connected" `nigeLab.Tank` and `nigeLab.Animal` objects.
* The following `.Fields` must have a `true` value for `.Status`:
  + `Raw` ([`doRawExtraction`](#Block.doRawExtraction))
    - Required (indirectly)
  + `Filt` ([`doUnitFilter`](#Block.doUnitFilter))
    - Required (indirectly)
  + `CAR` ([`doReReference`](#Block.doReReference))
    - Required (indirectly)
  + `Spikes` ([`doSD`](#Block.doSD))
    - Required (indirectly)
  + **`SpikeFeatures` ([`doSD`](#Block.doSD))**
    - Required directly
  + These requirements can be changed in `~/+nigeLab/+defaults/doActions.m`
* Associated defaults are in `blockObj.Pars.AutoClustering`
  + Defaults can be configured in `~/+nigeLab/+defaults/AutoClustering.m`
  + For specific clustering algorithms, such as K-Means or SPC, some configurations are located in ``~/+nigeLab/+defaults/+AutoClustering/[methodname].m` 

#### Example Auto-Clustering ####

```matlab
blockObj = tankObj{1,2}; % second Block of first Animal in Tank
doAutoClustering(blockObj); % does auto-clustering and saves to diskfiles
linkToData(blockObj); % connect clusters to blockObj in Matlab
% linkToData(blockObj,'Clusters','Sorted'); % should also work, potentially faster
```

---
### Block.doBehaviorSync ###
> _**WIP**: Synchronize neural data with behavioral events_

---
### Block.doEventDetection ###
> _**WIP**: Perform automated detection of events determined by `.Videos` or `.Streams`_

---
### Block.doEventHeaderExtraction ###
> _**WIP**: Extract **Header** for use with [`.scoreVideo`](#Block.scoreVideo) method_

---
### Block.doLFPExtraction ###

> Decimate raw signal to facilitate frequency-domain analyses

* Overloads superclass method inherited from `nigeLab.nigelObj`
  + Superclass just iterates on "connected" `nigeLab.Tank` and `nigeLab.Animal` objects.
* The following `.Fields` to have a `true` value for `.Status`:
  + **`Raw` ([`doRawExtraction`](#Block.doRawExtraction))**
    - Required (directly)
  + These requirements can be changed in `~/+nigeLab/+defaults/doActions.m`
* Associated defaults are in `blockObj.Pars.LFP`
  + Defaults can be configured in `~/+nigeLab/+defaults/LFP.m`

#### Example LFP Decimation ####

```matlab
blockObj = tankObj{2,:}; % All Blocks from the second Animal of the Tank
doLFPExtraction(blockObj); % extracts LFP and saves to diskfiles
linkToData(blockObj); % connect clusters to blockObj in Matlab
% linkToData(blockObj,'LFP'); % should also work, potentially faster
```

---
### Block.doRawExtraction ###

> Extract "raw" recorded amplifier and digital stream signals from recording binaries

* Overloads superclass method inherited from `nigeLab.nigelObj`
  + Superclass just iterates on "connected" `nigeLab.Tank` and `nigeLab.Animal` objects.
* Does not require any other fields to be completed before running (by default)
  + This requirement can be changed in `~/+nigeLab/+defaults/doActions.m`
* Associated defaults are somewhat disperse; there are not any explicit `+defaults` elements corresponding to the `Raw` field per se; however, the main thing is that **parsing** parameters must be set up in several places. See **[`Block Constructor`](#Constructor)** for more details.
  + Defaults can be configured in `~/+nigeLab/+defaults/Raw.m`

#### Example Raw Data Extraction ####

```Matlab
animalObj = tankObj{1}; % Returns 1st Animal in Tank
blockObj = animalObj{[2,5]}; % Returns 2nd and 5th block of 1st Animal in Tank
doRawExtraction(blockObj); % extracts Raw data and saves to diskfiles for both Blocks
linkToData(blockObj); % connect raw data to blockObj in Matlab
% linkToData(blockObj,'Raw','DigIO','AnalogIO','Stim','Time',); % should also work
```

---
### Block.doReReference ###

> _Apply "virtual" common-average subtraction to each probe separately_

* Overloads superclass method inherited from `nigeLab.nigelObj`
  + Superclass just iterates on "connected" `nigeLab.Tank` and `nigeLab.Animal` objects.
* The following `.Fields` must have a `true` value for `.Status`:
  + `Raw` ([`doRawExtraction`](#Block.doRawExtraction))
    - Required (indirectly)
  + **`Filt` ([`doUnitFilter`](#Block.doUnitFilter))**
    - Required (directly)
  + These requirements can be changed in `~/+nigeLab/+defaults/doActions.m`
  
* There are currently no associated `+defaults` for the `.CAR` field.

#### Example Re-Referencing ####

```Matlab
animalObj = tankObj{[1:3]}; % Returns first three Animals in Tank
blockObj = animalObj{:,[2,5]}; % Returns 2nd and 5th block of each Animal in animalObj array (first 3 animals of Tank)
doReReference(blockObj); % extracts Raw data and saves to diskfiles for both Blocks
linkToData(blockObj); % connect raw data to blockObj in Matlab
% linkToData(blockObj,'CAR',); % should also work
```

---
### Block.doSD ###

> _Detect spikes in the extracellular field potentials and associate compressed sample features_

* Overloads superclass method inherited from `nigeLab.nigelObj`
  + Superclass just iterates on "connected" `nigeLab.Tank` and `nigeLab.Animal` objects.
* The following `.Fields` must have a `true` value for `.Status`:
  + `Raw` ([`doRawExtraction`](#Block.doRawExtraction))
    - Required (indirectly)
  + `Filt` ([`doUnitFilter`](#Block.doUnitFilter))
    - Required (indirectly)
  + **`CAR` ([`doReReference`](#Block.doReReference))**
    - Required (directly)
  + These requirements can be changed in `~/+nigeLab/+defaults/doActions.m`

* Associated defaults are in `blockObj.Pars.SD`
  +  Note that these parameters are somewhat confusing due to being associated with a much older version of `nigeLab`, but will be ported to a less-confusing naming convention at some point.

#### Example Spike Detection ####

```matlab
blockObj = tankObj{:,:}; % Return all blocks from the Tank 
linkToData(blockObj); % connect clusters to blockObj in Matlab
% linkToData(blockObj,'Spikes','SpikeFeatures'); % should also work, potentially faster
```

---
### Block.doUnitFilter ###
> _Apply "spike-unit" bandpass filter to recorded extracellular field potentials_

* Overloads superclass method inherited from `nigeLab.nigelObj`
  + Superclass just iterates on "connected" `nigeLab.Tank` and `nigeLab.Animal` objects.
* The following `.Fields` to have a `true` value for `.Status`:
  + **`Raw` ([`doRawExtraction`](#Block.doRawExtraction))**
    - Required (directly)
  + These requirements can be changed in `~/+nigeLab/+defaults/doActions.m`
* Associated defaults are in `blockObj.Pars.Filt`
  + Defaults can be configured in `~/+nigeLab/+defaults/Filt.m`

#### Example Spike Bandpass Filtering ####

```matlab
blockObj = tankObj{:,2}; % Second block from all animals in Tank
doUnitFilter(blockObj); % extracts LFP and saves to diskfiles
linkToData(blockObj); % connect clusters to blockObj in Matlab
% linkToData(blockObj,'Filt'); % should also work, potentially faster
```

---
### Block.doVidInfoExtraction ###
> _**WIP**: Get basic video-related information prior to performing manual video curation_

---
### Block.doVidSyncExtraction ###
> _**WIP**: Synchronize videos with neurophysiological data record_

---
## `Curation` ##
### Block.scoreVideo ###
> _**WIP**: Curate and append metadata to individual "trials" or video frames_

---
## `Utility` ##
### Block.getStatus ###
> _Return the completion status of a given `.Field`_  
* superclass method inherited from `nigeLab.nigelObj`

---
### Block.linkToData ###
> _Connect the data saved on the disk to the hierarchical structure_  
* superclass method inherited from `nigeLab.nigelObj`

---
### Block.updateStatus ###
> _Update the completion status of a specific `.Field`_  
* superclass method inherited from `nigeLab.nigelObj`

---
### Block.updateParams ###
> _Update some or all of the sub-fields of `.Pars` _  

* superclass method inherited from `nigeLab.nigelObj`  

---