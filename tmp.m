load data/gt_cmu
param_init
    name = 'berk1.mat';
    patch_id = 2;
    D_name = D_BERK1;
    num_pervol = 200;
    num_pervol_n = 400;
nClusters = 1;
    tscale = 1;
feat_id = 6;
did=2;
for opt_id=9:12
 sname = sprintf([name(1:end-4) '_%d_%d_%d_%d_%d_%d_%d'],nClusters,num_pervol,num_pervol_n,numel(tscale),patch_id,feat_id,opt_id);
load([num2str(did) 'pb_' sname],'st3d')


thresh = 0.1:0.1:0.9;
y=zeros(1,numel(gts));
cc=zeros(numel(gts),numel(thresh),4);
for id=1:numel(gts)
id
[y(id),cc(id,:,:)] = U_occ(st3d{id},gts(id),thresh);
end
save(['eval_' sname],'y','cc')
U_fmax({cc},1)
end