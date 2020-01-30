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
        % . also could reference something like __.Block.Raw as a shortcut.
        % All Channels fields are adressable this way.
        %       idx = find(ismember(Shrt(:,1),S(1).subs),1,'first');
        Ffields = blockObj(1).Pars.Block.Fields;
        idx = strcmpi(Ffields,S(1).subs);
        % Shortcut case:
        if any(idx)
            % In this case, we need to deal with multiple block objects
            % slightly differently.
            if numel(blockObj) > 1
                varargout = arrayfun(@(x) subsref(x,S),blockObj,...
                    'UniformOutput',false);
                return;
            end
            
            if numel(S)<2
                S(2).type = '()';
                S(2).subs = {':'};
            end
            
            if numel(S(2).subs) > 1
                Chans = blockObj.Channels(S(2).subs{1});
                S(2).subs(1) = [];
            else
                Chans = blockObj.Channels;
            end
            out = arrayfun(@(x) subsref(x.(Ffields{idx}),S(2)),Chans,'UniformOutput',false);
            varargout{1} = cat(1,out{:});
            return;
            
 
        else
            % Standard case:
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
      
      %%% Input 1 defines which shortut we're going to use. It needs t obe
      %%% either a char that matches the fieldname in the shortcuts struct
      %%% or an index
       subs = S(1).subs;
      if ischar(subs{1})
          shrtName = subs{1};
          shrtStruct = Shrt.(shrtName);
      elseif isnumeric(subs{1}) && isscalar(subs{1})
          ff = fieldnames(Shrt);
          shrtStruct = Shrt.(ff{subs{1}});
      else
          error(['nigeLab:' mfilename ':badSubscriptIndex'],...
              'Invalid first input.');
      end
      
      %%% Now we know which shortcut we're using. We need to define the
      %%% number of inputs needed and construct the subsref struct
      
      NInputNeeded = sum(shrtStruct.indexable); % this gives us the number 
                                                % of indexble component in 
                                                % the shortcut ie the 
                                                % number of inputs needed
     if NInputNeeded > 2 
         error(['nigeLab:' mfilename ':unsupported'],...
                  ['Unsupported shortcut. Nigelab is supporting only shortcuts up to a depth of two levels.\n',...
                  'I.e. with at most two indexable subfields.'],...
                  numel(subs),shrtName);
     end
      
      subs = S(1).subs(2:end);
      if numel(subs) < NInputNeeded
          error(['nigeLab:' mfilename ':notEnoughSubscripts'],...
                  'Not enough subscripts (%g) used for the selcted shortcut (%s).',numel(subs),shrtName);
      elseif numel(subs) > NInputNeeded
          error(['nigeLab:' mfilename ':tooManySubscripts'],...
                  'Too many subscripts (%g) used for the selcted shortcut (%s).',numel(subs),shrtName);
      end
      
      % Let's gather the objects targeted by the shortcut
      substractInArgs = {};
      for ii = 1:numel(shrtStruct.subfields)
          substractInArgs = [substractInArgs, {'.'} ,shrtStruct.subfields(ii)];
          if shrtStruct.indexable(ii)
              substractInArgs = [substractInArgs, {'()' subs(1)}];
              break;
          else
              ... Do nothig, go on with the loop
          end
      end
      
      TargetObj = subsref(blockObj,substruct(substractInArgs{:}));
      
      subs = subs(end);     % we imposed only 2 levels of depth, this means subs has to be only one after this
      if iscell(subs{1}),subs = subs{end};end
      shrtStruct.subfields(1:ii) = [];
      shrtStruct.indexable(1:ii) = [];
      
      
      % Let's create the subsref structs
      % Again we need to gahter the substruct info from the shortcut
      
      substractInArgs = {};
      for ii = 1:numel(shrtStruct.subfields)
          substractInArgs = [substractInArgs, {'.'} ,shrtStruct.subfields(ii)];
          if shrtStruct.indexable(ii)
              substractInArgs = [substractInArgs, {'()'}];
              break;
          else
              ... Do nothig, go on with the loop
          end
      end
      
%        but this time we add the indexes after the () in a different way
      for jj = 1:numel(subs)
          if ~checkInputArgsCoherence(numel(TargetObj),subs{jj})
              % check that dimensions are coherent between inputs
              error(['nigeLab:' mfilename ':badSubscriptReference'],...
                   'Dimensions of arrays being concatenated are not consistent.');
          end
          
          switch checkSamplesInput(subs{jj})
              % habldes cell, not cell nonsense with substruct
              case {'numeric','semicolon'}                 
                   s(jj,:) = substruct(substractInArgs{:},subs(jj));
              case 'cell'
                  s(jj,:) = substruct(substractInArgs{:},subs{jj});
              otherwise
                  error(['nigeLab:' mfilename 'badSubscript'],...
                       'Bad subscript number 3. %ss are not supported.',class(subs))
          end
         
      end
      index = ones(1,length(TargetObj)).*(1:size(s,1));
      varargout = {arrayfun(@(x,idx) subsref(x,s(idx,:)),TargetObj,index,'UniformOutput',false)};


   otherwise
      %% Otherwise this is not a valid subsref 'type' reference
      error(['nigeLab:' mfilename ':badSubscript'],...
         'Not a valid indexing subscript type: %s',S(1).type);
end
   
end


function value = checkSamplesInput(subs)
% CHECKSAMPLESINPUT helper function to check inputs
    if (isnumeric(subs) && isvector(subs))
        value = 'numeric';
    elseif iscell(subs) && all(cellfun(@(x) strcmp(checkSamplesInput(x),'numeric'), subs))
        value = 'cell';
    elseif ischar(subs) && strcmp(subs, ':')
        value = 'semicolon';
    elseif ischar(subs) && strcmp(subs,'end')
        value = 'end';
    else
        value = 'invalid';
    end

end

function value = checkInputArgsCoherence(prevElNum,args)
value = isnumeric(args) || (iscell(args) && (numel(args) == prevElNum));
end