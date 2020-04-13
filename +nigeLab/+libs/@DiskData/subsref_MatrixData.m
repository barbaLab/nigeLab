function data = subsref_MatrixData(obj,S)
%SUBSREF_MATRIXDATA  Subscripted referencing for 'Event' .type_ files
%
%  data = subsref_MatrixData(obj,S);
%
%  obj : nigeLab.libs.DiskData object
%  S : struct or array struct from `substruct` built-in Matlab method

dataSize = size(obj);

switch S(1).type
   case '()'
      if numel(S) > 1 % b.S.Data(i1,i2).value
         propName = S(2).subs;
         numColumns = dataSize(2);
         % Return restricted "Hyperslab" we are writing to
         c = nigeLab.libs.DiskData.getEnumeratedColumn(propName,numColumns);
         offset = c(1) - 1;
         dims = [dataSize(1), numel(c)];
         [iRow,iCol] = nigeLab.libs.DiskData.parseRowColumnIndices(S(2),dims,offset);
      else
         [iRow,iCol] = nigeLab.libs.DiskData.parseRowColumnIndices(S,dataSize);
      end
      
   case '.'
      %e.g. blockObj.Channels(k).Spikes.value;
      propName = S(1).subs;
      c = nigeLab.libs.DiskData.getEnumeratedColumn(propName,dataSize(2));
      offset = c(1)-1;
      dims = [dataSize(1), numel(c)];
      if numel(S) > 1
         [iRow,iCol] = nigeLab.libs.DiskData.parseRowColumnIndices(S(2),dims,offset);  
      else
         switch lower(propName)
            case 'data'
               nigeLab.libs.DiskData.validateEventDataSize(c,dataSize(2),S.subs);
            case 'snippet'
               nigeLab.libs.DiskData.validateEventDataSize(c,dataSize(2)-4,S.subs);
            otherwise
               nigeLab.libs.DiskData.validateEventDataSize(c,1,S.subs);
         end
         iRow = 1:dataSize(1);
         iCol = c;
      end 
   otherwise
      error(['nigeLab:' mfilename ':InvalidSubscriptType'],...
         '%s-indexing is not supported for ''Event'' type DiskData',...
         S(1).type);
end

if nargout > 0 
   data = obj.getEventsFromIndexing(iRow,iCol);
end

end