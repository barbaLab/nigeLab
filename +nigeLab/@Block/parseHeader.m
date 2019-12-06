function header = parseHeader(blockObj)
% PARSEHEADER  Parse header from recording file or from folder hierarchy
%
%  header = blockObj.parseHeader();
%
%  header  --  struct with fields that are derived from header, as
%              appropriate to blockObj.RecType and/or blockObj.RecSystem

% Check input
if ~isscalar(blockObj)
   error(['nigeLab:' mfilename ':badInputType2'],...
          'blockObj must be scalar.');
end

% Always make sure to parse RecType FIRST
blockObj.parseRecType();

%
if isempty(blockObj.RecSystem)
   % blockObj.RecFile is a folder or who knows
   switch blockObj.RecType      
      case 'Matfile'
         header = blockObj.MatFileWorkflow.ReadFcn(blockObj.RecFile); 

      case 'nigelBlock'
         header = blockObj.parseHierarchy();
         
      otherwise
         blockObj.RecType='other';
         str = nigeLab.utils.getNigeLink('nigeLab.Block','parseRecType');
         fprintf(1,'\n\t\t-->\tSee also: %s <--\n',str);
         error(['nigeLab:' mfilename ':missingCase'],...
            'blockObj.FileExt == ''%s'' not yet handled.',...
            blockObj.RecSystem.Name);
   end
else
   % blockObj.RecFile is actually the recording
   switch blockObj.RecSystem.Name
      case 'RHD'
         header = ReadRHDHeader('NAME',blockobj.RecFile,...
                                'VERBOSE',blockObj.Verbose);
      case 'RHS'
         header=ReadRHSHeader('NAME',blockObj.RecFile,...
                              'VERBOSE',blockObj.Verbose); 
      case 'TDT'
         header=ReadTDTHeader('NAME',blockObj.RecFile,...
                              'VERBOSE',blockObj.Verbose);
      otherwise
         error(['nigeLab:' mfilename ':missingCase'],...
            'blockObj.RecSystem.Name == ''%s'' not yet handled.',...
            blockObj.RecSystem.Name);
   end
end

end