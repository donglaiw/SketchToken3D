addpath('para')
addpath('core')
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% A. Train 2D boundary detector
% A.1 opts
if exist('data/opt_2d.mat','file')
    load data/opt_2d.mat
    ntree = opts.nTrees;
else
    ntree = 3;
opts=struct('DD','',...
            'loadmat','/data/vision/billf/manifold-learning/DL/SketchToken3D/data/bsd2d',...
            'radius',17,...
            'pratio',0.3,...
            'tsz',  1,...
            'tstep', 1,...
            'num_pervol',100,...
            'ntChns',1,...
            'nClusters',2,...
            'nTrees',ntree,...
            'modelFnm','model2D');
    save data/opt_2d opts 
end
% A.2 parallel train N trees
PP=pwd;
system(['./para/p_run.sh 1 1 ' num2str(ntree) ' "' PP '/para" "' PP '/core" "st3dTrain_p(1," ");"'])

% A.3 form the forest
st3dTrain(opts);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% B. test boundary detection
load models/forest/model2D
model.opts.nChnFtrs = (model.opts.patchSiz^2)*model.opts.nChns;
im =imread('data/3063.jpg');
tmp_st = st3dDetect( im, model );
imagesc(tmp_st(:,:,1))
