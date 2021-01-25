
%%
function data_out=notchMainPower(data_in,Fs,MainF,NSub)
%% NOTCHMAINPOWER Utility to notch out the main power interference
% data_in               data to notch
% Fs                    Sampling frequency
% MainF                 Frequency of the principal harmonic
% NSub                  Number of subHarmonics to reiterate to process on
% 

switch nargin 
    case 3
        Nsub = 2;
    case 2
        Nsub = 2;
        MainF = 50;
    otherwise
end
data_out = data_in(:);

% first three harmonics
F0 = [1:NSub]' * MainF;

for ii =1:size(F0,1)

notchspec = fdesign.notch('N,F0,Q',4+ii*4,F0(ii),30*(ii),Fs);
notchfilt = design(notchspec,'SystemObject',true);

data_out = filtfilt(notchfilt.SOSMatrix,notchfilt.ScaleValues,data_out);
end
%%
% Revision history:
%{
2014-04-13 
    v0.1 Updated the file based on initial versions from Dante
(Revision author : Sri).
   

%}