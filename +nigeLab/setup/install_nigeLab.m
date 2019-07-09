%% this script will install nigeLab and check licences

%% check licences
%% parallel computing toolbox 
is_parallel_licence=license('test','Distrib_Computing_Toolbox'); 
if is_parallel_licence
    disp('You are using a Matlab version with the Parallel Computing Toolbox')
else
   warning('You are using a Matlab version with NO Parallel Computing Toolbox, this will affect nigeLab performances')
end

%% wavelet toolbox
is_wavelet_licence=license('test','Wavelet_Toolbox'); 
if is_wavelet_licence
    disp('You are using a Matlab version with the Wavelet Toolbox')
else
   warning('You are using a Matlab version with NO Wavelet Toolbox, this will affect nigeLab sorting')
end

%% signal processing toolbox
is_signal_proc_licence=license('test','Signal_Toolbox'); 
if is_signal_proc_licence
    disp('You are using a Matlab version with the Signal Processing Toolbox')
else
   error('You are using a Matlab version with NO Signal Processing Toolbox, this is mandatory for nigeLab')
end

% Determine where your m-file's folder is.
setup_folder = fileparts(which(mfilename)); 
cd(setup_folder)
cd ..

%% install WidgetToolbox
cd('+utils')
toolboxFile = 'Widgets Toolbox 1.3.330.mltbx';
installedToolbox = matlab.addons.toolbox.installToolbox(toolboxFile);

%% add nigeLab to path
cd ..
cd ..
addpath(pwd)
disp('ePhys_packages and thus nigeLab added to path')
% Add that folder plus all subfolders to the path.
% addpath(genpath(setup_folder));