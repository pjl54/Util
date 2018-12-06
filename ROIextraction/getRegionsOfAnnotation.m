% returns the annotationed regions of the inputted .xml
% Inputs:
% pathToAnnotation   - string, filepath to ImageScope .xml file of annotations

% Outputs:
% catAnnos           - struct, contins the X and Y coordinates of the
%   annotation in the order {benign, tumor, grade3, grade4}
% Patrick Leo - 2017
function catAnnos = getRegionsOfAnnotation(pathToAnnotation)

if(strcmp(pathToAnnotation(end-3:end),'.czi'))
    [anno,~] = getAnnotationFromCzi(pathToAnnotation,0);
    catAnnos = {[] anno [] [] []};
else
     
    annotations = parseXML(pathToAnnotation);
    status = zeros(1,length(annotations));
    
    %% finding benign and tumor annotations
    % 1: benign, 2: cancer, 3: grade 3 4: grade 4
    for(i = 1:length(annotations))
        
        % excluse negative ROI's
        if(annotations(i).negative == 0)
            % two kinds of yellow in annotations, [255 255 128] and [255 255 0]
            if(annotations(i).color(1) == 255 && annotations(i).color(2) == 255)
                status(i) = 1;
            elseif(annotations(i).color(1) == 0 && annotations(i).color(2) == 255 && annotations(i).color(3) == 0)
                status(i) = 2;
            elseif(annotations(i).color(1) == 0 && annotations(i).color(2) == 0 && annotations(i).color(3) == 255 || annotations(i).color(1) == 0 && annotations(i).color(2) == 255 && annotations(i).color(3) == 255)
                status(i) = 4;
            elseif((annotations(i).color(1) == 255 && annotations(i).color(2) == 0 && annotations(i).color(3) == 0))
                status(i) = 3;
            else
                status(i) = 5;
            end
        else
            status(i) = -1;
        end
    end
    
    benigns = find(status == 1);
    tumors = find(status == 2);
    grade3s = find(status == 3);
    grade4s = find(status == 4);
    others = find(status == 5);
    
    % benign, tumor, 3s, 4s
    catAnnos = {annotations(benigns) annotations(tumors) annotations(grade3s) annotations(grade4s) annotations(others)};
end