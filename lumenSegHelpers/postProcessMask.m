function cleanMask = postProcessMask(dirtyMask,img)


lum = bwareaopen(imclearborder(dirtyMask),4);
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

cleanMask = lum & ~badLums;
