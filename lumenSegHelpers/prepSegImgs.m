function prepSegImgs(imgsDir,outputDir,refImgPath,catagoriesToSlice,oneRegionPerCat,imageExtension)

% imgsDir = '/mnt/projects/CSE_BME_AXM788/data/UPenn_Prostate_Histology/Progressor_nonProgressorProstate/histologyImages/UPenn';
% outputDir = '/mnt/pan/Data7/pjl54/lumenUnet/10X/preppedSegClear';
% refImgPath = '';
% catagoriesToSlice = 2;
% oneRegionPerCat = true;
% imageExtension = '.svs';

% When calling from a bash script, all inputs are treated as strings
varNames = {'catagoriesToSlice','oneRegionPerCat'};
for(k = 1:length(varNames))
    if(exist(varNames{k},'var') && ischar(eval(varNames{k})))
        eval([varNames{k} '= str2num(' varNames{k} ');']);
    end
end

if(~exist('imageExtension','var'))
    imageExtension = [];    
    formats = validImageFormats;
    k = 1;
    while(isempty([imgsDir filesep '*' formats{k}]))
        k = k + 1;
    end
    imageExtension = formats{k};
end      
    
imgs = dir([imgsDir filesep '*' imageExtension]);
        
codes = {'Yellow','Green','Red','Blue','Other'};
placeholder = 'placeholder';

for a = 1:length(imgs)
    
    pause(rand*5); % There's a race condition in writing files soooooo...
    
    img = [imgsDir filesep imgs(a).name];
    name = imgs(a).name(1:end-length(imageExtension));
    
    if(~strcmp(imageExtension,'.czi'))
        pathToAnnotation = [imgsDir filesep name '.xml'];
    else
        pathToAnnotation = img;
    end
    saveName = [outputDir filesep name '_preppedSeg.png'];
    workingName = [outputDir filesep name '_preppedSeg.mat'];
    try
        if(~exist(saveName,'file') && ~exist(workingName,'file') && exist(pathToAnnotation,'file'))
            parsave(workingName,placeholder,'placeholder')
            fprintf('Workin on %s \n',name)
            
            [catAnnos, largestIDX] = getLargestRegionOfAnnotation(pathToAnnotation);
            
            for(catagory = catagoriesToSlice)
                if(~isempty(catAnnos{catagory}))
                    if(oneRegionPerCat)
                        regionsToSlice = largestIDX(catagory);
                    else
                        regionsToSlice = 1:length(catAnnos{catagory});
                    end
                    for(regionNum = regionsToSlice)
                        
                        if(oneRegionPerCat)
                            savePrefix = [name];
                        else
                            savePrefix = [name '_' codes{catagory} '_' num2str(regionNum)];
                        end
                        
                        [rgb] = getROIfromTif(img,catAnnos{catagory}(regionNum),1);
                                                
                        imwrite(rgb,[outputDir filesep savePrefix '_preppedSeg.png']);
                    end
                end
            end
        end
    catch ME
        if(strcmp(ME.identifier,'metadata:exceedsNumROIs'))
            fprintf('No annotation on %s \n',name);
        else
            rethrow(ME)
        end
    end
    
    try
        delete(workingName);
    catch
    end
    
end


