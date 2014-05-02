param_init

im1=imread('/home/Stephen/Desktop/Data/Flow/Middleburry_eval/Army/frame07.png');
im2=imread('/home/Stephen/Desktop/Data/Flow/Middleburry_eval/Army/frame08.png');

opts.tsz=2;
of = U_getOF({im1,im2},opts);

addpath(genpath([D_VLIB '/Util/flow/mb']))

subplot(321),imagesc(of{1}(:,:,1))
subplot(322),imagesc(of{1}(:,:,2))

addpath(genpath([D_VLIB '/Low/Filter/bfilter2']))
w     = [5 5];       % bilateral filter half-width
sigma = [1 0.2]; % bilateral filter standard deviations
subplot(323),imagesc(U_bila(double(rgb2gray(im1))/255,double(of{1}(:,:,1)),2*w+1,sigma))
subplot(324),imagesc(U_bila(double(rgb2gray(im2))/255,double(of{1}(:,:,2)),2*w+1,sigma))

subplot(325),imagesc(medfilt2(of{1}(:,:,1),2*w+1))
subplot(326),imagesc(medfilt2(of{1}(:,:,2),2*w+1))




param_init
fns = dir(D_CMU);fns(1:2)=[];
id = 29;
ims = U_fns2ims([D_CMU fns(id).name '/img']);
ims2 = U_resize(ims,0.5);


opts.tsz=2;
of = U_getOF({im1,im2},opts);
