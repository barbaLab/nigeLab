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
         
         % If only one argument given to subscripts (e.g. no ',')
         if numel(subs) == 1
            subs = subs{:};
            
            % If only referencing child objects using a vector
            % (not referencing animalObj, since animalObj is
            %  already a scalar!)
            if size(subs,2) == 1
               S = substruct('{}',{1, subs});
               varargout = {subsref(animalObj,S)};
               return;
               
               % Otherwise, if using a matrix to reference
            elseif size(subs,2) == 2
               S = substruct('{}',{subs(:,1),subs(:,2)});
               varargout = {subsref(animalObj,S)};
               return;
               
               % Otherwise, could be using 'end'
            else
               if ~ischar(subs)
                  error(['nigeLab:' mfilename ':badReference'],...
                     'Matrix references should be nChild x 2');
               end
               if strcmpi(subs,'end')
                  varargout = {animalObj.Block(...
                     animalObj.getNumBlocks)};
                  return;
               else
                  error(['nigeLab:' mfilename ':badReference'],...
                     'Unrecognized index: %s',subs);
               end
            end
            
            % Otherwise, subscript for Animal and Block both given
         elseif numel(subs) == 2
            if ~ischar(subs{1})
               if any(subs{1} > 1) % since this is a scalar animalObj
                  error(['nigeLab:' mfilename ':indexOutOfBounds'],...
                     'Bad indexing expression, animalObj is scalar.');
               end
            end
            S = substruct('()',{ones(size(subs,1),1),subs{2}});
            varargout = {subsref(animalObj.Children,S)};
            return;
            
            % Otherwise, too many subscript args were given
         else
            error(['nigeLab:' mfilename ':tooManyInputs'],...
               'Too many subscript indexing args (%g) given.',...
               numel(subs));
         end
         
         % If more than one animalObj in array
      else
         switch numel(subs)
            case 1
               subs = subs{:};
               
               % If only character input is given, it references
               % either all of the blocks or all blocks of the
               % last animal.
               if ischar(subs)
                  switch subs
                     % Return all children of all animals
                     case ':'
                        varargout = cell(1,nargout);
                        for i = 1:numel(animalObj)
                           varargout{1} = [varargout{1},...
                              animalObj(i).Children];
                        end
                     otherwise
                        error(['nigeLab:' mfilename ':badReference'],...
                           'Unrecognized index keyword: %s',subs);
                  end
                  return;
               end
               % Otherwise, the input is numeric
               % If it is a vector, then get all blocks of the
               % corresponding animals.
               if size(subs,2) == 1
                  varargout = {[]};
                  for i = 1:numel(subs)
                     varargout{1} = [varargout{1},...
                        animalObj(subs(i)).Children];
                  end
                  return;
                  
                  % If it is a matrix, reformat and make call back to
                  % subsref
               elseif size(subs,2) == 2
                  S = substruct('{}',{subs(:,1),subs(:,2)});
                  varargout = {subsref(animalObj,S)};
                  return;
                  
                  % Otherwise, it's a bad expression
               else
                  error(['nigeLab:' mfilename ':badReference'],...
                     'Matrix references should be nChild x 2');
               end
               
               % If there are two input arguments given to animalObj
               % array for subscripting
            case 2
               
               % If the first indexing element is a character,
               % then get the corresponding ANIMAL according to
               % that character index
               if ischar(subs{1})
                  switch lower(subs{1})
                     % For each animalObj in array, return the
                     % corresponding blocks.
                     case ':'
                        varargout = cell(1,nargout);
                        for i = 1:numel(animalObj)
                           if ischar(subs{2})
                              switch lower(subs{2})
                                 case ':'
                                    idx2 = 1:getNumBlocks(animalObj(i));
                                 otherwise
                                    error(['nigeLab:' mfilename ':badReference'],...
                                       'Unrecognized index keyword: %s',subs);
                              end
                           else
                              idx2 = subs{2}(i);
                           end
                           varargout{1} = [varargout{1},...
                              animalObj(i).Children(idx2)];
                        end
                        
                     otherwise
                        error(['nigeLab:' mfilename ':badReference'],...
                           'Unrecognized index keyword: %s',subs);
                  end
                  return;
               end
               
               % For an animalObj array, this means the indexing
               % inputs must be numeric and of the form
               % {animalObjIndex,blockObjIndex}
               idx1 = subs{1};
               varargout = cell(1,numel(idx1));
               
               for i = 1:numel(idx1)
                  if ischar(subs{2})
                     switch lower(subs{2})
                        case ':'
                           idx2 = 1:getNumBlocks(animalObj(idx1(i)));
                        otherwise
                           error(['nigeLab:' mfilename ':badReference'],...
                              'Unrecognized index keyword: %s',subs);
                     end
                  else
                     idx2 = subs{2}(i);
                  end
                  varargout{1} = [varargout{1},...
                     animalObj(idx1(i)).Children(idx2)];
               end
               return;
               
               % Otherwise too many input arguments given to
               % animalObj array
            otherwise
               error(['nigeLab:' mfilename ':tooManyInputs'],...
                  'Too many subscript indexing args (%g) given.',...
                  numel(subs));
         end
      end
   otherwise      
      [varargout{1:nargout}] = builtin('subsref',animalObj,S);
end
end