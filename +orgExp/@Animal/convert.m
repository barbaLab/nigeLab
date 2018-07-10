function flag = convert(animalObj)
%% CONVERT  Convert raw data files to Matlab TANK-BLOCK structure object
B=animalObj.Blocks;
for ii=1:numel(B)
    blockObj=B(ii);
    switch blockObj.RecType
        case 'Intan'
            
            switch blockObj.File_extension
                case '.rhs'
                    RHS2Block(blockObj)
                case '.rhd'
                    RHD2Block(blockObj)
                otherwise
                    error('Invalid file type (%s).',blockObj.File_extension);
            end
            
            fprintf(1,['complete.' newline]);
            
            
        case 'TDT'
            fprintf(1,'Unsupported yet')
        case 'mat'
            fprintf(1,'Unsupported yet')
        otherwise
            error('%s is not a supported acquisition system (case-sensitive).');
    end
end
flag = true;
end