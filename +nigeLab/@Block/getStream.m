function stream = getStream(blockObj,streamName,scaleOpts)
% GETSTREAM  Returns stream struct field corresponding to streamName
%
%  stream = blockObj.getStream('streamName'); 
%
%  streamName  :  Char array e.g. 'Paw' or 'Beam' etc. that is the name of
%                    some Stream.
%                 --> Set as `camOpts` struct to parse from camera
%                 instead. See `nigeLab.utils.initCamOpts` for
%                 details.
%                 --> In this case, can give struct array of CamOpts for
%                 multiple streams output.
%
%  scaleOpts   :  (Optional) -- Struct with fields:
%                          --> 'do_scale'  (set false to skip scaling)
%                          --> 'range'     ('normalized' or 'fixed_scale')
%                          --> 'fixed_min' (fixed/known min. value)
%                          --> 'fixed_range' (only used if range is
%                                               'fixed_scale'; flat value
%                                               that range should be scaled
%                                               to). 

if nargin < 2
   error(['nigeLab:' mfilename ':TooFewInputs'],...
      '\t\t->\t[BLOCK/GETSTREAM]: Must supply at least two arguments.');
end

if ischar(streamName)
   streamName = {streamName};
end

if nargin < 3
   scaleOpts = nigeLab.utils.initScaleOpts();
elseif isempty(scaleOpts)
   scaleOpts = nigeLab.utils.initScaleOpts();
elseif ~isstruct(scaleOpts)
   scaleOpts = nigeLab.utils.initScaleOpts();
end

if numel(blockObj) > 1
   stream = cell(size(blockObj));
   for i = 1:numel(blockObj)
      stream{i} = blockObj(i).getStream(streamName,scaleOpts);
   end
   return;
end

if numel(streamName) > 1
   stream = [];
   if numel(scaleOpts) == 1
      repmat(scaleOpts,size(streamName));
   end
   for i = 1:numel(streamName)
      stream = horzcat(stream,...
         blockObj.getStream(streamName(i),scaleOpts(i))); %#ok<AGROW>
   end
   return;
end

if iscell(streamName)
   streamName = streamName{:}; % Convert to char or back to struct
end

matchingNames = structfun(@(x) {x(contains({x.name},streamName)).name},blockObj.Streams,'UniformOutput',false);
matchingNames = struct2array(matchingNames);
stream = nigeLab.libs.nigelStream(blockObj,matchingNames{1},scaleOpts);

end