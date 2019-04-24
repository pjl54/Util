% to piece back together images cut up with sliceImage.m
% Patrick Leo - 2017

% Added inputs to make this a real function and replaced underscore finding
% nonsense with regexp
function stitchImageTogether(confidenceDir,unseggedPatchDir,seggedPatchDir,finishedFlagDir,buffer,modelInputSize)

fprintf('Starting stitchImageTogether \n');

% When calling from a bash script, all inputs are treated as strings
varNames = {'outputMPP','buffer','modelInputSize','catagoriesToSlice','oneRegionPerCat','conThresh','smallSizeThresh','bigSizeThresh','featsToExtract'};
for(k = 1:length(varNames))
    if(exist(varNames{k},'var') && ischar(eval(varNames{k})))                
        eval([varNames{k} '= str2num(' varNames{k} ');']);
    end
end

if(~exist(confidenceDir,'file'))
    mkdir(confidenceDir);
end

% buffer = 65;
% patchSize = round(2000/3 - (2 * buffer));
patchSize = modelInputSize - 2*buffer;

patches = dir([seggedPatchDir filesep '*.png']);

% check that there are no missing prob maps
markers = dir([seggedPatchDir filesep '*_@_prob.png']);
for(k = 1:length(markers))
    if(~exist([seggedPatchDir filesep markers(k).name(1:end - length('_@_prob.png')) '_class1_prob.png'],'file'))
        fprintf('Missing seg of %s \n',markers(k).name);
    end
end


% find out how many complete images are in the directory
imageCount = 0;
stopIdxs = [];
imageSizes = zeros(2,1000); % This has room for the two dimensions of 1000 images
imageNames = {};

pName = patches(1).name;
imageNameIDX = regexp(pName,'_\d*X\d*Y') - 1;
imageName = patches(1).name(1:imageNameIDX);
imageNames{end+1} = imageName;

for(i = 2:length(patches))
    pName = patches(i).name;
    
    imageNameIDX = regexp(pName,'_\d*X\d*Y') - 1;
    imageName = patches(i).name(1:imageNameIDX);
    
    prevImageNameIDX = regexp(patches(i-1).name,'_\d*X\d*Y') - 1;
    prevImageName = patches(i-1).name(1:prevImageNameIDX);
    
    if(~strcmp(imageName,prevImageName))
        imageCount = imageCount + 1;
        imageNames{end+1} = imageName;
    end
    
    Xval = str2num(pName((regexp(pName,'\d+X')):(regexp(pName,'\d+X','end')-1)));
    Yval = str2num(pName((regexp(pName,'\d+Y')):(regexp(pName,'\d+Y','end')-1)));
    
    if(imageSizes(1,imageCount+1) < Xval)
        imageSizes(1,imageCount+1) = Xval;
    end
    if(imageSizes(2,imageCount+1) < Yval)
        imageSizes(2,imageCount+1) = Yval;
    end
    
end
imageCount = imageCount + 1;
imageNames{end+1} = imageName;

placeholder = ones(10);
suffix = '__class1_prob.png';
for(k = 1:imageCount)
    saveName = [confidenceDir filesep imageNames{k} '_mask_stitched.png'];
    
    % check that all sliced patches have been segmented
    seggedPatches = dir([seggedPatchDir filesep imageNames{k} '_*']);
    if(numel(seggedPatches) == numel(dir([unseggedPatchDir filesep imageNames{k} '_*'])))
        
        % placeholder files are 69 bytes
        if(~any([seggedPatches.bytes]<70))
            
            if(~exist(saveName,'file') && exist([finishedFlagDir filesep imageNames{k} '_finished.mat'],'file'))
                imwrite(placeholder,saveName);
                fprintf('Working diligently to stitch %s \n',imageNames{k});
                x = 1;
                while(~exist([seggedPatchDir filesep imageNames{k} '_' num2str(x) 'X1Y' suffix],'file') && x < 100)
                    x = x + 1;
                end
                
                if(x < 100)
                    a = imread([seggedPatchDir filesep imageNames{k} '_' num2str(x) 'X1Y' suffix]);
                    stitchedImage = uint8(zeros(imageSizes(2,k)*patchSize,imageSizes(1,k)*patchSize,size(a,3)));
                    for(y = 1:imageSizes(1,k))
                        for(x = 1:imageSizes(2,k))
                            if(exist([seggedPatchDir filesep imageNames{k} '_' num2str(y) 'X' num2str(x) 'Y' suffix],'file'))
                                patchImg = imread([seggedPatchDir filesep imageNames{k} '_' num2str(y) 'X' num2str(x) 'Y' suffix]);
                            else
                                patchImg = zeros(patchSize+(2*buffer),patchSize+(2*buffer),size(a,3));
                            end
                            stitchedImage(x*patchSize - patchSize + 1:x*patchSize,y*patchSize - patchSize + 1:y*patchSize,:) = patchImg(buffer+1:end-buffer,buffer+1:end-buffer,:);
                        end
                    end
                    imwrite(stitchedImage,saveName);
                else
                    fprintf('Not all patches segmented for %s \n',imageNames{k})
                end
            else
%                 fprintf('Whew we already did %s \n',imageNames{k});
            end
        end
    end
    
end