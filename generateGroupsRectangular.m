function [] = generateGroupsRectangular(objects, length_rect, width_rect, height_rect, num_points_per_group, num_groups, min_dist)
resolution = 10;

% Adjust the total number of groups to include objects
total_groups = num_groups + length(objects);
groups = {};%cell(total_groups, 1);

% First, add the markers of objects to the first few groups
for group_idx = 1:length(objects)
    groups{group_idx} = objects(group_idx).markers;
end

addpath(genpath('RederingLibrary'));

options = optimoptions('particleswarm', ...
    'SwarmSize', 20, ...       % Number of particles
    'MaxIterations', 50, ...   % Iteration budget
    'Display', 'off', ...      % Show optimization progress
    'HybridFcn', @fmincon,...     % Optional: refine result with local search
    'OutputFcn', @myPSOOutputFcn, ...
    'UseParallel', true);

lb = repmat([-length_rect/2;-width_rect/2;0],num_points_per_group,1);
ub = repmat([length_rect/2;width_rect/2;height_rect],num_points_per_group,1);
nVars = 3*num_points_per_group;
for i = 1:num_groups

objectiveFcn = @(x) -computeVisibilityRectangular(x, objects, min_dist, resolution);
[x_opt, ~] = particleswarm(objectiveFcn, nVars, lb, ub, options);

X = reshape(x_opt,[3,5])';

groups{length(groups)+1} = X;
end

for i = 1:numel(groups)
    fprintf('Group %d:\n', i);
    disp(groups{i});
end

 % Plot all the groups with a wireframe rectangular volume
    figure;
    hold on;

    L = length_rect/2;
    W = width_rect/2;
    H = height_rect;

    corners = [
       -L, -W, 0;
        L, -W, 0;
        L,  W, 0;
       -L,  W, 0;
       -L, -W, H;
        L, -W, H;
        L,  W, H;
       -L,  W, H
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
    xlim([-length_rect/2, length_rect/2]);
    ylim([-width_rect/2, width_rect/2]);
    zlim([0, height_rect]);
    title('Scatter Plot of Point Groups in Rectangular Volume with Wireframe');
    xlabel('X'); ylabel('Y'); zlabel('Z');
    legend(arrayfun(@(i) ['Group ', num2str(i)], 1:num_groups, 'UniformOutput', false));
    grid on;
    hold off;
   

end

function stop = myPSOOutputFcn(optimValues, state)
    stop = false;  % don’t stop
    fprintf('PSO running ...\n');
end

