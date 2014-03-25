param_init
addpath('core')
addpath(genpath([D_VLIB '../Piotr/']))
addpath(genpath([D_VLIB 'Util/io']))
opts=struct('DD',D_BERK1,...
            'loadmat',[D_ST3D 'data/berk1'],...
            'patch_id',2,...
            'feat_id',3,...
            'radius',17,...
            'pratio',0.3,...
            'tsz',  5,...
            'tscale', [1 2 4],...
            'num_pervol',200,...
            'num_pervol_n',0,...
            'ntChns',2);

opts= st3dMakeOpts(opts);

[mat_x,mat_y] = st3dGetPatch(opts);
save -v7.3 data/patch_berk mat_x mat_y

% Kmeans or MoG
addpath([D_VLIB 'Opt'])
% need to rescale each channel [0 1]
%{
mat_x = reshape(mat_x,[],opts.nCells^2,opts.nChns,(opts.tsz-1));
for i=1:opts.nChns
    % mean
    mat_x(:,:,i,:) = (mat_x(:,:,i,:)-min(min(min(mat_x(:,:,i,:)))))/(max(max(max(mat_x(:,:,i,:))))-min(min(min(mat_x(:,:,i,:))))); 
end
mat_x = reshape(mat_x,size(mat_x,1),[]);
%}
% std
tmp_std = std(mat_x);
mat_x = bsxfun(@rdivide,mat_x,tmp_std);

ncluster = 100;
niter = 200;
tic;[label, center] = litekmeans(double(mat_x), ncluster, 'MaxIter', niter);toc

clusters.clusters = single(center);
clusters.chStd = tmp_std;
save data/cluster_berk100 clusters
opts.clusterFnm = 'data/cluster_berk100';
opts.patch_id =3;
[mat_x,mat_y] = st3dGetPatch(opts);
len = arrayfun(@(x) numel(mat_x{x}),1:numel(mat_x));
nScale = numel(opts.tscale);
clusters.imId = cell2mat(arrayfun(@(x) x*ones(1,sum(len((x-1)*nScale+(1:nScale)))),1:numel(mat_x)/nScale));
clusters.scaleId = cell2mat(arrayfun(@(x) mod(x,nScale)*ones(1,len(x)),1:numel(mat_x)));
clusters.scaleId(clusters.scaleId==0) = nScale;
clusters.ind = cell2mat(mat_x);
clusters.clusterId = cell2mat(mat_y);
%{
aa=histc(label,1:ncluster)
[a,b]=max(aa);
bb= reshape(center(b,:),[opts.nCells,opts.nCells,opts.nChns,opts.tsz-1]);
for i=1:4;subplot(2,2,i);imagesc(bb(:,:,1,i));colorbar;end
%}
