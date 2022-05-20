function varargout = subsref(stream,S)
%SUBSREF  Redefined subscripted reference: .data and .t are special
%
%  varargout = subsref(stream,S);
%
%  --> Redefines subscripting for public "properties": 
%     '.data' and '.t'
%  --> Otherwise, subscripted references remain identical

idx = find(strcmp({S.type},'.'));
dataCase = '';
SPECIAL = {'data','t'};
for i = 1:numel(idx)
   if isempty(S(idx(i)).subs)
      continue;
   end
   caseIndex = ismember(SPECIAL,lower(S(idx(i)).subs));
   if sum(caseIndex)==1
      dataCase = SPECIAL{caseIndex};
      break;
   end
end

% If not '.data' or '.t', then use normal reference
if isempty(dataCase)
   if nargout > 0
      [varargout{1:nargout}] = builtin('subsref',stream,S);
   else
      mc = ?nigeLab.libs.nigelStream;
      if any(ismember({S(idx).subs},{mc.PropertyList.Name}))
         out = builtin('subsref',stream,S);
         disp(out);
         clear out;
      else
         builtin('subsref',stream,S);
      end
   end
   return;
else
   switch dataCase % Enumerate the .DiskData that is being referenced
      case 'data'
         x = {stream.Data_};
         fun = @(streamObj,data)applyDataScaling(streamObj,data);
      case 't'
         x = {stream.Time_};
         fun = @(streamObj,t)applyTimeOffset(streamObj,t);
      otherwise
         error(['nigeLab:' mfilename ':BadConfig'],...
            '[NIGELSTREAM/SUBSREF]: %s is not yet configured in subsref.',...
            dataCase);
   end
end

% Otherwise, output depends on where it was accessed
switch idx(i)
   case 1 % stream.data or stream.t
      streamSubs = 1:numel(stream);
   case 2 % stream(streamIdx).data or stream(streamIdx).t
      if ~strcmp(S(1).type,'()')
         error(['nigeLab:' mfilename 'BadSubscript'],...
            ['[NIGELSTREAM/SUBSREF]: Can only use '...
            'stream.%s or stream(idx).%s (stream[%s].%s is invalid)'],...
            dataCase,dataCase,S(1).type,dataCase);
      end
      streamSubs = getValidatedArrayIndexing(S(1),numel(stream));
   otherwise
      error(['nigeLab:' mfilename 'BadSubscript'],...
         ['[NIGELSTREAM/SUBSREF]: Can only use '...
         'stream.%s or stream(idx).%s\n'],...
         dataCase,dataCase);
end

% Parse the array indexing for "samples"
k = numel(S) - idx(i); % Where is .data or .t relative to full expression
nData = cellfun(@length,x); % Max # samples
switch k
   case 1 % Then should be ___.data(idx) [return specific]
      if ~strcmp(S(idx(i)+1).type,'()')
         error(['nigeLab:' mfilename 'BadSubscript'],...
            ['[NIGELSTREAM/SUBSREF]: Can only use '...
            '__.%s(idx) (__.%s[%s] is invalid)'],...
            dataCase,dataCase,S(idx(i)+1).type);
      end
      s = S(idx(i)+1);
      sampleSubs = arrayfun(@(n)getValidatedArrayIndexing(s,n),nData,...
         'UniformOutput',false);
   case 0 % Then reference should be __.data [return all .data or .t]
      sampleSubs = arrayfun(@(n)1:n,nData,'UniformOutput',false);
   otherwise % Then it is like __.data(idx).__ or __.data(idx)() or whatever
      error(['nigeLab:' mfilename 'BadSubscript'],...
         ['[NIGELSTREAM/SUBSREF]: Can only use '...
         '__.%s or __.%s(idx) (__.%s(idx)[%s] is invalid)'],...
         dataCase,dataCase,dataCase,S(idx(i)+k).type);

end

% Iterate on all stream objects and pass values to output
varargout = cell(1,nargout);
for i = 1:nargout
   iCur = streamSubs(i);
   y = x{iCur}(sampleSubs{iCur}); % Get reduced subset of stream
   varargout{i} = fun(stream(iCur),y); % apply scaling or offset
end

% Helper function to return "validated" array subscript arguments
   function subs = getValidatedArrayIndexing(S,nMax)
      %GETVALIDATEDARRAYINDEXING  Returns "validated" array subscripts
      %
      %  subs = getValidatedArrayIndexing(S,nMax);
      
      if numel(S.subs) > 1
         if iscell(S.subs)
            sub = S.subs{1};
         else
            sub = S.subs;
         end
         if isnumeric(sub)
            if S.subs~=1
               error(['nigeLab:' mfilename 'BadSubscript'],...
                  ['[NIGELSTREAM/SUBSREF]: Invalid indexing dimensions. '...
                  '(If multiple subscript indices provided, first '...
                  'dimension MUST be 1)\n']);
            else
               subs = S.subs{2};
            end
         else % Otherwise it was ':' used as first index with additional index
            error(['nigeLab:' mfilename 'BadSubscript'],...
               ['[NIGELSTREAM/SUBSREF]: Invalid indexing dimensions. '...
               '(If multiple subscript indices provided, first '...
               'dimension MUST be 1)\n']);
         end
      elseif numel(S.subs) == 1
         if iscell(S.subs)
            subs = S.subs{1};
         else
            subs = S.subs;
         end
      else
         subs = [];
         return;
      end
      if ischar(subs)
         if strcmp(subs,':')
            subs = 1:nMax;
         end
      end
   end

end