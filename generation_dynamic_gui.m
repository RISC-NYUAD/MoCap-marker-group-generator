function generation_dynamic_gui
    % Main GUI window
    fig = uifigure('Name', 'Groups Generator', 'Position', [100, 100, 600, 500]);
    fig.UserData.objects = []; % Initialize UserData.objects

    % Panel for dynamic inputs
    inputPanel = uipanel(fig, 'Position', [20, 90, 560, 300], 'Title', 'Inputs');

    % File path section
    uilabel(fig, 'Text', 'Objects Directory:', 'Position', [20, 430, 100, 20]);
    pathField = uieditfield(fig, 'text', 'Position', [120, 430, 300, 20], 'Tag', 'path');
    uibutton(fig, 'Text', 'Load Objects', ...
        'Position', [440, 430, 100, 30], ...
        'ButtonPushedFcn', @(~, ~) loadAndStoreObjects(pathField, fig));

    % Dropdown for function selection
    uilabel(fig, 'Text', 'Select Function:', 'Position', [20, 400, 100, 20]);
    dropdown_function = uidropdown(fig, ...
        'Items', {'Tube', 'SemiSphere', 'STL', 'Rectangular'}, ...
        'Position', [130, 400, 150, 20], ...
        'ValueChangedFcn', @(src, ~) updateGUI(inputPanel, src.Value));

    % Generate button
    uibutton(fig, 'Text', 'Generate', ...
        'Position', [460, 50, 100, 30], ...
        'ButtonPushedFcn', @(~, ~) callSelectedFunction(dropdown_function.Value, inputPanel));

     % Add logos at the bottom left
    uiimage(fig, ...
        'Position', [20, 10, 120, 50], ... % Adjust size and position as needed
        'ImageSource', 'logos\uni_logo.png'); % Replace with the path to your first logo image

    uiimage(fig, ...
        'Position', [150, 10, 100, 50], ... % Adjust size and position as needed
        'ImageSource', 'logos\center_logo.png'); % Replace with the path to your first logo image

    % Initial input setup
    setupInputs(inputPanel); % Create reusable input fields
    updateGUI(inputPanel, dropdown_function.Value); % Adjust visibility for the initial selection
end

function setupInputs(parent)
    % Define shared input fields
    fields = {'Radius', 'Height', 'Width', 'Length', 'PointsPerGroup', 'GroupsToGenerate', 'MinDistance', 'STLFilePath'};
    labels = {'Radius (mm):', 'Height (mm):', 'Width (mm):', 'Length (mm):', 'Points/Group:', 'Groups to Generate:', ...
              'Min Distance (mm):', 'STL File Path:'};
    % Define positions for all fields
    positions = [20, 250; 20, 210; 20, 170; 20, 130; 20, 90; 20, 50; 20, 10; 20, 250];
    
    for i = 1:numel(fields)
        % Label
        uilabel('Parent', parent, 'Text', labels{i}, ...
            'Position', [positions(i, 1), positions(i, 2), 150, 20], ...
            'Tag', [fields{i}, 'Label'], ...
            'Visible', 'off');

        % Input Field
        uieditfield(parent, 'text', ... % Specify 'text' type directly
            'Position', [positions(i, 1) + 160, positions(i, 2), 150, 20], ...
            'Tag', fields{i}, ...
            'Visible', 'off');
    end
        % Add a checkbox for positive visibility (only for STL)
        uicheckbox('Parent', parent, ...
            'Text', 'Positive Visibility', ...
            'Position', [20, 180, 200, 20], ...
            'Tag', 'PositiveVisibility', ...
            'Visible', 'off');
end


function updateGUI(inputPanel, selectedFunction)
    % Map function to relevant inputs
    visibleFields = struct( ...
        'Tube', {{'Radius', 'Height', 'PointsPerGroup', 'GroupsToGenerate', 'MinDistance'}}, ...
        'SemiSphere', {{'Radius', 'PointsPerGroup', 'GroupsToGenerate', 'MinDistance'}}, ...
        'STL', {{'STLFilePath', 'PointsPerGroup', 'GroupsToGenerate', 'MinDistance', 'PositiveVisibility'}}, ...
        'Rectangular', {{'Length', 'Width', 'Height', 'PointsPerGroup', 'GroupsToGenerate', 'MinDistance'}} ...
    );

    % All possible field tags
    allTags = {'Radius', 'Height', 'Width', 'Length', 'PointsPerGroup', 'GroupsToGenerate', ...
               'MinDistance', 'STLFilePath', 'PositiveVisibility'};

    % Set visibility based on selected function
    for i = 1:numel(allTags)
        % Toggle visibility for both label and field
        toggleVisibility(inputPanel, allTags{i}, ismember(allTags{i}, visibleFields.(selectedFunction)));
    end
end

function toggleVisibility(parent, tag, isVisible)
    visibility = 'off';
    if isVisible, visibility = 'on'; end
    
    % Find and update visibility for the field
    field = findall(parent, 'Tag', tag);
    if ~isempty(field)
        set(field, 'Visible', visibility);
    end
    
    % Find and update visibility for the label
    label = findall(parent, 'Tag', [tag, 'Label']);
    if ~isempty(label)
        set(label, 'Visible', visibility);
    end
end

function callSelectedFunction(selectedFunction, inputPanel)
    % Gather inputs from visible fields inside inputPanel
    inputFields = findall(inputPanel, 'Type', 'uieditfield', 'Visible', 'on'); % Only visible edit fields
    inputs = struct();
    objects = [];

    for i = 1:numel(inputFields)
        tag = inputFields(i).Tag;
        if ~isempty(tag)
            % Use .Value to get the value of the edit field
            inputs.(tag) = inputFields(i).Value;
        end
    end

    % Get the checkbox value for STL
    checkbox = findall(inputPanel, 'Tag', 'PositiveVisibility');
    if ~isempty(checkbox)
        inputs.PositiveVisibility = checkbox.Value;
    end

    % Ensure there are inputs to process
    if isempty(fieldnames(inputs))
        uialert(inputPanel.Parent, 'No inputs provided. Please fill in the fields.', 'Error');
        return;
    end

    % Call the appropriate function based on selection
    switch selectedFunction
        case 'Tube'
            % Extract required inputs for Tube
            try
                fig = ancestor(inputPanel, 'figure');
                if isappdata(fig, 'objects')
                    objects = getappdata(fig, 'objects');
                end
                radius = str2double(inputs.Radius);
                height = str2double(inputs.Height);
                num_points_per_group = str2double(inputs.PointsPerGroup);
                num_groups = str2double(inputs.GroupsToGenerate);
                min_dist = str2double(inputs.MinDistance);


                % Validate inputs
                if isnan(radius) || isnan(height) || isnan(num_points_per_group) || ...
                   isnan(num_groups) || isnan(min_dist)
                    error('All inputs must be numeric.');
                end

                % Call the generateTube function
                generateGroupsTube(objects, radius, height, num_points_per_group, num_groups, min_dist);

                % Notify success
                uialert(inputPanel.Parent, 'Groups generation completed.', 'Success');
            catch ME
                uialert(inputPanel.Parent, ME.message, 'Error');
            end

        case 'SemiSphere'
            try
                fig = ancestor(inputPanel, 'figure');
                if isappdata(fig, 'objects')
                    objects = getappdata(fig, 'objects');
                end                
                radius = str2double(inputs.Radius);
                num_points_per_group = str2double(inputs.PointsPerGroup);
                num_groups = str2double(inputs.GroupsToGenerate);
                min_dist = str2double(inputs.MinDistance);

                % Validate inputs
                if isnan(radius) || isnan(num_points_per_group) || ...
                   isnan(num_groups) || isnan(min_dist)
                    error('All inputs must be numeric.');
                end

                generateGroupsSemiSphere(objects, radius, num_points_per_group, num_groups, min_dist)
                % Notify success
                uialert(inputPanel.Parent, 'Groups generation completed.', 'Success');
            catch ME
                uialert(inputPanel.Parent, ME.message, 'Error');
            end

        case 'STL'
            try
                fig = ancestor(inputPanel, 'figure');
                if isappdata(fig, 'objects')
                    objects = getappdata(fig, 'objects');
                end
                num_points_per_group = str2double(inputs.PointsPerGroup);
                num_groups = str2double(inputs.GroupsToGenerate);
                min_dist = str2double(inputs.MinDistance);
                filename = inputs.STLFilePath;
                positive_visibility = inputs.PositiveVisibility;

                % Validate inputs
                if isnan(num_points_per_group) || ...
                   isnan(num_groups) || isnan(min_dist)
                    error('Check numeric inputs.');
                end
                if isempty(filename) || ~isfile(filename)
                      error('Invalid STL file.');
                end

                % Call the generateTube function
                generateGroupsSTL(objects, num_points_per_group, num_groups, min_dist, filename, positive_visibility);
                
                % Notify success
                uialert(inputPanel.Parent, 'Groups generation completed.', 'Success');
            catch ME
                uialert(inputPanel.Parent, ME.message, 'Error');
            end

        case 'Rectangular'
            try
                fig = ancestor(inputPanel, 'figure');
                if isappdata(fig, 'objects')
                    objects = getappdata(fig, 'objects');
                end
                length_rect = str2double(inputs.Length);
                width_rect = str2double(inputs.Width);
                height_rect = str2double(inputs.Height);
                num_points_per_group = str2double(inputs.PointsPerGroup);
                num_groups = str2double(inputs.GroupsToGenerate);
                min_dist = str2double(inputs.MinDistance);

                % Validate inputs
                if isnan(length_rect) || isnan(width_rect) ||isnan(height_rect) || isnan(num_points_per_group) || ...
                   isnan(num_groups) || isnan(min_dist)
                    error('All inputs must be numeric.');
                end

                generateGroupsRectangular(objects, length_rect, width_rect, height_rect, num_points_per_group, num_groups, min_dist)                % Notify success
                uialert(inputPanel.Parent, 'Groups generation completed.', 'Success');
            catch ME
                uialert(inputPanel.Parent, ME.message, 'Error');
            end

        otherwise
            error('Unknown function selected.');
    end
end


function loadAndStoreObjects(pathField, fig)
    % Retrieve the file path from the text field
    filePath = pathField.Value;
    % Validate the file path
    if isempty(filePath) || ~isfolder(filePath)
        uialert(fig, 'Invalid folder path.', 'Error');
        return;
    end

    % Call the parseMarkerFiles function and retrieve the objects
    try
        objects = parseMarkerFiles(filePath); % Assuming parseMarkerFiles exists
        % Store the objects in the figure's application data
        setappdata(fig, 'objects', objects);

        % Inform the user that the objects were loaded successfully
        uialert(fig, 'Objects loaded successfully.', 'Success');
    catch ME
        % Handle errors from parseMarkerFiles
        uialert(fig, sprintf('Error loading objects: %s', ME.message), 'Error');
    end
end