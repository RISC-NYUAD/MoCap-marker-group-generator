function runGenerateGroups(objects)
    % Display menu for user input
    choice = menu('Select a geometry to generate markers in:', ...
                  '1-Tube', ...
                  '2-SemiSphere', ...
                  '3-Rectangular Volume', ...
                  '4-Robot STL');
    
    % Call the corresponding function based on user choice
    switch choice
        case 1
            generateGroupsTube(objects);
        case 2
            generateGroupsSemiSphere(objects);
        case 3
            generateGroupsRectangular(objects);
         case 4
             generateGroupsSTL(objects);
        otherwise
            disp('No valid selection made. Exiting...');
    end
end
