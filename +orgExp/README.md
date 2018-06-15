# orgExp #
A package for keeping experimental data and metadata organized and easily accessible. Provides access to common types of analyses used in extracellular electrophysiological and behavioral experiments, including (but not yet all pushed):

* Data extraction and filtering algorithms that are extensible for parallel computing
* Spike clustering and curation tools
* Metadata tracking for easily comparing combinations of experimental factors
* Spike train analyses (rasters, PETH, correlograms, population dynamics, mutual information)
* LFP analyses (phase/amplitude coupling, MEM spectrogram estimation)
* Probably other stuff!

## FAQ ##
[Why have you done this?](#object-oriented-matlab-data-structures "Progress reports, grant applications, etc...")  
[How would these tools benefit me (concretely)?](#example-of-how-it-works "Lets you quickly look at and analyze electrophysiological data in Matlab.")  
[Will this package work for my specific experimental pipeline?](#data-pipeline "I hope so!")  
[How are things organized and why so many redundancies?](#file-structure-hierarchy "Hard drive memory is inexpensive. And I'm not a computer scientist.")  
[What does a Tank object do?](#tank-methods-overview "Contains methods for groups of recordings.")  
[What does a Block object do?](#block-methods-overview "Contains methods for processing a single recording.")  
---
### Object-oriented Matlab Data Structures ###
1. As our group has added engineering students and begun collaborations with other engineering groups, it has become evident that we have spent too much time re-inventing the wheel. A major goal of this package is to provide a centralized resource that reflects our data collection process, and which can quickly be learned and added to by new students and collaborators.

2. A lot of analysis packages are "by engineers, for engineers." A personal goal of mine is to create tools "by engineers, for non-engineers." In my mind, one aspect of that is creating tools that allow useful analyses or increase productivity without ever having to enter jargon into a console. The goal of this package is to extend powerful tools for electrophysiological pre-processing, analysis, and metadata tracking using a relatively simple and straightforward interface. To that end, the two main kinds of objects you need to learn about to get up and running with this package are the "Tank" and "Block" objects (nomenclature shamelessly borrowed from TDT).  
	
	* [**Tank**](https://github.com/m053m716/ePhys_packages/tree/master/%2BorgExp/%40Tank)
		* A set of experimental recordings that all relate to the same project or overall experiment are part of a tank. Creating a Tank object and pointing it to the directory where individual recorded data folders reside allows you to have a single object that you can use to efficiently organize your data for further analyses.
		
	* [**Block**](https://github.com/m053m716/ePhys_packages/tree/master/%2BorgExp/%40Block)
		* A single experimental recording with a preset format. A Tank object could contain multiple Blocks; the Blocks have methods for viewing data specific to a single recording whereas the Tank contains methods for aggregating data from multiple Blocks.  
		
3. In line with the second point, offering this package through Matlab means that as long as you have Matlab R2017a or beyond (not tested with earlier versions, but probably mostly works), you don't have to go through the hassle of finding the right compiler and debugging everything for your specific software/hardware configuration.
---
### Example of how it works ###
1. Open the file Tank.m in the Matlab editor and click the green Play button.
2. Select the parent folder that contains your individual recording files (e.g. Intan *.rhd or *.rhs files, or TDT block folders). This is the [Tank](https://github.com/m053m716/ePhys_packages/tree/master/%2BorgExp/%40Tank).
3. A graphical interface (in progress...) will populate with all viable recordings and associated metadata. These are the [Blocks](https://github.com/m053m716/ePhys_packages/tree/master/%2BorgExp/%40Block). Dropdown menus will populate with options to configure processing steps such as:
	* Spike detection (filtering, spatial referencing, unsupervised clustering, etc.) 
	* LFP analysis (frequency spectrum estimation, phase coupling analyses)
	* Within-block segmentation into separate epochs
	* Extraction of behavioral alignment time stamps
	* Parallel computing options
4. Clicking the RUN button in the interface begins the specified analyses.
	* Depending on the length of recording and available computing resources, it may be wise to do this part overnight. 
5. Once a set of Blocks reaches the same processing state, available figure or statistic export options are populated. 
	* Based on naming convention, the Tank will try to pre-populate metadata variables, which can be used to group Block outputs.  
  
---
## Data Pipeline ##
### Overview ###  
![][DataPipeline_Overview]  
_**Figure 1:** Generic overview for behavioral electrophysiology data acquisition and processing pipeline. Moving from performing experiments to data endpoints is easy with orgExp. Thanks to an intuitive user interface, no need to compile anything (everything runs in Matlab), and built-in flexibility that can be easily integrated to your workflow, orgExp is a good choice to move from acquisition to analysis seamlessly._  
  
---
## File Structure Hierarchy ##
### Tank Structure ###  
![][TankStructure_Overview]  
_**Figure 2:** Tank folder hierarchy overview. A Tank is a parent folder that contains one or more files as they are produced from the particular acquisition hardware and software used during data collection. The Tank may also contain a file with a general description of the types of experiments as well as a file that indicates how the naming convention should be translated into metadata for downstream analyses._  
### Block Structure ### 
![][BlockStructure_Overview]  
_**Figure 3:** Block folder and file hierarchy overview, after data processing and extraction has been applied to a recording file. The string inset at the top-right of the figure shows the recording naming convention used by the Nudo Lab (Cortical Plasticity Lab) at the University of Kansas Medical Center. The legend inset at the top-left of the figure shows the type(s) of file that are contained within a particular sub-folder or general grouping of types of files._   
  
---
## Tank Methods Overview ##
Brief example calls to methods used by Tank class. For more detailed descriptions, visit the Tank [class folder](https://github.com/m053m716/ePhys_packages/tree/master/%2BorgExp/%40Tank "@Tank") or try entering the following into the Matlab command window for more detailed documentation:   

```Matlab
doc orgExp.Tank
```
  
### [Tank](https://github.com/m053m716/ePhys_packages/tree/master/%2BorgExp/%40Tank#tank-1 "Tank Class constructor") ###  
Construct the Tank Class object.

```Matlab
tank = orgExp.Tank; % Will prompt Tank selection UI
```  

```Matlab
tank = orgExp.Tank('DIR','C:/Tank/Folder/Path');
```  
---  
  
### [convert](https://github.com/m053m716/ePhys_packages/tree/master/%2BorgExp/%40Tank#convert "Convert raw files") ###  
Convert raw acquisition files to Matlab Block file hierarchical structure.  

```Matlab
% Begin conversion with current Tank properties
flag = tank.convert;
```
---  
  
### [list](https://github.com/m053m716/ePhys_packages/tree/master/%2BorgExp/%40Tank#list "List of Blocks in Tank")###  
List all Blocks in the Tank.

```Matlab
blockList = tank.list;
```  

```Matlab
blockList = list(tank);
```
---  
  
### [tankGet](https://github.com/m053m716/ePhys_packages/tree/master/%2BorgExp/%40Tank#tankget "Get Tank property")###  
Get a specified property of the Tank.

```Matlab
propertyValue = tank.tankGet('PropertyName');
```  

```Matlab
propertyValueArray_1xK = tankGet(tank,{'PropertyName1','PropertyName2',...,'PropertyNameK'});  
```

```Matlab
propertyValueArray = tankGet(tank); % Return all properties
```  
---  
  
###[tankSet](https://github.com/m053m716/ePhys_packages/tree/master/%2BorgExp/%40Tank#tankset "Set Tank property")###  
Set a specified property of the Tank.
  
```Matlab
setFlag = tank.tankSet('PropertyName',propertyValue); % Returns true if property set successfully
```  

```Matlab
setFlagArray_1xK = tankSet(tank,{'PropertyName1','PropertyName2',...,'PropertyNameK'},...
{propertyVal1,   propertyVal2,  ..., PropertyValK});  
```
---  
  
## Block Methods Overview ##
Brief example calls to methods used by Block class. For more detailed descriptions, visit the Block [class folder](https://github.com/m053m716/ePhys_packages/tree/master/%2BorgExp/%40Block "@Block") or try entering the following into the Matlab command window for more detailed documentation:  
```Matlab
doc orgExp.Block
```  
  
###[Block](https://github.com/m053m716/ePhys_packages/tree/master/%2BorgExp/%40Block#block-1 "Block Class constructor")###  
Construct the Block Class object.

```Matlab
block = tank.Block(1);
```  

```Matlab
block = orgExp.Block; % Will bring up Block selection UI
```

```Matlab
block = orgExp.Block('DIR','C:/Block/Folder/Path');
```
---  
  
###[blockGet](https://github.com/m053m716/ePhys_packages/tree/master/%2BorgExp/%40Block#blockget "Get Block property")###  
Get a specific Block property.
```Matlab
propertyValue = block.blockGet('PropertyName');
```  

```Matlab
propertyValueArray_1xK = blockGet(block,{'PropertyName1','PropertyName2',...,'PropertyNameK'});  
```

```Matlab
propertyValueArray = blockGet(block); % Return all properties
```  
---  
  
###[blockSet](https://github.com/m053m716/ePhys_packages/tree/master/%2BorgExp/%40Block#blockset "Set Block property")###  
Set a specific Block property.

```Matlab
% Returns true if property set successfully
setFlag = block.blockSet('PropertyName',propertyValue); 
```  

```Matlab
setFlagArray_1xK = blockGet(block,{'PropertyName1','PropertyName2',...,'PropertyNameK'},...
	{propertyVal1,   propertyVal2,  ..., PropertyValK});  
```
---  
  
###[list](https://github.com/m053m716/ePhys_packages/tree/master/%2BorgExp/%40Block#list "List files in Block")###  
List all the data files associated with this Block.

```Matlab
% Print all files associated with Block to the Command Window. 
flag = block.list; % true if ANY file is associated with the Block
```  

```Matlab
% Prints files associated of a specific type
fieldname = 'Raw'; 		   % (here: RawData)
flag = list(Block,fieldname); % false if no RawData files 
```
---  
  
###[loadClusters](https://github.com/m053m716/ePhys_packages/tree/master/%2BorgExp/%40Block#loadclusters "Load spike clusters")###  
Load unsupervised spike cluster assignments for a single channel.

```Matlab
% Returns a struct with cluster data for spikes on channel 9.
channel = 9;
out = block.loadClusters(channel); 
```  

```Matlab
% Returns an array struct with cluster data for spikes on channels 1:16.
channel = 1:16;
out = block.loadClusters(channel); 
``` 

```Matlab
% Returns an array struct with cluster data for spikes on all channels.
out = block.loadClusters; 
``` 
---  
  
###[loadSorted](https://github.com/m053m716/ePhys_packages/tree/master/%2BorgExp/%40Block#loadsorted "Load sorted spike classes")###  
Load manually curated spike cluster assignments for a single channel.

```Matlab
% Returns a struct with manual sorting data for spikes on channel 9.
channel = 9;
out = block.loadSorted(channel); 
```  

```Matlab
% Returns an array struct with manual sorting data for spikes on channels 1:16.
channel = 1:16;
out = block.loadSorted(channel); 
```

```Matlab
% Returns an array struct with manual sorting data for spikes on all channels.
out = block.loadSorted; 
``` 
---  
  
###[loadSpikes](https://github.com/m053m716/ePhys_packages/tree/master/%2BorgExp/%40Block#loadspikes "Load detected spikes")###  
Load sparse indexing vector of spike peaks and an associated matrix of waveform snippets.  
```Matlab
% Returns a struct with spikes for channel 9.
channel = 9;
out = block.loadSpikes(channel); 
```  

```Matlab
% Returns an array struct with spikes for channels 1:16.
channel = 1:16;
out = block.loadSpikes(channel); 
``` 

```Matlab
% Returns an array struct with spikes for all channels.
out = block.loadSpikes; 
``` 
---  
  
###[plotSpikes](https://github.com/m053m716/ePhys_packages/tree/master/%2BorgExp/%40Block#plotspikes "Plot spike cluster waveform snippets")###  
Plot all spike clusters for a single channel.  
```Matlab
% Makes figure with spikes for channel 9, returns true if successful.
channel = 9;
flag = block.plotSpikes(channel);  
``` 
---  
  
###[plotWaves](https://github.com/m053m716/ePhys_packages/tree/master/%2BorgExp/%40Block#plotwaves "Plot data stream snippet")###  
Plot a short segment of the data stream from each channel on one plot. Note that this can take a **long time.** Highlights spikes and cluster assignments if spike detection and clustering or sorting has been performed as well.  
```Matlab
% Returns true if wave stream plot figure is generated successfully.
flag = block.plotWaves;  % Plots most-filtered/curated possible.
``` 

```Matlab
% Returns true if wave stream plot figure is generated successfully.
WAV = 'C:/FILT/or/CARFILT/PATH';
flag = block.plotWaves(WAV);  
``` 

```Matlab
% Returns true if wave stream plot figure is generated successfully.
WAV = 'C:/FILT/or/CARFILT/PATH';
SPK = 'C:/SORTED/CLUSTERS/or/SPIKES/PATH';
flag = block.plotWaves(WAV,SPK);  
``` 
---  
  
###[syncBehavior](https://github.com/m053m716/ePhys_packages/tree/master/%2BorgExp/%40Block#syncbehavior "Synchronize behavioral and neural data")    
---  
  
###[takeNotes](https://github.com/m053m716/ePhys_packages/tree/master/%2BorgExp/%40Block#takenotes "Add/View Notes")###  
View or Add Notes .txt to Block.  
```Matlab
% Pull up NotesUI to view or enter notes
block.takeNotes;  
``` 
---  
  
###[updateContents](https://github.com/m053m716/ePhys_packages/tree/master/%2BorgExp/%40Block#updatecontents "Update Block contents")###  
Refresh file contents of Block.  
```Matlab
% Update files associated with all fields of blockObj.
blockObj.updateContents;  
``` 

```Matlab
% Update files associated with Raw Data streams only.
fieldname = 'Raw';
blockObj.updateContents(fieldname);  
``` 
---  
  
###[updateID](https://github.com/m053m716/ePhys_packages/tree/master/%2BorgExp/%40Block#updateid "Modify ID tokens for Block")###  
Modify Block string tokens that associate specific file types with Block data fields.  
```Matlab
fieldname = 'Filt'; % Update filtered data streams identifier
type = 'File';		 % For .mat files ('File' or 'Folder')
updatedValue = 'filtdata';	 % New token for Block to recognize
blockObj.updateID(fieldname,type,updatedValue); % Update file associations.
``` 
---  
  
[DataPipeline_Overview]: https://github.com/m053m716/ePhys_packages/blob/master/%2BorgExp/img/DataPipeline_Overview.JPG "Fig. 1: Generic experimental pipeline"
[DataPipeline_Recording]: https://github.com/m053m716/ePhys_packages/blob/master/%2BorgExp/img/DataPipeline_Recording.JPG "Fig. 1a: Data collected during experiments"
[DataPipeline_Conversion]: https://github.com/m053m716/ePhys_packages/blob/master/%2BorgExp/img/DataPipeline_Conversion.JPG "Fig. 1b: Conversion of data from binary to Matlab-compatible file format"
[DataPipeline_Analysis]: https://github.com/m053m716/ePhys_packages/blob/master/%2BorgExp/img/DataPipeline_Analysis.JPG "Fig. 1c: Extraction of features of interest and hypothesis-testing"

[TankStructure_Overview]: https://github.com/m053m716/ePhys_packages/blob/master/%2BorgExp/img/TankBlockHierarchy_Overview.JPG "Fig. 2: Tank folder hierarchy"

[BlockStructure_Overview]: https://github.com/m053m716/ePhys_packages/blob/master/%2BorgExp/img/BlockStructure_Overview.JPG "Fig. 3: Block file hierarchy"
[BlockStructure_Base]: https://github.com/m053m716/ePhys_packages/blob/master/%2BorgExp/img/BlockStructure_Base.JPG "Fig. 3a: Block parent folder"
[BlockStructure_HighSampleRateStreams]: https://github.com/m053m716/ePhys_packages/blob/master/%2BorgExp/img/BlockStructure_HighSampleRateStreams.JPG "Fig. 3c: High sample rate streams"
[BlockStructure_LowSampleRateStreams]: https://github.com/m053m716/ePhys_packages/blob/master/%2BorgExp/img/BlockStructure_LowSampleRateStreams.JPG "Fig. 3d: Low sample rate streams"
[BlockStructure_SnippetFeatures]: https://github.com/m053m716/ePhys_packages/blob/master/%2BorgExp/img/BlockStructure_SnippetFeatures.JPG "Fig. 3e: Spike detection, clustering, and sorting"
[BlockStructure_BehaviorSyncData]: https://github.com/m053m716/ePhys_packages/blob/master/%2BorgExp/img/BlockStructure_BehaviorSyncData.JPG "Fig. 3f: Digital inputs for behavioral synchronization to neural data"

[NamingConvention_Example]: https://github.com/m053m716/ePhys_packages/blob/master/%2BorgExp/img/NamingConvention_Example.JPG "Fig. 3b: Naming convention used by the Nudo Lab at KUMC"