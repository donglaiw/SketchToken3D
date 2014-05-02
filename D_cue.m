param_init


cid=3;
switch cid
case 1
% flow
     alpha = 0.05;
    ratio = 0.5;
    minWidth = 10;
    nOuterFPIterations = 7;
    nInnerFPIterations = 1;
    nSORIterations = 30;
    para = [alpha,ratio,minWidth,nOuterFPIterations,nInnerFPIterations,nSORIterations];
    addpath('/home/Stephen/Desktop/VisionLib/Donglai/Low/Flow/CeOF')
case 2
    % stbd
    addpath(genpath([D_VLIB 'Mid/Boundary/SketchTokens']))    
    load('modelFull.mat');
case 3
    tsz_step = 1;
    tsz_h=2;
    addpath(genpath([D_VLIB 'Low/Filter/Neal']))
end


did=2;
switch did
case 1
DD=D_BERK1;
spre = 'BERK1_';
case 2
DD=D_CMU;
spre = 'CMU_';
end


fns = dir(DD);fns(1:2)=[];
im_pre='im';
parfor id=1:numel(fns)
    ims = uint8(U_fns2ims([DD fns(id).name '/' im_pre]));
    tcen = U_getTcen([DD fns(id).name '/'],did);        

    switch cid
    case 1   
    for fid = 1:2        
        tar = double(im(:,:,:,tcen+(fid*2-3)*2))/255;
        [vx,vy,warpI2] = Coarse2FineTwoFrames(double(im(:,:,:,tcen))/255,tar,para);
        flo = cat(3,vx,vy);
        U_psave([spre fns(id).name '_of' num2str(fid) '.mat'],{'flo'},flo);
    end   
    case 2
    s_s = [1 0.75 0.5 0.25];
    s_bd = cell(1,numel(s_s));
    for k = 1:numel(s_s)
        im = imresize(ims(:,:,:,tcen),s_s(k),'nearest');
        st = stDetect( im, model );
        s_bd{k} = stToEdges( st, 1 );
    end
    U_psave([spre fns(id).name '_s2d.mat'],{'s_bd'},s_bd);    

    case 3
    % phase    
    %ims = ims(:,:,:,tcen+(-tsz_h*tsz_step:tsz_step:tsz_h*tsz_step));
    % hack for CMU
    dif = mean(mean(ims(:,:,1,1:end-1)-ims(:,:,1,2:end)));
    thres = mean(dif(tcen+[0 1]));
    dif = dif>thres;
    ind1 = find(dif(tcen+1:end)==dif(tcen));
    ind2 = find(dif(1:tcen-1)==dif(tcen));
    ims = ims(:,:,:,[ind2(end-1:end) tcen+[0 ind(1:2)]);

    ims = 0.2989 * ims(:,:,1,:) + 0.5870 * ims(:,:,2,:) + 0.1140 * ims(:,:,3,:);    
    %ims = cat(4,ims(:,:,:,1),ims);
    T_phase(ims,[spre fns(id).name '_phase.mat']);
    end    
end



