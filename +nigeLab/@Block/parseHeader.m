function [header,fid] = parseHeader(blockObj,fid)
% PARSEHEADER  Parse header from recording file or from folder hierarchy
%
%  header = blockObj.parseHeader();
%
%  header  --  struct with fields that are derived from header, as
%              appropriate to blockObj.RecType and/or blockObj.RecSystem

% Check if second input arg is provided
if nargin < 2
   fid = [];
end

% Check input
if ~isscalar(blockObj)
   error(['nigeLab:' mfilename ':badInputType2'],...
          'blockObj must be scalar.');
end

% Always make sure to parse RecType FIRST
parseRecType(blockObj);

%
if isempty(blockObj.RecSystem)
   % blockObj.RecFile is a folder or who knows
   switch blockObj.RecType      
      case 'Matfile'
         header = blockObj.MatFileWorkflow.ReadFcn(blockObj.RecFile); 

      case 'nigelBlock'
         header = parseHierarchy(blockObj);
         
      otherwise
         blockObj.RecType='other';
         str = nigeLab.utils.getNigeLink('nigeLab.Block','parseRecType');
         fprintf(1,'\n\t\t-->\tSee also: %s <--\n',str);
         error(['nigeLab:' mfilename ':missingCase'],...
            ['[BLOCK/PARSEHEADER]: blockObj.FileExt == ''%s'' ' ...
            'not yet handled.'],blockObj.RecSystem.Name);
   end
else
   % blockObj.RecFile is actually the recording
   switch blockObj.RecSystem.Name
      case 'RHD'
         if nargin < 2
            [header,fid] = ReadRHDHeader(blockObj.RecFile,blockObj.Verbose);
         else
            header = ReadRHDHeader([],blockObj.Verbose,fid);
         end
      case 'RHS'
         if nargin < 2
            [header,fid] = ReadRHSHeader(blockObj.RecFile,blockObj.Verbose); 
         else
            header = ReadRHSHeader([],blockObj.Verbose,fid);
         end
      case 'TDT'
         header = ReadTDTHeader(blockObj.RecFile,blockObj.Verbose);
      otherwise
         error(['nigeLab:' mfilename ':missingCase'],...
            'blockObj.RecSystem.Name == ''%s'' not yet handled.',...
            blockObj.RecSystem.Name);
   end
end

header = nigeLab.utils.fixNamingConvention(header);

end