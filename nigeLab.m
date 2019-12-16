function nigelDash = nigeLab(tankObj)
% NIGELAB  Graphical wrapper to nigeLab package
%
%  nigelDash = nigeLab();  Allows selection of tank object from UI
%  nigelDash = nigeLab(tankObj); Specify tank object as input directly
%  nigelDash = nigeLab(tankPath); Specify filename or path to tank
%
%  nigelDash  --  Handle to nigeLab.libs.DashBoard class graphical
%                    interface to nigeLab

%% Parse input
if nargin < 1
   tankObj = [];
end

switch class(tankObj)
   case 'nigeLab.Tank' % actual tank object
      nigelDash = nigeLab.libs.DashBoard(tankObj);
      
   case 'char' % path or filename
      tankName = fullfile(tankObj); 
      clear('tankObj');
      if exist(tankName,'file')~=0
         load(tankName,'tankObj');
      end
      
      
      nigelDash = nigeLab.libs.DashBoard(tankObj);
      
   case 'double' % []
      
      
   otherwise
      error('Bad input type: %s',class(tankObj));
end

end