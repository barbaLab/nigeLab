function channelName = parseChannelName(sortObj)
%% PARSECHANNELNAME    Get unique channel/probe combination for identifier
%
%  channelName = PARSECHANNELNAME(sortObj);
%
%  --------
%   INPUTS
%  --------
%   sortObj	   :     nigeLab.Sort class object
%
%  --------
%   OUTPUT
%  --------
%  channelName :     Cell array of chars that give the written name of each
%                       channel described in channelID.
%
% By: Max Murphy   v1.0 2019/01/08   Original version (R2017a)

%%
N = size(sortObj.Channel.ID,1);
channelName = cell(N,1);
for ii = 1:N
   channelName{ii} = sprintf('P%g Ch %03g',...
                             sortObj.Channel.ID(ii,1),...
							 sortObj.Channel.ID(ii,2));
end


end