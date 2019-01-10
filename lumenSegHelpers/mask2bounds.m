function bounds = mask2bounds(img,isobjectblack)
%% takes in an image mask and extracts boundaries and centroids from it
% Original version written by George Lee in time immemorial

% Updated by Patrick Leo, June 2018
% - added parfor loop and all associated code to run in parallel
% - removed unneeded code for vectorizing mask and working with it in
% vector form

% Updated by Patrick Leo, October 2018
% Replaced this whole mess with matlab builtin functions for a billion
% percent speedup

% threshold - get rid of bad image compression in jpg.
pres = max(double(img(:)));
img(img > pres/2) = pres;
img(img < pres/2) = 0;

if exist('isobjectblack','var')
    mask = logical(~img); % object is black
else
    mask = logical(img); % object is white
end

mask = imfill(mask,'holes');

S = regionprops(mask,'Centroid');
bwbd = bwboundaries(mask);

bounds(length(S)).r = [];
bounds(length(S)).c = [];
bounds(length(S)).centroid_r = [];
bounds(length(S)).centroid_c = [];


for(k = 1:length(S))
    bounds(k).r = bwbd{k}(:,1)';
    bounds(k).c = bwbd{k}(:,2)';
    bounds(k).centroid_r = S(k).Centroid(2);
    bounds(k).centroid_c = S(k).Centroid(1);
end

% imshow(img); hold on;
% 
% % for i = 1:numel(bounds)
% %     plot([bounds(i).r bounds(i).r(1)], [bounds(i).c bounds(i).c(1)]); hold on
% %     plot(bounds(i).centroid_c,bounds(i).centroid_r,'r.');
% % end
% 
for i = 1:numel(bounds)
    plot([bounds(i).c bounds(i).c(1)], [bounds(i).r bounds(i).r(1)]); hold on
    plot(bounds(i).centroid_c,bounds(i).centroid_r,'r.');
end

