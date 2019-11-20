function flag = doRawExtraction(blockObj)
%% CONVERT  Convert raw data files to Matlab TANK-BLOCK structure object
%
%  b = nigeLab.Block;
%  flag = doRawExtraction(b);
%
%  --------
%   OUTPUT
%  --------
%   flag       :     Returns true if conversion was successful.
%
% By: MAECI 2018 collaboration (Federico Barban & Max Murphy)

%% PARSE EXTRACTION DEPENDING ON RECORDING TYPE AND FILE EXTENSION
% If returns before completion, indicate failure to complete with flag
flag = false;

nigeLab.utils.checkForWorker('config');

if ~genPaths(blockObj)
   warning('Something went wrong when generating paths for extraction.');
   return;
end

%% Check for MultiAnimals
% More than one animal can be recorded simultaneously in one single file. 
% Thi eventuality is explicitely handled here. The init process looks for a
% special char string in the block ID (defined in defaults), if detected
% the flag ManyAnimalsLinkedBlocks is set true. 
% The function splitMultiAnimals prompts the user to assign channels and
% other inputs to the different animals. When this is done two or ore child
% blocks are initialized and stored in the ManyAnimalsLinkedBlocks field.
 
% flag = [blockObj.ManyAnimals ~isempty(blockObj.ManyAnimalsLinkedBlocks)];
% if all(flag == [false true]) % child block. Call rawExtraction on father
%     blockObj.ManyAnimalsLinkedBlocks.doRawExtraction;
% elseif all(flag == [true false]) % father block without childern. Call splitMultiAnimals
%     blockObj.splitMultiAnimals;
% elseif all(flag == [true true])  % father block with children. Go on with extraction and move files at the end
%     ManyAnimals = true;
% else
% end
%% extraction
switch blockObj.RecType
   case 'Intan'
      % Intan extraction should be compatible for both the *.rhd and *.rhs
      % binary file formats.
      flag = blockObj.intan2Block;
      
   case 'TDT'
      % TDT raw data already has a sort of "BLOCK" structure that should be
      % parsed to get this information.
      fprintf(1,' \n');
      nigeLab.utils.cprintf('*Red','\t%s extraction is still ',blockObj.RecType);
      nigeLab.utils.cprintf('Magenta-', 'WIP\n');
      nigeLab.utils.cprintf('*Comment','\tIt might take a while...\n\n');
      flag = tdt2Block(blockObj);
      
   case 'Matfile' % "FLEX" format wherein source is an "_info.mat" file
      % -- Primarily for backwards-compatibility, or for if the extraction
      %     has already been performed, but some error or something
      %     happened and you no longer have the 'Block' object, but you
      %     would like to associate the 'Block' with that file structure
      %
      % Federico did you add this? I don't think there are plans to add
      % support for acquisition that streams to Matlab files...? -MM
      %
      % Yup, I thought this could be a good way to ensure backwards
      % compatibility for already acquired and extracted files. Also for
      % other possible future users     -FB
      %
      % Good job. -MM
      
      flag = blockObj.MatFileWorkflow.ExtractFcn(blockObj);
   otherwise
      % Currently only working with TDT and Intan, the two types of
      % acquisition hardware that are in place at Nudo Lab at KUMC, and at
      % Chiappalone Lab at IIT.
      %
      % To add in the future (?):
      %  
      %  * All formats listed on open-ephys "data formats"
        
      warning('%s is not a supported (case-sensitive).',...
         blockObj.RecType);
      return;
end

%%
blockObj.updateStatus('Raw',true);
blockObj.save;
end