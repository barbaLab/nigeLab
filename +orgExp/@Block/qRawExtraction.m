function flag = qRawExtraction()
%% QRAWEXTRACTION  Extract raw data files to BLOCK format using Isilon
%
%  b = orgExp.Block;
%  flag = qRawExtraction(b);
%
%  --------
%   OUTPUT
%  --------
%   flag       :     Returns true if conversion was successful.
%
%  By: Max Murphy v1.0  06/15/2018 Original version (R2017b)

%% PREPARE THE PROPER PATH NAMES TO GIVE TO ISILON
% Replace the leading string for the recording file on R:/Recorded_Data
recFile = [blockObj.UNC_Path{1}, ...
    blockObj.RecFile((find(blockObj.RecFile == filesep,1,'first')+1):end)];

% Replace the leading string for the processed data (P:/Processed_Data)
paths = blockObj.paths;
f = reshape(fieldnames(paths),1,numel(fieldnames(paths)));
for varName = f
   paths.(varName) = [blockObj.UNC_Path{2},...
      paths.(varName)((find(paths.(varName) == filesep,1,'first')+1):end)];
end

%% GET CURRENT VERSION INFORMATION WIP
attach_files = dir(fullfile(repoPath,'**'));
attach_files = attach_files((~contains({attach_files(:).folder},'.git')))';
dir_files = ~cell2mat({attach_files(:).isdir})';
ATTACHED_FILES = fullfile({attach_files(dir_files).folder},...
    {attach_files(dir_files).name})';

%% PARSE EXTRACTION DEPENDING ON RECORDING TYPE AND FILE EXTENSION
% If returns before completion, indicate failure to complete with flag
flag = false; 

switch blockObj.RecType
   case 'Intan'
      % Two types of Intan binary files: rhd and rhs
      switch blockObj.File_extension
         case '.rhs'
            flag = RHS2Block(blockObj,recFile,paths);
         case '.rhd'
            flag = RHD2Block(blockObj,recFile,paths);
         otherwise
            warning('Invalid file type (%s).',blockObj.File_extension);
            return;
      end
      
   case 'TDT'
      % TDT raw data already has a sort of "BLOCK" structure that should be
      % parsed to get this information.
      warning('%s is not yet supported, but will be added.',...
         blockObj.RecType);
      return;
      
   case 'mat'
      % Federico did you add this? I don't think there are plans to add
      % support for acquisition that streams to Matlab files...? -MM
      warning('%s is not yet supported, but will be added.',...
         blockObj.RecType);
      return;
      
   otherwise
      % Currently only working with TDT and Intan, the two types of
      % acquisition hardware that are in place at Nudo Lab at KUMC, and at
      % Chiappalone Lab at IIT.
      warning('%s is not a supported (case-sensitive).',...
         blockObj.RecType);
      return;
end

blockObj.updateStatus('Raw',true);

end