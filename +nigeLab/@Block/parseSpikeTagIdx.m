function tagIdx = parseSpikeTagIdx(blockObj,tagArray)
%PARSESPIKETAGIDX   Get index given a cell array of spike tags
%
%  tagIdx = PARSESPIKETAGIDX(blockObj,tagArray);
%
%  --------
%   INPUTS
%  --------
%  blockObj    :     nigeLab.Block class object
%
%  tagArrary   :     Cell array of tags as strings.
%
%  --------
%   OUTPUT
%  --------
%   tagIdx     :     Numeric array of indices corresponding to tagArray.

% FIRST MAKE SURE THAT ARRAY DOES NOT HAVE ANY EMPTY ELEMENTS
tagArray = cellfun(@parseEmptyCell,tagArray,'UniformOutput',false);
% THIS APPEARS TO BE FASTEST WAY:
tagIdx = nan(size(tagArray));
for ii = 1:numel(blockObj.Pars.Sort.TAG)
   tmp = ismember(tagArray,blockObj.Pars.Sort.TAG{ii});
   tagIdx(logical(tmp)) = ii;
end
   function out = parseEmptyCell(in)
      %PARSEEMPTYCELL    Make sure each cell element has correct format
      if isempty(in)
         out = '';
      else
         out = in;
      end
   end
end