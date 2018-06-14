# orgExp #
A package for keeping experimental data and metadata organized and easily accessible. Provides access to common types of analyses used in extracellular electrophysiological and behavioral experiments, including (but not yet all pushed):

* Data extraction and filtering algorithms that are extensible for parallel computing
* Spike clustering and curation tools
* Metadata tracking for easily comparing combinations of experimental factors
* Spike train analyses (rasters, PETH, correlograms, population dynamics, mutual information)
* LFP analyses (phase/amplitude coupling, MEM spectrogram estimation)
* Probably other stuff!

## FAQ ##
[Why have you done this?](https://github.com/m053m716/ePhys_packages/tree/master/%2BorgExp#object-oriented-matlab-data-structures "Progress reports, grant applications, etc...")  
[How would these tools benefit me (concretely)?](https://github.com/m053m716/ePhys_packages/tree/master/%2BorgExp#example-of-how-it-works "Lets you quickly look at and analyze electrophysiological data in Matlab.")  
[Will this package work for my specific experimental pipeline?](https://github.com/m053m716/ePhys_packages/tree/master/%2BorgExp#data-pipeline "I hope so!")  
[How are things organized and why so many redundancies?](https://github.com/m053m716/ePhys_packages/tree/master/%2BorgExp#file-structure-hierarchy "Hard drive memory is inexpensive. And I'm not a computer scientist.")  
[What does a Tank object do?](https://github.com/m053m716/ePhys_packages/tree/master/%2BorgExp#tank-methods-overview "Contains methods for groups of recordings.")  
[What does a Block object do?](https://github.com/m053m716/ePhys_packages/tree/master/%2BorgExp#block-methods-overview "Contains methods for processing a single recording.")  

### Object-oriented Matlab Data Structures ###
1. As our group has added engineering students and begun collaborations with other engineering groups, it has become evident that we have spent too much time re-inventing the wheel. A major goal of this package is to provide a centralized resource that reflects our data collection process, and which can quickly be learned and added to by new students and collaborators.

2. A lot of analysis packages are "by engineers, for engineers." A personal goal of mine is to create tools "by engineers, for non-engineers." In my mind, one aspect of that is creating tools that allow useful analyses or increase productivity without ever having to enter jargon into a console. The goal of this package is to extend powerful tools for electrophysiological pre-processing, analysis, and metadata tracking using a relatively simple and straightforward interface. To that end, the two main kinds of objects you need to learn about to get up and running with this package are the "Tank" and "Block" objects (nomenclature shamelessly borrowed from TDT).  
	
	* [**Tank**](https://github.com/m053m716/ePhys_packages/tree/master/%2BorgExp/%40Tank)
		* A set of experimental recordings that all relate to the same project or overall experiment are part of a tank. Creating a Tank object and pointing it to the directory where individual recorded data folders reside allows you to have a single object that you can use to efficiently organize your data for further analyses.
		
	* [**Block**](https://github.com/m053m716/ePhys_packages/tree/master/%2BorgExp/%40Block)
		* A single experimental recording with a preset format. A Tank object could contain multiple Blocks; the Blocks have methods for viewing data specific to a single recording whereas the Tank contains methods for aggregating data from multiple Blocks.  
		
3. In line with the second point, offering this package through Matlab means that as long as you have Matlab R2017a or beyond (not tested with earlier versions, but probably mostly works), you don't have to go through the hassle of finding the right compiler and debugging everything for your specific software/hardware configuration.

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

### Data Pipeline ###
![][DataPipeline_Overview]  
_**Figure 1:** Generic overview for behavioral electrophysiology data acquisition and processing pipeline._
  
  

### File Structure Hierarchy ###
![][TankStructure_Overview]  
_**Figure 2:** Tank folder hierarchy overview. A Tank is a parent folder that contains one or more files as they are produced from the particular acquisition hardware and software used during data collection. The Tank may also contain a file with a general description of the types of experiments as well as a file that indicates how the naming convention should be translated into metadata for downstream analyses._  
  
  
![][BlockStructure_Overview]  
_**Figure 3:** Block folder and file hierarchy overview, after data processing and extraction has been applied to a recording file. The string inset at the top-right of the figure shows the recording naming convention used by the Nudo Lab (Cortical Plasticity Lab) at the University of Kansas Medical Center. The legend inset at the top-left of the figure shows the type(s) of file that are contained within a particular sub-folder or general grouping of types of files._  
   
### Tank Methods Overview ###
Brief summary of main methods used by Tank class. For more detailed descriptions, visit the Tank [class folder](https://github.com/m053m716/ePhys_packages/tree/master/%2BorgExp/%40Tank "@Tank") or try:  
```matlab
doc orgExp.Tank
```
in the Matlab command window for more detailed documentation. 

* Tank
	* ```Matlab
		 tank = orgExp.Tank;
	  ```  
	  or
	* ```Matlab
		 tank = orgExp.Tank('DIR','C:/Tank/Folder/Path');
	  ``` 
* orgExp.List
* orgExp.MetaData

### MetaData ### 

### Block Methods Overview ###
Brief summary of main methods used by Block class. For more detailed descriptions, visit the Block [class folder](https://github.com/m053m716/ePhys_packages/tree/master/%2BorgExp/%40Block "@Block") or try:  
```matlab
doc orgExp.Block
```  
in the Matlab command window for more detailed documentation.  

* orgExp.Block
* List
* LoadClusters
* LoadSorted
* LoadSpikes
* PlotSpikes
* PlotWaves
* SyncBehavior
* TakeNotes
* UpdateContents
* UpdateID  

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