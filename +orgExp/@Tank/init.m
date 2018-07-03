function init(tankObj)
%% INIT Initialize TANK object
%
%  tankObj.INIT;
%
%  By: Max Murphy v1.0  06/14/2018 Original version (R2017b)
 
%% PARSE NAME AND SAVE LOCATION
tankObj.Name = strsplit(tankObj.DIR,filesep);
tankObj.Name = tankObj.Name{end};

if isempty(tankObj.SaveLoc)
   tankObj.SaveLoc = fullfile(tankObj.DefaultSaveLoc,...
                              tankObj.RecType);
   tankObj.setSaveLocation;
   
   if exist(fullfile(tankObj.SaveLoc,tankObj.Name),'dir')==0
      mkdir(fullfile(tankObj.SaveLoc,tankObj.Name));
      tankObj.ExtractFlag = true;
   else
      tankObj.ExtractFlag = false;
   end
end

%% DO CONVERSION OR CHECK AND CREATE METADATA FOR TANK
if tankObj.ExtractFlag
   tankObj.convert(tankObj.CheckBeforeConversion);
else
   tankObj.createMetadata;
end


end