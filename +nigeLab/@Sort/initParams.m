function flag = initParams(sortObj)
%% INITPARAMS  Initialize parameters structure for Spike Sorting UI.
%
%  flag = INITPARAMS(sortObj);
%
% By: Max Murphy  v3.0    01/07/2019 Port to object-oriented architecture.
%                 v2.0    10/03/2017 Added ability to handle multiple input
%                                    probes with redundant channel labels.
%                 v1.0    08/18/2017 Original version (R2017a)

%% MODIFY SORT CLASS OBJECT PROPERTIES HERE
flag = false;

pars = nigeLab.defaults.Sort();

%% COULD ADD PARSING FOR PROPERTY VALIDITY HERE?
% To look into for future...
%
%  e.g. Check that "SDMAX" is numeric, and greater than "SDMIN" etc...

%% UPDATE PARS PROPERTY
sortObj.pars = pars;
flag = true;

end