function opts= st3dMakeOpts(opts)

dfs={'DD',[],'loadmat',[],'pratio',0,'tsz',0,'tstep',0,'num_pervol',0,'num_pervol_n',0,'feat_id',0,'patch_id',0,'ntChns',2,'tscale',1,'clusters',[],...
    'nClusters',150, 'nTrees',25, 'radius',17, 'nPos',1000, 'nNeg',800,...
    'negDist',2, 'minCount',4, 'nCells',5, 'normRad',5, 'normConst',0.01, ...
    'nOrients',[4 4 0], 'sigmas',[0 1.5 5], 'chnsSmooth',2, 'fracFtrs',1, ...
    'seed',1, 'modelDir','../models/', 'modelFnm','model', ...
    'clusterFnm','clusters.mat', 'bsdsDir','BSR/BSDS500/data/'};
opts = getPrmDflt(opts,dfs,1);


nCells=opts.nCells;
nChns = size(stChns(ones(2,2,3),opts),3);
opts.nChns=nChns;
opts.patchSiz=2*opts.radius + 1;
psz = opts.patchSiz;

%opts.nChnFtrs = psz*psz*nChns;
%opts.nSimFtrs = (nCells*nCells)*(nCells*nCells-1)/2*nChns;
%opts.nTotFtrs = opts.nChnFtrs + opts.nSimFtrs;

opts.cellRad = round(psz/nCells/2);
tmp=opts.cellRad*2+1;
opts.cellStep = tmp-ceil((nCells*tmp-psz)/(nCells-1));


