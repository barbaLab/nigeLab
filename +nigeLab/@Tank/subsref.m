function varargout = subsref(tankObj,S)
% SUBSREF  Overloaded function modified so that BLOCK can be
%          referenced by indexing from ANIMAL using {} operator.
%          Everything with {} referencing refers to the
%          tankObj.Children property. NOTE: {} indexing does not support
%          additional subscripts (e.g. can't do tankObj{:,:}.Children).
%
%  childBlockArray = tankObj{[2,1;1,4;3,1]}
%  --> childBlockArray is the 1st Child Block of 2nd Animal in
%     array, 4th Block of 1st Animal, and 1st Block of 3rd Animal,
%     concatenated into a horizontal array [b21, b14, b31]
%
%  --> equivalent to calling tankObj{[2,1,3],[1,4,1]};
%
%  ** NOTE 1 ** calling tankObj{[2,1,3],[1,2,4,5]} would only return a
%  single element for each animalObj [b21, b12, b34], NOT the 1st, 2nd,
%  4th, and 5th block from each animal.
%
%  ** NOTE 2 ** calling tankObj{1:2} would return the 2nd block of the
%               first  animal, whereas calling tankObj{(1:2)'} would return
%               an array with the first and second animals, so be careful
%               about that part.
%
%  childBlock = tankObj{1,1}
%  --> returns 1st child of 1st animal in tankObj.Children
%
%  childBlockArray = tankObj{1}
%  --> Returns first animal in tankObj.Children
%
%  ** NOTE ** tankObj{end} references the last Animal in
%             tankObj.Children.
%
%  childBlockArray = tankObj{:}
%  --> Returns all animals in tankObj.Children.
%
%  childBlockArray = tankObj{2,:}
%  --> Returns all children of 2nd animal in tankObj.Children.
%
%  childBlockArray = tankObj{:,1}
%  --> Returns first child Block of each animal in tankObj.Children
%
%  ** NOTE ** tankObj{idx1,end} references the last Block in each
%             element of tankObj.Children indexed by idx1.

varargout = cell(1,nargout);
if isempty(tankObj.Children)
   return;
end

subs = S(1).subs;

switch S(1).type
   case '{}'
      %% Shortcut: tankObj{:} --> All Animals / tankObj{:,:} --> All Blocks
      if numel(S) > 1
         error(['nigeLab:' mfilename ':badSubscriptReference'],...
            ['Shortcut indexing using {} does not support subsequent ' ...
            '''.'' or ''()'' references.']);
      end
      switch numel(subs)
         % If only 1 subscript, then it indexes Animals
         case 1
            % Unless it is a matrix reference
            if size(subs{1},2) > 1
               s = substruct('{}',subs);
            else
               % If "return all" make sure it is in row vector format
               if ischar(subs{1})
                  if strcmp(subs{1},':')
                     subs = [1, subs];
                  end
               end
               s = substruct('()',subs);
            end
            out = subsref(tankObj.Children,s);
         case 2
            s = substruct('{}',subs);
            out = subsref(tankObj.Children,s);
            
         otherwise
            error(['nigeLab:' mfilename ':tooManyInputs'],...
               'Too many subscript indexing args (%g) given.',...
               numel(subs));
      end
      if numel(S) > 1
         methodIndex = tankObj.findMethodSubsIndices(S);
      else
         varargout{1} = out;
      end
      
      return;
      
      % If not {} index, use normal behavior
      %    case '
   otherwise
      if nargout > 0
         [varargout{1:nargout}] = builtin('subsref',tankObj,S);
      else
         [methodSubs,~,methodOutputs,methodInputs] = ...
            tankObj.findMethodSubsIndices(S);
         obj = tankObj;
         while ~isempty(methodSubs)
            if methodOutputs(1) > 0 
               if numel(S) > methodSubs(1)
                  switch S(methodSubs(1)+1).type
                     case '()' % Then arguments were given
                        if methodInputs(1) >= numel(S(methodSubs(1)+1).subs)
                           tmp = builtin('subsref',obj,S(1:(methodSubs(1)+1)));
                           if ismethod(tmp,'findMethodSubsIndices')
                              obj = tmp;
                              S(1:(methodSubs(1)+1)) = [];
                              [methodSubs,~,methodOutputs,methodInputs] = ...
                                 obj.findMethodSubsIndices(S);
                           else
                              methodSubs = [];
                           end
                        else
                           tmp = builtin('subsref',obj,S(1:methodSubs(1)));
                           if ismethod(tmp,'findMethodSubsIndices')
                              obj = tmp;
                              S(1:methodSubs(1)) = [];
                              [methodSubs,~,methodOutputs,methodInputs] = ...
                                 obj.findMethodSubsIndices(S);
                           else
                              methodSubs = [];
                           end
                        end
                     otherwise % Then it was "obj.method.method" call
                        tmp = builtin('subsref',obj,S(1:methodSubs(1)));
                        if ismethod(tmp,'findMethodSubsIndices')
                           obj = tmp;
                           S(1:methodSubs(1)) = [];
                           [methodSubs,~,methodOutputs] = ...
                              obj.findMethodSubsIndices(S);
                        else
                           methodSubs = [];
                        end
                  end
               else
                  tmp = builtin('subsref',obj,S);
                  if isscalar(tmp) && islogical(tmp)
                     return;
                  else
                     ans = tmp %#ok<NOPRT,*NOANS>
                     nigeLab.utils.mtb(ans); 
                     return;
                  end
               end
            else
               builtin('subsref',obj,S);
               return;
            end
         end
         ans = builtin('subsref',obj,S) %#ok<NOPRT>
         nigeLab.utils.mtb(ans);
      end
end
end