function visibility_counts = PostcheckCubesVisibility(existing_points, a, resolution)

% --- PARAMETERS ---
cube_size = 5000; % Size of the camera cube (meters)

% --- Step 1: Build vertices and faces for the scene ---
% (rectangles + small cubes at the existing points)
[vertices, faces, cube_indices] = buildScene(existing_points, a);

% --- Step 2: Define camera positions (8 cameras) ---
ground_height = 0;
top_height = cube_size;

base_positions = [
    -cube_size/2, -cube_size/2;
    -cube_size/2,  cube_size/2;
     cube_size/2, -cube_size/2;
     cube_size/2,  cube_size/2;
];

ground_cameras = [base_positions, repmat(ground_height, 4, 1)];
top_cameras    = [base_positions, repmat(top_height, 4, 1)];

camera_positions = [ground_cameras; top_cameras];

objectCenter = mean(vertices);

% --- Step 3: Set up rotations ---
angles = 0:resolution:360-resolution; % degrees
num_cameras = size(camera_positions,1);
num_existing = size(existing_points,1);
visibility_counts = zeros(length(angles), num_existing); % one column per small cube

% --- Step 4: Loop over rotations ---
for ai = 1:length(angles)
    theta = deg2rad(angles(ai));
    Rz = [
        cos(theta), -sin(theta), 0;
        sin(theta),  cos(theta), 0;
        0,           0,          1
    ];

    rotated_vertices = (Rz * vertices')';

    % Track which cubes are seen at this rotation
    cube_visible = false(num_existing, num_cameras);

    % --- Loop over cameras ---
     for ci = 1:num_cameras
     %for ci = 8
        cam_pos = camera_positions(ci,:);
        cam_dir = objectCenter - cam_pos;


        [Cam, rotationMatrix] = generateCameraForDirectionFromPosition(cam_pos, cam_dir);
        [proj_vertices, ~, ids] = world2image(Cam, rotated_vertices, faces);

%         figure(20); clf; hold on;
%         scatter(proj_vertices(:,1), proj_vertices(:,2), 20, 'filled');
%         title(['Camera ' num2str(ci) '  at rotation ' num2str(angles(ai))]);
%         xlim([0 300]);
%         ylim([0 300]);
%         axis ij; % flip Y to image coordinates
        
        % --- Check visibility per cube ---
        for j = 1:num_existing
            if any(ismember(cube_indices{j}, ids))
                cube_visible(j, ci) = true;
            end
        end
    end

    % Count how many cameras see each cube at this rotation
    visibility_counts(ai, :) = sum(cube_visible, 2);

    % --- Optional visualization ---
%     figure(10); clf; hold on; axis equal;
%     patch('Vertices', rotated_vertices, 'Faces', faces, ...
%           'FaceColor', [0.8 0.8 0.8], 'FaceAlpha', 0.3, 'EdgeColor', 'k');
% 
%     % Draw cameras and FOV cones
%     for ci = 1:num_cameras
%         cam_pos = camera_positions(ci, :);
%         scatter3(cam_pos(1), cam_pos(2), cam_pos(3), ...
%                  100, 'filled', 'MarkerFaceColor', 'r');
% 
%         % View direction
%         cam_dir = objectCenter - cam_pos;
%         cam_dir = cam_dir / norm(cam_dir);
% 
%         % Draw direction arrow
%         quiver3(cam_pos(1), cam_pos(2), cam_pos(3), ...
%                 cam_dir(1), cam_dir(2), cam_dir(3), ...
%                 cube_size/4, 'LineWidth', 2, 'Color', 'b');
% 
%         % Draw FOV cone
%         drawFOVcone(cam_pos, cam_dir, deg2rad(70), cube_size/4); % 70 deg FOV like your projection matrix
%     end
% 
%     title(['Rotation ' num2str(angles(ai)) '°']);
%     xlabel('X'); ylabel('Y'); zlabel('Z');
%     view(3);
%     drawnow;
end

% Display result
% disp('Visibility counts (rows = Rotations, columns = Markers):');
% disp(visibility_counts);

end

function [vertices, faces, cube_indices] = buildScene(existing_points, a)

vertices = [];
faces = [];
face_offset = 0;

% Rectangles for existing points
U = [1, 0, 0] * a / 2;
V = [0, 1, 0] * a / 2;

for i = 1:size(existing_points,1)
    P = existing_points(i,:);

    rect_vertices = [
        [0 0 0] + U + V;
        [0 0 0] + U - V;
        [0 0 0] - U + V;
        [0 0 0] - U - V;
        P + U + V - [0 0 a/2];
        P + U - V - [0 0 a/2];
        P - U + V - [0 0 a/2];
        P - U - V - [0 0 a/2];
    ];

    rect_faces = [
        1 2 3; 2 4 3;
        5 6 7; 6 8 7;
        1 2 5; 2 6 5;
        3 4 7; 4 8 7;
        1 3 5; 3 7 5;
        2 4 6; 4 8 6;
    ] + face_offset;

    vertices = [vertices; rect_vertices];
    faces = [faces; rect_faces];
    face_offset = face_offset + 8;
end

% Cubes for existing points (markers)
cube_indices = {};
cube_size = a / 2;

for i = 1:size(existing_points,1)
    cube_vertices = PostgenerateCubeVertices(existing_points(i,:), cube_size);
    cube_faces = convhull(cube_vertices) + size(vertices,1);

    cube_indices{i} = size(faces,1)+1:size(faces,1)+size(cube_faces,1);
    vertices = [vertices; cube_vertices];
    faces = [faces; cube_faces];
end

end

function [Cam ,rotationMatrix] = generateCameraForDirectionFromPosition(cameraPosition, direction)
    PROJECTION_MATRIX = ProjectionMatrix(deg2rad(75), 1, 0.1, 10000);
    IMAGE_SIZE = [300, 300];
    viewDir = direction / norm(direction);
    rotationMatrix = createRotationMatrix_new(viewDir);

    Cam = Camera(PROJECTION_MATRIX, IMAGE_SIZE, cameraPosition, rotationMatrix);
end

function cube_vertices = PostgenerateCubeVertices(center, edge_size)
    offsets = edge_size / 2 * [-1 -1 -1; -1 -1 1; -1 1 -1; -1 1 1; ...
                               1 -1 -1;  1 -1 1;  1 1 -1;  1 1 1];
    cube_vertices = center + offsets;
end

function rotationMatrix = createRotationMatrix_new(direction)
    % Create a rotation matrix to align the camera with the given direction
    up = [0, 0, 1]; % Default up direction
    if all(direction == [0, 0, 1]) || all(direction == [0, 0, -1])
        up = [0, 1, 0]; % Change up direction for Z-axis views
    end
    
    z = -direction / norm(direction); % Negative view direction (camera looks at origin)
    if (direction(2) < 0)
        x = cross(up, z); % Orthogonal vector
    else
        x = cross(z, up); % Orthogonal vector
    end
    x = x / norm(x);
    y = cross(z, x)/norm(cross(z, x));
    rotationMatrix = [x(:), y(:), z(:)];
end

function drawFOVcone(cam_pos, cam_dir, fov_angle, cone_length)
    % cam_pos : 1x3 camera position
    % cam_dir : 1x3 normalized direction vector
    % fov_angle : full field of view angle in radians
    % cone_length : how far the cone extends

    % Make orthonormal basis for the cone's circle
    z = cam_dir(:); % ensure column
    arbitrary = [0; 0; 1];
    if abs(dot(z, arbitrary)) > 0.99
        arbitrary = [0; 1; 0];
    end

    x = cross(arbitrary, z); x = x / norm(x);
    y = cross(z, x);

    % Circle at the cone base
    t = linspace(0, 2*pi, 30);
    radius = cone_length * tan(fov_angle / 2);
    circle_pts = cam_pos(:) + z * cone_length + ...
                 radius * (x * cos(t) + y * sin(t)); % 3 x N matrix

    % Draw lines from camera to circle perimeter
    for i = 1:length(t)
        plot3([cam_pos(1), circle_pts(1,i)], ...
              [cam_pos(2), circle_pts(2,i)], ...
              [cam_pos(3), circle_pts(3,i)], 'g');
    end

    % Draw circle at base
    plot3(circle_pts(1,:), circle_pts(2,:), circle_pts(3,:), 'g-', 'LineWidth', 1.5);
end
