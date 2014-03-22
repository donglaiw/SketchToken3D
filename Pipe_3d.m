addpath('para')
addpath('core')
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% A. Train 2D boundary detector
% A.1 opts
if exist('data/opt_3d.mat','file')
    load data/opt_3d.mat
    ntree = opts.nTrees;
else
    ntree = 3;
opts=struct('DD','/data/vision/billf/manifold-learning/Data/Seg/Segtrack/',...
            'loadmat','/data/vision/billf/manifold-learning/DL/SketchToken3D/data/segtrack',...
            'radius',17,...
            'pratio',0.3,...
            'tsz',  5,...
            'tstep', 2,...
            'num_pervol',100,...
            'ntChns',1,...
            'nClusters',2,...
            'nTrees',ntree,...
            'modelFnm','model3D');
    save data/opt_3d opts 
end
% A.2 parallel train N trees
do_local=0;
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
DD='/data/vision/billf/stereo-vision/';
fns = dir([DD 'Occ/CMU/clips']);
fns(1:2)=[];
tsz_h = (opts.tsz-1)/2;
tsz_step = 1;% number of frames in between 
st3d = cell(1,numel(fns));
parfor i=1:numel(fns)
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
