function FilterStream(data,save_name,b,a,fs)
%% FILTERSTREAM   Filter a single channel of streamed data and save it.
%
%   FILTERSTREAM(data,savename)
%
%   --------
%    INPUTS
%   --------
%     data      :       Single stream channel of re-referenced data.
%
%   save_name   :       Full filename of save file.
%
%      b        :       Filter numerator coefficients.
%
%      a        :       Filter denominator coefficients.
%
% See also: SPIKEDETECTCLUSTER
%   By: Max Murphy  v1.0    01/30/2017  Original Version

%% FILTER
filtdata =(filtfilt(b,a,double(data)));

%% SAVE
parsavedata(save_name, ...
            'data', single(filtdata), ...
            'fs', fs);
                                
end