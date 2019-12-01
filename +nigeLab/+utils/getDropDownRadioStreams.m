function [title_str,prompt_str,opts] = getDropDownRadioStreams(blockObj,t_str)
% GETDROPDOWNRADIOSTREAMS  Return inputs to uidropdownradiobox for
%                          selecting desired STREAMS options.
%
%  [title_str,prompt_str,opts] =
%        nigeLab.utils.getDropDownRadioStreams(blockObj);
%  --> prompt_str corresponds with Fields of Streams.
%  --> opts corresponds with names of Streams in each Fields element
%
%  [title_str,prompt_str,opts] =
%        nigeLab.utils.getDropDownRadioStreams(blockObj,t_str);
%  --> Specify t_str manually

% Get title string (or assign)
if nargin < 2
   title_str = {'Stream Selection Window';...
      'Select Digital or Analog stream(s)'};
else
   title_str = t_str;
end

% Get prompt, corresponding to radio button options, which are fieldnames
% of blockObj.Streams (e.g. 'DigIO', 'AnalogIO' etc)
prompt_str = fieldnames(blockObj.Streams);
prompt_str(cellfun(@isempty,prompt_str)) = [];

% Get opts, which are sub-fields of Streams elements (e.g.
%     blockObj.Streams.DigIO(1).custom_channel_name == 'Beam')
opts = cell(numel(prompt_str),2);
rmvec = true(size(prompt_str));
for i = 1:numel(prompt_str)
   rmvec(i) = isempty(blockObj.Streams.(prompt_str{i}));
   opts{i,2} = prompt_str{i};
   opts{i,1} = {blockObj.Streams.(prompt_str{i}).custom_channel_name}.';
end

% For Streams Fields that don't have any elements, remove them from the
% options so the interface doesn't throw warnings.
opts(rmvec) = [];

end
