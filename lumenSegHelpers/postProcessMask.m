function postProcessMask(baseDir)

dirtyMaskDir = [baseDir filesep 'dirtyMasks'];
cleanMaskDir = [baseDir filesep 'cleanMasks'];
imgsDir = [baseDir filesep 'preppedSeg'];

dirtyMasks = dir([dirtyMaskDir filesep '*.png']);

for(m = 1:length(dirtyMasks))
    cleanMaskName = [cleanMaskDir filesep dirtyMasks(m).name(1:end-length('.png')) '_clean.png'];
    if(~exist(cleanMaskName,'file'))
        imwrite(zeros(10),cleanMaskName)
        dirtyMask = imread([dirtyMasks(m).folder filesep dirtyMasks(m).name]);
        img = imread([imgsDir filesep dirtyMasks(m).name(1:end-length('_class.png')) '.png']);
                
        lum = bwareaopen(imclearborder(dirtyMask),4);        
%         white = imfill(rgb2gray(img)>230,'holes');
        white = rgb2gray(img)>230;
        whiteNonLum = white & ~lum;
        c = regionprops(lum,'BoundingBox','PixelIdxList','Perimeter','Image');
        badLums = false(size(lum));
        for(k = 1:length(c))
            bb = c(k).BoundingBox;
            bb = round(bb);
            ob = bb;
            
            % increase bounding box by 2
            bb(1) = max(1,bb(1) - 2);
            bb(2) = max(1,bb(2) - 2);
            bb(3) = min(size(img,2)- bb(1),bb(3) + 4);
            bb(4) = min(size(img,1)-bb(2),bb(4) + 4);
            lumimg = lum(bb(2):(bb(2)+bb(4)),bb(1):(bb(1)+bb(3)));
            lumo = c(k).Image;
            lumo = padarray(lumo,[ob(2)-bb(2),ob(1)-bb(1)],'pre');
            lumo = padarray(lumo,size(lumimg)-size(lumo),'post');
            lumimg = lumimg & lumo;

            whiteImg = whiteNonLum(bb(2):(bb(2)+bb(4)),bb(1):(bb(1)+bb(3)));            
            lumimg = imdilate(lumimg,strel('disk',1));
            if((sum(sum(lumimg & whiteImg))/(c(k).Perimeter)) > .05)
                badLums(c(k).PixelIdxList) = true;
            end
        end
        
        imwrite(lum & ~badLums,cleanMaskName);
    end
end