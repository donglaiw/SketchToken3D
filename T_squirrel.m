param_init
id1 = 19;
id2 = 20;
%{
addpath([D_VLIB 'Util/flow'])
fns = dir([D_CMU 'clips']);
fns(1:2)=[];
tsz = 5;
tsz_h = (tsz-1)/2;
tsz_step = 1;% number of frames in between 
    opts.tsz = tsz;
    im = uint8(U_fns2ims([D_CMU 'clips/' fns(id1).name '/img_']));
    fn  = dir([D_CMU 'clips/' fns(id1).name '/ground_truth*']);
    id = str2double(fn.name(find(fn.name=='_',1,'last')+1:end-4))+1;
    I0 = cell(1,tsz);for i=1:tsz;I0{i}=im(:,:,:,id-(tsz_h+1)*tsz_step+i*tsz_step);end
    of = U_getOF(I0,opts);
    for i=1:4;subplot(2,2,i),imagesc(flowToColor(of{i}));end
%}
ntree = 10;
tid = 1;
switch tid
case 1
    % cmu train: 2-class
    did= 2;
    name = 'cmu.mat';
    patch_id = 2;
    D_name = [D_CMU 'clips/'];
    num_pervol = 2000;
    num_pervol_n = 4000;
    feat_id = 4;opt_id=8;
    %feat_id = 5;opt_id=7;
    nClusters = 1;
    tscale = 1;
    ids = id1;
end
sname = sprintf([name(1:end-4) '_%d_%d_%d_%d_%d_%d'],nClusters,num_pervol,num_pervol_n,numel(tscale),patch_id,feat_id);
if exist(['data/opt_' sname],'file')
    load(['data/opt_' sname])
    ntree = opts.nTrees;
else
opts=struct('DD',D_name,...
            'did',did,...
            'loadmat',[D_ST3D 'data/gt_' name],...
            'im_ids',ids,...
            'patch_id',patch_id,...
            'feat_id',feat_id,...
            'radius',17,...
            'pratio',0.3,...
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

% A.2 parallel train N trees
do_local=1;
if do_local
    %try;matlabpool;end;
    cd core
    parfor id=1:ntree;st3dTrain_p(opts,id);end
    cd ../
else
    PP=pwd;
    system(['./para/p_run.sh 1 1 ' num2str(ntree) ' "' PP '/para" "' PP '/core" "st3dTrain_p(' num2str(opt_id) '," ");"'])
end
% A.3 form the forest
cd core;st3dTrain(opts);cd ..
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% B. test boundary detection
load(['models/forest/' opts.modelFnm '_' num2str(ntree)])

fns = dir([D_CMU 'clips']);
fns(1:2)=[];
tsz = 5;
tsz_h = (tsz-1)/2;
tsz_step = 1;% number of frames in between 
    im = uint8(U_fns2ims([D_CMU 'clips/' fns(id2).name '/img_']));
    id = U_getTcen([D_CMU 'clips/' fns(id2).name],2);
    %try
        tmp_st = st3dDetect( im(:,:,:,id+(-tsz_h*tsz_step:tsz_step:tsz_h*tsz_step)), model );
        st3d = 1-tmp_st(:,:,end);
    %end

for i=1:numel(fns)
    try
        if tsz_step==1
             imwrite(stToEdges( 1-st3d{i}, 1 ),['st3d_' fns(i).name '.png'])
        else
             imwrite(stToEdges( 1-st3d{i}, 1 ),['st3d2_' fns(i).name '.png'])
        end
    end
end
