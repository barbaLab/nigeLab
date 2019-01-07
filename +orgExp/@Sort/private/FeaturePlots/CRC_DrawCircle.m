function [X,Y] = CRC_DrawCircle(obj,ch,clust,sel1,sel2,scaling)
%% CRC_DRAWCIRCLE   Draw the feature-radius circle 
scaling = scaling/4; % Increase sampling for 2-D
X = cos(0:scaling*pi:2*pi)*obj.Data.cl.num.rad{ch}(clust);
X = X + obj.Data.cl.num.centroid{ch,clust}(sel1);
Y = sin(0:scaling*pi:2*pi)*obj.Data.cl.num.rad{ch}(clust);
Y = Y + obj.Data.cl.num.centroid{ch,clust}(sel2);
end