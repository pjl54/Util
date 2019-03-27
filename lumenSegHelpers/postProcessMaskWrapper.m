function postProcessMaskWrapper(baseDir)

dirtyMaskDir = [baseDir filesep 'dirtyMasks'];
cleanMaskDir = [baseDir filesep 'cleanMasks'];
imgsDir = [baseDir filesep 'preppedSeg'];

dirtyMasks = dir([dirtyMaskDir filesep '*.png']);
dirtyMasks = dirtyMasks([dirtyMasks.bytes] > 70);

for(m = 1:length(dirtyMasks))
    cleanMaskName = [cleanMaskDir filesep dirtyMasks(m).name(1:end-length('.png')) '_clean.png'];
    imgName = [imgsDir filesep dirtyMasks(m).name(1:end-length('_class.png')) '.png'];
    if(~exist(cleanMaskName,'file') && exist(imgName,'file'))
        imwrite(zeros(10),cleanMaskName)
        dirtyMask = imread([dirtyMasks(m).folder filesep dirtyMasks(m).name]);
        img = imread(imgName);
                
        cleanMask = postProcessMask(dirtyMask,img);
        imwrite(cleanMask,cleanMaskName);
    end
end