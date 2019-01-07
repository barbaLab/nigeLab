function flag = doBehaviorSync(blockObj)
%% DOBEHAVIORSYNC   Get event times from synchronized optiTrack record.
%
%  flag = DOBEHAVIORSYNC(blockObj);
%
%  --------
%   INPUTS
%  --------
%  blockObj    :     BLOCK class object from orgExp package.
%
%  --------
%   OUTPUT
%  --------
%     flag     :     Boolean logical operator to indicate whether
%                     synchronization
%
%
% Adapted from CPLTools By: Max Murphy  v1.0  12/05/2018 version (R2017b)

%% DEFAULTS
flag = false;
blockObj.SyncPars = nigeLab.defaults.Sync;
blockObj.SyncPars.File = fullfile(sprintf(blockObj.paths.DW_N,...
                                    blockObj.SyncPars.ID));

                                 
flag = true;


end