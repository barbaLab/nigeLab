function runFun(tankObj,f)
% RUNFUN   Run function f on all child Blocks in tank
%
%  example:
%  runFun(myTank,'checkMask'); Runs the function 'checkMask' of all child
%                              Blocks in the Tank.

%% Check if it is a valid method
clc;
fprintf(1,' \n');
nigeLab.utils.cprintf('*Blue','%s: ',tankObj.Name);
if ismethod(tankObj.Animals(1).Blocks(1),f)
   nigeLab.utils.cprintf('*Magenta','%s method\n',f);
else
   nigeLab.utils.cprintf([0.3 0.3 0.3],'%s is not a ',f);
   nigeLab.utils.cprintf('*Red', 'BLOCK');
   nigeLab.utils.cprintf([0.3 0.3 0.3],' method\n\n',f);
   return;
end

%% Iterate on all Blocks, of all Animals
for iA = 1:numel(tankObj.Animals)
   nigeLab.utils.cprintf('Comment-','->\t%s\n',tankObj.Animals(iA).Name);
   for iB = 1:numel(tankObj.Animals(iA).Blocks)
      nigeLab.utils.cprintf('Text','\t->\t%s - ',...
         tankObj.Animals(iA).Blocks(iB).Name);
      try
         tankObj.Animals(iA).Blocks(iB).(f);
         nigeLab.utils.cprintf('*Blue', 'successful\n');
      catch
         nigeLab.utils.cprintf('*Red', 'unsuccessful\n');
      end
   end
   fprintf(1,' \n');
end

end