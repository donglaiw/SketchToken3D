addpath('para')
addpath('core')
param_init
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% A. Train 2D boundary detector
% A.1 opts
tid = 1;
ntree = 5;
switch tid
case 1
    % segtrack train: 2-class
    name = 'segt.mat';
    patch_id = 1;
    feat_id = 2;
    D_name = D_STRACK;
    num_pervol = 200;
    num_pervol_n = 160;
    nClusters = 2;
case 2
    % berk train: 101-class
    name = 'berk1.mat';
    patch_id = 4;
    feat_id = 2;
    D_name = D_BERK1;
    num_pervol = 200;
    num_pervol_n = 160;
    nClusters = 100;
end
if exist(['data/opt_' opt_name],'file')
    load(['data/opt_' opt_name])
    ntree = opts.nTrees;
else
opts=struct('DD',D_name,...
            'loadmat',[D_ST3D 'data/gt_' name],...
            'patch_id',patch_id,...
            'feat_id',feat_id,...
            'radius',17,...
            'pratio',0.3,...
            'tsz',  5,...
            'tstep', 2,...
            'num_pervol',num_pervol,...
            'num_pervol_n',num_pervol_n,...
            'ntChns',2,...
            'nClusters',nClusters,...
            'nTrees',ntree,...
            'modelFnm',['model_' name]);
    save(['data/' opt_name],'opts')
end
% A.2 parallel train N trees
do_local=1;
if do_local
    try;matlabpool;end;
    cd core
    parfor id=1:ntree;st3dTrain_p(2,id);end
    cd ../
else
    PP=pwd;
    system(['./para/p_run.sh 1 1 ' num2str(ntree) ' "' PP '/para" "' PP '/core" "st3dTrain_p(2," ");"'])
end
% A.3 form the forest
st3dTrain(opts);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% B. test boundary detection
load models/forest/model3D
DD='/data/vision/billf/stereo-vision/Data/';
fns = dir([DD 'Occ/CMU/clips']);
fns(1:2)=[];
tsz_h = (model.opts.tsz-1)/2;
tsz_step = 1;% number of frames in between 
st3d = cell(1,numel(fns));
parfor i=1:1%numel(fns)
    im = uint8(U_fns2ims([DD 'Occ/CMU/clips/' fns(i).name '/img_']));
    fn  = dir([DD 'Occ/CMU/clips/' fns(i).name '/ground_truth*']);
    id = str2double(fn.name(find(fn.name=='_',1,'last')+1:end-4))+1;
    try
        tmp_st = st3dDetect( im(:,:,:,id+(-tsz_h*tsz_step:tsz_step:tsz_h*tsz_step)), model );
        st3d{i} =tmp_st(:,:,1);
    end
end

for i=1:numel(fns)
    try
    imwrite(stToEdges( 1-st3d{i}, 1 ),['st3d2_' fns(i).name '.png'])
    end
end
