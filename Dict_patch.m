function Dict_patch(opts)

if ~exist(opts.clusterFnm,'file')
    fprintf(' --  Dictionary Learning  --  \n');
    opts.patch_id =2;
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
    opts.clusterFnm = 'data/cluster_berk100';
    save(opts.clusterFnm,'clusters')

    opts.patch_id =3;
    [mat_x,mat_y] = st3dGetPatch(opts);
    len = arrayfun(@(x) numel(mat_x{x}),1:numel(mat_x));
    nScale = numel(opts.tscale);
    clusters.imId = cell2mat(arrayfun(@(x) x*ones(1,sum(len((x-1)*nScale+(1:nScale)))),1:numel(mat_x)/nScale,'UniformOutput',false))';
    clusters.scaleId = cell2mat(arrayfun(@(x) mod(x,nScale)*ones(1,len(x)),1:numel(mat_x),'UniformOutput',false))';
    clusters.scaleId(clusters.scaleId==0) = nScale;
    clusters.ind = cell2mat(mat_x);
    clusters.clusterId = cell2mat(mat_y);
    save(opts.clusterFnm,'clusters')
end

% check stats:
%aa=histc(clusters.clusterId,1:ncluster);
%{
aa=histc(label,1:ncluster)
[a,b]=max(aa);
aa= sum(abs(clusters.clusters),2);
[a,b]=min(aa);
opts.tsz=5;opts.nChns=14;opts.nCells=5;
bb= reshape(clusters.clusters(b,:),[opts.nCells,opts.nCells,opts.nChns,opts.tsz-1]);
for i=1:4;subplot(2,2,i);imagesc(bb(:,:,1,i));colorbar;end

%}
