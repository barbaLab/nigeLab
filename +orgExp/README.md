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
Open the file Tank.m in the Matlab editor and click the green Play button. 
	
### Data Pipeline ###
![alt text][DataPipeline_Overview]  

### File Structure Hierarchy ###
![alt text][TankStructure_Overview]  

![alt text][BlockStructure_Overview]  



### Tank Methods Overview ###
In progress...

### Block Methods Overview ###
In progress...



[DataPipeline_Overview]: https://github.com/m053m716/ePhys_packages/blob/master/%2BorgExp/img/DataPipeline_Overview.JPG "Generic experimental pipeline"
[TankStructure_Overview]: https://github.com/m053m716/ePhys_packages/blob/master/%2BorgExp/img/TankBlockHierarchy_Overview.JPG "Tank folder hierarchy"
[BlockStructure_Overview]: https://github.com/m053m716/ePhys_packages/blob/master/%2BorgExp/img/BlockStructure_Overview.JPG "Block file hierarchy"