function sliceImage(rgb,buffer,modelInputSize,saveDir,savePrefix,colorNormTemplate)

if(exist('colorNormTemplate','var'))
    if(isstring(colorNormTemplate))
        colorNormTemplate = imread(colorNormTemplate);
    end
    
    if(numel(colorNormTemplate) == 3)
        masterHist = colorNormTemplate;
        clear('colorNormTemplate')
    else
        refMask = rgb2gray(colorNormTemplate)<190;
        %%
        refChannel = cell(1,3);
        for(channel = 1:3)
            refChannel{channel} = refImg(:,:,channel);
            masterHist(channel,:) = histcounts(refChannel{channel}(find(refMask)),256);
        end
    end
    
    needColorNorm = true;
else
    needColorNorm = false;
end

patchSize = modelInputSize - (2 * buffer); % side length of square patch

if(needColorNorm)
    mask = rgb2gray(rgb)<190;
    rgbChannel = cell(1,3);
    for(channel = 1:3)
        rgbChannel{channel} = rgb(:,:,channel);
        rgbChannel{channel}(find(mask)) = histeq(rgbChannel{channel}(find(mask)),masterHist(channel,:));
    end
    rgb = cat(3,rgbChannel{1},rgbChannel{2},rgbChannel{3});
    rgbChannel = [];
end
origSize = size(rgb);
rgb = padarray(rgb,[patchSize-mod(size(rgb,1),patchSize),patchSize-mod(size(rgb,2),patchSize)],'post'); % made image divisble by patchSize

rgb(:,origSize(2):end,:) = 255;
rgb(origSize(1):end,:,:) = 255;

kPoints = ((1:floor(size(rgb,1)/patchSize)) * patchSize) + buffer;
zPoints = ((1:floor(size(rgb,2)/patchSize)) * patchSize) + buffer;

rgb = padarray(rgb,[buffer buffer],'both');
rgb(1:buffer,:,:) = 255;
rgb(:,1:buffer,:) = 255;
rgb(end-buffer:end,:,:) = 255;
rgb(:,end-buffer:end,:) = 255;
for(k = kPoints)
    for(z = zPoints)
        patch = rgb(k-patchSize+1-buffer:k+buffer,z-patchSize+1-buffer:z+buffer,:);
        if((max(patch(:)) > 0) && min(patch(:)) < 255)
            imwrite(patch,[saveDir filesep savePrefix '_' num2str((z-buffer)/patchSize) 'X' num2str((k-buffer)/patchSize) 'Y.tif']);
        end
    end
end