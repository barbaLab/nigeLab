function L = list(tankObj)
%% LIST  List BLOCK objects in parent TANK
%
%  blockList = LIST(tankObj);
%
%  --------
%   INPUTS
%  --------
%   tankObj    :     TANK Class object.
%
%  --------
%   OUTPUT
%  --------
%  blockList   :     List of BLOCK Class objects in this tank.
%                    Returns an empty array if no BLOCKS are in TANK.
%
% By: Max Murphy  v1.0  06/14/2018  Original version (R2017b)

%%
% if isempty(tankObj.Block)
%    L = [];   
% else
%    L = cell(size(tankObj.Block));
%    
%    fprintf(1,'Blocks in %s:\n',tankObj.Name);
%    fprintf(1,'---------------------------------\n\n');
%    for ii = 1:numel(tankObj.Block)
%       fprintf(1,'->\t%s\n',tankObj.Block(ii).Name);
%       L{ii} = tankObj.Block(ii).Name;
%    end
%    
% end

VariableNames = {'Key';
                 'Animals';
                 'Recording_date';
                 'RecordingType';
                 'NumberOfBlocks';
                 'NumberOfChannels';     
                 'Status';
                    };
                
GatherFunction = { @(an) {num2str(an.UserData)};
                   @(an) an.Name;
                   @(an) getAnimalDate(an)
                   @(an) getRecDate(an);
                   @(an) numel(an.Blocks);
                   @(an) getNChannel(an);
                   @(an) getAnimalStatus(an);
    };

Lstruc=cell2struct(cell(1,numel(VariableNames)),VariableNames,2);

for ii=1:numel(tankObj.Animals)
    an=tankObj.Animals(ii);
    an.UserData = ii;
    if isempty(an.Blocks)
       Lstruc(ii).(VariableNames{1}) = GatherFunction{1}(an);
       Lstruc(ii).(VariableNames{2}) = 'Empty';
       for kk=3:numel(VariableNames)
          Lstruc(ii).(VariableNames{kk}) = '---';
       end
    else
       for kk=1:numel(VariableNames)
          Lstruc(ii).(VariableNames{kk}) =  GatherFunction{kk}(an);
       end
    end
%     I=ismember(tmp.Properties.VariableNames,'Animals');
%     L_(jj,:)=[tmp(1,I),tmp(1,~I)];
end

Lstruc=struct2table(Lstruc);
Lstruc.Properties.RowNames=cellstr(num2str((1:numel(tankObj.Animals))'));


if nargout==0
    disp(Lstruc);
else
    L=(Lstruc);
end

end

function Status = getAnimalStatus(animalObj)
    L = animalObj.list;
    Status = unique(L.Status)';
    Status = sprintf([repmat('%s;',1,numel(Status)) '\b'],Status{:});
end

function D = getAnimalDate(animalObj)
   try
      tmp = cat(1,animalObj.Blocks.Meta);
      D = unique(datetime({tmp.RecDate},'InputFormat','yyMMdd'));
   catch
      D = NaT;
   end
end

function N = getNChannel(animalObj)
b = animalObj.Blocks;
N = {unique(cat(1,b.NumChannels))};
end

function R = getRecDate(animalObj)
b = animalObj.Blocks;
rt = unique({b.RecType});
fe = unique({b.FileExt});
R = [rt, fe];
end