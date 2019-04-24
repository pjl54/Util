% Cuts image into square patches for deep learning processing
% Patrick Leo - 2017
% April 2018, Patrick Leo:
%   - Modified code to slice only the largest region of the selected
%   catagories
function sliceImageLargestRegion

%% Parameters that may need to be changed
if(ispc)
    saveDir = 'D:\testing';
    imgsDir = 'D:\ccipd_data\TCGA_PRAD\imagesConvertedToJPEG';
    xmlsDir = 'D:\ccipd_data\TCGA_PRAD\imagesConvertedToJPEG';
else
    saveDir = '/mnt/pan/Data7/pjl54/testing/patches';
    imgsDir = '/mnt/projects/CSE_BME_AXM788/data/UPenn_Prostate_Histology/Progressor_nonProgressorProstate/histologyImages/UPenn';
    xmlsDir = '/mnt/projects/CSE_BME_AXM788/data/UPenn_Prostate_Histology/Progressor_nonProgressorProstate/histologyImages/UPenn';
end

inputMag = 20;
outputMag = 20;

imgs = dir([imgsDir filesep '*.s*']);

buffer = 65; % how many extra pixels around the region need to be included
modelInputSize = 1000; % what slice size the model is designed to take

catagoriesToSlice = 2; % which colors of annotation to slice
%%

% patchSize = round(modelInputSize/3) - (2 * buffer); % side length of square patch
patchSize = modelInputSize - (2 * buffer); % side length of square patch

for(a = 1:length(imgs))
    img = [imgsDir filesep imgs(a).name];
    name = imgs(a).name(1:end-4);
    pathToAnnotation = [xmlsDir filesep name '.xml'];
    if(exist(pathToAnnotation,'file') && isempty(dir([saveDir filesep name '*'])))
        fprintf('Slicing and dicing %s \n',name);
        
        catAnnos = getLargestRegionOfAnnotation(pathToAnnotation);
        
        for(cat = catagoriesToSlice)
            for(regionNum = 1:length(catAnnos{cat}))
                rgb = getROIfromTif(img,catAnnos{cat},inputMag,outputMag);
                
                rgb = padarray(rgb,[patchSize-mod(size(rgb,1),patchSize),patchSize-mod(size(rgb,2),patchSize)],'post'); % made image divisble by patchSize
                kPoints = ((1:floor(size(rgb,1)/patchSize)) * patchSize) + buffer;
                zPoints = ((1:floor(size(rgb,2)/patchSize)) * patchSize) + buffer;
                
                rgb = padarray(rgb,[buffer buffer],'both');
                
                for(k = kPoints)
                    for(z = zPoints)
                        patch = rgb(k-patchSize+1-buffer:k+buffer,z-patchSize+1-buffer:z+buffer,:);
                        if(max(patch(:)) > 0)
                            imwrite(patch,[saveDir filesep name '_catagory_' num2str(cat) '_regionNumber_' num2str(regionNum) '_' num2str((z-buffer)/patchSize) 'X' num2str((k-buffer)/patchSize) 'Y.png']);
                        end
                    end
                end
            end
        end
    else
        fprintf('Skipping %s \n',name);
    end
end