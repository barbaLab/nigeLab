function behaviorData = changeAlignOffset(behaviorData,offset,add_rm,varType)
%% CHANGEALIGNOFFSET    Change alignment of table
%
%  behaviorData = CHANGEALIGNOFFSET(behaviorData,offset,add_rm,varType);
%
%  --------
%   INPUTS
%  --------
%  behaviorData   :     Matlab Table containing behavior scoring variables.
%
%   offset        :     (VideoStart) Number of seconds between starting the
%                                   neural (TDT) recording and starting the
%                                   video. Positive value indicates neural
%                                   data started first.
%
%  add_rm         :     (Optional) Add (1) or remove (-1) offset. If
%                                  unspecified, defaults to 1.
%
%  varType        :     (Optional) Vector with values giving the UserData
%                       field of behaviorData.Properties. This specifies
%                       what kind of variable is  measured for each
%                       variable, per SCOREVIDEO. If not specified, uses
%                       default values of [0,1,1,1,2,3,4,5].
%
%  --------
%   OUTPUT
%  --------
%  behaviorData   :     Same as input but with updated fields.
%
% By: Max Murphy  v1.0  09/11/2018  Original version (R2017b)

%% PARSE INPUT
% Default for "Trials" "Reach" "Grasp" "Support" and then nothing else
% needs offset added or removed.
if exist('varType','var')==0
   varType = [0,1,1,1,2,3,4,5]; % Works for RC project
end

% Default is to add offset
if exist('add_rm','var')==0
   add_rm = 1;
end

% Parse variable types
u = behaviorData.Properties.UserData;
v = behaviorData.Properties.VariableNames;

% Update UserData if needed
if numel(u)~=numel(v)
   u = varType;
   behaviorData.Properties.UserData = u;
end

%% REMOVE OR ADD OFFSET TO CORRECT VARIABLE TYPES
for ii = 1:numel(v)
   if u(ii) < 2
      behaviorData.(v{ii}) = behaviorData.(v{ii}) + (offset * add_rm);
   end
end


end