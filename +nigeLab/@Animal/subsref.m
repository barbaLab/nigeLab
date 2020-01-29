function varargout = subsref(animalObj,S)
% SUBSREF  Overloaded function modified so that BLOCK can be
%          referenced by indexing from ANIMAL using {} operator.
%          NOTE: {} indexing does not support
%          additional subscripts (e.g. can't do animalObj{:,:}.Children).
%
%  childBlockArray = animalObjArray{[2,1;1,4;3,1]}
%  --> childBlockArray is the 1st Child Block of 2nd Animal in
%     array, 4th Block of 1st Animal, and 1st Block of 3rd Animal,
%     concatenated into a horizontal array [b21, b14, b31]
%
%  --> equivalent to calling animalObjArray{[2,1,3],[1,4,1]};
%
%  ** NOTE ** that calling
%  animalObjArray{[2,1,3],[1,2,4,5]} would only return a single
%  element for each animalObj [b21, b12, b34], NOT the 1st, 2nd,
%  4th, and 5th block from each animal.
%
%  childBlock = animalObjArray{1,1}
%  --> returns 1st child of 1st animal in array
%
%  childBlockArray = animalObjArray{1}
%  --> Returns all children of the 1st animal in array
%
%  childBlock = animalObj{1}
%  --> Returns 1st block of that animal
%
%  childBlockArray = animalObj{:}
%  --> Returns all children of that animal object
%
%  childBlockArray = animalObjArray{:}
%  --> Returns all children of all animals in array
%
%  childBlockArray = animalObjArray{2,:}
%  --> Returns all children of 2nd animal in array
%
%  childBlockArray = animalObjArray{:,1}
%  --> Returns first child of all animals in array

subs = S(1).subs;
switch S(1).type
    case '{}'
        if numel(S) > 1
            error(['nigeLab:' mfilename ':badSubscriptReference'],...
                ['Shortcut indexing using {} does not support subsequent ' ...
                '''.'' or ''()'' references.']);
        end
        
        % If referencing a single animal, the behavior is different
        % if a single vector of subscripts is given.
        if isscalar(animalObj)
            
%             check coherence of indexes for example the user should not be
%             allowed to input numeric and char indexes toghether
            if numel(unique(cellfun(@(x) class(x), subs, 'UniformOutput', false))) ~= 1
                error(['nigeLab:' mfilename ':badSubscriptReference'],...
                    ['Shortcut indexing using {} does not support different index types (numeric,char). ']);
            end
            
           
            if IsRightKeyFormat(animalObj,subs{1})
                % Attempting to use Key index. A cell array with n keys inside
                % it
                if numel(subs)>1
                    warning(['nigeLab:' mfilename ':badSubscriptReference'],...
                        ['Too many subscript references. Ignoring all except the first one.\n'...
                        'If you want to access more blocks, please put your keys betwee {}']);
                end
                s = substruct('.','findByKey','()',subs(1));
            elseif IsSemiColon(subs{1})
                    % one of the iputs is ':'
                    if numel(subs)>1
                        % and has some other input after it
                        warning(['nigeLab:' mfilename ':badSubscriptReference'],...
                            ['This doesn''t make any sense. Ignoring all inputs except '':''. ']);
                    end
                    s = substruct('()',{':'});
            elseif isnumeric(subs{1})
                 if numel(subs)>1
                    warning(['nigeLab:' mfilename ':badSubscriptReference'],...
                        ['Too many subscript references. Ignoring all except the first one.\n'...
                        'If you want to access more blocks, please put your indexes betwee []']);
                end
                s = substruct('()',subs(1));
            else
                error(['nigeLab:' mfilename ':badSubscriptReference'],...
                    ['Invalid subscipt reference. ']);
            end
            varargout{1} = subsref(animalObj.Children,s);
            
            %%%%%%%%
            %%%%%%%%   Deprecated 29/01/2020
            %%%%%%%%
            % % %          % If only one argument given to subscripts (e.g. no ',')
            % % %          if numel(subs) == 1
            % % %             subs = subs{:};
            % % %
            % % %             % If only referencing child objects using a vector
            % % %             % (not referencing animalObj, since animalObj is
            % % %             %  already a scalar!)
            % % %             if size(subs,2) == 1
            % % %                S = substruct('{}',{1, subs});
            % % %                varargout = {subsref(animalObj,S)};
            % % %                return;
            % % %
            % % %                % Otherwise, if using a matrix to reference
            % % %             elseif size(subs,2) == 2
            % % %                S = substruct('{}',{subs(:,1),subs(:,2)});
            % % %                varargout = {subsref(animalObj,S)};
            % % %                return;
            % % %
            % % %                % Otherwise, could be using 'end'
            % % %             else
            % % %                if ~ischar(subs)
            % % %                   error(['nigeLab:' mfilename ':badReference'],...
            % % %                      'Matrix references should be nChild x 2');
            % % %                end
            % % %                if strcmpi(subs,'end')
            % % %                   varargout = {animalObj.Block(...
            % % %                      animalObj.getNumBlocks)};
            % % %                   return;
            % % %                else
            % % %                   error(['nigeLab:' mfilename ':badReference'],...
            % % %                      'Unrecognized index: %s',subs);
            % % %                end
            % % %             end
            % % %
            % % %             % Otherwise, subscript for Animal and Block both given
            % % %          elseif numel(subs) == 2
            % % %             if ~ischar(subs{1})
            % % %                if any(subs{1} > 1) % since this is a scalar animalObj
            % % %                   error(['nigeLab:' mfilename ':indexOutOfBounds'],...
            % % %                      'Bad indexing expression, animalObj is scalar.');
            % % %                end
            % % %             end
            % % %             S = substruct('()',{ones(size(subs,1),1),subs{2}});
            % % %             varargout = {subsref(animalObj.Children,S)};
            % % %             return;
            % % %
            % % %             % Otherwise, too many subscript args were given
            % % %          else
            % % %             error(['nigeLab:' mfilename ':tooManyInputs'],...
            % % %                'Too many subscript indexing args (%g) given.',...
            % % %                numel(subs));
            % % %          end
            % % %
            % If more than one animalObj in array
        else
            switch numel(subs)
                case 1
                    
                     if ~iscell(subs{1}) && ~ischar(subs{1})
                        error(['nigeLab:' mfilename ':badReference'],...
                            ['Unrecognized index element; '...
                            'When animalObj is an array, single indexing is allowed only with Keys.']);
                     end
       
                     if IsRightKeyFormat(animalObj,subs{1})
                         % index by key
                         out = animalObj.findByKey(subs{1});
                         if isempty(out)
                             bl = [animalObj.Children];
                             out = bl.findByKey(subs{1});
                         end
                         varargout{1} = out;
                         return;
                     end
                case 2
                    % in this case subs{1} selcts the animal and subs{2} the
                    % child block. E.g. {animalObjIndex,blockObjIndex} or
                    % {animalObjKey,blockObjKey} or a combination of the two.
                    
                    %%% INPUT 1
                    % first of all, let's check the input class. This is
                    % redundant, but I'm trying to make this extra robust.
                    if ~iscell(subs{1}) && ~ischar(subs{1}) && ~isnumeric(subs{1})
                        error(['nigeLab:' mfilename ':badReference'],...
                            ['Unrecognized index element; '...
                            '%s not allowed as index 1.'],class(subs{1}));
                    elseif ~iscell(subs{2}) && ~ischar(subs{2}) && ~isnumeric(subs{2})
                        error(['nigeLab:' mfilename ':badReference'],...
                            ['Unrecognized index element; '...
                            '%s not allowed as index 2.'],class(subs{2}));
                    end
   
                    % Everything is ok.
                    % this means we can select the animals first and then selct
                    % the corresponding blocks.
                    if iscell(subs{1})
                        checkCellInputCoherence(subs{1},1);
                    end
                    if IsRightKeyFormat(animalObj,subs{1})
                        % if is a char array of the right form or is cell
                        s = substruct('.','findByKey','()',subs(1));
                    elseif IsSemiColon(subs{1})
                        s = substruct('()',subs(1));
                    elseif isnumeric(subs{1})
                        s = substruct('()',subs(1));
                    else
                        error(['nigeLab:' mfilename ':badReference'],...
                            ['Unrecognized index element; '...
                            '%s not allowed as index 1.'],class(subs{1}));
                    end
                    
                    an = subsref(animalObj,s);  % selected animals
                    
                    %%% INPUT 2
                    % Now we need to format s for the blocks
                    if  IsRightKeyFormat(animalObj,subs{2})
                        s = substruct('.','findByKey','()',subs(2));
                    elseif IsSemiColon(subs{2})
                        s = substruct('()',subs(2));
                        s = repmat(s,numel(an),1);
                    elseif  iscell(subs{2}) 
                         checkCellInputCoherence(subs{2},2);
                        if all( cellfun( @(x) isnumeric(x),subs{2}) )
                            % if is a cell array of numerical indexes.
                            % E.g. animalObj{[1,2],{1,[1 3]}} which should return
                            % [animalObj(1).Children(1),animalObj(1).Children([1,3])]
                            if numel(an) == numel(subs{2})
                                % check if the indexes in subs{1} have the same
                                % dimensions as the ones in subs{2}
                                f = {'type','subs'};
                                c = repmat({'()'},1,numel(an));
                                for ii=1:numel(subs{2})
                                    c(2,ii) = {subs{2}(ii)};
                                end
                                s = cell2struct(c,f,1);
                                s = s(:); % just to be sure is a column
                            else
                                error(['nigeLab:' mfilename ':VerticalDimensionsMismatch'],...
                                    'Dimensions of arrays being concatenated are not consistent.');
                            end
                        elseif all( cellfun( @(x) IsRightKeyFormat(animalObj,x),subs{2}) )
                            if numel(an) == numel(subs{2})
                                % check if the indexes in subs{1} have the same
                                % dimensions as the ones in subs{2} 
                                s =  substruct('.','findByKey','()',subs{2}(1));
                                for ii=2:numel(subs{2})
                                    s(ii,:) =  substruct('.','findByKey','()',subs{2}(ii));
                                end
                            else
                                error(['nigeLab:' mfilename ':VerticalDimensionsMismatch'],...
                                    'Dimensions of arrays being concatenated are not consistent.');
                            end
                        end
                        
                    elseif isnumeric(subs{2})
                        s = substruct('()',subs(2));
                        s = repmat(s,numel(an),1);
                    else
                        error(['nigeLab:' mfilename ':badReference'],...
                            ['Unrecognized index element; '...
                            '%s not allowed as index 2.'],class(subs{2}));
                    end
                    
                    % A little bit of output formatting
                    if isempty(an)
                        varargout{1} = an;
                        return;
                    end
                    out = arrayfun(@(x,idx) subsref(x.Children,s(idx,:)),an(:),(1:numel(an))','UniformOutput',false);
                    varargout{1} = [out{:}]';
                    return;                    
                otherwise
                    % Otherwise too many input arguments given to
                    % animalObj array
                    error(['nigeLab:' mfilename ':tooManyInputs'],...
                        'Too many subscript indexing args (%g) given.',...
                        numel(subs))
            end %switch(numel(subs))
        end %fi isscalar(animalObj)
    otherwise
        % if not {}, proceed as always
        [varargout{1:nargout}] = builtin('subsref',animalObj,S);
end % switch(S(1).type)
end % function

function value = IsRightKeyFormat(obj,subs)
%% ISRIGHTKEYFORMAT returns right if subs is a key or a cell array of keys
key = obj(1).Key.Public;
KeyLength = numel(key);


value = (ischar(subs) && numel(subs) == KeyLength) ||...
    (iscell(subs) && ...
    all( cellfun( @(x) ischar(x) && numel(x) == KeyLength,subs) ));


end

function value = IsSemiColon(subs)
value = ischar(subs) && strcmp(subs,':');
end

function checkCellInputCoherence(subs,indxNum)
%% CHECKCELLINPUTCOHERENCE 
% Checks coherence of input ie all inputs must have the same type. The user
% cannot index with keys and numbers for the same field.

if numel(unique(cellfun(@(x) class(x), subs, 'UniformOutput', false))) ~= 1
   classStr = strjoin(unique(cellfun(@(x) class(x), subs, 'UniformOutput', false)),' and ');
    error(['nigeLab:' mfilename ':badSubscriptReference'],...
        ['Shortcut indexing using {} does not support different index types (numeric,char). \n'...
        'Index %d is composed of %s.'],indxNum,classStr);
end
end

% function checkCellInputCoherence(subs)
%% CHECKCELLINPUTCOHERENCE v2
% TODO update the rest to reflect this
% Checks coherence of input within the same cell
% the user can index with keys and numbers for the same field as long as
% it's clear what he's referring to:
%  e.g animalObj{{key,key},{number,{key,key}}}
% what is not allowed is 
% animalObj{{number,key},...} or
% animalObj{...,{number,{number,key}}}
% since number and key can inadvertedly lead to the same result

% cellIdx = cellfun(@(x) iscell(x), subs);
% if any(cellIdx)
%     checkCellInputCoherence(subs{cellIdx});
% end
% subs(cellIdx) = [];
% if numel(unique(cellfun(@(x) class(x), subs, 'UniformOutput', false))) ~= 1
%     error(['nigeLab:' mfilename ':badSubscriptReference'],...
%         ['Shortcut indexing using {} does not support different index types (numeric,char). ']);
% end
% end