function [diff_pca, diff_ica] = computePCADiff(new_group, prev_points)
    diff_ica = inf;
    % Equalize sizes by replicating points
    if size(new_group, 1) < size(prev_points, 1)
        diff_size = size(prev_points, 1) - size(new_group, 1);
        indices = randi(size(new_group, 1), diff_size, 1);
        new_group = [new_group; new_group(indices, :)];
    elseif size(new_group, 1) > size(prev_points, 1)
        diff_size = size(new_group, 1) - size(prev_points, 1);
        indices = randi(size(prev_points, 1), diff_size, 1);
        prev_points = [prev_points; prev_points(indices, :)];
    end
    
    % Euclidean distance matrix
    dist_matrix_new = computeDistanceMatrix(new_group);
    dist_matrix_prev = computeDistanceMatrix(prev_points);

    % Cosine of angles matrix
    cos_matrix_new = computeCosineMatrix(new_group);
    cos_matrix_prev = computeCosineMatrix(prev_points);

    % Apply PCA to both Euclidean and cosine distance matrices
    [coeff_pca_new, ~] = pca(dist_matrix_new);
    [coeff_pca_prev, ~] = pca(dist_matrix_prev);

    [coeff_pca_cos_new, ~] = pca(cos_matrix_new);
    [coeff_pca_cos_prev, ~] = pca(cos_matrix_prev);

    % % Apply ICA to both Euclidean and cosine distance matrices
    % num_components = min([size(dist_matrix_new, 2), size(dist_matrix_prev, 2)]);
    % rica_model_new = rica(dist_matrix_new, num_components);
    % rica_model_prev = rica(dist_matrix_prev, num_components);
    % 
    % rica_model_cos_new = rica(cos_matrix_new, num_components);
    % rica_model_cos_prev = rica(cos_matrix_prev, num_components);

    % Compute the PCA difference (Euclidean and Cosine combined)
    diff_pca = norm(coeff_pca_new - coeff_pca_prev, 'fro') + ...
               norm(coeff_pca_cos_new - coeff_pca_cos_prev, 'fro');

    % Compute the ICA difference (Euclidean and Cosine combined)
    % diff_ica = norm(rica_model_new.TransformWeights - rica_model_prev.TransformWeights, 'fro') + ...
    %            norm(rica_model_cos_new.TransformWeights - rica_model_cos_prev.TransformWeights, 'fro');
end


function dist_matrix = computeDistanceMatrix(points)
    % Compute pairwise Euclidean distance matrix
    dist_matrix = squareform(pdist(points));
end

function cos_matrix = computeCosineMatrix(points)
    % Compute cosine of angles between points
    
    % find cosine around mean of points
    points = points - mean(points);

    % Compute norms of points (Euclidean norm)
    norms = vecnorm(points, 2, 2);
    
    % Prevent division by zero by replacing zero norms with a small value
    norms(norms == 0) = eps;  % 'eps' is the smallest positive number in MATLAB
    
    % Compute the cosine similarity matrix
    cos_matrix = (points * points') ./ (norms * norms');
end