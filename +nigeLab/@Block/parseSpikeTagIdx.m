function tagIdx = parseSpikeTagIdx(blockObj,tagArray)
%% PARSESPIKETAGIDX   Get index given a cell array of spike tags
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
%
% By: Max Murphy   v1.0 2019/01/08   Original version (R2017a)

%% FIRST MAKE SURE THAT ARRAY DOES NOT HAVE ANY EMPTY ELEMENTS
tagArray = cellfun(@parseEmptyCell,tagArray,'UniformOutput',false);

%% THIS APPEARS TO BE FASTEST WAY:
tagIdx = nan(size(tagArray));
for ii = 1:numel(blockObj.SortPars.TAG)
   tmp = ismember(tagArray,blockObj.SortPars.TAG{ii});
   tagIdx(logical(tmp)) = ii;
end

   function out = parseEmptyCell(in)
      %% PARSEEMPTYCELL    Make sure each cell element has correct format
      if isempty(in)
         out = '';
      else
         out = in;
      end
   end


end