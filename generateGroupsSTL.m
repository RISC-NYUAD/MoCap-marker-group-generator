function generateGroupsSTL(objects,num_points_per_group, num_groups, min_dist, filename, positive_visibility)
% positive visibility indicates if we need all markers to be visible from
% top
% then we choose points from directions:
%5: [0, 0, 1]       (+Z)
%7: [+1, +1, +1]    (Top-right-front octant)
%9: [+1, -1, +1]    (Top-right-back octant)
%11: [-1, +1, +1]    (Top-left-front octant)
%13: [-1, -1, +1]    (Top-left-back octant)
% num_points_per_group = input('Enter the number of points per group: ');
% num_groups = input('Enter the number of groups to generate (excluding objects): ');
% min_dist = input('Enter the minimum distance between points in mm: ');
% positive_visibility = input('Do you need all markers visible from top? (true of false) ');
% filename =  input('Input the address of your STL inside single quoations: ');
% Load the STL file
stlData = stlread(filename);

% Extract vertices and faces
vertices = stlData.Points;
faces = stlData.ConnectivityList;
normals = stlData.faceNormal;


   % first load STL, get candidate points and clusters
   % points generated are part of 3D grid, with min_dist/2 granularity
   [allPoints, clustered_directions, cluster_idx, clustered_points] = getPointsFromSTL(filename, num_points_per_group*2+1, min_dist, positive_visibility);
   
   clusters_centers = zeros(length(clustered_points),3);
   for i = 1:length(clustered_points)
        clusters_centers(i,:) = mean(clustered_points{i});
   end



    % Initialize groups
    total_groups = num_groups + length(objects);
    groups = cell(total_groups, 1);

    % First, add the markers of objects to the first few groups
    for group_idx = 1:length(objects)
        groups{group_idx} = objects(group_idx).markers;
    end

    for group_idx = 1 + length(objects):total_groups
        % Find the next group that maximizes the PCA + ICA difference
        groups{group_idx} = maximizeGroupDifference(groups, clustered_points, clusters_centers, clustered_directions, num_points_per_group, min_dist, group_idx);
    end
    
    % Display the generated groups
    for i = 1 + length(objects):total_groups
        disp(['Group ', num2str(i - length(objects)), ':']);
        disp(groups{i});
    end
    
    % Plot all the groups
    figure;
    hold on;
    % Plot the STL surface
patch('Faces', faces, 'Vertices', vertices, ...
      'FaceColor', [0.8 0.8 1.0], 'EdgeColor', 'none', ...
      'FaceLighting', 'gouraud', 'AmbientStrength', 0.15);

    colors = lines(num_groups);
    for i = length(objects) + 1:total_groups
        scatter3(groups{i}(:, 1), groups{i}(:, 2), groups{i}(:, 3), 100, colors(i- length(objects), :), 'filled');
    end
    title('Scatter Plot of Point Groups');
    xlabel('X'); ylabel('Y'); zlabel('Z');
    legend(['STL' , arrayfun(@(i) ['Group ', num2str(i)], 1:num_groups, 'UniformOutput', false)]);
    grid on;
    hold off;
end

function points = generateRandomPointsSTLNonSymmetrical(clustered_points, clusters_centers, clustered_directions, num_points_per_group, min_dist)
symmetrical = true;
while symmetrical == true

    points = generateRandomPointsSTL(clustered_points, clusters_centers, clustered_directions, num_points_per_group, min_dist);
    [max_symmetry_weight, min_symmetry_weight] = computeSymmetry(points,min_dist);
    symmetrical = max_symmetry_weight > min_symmetry_weight;
end
end


function points = generateRandomPointsSTL(clustered_points, clusters_centers, clustered_directions, num_points_per_group, min_dist)
    points = [];
    num_clusters = length(clustered_points);
    selected_directions = []; % Store directions of selected points
    clusters = 1:num_clusters;


   while size(points, 1) < num_points_per_group
        % Calculate distances between cluster centers and existing points
        if isempty(points)
            distances = ones(1, num_clusters); % No points chosen yet
        else
            distances = min(pdist2(points, clusters_centers), [], 1); % Min distance from each center to chosen points
        end
        
        % Weight clusters based on distance (higher distances preferred)
        weights_clusters = distances / sum(distances); % Normalize weights
        
        % Choose a cluster probabilistically based on weights
        cluster_idx = randsample(1:length(weights_clusters), 1, true, weights_clusters);
        points_c = clustered_points{clusters(cluster_idx)};
        directions_c = clustered_directions{clusters(cluster_idx)};

        % Calculate direction weights for points in the chosen cluster
        if isempty(selected_directions)
            direction_weights = ones(size(points_c, 1), 1); % No selected directions yet
        else
            direction_weights = zeros(size(points_c, 1), 1);
            for i = 1:size(points_c, 1)
                candidate_dir = directions_c(i, :); % Candidate point's direction
                similarities = abs(candidate_dir * selected_directions'); % Dot product similarity
                direction_weights(i) = 1 / (1 + max(similarities)); % Weight inversely proportional to max similarity
            end
        end
        
        % Normalize direction weights
        direction_weights = direction_weights / sum(direction_weights);
        
        % Choose a point probabilistically based on direction weights
        point_idx = randsample(1:size(points_c, 1), 1, true, direction_weights);
        new_point = points_c(point_idx, :);
        new_direction = directions_c(point_idx, :);

        % Check if the new point satisfies the minimum distance constraint
        if isempty(points) || all(pdist2(new_point, points) > min_dist)
            points = [points; new_point]; 
            selected_directions = [selected_directions; new_direction]; % Add direction to selected list
            clusters(cluster_idx) = [];
            clusters_centers(cluster_idx, :) = [];
        end
    end
end


function new_group = maximizeGroupDifference(groups, clustered_points, clusters_centers,clustered_directions,  num_points_per_group, min_dist, index)
    % Find a new group of points that maximizes the PCA + ICA difference
    
    
    max_diff_pca = 0;
    max_diff_ica = 0;
    best_group = [];

    % Try multiple random groups
    for i = 1:100
        
        % Generate a new group of points
        new_group = generateRandomPointsSTLNonSymmetrical(clustered_points, clusters_centers, clustered_directions, num_points_per_group, min_dist);
        
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
