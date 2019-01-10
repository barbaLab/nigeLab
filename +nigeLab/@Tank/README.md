# Tank #

Class with methods for managing data and metadata from a group of similar recordings for a particular experiment.

## Table of Contents ##
[Tank](#tank-1)  
[convert](#convert)  
[list](#list)  
[tankGet](#tankget)    
[tankSet](#tankset)  

## Methods ##   
The following are methods used by the Tank object.

### Tank ###   
Construct the Tank Class object.  
```Matlab
tank = orgExp.Tank; % Will prompt Tank selection UI
```  
---
### convert ###   
Convert raw acquisition files to Matlab Block file hierarchical structure.
```Matlab
% Begin conversion with current Tank properties
flag = tank.convert;
```
---
### list ###  
List all Blocks in the Tank.  
```Matlab
blockList = tank.list;
```  

```Matlab
% Alternative syntax for calling Class methods
blockList = list(tank);
```
---
### tankGet ###  
Get a specified property of the Tank. Similar to [tankSet](#tankset), the motivation for writing a method that is seemingly redundant with built-in Matlab features is to give the option for adding notifications or listeners during reads of specific Tank properties.
```Matlab
% For example, get Tank directory
prop = 'DIR';
propertyValue = tank.tankGet(prop);
```  

```Matlab
% Return a cell array of Tank properties
propertyValueArray_1xK = tankGet(tank,{'PropertyName1','PropertyName2',...,'PropertyNameK'});  
```

```Matlab
% Return all properties
propertyValueArray = tankGet(tank); 
```  
---
### tankSet ###  
Set a specified property of the Tank. Similar to [tankGet](#tankget), the motivation for writing a method that is seemingly redundant with built-in Matlab features is to give the option for adding notifications or listeners during writes to specific Tank properties.
```Matlab
% Returns true if property set successfully
setFlag = tank.tankSet('PropertyName',propertyValue); 
```  

```Matlab
% Can set a whole bunch of properties at once
setFlagArray_1xK = tankGet(tank,{'PropertyName1','PropertyName2',...,'PropertyNameK'},...
{propertyVal1,   propertyVal2,  ..., PropertyValK});  
```
---