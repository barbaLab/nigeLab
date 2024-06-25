function [locs pks]=peakseek(x,minpeakdist,minpeakh,npeaks)
% Alternative to the findpeaks function.  This thing runs much much faster.
% It really leaves findpeaks in the dust.  It also can handle ties between
% peaks.  Findpeaks just erases both in a tie.  Shame on findpeaks.
%
% x is a vector input (generally a timecourse)
% minpeakdist is the minimum desired distance between peaks (optional, defaults to 1)
% minpeakh is the minimum height of a peak (optional)
%
% (c) 2010
% Peter O'Connor
% peter<dot>ed<dot>oconnor .AT. gmail<dot>com
% modified by Tommaso Lambresa 2024, introduced the "npeaks" input

switch nargin 
    case 1
        minpeakdist = 1;
        minpeakh = -inf;
        npeaks = [];
    case 2
        minpeakh = -inf;
        npeaks = [];
    case 3
        npeaks = [];
    case 4
        ...
    otherwise
        error("not ienough input arguments");
end

if isempty(minpeakdist)
    minpeakdist = 1;
end
if isempty(minpeakh)
    minpeakh = -inf;
end


if size(x,2)==1, x=x'; end

% Find all maxima and ties
locs=find(x(2:end-1)>=x(1:end-2) & x(2:end-1)>=x(3:end))+1;


locs(x(locs)<=minpeakh)=[];

if minpeakdist>1
    while 1

        del=diff(locs)<minpeakdist;

        if ~any(del), break; end

        pks=x(locs);

        [garb, mins]=min([pks(del) ; pks([false del])]); %#ok<ASGLU>

        deln=find(del);

        deln=[deln(mins==1) deln(mins==2)+1];

        locs(deln)=[];

    end
end

if ~isempty(npeaks) && ~isempty(locs)
    locs = locs(1:npeaks);
end

if nargout>1
    pks=x(locs);
end

end