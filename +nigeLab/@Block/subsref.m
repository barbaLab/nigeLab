function varargout = subsref(blockObj,S)
% SUBSREF  Overload indexing operators for BLOCK (subscripted reference)
%
%  varargout = subsref(blockObj,S);
%
%  s: Struct returned by SUBSTRUCT function
%
%  Note that if a subscripted reference is made without a left-hand-side
%  assignment, then varargout automatically becomes the "maximum possible"
%  number of returned arguments.
%
%  data = blockObj.raw;   --> Return all channels raw data for blockObj
%                         ---> See nigeLab.defaults.Shortcuts() for
%                              shortcut configuration.
%
%  data = blockObj{'filt',3:5}; --> Return All filtered data samples from
%                                   channels 3:5
%
%  data = blockObj{'filt',3:5,1:100}; --> Return samples 1:100 from
%                                         channels 3:5
%
%  data = blockObjArray{'filt',3:5,1:100}; --> Return samples 1:100 from
%                                              channels 3:5 of each element
%                                              of blockObjArray. Note that
%                                              each block returns the array
%                                              as a separate cell array.

% Shrt: cell array of shortcuts
Shrt = nigeLab.defaults.Shortcuts();
switch S(1).type
   case '.'
      %% Handle '.' subscripted references
      % . means Block was referenced as __.Block.[method or property]
      % . also could reference something like __.Block.raw as a shortcut.
      
      idx = find(ismember(Shrt(:,1),S(1).subs),1,'first');
      % Shortcut case:
      if ~isempty(idx)
         % In this case, we need to deal with multiple block objects
         % slightly differently.
         if numel(blockObj) > 1
            varargout = cell(1,nargout);
            for i = 1:numel(blockObj)
               varargout{i} = subsref(blockObj(i),S);
            end
            return;
         end
         if numel(S) > 1
            iRow = subs2idx(S(2).subs{1},blockObj.NumChannels);
            iCol = subs2idx(S(2).subs{2},blockObj.Samples);
         else
            iRow = 1:blockObj.NumChannels;
            iCol = 1:blockObj.Samples;
         end
         
         out = nan(numel(S(2).subs{1}),numel(S(2).subs{2}));
         expr = sprintf('blockObj.%s;',Shrt{idx,2});
         
         for i = 1:numel(iRow)
            tmp = eval(sprintf(expr,iRow(i)));
            out(i,:) = tmp(iCol);
         end
         
         varargout{1} = out;
         return;
         
      % Standard case:
      else
         
         [varargout{1:nargout}] = builtin('subsref',blockObj,S);
         return;
      end
   
   case '()'
      %% Handle '()' subscripted references
      % () Means Blocks was referenced as __.Block() ... so it should be
      % used for dealing with Block arrays
      % Should always be dealt with in standard way:
      
      [varargout{1:nargout}] = builtin('subsref',blockObj,S);
      return;
      
   case '{}'
      %% Handle '{}' subscripted (shortcut) references
      % Move "shortcut" referencing onto {} indexing, since it isn't
      % being used anyways. Simplifies everything.
      % Should only use one level of subscripting
      if numel(S) > 1
         error(['nigeLab:' mfilename ':badSubscript'],...
            'Use of {} shortcuts does not support additional indexing.');
      end
      
      % Should only reference a single block at a time, since if the first
      % index is numeric, it would reference the channels.
      if ~isscalar(blockObj)
         varargout = cell(1,nargout);
         for i = 1:numel(blockObj)
            varargout{i} = subsref(blockObj(i),S);
         end
         return;
      end
      
      % Make sure that orientation of indexing vector is correct with
      % respect to the data.
      iShortcut = cellfun(@ischar,S(1).subs);
      if sum(iShortcut) < 1
         shortcutRef = Shrt{1,1}; % Default is 'raw' if not specified
         
      elseif sum(iShortcut) > 1
         shortcutRef = setdiff(S(1).subs(iShortcut),{':','end'});
         S(1).subs = setdiff(S(1).subs,{shortcutRef});
      else
         shortcutRef = S(1).subs{iShortcut};
         if numel(S(1).subs) > 1
            S(1).subs(iShortcut) = [];
         else
            S(1).subs{1} = ':';
         end
      end
      
      idx = ismember(shortcutRef,Shrt(:,1));
      if sum(idx) ~= 1
         error(['nigeLab:' mfilename ':badShortcutName'],...
            'Matched %g shortcut strings.',sum(idx));
      end
      shortField = Shrt{idx,3};

      nargsi=numel(S(1).subs);
      nargo = 1;

      
      switch nargsi
         case 0
            % If only given {'raw'}, for example, then return all samples 
            % of all channels
            varargout{nargo} = nan(blockObj.NumChannels,blockObj.Samples);
            for iCh = 1:blockObj.NumChannels
               varargout{nargo}(iCh,:) = ...
                  blockObj.Channels(iCh).(shortField).data(:);
            end
            return;

      
         case 1
            % If given {'raw',[1,5,19]} for example, or just {[1,5,19]}
            % Return all samples of those channels
            ch = subs2idx(S.subs{1});
            varargout{nargo} = nan(numel(ch),blockObj.Samples);
            
            for iCh = 1:numel(ch)
               varargout{nargo}(iCh,:) = ...
                  blockObj.Channels(ch(iCh)).(shortField).data(:);
            end
            return;
            
         case 2
            % In this case, {'raw',[1,5,19],1:100} or {[1,5,19],1:100} for
            % example. The sample indexing is also specified.
            ch = subs2idx(S.subs{1});
            samples = subs2idx(S.subs{2});
            varargout{nargo} = nan(numel(ch),numel(samples));
            for iCh = 1:numel(ch)
               varargout{nargo}(iCh,:) = ...
                  blockObj.Channels(ch(iCh)).(shortField).data(samples);
            end
            return;

         otherwise
            error(['nigeLab:' mfilename ':tooManySubscripts'],...
               'Too many subscripts (%g) used for shortcut reference.',nargsi);
      end

   otherwise
      %% Otherwise this is not a valid subsref 'type' reference
      error(['nigeLab:' mfilename ':badSubscript'],...
         'Not a valid indexing subscript type: %s',S(1).type);
end

      % Nested function for converting subs to index
      function idx = subs2idx(subs,n)
         % SUBS2IDX  Converts subscripts to indices
         
         if ischar(subs) % If it is a character, use keywords
            switch subs
               case ':'
                  idx = 1:n;
               case 'end'
                  idx = n;
               otherwise
                  error(['nigeLab:' mfilename ':badSubscript'],...
                     'Bad subscript keyword: %s',subs);
            end
            
         else % If it is numeric then check if it is in range
            if max(subs) > n
               error(['nigeLab:' mfilename ':subscriptOutOfRange'],...
                  'Subscript out of range (%g requested vs %g available)',...
                  max(subs),n);
            elseif min(subs) <= 0
               error(['nigeLab:' mfilename ':subscriptOutOfRange'],...
                  'Subscript is zero or less than zero.');
            end
            idx = subs;
         end
      end

end
