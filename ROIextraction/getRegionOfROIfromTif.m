% Region specified as [xStart width yStart height] or 'middle'
function [ROI, region] = getRegionOfROIfromTif(imgPath,annotation,outputMPP,region,windowSize)

minX = min(annotation.X);
maxX = max(annotation.X);

minY = min(annotation.Y);
maxY = max(annotation.Y);

if(ischar(region))    
    
    xStart = round((minX+maxX)/2 - windowSize(1)/2);
    width = windowSize(1);
    yStart = round((minY+maxY)/2 - windowSize(2)/2);
    height = windowSize(2);      
    
else
    
    xStart = region(1)+minX;
    width = windowSize(1);
    
    yStart = region(2)+minY;
    height = windowSize(2);
end

newAnno.X = [xStart,xStart,xStart + width,xStart+ width];
newAnno.Y = [yStart,yStart + height,yStart + height,yStart];

region = [xStart - minX, width, yStart - minY, height];

% if(nargout == 1)
    ROI = getROIfromTif(imgPath,newAnno,outputMPP);
% else
%     [ROI, mask] = getROIfromTif(imgPath,newAnno,outputMPP);
% end
