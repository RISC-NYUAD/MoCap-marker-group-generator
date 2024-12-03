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