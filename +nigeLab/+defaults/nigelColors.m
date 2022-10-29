function [Col] = nigelColors(input,source,map)
%NIGELCOLORS default colors for nigeLab
%  
%   returns one or more colors depending on the input
%
%   input,  numeric array or string.
%
%  To get a list of input color options, call as:
%  <strong>>> nigeLab.defaults.nigelColors('help'); </strong>
%
% ---------------------------------
%   Col,   Color matrix. Nx3, where N is nunmel(input)

switch nargin
   case 0
      % preview the color palette
      Clrs = nigeLab.defaults.nigelColors({1,2,3,4,5,1.1,2.1,3.1,4.1,0,0.1,0.2});
      Clrs = [Clrs; cubehelix(16,2.8,1.9,1.45,0.6,[0.05 0.95],[0 .7])];
      displayPalette(Clrs);
   case 1
      Col = [];
      if ~ischar(input) && numel(input) ~= 1
         Col = [nigeLab.defaults.nigelColors(input(1));...
            nigeLab.defaults.nigelColors(input(2:end))];
         return;
      end
      if iscell(input),Col=nigeLab.defaults.nigelColors(input{1});return;end
      switch lower(input)
         case {'help','opts','options'}
            fprintf(1,'<strong>''primary'',''g'',''enableobj'',''goodobj'',''hl''</strong> -> ');
            nigeLab.utils.cprintf([30, 185, 128]./255,'green\n');
            fprintf(1,'<strong>''secondary'',''dg'',''enable'',''button''</strong> -> ');
            nigeLab.utils.cprintf([4, 93, 86]./255,'dark green\n');
            fprintf(1,'<strong>''disable'',''ddg''</strong> -> ');
            nigeLab.utils.cprintf([4, 55, 32]./255,'darker green\n');
            fprintf(1,'<strong>''tertiary'',''o''</strong> -> ');
            nigeLab.utils.cprintf([255, 104, 89]./255,'orange\n');
            fprintf(1,'<strong>''quaternary'',''y''</strong> -> ');
            nigeLab.utils.cprintf([255, 207, 68]./255,'yellow\n');
            fprintf(1,'<strong>''onprimary'',''k''</strong> -> ');
            nigeLab.utils.cprintf([0 0 0],'black\n');
            fprintf(1,'<strong>''background'',''bg''</strong> -> ');
            nigeLab.utils.cprintf([18, 18, 18]./255,'nearly black\n');
            fprintf(1,'<strong>''surface'',''sfc'',''dark''</strong> -> ');
            nigeLab.utils.cprintf([55, 56, 58]./255,'dark gray\n');
            fprintf(1,'<strong>''disabletext'',''med''</strong> -> ');
            nigeLab.utils.cprintf([125, 125, 125]./255,'medium gray\n');
            fprintf(1,'<strong>''light'',''light_grey''</strong> -> ');
            nigeLab.utils.cprintf([220, 220, 220]./255,'light gray\n');
            fprintf(1,'''onsecondary'',''onbutton'',''onsurface'',''rollover'',''enabletext'',''w'' -> ');
            nigeLab.utils.cprintf([1 1 1],'white\n');
            fprintf(1,'<strong>''r'',''red'',''disableobj'',''badobj''</strong> -> ');
            nigeLab.utils.cprintf([240, 25, 25]./255,'red\n');
            fprintf(1,'<strong>''m'',''magenta''</strong> -> ');
            nigeLab.utils.cprintf([240, 25, 240]./255,'magenta\n');
            fprintf(1,'<strong>''b'',''blue''</strong> -> ');
            nigeLab.utils.cprintf([67 129 193]./255,'blue\n');
         case {'primary','g','green','highlight','hl','goodobj','enableobj',1}
            Col = [30, 185, 128]./255;   % green
         case {'secondary','dg','darkgreen','button','enable',2}
            Col = [4, 93, 86]./255;      % dark green
         case {'disable','ddg','darkergreen',2.5}
            Col = [4, 55, 32]./255;      % darker green
         case {'tertiary','o','orange',3}
            Col = [255, 104, 89]./255;   % orange
         case {'quaternary','y','yellow',4}
            Col = [255, 207, 68]./255;   % yellow
         case {'onprimary','k','black','ontertiary','onquaternary',1.1}
            Col = [0, 0, 0]./255; % black
         case {'background','bg',0}
            Col = [18, 18, 18]./255; % nearly black
         case {'surface','sfc','dark_gray','dark_grey','dark',0.1}
            Col = [55, 56, 58]./255; % dark grey
         case {'disabletext','med_gray','med_grey','med'}
            Col = [125, 125, 125]./255;
         case {'light_grey','light_gray','light'}
            Col = [220, 220, 220]./255; % light grey
         case {'onsecondary','w','white','rollover','onbutton','enabletext','onsurface','onsfc',2.1,0.2} 
            Col = [255, 255, 255]./255; % white
         case {'r','red','disableobj','badobj'}
            Col = [240, 25, 25]./255; % red
         case {'m','magenta'}
            Col = [240, 25, 240]./255; % magenta
         case {'b','blue'}
            Col = [67 129 193]./255; % blue
         otherwise
            Col = [0, 0, 0]./255;
            warning('%s is not a recognized nigelColors option.',input);
      end
   case 2
       maxColorSteps = 25;
      switch source
         case 'cubehelix'
            if not(isnumeric(input))
               % Something is wrong
               Col = [];
               return;
            else
               idx = mod(input-1,maxColorSteps)+1;
               Clrs = nigeLab.utils.cubehelix(maxColorSteps,1.45,1.57,2.20,0.78,[0.25 0.57],[0.28 .82]);
               Col = Clrs(idx,:);
            end
          case 'brewer'
              if not(isnumeric(input))
                  % Something is wrong
                  Col = [];
                  return;
              else
                  if nargin < 3 || isempty(map)
                      map = 'Pastel2';
                  end
                  Clrs = nigeLab.utils.brewermap(max(input),map);
                  Col = Clrs(input,:);
              end
      end
end




   function displayPalette(Clrs)
      ind=1:size(Clrs,1);
      f=figure('Color',[1 1 1],'Units','normalized');
      f.Position=[.01 .15 .07*size(Clrs,1) .7];
      ax=axes(f, 'Position',[0.01 0.2 0.98 0.7]);
      
      hBar=bar(ax,ind,ones(size(ind)),'EdgeColor','flat','FaceColor','flat','CData',Clrs);
      set(ax.YAxis,'Visible','off');
      set(ax,'XLim',[ind(1)-.5 ind(end)+.5],'Box','off');
      ax.XTickLabel=cellstr(num2str(Clrs));
      
      for ii=ind
         ann = text(ii,.8,num2str(ii));
         ann.FontSize=20;
      end
      
      
   