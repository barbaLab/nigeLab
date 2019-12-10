function varargout = subsref(blockObj,s)
% SUBSREF  Overload indexing operators for BLOCK (subscripted reference)
%
%  varargout = subsref(blockObj,s);
%
%  s: Struct returned by SUBSTRUCT function
%
%  Note that if a subscripted reference is made without a left-hand-side
%  assignment, then varargout automatically becomes the "maximum possible"
%  number of returned arguments.

if numel(blockObj) > 1
   varargout = cell(1,nargout);
   for i = 1:numel(blockObj)
      varargout{i} = subsref(blockObj(i),s);
   end
   return;
end

% Shrt: cell array of shortcuts
Shrt = nigeLab.defaults.Shortcuts();
switch s(1).type
   case '.'
      idx = find(ismember(Shrt(:,1),s(1).subs),1,'first');
      if ~isempty(idx)
         varargout = {};
         iRow = blockObj.subs2idx(s(2).subs{1},blockObj.NumChannels);
         iCol = blockObj.subs2idx(s(2).subs{2},blockObj.Samples);
         
         out = nan(numel(s(2).subs{1}),numel(s(2).subs{2}));
         expr = sprintf('blockObj.%s;',Shrt{idx,2});
         
         for i = 1:numel(iRow)
            tmp = eval(sprintf(expr,iRow(i)));
            out(i,:) = tmp(iCol);
         end
         
         varargout{1} = out;
         return;
      else
         
         [varargout{1:nargout}] = builtin('subsref',blockObj,s);
         return;
      end
   case '()'
      
      [varargout{1:nargout}] = builtin('subsref',blockObj,s);
      return;
      
      % Move "shortcut" referencing onto {} indexing, since it isn't
      % being used anyways. Simplifies everything.
   case '{}'
      if isscalar(blockObj) && ~isnumeric(s(1).subs{1})
         s(1).subs=[{1} s(1).subs];
      end
      if length(s) == 1
         nargsi=numel(s(1).subs);
         nargo = 1;
         
         
         iAll = 1:blockObj.NumChannels;
         if nargsi == 1
            if isnumeric(s.subs{1})
               Out = sprintf('blockObj.Channels(%d).Raw;\n',s.subs{1});
            elseif ismember(s.subs{1},Shrt(:,1))
               Out = sprintf('blockObj.Channels(%d).%s;\n',iAll,s.subs{1});
            else
               Out = sprintf('blockObj.Channels(%d).Raw;\n',iAll);
            end
         end
         
         if nargsi > 2
            
            
            if ischar( s(1).subs{2} )
               longCommand = sprintf(Shrt{strcmp(Shrt(:,1),s(1).subs{2}),2},s(1).subs{3});
               
            elseif isnumeric( s(1).subs{1} )
               if s(1).subs{1} > size(Shrt,1)
                  warning('Possible reference error.');
                  varargout{1} = builtin('subsref',blockObj,s);
                  return;
               end
               longCommand = sprintf(Shrt{s(1).subs{1},2},s(1).subs{2});
            end
            
            Out = sprintf('%s.%s',Out,longCommand);
            indx = ':';
            
            if nargsi > 3
               indx = sprintf('[%s]',num2str(s(1).subs{4}));
            end
            Out = sprintf('%s(%s)',Out,indx);
         end
         
         if size(Out,1) > 1
            varargout = cell(1,size(Out,1));
            for i = 1:size(Out,1)
               varargout{i} = eval(Out(i,:));
            end
         else
            [varargout{1:nargo}] = eval(Out);
         end

      else
         % Use built-in for any other expression
         [varargout{1:nargout}] = builtin('subsref',blockObj,s);
      end
   otherwise
      error('Not a valid indexing expression')
end
end
