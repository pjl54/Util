% Modified from getProstateAnnotation
function annotation = parseXML(xmlFile)

xDoc = xmlread(xmlFile);

% Read in the Annotations and Regions
Annotations = xDoc.getElementsByTagName('Annotation');

% Empty structure to hold the annotations
annotation = []; counter = 1;

for ii=0:Annotations.getLength-1
    
    % Save the current annotation block
    this_Annotation = Annotations.item(ii);
    
    % Grab this Annotation Color (32-bit integer value)
    this_color = cell(this_Annotation.getAttribute('LineColor'));
    
    % Convert color to RGB triplet
    this_color_hex = dec2hex(str2double(this_color{1}));
    while length(this_color_hex) < 6
        this_color_hex = strcat('0', this_color_hex);
    end
    % The hex values are messed up; in the xml, it goes BBGGRR instead of
    % RRGGBB
    this_color = [...
        hex2dec(this_color_hex(5:6)),...
        hex2dec(this_color_hex(3:4)),...
        hex2dec(this_color_hex(1:2))];
    clear this_color_hex
    
    % Get the "Regions" child of this annotation (each contour is a region)
    Regions = this_Annotation.getFirstChild;
    while ~strcmpi(Regions.getNodeName,'Regions')
        Regions = Regions.getNextSibling;
    end
    
    % Cycle through each region in this annotation (Skip the first ID,
    % which is "RegionAttributeHeaders"
    for jj = 3:Regions.getLength-1
        
        % Save the current region
        this_region = Regions.item(jj);
        
        if(isempty(this_region.getFirstChild)), continue; end;
        
        % Get to the Vertices child of the region
        Vertices = this_region.getFirstChild;
       
        while ~strcmpi(Vertices.getNodeName,'Vertices')
            Vertices = Vertices.getNextSibling;
%             if(isempty(Vertices))
%                 fprintf('Empty Vertices, skipping...\n');
%                 break;
%             end
        end
        
        
        
        % Get vertices for current region
        X=[]; Y=[];
        Vertex = Vertices.getFirstChild; 
        while ~isempty(Vertex)
            if ~strcmpi(Vertex.getNodeName,'Vertex')
                Vertex = Vertex.getNextSibling;
                continue;
            end
            
            x = cell(Vertex.getAttribute('X')); x = str2double(x{1});
            y = cell(Vertex.getAttribute('Y')); y = str2double(y{1});
            X = [X; x];
            Y = [Y; y];
            
            Vertex = Vertex.getNextSibling;
        end
        
        % Throw the current vertices into this region's location in the
        % annotation structure
        annotation(counter).color = this_color;
        annotation(counter).X = X;
        annotation(counter).Y = Y;
        annotation(counter).negative = str2double(this_region.getAttribute('NegativeROA'));
        counter = counter+1;

    end
    
end