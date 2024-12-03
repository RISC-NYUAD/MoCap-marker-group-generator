function new_cube_visible = checkCubeVisibility(origin, existing_points, new_point, a, directions)
% CHECKCUBEVISIBILITY Determines visibility of a cube at a new point
%   origin: [1x3] Origin point
%   existing_points: [nx3] Matrix of existing points
%   new_point: [1x3] New point
%   a: Edge size of the rectangles (cube has size a/4)
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
    
    % Faces for rectangle (triangles)
    rect_faces = [
        1 2 3; 2 3 4; % Bottom face
        5 6 7; 6 7 8; % Top face
        1 2 5; 2 5 6; % Side 1
        3 4 7; 4 7 8; % Side 2
        1 3 5; 3 5 7; % Side 3
        2 4 6; 4 6 8; % Side 4
    ] + face_offset;

    % Store vertices and faces
    vertices = [vertices; rect_vertices];
    faces = [faces; rect_faces];
    face_offset = face_offset + size(rect_vertices, 1);
end

% Generate cube at the new point with side a/4
cube_size = a / 4;
new_cube_vertices = generateCubeVertices(new_point, cube_size);
new_cube_faces = convhull(new_cube_vertices) + face_offset;
new_cube_indeces = face_offset+1:size(new_cube_faces,1);

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
    existing_cube_indeces{i} = size(vertices_new, 1)+1:size(cube_faces,1);
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
    1 2 3; 2 3 4; % Bottom face
    5 6 7; 6 7 8; % Top face
    1 2 5; 2 5 6; % Side 1
    3 4 7; 4 7 8; % Side 2
    1 3 5; 3 5 7; % Side 3
    2 4 6; 4 6 8; % Side 4
] + face_offset;

vertices_new = [vertices_new;rect_vertices_new];
faces_new = [faces_new;rect_faces_new];

% Initialize visibility array
num_directions = size(directions, 1);
new_cube_visible = false(num_directions, size(existing_points,1)+1);


% Check visibility of the new cube for each direction
for i = 1:num_directions
    % Generate camera for the current direction
    Cam = generateCameraForDirection(vertices, directions(i, :), 2);
    [~, ~, ids] = world2image(Cam, vertices, faces);
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

% if all(new_cube_visible) == 0
% % Visualization for debugging (optional)
% figure;
% hold on;
% axis equal;
% 
% % Plot existing rectangles
% for i = 1:size(existing_points, 1)
%     patch('Vertices', vertices, 'Faces', faces((i - 1) * 12 + (1:12), :), ...
%         'FaceColor', 'red', 'FaceAlpha', 0.5, 'EdgeColor', 'none');
% end
% 
% % Plot new cube
% patch('Vertices', new_cube_vertices, 'Faces', new_cube_faces, ...
%     'FaceColor', 'blue', 'FaceAlpha', 0.5, 'EdgeColor', 'none');
% 
% % Plot origin and points
% scatter3(origin(1), origin(2), origin(3), 100, 'k', 'filled');
% scatter3(new_point(1), new_point(2), new_point(3), 100, 'b', 'filled');
% 
% % Labels
% xlabel('X');
% ylabel('Y');
% zlabel('Z');
% title('New Cube Visibility');
% view(3);
% hold off;
% end

end

function cube_vertices = generateCubeVertices(center, edge_size)
% GENERATECUBEVERTICES Generate vertices for a cube at a given center with edge size
offsets = edge_size / 2 * [-1 -1 -1; -1 -1 1; -1 1 -1; -1 1 1; ...
                           1 -1 -1;  1 -1 1;  1 1 -1;  1 1 1];
cube_vertices = center + offsets;
end


