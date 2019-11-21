function header_ = fixNamingConvention(header)
%% FIXNAMINGCONVENTION  Remove '_' and switch to CamelCase
%
%  header_ = nigeLab.utils.FIXNAMINGCONVENTION(header);
%
%  Returns struct header_, which is identical to input struct header, but
%     with fieldnames named in convention used for Property names in
%     nigeLab.

%%
header_ = struct;
f = fieldnames(header);
for iF = 1:numel(f)
   str = strsplit(f{iF},'_');
   for iS = 1:numel(str)
      str{iS}(1) = upper(str{iS}(1));
   end
   str = strjoin(str,'');
   header_.(str) = header.(f{iF});
end

end