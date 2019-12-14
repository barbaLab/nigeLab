function parseRecType(blockObj)
% PARSERECTYPE   Figure out what kind of recording this is
%
%  blockObj.parseRecType();
%
%  Sets the 'RecType' property of blockObj

%%
switch blockObj.FileExt
   case '.rhd'
      blockObj.RecType='Intan';
      blockObj.RecSystem = nigeLab.utils.AcqSystem('RHD');
      return;
      
   case '.rhs'
      blockObj.RecType='Intan';  
      blockObj.RecSystem = nigeLab.utils.AcqSystem('RHS');
      return;
      
   case {'.Tbk', '.Tdx', '.tev', '.tnt', '.tsq'}
      blockObj.RecType='TDT';
      blockObj.RecSystem = nigeLab.utils.AcqSystem('TDT');
      return;
      
   case '.mat'
      blockObj.RecType = 'Matfile';
      return;
   
   case '.nigelBlock'
      blockObj.RecType = 'nigelBlock';
      return;
      
   case ''
      files = dir(nigeLab.utils.getUNCPath(blockObj.RecFile));
      files = files(~[files.isdir]);
      if isempty(files)
         blockObj.RecType = 'nigelBlock';
         return;
      end
      [~,~,ext] = fileparts(files(1).name);
      switch ext
         case {'.Tbk', '.Tdx', '.tev', '.tnt', '.tsq'}
            blockObj.RecType = 'TDT';
            blockObj.FileExt = ext;
            
         case '.nigelBlock'
            blockObj.RecType = 'nigelBlock';
            blockObj.FileExt = ext;
            
         case '.mat'
            blockObj.RecType = 'Matfile';
            blockObj.FileExt = '.mat';
            
         otherwise
            blockObj.RecType = 'other';
            blockObj.FileExt = ext;
            warning('Not a recognized file extension: %s',ext);

      end
      blockObj.RecFile = nigeLab.utils.getUNCPath(...
               fullfile(files(1).folder,files(1).name));
      return;
      
   otherwise
      blockObj.RecType='other';
      warning('Not a recognized file extension: %s',blockObj.FileExt);
      return;
end

end