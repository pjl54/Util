% Note: Set you C/C++ compiler and load openslide Library before calling
% this function. MATLAB easily crashes.
% =================================================================
% Returns the ROI defined by the annotation.  This replaces a half dozen
% cobbled together functions

% Inputs:
% imgPath         - string, path to image file
% annotation      - struct, with fields X and Y containing the X and Y coordinates of the ordered set of verticies defining the ROI boundary
% inputMag        - integer, the original magnification of the image
% outputMag       - integer, the desired output magnification

% Output:
% ROI             - 3D uint8, RGB image of ROI, cropped from original as rectangular image
% mask            - 2D logical, mask to be applied to get ROI from rectangle
% Patrick Leo - 2017
    % October 2017: removed rotation from input list, added nargout
    % consideration
% ========================================================================
% New features added - This version intergates the OPENSLIDE package from
% CMU. Original MATLAB implementation done by Daniel Forsberg. GNU General
% Public License.

% Disclaimer: The use of OPENSLIDE is for Non-profit?research purpose only.
% Yuntao Sang, Revised March 2018
% ========================================================================
function [ROI mask] = getROIfromJPEG2000SVS(imgPath,annotation,inputMag,outputMag)
slidePtr = openslide_open(imgPath);

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

Xstart = round(min(annotation.X/targetAnnoDown));
Xend = round(max(annotation.X/targetAnnoDown));
Xlength = abs(Xstart - Xend);
        
Ystart = round(min(annotation.Y/targetAnnoDown));
Yend = round(max(annotation.Y/targetAnnoDown));
Ylength = abs(Ystart - Yend);
        
slideread = openslide_read_region(slidePtr,Xstart,Ystart,Xlength,Ylength);
rgb = slideread(:,:,2:4);

mask = poly2mask(round(annotation.X/resFactor - min(annotation.X/resFactor)),round(annotation.Y/resFactor - min(annotation.Y/resFactor)),...
    round(max(annotation.Y/resFactor)-min(annotation.Y/resFactor)),round(max(annotation.X/resFactor)-min(annotation.X/resFactor)));

% zero pad or reduce mask to match size of image
% rgb and mask can have different sizes due to rounding(annotation
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
end