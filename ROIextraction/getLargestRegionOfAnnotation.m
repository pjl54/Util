% Returns the largest annotation of each color from an xml file
% Patrick Leo - April 2018
function [catAnnos, largestIDX] = getLargestRegionOfAnnotation(pathToAnnotation)

catAnnos = getRegionsOfAnnotation(pathToAnnotation);
largestIDX = zeros(1,length(catAnnos));

for(c = 1:length(catAnnos))
    maxSize = 0;
    maxIDX = 0;    
    if(~isempty(catAnnos{c}))
        for(a = 1:length(catAnnos{c}))
            thisSize = polyarea(catAnnos{c}(a).X,catAnnos{c}(a).Y);
            if(thisSize > maxSize)
                maxSize = thisSize;
                maxIDX = a;
            end
        end
%         catAnnos{c} = catAnnos{c}(maxIDX);
    end
    largestIDX(c) = maxIDX;
end