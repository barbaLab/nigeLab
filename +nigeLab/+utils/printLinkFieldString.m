function printLinkFieldString(fieldType,field)
%% PRINTLINKFIELDSTRING  Standardized Command Window print command for link
%
%  nigeLab.utils.PRINTLINKFIELDSTRING(fieldType,field);
%
%  fieldType: {'Channels', 'Streams', 'Events', 'Videos', or 'Meta'}
%  field: Member of blockObj.Fields;

%%

nigeLab.utils.cprintf('Text','\nLinking ');
nigeLab.utils.cprintf('Keywords',fieldType);
nigeLab.utils.cprintf('Text',' field: %s ...000%%\n',field);

end