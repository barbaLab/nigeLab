function setClass(sortObj,class)
%% SETCLASS    Set class on current channel
%
%  sortObj.setClass(class);
%
%  --------
%   INPUTS
%  --------
%  sortObj     :     nigeLab.Sort class object
%
%   class      :     Cluster "class" ID values
%
%  --------
%   OUTPUT
%  --------
%  Updates the associated sorting class ID in Sort object, which are then
%  used for the 'Undo' feature and also ultimately what gets saved.
%
% By: Max Murphy  v1.0  2019-02-14  Original version (R2017a)

%% 
sortObj.spk.class{get(sortObj,'channel')} = class;

end