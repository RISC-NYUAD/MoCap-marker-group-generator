function generateGroupsSemiSphere(objects, radius, num_points_per_group, num_groups, min_dist)
    % Generate random point groups in a semisphere with specified constraints

    % Prompt user for parameters
%     radius = input('Enter the radius of the semisphere in mm: ');
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
        groups{group_idx} = maximizeGroupDifference(groups, radius, num_points_per_group, min_dist, group_idx);
    end

    % Display the generated groups
    for i = length(objects) + 1:total_groups
        disp(['Group ', num2str(i - length(objects)), ':']);
        disp(groups{i});
    end

    % Plot all the groups with a wireframe semisphere
    figure;
    hold on;

    % Generate the semisphere wireframe
    [theta, phi] = meshgrid(linspace(0, pi, 30), linspace(0, 2*pi, 60));
    x = radius * sin(theta) .* cos(phi);
    y = radius * sin(theta) .* sin(phi);
    z = radius * cos(theta);

    % Plot the wireframe of the semisphere
    mesh(x, y, z, 'EdgeColor', [0.5, 0.5, 0.5], 'FaceColor', 'none');

    % Scatter plot for the points
    colors = lines(num_groups);
    for i = length(objects) + 1:total_groups
        scatter3(groups{i}(:, 1), groups{i}(:, 2), groups{i}(:, 3), 100, colors(i - length(objects), :), 'filled');
    end

    % Set axis limits to fit the semisphere
    axis equal;
    xlim([-radius, radius]);
    ylim([-radius, radius]);
    zlim([0, radius]);

    % Add labels and grid
    title('Scatter Plot of Point Groups in Semisphere with Wireframe');
    xlabel('X'); ylabel('Y'); zlabel('Z');
    legend(['SemiSphere', arrayfun(@(i) ['Group ', num2str(i)], 1:num_groups, 'UniformOutput', false)]);
    grid on;
    hold off;

end

function points =  generateRandomPointsInSemiSphereNonSymmetric(radius, num_points, min_dist)
symmetrical = true;
while symmetrical == true

    points =  generateRandomPointsInSemiSphere(radius, num_points, min_dist);
    [max_symmetry_weight, min_symmetry_weight] = computeSymmetry(points,min_dist);
    symmetrical = max_symmetry_weight > min_symmetry_weight;
end
end

function points = generateRandomPointsInSemiSphere(radius, num_points, min_dist)
% load image rendering library
addpath("RederingLibrary") 
% Generate random points in a semisphere with a minimum distance constraint
    points = [];
    % Define directions and octants for visibility
    directions = [
    +1, +1, +1;
    +1, -1, +1;
    -1, +1, +1;
    -1, -1, +1;
    ];
    while size(points, 1) < num_points
        % Generate a random point in the spherical coordinates
        theta = rand() * pi; % Theta ranges from 0 to pi (semisphere)
        phi = rand() * 2 * pi; % Phi ranges from 0 to 2*pi
        r = (radius - min_dist/2) * (rand()^(1/3)); % Uniform distribution in volume

        % Convert spherical coordinates to Cartesian
        x = r * sin(theta) * cos(phi);
        y = r * sin(theta) * sin(phi);
        z = r * cos(theta);

        % Only consider points in the semisphere (z >= 0)
        if z >= 0
            new_point = [x, y, z];

            % Check if the new point satisfies the minimum distance constraint
            if isempty(points) || all(pdist2(new_point, points) > min_dist)
            if size(points,1) == 1
                new_cube_visible = checkCubeVisibility(zeros(1,3), points, new_point, min_dist, directions); 
            else
                new_cube_visible = 1;
            end
                if any(new_cube_visible)
                points = [points; new_point]; %#ok<AGROW>
                else
                    [points; new_point]
                end
            end
        end
    end
end

function new_group = maximizeGroupDifference(groups, radius, num_points_per_group, min_dist, index)
    % Find a new group of points that maximizes the PCA + ICA difference
    max_diff_pca = 0;
    max_diff_ica = 0;
    best_group = [];

    % Try multiple random groups
    for i = 1:100
        % Generate a new group of points
        new_group = generateRandomPointsInSemiSphereNonSymmetric(radius, num_points_per_group, min_dist);
        
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
