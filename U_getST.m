function st=U_getST(im,opts)
switch opts.did
case {1,2}
    st = cell(1,opts.tsz);
    load([opts.DD '../bd_st/' opts.flo_name '_s2d'])
    sz = size(s_bd{1});
    for jj=1:opts.drf;st{jj}=imresize(s_bd{jj},sz,'nearest');end
    for jj=(opts.drf+1):opts.tsz;st{jj}=zeros(size(st{1}),'single');end
otherwise
    st =[];
end
