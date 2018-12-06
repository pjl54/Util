function [annotation,reader] = getAnnotationFromCzi(imgPath,annotationIndex)

reader = bfGetReader(imgPath);
omeMeta = reader.getMetadataStore();

if(annotationIndex <= omeMeta.getROICount() - 1)
    points = omeMeta.getPolygonPoints(0,annotationIndex);
    
    pointsText = string(points);
    Vertexes = strsplit(pointsText,' ');
    
    X = nan(length(Vertexes),1);
    Y = nan(length(Vertexes),1);
    
    
    for(v = 1:length(Vertexes))
        splitted = strsplit(Vertexes{v},',');
        
        X(v) = round(str2double(splitted{1}));
        Y(v) = round(str2double(splitted{2}));
    end
    
    annotation.X = X;
    annotation.Y = Y;
    
else
    error('metadata:exceedsNumROIs','Zero-indexed annotation index (%d) exceeds number of annotations in image (%d)',...
        annotationIndex,omeMeta.getROICount())        
end


