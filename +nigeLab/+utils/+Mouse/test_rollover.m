clear
close all

% Figure
fig_hdl = figure('Color', [0 0 0]);

% Pushbuttons
import_icons; % Import icons from bmp files
button1_hdl = uicontrol('Style', 'pushbutton', 'Pos', [50 200 40 40], 'CData', ok);
button2_hdl = uicontrol('Style', 'pushbutton', 'Pos', [150 60 40 40], 'String', '2', 'CData', down);
button3_hdl = uicontrol('Style', 'pushbutton', 'Pos', [200 240 80 20], 'String', 'Button 3');
button4_hdl = uicontrol('Style', 'pushbutton', 'Pos', [200 320 40 40], 'String', '', 'CData', add);

% Instantiate a rollover object on current figure
ro = rollover(fig_hdl);

% Set list of "rollover-allowed" pushbuttons
% ---
% Set pushbuttons handles
set(ro, 'Handles', [button1_hdl button2_hdl button3_hdl button4_hdl]);
% Set strings during rollover
set(ro, 'StringsOver', {'1''', '2''', '', '4'''});
% Set icons during rollover
set(ro, 'IconsOver', {cancel, up, [], remove});