function flag = initData(sortObj,nigelObj)
%% INITDATA  Initialize data structure for Spike Sorting UI
%
%  flag = INITDATA(sortObj);
%  flag = INITDATA(sortObj,nigelObj);
%
%  --------
%   INPUTS
%  --------
%   sortObj    :     nigeLab.Sort class object that is under construction.
%
%  nigelObj    :     (Optional) Can be either:
%                       -> 1 or more nigeLab.Block objects
%                       -> 1 or more nigeLab.Animal objects
%                       -> 1 nigeLab.Tank object
%
% By: Max Murphy  v3.0    01/07/2019 Port to object-oriented architecture.
%                 v2.0    10/03/2017 Added ability to handle multiple input
%                                    probes with redundant channel labels.
%                 v1.0    08/18/2017 Original version (R2017a)

%% PARSE INPUT
flag = false;
if nargin > 1
   % Parse input argument type
   switch class(nigelObj(1))
      case 'nigeLab.Block'
         if ~parseBlocks(sortObj,nigelObj)
            warning('Could not parse nigeLab.Block objects.');
            return;
         end
      case 'nigeLab.Animal'
         if ~parseAnimals(sortObj,nigelObj)
            warning('Could not parse nigeLab.Animal objects.');
            return;
         end
      case 'nigeLab.Tank'
         if numel(nigelObj) > 1
            warning('Only 1 nigeLab.Tank object can be scored at a time.');
            return;            
         else
            if ~parseAnimals(sortObj,nigelObj.Animals)
               warning('Could not parse nigeLab.Animal objects.');
               return;
            end
         end         
      otherwise
         warning(['%s is an invalid input type.\n' ...
                  'Must be a Block, Animal, or Tank object array.'],...
                  class(nigelObj(1)));
         return;
   end
   
else   
   [fName,pName,~] = uigetfile(sortObj.pars.InFileFilt,...
                               sortObj.pars.InFilePrompt,...
                               sortObj.pars.InFileDefDir,...
                               'MultiSelect','on');
                               
   if iscell(fName) % Load array and run using recursion
      nigelObjArray = [];
      for ii = 1:numel(fName)
         in = load(fullfile(pName,fName{ii}));
         f = fieldnames(in);
         nigelObjArray = [nigelObjArray; in.(f{1})]; %#ok<AGROW>
      end
      flag = initData(sortObj,nigelObjArray);
      return;
      
   else % Otherwise, just load it and run init using recursion
      in = load(fullfile(pName,fName));
      f = fieldnames(in);
      flag = initData(sortObj,in.(f{1}));
      return;
   end
   
end

%% INITIALIZE SPK, CLU, AND ORIG PROPERTY STRUCTS
% Create store for all concatenated spike info
sortObj.spk.spikes = cell(sortObj.Channels.N,1); % Spike waveforms
sortObj.spk.feat = cell(sortObj.Channels.N,1); % Spike dimreduced features
sortObj.spk.class = cell(sortObj.Channels.N,1);% Spike assigned classes
sortObj.spk.tag = cell(sortObj.Channels.N,1);  % Spike qualitative tags
sortObj.spk.ts = cell(sortObj.Channels.N,1);   % Spike times
sortObj.spk.block = cell(sortObj.Channels.N,1);% Original block for spikes
sortObj.spk.fs = sortObj.Blocks(1).SampleRate; % Sample rate for all blocks

fprintf(1,'\nImporting spike info for %d Blocks...000%%\n',...
   numel(sortObj.Blocks));
for iCh = sortObj.Channels.Mask % get # clusters per channel   
   % Get all associated spike data for that channel, from all blocks
   [sortObj.spk.spikes{iCh},...
    sortObj.spk.feat{iCh},...
    sortObj.spk.class{iCh},...
    sortObj.spk.tag{iCh},...
    sortObj.spk.ts{iCh},...
    sortObj.spk.block{iCh}] = getAllSpikeData(sortObj,iCh);  
 
   fraction_done = 100 * (iCh / sortObj.Channels.N);
   fprintf(1,'\b\b\b\b\b%.3d%%\n',floor(fraction_done))
end


% Create store for previous classes for "UNDO" and "RESET"
sortObj.prev = sortObj.spk.class;
sortObj.orig = sortObj.spk.class;

flag = true;
end