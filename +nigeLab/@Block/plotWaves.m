function flag = plotWaves(blockObj,ax,field,idx,computeRMS)
%% PLOTWAVES  Plot multi-channel waveform snippets for BLOCK
%
%  flag = PLOTWAVES(blockObj);
%
%  --------
%   INPUTS
%  --------
%  blockObj :     BLOCK class object from orgExp package.
%
%  --------
%   OUTPUT
%  --------
%    flag   :     Returns true if the figure is successfully generated.
%
%  See also: PLOTCHANNELS
%
% By: Max Murphy  v1.1  06/14/2018  Added flag output.

%% DEFAULTS
flag = false;
% blockObj.Pars.Pars.Plot = nigeLab.defaults.Plot();
%% FIGURE OUT WHAT TO PLOT
str_in = blockObj.getStatus;

%% Parse first input for axes reference
if isa(ax,'matlab.graphics.axis.Axes')
    fig = ax.Parent;
    nargs = nargin-1;
else
    field = ax;
    nargs = nargin;

    fig = figure('Name',sprintf('Multi-Channel %s Snippets',field), ...
        'Units','Normalized', ...
        'Position',[0.05*rand+0.1,0.05*rand+0.1,0.8,0.8],...
        'Color','w','NumberTitle','off');
    
    ax = axes(fig,'NextPlot','add');
end

%% Parse field input and change options accordingly
if nargs < 2
    [~,idx] = nigeLab.utils.uidropdownbox('Choose Wave Type',...
        'Select type of waveform to plot:',...
        str_in);
    field = str_in{idx};
end

plotSpikesOverlay = false;
switch field
    case 'LFP'
        fs = blockObj.Pars.LFP.DownSampledRate;
    case 'Spikes'
        fs = blockObj.SampleRate;
        plotSpikesOverlay = true;
       if  all(blockObj.getStatus({'CAR'}))
           field = 'CAR';
       elseif  all(blockObj.getStatus({'Filt'}))
           field = 'Filt';
       else
           error('CAR or Filt are needed to overlay spikes!');
       end
    otherwise
        fs = blockObj.SampleRate;
end

%% Get correct index
if nargs < 3    
    tStart = (blockObj.Pars.Plot.DefTime - blockObj.Pars.Plot.PreAlign)/1000;
    iStart = max(1,round(tStart * fs));
    
    tStop = (blockObj.Pars.Plot.DefTime + blockObj.Pars.Plot.PostAlign)/1000;
    iStop = min(blockObj.Samples,round(tStop * fs));
    
    idx = iStart:iStop;
end
t = linspace(idx(1)./fs,idx(end)./fs,numel(idx));
dt = mode(diff(t));

%% RMS input
if nargs < 4
    computeRMS = false;
end



%% ASSIGN CHANNEL COLORS BASED ON RMS
load(blockObj.Pars.Plot.ColorMapFile,'cm');
if isempty(blockObj.RMS) && computeRMS
    analyzeRMS(blockObj);
    r = blockObj.RMS.(field);
    ic = assignColors(r);
elseif ~ismember(field,blockObj.RMS.Properties.VariableNames) && computeRMS
    analyzeRMS(blockObj);
    r = blockObj.RMS.(field);
    ic = assignColors(r);
else
    %Multicolored version
%     cm = nigeLab.defaults.nigelColors(1:blockObj.NumChannels,'cubehelix');
%     ic = 1:blockObj.NumChannels;

    %Monochrome version
    cm = nigeLab.defaults.nigelColors('primary');
    ic = ones(1,blockObj.NumChannels);
    
    r = nan(1,blockObj.NumChannels);
end


%% MAKE FIGURE AND PLOT
tickLabs = cell(blockObj.NumChannels,1);
% tickLocs = 1:blockObj.Pars.Plot.VertOffset:(blockObj.Pars.Plot.VertOffset*(...
%    blockObj.NumChannels));
tickLocs = zeros(1,blockObj.NumChannels);
pixelPos = getpixelposition(ax);
chNum = 1;
for iCh = blockObj.Mask
   tickLabs{iCh} = blockObj.Channels(iCh).custom_channel_name;
   if chNum > 1
   tickLocs(iCh) = tickLocs(iCh-1) + max(2*prctile(y,75),blockObj.Pars.Plot.VertOffset);
   end
   y = blockObj.Channels(iCh).(field)(idx);
   [t_reduced, y_reduced] = nigeLab.utils.reduce_to_width(t, y, pixelPos(end) ,[t(1) t(end)]);
   line(ax,t_reduced,y_reduced+tickLocs(iCh), ...
      'Color',cm(ic(iCh),:), ...
      'LineWidth',1.75,...
      'UserData',iCh,...
      'LineStyle',':'); %#ok<NODEF>
  
  if plotSpikesOverlay
      fs = blockObj.SampleRate;
      Wpre =  blockObj.Pars.SD.WPre * 1e-3;
      Wpost =  blockObj.Pars.SD.WPost * 1e-3;
      
      tSpk = blockObj.getSpikeTimes(iCh);            
      spkToKeep = tSpk < t(end) & tSpk > t(1);
      tSpk = tSpk(spkToKeep,:);
      tSpk = (-Wpre : 1/fs : Wpost) + tSpk;
      spkIndex = logical(sum( ...
          tSpk(:,1) <= t_reduced &  tSpk(:,end) >= t_reduced, 1));
      
      spkBound = conv(spkIndex,[-1 1],'same')>0;
      spkBound(end) = false;
      
      tSpk = t_reduced;
      tSpk(~spkIndex) = nan;
      
      spk = y_reduced;
      spk(~spkIndex) = nan;
      
      line(ax,tSpk,spk+tickLocs(iCh), ...
          'Color','k', ...
          'LineWidth',1.75,...
          'UserData',iCh); %#ok<NODEF>
  end
   
   text(ax,max(t)*1.01,tickLocs(iCh),...
         sprintf('RMS: %.3g',r(iCh)),...
         'FontName','Arial',...
         'FontWeight','bold',...
         'Color','k',...
         'FontSize',10,...
         'UserData',iCh);
   chNum = chNum+1;
end
ax.YTick = tickLocs;
ax.YTickLabel = tickLabs;
xlabel('Time (sec)','FontName','Arial','FontSize',14,'Color','k');
ylabel('Channel','FontName','Arial','FontSize',14,'Color','k');
title(sprintf('Multi-Channel %s Snippets',field),'FontName','Arial',...
   'Color','k','FontSize',20);

xlim(ax,t([1,end]))
ylim(ax,tickLocs([1,end])+ diff(tickLocs([1,end]))*[-.05 .05])
% fname = fullfile(blockObj.paths.TW,...
%    [blockObj.Name sprintf(blockObj.Pars.Plot.SnippetString,str)]);
% 
% savefig(fig,[fname '.fig']);
% saveas(fig,[fname '.png']);
% blockObj.Graphics.Waves = fig; 
flag = true;


   function ic = assignColors(r)
      %% ASSIGNCOLORS   Assign "RMS BINS" different color values
      hvec = [-inf, ...
               linspace(0,14,3),...
               linspace(15,19.99,40),...
               linspace(20,35,20),...
               inf]; % Bin vector with 65 edges (64 bins)
      [~,~,ic] = histcounts(r,hvec);
      ic(isnan(ic)) = 64;
      ic(ic < 1) = 64;
   end

end