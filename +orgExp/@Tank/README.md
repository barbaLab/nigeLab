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
blockList = list(tank);
```
---
### tankGet ###  
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
### tankSet ###  
Set a specified property of the Tank.
```Matlab
setFlag = tank.tankSet('PropertyName',propertyValue); % Returns true if property set successfully
```  

```Matlab
setFlagArray_1xK = tankGet(tank,{'PropertyName1','PropertyName2',...,'PropertyNameK'},...
{propertyVal1,   propertyVal2,  ..., PropertyValK});  
```
---