

%% OpenCV 3.4.1
input = fullfile(fileparts(mfilename('fullpath')),'simpleVideoReader.cpp');
output = fullfile(fileparts(mfilename('fullpath')),'simpleVideoReader');
opencvpath = fileparts(mfilename('fullpath'));
opencvIpath = fullfile(opencvpath,'include');
if ~exist(fullfile(opencvIpath,'opencv2'),'dir')
    unzip(fullfile(opencvIpath,'opencv2.zip'), opencvIpath)
end
opencvLpath = fullfile(opencvpath,'lib');
debugFlag = '-g';
mex( '-O','-R2017b', ...
['-I' opencvIpath],                                                         ...
['-L' opencvLpath],                                                         ...
'-lopencv_world3413',                                                      ...                                                       ...
input,                                                                      ...
'-output', output)

%% flags examples
% COMPILER="nvcc"
%       COMPFLAGS="-gencode=arch=compute_20,code=sm_20 -gencode=arch=compute_30,code=sm_30 -gencode=arch=compute_35,code=sm_35 -gencode=arch=compute_50,code=&#92;&quot;sm_50,compute_50&#92;&quot; --compiler-options=/c,/GR,/W3,/EHs,/nologo,/MD"
%       COMPDEFINES="--compiler-options=/D_CRT_SECURE_NO_DEPRECATE,/D_SCL_SECURE_NO_DEPRECATE,/D_SECURE_SCL=0,$MATLABMEX"
%       MATLABMEX="/DMATLAB_MEX_FILE"
%       OPTIMFLAGS="--compiler-options=/O2,/Oy-,/DNDEBUG"
%       INCLUDE="-I&quot;$MATLABROOT\extern\include&quot; -I&quot;$MATLABROOT\simulink\include&quot;"
% 
%   DEBUGFLAGS="--compiler-options=/Z7"

%% OpenCV 4.5.1
% input = fullfile(fileparts(mfilename('fullpath')),'simpleVideoReader.cpp');
% output = fullfile(fileparts(mfilename('fullpath')),'simpleVideoReader');
% opencvpath = 'C:\opencv\build';
% opencvIpath = fullfile(opencvpath,'include');
% opencvLpath = fullfile(opencvpath,'x64\vc15\lib');
% 
% mex( '-O', '-g','-R2017b', ...
% ['-I' opencvIpath],                                                         ...
% ['-L' opencvLpath],                                                         ...
% '-lopencv_world451',                                                      ...                                                        ...
% input,                                                                      ...
% '-output', output)
