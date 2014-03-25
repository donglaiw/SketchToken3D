function st3dTrain_p(opt_id,id)
switch opt_id
case 1
    % 2d boundary
    load ../data/opt_2d opts 
case 2
    % i3d boundary
    load ../data/opt_3d opts 
case 3
    % i3d boundary
    load ../data/opt_berk1 opts 
end

addpath('../');param_init;
addpath(genpath([D_VLIB 'Util/io']))
addpath(genpath([D_VLIB '../Piotr']))

opts= st3dMakeOpts(opts);
nTrees=opts.nTrees;

stream=RandStream('mrg32k3a','Seed',opts.seed);

% train nTrees random trees (can be trained with parfor if enough memory)
st3dTrainTree( opts, stream, id );
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

[mat_x,mat_y] = st3dGetPatch(opts);
% train sketch token classifier (random decision tree)
%save -v7.3 ho mat_x mat_x2 mat_y
tree=forestTrain(mat_x,mat_y,'maxDepth',999);
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
