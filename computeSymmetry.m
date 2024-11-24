function [max_symmetry_weight, min_symmetry_weight] = computeSymmetry(P,d_threshold)
%% assumed all entries in mm, transform to dm to ensure numbers make sense

% Initialize weight sum
total_symmetry_weight = 0;

centered_positions = P - mean(P);
% Perform PCA
[coeff, ~, eigenvalues] = pca(centered_positions);

% Principal planes are orthogonal to the principal axes
% Principal components stored in `coeff` (columns are eigenvectors)
principal_axes = coeff;
% Iterate over each principal axis
max_symmetry_weight = 0;
for i = 1:3
    % Get the current principal axis (normal to the plane)
    normal = principal_axes(:, i);
    
    % Reflect points across the plane
    reflected_positions = centered_positions - 2 * (centered_positions * normal) * normal';
    
    % Compute distances to the closest original point
    distances = zeros(size(centered_positions, 1), 1);
    for j = 1:size(centered_positions, 1)
        % Compute Euclidean distances to all original points
        diff = centered_positions - reflected_positions(j, :);
        dists = sqrt(sum(diff.^2, 2));
        distances(j) = min(dists); % Closest point distance
    end


    % Compute adjusted distances
    adjusted_distances = distances*0.01;

    % Compute the symmetry weight
    symmetry_weight = 1 / (1 + mean(adjusted_distances));
    max_symmetry_weight = max(symmetry_weight,max_symmetry_weight);
    total_symmetry_weight = total_symmetry_weight + symmetry_weight;

    % Display intermediate results
    %fprintf('Plane %d symmetry weight: %.4f\n', i, symmetry_weight);
end
min_symmetry_weight = 1/(1+d_threshold*0.01);

end