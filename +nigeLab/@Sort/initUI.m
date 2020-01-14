function flag = initUI(sortObj)
%INITUI  Initialize graphics handles for Spike Sorting UI
%
%  flag = INITUI(sortObj);

% Construct nigeLab.libs.SortUI object
flag = false;
sortObj.UI = nigeLab.libs.SortUI(sortObj);
addChannelSelector(sortObj.UI);
addSpikeImage(sortObj.UI);
addFeaturesUI(sortObj.UI);
flag = true;
end