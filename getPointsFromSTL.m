function [allPoints, clusterd_directions, cluster_idx, clustered_points] = getPointsFromSTL(filename, clusterCount, min_dist, positive_visibility) 
% load image rendering library
addpath("RederingLibrary")

% Load the STL file
stlData = stlread(filename);

% Extract vertices and faces
vertices = stlData.Points;
faces = stlData.ConnectivityList;
normals = stlData.faceNormal;

% Parameters
gridResolution = min_dist; % Minimum spacing between points (mm)

% Initialize storage for all generated points
allPoints = [];

% Define directions and octants
directions = [
    +1,  0,  0;  % +X
    -1,  0,  0;  % -X
    0, +1,  0;  % +Y
    0, -1,  0;  % -Y
    0,  0, +1;  % +Z
    0,  0, -1;  % -Z
    ];

octants = [
    +1, +1, +1;
    +1, +1, -1;
    +1, -1, +1;
    +1, -1, -1;
    -1, +1, +1;
    -1, +1, -1;
    -1, -1, +1;
    -1, -1, -1;
    ];

% Combine directions and octants
allDirections = [directions; octants];
numDirections = size(allDirections, 1);

% Initialize storage for visible faces
visibleFaces = cell(numDirections, 1);
visibilitiyMatrix = zeros(size(faces,1),numDirections);

% Compute visible faces for each direction
for i = 1:numDirections
    %Cam = generateCamera(allDirections(i, :));
    Cam = generateCameraForDirection(vertices, allDirections(i, :), 2);
    [~, ~, ids] = world2image(Cam, vertices, faces);
    visibleFaces{i} = ids; % Store visible face indices
    visibilitiyMatrix(ids,i) = 1;
end

% Define the column indices corresponding to top directions
col_top_directions = [5, 7, 9, 10, 11, 12, 13]; %
visibilitiyMatrix = visibilitiyMatrix(:,col_top_directions);
numDirections = length(col_top_directions);

if positive_visibility
% Logical mask: faces visible from any top direction
    is_visible_from_top = any(visibilitiyMatrix, 2);
else
    is_visible_from_top = ones(size(visibilitiyMatrix, 1),1);
end

visibilitiyMatrixPoints = [];
tic;

% Precompute the total number of points to preallocate visibility matrix
totalPoints = 0;
for i = 1:size(faces, 1)
    if ~is_visible_from_top(i) 
        continue;
    end
    tri = faces(i, :);
    v1 = vertices(tri(1), :);
    v2 = vertices(tri(2), :);
    v3 = vertices(tri(3), :);
    e1 = v2 - v1;
    e2 = v3 - v1;
    area = 0.5 * norm(cross(e1, e2));
    totalPoints = totalPoints + ceil(area / (gridResolution^2));
end
visibilitiyMatrixPoints = zeros(totalPoints,numDirections);
allPoints = zeros(totalPoints,3);
current_index = 1;
% Loop through each triangle
for i = 1:size(faces, 1)
    if ~is_visible_from_top(i)
        continue;
    end
    % Get the vertices of the current triangle
    tri = faces(i, :);
    v1 = vertices(tri(1), :);
    v2 = vertices(tri(2), :);
    v3 = vertices(tri(3), :);

    % Calculate triangle edges and normal
    e1 = v2 - v1;
    e2 = v3 - v1;
    %normal = cross(e1, e2);
    %normal = normal / norm(normal); % Normalize the normal
    normal = normals(i,:);

    % Compute the area of the triangle
    area = 0.5 * norm(cross(e1, e2));

    % Estimate the number of points based on the triangle area
    numPoints = ceil(area / (gridResolution^2));

    % Generate uniformly spaced points within the triangle using barycentric coordinates
    for n = 1:numPoints
        % Generate random barycentric coordinates
        r1 = rand();
        r2 = rand();
        if (r1 + r2 > 1)
            r1 = 1 - r1;
            r2 = 1 - r2;
        end
        b1 = 1 - r1 - r2;
        b2 = r1;
        b3 = r2;

        % Convert to Cartesian coordinates
        newPoint = b1 * v1 + b2 * v2 + b3 * v3;

        % Add the point to the collection (discretized)
        newPoint = round(newPoint / gridResolution) * gridResolution;
        allPoints(current_index+n-1,:) = newPoint;
    end

        visibilitiyMatrixPoints(current_index:current_index+numPoints-1,:) =...
            repmat(visibilitiyMatrix(i,:),numPoints,1);
        current_index = current_index+numPoints;
    %visibilitiyMatrixPoints = [visibilitiyMatrixPoints;...
    %    repmat(visibilitiyMatrix(i,:),numPoints,1)];%#ok<AGROW>
end

% Remove duplicate points
[allPoints, uniqueIdx] = unique(allPoints, 'rows');
visibilitiyMatrixPoints = visibilitiyMatrixPoints(uniqueIdx,:);
distanceThreshold = gridResolution;

toc
% Compute closest directions for all points

% Visualize the STL and generated points
figure;
hold on;

% Plot the STL surface
patch('Faces', faces, 'Vertices', vertices, ...
      'FaceColor', [0.8 0.8 1.0], 'EdgeColor', 'none', ...
      'FaceLighting', 'gouraud', 'AmbientStrength', 0.15);

% Plot all generated points
plot3(allPoints(:, 1), allPoints(:, 2), allPoints(:, 3), 'r.', 'MarkerSize', 5);

% Set visualization properties
axis equal;
camlight('headlight');
material('dull');
xlabel('X');
ylabel('Y');
zlabel('Z');
title('Candidate Points Along STL Surface');
grid on;
hold off;


cluster_idx = kmeans(allPoints,clusterCount);
% Visualize the clusters
figure;
scatter3(allPoints(:,1), allPoints(:,2), allPoints(:,3), 10, cluster_idx, 'filled');
hold on;
title('Clustered Candidate Points');
xlabel('X'); ylabel('Y'); zlabel('Z');
grid on;

clusters = unique(cluster_idx);
num_clusters = length(clusters);
clustered_points = {};
clustered_directions = {};
for i = 1:num_clusters
    clustered_points{i} = allPoints(cluster_idx==i,:); %#ok<AGROW>
    clusterd_directions{i} = visibilitiyMatrixPoints(cluster_idx==i,:);%#ok<AGROW>
end



end


function Cam = generateCameraForDirection(vertices, direction, scaleFactor)
    % Calculate the object's bounding box
    minBounds = min(vertices, [], 1);
    maxBounds = max(vertices, [], 1);

    % Calculate the object's center and size
    objectCenter = (minBounds + maxBounds) / 2;
    objectSize = norm(maxBounds - minBounds);

    % Calculate the camera position
    cameraPosition = objectCenter + scaleFactor * objectSize * direction;

    % Define the projection matrix (e.g., perspective)
    PROJECTION_MATRIX = ProjectionMatrix(deg2rad(70), 1, 0.1);

    % Define the camera rotation matrix
    viewDir = objectCenter - cameraPosition; % Camera looks at the center
    viewDir = viewDir / norm(viewDir);      % Normalize
    rotationMatrix = createRotationMatrix(viewDir);

    % Define the image size
    IMAGE_SIZE = [300, 300];

    % Create the camera
    Cam = Camera(PROJECTION_MATRIX, IMAGE_SIZE, cameraPosition, rotationMatrix);
end

function rotationMatrix = createRotationMatrix(direction)
    % Create a rotation matrix to align the camera with the given direction
    up = [0, 0, 1]; % Default up direction
    if all(direction == [0, 0, 1]) || all(direction == [0, 0, -1])
        up = [0, 1, 0]; % Change up direction for Z-axis views
    end
    z = -direction / norm(direction); % Negative view direction (camera looks at origin)
    x = cross(up, z); % Orthogonal vector
    x = x / norm(x);
    y = cross(z, x);
    rotationMatrix = [x; y; z];
end



