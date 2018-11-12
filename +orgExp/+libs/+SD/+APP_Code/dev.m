function clu = dev(features, pp, pw)
K = 4;
% D = 500;

SIGMA = 'full';
SHARED_COV = false;
THRESH = sqrt(chi2inv(0.99,2));
MAX_ITERATIONS = 1000;
DT_PK = {'\deltat','peak height'};

dt = (log(pp)-mean(log(pp)))./std(log(pp));
pk = (log(pw)-mean(log(pw)))./std(log(pw));

Z = [features, dt.', pk.'];
nf = size(features,2);

% comb = repmat(1:nf,2,1);
% comb = comb(:);

% dtpk = repmat((nf+1):(nf+2),nf,1);
% dtpk = dtpk(:);

% comb_list = [comb, dtpk];

comb_list = nchoosek(1:size(Z,2),2);
nCombos = size(comb_list,1);
clu = zeros(size(Z,1),nCombos);

% mh = zeros(size(Z,1),nZ);
% leg_str = [];
% for iK = 1:K
%    leg_str = [leg_str, {num2str(iK)}]; %#ok<AGROW>
% end

for iZ = 1:nCombos
   X = Z(:,comb_list(iZ,:));


   options = statset('MaxIter',MAX_ITERATIONS); % Increase number of EM iterations


   gmfit = fitgmdist(X,K, ...
      'CovarianceType',SIGMA,...
      'SharedCovariance',SHARED_COV, ...
      'Options',options);
   
   clu(:,iZ) = cluster(gmfit,X);
   
%    figure;
%    x1 = linspace(min(X(:,1)) - 2,max(X(:,1)) + 2,D);
%    x2 = linspace(min(X(:,2)) - 2,max(X(:,2)) + 2,D);
%    [x1grid,x2grid] = meshgrid(x1,x2);
%    X0 = [x1grid(:) x2grid(:)];
%    mh_d = mahal(gmfit,X);
%    mhEllipses = mahal(gmfit,X0);
%    h1 = gscatter(X(:,1),X(:,2),clu(:,iZ));
%    hold on;
%    for m = 1:max(clu(:,iZ))
%       idx = mhEllipses(:,m)<=THRESH;
%       mh(mh_d(:,m)<=THRESH,iZ) = m;
%       col = h1(m).Color*0.75 + -0.5*(h1(m).Color - 1);
%       h2 = plot(X0(idx,1),X0(idx,2),'.',...
%          'Color',col,...
%          'MarkerSize',1);
%       uistack(h2,'bottom');
%    end
%    plot(gmfit.mu(:,1),gmfit.mu(:,2),'kx',...
%       'LineWidth',2,...
%       'MarkerSize',10)
   
%    str = sprintf('Feature %d vs %s',...
%       comb_list(iZ,1),...
%       DT_PK{comb_list(iZ,2)-nf});
%    title(str,...
%       'FontName','Arial',...
%       'FontSize',16);
%    legend(h1,leg_str);
%    hold off
end
end