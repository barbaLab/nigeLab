function addScoringDescription(scoring_file,scorer_ID)
%% ADDSCORINGDESCRIPTION   Add scoring description to previously-scored files
%
%  ADDSCORINGDESCRIPTION(scoring_file,scorer_ID);
%
%  --------
%   INPUTS
%  --------
%  scoring_file      :     Full filename of '*_Scoring.mat' file.
%
%  scorer_ID         :     (string) Initials of scoring author. If not
%                             provided, a dialog will popup to query this.
%
%  --------
%   OUTPUT
%  --------
%  Overwrites table in current '*_Scoring.mat' file with new table that has
%  the initials of the scorer and today's date in the table Description
%  field of its Properties.
%
% By: Max Murphy  v1.0  09/11/2018  Original version (R2017b)

%% PARSE INPUT
if nargin < 2
   scorer_ID = inputdlg('Enter initials of scorer:',...
                        'Missing Initials',...
                        1,...
                        {'MM'});
                     
   scorer_ID = scorer_ID{1};

end

%% LOAD TABLE
load(scoring_file,'behaviorData');

%% MODIFY DESCRIPTION
todays_date = datestr(datetime,'YYYY-mm-dd');
behaviorData.Properties.Description = sprintf('Scored by %s on %s',...
   scorer_ID,todays_date); %#ok<STRNU>

%% OVERWRITE SCORING FILE
save(scoring_file,'behaviorData','-v7.3');

end