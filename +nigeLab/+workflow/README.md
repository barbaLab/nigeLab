# Convert #
Function handles to convert old workflow hierarchies to `nigeLab.Block` hierarchy prior to linking the data to a `nigeLab.Block` object.

## Input Arguments ##

Conversion functions take three arguments: the full filename (path + filename) of the `nigeLab.Block.RecFile` and `nigeLab.Block.AnimalLoc` properties that are set on object construction, and the `nigeLab.Block.BlockPars` property that is set based on what is configured in `nigeLab.defaults.Block`. 

The value for both `nigeLab.Block.RecFile` and `nigeLab.Block.AnimalLoc` can be set during object construction by specifying their `'Name',value` argument pairs manually:
```Matlab
blockObj = nigeLab.Block('RecFile','C:/Path/To/RecFile.filetype',...
'AnimalLoc','C:/Path/To/Converted/AnimalName');
```
If one or both settings are not specified in the constructor argument pairs, then the file selection GUI allows them to be selected manually. 

## ConvertOldBlockFcn ##

To select a conversion function, set the handle to the desired function in `defaults.Block` using the `ConvertOldBlockFcn` parameter, which typically takes an empty array. The function handle should take the format `@nigeLab.convert.(FunctionName)`, where `FunctionName` is the name of the function, which should be saved in the `+convert` "package" (this folder). 

## Writing a Conversion Function ##
The function should use the input `RecFile` to parse the existing (pre-extracted) file hierarchy and convert it into a format that matches the 1-file-per-channel format of `nigeLab`. The second argument, which is `AnimalLoc`, is a folder location where the converted outputs will be saved in block format. Use the function `rc2block` for reference in developing custom conversion for your workflow.