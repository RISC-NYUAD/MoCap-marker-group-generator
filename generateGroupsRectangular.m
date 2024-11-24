function generateGroupsRectangular(objects, length_rect, width_rect, height_rect, num_points_per_group, num_groups, min_dist)
    % Generate random point groups in a rectangular volume with specified constraints

    % Prompt user for parameters
%     length_rect = input('Enter the length of the rectangular volume in mm: ');
%     width_rect = input('Enter the width of the rectangular volume in mm: ');
%     height_rect = input('Enter the height of the rectangular volume in mm: ');
%     num_points_per_group = input('Enter the number of points per group: ');
%     num_groups = input('Enter the number of groups to generate (excluding objects): ');
%     min_dist = input('Enter the minimum distance between points in mm: ');

    % Adjust the total number of groups to include objects
    total_groups = num_groups + length(objects);
    groups = cell(total_groups, 1);
    
    % First, add the markers of objects to the first few groups
    for group_idx = 1:length(objects)
        groups{group_idx} = objects(group_idx).markers;
    end

    % Generate random points for the remaining groups
    for group_idx = length(objects) + 1:total_groups
        groups{group_idx} = maximizeGroupDifference(groups, length_rect, width_rect, height_rect, num_points_per_group, min_dist, group_idx);
    end

    % Display the generated groups
    for i = length(objects) + 1:total_groups
        disp(['Group ', num2str(i - length(objects)), ':']);
        disp(groups{i});
    end

    % Plot all the groups with a wireframe rectangular volume
    figure;
    hold on;

    % Generate the corners of the rectangular volume
    corners = [
        0, 0, 0;
        length_rect, 0, 0;
        length_rect, width_rect, 0;
        0, width_rect, 0;
        0, 0, height_rect;
        length_rect, 0, height_rect;
        length_rect, width_rect, height_rect;
        0, width_rect, height_rect
    ];
    
    % Define edges of the wireframe
    edges = [
        1, 2; 2, 3; 3, 4; 4, 1; % Bottom face
        5, 6; 6, 7; 7, 8; 8, 5; % Top face
        1, 5; 2, 6; 3, 7; 4, 8  % Vertical edges
    ];
    
    % Plot the wireframe
    for i = 1:size(edges, 1)
        plot3([corners(edges(i, 1), 1), corners(edges(i, 2), 1)], ...
              [corners(edges(i, 1), 2), corners(edges(i, 2), 2)], ...
              [corners(edges(i, 1), 3), corners(edges(i, 2), 3)], 'k');
    end
    
    % Scatter plot for the points
    colors = lines(num_groups);
    for i = length(objects) + 1:total_groups
        scatter3(groups{i}(:, 1), groups{i}(:, 2), groups{i}(:, 3), 100, colors(i - length(objects), :), 'filled');
    end
    
    % Set axis limits and labels
    axis equal;
    xlim([0, length_rect]);
    ylim([0, width_rect]);
    zlim([0, height_rect]);
    title('Scatter Plot of Point Groups in Rectangular Volume with Wireframe');
    xlabel('X'); ylabel('Y'); zlabel('Z');
    legend(arrayfun(@(i) ['Group ', num2str(i)], 1:num_groups, 'UniformOutput', false));
    grid on;
    hold off;


end

function points =  generateRandomPointsInRectangularNonSymmetric(length_rect, width_rect, height_rect, num_points, min_dist)
symmetrical = true;
while symmetrical == true

    points =  generateRandomPointsInRectangular(length_rect, width_rect, height_rect, num_points, min_dist);
    [max_symmetry_weight, min_symmetry_weight] = computeSymmetry(points,min_dist);
    symmetrical = max_symmetry_weight > min_symmetry_weight;
end
end

function points = generateRandomPointsInRectangular(length_rect, width_rect, height_rect, num_points, min_dist)
    % Generate random points in a rectangular volume with a minimum distance constraint
    points = [];
    while size(points, 1) < num_points
        % Generate a random point within the rectangular bounds
        x = min_dist/2 + rand() * (length_rect - min_dist);
        y = min_dist/2 + rand() * (width_rect - min_dist);
        z = min_dist/2 + rand() * (height_rect - min_dist);
        new_point = [x, y, z];
        
        % Check if the new point satisfies the minimum distance constraint
        if isempty(points) || all(pdist2(new_point, points) > min_dist)
            points = [points; new_point]; %#ok<AGROW>
        end
    end
end

function new_group = maximizeGroupDifference(groups, length_rect, width_rect, height_rect, num_points_per_group, min_dist, index)
    % Find a new group of points that maximizes the PCA + ICA difference
    max_diff_pca = 0;
    max_diff_ica = 0;
    best_group = [];

    % Try multiple random groups
    for i = 1:100
        % Generate a new group of points
        new_group = generateRandomPointsInRectangularNonSymmetric(length_rect, width_rect, height_rect, num_points_per_group, min_dist);
        
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
