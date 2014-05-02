function ff=U_eval(pb)
% pb: cell of probability map
param_init
load data/gt_cmu
thresh = 0.1:0.1:0.9;
y=zeros(1,numel(gts));
cc=zeros(numel(gts),numel(thresh),4);
for id=1:numel(gts)
id
[y(id),cc(id,:,:)] = U_occ(pb{id},gts(id),thresh);
end
save(['eval_' sname],'y','cc')
ff = U_fmax({cc});
