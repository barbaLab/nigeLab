# Block #

Class with methods for managing data from a single experimental recording.

## Table of Contents ##
[Block](#block-1)  
[blockGet](#blockget)  
[blockSet](#blockset)   
[list](#list)  
[loadClusters](#loadclusters)  
[loadSorted](#loadsorted)  
[loadSpikes](#loadspikes)  
[plotSpikes](#plotspikes)  
[plotWaves](#plotwaves)  
[syncBehavior](#syncbehavior)  
[takeNotes](#takenotes)  
[updateContents](#updatecontents)  
[updateID](#updateid)  

## Methods ##
The following are methods used by the Block object.

### Block ###
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
### blockGet ###
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
### blockSet ###
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
### list ###  
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
### loadClusters ###
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
### loadSorted ###
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
### loadSpikes ###
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
### plotSpikes ###
Plot all spike clusters for a single channel.  
```Matlab
% Makes figure with spikes for channel 9, returns true if successful.
channel = 9;
flag = block.plotSpikes(channel);  
``` 
---
### plotWaves ###
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
### syncBehavior ###
---
### takeNotes ###
View or Add Notes .txt to Block  
```Matlab
% Pull up NotesUI to view or enter notes
block.takeNotes;  
``` 
---
### updateContents ###
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
### updateID ###  
Modify Block string tokens that associate specific file types with Block data fields.  
```Matlab
fieldname = 'Filt'; % Update filtered data streams identifier
type = 'File';		 % For .mat files ('File' or 'Folder')
updatedValue = 'filtdata';	 % New token for Block to recognize
blockObj.updateID(fieldname,type,updatedValue); % Update file associations.
``` 
---	  