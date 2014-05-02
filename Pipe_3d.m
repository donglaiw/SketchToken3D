param_init
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% A. Train 2D boundary detector
% A.1 opts
tid = 4;
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
    feat_id = 4;opt_id=8;
    feat_id = 6;drf=1;nbd_thres=0.1;of_fn='of_idm';opt_id=9;
    feat_id = 6;drf=4;nbd_thres=0.4;of_fn='of_idm';opt_id=10;
    feat_id = 6;drf=1;nbd_thres=0.4;of_fn='of_idm';opt_id=11;
    feat_id = 6;drf=4;nbd_thres=0.1;of_fn='of_idm';opt_id=12;
    feat_id = 7;drf=4;nbd_thres=0.1;opt_id=13;
    feat_id = 8;drf=4;nbd_thres=0.1;opt_id=14;
    feat_id = 6;drf=1;nbd_thres=0.1;of_fn='of_idm2';opt_id=15;
    feat_id = 6;drf=1;nbd_thres=0.1;of_fn='of_idm3';opt_id=16;
    feat_id = 6;drf=1;nbd_thres=0.1;of_fn='of_idm3';pool_id=3;opt_id=17;
    feat_id = 9;drf=1;nbd_thres=0.1;of_fn='of_idm3';pool_id=3;opt_id=18;
    feat_id = 9;drf=1;nbd_thres=0.1;of_fn='of_idm3';pool_id=4;opt_id=19;
    nClusters = 1;
    tscale = 1;
end
sname = sprintf([name(1:end-4) '_%d_%d_%d_%d_%d_%d_%d'],nClusters,num_pervol,num_pervol_n,numel(tscale),patch_id,feat_id,opt_id);
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
            'drf',drf,...
            'of_fn',of_fn,...
            'pool_id',pool_id,...
            'nbd_thres',nbd_thres,...
            'clusterFnm',[D_ST3D 'data/cluster_' num2str(nClusters) '_' name],...
            'modelFnm',['model_' sname]);
    save(['data/opt_' sname],'opts')
end

if opts.nClusters>1
    % need to learn dictionary
    Dict_patch(opts)
end
% A.2 parallel train N trees
if ~exist(['models/forest/' opts.modelFnm '_' num2str(ntree) '.mat'])
    do_local=0;
    if do_local
        %try;matlabpool;end;
        cd core
        for id=1:ntree;st3dTrain_p(opts,id);end
        cd ../
    else
        PP=pwd;
        %system(['./para/p_run.sh 1 1 ' num2str(ntree) ' "' PP '/para" "' PP '/core" "st3dTrain_p(''''../data/opt_' sname '''''," ");"'])
        for i=1:ntree
            if ~exist(['models/tree/' opts.modelFnm sprintf('_tree%03d.mat',i)],'file')
                system(['./para/p_run.sh 1 ' num2str(i) ' ' num2str(i) ' "' PP '/para" "' PP '/core" "st3dTrain_p(''''../data/opt_' sname '''''," ");"'])
            end
        end
        p_wait(['models/tree/' opts.modelFnm '_tree*'],30,ntree,300,1);
    end
    % A.3 form the forest
    cd core;st3dTrain(opts);cd ..
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% B. test boundary detection
% model III:
% models/forest/model_berk1_1_200_400_1_2_5_20.mat
load(['models/forest/' opts.modelFnm '_' num2str(ntree)])
tsz_h = (model.opts.tsz-1)/2;
tsz_step = 1;% number of frames in between 


did=2;
model.opts.did=did;
im_pre='im';
switch did
case 1
% berk
DD=D_BERK1;
model.opts.DD=D_BERK1;
case 2
% cmu
DD=D_CMU;
flo_pre = 'CMU_';
model.opts.DD=D_CMU;
end

fns = dir(DD);fns(1:2)=[];
st3d = cell(1,numel(fns));
im=[];
for i=1:numel(fns)
    im = uint8(U_fns2ims([DD fns(i).name '/' im_pre]));
    id = U_getTcen([DD fns(i).name '/'],did);
    model.opts.flo_name = [flo_pre fns(i).name];
    %try
        tmp_st = st3dDetect( im(:,:,:,id+(-tsz_h*tsz_step:tsz_step:tsz_h*tsz_step)), model );
        st3d{i} = 1-tmp_st(:,:,end);
    %end
end
save([num2str(did) 'pb_' sname],'st3d')

nn=['berk1_stof' num2str(opt_id) '/'];
mkdir(nn)
for i=1:numel(fns)
    try
        if tsz_step==1
             imwrite(stToEdges( 1-st3d{i}, 1 ),[nn 'st3d_' fns(i).name '.png'])
        else
             imwrite(stToEdges( 1-st3d{i}, 1 ),[nn 'st3d2_' fns(i).name '.png'])
        end
    end
end

%{
load data/gt_cmu
thresh = 0.1:0.1:0.9;
y=zeros(1,numel(gts));
cc=zeros(numel(gts),numel(thresh),4);
for id=1:numel(gts)
id
[y(id),cc(id,:,:)] = U_occ(st3d{id},gts(id),thresh);
end
save(['eval_' sname],'y','cc')
U_fmax({cc},1)
%}
