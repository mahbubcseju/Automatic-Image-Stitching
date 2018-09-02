
directory = '/home/krishna/Documents/MATLAB/images';
images = imageDatastore(directory);
I1 = readimage(images, 1);
grayImage = rgb2gray(I1);
% points1 = detectSURFFeatures(grayImage);
% points1 = detectFASTFeatures(grayImage);
% points1 = detectHarrisFeatures(grayImage);
points1 = detectMSERFeatures(grayImage);
[features1, points1] = extractFeatures(grayImage, points1);
%     figure, imshow(I1); hold on;
%     plot(points1);
I2 = readimage(images, 2);
grayImage = rgb2gray(I2);

% points2 = detectSURFFeatures(grayImage);
% points2 = detectFASTFeatures(grayImage);
% points2 = detectHarrisFeatures(grayImage);
points2 = detectMSERFeatures(grayImage);
[features2, points2] = extractFeatures(grayImage, points2);
%     figure, imshow(I2); hold on;
%     plot(points2);
% 
% % subplot(1,2,1);
% % imshow(I1); hold on;
% % plot(points1);
% % subplot(1,2,2);
% % imshow(I2); hold on;
% % plot(points2);
%   imshow(I1,I2,'montag');
   indexPairs = matchFeatures(features1, features2,'Unique',true);
%    size(indexPairs)
% %     
   matchedPoints1 = points1(indexPairs(:,1), :);
   matchedPoints2 = points2(indexPairs(:,2), :);
    
% % %    Display match points
     figure, showMatchedFeatures(I1,I2,matchedPoints1,matchedPoints2);