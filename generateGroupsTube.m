 function generateGroupsTube(objects, radius, height, num_points_per_group, num_groups, min_dist)
    % Generate random point groups in a tube with specified constraints

    % Prompt user for parameters
%     radius = input('Enter the radius of the tube in mm: ');
%     height = input('Enter the height of the tube in mm: ');
%     num_points_per_group = input('Enter the number of points per group: ');
%     num_groups = input('Enter the number of groups to generate (excluding objects): ');
%     min_dist = input('Enter the minimum distance between points in mm: ');

    % Adjust the total number of groups to include objects
    total_groups = num_groups + length(objects);   
    % Initialize groups: Extend the length by the number of objects
    groups = cell(num_groups + length(objects), 1);
    
    % First, add the markers of objects to the first few groups
    for group_idx = 1:length(objects)  % Limit to the number of groups or objects available
        groups{group_idx} = objects(group_idx).markers;
    end
    
    % Now generate the random points for the remaining groups
    for group_idx = length(objects) + 1:num_groups + length(objects)
        % Generate a new group of random points that maximizes the PCA + ICA difference
        groups{group_idx} = maximizeGroupDifference(groups, radius, height, num_points_per_group, min_dist, group_idx);;
    end
    % Display the generated groups
    for i = length(objects) + 1:num_groups + length(objects)
        disp(['Group ', num2str(i - length(objects)), ':']);
        disp(groups{i});
    end
    
    % Plot all the groups with a wireframe cylindrical tube
    figure;
    hold on;
    
    % Generate the wireframe of the tube
    [theta, z] = meshgrid(linspace(0, 2 * pi, 50), linspace(0, height, 50));
    x = radius * cos(theta);
    y = radius * sin(theta);
    
    % Plot the wireframe of the tube
    mesh(x, y, z, 'EdgeColor', [0.5, 0.5, 0.5], 'FaceColor', 'none');
    
    % Scatter plot for the points
    colors = lines(num_groups);
    for i = length(objects) + 1:total_groups
        scatter3(groups{i}(:, 1), groups{i}(:, 2), groups{i}(:, 3), 100, colors(i - length(objects), :), 'filled');
    end
    
    % Set axis limits and labels
    axis equal;
    xlim([-radius, radius]);
    ylim([-radius, radius]);
    zlim([0, height]);
    title('Scatter Plot of Point Groups in Tube with Wireframe');
    xlabel('X'); ylabel('Y'); zlabel('Z');
    legend(['Cylinder',arrayfun(@(i) ['Group ', num2str(i)], 1:num_groups, 'UniformOutput', false)]);
    grid on;
    hold off;


end

function points =  generateRandomPointsInTubeNonSymmetric(radius, height, num_points, min_dist)
symmetrical = true;
while symmetrical == true

    points =  generateRandomPointsInTube(radius, height, num_points, min_dist);
    [max_symmetry_weight, min_symmetry_weight] = computeSymmetry(points,min_dist);
    symmetrical = max_symmetry_weight > min_symmetry_weight;
end
end

function points = generateRandomPointsInTube(radius, height, num_points, min_dist)
    % Generate random points in a tube with a minimum distance constraint
    points = [];
    while size(points, 1) < num_points
        % Generate random point in the tube
        angle = rand() * 2 * pi;
        r = sqrt(rand()) * (radius - min_dist/2);
        z = min_dist/2 + rand() * (height -  min_dist);
        new_point = [r * cos(angle), r * sin(angle), z];
        
        % Check if the new point satisfies the minimum distance constraint
        if isempty(points) || all(pdist2(new_point, points) > min_dist)
            points = [points; new_point]; %#ok<AGROW>
        end
    end
end

function new_group = maximizeGroupDifference(groups, radius, height, num_points, min_dist, index)
    % Find a new group of points that maximizes the PCA + ICA difference
    max_diff_pca = 0;
    max_diff_ica = 0;
    best_group = [];

    % Try multiple random groups
    for i = 1:100
        % Generate a new group of points
        new_group = generateRandomPointsInTubeNonSymmetric(radius, height, num_points, min_dist);
        
        min_diff_pca = inf;
        min_diff_ica = inf;

        for j = 1:index-1
            % Get the previous groups' points
            prev_points = groups{j};
            % Compute the difference in PCA and ICA over both Euclidean and cosine distances
            [diff_pca, diff_ica] = computePCADiff(new_group, prev_points);
            min_diff_pca = min(min_diff_pca, diff_pca);
            min_diff_ica = min(min_diff_ica, diff_ica);
        end
        % Maximize the difference
        if min_diff_pca > max_diff_pca && min_diff_ica > max_diff_ica
            max_diff_pca = min_diff_pca;
            max_diff_ica = min_diff_ica;
            best_group = new_group;
        end
    end
    
    % Return the best group found
    new_group = best_group;
end

