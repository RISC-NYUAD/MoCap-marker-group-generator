function new_cube_visible = checkCubeVisibility(origin, existing_points, new_point, a, directions)
% CHECKCUBEVISIBILITY Determines visibility of a cube at a new point
%   origin: [1x3] Origin point
%   existing_points: [nx3] Matrix of existing points
%   new_point: [1x3] New point
%   a: Edge size of the rectangles (cube has size a/2)
%   directions: [mx3] Camera directions to check visibility
%
% Output:
%   new_cube_visible: [mx1] Boolean array, visibility of the new cube per direction

% Initialize storage for vertices and faces
vertices = [];
faces = [];
face_offset = 0;

% Orthogonal directions for rectangles
U = [1, 0, 0] * a / 2; % Fixed square edge direction
V = [0, 1, 0] * a / 2;

% Generate rectangles for existing points
for i = 1:size(existing_points, 1)
    P = existing_points(i, :);

    % Vertices for rectangle
    rect_vertices = [
        origin + U + V;
        origin + U - V;
        origin - U + V;
        origin - U - V;
        P + U + V;
        P + U - V;
        P - U + V;
        P - U - V;
    ];
    

    rect_faces = [
        1 2 3; 2 4 3; % Bottom face
        5 6 7; 6 8 7; % Top face
        1 2 5; 2 6 5; % Side 1
        3 4 7; 4 8 7; % Side 2
        1 3 5; 3 7 5; % Side 3
        2 4 6; 4 8 6; % Side 4
    ] + face_offset;

    % Store vertices and faces
    vertices = [vertices; rect_vertices];
    faces = [faces; rect_faces];
    face_offset = face_offset + size(rect_vertices, 1);
end

% Generate cube at the new point with side a/4
cube_size = a;
new_cube_vertices = generateCubeVertices(new_point, cube_size);
new_cube_faces = convhull(new_cube_vertices) + face_offset;
new_cube_indeces = face_offset+1:size(new_cube_faces,1) + face_offset;

vertices = [vertices; new_cube_vertices];
faces = [faces; new_cube_faces];

% Initialize storage for vertices and faces
vertices_new = [];
faces_new = [];
face_offset = 0;
existing_cube_indeces = {};

% Generate cubes for the existing points
for i = 1:size(existing_points, 1)
    cube_vertices = generateCubeVertices(existing_points(i, :), cube_size);
    cube_faces = convhull(cube_vertices) + size(vertices_new, 1);
    existing_cube_indeces{i} = size(faces_new, 1)+1:size(cube_faces,1)+size(faces_new, 1);
    vertices_new = [vertices_new; cube_vertices];
    faces_new = [faces_new; cube_faces];
end
face_offset = size(vertices_new,1);

% Generate rectangle for the new point
rect_vertices_new = [
    origin + U + V;
    origin + U - V;
    origin - U + V;
    origin - U - V;
    new_point + U + V;
    new_point + U - V;
    new_point - U + V;
    new_point - U - V;
];

rect_faces_new = [
    1 2 3; 2 4 3; % Bottom face
    5 6 7; 6 8 7; % Top face
    1 2 5; 2 6 5; % Side 1
    3 4 7; 4 8 7; % Side 2
    1 3 5; 3 7 5; % Side 3
    2 4 6; 4 8 6; % Side 4
] + face_offset;

vertices_new = [vertices_new;rect_vertices_new];
faces_new = [faces_new;rect_faces_new];

% Initialize visibility array
num_directions = size(directions, 1);
new_cube_visible = false(num_directions, size(existing_points,1)+1);


% Check visibility of the new cube for each direction
for i = 1:num_directions
    % Generate camera for the current direction

    current_dir = directions(i, :);

    % If this is the -Y camera, flip the direction
    if i == 4 || i == 2 
        current_dir = -current_dir;  % Flip the direction
    end
    
    Cam = generateCameraForDirection(vertices, current_dir, 10);
    [~, ~, ids] = world2image(Cam, vertices, faces);

%     % ---- START VISUALIZATION ----
%     cam_pos = Cam.t; % Camera position
%     cam_dir = -Cam.R(:,3); % Negative Z axis of the camera frame
%     figure(1); clf; hold on; axis equal;
% 
%     % Plot all faces in gray
%     patch('Vertices', vertices, 'Faces', faces, ...
%         'FaceColor', [0.8 0.8 0.8], 'FaceAlpha', 0.3, 'EdgeColor', 'k');
% 
%     % Plot the ray
%     quiver3(cam_pos(1), cam_pos(2), cam_pos(3), ...
%         cam_dir(1), cam_dir(2), cam_dir(3), ...
%         100, 'r', 'LineWidth', 2);
% 
%     % Plot the ray origin
%     scatter3(cam_pos(1), cam_pos(2), cam_pos(3), ...
%         100, 'filled', 'MarkerFaceColor', 'r');
% 
%     % Plot the object center (approximate)
%     scatter3(mean(vertices(:,1)), mean(vertices(:,2)), mean(vertices(:,3)), ...
%         10, 'filled', 'MarkerFaceColor', 'b');
% 
%     drawFOVCone(cam_pos, cam_dir, deg2rad(70), 1000); % length 1000 (or scale as needed)
% 
%     title(['Direction ' num2str(i)]);
%     xlabel('X'); ylabel('Y'); zlabel('Z');
%     view(3);
% 
%     pause(0.5); % So you can see each direction one by one
%     % ---- END VISUALIZATION ----

    % Find visible faces
    visible_faces = ids;

    % Check if the new cube is visible
    new_cube_visible(i,end) = any(ismember(new_cube_indeces, visible_faces));

    [~, ~, ids] = world2image(Cam, vertices_new, faces_new);
    visible_faces = ids;

    for j = 1:size(existing_points,1)
        new_cube_visible(i,j) = any(ismember(existing_cube_indeces{j}, visible_faces));
    end
end
new_cube_visible = any(new_cube_visible);
new_cube_visible = all(new_cube_visible);

end

function cube_vertices = generateCubeVertices(center, edge_size)
% GENERATECUBEVERTICES Generate vertices for a cube at a given center with edge size
offsets = edge_size / 2 * [-1 -1 -1; -1 -1 1; -1 1 -1; -1 1 1; ...
                           1 -1 -1;  1 -1 1;  1 1 -1;  1 1 1];
cube_vertices = center + offsets;
end

% function drawFOVCone(origin, direction, fov, length)
%     % Draw a simple FOV cone as lines
% 
%     % Normalize direction
%     direction = direction / norm(direction);
% 
%     % Create a rotation matrix aligning Z axis with the direction
%     z = direction;
%     up = [0, 0, 1];
%     if abs(dot(z, up)) > 0.999
%         up = [0, 1, 0];
%     end
%     x = cross(up, z); x = x / norm(x);
%     y = cross(z, x);
% 
%     R = [x(:), y(:), z(:)];
% 
%     % Define cone angle
%     radius = length * tan(fov/2);
% 
%     % Circle points at the end of the cone
%     theta = linspace(0, 2*pi, 20);
%     circle = [radius * cos(theta); radius * sin(theta); repmat(length, 1, numel(theta))];
% 
%     % Rotate circle to align with direction
%     circle_world = R * circle;
% 
%     % Plot cone lines
%     for i = 1:numel(theta)
%         plot3([origin(1), origin(1)+circle_world(1,i)], ...
%               [origin(2), origin(2)+circle_world(2,i)], ...
%               [origin(3), origin(3)+circle_world(3,i)], 'm');
%     end
% 
%     % Plot the circle at the far end
%     plot3(origin(1)+circle_world(1,:), ...
%           origin(2)+circle_world(2,:), ...
%           origin(3)+circle_world(3,:), 'm');
% end
