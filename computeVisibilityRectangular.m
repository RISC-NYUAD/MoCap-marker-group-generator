function cost = computeVisibilityRectangular(x, old_groups, min_dist,resolution)
    X = reshape(x,[3,5])';

    [max_symmetry_weight, min_symmetry_weight] = computeSymmetry(X,min_dist);
    symmetrical = max_symmetry_weight > min_symmetry_weight;
    if symmetrical
        cost = 1;
    else
    cost_matrix = PostcheckCubesVisibility(X, min_dist, resolution);
    N = length(old_groups);
    pca_cost = inf;
    if N > 0
    for i = 1:N
        [diff_pca, ~] = computePCADiff(X, old_groups{i}, min_dist);
        pca_cost = min(diff_pca,pca_cost);
    end
    else 
        pca_cost = 0;
    end

    
    cost = mean(mean(cost_matrix)) + pca_cost;
    end
end