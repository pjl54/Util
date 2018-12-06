% Region specified as [xStart width yStart height] or 'middle'
function [ROI mask] = getRegionOfROIfromTif(imgPath,annotation,inputMag,outputMag,region,regionEdgeLength)

% Matlab rotates some files (.scn, .tiff) when reading them in, need to undo this
if(strcmp(imgPath(end-3:end),'.scn'))
    rotation = 270;
elseif(strcmp(imgPath(end-3:end),'.tiff'))
    rotation = 180; % not actually implemented here
else
    rotation = 0;
end

resFactor = inputMag/outputMag;

imgInfo = imfinfo(imgPath);
imgWidths = extractfield(imgInfo,'Width');
imgHeights = extractfield(imgInfo,'Height');
[~,baseLayer] = max(imgWidths); % find which layer is highest magnification

% Only consider layers larger than the desired output, downsize later if
% needed.  "+ resFactor" is because every downsize can cut a few pixels off
% due to rounding, wouldn't want to exclude an exact outputMag match.
validLayers = find((imgWidths - imgWidths(baseLayer)/resFactor) + resFactor > 0);
[~,vTarget] = min(abs(imgWidths(validLayers) - imgWidths(baseLayer)/resFactor));
targetLayer = validLayers(vTarget);
amountToReduceByLater = imgHeights(targetLayer) / (imgHeights(baseLayer) / resFactor); % if targetLayer doesn't match outputMag
targetAnnoDown = resFactor/amountToReduceByLater; % how much to downsize annotation by when getting region, corresponds to magnification of targetLayer


% Need to account for possible rotation
switch rotation
    case 0
        
        annStartX = round(min(annotation.Y/targetAnnoDown));
        annEndX = round(max(annotation.Y/targetAnnoDown));
        annStartY = round(min(annotation.X/targetAnnoDown));
        annEndY = round(max(annotation.X/targetAnnoDown));
        
        
    case 270
        
        annStartX = round(imgInfo(targetLayer).Height - max(annotation.X/targetAnnoDown));
        annEndX = round(imgInfo(targetLayer).Height - min(annotation.X/targetAnnoDown));
        annStartY = round(min(annotation.Y/targetAnnoDown));
        annEndY = round(max(annotation.Y/targetAnnoDown));
        
        
end

imgHeight = annEndY - annStartY;
imgWidth = annEndX - annStartX;

if(ischar(region))
    xStart = round(imgWidth/2)  + annStartX;
    xEnd = xStart + regionEdgeLength(1);
    
    yStart = round(imgHeight/2) + annStartY;
    yEnd = yStart + regionEdgeLength(2);

%     yEnd = round(imgHeight/2);
%     yStart = yEnd + regionEdgeLength(2);

    
else
%     xStart = xStart + region(1);
%     xEnd = xStart + region(1) + region(2);
    
end

[annStartX annEndX annStartY annEndY]
[xStart,xEnd,yStart,yEnd]

rgb = imread(imgPath,'Index',targetLayer,'PixelRegion',{[xStart,xEnd],...
    [yStart,yEnd]});


rgb = imrotate(rgb,rotation);
rgb = imresize(rgb,1/amountToReduceByLater);

% mask = poly2mask(round(annotation.X/resFactor - min(annotation.X/resFactor)),round(annotation.Y/resFactor - min(annotation.Y/resFactor)),...
%     round(max(annotation.Y/resFactor)-min(annotation.Y/resFactor)),round(max(annotation.X/resFactor)-min(annotation.X/resFactor)));
mask = ones(size(rgb,1),size(rgb,2));

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