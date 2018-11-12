% Function for collecting artifact in a fast way
% by Michela Chiappalone
% modified by Luca Leonardo Bologna 13 November 2006
function [artifact] = find_artefacts_spikeTrain(x, period, threshold)
% x -> peak_train
% period -> smaller distance between artifacts considered as valid (smaller
%           ones are catched by the preceding artifact
% threshold -> "threshold" the data must to overcome in order for an
%           artifact to be considered
artifact=[];  % array containing artifact timestamps
n = length(x); % number of recorded samples
r = rem(n, period); % remainder of the division
artPos=find(x>threshold); % indices of "x" containing elements greater than "threshold"
artPosPerRat=artPos/period; % division
artPosPerRatRef=artPosPerRat-1;
artPosPerRatRefCeil=ceil(artPosPerRatRef);
[b,m,c]=unique(artPosPerRatRefCeil);
mUseful=m<=n-r;
mFin=m(mUseful);
if (~isempty(mFin))
    artifact=artPos(mFin);
end