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

VariableNames = {'Animals';
                 'Recording_date';
                 'RecordingType';
                 'NumberOfBlocks';
                 'NumberOfChannels';     
                 'Status';
                    };
                
GatherFunction = { @(an) an.Name;
                   @(an) unique(datetime(cat(1,an.Blocks.Recording_date),'InputFormat','yyMMdd'));
                   @(an) [unique({an.Blocks.RecType}), unique({an.Blocks.File_extension})];
                   @(an) numel(an.Blocks);
                   @(an) unique(cat(1,an.Blocks.numChannels));
                   @(an) getAnimalStatus(an);
    };

Lstruc=cell2struct(cell(1,numel(VariableNames)),VariableNames,2);

for ii=1:numel(tankObj.Animals)
    an=tankObj.Animals(ii);
    for kk=1:numel(VariableNames)
        Lstruc(ii).(VariableNames{kk}) =  GatherFunction{kk}(an);
    end
%     I=ismember(tmp.Properties.VariableNames,'Animals');
%     L_(jj,:)=[tmp(1,I),tmp(1,~I)];
end

if nargout==0
    disp(struct2table(Lstruc));
else
    L=struct2table(Lstruc);
end

end

function Status = getAnimalStatus(animalObj)
    L = animalObj.list;
    Status = unique(L.Status)';
    Status = sprintf([repmat('%s;',1,numel(Status)) '\b'],Status{:});
end