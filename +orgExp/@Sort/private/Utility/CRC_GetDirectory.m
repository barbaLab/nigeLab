function handles = CRC_GetDirectory(handles)
%% CRC_GETDIRECTORY  Allows selection of recording BLOCK
%
%  handles = CRC_GETDIRECTORY(handles);
%
%  --------
%   INPUTS
%  --------
%   handles :  Object containing parameter info for GUI.
%
%  --------
%   OUTPUT
%  --------
%   handles :  Updated handles object with DIR field (most important
%              update). Also gets recording name, spike directory, and
%              clustering version string.
%
% By: Max Murphy  v1.0  10/03/2017  Original version (R2017a)

%% GET DIRECTORY OF CRC MAIN FUNCTION
handles.func = which('CRC.m');
handles.srcpath = strsplit(handles.func,filesep);
handles.srcpath = strjoin(handles.srcpath(1:end-1),filesep);

%% POINT TO CRC_DEFS.MAT, WHICH POTENTIALLY HAS DEFAULT PATH INFO
def_file = fullfile(handles.SRCPATH,'CRC_lib','Extras','CRC_defs.mat');
dirfile = exist(def_file,'file');

%% IF THAT FILE DOESN'T EXIST, ALLOW IT TO BE SPECIFIED
if ~isfield(handles,'DIR')
   if dirfile~=0
      dirinfo = load(def_file,'defloc');
      handles.DIR = uigetdir(dirinfo.defloc,'Select BLOCK or CLUSTERS');
   else
      handles.DIR = uigetdir(handles.DEF_DIR,'Select BLOCK or CLUSTERS');
      dirinfo.defloc = pwd;
   end

   if handles.DIR==0
      error('No path selected. Script aborted.');
   end
   flag = true;
else
   flag = false;
end

%% IF BLOCK IS SPECIFIED, AND MULTIPLE CLUSTERS FOLDERS, ALLOW SELECTION
% In case the BLOCK is selected instead of CLUSTERS:
Ftemp = dir(fullfile(handles.DIR,['*' handles.IN_ID '*']));
if numel(Ftemp) > 0
   if numel(Ftemp) > 1
      ind = listdlg(...
         'Name', 'Multiple Possible Locations Detected',...
         'PromptString',...
         'Multiple Clusters folders detected. Select one:',...
         'SelectionMode','single',...
         'ListSize',[400 150], ...
         'ListString',{Ftemp.name}.');
      
      handles.DIR = fullfile(handles.DIR,Ftemp(ind).name);
   else
      handles.DIR = fullfile(handles.DIR,Ftemp.name);
   end
end

%% IF PARENT DIRECTORY HAS CHANGED FROM DEFAULT, CHECK TO SAVE IT
temp = strsplit(handles.DIR,filesep);
temp = strjoin(temp(1:end-2),filesep);

if flag
   if ~strcmp(temp,dirinfo.defloc)
      qans = questdlg('Remember directory info?','Shortcut',...
         'Yes','No','Yes');
      if strcmp(qans,'Yes')
         defloc = temp;
         save(def_file,'defloc','-v7.3');
      end
   end
end

%% GET RECORDING NAME
handles.recname = strsplit(handles.DIR,filesep);
handles.recname = strsplit(handles.recname{end},handles.DELIM);

%% GET "SPIKES" DIRECTORY
temp = strsplit(handles.DIR, filesep);
tempname = strsplit(temp{end},'_');
if strcmp(tempname{end-handles.SPKF_IND+1},'CAR')
    tempcomb = strjoin(tempname([1:(end-handles.SPKF_IND-1), ...
                        (end-handles.SPKF_IND+1):(end-1)]),handles.DELIM);
else
    tempcomb = strjoin(tempname([1:(end-handles.SPKF_IND), ...
                        (end-handles.SPKF_IND+2):(end-1)]),handles.DELIM);
end
tempcomb = strjoin([temp(1:end-1),tempcomb],filesep);
handles.SPKDIR = strjoin([tempcomb,{handles.SPKF_ID}],handles.DELIM);

%% GET CLUSTERING VERSION
handles.sc = tempname{end-handles.SC_IND};
handles.sc = strsplit(handles.sc,'-');
handles.sc = handles.sc{1};  

end