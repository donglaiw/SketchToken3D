param_init
fns = dir(D_CMU);fns(1:2)=[];
id = 10;
%ims = U_fns2ims([D_CMU fns(id).name '/img']);

ims= cat(4,imread('/home/Stephen/Desktop/Data/Flow/Middleburry_eval/Army/frame07.png'),...
	imread('/home/Stephen/Desktop/Data/Flow/Middleburry_eval/Army/frame08.png'));

addpath(genpath([D_VLIB 'Low/Flow/costfilter']))
% Parameter settings
r = 9;                  % filter kernel in eq. (3) has size r \times r
warp_h = 5;
eps = 0.0001;           % \epsilon in eq. (3)
thresColor = 7/255;     % \tau_1 in eq. (5)
thresGrad = 2/255;      % \tau_2 in eq. (5)
gamma = 0.11;           % (1- \alpha) in eq. (5)
threshBorder = 3/255;   % some threshold for border pixels
gamma_c = 0.1;          % \sigma_c in eq. (6)
gamma_d = 9;            % \sigma_s in eq. (6)
r_median = 19;          % filter kernel of weighted median in eq. (6) has size r_median \times r_median

% Compute disparity map for middlebury test images (vision.middlebury.edu/stereo/)
[vx,vy]=flow_cf(ims(:,:,:,1:2),warp_h,r,eps,thresColor,thresGrad,gamma,threshBorder,gamma_c,gamma_d,r_median,1);


 z2x = repmat(-warp_h:warp_h,2*warp_h+1,1);
 z2y = z2x';

  subplot(221),imagesc(z2x(vx));
  subplot(222),imagesc(z2y(vx));

  subplot(223),imagesc(z2x(vy));
  subplot(224),imagesc(z2y(vy));

