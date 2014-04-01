function T_of(i,did)
param_init;
switch did
case 1
DD=D_BERK1;
case 2
DD = [D_CMU 'clips/'];
end

fns=dir(DD);
fns(1:2)=[];
if ~exist([DD '../feat/of_' fns(i).name '.mat'],'file')
    addpath(genpath([D_VLIB 'Util/io']))
    addpath('lib/IDM')
    psz_h = 2;
    warp_h = 5;
    step = 1;%psz_h;
    penalty = 2;
    z2x = repmat(-warp_h:warp_h,2*warp_h+1,1);
    z2y = z2x';

    tmp_fn = U_getims([DD fns(i).name '/']);
    tmp_fn([arrayfun(@(x) tmp_fn(x).name(1)=='g',1:numel(tmp_fn))])=[];
    tcen = U_getTcen([DD fns(i).name],did);
    cc=1;
    % 1 dim first
    im = uint8(U_fns2ims([DD fns(i).name '/'],tmp_fn(tcen+(-2:2))));
    of = cell(1,4);
    for tstep=setdiff(1:5,3)
        z = IDM_map(double(rgb2gray(im(:,:,:,3))),double(rgb2gray(im(:,:,:,tstep))),warp_h,psz_h,step,penalty);
        of{cc} = zeros([size(z) 2],'single');
        of{cc}(:,:,1) = z2x(1+z);
        of{cc}(:,:,2) = z2y(1+z);
        cc=cc+1;
    end
    save([DD '../feat/of_' fns(i).name],'of')
end
%{
 PP = pwd;
 system(['./para/p_run.sh 1 2 30 "' PP '/para" "' PP '" "T_of(" ",2);"'])

 DD = '/data/vision/billf/deep-learning/data/Berk_occ/feat/';
fns = dir([DD '*.mat']);

 z2x = repmat(-warp_h:warp_h,2*warp_h+1,1);
 z2y = z2x';
for i=1:numel(fns)
    load([DD fns(i).name],'zs')
    of= cell(1,numel(zs));
    for j=1:numel(zs)
        of{j} = zeros([size(zs{1}) 2],'single');
        of{j}(:,:,1) = z2x(1+zs{j});
        of{j}(:,:,2) = z2y(1+zs{j});
    end
    save([DD fns(i).name],'of')
end

%}
