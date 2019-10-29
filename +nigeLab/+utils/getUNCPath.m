function [ uncPath ] = getUNCPath( p )
%% [ uncPath ] = getUNCPath( path )
% returns UNC formatted path of the input path.
if isempty(p),uncPath=p;return;end

p = nigeLab.utils.GetFullPath.GetFullPath(p);
pathParts = strsplit(p,filesep);
if isempty(pathParts{1}),uncPath=p;return;end
switch isunix
    case true  % TODO. linux or mac.
       fprintf('TODO.')
    case false
        attempt = getUncPathFromMappedDrive(pathParts{1});
        if isempty(attempt)
            attempt = fullfile('\\localhost',lower(sprintf('%s$',pathParts{1}(1))));
        end
        pathParts{1} = attempt;
end

uncPath = fullfile(pathParts{:});

end

