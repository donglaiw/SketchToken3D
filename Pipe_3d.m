param_init
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% A. Train 2D boundary detector
% A.1 opts
tid = -1;
ntree = 20;
switch tid
case -1
    % berk train: 2-class
    name = 'berk1.mat';
    patch_id = 2;
    feat_id = -1;
    D_name = D_BERK1;
    num_pervol = 200;
    num_pervol_n = 400;opt_id=-1;
    nClusters = 1;
    tscale = 1;
case 1
    % segtrack train: 2-class
    name = 'segt.mat';
    patch_id = 1;
    feat_id = 2;
    D_name = D_STRACK;
    num_pervol = 200;
    num_pervol_n = 200;opt_id=2;
    nClusters = 1;
    tscale = 1;
case 2
    % berk train: 2-class
    name = 'berk1.mat';
    patch_id = 2;
    feat_id = 2;
    D_name = D_BERK1;
    num_pervol = 200;
    num_pervol_n = 160;opt_id=3;
    num_pervol_n = 400;opt_id=4;
    nClusters = 1;
    tscale = 1;
case 3
    % berk train: 101-class
    name = 'berk1.mat';
    patch_id = 4;
    feat_id = 2;
    D_name = D_BERK1;
    num_pervol = 200;
    num_pervol_n = 160;opt_id=5;
    nClusters = 100;
    tscale = [1 2 4];
case 4
    % berk train: 2-class
    name = 'berk1.mat';
    patch_id = 2;
    D_name = D_BERK1;
    num_pervol = 200;
    num_pervol_n = 400;
    %feat_id = 4;opt_id=6;
    did = 1;
    feat_id = 5;opt_id=7;
    nClusters = 1;
    tscale = 1;
end
sname = sprintf([name(1:end-4) '_%d_%d_%d_%d_%d_%d'],nClusters,num_pervol,num_pervol_n,numel(tscale),patch_id,feat_id);
if exist(['data/opt_' sname],'file')
    load(['data/opt_' sname])
    ntree = opts.nTrees;
else
opts=struct('DD',D_name,...
            'loadmat',[D_ST3D 'data/gt_' name],...
            'patch_id',patch_id,...
            'feat_id',feat_id,...
            'radius',17,...
            'pratio',0.3,...
            'did',  did,...
            'tsz',  5,...
            'tstep', 2,...
            'tscale', tscale,...
            'num_pervol',num_pervol,...
            'num_pervol_n',num_pervol_n,...
            'ntChns',2,...
            'nClusters',nClusters,...
            'nTrees',ntree,...
            'clusterFnm',[D_ST3D 'data/cluster_' num2str(nClusters) '_' name],...
            'modelFnm',['model_' sname]);
    save(['data/opt_' sname],'opts')
end

if opts.nClusters>1
    % need to learn dictionary
    Dict_patch(opts)
end
% A.2 parallel train N trees
do_local=0;
if do_local
    %try;matlabpool;end;
    cd core
    parfor id=1:ntree;st3dTrain_p(opts,id);end
    cd ../
else
    PP=pwd;
    system(['./para/p_run.sh 1 1 ' num2str(ntree) ' "' PP '/para" "' PP '/core" "st3dTrain_p(' num2str(opt_id) '," ");"'])
end
error(1)
% A.3 form the forest
cd core;st3dTrain(opts);cd ..
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% B. test boundary detection
load(['models/forest/' opts.modelFnm '_' num2str(ntree)])
DD='/data/vision/billf/stereo-vision/Data/';
fns = dir([DD 'Occ/CMU/clips']);
fns(1:2)=[];
tsz_h = (model.opts.tsz-1)/2;
tsz_step = 1;% number of frames in between 
st3d = cell(1,numel(fns));
im=[];
for i=1:numel(fns)
    im = uint8(U_fns2ims([DD 'Occ/CMU/clips/' fns(i).name '/img_']));
    fn  = dir([DD 'Occ/CMU/clips/' fns(i).name '/ground_truth*']);
    id = str2double(fn.name(find(fn.name=='_',1,'last')+1:end-4))+1;
    %try
        tmp_st = st3dDetect( im(:,:,:,id+(-tsz_h*tsz_step:tsz_step:tsz_h*tsz_step)), model );
        st3d{i} = 1-tmp_st(:,:,end);
    %end
end
save(['pb_' sname],'st3d')
for i=1:numel(fns)
    try
        if tsz_step==1
             imwrite(stToEdges( 1-st3d{i}, 1 ),['st3d_' fns(i).name '.png'])
        else
             imwrite(stToEdges( 1-st3d{i}, 1 ),['st3d2_' fns(i).name '.png'])
        end
    end
end


load data/gt_cmu
thresh = 0.3:0.1:0.8;
y=zeros(1,numel(gts));
cc=zeros(numel(gts),numel(thresh),4);
for id=1:numel(gts)
id
[y(id),cc(id,:,:)] = U_occ(st3d{id},gts(id),thresh);
end
save(['eval_' sname],'y','cc')
U_fmax({cc},1);
