% Parses Cz files that are the result of exporting annotations from .czi
% files
function annotation = parseCz(czFile)

xDoc = xmlread(czFile);

% Read in the Annotations and Regions
Annotations = xDoc.getElementsByTagName('Elements');

% Empty structure to hold the annotations
numAnns = Annotations.getLength;
% annotation(numAnns).color = [];
% annotation(numAnns).X = [];
% annotation(numAnns).Y = [];
% annotation(numAnns).negative = [];
% annotation(numAnns).text = [];

counter = 1;

for ii=0:Annotations.getLength-1
    % Save the current annotation block
    this_Annotation = Annotations.item(ii);
    %
    %     % Grab this Annotation Color (32-bit integer value)
    %     this_color = cell(this_Annotation.getAttribute('LineColor'));
    %
    %     % Convert color to RGB triplet
    %     this_color_hex = dec2hex(str2double(this_color{1}));
    %     while length(this_color_hex) < 6
    %         this_color_hex = strcat('0', this_color_hex);
    %     end
    %     % The hex values are messed up; in the xml, it goes BBGGRR instead of
    %     % RRGGBB
    %     this_color = [...
    %         hex2dec(this_color_hex(5:6)),...
    %         hex2dec(this_color_hex(3:4)),...
    %         hex2dec(this_color_hex(1:2))];
    %     clear this_color_hex
    
    % Get the "Regions" child of this annotation (each contour is a region)
    Regions = this_Annotation.getElementsByTagName('Polygon');
    
    for jj = 0:Regions.getLength-1
        
        % Save the current region
        this_region = Regions.item(jj);
        Region = this_region.getElementsByTagName('Geometry');
        
        Vertices = Region.item(0).getElementsByTagName('Points');
        pointsText = string(Vertices.item(0).getTextContent);
        Vertexes = strsplit(pointsText,' ');
        
        X = nan(length(Vertexes),1);
        Y = nan(length(Vertexes),1);
        
        
        for(v = 1:length(Vertexes))
            splitted = strsplit(Vertexes{v},',');
                        
            X(v) = round(str2double(splitted{1}));
            Y(v) = round(str2double(splitted{2}));
        end
        
%         % Throw the current vertices into this region's location in the
%         % annotation structure
%         annotation(counter).color = this_color;
        annotation(counter).X = X;
        annotation(counter).Y = Y;
%         annotation(counter).negative = str2double(this_region.getAttribute('NegativeROA'));
%         annotation(counter).text = this_region.getAttribute('Text');
        counter = counter+1;
        
    end
end