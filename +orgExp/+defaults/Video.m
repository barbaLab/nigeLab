function pars = Video()
%% VIDEO  Template for initializing parameters related to experiment trigger synchronization
%
%   pars = orgExp.defaults.Video;
%
% By: MAECI 2018 collaboration (MM, FB, SB)

%%
pars = struct;

% Paths information
pars.Root    = 'K:\Rat\Video\BilateralReach\Murphy'; % MUST point to where the videos are
pars.AltRoot = 'K:\Rat\Video\BilateralReach\RC';
pars.FileExt = '.avi';
pars.File = [];

% Metadata parsing
pars.Delimiter = {'_','-'};
pars.DynamicVars = {'$Surg_Year','$Surg_ID','$Rec_Year','$Rec_Month','$Rec_Day','$Rec_ID','&Door','&View','&Movie_ID'};
pars.IncludeChar = '$';
pars.ExcludeChar = '&';
pars.Meta = [];

% Information about video scoring
pars.user = 'MM'; % Who did the scoring?
pars.vars = {'Trial','Reach','Grasp','Support','Pellets','PelletPresent','Outcome','Forelimb'};
pars.varType = [0,1,1,1,2,3,4,5]; % must have same number of elements as VARS
                              % options: 
                              % -> 0: Trial "onset" guess
                              % -> 1: Timestamps
                              % -> 2: Counts (0 - 9)
                              % -> 3: No (0) or Yes (1)
                              % -> 4: Unsuccessful (0) or Successful (1)
                              % -> 5: Left (0) or Right (1)
                              
end