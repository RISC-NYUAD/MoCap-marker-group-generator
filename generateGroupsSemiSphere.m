function [] = generateGroupsSemiSphere(objects, radius, num_points_per_group, num_groups, min_dist)

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

lb = repmat([0;0;0],num_points_per_group,1);
ub = repmat([2*pi;pi/2;radius],num_points_per_group,1);
nVars = 3*num_points_per_group;
for i = 1:num_groups

objectiveFcn = @(x) -computeVisibilitySemi(x, objects, min_dist, resolution);
[x_opt, ~] = particleswarm(objectiveFcn, nVars, lb, ub, options);

X = reshape(x_opt,[3,5])';

[xx, yy, zz] = sph2cart(X(:,1), X(:,2), X(:,3));
X = [xx, yy, zz];   % now X is [x, y, z]


groups{length(groups)+1} = X;
end

for i = 1:numel(groups)
    fprintf('Group %d:\n', i);
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

function stop = myPSOOutputFcn(optimValues, state)
    stop = false;  % don’t stop
    fprintf('PSO running ...\n');
end

