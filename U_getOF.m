function of=U_getOF(im,opts)
    psz_h = 2;
    warp_h = 5;
    step = 1;%psz_h;
    penalty = 2;
    z2x = repmat(-warp_h:warp_h,2*warp_h+1,1);
    z2y = z2x';
    of = cell(1,4);

<<<<<<< HEAD
    t_cen = floor((1+opts.tsz)/2);
=======
    t_cen = (1+opts.tsz)/2;
>>>>>>> 38611fee6d1a0a178fcc4ba52ad5e378c50324bb
    cc=1;
    for tstep=setdiff(1:opts.tsz,t_cen)
        if iscell(im)
            z = IDM_map(double(rgb2gray(im{t_cen})),double(rgb2gray(im{tstep})),warp_h,psz_h,step,penalty);
        else
<<<<<<< HEAD
            if numel(size(im))==4
                z = IDM_map(double(rgb2gray(im(:,:,:,t_cen))),double(rgb2gray(im(:,:,:,tstep))),warp_h,psz_h,step,penalty);
            else
                z = IDM_map(double(im(:,:,t_cen)),double(im(:,:,tstep)),warp_h,psz_h,step,penalty);
            end
=======
            z = IDM_map(double(rgb2gray(im(:,:,:,t_cen))),double(rgb2gray(im(:,:,:,tstep))),warp_h,psz_h,step,penalty);
>>>>>>> 38611fee6d1a0a178fcc4ba52ad5e378c50324bb
        end
        of{cc} = zeros([size(z) 2],'single');
        of{cc}(:,:,1) = z2x(1+z);
        of{cc}(:,:,2) = z2y(1+z);
        cc=cc+1;
    end

