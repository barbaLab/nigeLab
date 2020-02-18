function subsasgn_MatrixData(obj,S,data)
%SUBSASGN_MATRIXDATA  Subscripted assignment method for .type_ == 'Event'
%
%  subsasgn_MatrixData(obj,S,data);
%
%  Protected method that deals with matrix data, such as is saved for
%  'Event' data type.
%
%  %%%%%%%%%%%%%%%%%%%%%
%  Cases that can happen
%  %%%%%%%%%%%%%%%%%%%%%
%     For the following, assume that b.S.Data references a DiskData object
%     that is a struct field of some struct array (as would typically be
%     the case for nigeLab.Block.Channels, .Events, or .Streams property,
%     where b is the Block, S is the intermediate struct array property,
%     and Data is the actual DiskData object)
%
%     NOTE: b.S.Data itself will never be an array object! Therefore we
%     should assume that a reference such as b.S.Data(:) is not indexing
%     into an array of DiskData objects, but rather into the .diskfile_
%
%     Using '()' indexing with "full-rank" (both subscript arguments given)
%     >> b.S.Data(indexing_1,indexing_2) = data;
%        --> Simplest case, data is fully assigned and there are two sets
%              of numeric subscripts.
%        --> Note that we should pay attention to the CLASS of indexing_1
%            and indexing_2
%
%     Using '()' indexing with a single indexing subscripted argument
%     >> b.S.Data(indexing) = data;
%        --> We know this is a Matrix type, so we will just assume indexing
%              works as normally for a Matlab matrix in this case.
%
%     Using 'dot'-indexing:
%     >> b.S.Data.propName = data;
%        --> A couple of things could happen:
%           * This could be a reference to a DiskData property
%              + (e.g  .size_)
%           * This could be a reference to a DiskData shortcut property
%              + (e.g  .ts)
%
%     And the "most complicated" case:
%     >> b.S.Data.propName(indexing) = data;
%
%     This should be treated equivalently to:
%     >> b.S.Data(indexing).propName = data;
%
%     This is due to the assumption that we are only ever using a scalar
%     DiskData object
%
%
%  See Also: nigeLab.libs.DiskData/subsasgn

% Get the size of data on the disk
dataSize = size(obj);
zeroDims = dataSize==0;
if any(zeroDims)
   error(['nigeLab:' mfilename ':BadInit'],...
      '[DISKDATA]: Data extent is zero in dim-%g\n',find(zeroDims));
end

nigeLab.libs.DiskData.validateEventDataRange(data,@isnumeric);

switch S(1).type
   case '()' % b.S.Data(i1,i2)
      if numel(S) > 1 % b.S.Data(i1,i2).value
         propName = S(2).subs;
         numColumns = dataSize(2);
         % Return restricted "Hyperslab" we are writing to
         c = obj.getEnumeratedColumn(propName,numColumns);
         offset = c(1) - 1;
         dims = [dataSize(1), numel(c)];
         [iRow,iCol] = obj.parseRowColumnIndices(S(2),dims,offset);
      else
         [iRow,iCol] = obj.parseRowColumnIndices(S,dataSize);
      end
      
   case '.'
      n = dataSize(1);
      if numel(S)==1
         if (size(data,1) ~= n) && (numel(data)>1)
            error(['nigeLab:' mfilename ':ImproperAssignment'],...
               ['Input data number of rows (%d) ' ...
               'does not match existing file (%d).'],...
               size(data,1),n);
         end
      end
      
      propName = S(1).subs;
      c = obj.getEnumeratedColumn(propName,dataSize(2));
      offset = c(1)-1;
      dims = [n, numel(c)];
      if numel(S) > 1
         [iRow,iCol] = obj.parseRowColumnIndices(S(2),dims,offset);
      else
         switch lower(propName)
            case 'data'
               nigeLab.libs.DiskData.validateEventDataSize(c,dataSize(2),S.subs);
            case 'snippet'
               nigeLab.libs.DiskData.validateEventDataSize(c,dataSize(2)-4,S.subs);
            otherwise
               nigeLab.libs.DiskData.validateEventDataSize(c,1,S.subs);
         end
         iRow = 1:n;
         iCol = c;
      end 
   otherwise
      error(['nigeLab:' mfilename ':InvalidSubscriptType'],...
         '%s-indexing is not supported for ''Event'' type DiskData',...
         S(1).type);
      
end

setEventsFromIndexing(obj,iRow,iCol,data);

end