function data = subsref(obj,S)
%SUBSREF  Overloaded function for referencing DiskData array
%
%  data = subsref(obj,S);

% Do some checks to ensure data accessed is valid
data = [];
% First: see if this is a reference to access a property of '.'-indexed
% method instead of a reference to the diskfile_
if strcmp(S(1).type,'.')
   mc = ?nigeLab.libs.DiskData;
   m = mc.MethodList;
   diskMethods = {m.Name};
   diskProps = {mc.PropertyList.Name};
   excludedPropNames = {'class'};
   includedPropNames = setdiff(diskProps,...
      {'type','value','tag','ts','snippet','data'});
   mIdx = strcmp(diskMethods,S(1).subs);
   if any(mIdx) && ~any(strcmp(excludedPropNames,S(1).subs))
       nOut = nargout;
      if nOut > 0
         data = builtin('subsref',obj,S);
      else
         if numel(m(mIdx).OutputNames) > 0
            out = builtin('subsref',obj,S);
            disp(out);
            clear data;
         else
            builtin('subsref',obj,S);
         end
      end
      return;
   elseif any(strcmp(includedPropNames,S(1).subs))
      if nargout > 0
         data = builtin('subsref',obj,S);
      else
         out = builtin('subsref',obj,S);
         disp(out);
         clear data;
      end
      return;
   end
end

% Now check if the object itself is empty
if isempty(obj)
   if ~checkSize(obj)
      dbstack();
      nigeLab.utils.cprintf('Errors*','\t\t->\t[DISKDATA]: '); 
      nigeLab.utils.cprintf('Errors','Object is '); 
      nigeLab.utils.cprintf('Keywords*','empty\n');
      return;
   end
elseif ~isvalid(obj)
   if ~checkSize(obj)
      dbstack();
      nigeLab.utils.cprintf('Errors*','\t\t->\t[DISKDATA]: '); 
      nigeLab.utils.cprintf('Errors','Object is '); 
      nigeLab.utils.cprintf('Keywords*','invalid\n');
      return;
   end
end
if exist(obj.diskfile_,'file')==0
   dbstack();
   nigeLab.utils.cprintf('Errors*','\t\t->\t[DISKDATA]: '); 
   nigeLab.utils.cprintf('Errors','No such file--');
   nigeLab.utils.cprintf('Keywords*','%s\n',obj.diskfile_);
   return;
end

% Referencing depends on .type_ of file
switch obj.type_
   case 'Event'
      if nargout > 0
         data = subsref_MatrixData(obj,S);
      else
         subsref_MatrixData(obj,S);
      end
   otherwise
      if nargout > 0
         data = subsref_VectorData(obj,S);
      else
         subsref_VectorData(obj,S);
      end
end
end