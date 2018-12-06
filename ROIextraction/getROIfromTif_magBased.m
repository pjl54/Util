% Returns the ROI defined by the annotation.  This replaces a half dozen
% cobbled together functions

% Inputs:
% imgPath         - string, path to image file
% annotation      - struct, with fields X and Y containing the X and Y coordinates of the ordered set of verticies defining the ROI boundary
% inputMag        - integer, the original magnification of the image
% outputMag       - integer, the desired output magnification
% rot             - not used, kept just for compatability reasons

% Output:
% ROI             - 3D uint8, RGB image of ROI, cropped from original as rectangular image
% mask            - 2D logical, mask to be applied to get ROI from rectangle
% Patrick Leo - 2017
% October 2017: removed rotation from input list, added nargout
% consideration
% July 2018: changed imgWidths = extractfield(imgInfo,'Width') to
% imgWidths = [imgInfo.Width] to avoid checking out MAP toolbox license
function [ROI mask] = getROIfromTif(imgPath,annotation,inputMag,outputMag,rot)

% If we were given a BF reader object in imgPath
if(~isstring(imgPath) && ~ischar(imgPath))
    reader = imgPath;
    imgPath = 'dummy.czi';
end

formatsThatNeedBF = {'czi','ndpi'}; % These are formats that aren't supported by imread or openslide

if(nargin < 5)
    rot = [];
end

% Matlab rotates some files (.scn, .tiff) when reading them in, need to undo this
if(strcmp(imgPath(end-3:end),'.scn'))
    rotation = 270;
elseif(strcmp(imgPath(end-3:end),'.tiff'))
    rotation = 180; % not actually implemented here
else
    rotation = 0;
end

resFactor = inputMag/outputMag;

if(any(strcmp(imgPath(end-2:end),formatsThatNeedBF)))
    
    if(~exist('reader','var'))
        reader = bfGetReader(imgPath);    
    end
    
    omeMeta = reader.getMetadataStore();
    
    numMags = omeMeta.getImageCount;
    imgWidths = zeros(1,numMags);
    imgHeights = zeros(1,numMags);
    for(k = 1:omeMeta.getImageCount)
        imgWidths(k) = omeMeta.getPixelsSizeX(k-1).getValue();
        imgHeights(k) = omeMeta.getPixelsSizeY(k-1).getValue();
    end
else
    imgInfo = imfinfo(imgPath);
    % extractfield uses the MAP toolbox, which CWRU only has 4 licenses for
    % imgWidths = extractfield(imgInfo,'Width');
    % imgHeights = extractfield(imgInfo,'Height');
    imgWidths = [imgInfo.Width];
    imgHeights = [imgInfo.Height];
    
end

[~,baseLayer] = max(imgWidths); % find which layer is highest magnification

% Only consider layers larger than the desired output, downsize later if
% needed.  "+ resFactor" is because every downsize can cut a few pixels off
% due to rounding, wouldn't want to exclude an exact outputMag match.
validLayers = find((imgWidths - imgWidths(baseLayer)/resFactor) + resFactor > 0);
[~,vTarget] = min(abs(imgWidths(validLayers) - imgWidths(baseLayer)/resFactor));
targetLayer = validLayers(vTarget);
amountToReduceByLater = imgHeights(targetLayer) / (imgHeights(baseLayer) / resFactor); % if targetLayer doesn't match outputMag
targetAnnoDown = resFactor/amountToReduceByLater; % how much to downsize annotation by when getting region, corresponds to magnification of targetLayer


if(any(strcmp(imgPath(end-2:end),formatsThatNeedBF)))
    x = min(annotation.X);
    y = min(annotation.Y);
    w = max(annotation.X)-min(annotation.X);
    h = max(annotation.Y)-min(annotation.Y);
    
    ef = bfopenSpecificLayer(reader,targetLayer,x,y,w,h);
    rgb = cat(3,ef{1}{1,1},ef{1}{2,1},ef{1}{3,1});
%     r = bfGetPlane(reader,1,x,y,w,h);
%     g = bfGetPlane(reader,2,x,y,w,h);
%     b = bfGetPlane(reader,3,x,y,w,h);   
%     rgb = cat(3,r,g,b);

else
    % Need to account for possible rotation
    switch rotation
        case 0
            rgb = imread(imgPath,'Index',targetLayer,'PixelRegion',{[round(min(annotation.Y/targetAnnoDown)),round(max(annotation.Y/targetAnnoDown))],...
                [round(min(annotation.X/targetAnnoDown)),round(max(annotation.X/targetAnnoDown))]});
        case 270
            rgb = imread(imgPath,'Index',targetLayer,'PixelRegion',{[round(imgInfo(targetLayer).Height - max(annotation.X/targetAnnoDown)),round(imgInfo(targetLayer).Height - min(annotation.X/targetAnnoDown))],...
                [round(min(annotation.Y/targetAnnoDown)),round(max(annotation.Y/targetAnnoDown))]});
    end
end

rgb = imrotate(rgb,rotation);
rgb = imresize(rgb,1/amountToReduceByLater);

mask = poly2mask(round(annotation.X/resFactor - min(annotation.X/resFactor)),round(annotation.Y/resFactor - min(annotation.Y/resFactor)),...
    round(max(annotation.Y/resFactor)-min(annotation.Y/resFactor)),round(max(annotation.X/resFactor)-min(annotation.X/resFactor)));

% zero pad or reduce mask to match size of image
% rgb and mask can have different sizes due to rounding
if(size(mask,1) > size(rgb,1))
    mask = mask(1:size(rgb,1),:);
elseif(size(mask,1) < size(rgb,1))
    mask = padarray(mask,[size(rgb,1) - size(mask,1) 0],'post');
end

if(size(mask,2) > size(rgb,2))
    mask = mask(:,1:size(rgb,2));
elseif(size(mask,2) < size(rgb,2))
    mask = padarray(mask,[0 size(rgb,2) - size(mask,2) 0],'post');
end

ROI = rgb;

if(nargout == 1)
    ROI = ROI .* uint8(repmat(mask,1,1,size(ROI,3)));
    ROI = ROI + uint8(repmat(~mask,1,1,3))*255;
end