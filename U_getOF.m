function of=U_getOF(im,opts)
switch opts.did
case {1,2}    
    of = cell(1,opts.tsz);
    switch opts.of_fn
    case 'of_ce'
        load([opts.DD '../' opts.of_fn '/' opts.flo_name '_of1'])
        of{1} = flo;
        load([opts.DD '../' opts.of_fn '/' opts.flo_name '_of2'])
        of{2} = flo;
        num=2;
    case 'of_idm'
        tmp=load([opts.DD '../' opts.of_fn '/' opts.flo_name],'of');
        num=numel(tmp.of);
        of(1:num) = tmp.of;
    case 'of_idm2'
        tmp=load([opts.DD '../' opts.of_fn(1:end-1) '/' opts.flo_name],'dis');
        num=numel(tmp.dis);
        of(1:num) = tmp.dis;
    case 'of_idm3'
        tmp=load([opts.DD '../' opts.of_fn(1:end-1) '/' opts.flo_name],'of2');
        num=numel(tmp.of2);
        of(1:num) = tmp.of2;
    end
    for jj=(num+1):opts.tsz;of{jj}=zeros(size(of{1}),'single');end
otherwise
    psz_h = 2;
    warp_h = 5;
    step = 1;%psz_h;
    penalty = 2;
    z2x = repmat(-warp_h:warp_h,2*warp_h+1,1);
    z2y = z2x';

    of = cell(1,opts.tsz);
    t_cen = floor((1+opts.tsz)/2);
    cc=1;
    for tstep=setdiff(1:opts.tsz,t_cen)
        if iscell(im)
            z = IDM_map(double(rgb2gray(im{t_cen})),double(rgb2gray(im{tstep})),warp_h,psz_h,step,penalty);
        else
            if numel(size(im))==4
                z = IDM_map(double(rgb2gray(im(:,:,:,t_cen))),double(rgb2gray(im(:,:,:,tstep))),warp_h,psz_h,step,penalty);
            else
                z = IDM_map(double(im(:,:,t_cen)),double(im(:,:,tstep)),warp_h,psz_h,step,penalty);
            end
        end
        of{cc} = zeros([size(z) 2],'single');
        of{cc}(:,:,1) = z2x(1+z);
        of{cc}(:,:,2) = z2y(1+z);
        cc=cc+1;
    end
    for jj=cc:opts.tsz;of{jj}=zeros(size(of{1}),'single');end
end
