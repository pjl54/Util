
imgs = dir('F:\Gupta_Zeiss\p-AKT_Staining\3x1_split\*.czi');

for(k = 1:length(imgs))
    f = fopen([imgs(k).folder filesep imgs(k).name(1:end-3) 'xml'],'wt');
    try
        annotation = getAnnotationFromCzi([imgs(k).folder filesep imgs(k).name],0);
        fprintf(f,'<?xml version="1.0" encoding="UTF-8" standalone="no"?> \n');
        fprintf(f,'<Annotations MicronsPerPixel="0.25"> \n');
        fprintf(f,'<Annotation Id="1" LineColor="65536"> \n');
        fprintf(f,'<Regions> \n');
        fprintf(f,'<RegionAttributeHeaders/> \n');
        fprintf(f,'<Region Id="1" NegativeROA="0"> \n');
        fprintf(f,'<Vertices> \n');
        
        for(k = 1:length(annotation.X))
            fprintf(f,'<Vertex X="%f" Y="%f"/> \n',annotation.X(k),annotation.Y(k));
        end
        
        fprintf(f,'</Vertices> \n');
        fprintf(f,'</Region> \n');
        fprintf(f,'</Regions> \n');
        fprintf(f,'</Annotation> \n');
        fprintf(f,'</Annotations> \n');
        fclose(f);
    catch
        fclose(f);
        delete([imgs(k).folder filesep imgs(k).name(1:end-3) 'xml'])
    end
end