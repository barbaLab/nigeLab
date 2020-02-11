function obj = saveobj(obj)
%SAVEOBJ Save filter for VideoReader objects.
%
%    OBJ = SAVEOBJ(OBJ) is called by SAVE when an VideoReader object is 
%    saved to a .MAT file. The return value, OBJ, is subsequently 
%    written by SAVE to a MAT file.  

%    Dinesh Iyer
%    Copyright 2014-2015 The MathWorks, Inc.

% Save constructor arg for load.
obj.LoadArgs{1} = fullfile(obj.Path, obj.Name);

if obj.IsStreamingBased
    currentTime = obj.CurrentTime;
    obj.LoadArgs{2} = currentTime;
end

end

