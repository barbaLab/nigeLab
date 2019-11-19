function CData = load_ratskull_plot_img(res)
%% LOAD_RATSKULL_PLOT_IMG  utils.load_ratskull_plot_img;
%
%  Returns image array for ratskull_plot class object.
%
%  CData = load_ratskull_plot_img; % return full-resolution image
%  CData = load_ratskull_plot_img('low'); % return low-resolution image
%  

%% PARSE INPUT
if nargin < 1
   res = 'full';
end

%% CAN CHANGE THESE BASED ON IMAGE LOCATION 
% Note that the sub-folder (img_folder) should be in +utils
img_folder = 'img';
img_file = struct(... % Struct where fields are 'res' and value is fname
            'full','Skull-Brain.png',...
            'low','Skull-Brain_low-res.png');

%% Get the full filepath
thispath = mfilename('fullpath');
thispath = fileparts(thispath);

%% Return data
if ~ismember(res,fieldnames(img_file))
   error('Input ''res'' (%s) is not a valid filename option.',res);
end
CData = imread(fullfile(thispath,img_folder,img_file.(res)));

end