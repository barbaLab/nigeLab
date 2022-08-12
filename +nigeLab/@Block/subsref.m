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
if all(size(blockObj)==[0,0])
    varargout = {[]};
   return; 
end
switch S(1).type
   case '.' % Handle '.' subscripted references
      % . means Block was referenced as __.Block.[method or property]
      % . also could reference something like __.Block.Raw as a shortcut.
      % All Channels fields are adressable this way.
      %       idx = find(ismember(Shrt(:,1),S(1).subs),1,'first');
      fixed_fields = blockObj(1).Pars.Block.Fields;
      Exceptions = {'Time'};
      fixed_fields = setdiff(fixed_fields,Exceptions);
      idx = strcmpi(fixed_fields,S(1).subs);
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
            S(2).subs = {1, ':'};
         end
         
         if numel(S(2).subs) > 1
            Chans = blockObj.Channels(S(2).subs{1});
            S(2).subs(1) = [];
         else
            Chans = blockObj.Channels;
         end
         out = arrayfun(@(x) subsref(x.(fixed_fields{idx}),S(2)),...
            Chans,...
            'UniformOutput',false);
         varargout{1} = horzcat(out{:});
         return;
      else
         % Standard case:
         [varargout{1:nargout}] = builtin('subsref',blockObj,S);
         return;
      end
      
   case '()' % Handle '()' subscripted references
      % () Means Blocks was referenced as __.Block() ... so it should be
      % used for dealing with Block arrays
      % Should always be dealt with in standard way:
%       if numel(S(1).subs)==1
%          S(1).subs = [1, S(1).subs]; % Make sure is indexing rows
%       end
      [varargout{1:nargout}] = builtin('subsref',blockObj,S);
      return;
      
   case '{}' % Handle '{}' subscripted (shortcut) references
      % Move "shortcut" referencing onto {} indexing, since it isn't
      % being used anyways. Simplifies everything.
      % Should only use one level of subscripting
      if numel(S) > 1
         error(['nigeLab:' mfilename ':BadSubsCount'],...
            ['[BLOCK/SUBSREF]: Use of {} shortcuts does not ' ...
            'support additional indexing.']);
      end
      
      % Should only reference a single block at a time, since if the first
      % index is numeric, it would reference the channels.
      if ~isscalar(blockObj)
          subs = S(1).subs;
          switch numel(subs)
              case 1
                  if isnumeric(subs{1})
                    % error. Single blocks in array should be referenced
                    % with ()
                    error(['nigeLab:' mfilename ':badReference'],...
                        ['[BLOCK/SUBSREF]: To access blocks from ' ...
                        'an array, use () instead of {}']);
                  elseif blockObj(1).IsRightKeyFormat(subs{1})
                      varargout{1} = blockObj.findByKey(subs{1});
                      return
                  end
              otherwise
                  if isQuery(subs)
                    idx = arrayfun(@(bb)filterMeta(bb,subs{:}),blockObj);
                    varargout{1} = blockObj(idx);
                    return
                  end
                  varargout{1} = arrayfun(@(bb)subsref(bb,S),blockObj,'UniformOutput',false);
%                   for i = 1:numel(blockObj)
%                       varargout{1}{i} = subsref(blockObj(i),S);
%                   end
                  return;
          end
      end
      
      %%% Input 1 defines which shortcut we're going to use. It needs to be
      %%% either a char that matches the fieldname in the shortcuts struct
      %%% or an index
      subs = S(1).subs;
      if ischar(subs{1})
         shrtName = subs{1};
         shrtStruct = blockObj.Shortcut.(shrtName);
      elseif isnumeric(subs{1}) && isscalar(subs{1})
         ff = fieldnames(blockObj.Shortcut);
         shrtStruct = blockObj.Shortcut.(ff{subs{1}});
      else
         error(['nigeLab:' mfilename ':BadSubsType'],...
            '[BLOCK/SUBSREF]: Invalid first input.');
      end
      
      %%% Now we know which shortcut we're using. We need to define the
      %%% number of inputs needed and construct the subsref struct
      
      NInputNeeded = sum(shrtStruct.indexable); 
      % this gives us the number of "indexable" component in the shortcut
      % (i.e. the number of inputs needed)
      if NInputNeeded > 2
         error(['nigeLab:' mfilename ':BadConfig'],...
            ['[BLOCK/SUBSREF]: Unsupported shortcut.\n' ...
            'nigeLab supports shortcuts up to a depth of two levels.\n',...
            '\t->\t(i.e. with at most two indexing sub-fields)'],...
            numel(subs),shrtName);
      end
      
      subs = S(1).subs(2:end);
      if numel(subs) < NInputNeeded
         error(['nigeLab:' mfilename ':TooFewInputs'],...
            ['[BLOCK/SUBSREF]: Not enough subscripts (%g) used for ' ...
            'the selected shortcut (%s).'],numel(subs),shrtName);
      elseif numel(subs) > NInputNeeded
         error(['nigeLab:' mfilename ':TooManyInputs'],...
            ['[BLOCK/SUBSREF]: Too many subscripts (%g) used for ' ...
            'the selected shortcut (%s).'],numel(subs),shrtName);
      end
      
      % Let's gather the objects targeted by the shortcut
      substructInArgs = {};
      for ii = 1:numel(shrtStruct.subfields)
         substructInArgs = [substructInArgs, {'.'} ,shrtStruct.subfields(ii)]; %#ok<AGROW>
         if shrtStruct.indexable(ii)
            substructInArgs = [substructInArgs, {'()' subs(1)}]; %#ok<AGROW>
            break;
         else
            ... Do nothing, go on with the loop
         end
      end
      
      TargetObj = subsref(blockObj,substruct(substructInArgs{:}));
      
      % we imposed only 2 levels of depth:
      % --> this means subs has to be only one cell after this
      subs = subs(end);     
      if iscell(subs{1})
         subs = subs{end};
      end
      shrtStruct.subfields(1:ii) = [];
      shrtStruct.indexable(1:ii) = [];
      
      % Let's create the subsref structs
      % Again we need to gather the substruct info from the shortcut
      substructInArgs = {};
      for ii = 1:numel(shrtStruct.subfields)
         substructInArgs = [substructInArgs, {'.'} ,shrtStruct.subfields(ii)]; %#ok<AGROW>
         if shrtStruct.indexable(ii)
            substructInArgs = [substructInArgs, {'()'}]; %#ok<AGROW>
            break;
         else
            ... Do nothing, go on with the loop
         end
      end
      
      % This time we add the indices after the () in a different way
      for jj = 1:numel(subs)
         if ~checkInputArgsCoherence(numel(TargetObj),subs{jj})
            % check that dimensions are coherent between inputs
            error(['nigeLab:' mfilename ':BadSize'],...
               ['[BLOCK/SUBSREF]: Dimensions of arrays being ' ...
               'concatenated are not consistent.']);
         end
         
         switch checkSamplesInput(subs{jj})
            case {'numeric','colon'}
               s(jj,:) = substruct(substructInArgs{:},subs(jj)); %#ok<AGROW>
            case 'cell'
               s(jj,:) = substruct(substructInArgs{:},subs{jj}); %#ok<AGROW>
            otherwise
               error(['nigeLab:' mfilename 'BadClass'],...
                  ['[BLOCK/SUBSREF]: Bad subscript number 3.\n' ...
                  '%ss are not supported.'],class(subs))
         end
         
      end
      index = ones(size(TargetObj)).*(1:size(s,1));
      varargout = {arrayfun(@(x,idx) subsref(x,s(idx,:)),TargetObj,index,'UniformOutput',false)};
      
   otherwise % Otherwise this is not a valid subsref 'type' reference
      error(['nigeLab:' mfilename ':BadType'],...
         '[BLOCK/SUBSREF]: Not a valid indexing subscript type: %s',...
         S(1).type);
end

end

% Return type as char ('numeric'; 'cell'; 'colon'; 'end'; 'invalid')
function value = checkSamplesInput(subs)
%CHECKSAMPLESINPUT  Helper function to check inputs
%
%  value = checkSamplesInput(subs);
%
%  subs : Subscript reference input argument
%
%  Returns the `type` of `subs` according to its class and other "special"
%  characteristics depending on its type.

if (isnumeric(subs) && isvector(subs))
   value = 'numeric';
elseif iscell(subs) && all(cellfun(@(x) strcmp(checkSamplesInput(x),'numeric'), subs))
   value = 'cell';
elseif ischar(subs) && strcmp(subs, ':')
   value = 'colon';
elseif ischar(subs) && strcmp(subs,'end')
   value = 'end';
else
   value = 'invalid';
end

end

% Checks that input subscript arguments "work" together
function value = checkInputArgsCoherence(prevElNum,args)
%CHECKINPUTARGSCOHERENCE  Ensure that subscript args "work" together
value = isnumeric(args) || (iscell(args) && (numel(args) == prevElNum)) || (ischar(args) && strcmp(args,':'));
end

function val = isQuery(subs)
    val = ~mod(numel(subs),2);
    val = val & all(cellfun(@ischar,subs(1:2:end)));
end