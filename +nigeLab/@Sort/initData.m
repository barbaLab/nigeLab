function flag = initData(sortObj,nigelObj)
%% INITDATA  Initialize data structure for Spike Sorting UI
%
%  flag = INITDATA(sortObj);
%  flag = INITDATA(sortObj,nigelObj);
%
%  --------
%   INPUTS
%  --------
%   sortObj    :     nigeLab.Sort class object that is under construction.
%
%  nigelObj    :     (Optional) Can be either:
%                       -> 1 or more nigeLab.Block objects
%                       -> 1 or more nigeLab.Animal objects
%                       -> 1 nigeLab.Tank object
%
% By: Max Murphy  v3.0    01/07/2019 Port to object-oriented architecture.
%                 v2.0    10/03/2017 Added ability to handle multiple input
%                                    probes with redundant channel labels.
%                 v1.0    08/18/2017 Original version (R2017a)

%% PARSE INPUT
flag = false;
if nargin > 1
   % Parse input argument type
   switch class(nigelObj(1))
      case 'nigeLab.Block'
         if ~parseBlocks(sortObj,nigelObj)
            warning('Could not parse nigeLab.Block objects.');
            return;
         end
      case 'nigeLab.Animal'
         if ~parseAnimals(sortObj,nigelObj)
            warning('Could not parse nigeLab.Animal objects.');
            return;
         end
      case 'nigeLab.Tank'
         if numel(nigelObj) > 1
            warning('Only 1 nigeLab.Tank object can be scored at a time.');
            return;            
         else
            if ~parseAnimals(sortObj,nigelObj.Animals)
               warning('Could not parse nigeLab.Animal objects.');
               return;
            end
         end         
      otherwise
         warning(['%s is an invalid input type.\n' ...
                  'Must be a Block, Animal, or Tank object array.'],...
                  class(nigelObj(1)));
         return;
   end
   
else   
   [fName,pName,~] = uigetfile(sortObj.pars.INFILE_FILT,...
                               sortObj.pars.INFILE_PROMPT,...
                               sortObj.pars.INFILE_DEF_DIR,...
                               'MultiSelect','on');
                               
   if iscell(fName) % Load array and run using recursion
      nigelObjArray = [];
      for ii = 1:numel(fName)
         in = load(fullfile(pName,fName{ii}));
         f = fieldnames(in);
         nigelObjArray = [nigelObjArray; in.(f{1})]; %#ok<AGROW>
      end
      flag = initData(sortObj,nigelObjArray);
      return;
      
   else % Otherwise, just load it and run init using recursion
      in = load(fullfile(pName,fName));
      f = fieldnames(in);
      flag = initData(sortObj,in.(f{1}));
      return;
   end
   
end

%% INITIALIZE SPK AND CLU PROPERTY STRUCTS

sortObj.spk.include.in = cell(sortObj.Channels.N,1);
sortObj.spk.include.cur = cell(sortObj.Channels.N,1);
sortObj.spk.fs = nan(sortObj.Channels.N,1);
sortObj.spk.nfeat = nan(sortObj.Channels.N,1);
sortObj.spk.peak_train = cell(sortObj.Channels.N,1);
sortObj.clu.num.centroid=cell(sortObj.Channels.N,sortObj.pars.NCLUS_MAX);
sortObj.clu.tag.name = cell(sortObj.Channels.N,1);
sortObj.clu.tag.val = cell(sortObj.Channels.N,1);
sortObj.clu.num.class.in=cell(sortObj.Channels.N,1);
sortObj.clu.num.class.cur = cell(sortObj.Channels.N,1);
sortObj.clu.sel.in = cell(sortObj.Channels.N,sortObj.pars.NCLUS_MAX);
sortObj.clu.sel.base = cell(sortObj.Channels.N,sortObj.pars.NCLUS_MAX);
sortObj.clu.sel.cur = cell(sortObj.Channels.N,sortObj.pars.NCLUS_MAX);

sortObj.pars.zmax = 0;
sortObj.pars.nfeatmax = 0;
for iCh = 1:sortObj.Channels.N % get # clusters per channel   
  
   sortObj.spk.include.in{iCh,1} = true(size(in_feat.features,1),1);
   sortObj.spk.include.cur{iCh,1} = true(size(in_feat.features,1),1);
   sortObj.spk.nfeat(iCh) = size(in_feat.features,2);
   
   sortObj.pars.nfeatmax = max(sortObj.pars.nfeatmax,sortObj.spk.nfeat(iCh));

   
   % Load classes. 1 == OUT; all others (up to NCLUS) are valid
   if sorted_flag
      in_class = load(sortObj.clu.fname{iCh},'class');
   else
      in_class = struct;
      in_class.class = ones(size(in_feat.features,1),1);
   end
   
   if min(in_class.class) < 1
      in_class.class = in_class.class + 1;
   end
   
   % Assign "other" clusters as OUT
   in_class.class(in_class.class > numel(sortObj.clu.tag.defs)) = 1;
   in_class.class(isnan(in_class.class)) = 1;
   
   % For "selected" make copy of original as well.
   sortObj.clu.num.class.in{iCh} = in_class.class;
   sortObj.clu.num.class.cur{iCh} = in_class.class;
   sortObj.clu.tag.name{iCh} = sortObj.clu.tag.defs(in_class.class);
   
   % Get each cluster centroid and membership
   val = [];
   for iN = 1:sortObj.pars.NCLUS_MAX
      if isempty(sortObj.clu.tag.defs{iN})
         tags_val = 1;
      else
         tags_val = find(ismember(sortObj.pars.Labels(2:end),...
            sortObj.clu.tag.defs(iN)),1,'first');
         if isempty(tags_val)
            tags_val = 1;
         else
            tags_val = tags_val + 1;
         end
      end
      val = [val, tags_val]; %#ok<AGROW>
      sortObj.clu.num.centroid{iCh,iN} = median(in_feat.features(...
         in_class.class==iN,:));
      sortObj.clu.sel.in{iCh,iN}=find(sortObj.clu.num.class.in{iCh}==iN);
      sortObj.clu.sel.base{iCh,iN}=find(sortObj.clu.num.class.in{iCh}==iN);
      sortObj.clu.sel.cur{iCh,iN}=find(sortObj.clu.num.class.in{iCh}==iN);
   end
   sortObj.clu.tag.val{iCh} = val;
   
end
clear features
fprintf(1,'complete.\n');


flag = true;
end