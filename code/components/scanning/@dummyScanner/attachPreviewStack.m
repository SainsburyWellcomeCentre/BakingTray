function attachPreviewStack(obj,pStack)
    %  function attachPreviewStack(obj,pStack)
    %
    %  e.g.
    %  load some_pStack
    %  hBT.scanner.attachExistingData(pStack)

    verbose=false;

    % Add data to object
    obj.imageStackData=pStack.imStack;
    obj.imageStackVoxelSizeXY = pStack.voxelSizeInMicrons;
    obj.imageStackVoxelSizeZ = pStack.recipe.mosaic.sliceThickness;

    % Set the number of optical planes to 1, as we won' be doing this here
    obj.numOpticalPlanes=1;
    obj.parent.recipe.mosaic.numOpticalPlanes=obj.numOpticalPlanes;
    obj.currentOpticalPlane=1;

    obj.getClim % Set the max plotted value

    % Initially move stage to origin to avoid any possible errors caused by it being out 
    % of position due to possibly larger previous sample
    obj.parent.moveXYto(0,0)

    % pad sample by about a tile preparation for autoROI. The pad value will be pi, 
    % so we can find it later and remove it from stats or whatever as needed. 
    padTiles=2;
    padBy =round(ceil(pStack.tileSizeInMicrons/pStack.voxelSizeInMicrons)*padTiles);

    obj.imageStackData = padarray(obj.imageStackData,[padBy,padBy,0],pi);

    % Report the new image size
    im_mmY = size(obj.imageStackData,2) * obj.imageStackVoxelSizeXY * 1E-3;
    im_mmX = size(obj.imageStackData,1) * obj.imageStackVoxelSizeXY * 1E-3;

    if verbose
        fprintf('Padding preview stack image by %d pixels (%0.1f tiles) yielding a total area of x=%0.1f mm by y=%0.1f mm\n', ...
            padBy, padTiles, im_mmX, im_mmY)
    end

    % Set min/max limits of the stages so we can't scan outside of the available area
    obj.parent.xAxis.attachedStage.maxPos = 0;
    obj.parent.yAxis.attachedStage.maxPos = 0;

    obj.parent.xAxis.attachedStage.minPos = -floor(im_mmX) + pStack.tileSizeInMicrons*1E-3;
    obj.parent.yAxis.attachedStage.minPos = -floor(im_mmY) + pStack.tileSizeInMicrons*1E-3;
    if verbose
        fprintf('Setting min allowed stage positions to: x=%0.2f y=%0.2f\n', ...
            obj.parent.xAxis.attachedStage.minPos, ...
            obj.parent.yAxis.attachedStage.minPos)
    end

    % Move stages to the middle of the sample area so we are more likely to see something if we take an image
    midY = -im_mmY/2;
    midX = -im_mmX/2;
    obj.parent.moveXYto(midX,midY)

    % Set the sample size to something reasonable based on the area of the sample
    obj.scannerSettings.FOV_alongColsinMicrons=pStack.tileSizeInMicrons;
    obj.scannerSettings.FOV_alongRowsinMicrons=pStack.tileSizeInMicrons;


    obj.scannerSettings.pixelsPerLine=round(obj.scannerSettings.FOV_alongColsinMicrons / obj.imageStackVoxelSizeXY);
    obj.scannerSettings.linesPerFrame=round(obj.scannerSettings.FOV_alongColsinMicrons / obj.imageStackVoxelSizeXY);

    % Calculate the extent of the originally imaged area
    obj.parent.recipe.mosaic.sampleSize.Y = size(pStack.imStack,2) * obj.imageStackVoxelSizeXY*1E-3;
    obj.parent.recipe.mosaic.sampleSize.X = size(pStack.imStack,1) * obj.imageStackVoxelSizeXY*1E-3 ;


    % Set the front/left so we start at the corner of the sample, not the padded area
    obj.parent.recipe.FrontLeft.X = -padBy * pStack.voxelSizeInMicrons * 1E-3;
    obj.parent.recipe.FrontLeft.Y = -padBy * pStack.voxelSizeInMicrons * 1E-3;

    if verbose
        fprintf('Front/Left is at %0.2f x %0.2f mm\n', ...
            obj.parent.recipe.FrontLeft.X, ...
            obj.parent.recipe.FrontLeft.Y)
    end

    % Set scanner pixel size
    obj.scannerSettings.micronsPerPixel_cols = pStack.voxelSizeInMicrons;
    obj.scannerSettings.micronsPerPixel_rows = pStack.voxelSizeInMicrons;

    % Set the stitching voxel size in the recipe
    obj.parent.recipe.StitchingParameters.VoxelSize.X = pStack.voxelSizeInMicrons;
    obj.parent.recipe.StitchingParameters.VoxelSize.Y = pStack.voxelSizeInMicrons;

    % Set the number of sections in the recipe file based on the number available in the stack
    obj.parent.recipe.mosaic.numSections=size(pStack.imStack,3);
    hBT.currentTilePosition=1;

    % Determine reasonable x and y limits for the section image so we don't display
    % the padded area
    obj.sectionImage_xlim = [padBy+1,size(obj.imageStackData,2)-padBy-1];
    obj.sectionImage_ylim = [padBy+1,size(obj.imageStackData,1)-padBy-1];


    % Set more fields in the recipe
    obj.parent.recipe.sample.ID = pStack.recipe.sample.ID;
    obj.parent.recipe.mosaic.overlapProportion = pStack.recipe.mosaic.overlapProportion;

    obj.parent.currentSectionNumber=1;
end