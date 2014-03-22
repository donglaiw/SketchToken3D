function st3dTrain(opts)
addpath(genpath('/data/vision/billf/stereo-vision/VisionLib/Donglai/Util/io'))
addpath(genpath('/data/vision/billf/stereo-vision/VisionLib/Piotr'))

dfs={'DD',[],'loadmat',[],'pratio',0,'tsz',0,'tstep',0,'num_pervol',0,'ntChns',2,...
    'nClusters',150, 'nTrees',25, 'radius',17, 'nPos',1000, 'nNeg',800,...
    'negDist',2, 'minCount',4, 'nCells',5, 'normRad',5, 'normConst',0.01, ...
    'nOrients',[4 4 0], 'sigmas',[0 1.5 5], 'chnsSmooth',2, 'fracFtrs',1, ...
    'seed',1, 'modelDir','models/', 'modelFnm','model', ...
    'clusterFnm','clusters.mat', 'bsdsDir','BSR/BSDS500/data/'};
opts = getPrmDflt(opts,dfs,1);

forestDir = [opts.modelDir '/forest/'];
forestFn = [forestDir opts.modelFnm];
if exist([forestFn '.mat'], 'file')
    load([forestFn '.mat']);
    return;
end


nTrees=opts.nTrees;
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

stream=RandStream('mrg32k3a','Seed',opts.seed);
% train nTrees random trees (can be trained with parfor if enough memory)
for i=1:nTrees
    st3dTrainTree( opts, stream, i );
end

    % accumulate trees and merge into final model
    treeFn = [opts.modelDir '/tree/' opts.modelFnm '_tree'];
    for i=1:nTrees
        t=load([treeFn int2str2(i,3) '.mat'],'tree');
        t=t.tree;
        if (i==1)
            trees=t(ones(1,nTrees));
        else
            trees(i)=t;
        end
    end
    nNodes=0;
    for i=1:nTrees
        nNodes=max(nNodes,size(trees(i).fids,1));
    end
    model.thrs=zeros(nNodes,nTrees,'single');
    Z=zeros(nNodes,nTrees,'uint32');
    model.fids=Z;
    model.child=Z;
    model.count=Z;
    model.depth=Z;
    model.distr=zeros(nNodes,size(trees(1).distr,2),nTrees,'single');
    for i=1:nTrees, tree=trees(i); nNodes1=size(tree.fids,1);
        model.fids(1:nNodes1,i) = tree.fids;
        model.thrs(1:nNodes1,i) = tree.thrs;
        model.child(1:nNodes1,i) = tree.child;
        model.distr(1:nNodes1,:,i) = tree.distr;
        model.count(1:nNodes1,i) = tree.count;
        model.depth(1:nNodes1,i) = tree.depth;
    end
    model.distr = permute(model.distr, [2 1 3]);
    
    %clusters=load(opts.clusterFnm);
    %clusters=clusters.clusters;
    
    model.opts = opts;
    %model.clusters=clusters.clusters;
    if ~exist(forestDir,'dir')
        mkdir(forestDir);
    end
    save([forestFn '.mat'], 'model', '-v7.3');
end

function st3dTrainTree( opts, stream, treeInd )

streamOrig = RandStream.getGlobalStream();
set(stream,'Substream',treeInd);
RandStream.setGlobalStream( stream );

treeDir = [opts.modelDir '/tree/'];
treeFn = [treeDir opts.modelFnm '_tree'];
if exist([treeFn int2str2(treeInd,3) '.mat'],'file')
    return;
end
fprintf('\n-------------------------------------------\n');
fprintf('Training tree %d of %d\n',treeInd,opts.nTrees);
tStart=clock;

% get data
load(opts.loadmat)
if ~exist('Is','var')
    Is = [];
end
psz_h = opts.radius;
psz = 2*psz_h+1;
tstep = opts.tstep;
tsz = opts.tsz;
len = cumsum([0 arrayfun(@(x) floor((size(gts{x},3)-tsz+1)/tstep),1:numel(gts))]);
mat_x = cell(len(end),1);
mat_x2 = cell(len(end),1);
mat_y = cell(len(end),1);

DD = opts.DD;
fns=[];
num_v= numel(Is)
if isempty(Is)
    fns = dir(DD);
    fns(1:2)=[];
    num_v= numel(fns);
end

for i=1:num_v
    fprintf('   Video %d / %d\n',i,num_v);
    tmp_x = cell(1,len(i+1)-len(i));
    tmp_x2 = cell(1,len(i+1)-len(i));
    tmp_y = cell(1,len(i+1)-len(i));
    tmp_fn = [];
    if isempty(Is) 
        tmp_fn = U_getims([DD fns(i).name '/']);
    end
    sz = size(gts{i});    
    tmp_gts = single(gts{i});
    
    
    ind1 =[]; ind2=[]; tmp_im=[];
    p_ind = reshape(bsxfun(@plus,(-psz_h:psz_h),sz(1)*(-psz_h:psz_h)'),[],1);
    for j = 1:numel(tmp_x)
    %parfor j = 1:numel(tmp_x)
        tcen = (j-1)*tstep+(1+tsz)/2;
        tmp_dist = U_addnan(single(bwdist(tmp_gts(:,:,tcen)>0)),psz_h);
        
        % sample pos:
        ind1 = find(tmp_dist<2)';
        tmp_ind1 = randsample(ind1,min(floor(opts.pratio*numel(ind1)),opts.num_pervol));
        % sample neg:
        ind2 = find(tmp_dist>psz)';
        tmp_ind2 = randsample(ind2,opts.num_pervol);
        
        
        num_p = numel(tmp_ind1)+numel(tmp_ind2);
        tmp_x{j} = zeros(psz,psz,num_p,opts.nChns,tsz,'single');
        cc = 1;
        % 2d edge
        for k= (j-1)*tstep+(1:tsz)
            if isempty(Is)
                tmp_im = imread([DD fns(i).name '/' tmp_fn(k).name]);
            else
                tmp_im = Is{i};
            end
            %tmp_im = imPad(tmp_im,psz_h,'symmetric');
            chns = reshape(stChns(tmp_im,opts),prod(sz(1:2)),[]);
            tmp_x{j}(:,:,:,:,cc) = ...
                reshape(chns(reshape(bsxfun(@plus,[tmp_ind1,tmp_ind2],p_ind),1,[]),:),psz,psz,num_p,[]);
            cc= cc+1;
        end
        % 35*35*14*tsz*num
        tmp_x{j} = permute(tmp_x{j},[1 2 4 5 3]);
        % 3d self-similarity: texture + flow
        tmp_x2{j} = st3dComputeSimFtrs(tmp_x{j},opts);
        tmp_x{j} = reshape(tmp_x{j},[],num_p)';
        tmp_y{j} = [ones(numel(tmp_ind1),1,'uint8'); 2*ones(numel(tmp_ind2),1,'uint8')];
        %tmp_y{j} = logical([ones(numel(tmp_ind1),1); zeros(numel(tmp_ind2),1)]);
    end
    
    mat_x(len(i)+1:len(i+1)) = tmp_x;
    mat_x2(len(i)+1:len(i+1)) = tmp_x2;
    mat_y(len(i)+1:len(i+1)) = tmp_y;
end

% train sketch token classifier (random decision tree)
%save -v7.3 ho mat_x mat_x2 mat_y
tree=forestTrain([cell2mat(mat_x) cell2mat(mat_x2)],cell2mat(mat_y),'maxDepth',999);
%tree.fids(tree.child>0) = fids(tree.fids(tree.child>0)+1)-1;
tree=pruneTree(tree,opts.minCount); %#ok<NASGU>
if ~exist(treeDir,'dir')
    mkdir(treeDir);
end
save([treeFn int2str2(treeInd,3) '.mat'],'tree');
e=etime(clock,tStart);
fprintf('Training of tree %d complete (time=%.1fs).\n',treeInd,e);
RandStream.setGlobalStream( streamOrig );

end



function tree = pruneTree( tree, minCount )
% Prune all nodes whose count is less than minCount.

% mark all internal nodes if either child has count<=minCount
mark = [0; tree.count<=minCount];
mark = mark(tree.child+1) | mark(tree.child+2);

% list of nodes to be discarded / kept
disc=tree.child(mark);
disc=[disc; disc+1];
n=length(tree.fids);
keep=1:n;
keep(disc)=[];

% prune tree
tree.fids=tree.fids(keep);
tree.thrs=tree.thrs(keep);
tree.child=tree.child(keep);
tree.distr=tree.distr(keep,:);
tree.count=tree.count(keep);
tree.depth=tree.depth(keep);
assert(all(tree.count>minCount))

% re-index children
route=zeros(1,n);
route(keep)=1:length(keep);
tree.child(tree.child>0) = route(tree.child(tree.child>0));
end
