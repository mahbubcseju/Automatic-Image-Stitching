clear all;
close all;
clc;
%% Load Images
directory = 'enhancedImages';
images = imageDatastore(directory);

%% Image Resize according to first image

numImages = numel(images.Files);
I = readimage(images, 1);
sz = size(I);
while hasdata(images)
    [B,info] = read(images);
    B = imresize(B, [sz(1) sz(2)]);
    imwrite(B,info.Filename);
end
%% display input images
montage(images.Files)

%% Image Registration

% Reading First Image
I = readimage(images, 1);

% Initialize feature for First Image I(1)

grayImage = rgb2gray(I);
points = detectSURFFeatures(grayImage);
% points = detectFASTFeatures(grayImage);
% points = detectHarrisFeatures(grayImage);
% points = detectMSERFeatures(grayImage);
[features, points] = extractFeatures(grayImage, points);

% Initialize all the transforms to the identity matrix.

tforms(numImages) = projective2d(eye(3));
%  tforms(numImages) = affine2d(eye(3));

% iterating over remain Images
for n = 2:numImages
    % Previous features
    prevPoints = points;
    prevFeatures = features;
    
    % Read I(n) image
    pi = I;
    I = readimage(images,n);
    grayImage = rgb2gray(I);
    points = detectSURFFeatures(grayImage);
%     points = detectFASTFeatures(grayImage);
%     points = detectHarrisFeatures(grayImage);
%     points = detectMSERFeatures(grayImage);
    [features, points] = extractFeatures(grayImage, points);

    indexPairs = matchFeatures(features, prevFeatures,'Unique',true);
    
    matchedPoints = points(indexPairs(:,1), :);
    prevMatchedPoints = prevPoints(indexPairs(:,2), :);
    
    %Estimate the Homography transformation using RANSAC algorithm
    tforms(n) = estimateGeometricTransform(matchedPoints, prevMatchedPoints,'projective');
    
    % Compute T(n) * T(n-1) * ... * T(1)
    tforms(n).T = tforms(n).T * tforms(n-1).T;
end
imageSize = size(I);  % all the images are the same size

% Compute the output limits  for each transform
for i = 1:numel(tforms)
    [xlim(i,:), ylim(i,:)] = outputLimits(tforms(i), [1 imageSize(2)], [1 imageSize(1)]);
end
avgXLim = mean(xlim, 2);

[~, idx] = sort(avgXLim);

centerIdx = floor((numel(tforms)+1)/2);

centerImageIdx = idx(centerIdx);
Tinv = invert(tforms(centerImageIdx));

for i = 1:numel(tforms)
    tforms(i).T = tforms(i).T * Tinv.T;
end

for i = 1:numel(tforms)
    [xlim(i,:), ylim(i,:)] = outputLimits(tforms(i), [1 imageSize(2)], [1 imageSize(1)]);
end

%% Initializing Empty panorama

% Find the minimum and maximum output limits
xMin = min([1; xlim(:)]);
xMax = max([imageSize(2); xlim(:)]);

yMin = min([1; ylim(:)]);
yMax = max([imageSize(1); ylim(:)]);

% Width and height of panorama.
width  = round(xMax - xMin);
height = round(yMax - yMin);

% Initialize the "empty" panorama.
panorama = zeros([height width 3], 'like', I);
blender = vision.AlphaBlender('Operation', 'Binary mask', ...
    'MaskSource', 'Input port');

% Create a 2-D spatial reference object defining the size of the panorama.
xLimits = [xMin xMax];
yLimits = [yMin yMax];
panoramaView = imref2d([height width], xLimits, yLimits);

directory = 'originalImages';
images = imageDatastore(directory);
I = readimage(images, 1);

%% Create the panorama.
for i = 1:numImages

    I = readimage(images, i);

    % Transform I into the panorama.
    warpedImage = imwarp(I, tforms(i), 'OutputView', panoramaView);
    %figure, imshow(warpedImage);
    % Generate a binary mask.
    mask = imwarp(true(size(I,1),size(I,2)), tforms(i), 'OutputView', panoramaView);

    % Overlay the warpedImage onto the panorama.
    panorama = step(blender, panorama, warpedImage, mask);
end

%% Display panorama

figure
imshow(panorama)
% title('Stitched Images')
set(gca,'XTick',[]) % Remove the ticks in the x axis!
set(gca,'YTick',[]) % Remove the ticks in the y axis
set(gca,'Position',[0 0 1 1]) % Make the axes occupy the hole figure
saveas(gcf,'SURF1','jpg')
% saveas(gcf,'FAST1','jpg')
% saveas(gcf,'Harris1','jpg')
% saveas(gcf,'MSER1','jpg')
set(gca,'Position',[0.08 0.08 .84 .84])
