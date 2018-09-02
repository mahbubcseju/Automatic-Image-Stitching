clear all;
close all;
clc;
%% Load Image

directory = 'enhanceImages';
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

%% Image enhancement using adaptive histogram equalization

images = imageDatastore(directory);

while hasdata(images)
    [B,info] = read(images);
    hsvB = rgb2hsv(B);
    hChannel = hsvB(:, :, 1);
    sChannel = hsvB(:, :, 2);
    vChannel = hsvB(:, :, 3);
    vChannel = adapthisteq(vChannel);
    hsvB2 = cat(3, hChannel, sChannel, vChannel);
    B2 = hsv2rgb(hsvB2);
    imwrite(B2,info.Filename);
end
