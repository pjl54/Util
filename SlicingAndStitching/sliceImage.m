% Cuts image into square patches for deep learning processing
% Patrick Leo - 2017
% Modified October 2018: moved all inputs to be actual inputs
function sliceImage(imgsDir,refImgPath,unseggedPatchDir,problemDir,finishedFlagDir,outputMPP,buffer,modelInputSize,catagoriesToSlice,oneRegionPerCat,imageExtension)

% baseDir = '/mnt/pan/Data7/pjl54/prostateNuc/caffe/PennRacial';
% baseDir = '/mnt/pan/Data7/pjl54/prostateNuc/caffe/TCGA';
% imgsDir = '/mnt/projects/CSE_BME_AXM788/data/TCGA_PRAD/2018Jan14'
% imgsDir='/mnt/projects/CSE_BME_AXM788/data/UPenn_Prostate_Histology/RacialDisparity/imagesAndAnnotations'
% outputMPP=0.25
% buffer=65
% modelInputSize=2000
% catagoriesToSlice='2'
% oneRegionPerCat=1
% imageExtension=''
% refImgPath='/mnt/pan/Data7/pjl54/nuclei_refImg.png'
% conThresh=63.75
% smallSizeThresh=60
% bigSizeThresh=3000
% featsToExtract='[2:3]'
%
% unseggedPatchDir = [baseDir filesep 'nuclearUnseggedPatches'];
% seggedPatchDir = [baseDir filesep 'nuclearSeggedPatches'];
% confidenceDir = [baseDir filesep 'nuclearConfidenceMaps'];
% boundsDir = [baseDir filesep 'nuclearBounds'];
% problemDir = [baseDir filesep 'nuclearProblems'];
% finishedFlagDir = [baseDir filesep 'nuclearFinishedFlag'];
% featsDir = [baseDir filesep 'nuclearFeats'];
%
%
% When calling from a bash script, all inputs are treated as strings

pause(rand*5); % There's a race condition in writing files soooooo...

varNames = {'outputMPP','buffer','modelInputSize','catagoriesToSlice','oneRegionPerCat','conThresh','smallSizeThresh','bigSizeThresh','featsToExtract'};
for(k = 1:length(varNames))
    if(exist(varNames{k},'var') && ischar(eval(varNames{k})))
        eval([varNames{k} '= str2num(' varNames{k} ');']);
    end
end

if(~exist('imageExtension','var') || isempty(imageExtension))
    imageExtension = [];
    formats = validImageFormats;
    k = 1;
    while(isempty(dir([imgsDir filesep '*' formats{k}])))
        k = k + 1;
    end
    imageExtension = formats{k};
end

if(~exist('oneRegionPerCat','var'))
    oneRegionPerCat = true;
end

if(~isempty(refImgPath))
    refImg = imread(refImgPath);
    refMask = rgb2gray(refImg)<190;
    %%
    refChannel = cell(1,3);
    for(channel = 1:3)
        refChannel{channel} = refImg(:,:,channel);
        masterHist(channel,:) = histcounts(refChannel{channel}(find(refMask)),256);
    end
else
    masterHist = [];
end


xmlsDir = imgsDir;

imgs = dir([imgsDir filesep '*' imageExtension]);

patchSize = modelInputSize - (2 * buffer); % side length of square patch
placeholder = 'placeholder';

codes = {'Yellow','Green','Red','Blue','Other'};

needColorNorm = exist('refImg','var');
for(a = 1:length(imgs))
    iMadeWorkName = false;
    try
        img = [imgsDir filesep imgs(a).name];
        name = imgs(a).name(1:end-4);
        
        fprintf('Checking %s \n',name);
        
        if(~strcmp(imageExtension,'.czi'))
            pathToAnnotation = [xmlsDir filesep name '.xml'];
        else
            pathToAnnotation = img;
        end
        
        % If there's only one region per patient, can just check for that
        % patient without loading the annotations
        if(oneRegionPerCat)
            savePrefix = name;
            workName = [unseggedPatchDir filesep savePrefix '_workingOn.mat'];
            problemName = [problemDir filesep savePrefix '_otherProblem'];
            noAnnotationName = [problemDir filesep savePrefix '_otherProblem'];
            finishedName = [finishedFlagDir filesep savePrefix '_finished.mat'];
            if(exist(workName,'file') || exist(finishedName,'file') || exist(problemName,'file') || exist(noAnnotationName,'file'))
                oneCatDone = true;
            else
                oneCatDone = false;
            end
        else
            oneCatDone = false;
        end
        
        
        noAnnotationName = [problemDir filesep name '_noAnnotation.mat'];
        
        % .czi files cant be larger than 4GB
        %     if(~(strcmp(imageExtension,'.czi') && (imgs(a).bytes > (4 * 2^30))))
        
        if((exist(pathToAnnotation,'file') && ~exist(noAnnotationName,'file')))
            if(~oneCatDone )
                
                fprintf('Found annotation %s \n',pathToAnnotation)
                
                %                 catAnnos = getRegionsOfAnnotation(anno);
                try
                    [catAnnos, largestIDX] = getLargestRegionOfAnnotation(pathToAnnotation);
                    
                    fprintf('Have largest region on %s \n',name);
                    
                    for(category = catagoriesToSlice)
                        if(~isempty(catAnnos{category}))
                            if(oneRegionPerCat)
                                regionsToSlice = largestIDX(category);
                            else
                                regionsToSlice = 1:length(catAnnos{category});
                            end
                            for(regionNum = regionsToSlice)
                                
                                if(oneRegionPerCat)
                                    savePrefix = [name];
                                else
                                    savePrefix = [name '_' codes{category} '_' num2str(w)];
                                end
                                workName = [unseggedPatchDir filesep savePrefix '_workingOn.mat'];
                                problemName = [problemDir filesep savePrefix '_otherProblem.mat'];
                                finishedName = [finishedFlagDir filesep savePrefix '_finished.mat'];
                                
                                if(~exist(workName,'file') && ~exist(finishedName,'file') && ~exist(problemName,'file'))
                                    parsave(workName,placeholder,'placeholder');
                                    iMadeWorkName = true;
                                    fileattrib(workName,'-w','a'); % if another sliceImage process comes along and tries to start working on
                                    fprintf('Slicing and dicing %s \n',name);
                                    
                                    rgb = getROIfromTif(img,catAnnos{category}(regionNum),outputMPP);
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
                                                imwrite(patch,[unseggedPatchDir filesep savePrefix '_' num2str((z-buffer)/patchSize) 'X' num2str((k-buffer)/patchSize) 'Y.tif']);
                                            end
                                        end
                                    end
                                    
                                    parsave(finishedName,placeholder,'placeholder');
                                else
                                    %                             fprintf('Already did %s \n',name)
                                end
                                
                            end
                        end
                    end
                    
                catch ME
                    if(strcmp(ME.identifier,'metadata:exceedsNumROIs'))
                        fprintf('Skipping %s \n',name);
                        parsave(noAnnotationName,placeholder,'placeholder')
                    else
                        rethrow(ME)
                    end
                end
            end
        else
            %         fprintf('Skipping %s \n',name);
            parsave(noAnnotationName,placeholder,'placeholder')
        end
        
        
    catch u
        fprintf('Problem in %s, line %d: %s \n',name,u.stack(end).line,u.message);
        probSave = sprintf('Problem in %s, line %d: %s \n',name,u.stack(end).line,u.message);
        parsave(problemName,probSave,'probSave')
        
    end
    
    % can't check if variable exists while in a parfor loop so...
    try
        if(exist(workName,'file') && iMadeWorkName)
            delete(workName)
        end
    catch
    end
    
    %     else
    %         probSave = 'Too big';
    %         parsave([problemName '_tooBig.mat'],probSave,'probSave')
    %     end
    
end