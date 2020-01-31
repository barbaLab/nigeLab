function data = subsref_VectorData(obj,S)
%SUBSREF_VECTORDATA  Subscripted referencing for 'Hybrid' or 'MatFile' type
%
%  out = subsref_VectorData(obj,S);
%
%  obj : nigeLab.libs.DiskData object
%  S : struct or array struct from `substruct` built-in Matlab method

data = [];
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
data = getStreamsFromIndexing(obj,idx);
end