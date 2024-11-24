function objects = parseMarkerFiles(directory)
    % processMarkerFiles processes VSK and TAK files in the specified directory
    % and returns an array of objects containing marker data.
    % 
    % Inputs:
    %   directory - Directory containing VSK and TAK files.
    %
    % Outputs:
    %   objects - Array of objects with names and marker positions.

    % Define a custom object structure to hold markers for each object
    Object = struct('name', '', 'markers', []); % Custom object structure

    % Initialize array to hold objects
    objects = [];

    % List all VSK and TAK files in the directory
    vskFiles = dir(fullfile(directory, '*.vsk'));
    takFiles = dir(fullfile(directory, '*.tak'));

    %% Process VSK files
    if ~isempty(vskFiles)
        disp('Processing VSK files...');
        for i = 1:length(vskFiles)
            vskFilePath = fullfile(directory, vskFiles(i).name);
            
            try
                % Parse the XML content of the VSK file
                vskData = xmlread(vskFilePath);
                
                % Extract Parameters (key-value pairs of positions)
                params = vskData.getElementsByTagName('Parameter');
                paramMap = containers.Map; % To map parameter names to values
                for j = 0:params.getLength-1
                    paramNode = params.item(j);
                    paramName = char(paramNode.getAttribute('NAME'));
                    paramValue = str2double(paramNode.getAttribute('VALUE'));
                    paramMap(paramName) = paramValue;
                end
                
                % Extract Objects (e.g., segments or groups that contain markers)
                segments = vskData.getElementsByTagName('Segment');
                for s = 0:segments.getLength-1
                    segmentNode = segments.item(s);
                    segmentName = char(segmentNode.getAttribute('NAME'));
                    
                    % Initialize the object for this segment
                    currentObject = Object;
                    currentObject.name = segmentName;
                    currentObject.markers = [];

                    % Extract Markers and their positions
                    targets = vskData.getElementsByTagName('TargetLocalPointToWorldPoint');
                    for t = 0:targets.getLength-1
                        targetNode = targets.item(t);
                        targetMarker = char(targetNode.getAttribute('MARKER'));

                        % If the marker belongs to the current segment, extract its position
                        if contains(targetMarker, segmentName)
                            position = char(targetNode.getAttribute('POSITION'));
                            
                            % Resolve parameter references in POSITION
                            position = strrep(position, "'", ""); % Remove single quotes
                            posParts = split(position);
                            x = paramMap(posParts{1});
                            y = paramMap(posParts{2});
                            z = paramMap(posParts{3});
                            
                            % Append marker position to this object's marker list
                            currentObject.markers = [currentObject.markers; x, y, z];
                        end
                    end
                    
                    % Append the current object to the array of objects
                    objects = [objects; currentObject];
                end
            catch ME
                disp(['Error processing VSK file: ', vskFiles(i).name]);
                disp(ME.message);
            end
        end
    end

    %% Process TAK files
    if ~isempty(takFiles)
        disp('Processing TAK files...');
        for i = 1:length(takFiles)
            takFilePath = fullfile(directory, takFiles(i).name);
            
            try
                % Read the TAK file
                fid = fopen(takFilePath, 'r');
                takData = fread(fid, '*char')';
                fclose(fid);
                
                % Split the file into individual rigid body definitions
                rigidBodies = strsplit(takData, 'RigidBody');
                
                % Loop through each rigid body definition
                for rb = 2:length(rigidBodies)
                    rigidBodyData = strtrim(rigidBodies{rb});
                    
                    % Extract the rigid body name (assume the first line contains it)
                    nameLine = strsplit(rigidBodyData, '\n');
                    rigidBodyName = strtrim(nameLine{1});
                    
                    % Initialize the object for this rigid body
                    currentObject = Object;
                    currentObject.name = rigidBodyName;
                    currentObject.markers = [];

                    % Extract marker positions from the file (assuming "Markers:" section exists)
                    markerSection = strsplit(rigidBodyData, 'Markers:');
                    if length(markerSection) > 1
                        markersData = strtrim(markerSection{2});
                        markers = strsplit(markersData, '\n');
                        
                        for m = 1:length(markers)
                            markerLine = strtrim(markers{m});
                            if ~isempty(markerLine)
                                % Assuming marker positions are in the format "Marker_X: x, y, z"
                                markerParts = strsplit(markerLine, ':');
                                markerPos = str2double(strsplit(markerParts{2}, ','));
                                
                                % Append marker position to this object's marker list
                                currentObject.markers = [currentObject.markers; markerPos];
                            end
                        end
                    end
                    
                    % Append the current object to the array of objects
                    objects = [objects; currentObject];
                end
            catch ME
                disp(['Error processing TAK file: ', takFiles(i).name]);
                disp(ME.message);
            end
        end
    end

    %% Display Results
    disp(['Found ', num2str(length(objects)), ' Objects']);
    for i = 1:length(objects)
        disp(['Object: ', objects(i).name, ', Number of markers: ', num2str(size(objects(i).markers, 1))]);
    end
end

