function subsasgn_VectorData(obj,S,data)
%SUBSASGN_VECTORDATA  Subscripted assignment method for 'MatFile'/'Hybrid'
%
%  subsasgn_VectorData(obj,S,data);
%
%  Protected method that deals with vector data, such as is saved for the
%  'MatFile' or 'Hybrid' data types.
%
%  See Also: nigeLab.libs.DiskData/subsasgn


switch S(1).type
   case '()'
      idx = nigeLab.libs.DiskData.parseColumnIndices(S(1));
   case '.'
      if numel(S) > 1
         idx = nigeLab.libs.DiskData.parseColumnIndices(S(2));
      else % Otherwise this is just like, .data or something
         if strcmp(S.subs,'data')
            idx = inf;
         else
            idx = [];
         end
      end
   otherwise
      error(['nigeLab:' mfilename ':InvalidSubscriptType'],...
         '%s-indexing is not supported for ''%s'' type DiskData',...
         S(1).type,obj.type_);
end
setStreamsFromIndexing(obj,idx,data);

end