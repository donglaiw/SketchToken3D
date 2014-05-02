function S = st3dDetect( Is, model, stride, rescale_back )
% Detect sketch tokens in image.
%
% USAGE
%  S = stDetect( I, model, [stride] )
%
% INPUTS
%  I            - [h x w x 3] color input image
%  model        - sketch token model trained with stTrain
%  stride       - [2] stride at which to compute sketch tokens
%  rescale_back - [true] rescale after running stride
%
% OUTPUTS
%  S          - [h x w x (nTokens+1)] sketch token probability maps
%
% EXAMPLE
%
% See also stTrain, stChns
%
% Sketch Token Toolbox     V0.95
% Copyright 2013 Joseph Lim [lim@csail.mit.edu]
% Please email me if you find bugs, or have suggestions or questions!
% Licensed under the Simplified BSD License [see bsd.txt]

    if nargin<3
        stride=2;
    end
    if nargin<4
        rescale_back = true;
    end

    % compute features
    sizeOrig=size(Is);
    opts=model.opts;
    %opts.inputColorChannel = 'luv';
    %opts.inputColorChannel = 'rgb';

    I0 = cell(1,opts.tsz);
    tmp_dist2 = [];
    if sum([6 7 8 9]==opts.feat_id)>0
        Is = U_getST([],opts);
        tmp_dist2 = bwdist(max(cat(3,Is{:}),[],3)>opts.nbd_thres);
        Is = cat(4,Is{:});
    end
    for i=1:opts.tsz
        I0{i} = imPad(Is(:,:,:,i),opts.radius,'symmetric');
    end

    feat_oid = opts.feat_id;
    if sum([-1:3]==opts.feat_id)>0
        % only the 2D image feature
        opts.feat_id = 0;
    elseif sum([4 5 6 9]==opts.feat_id)>0
        % add channels
        of = U_getOF(I0,opts);
        for i=1:opts.tsz
            of{i} = imPad(of{i},opts.radius,'symmetric');
        end
    
        if sum([4 5]==opts.feat_id)>0
            opts.feat_id = 4;
        end

        for i=1:opts.tsz
            I0{i} = cat(3,I0{i},of{i});
        end
    end
    sz = size(I0{1});
   
    % all feature without self-similarity

    chns = st3dGetFeature(I0,[],opts);
    chns = reshape(chns,sz(1),sz(2),[]);
    sz = [sz(1:2) size(chns,3)];

    if opts.nCells && sum([4 6 7 8 9]==feat_oid)==0
        chnsSs = reshape(chns(:,:,1:opts.nChns*opts.tsz),[sz(1:2) opts.nChns opts.tsz]);
        for i=1:opts.tsz
            chnsSs(:,:,:,i) = convBox(chns(:,:,(i-1)*opts.nChns+(1:opts.nChns)),opts.cellRad);
        end
        if opts.ntChns>1
            chnsSs = squeeze(sum(reshape(chnsSs(:,:,:,1:opts.ntChns*opts.tstep),[sz(1:end-1) opts.nChns opts.tstep opts.ntChns]),numel(size(chnsSs))));
        end
    else
        chnsSs = [];
    end

    opts.feat_id = feat_oid;
    if feat_oid ==-1
        chns = chns(:,:,((opts.tsz+1)/2-1)*opts.nChns+(1:opts.nChns));
        sz(3) = size(chns,3);
    end

    [cids1,cids2] = computeCids3d(sz,opts);    
    % run forest on image
    nChnFtrs=opts.patchSiz*opts.patchSiz*sz(3);
    %save db2
    S = stDetectMex( chns, chnsSs, model.thrs, model.fids, model.child, ...
      model.distr, cids1, cids2, stride, opts.radius, nChnFtrs );

    % finalize sketch token probability maps
    S = permute(S,[2 3 1]) * (1/opts.nTrees);
    if ~rescale_back
        %keyboard;
    else    
        S = imResample( S, stride );
        cr=size(S); cr=cr(1:2)-sizeOrig(1:2);
        if any(cr)
            S=S(1:end-cr(1),1:end-cr(2),:);
        end
    end

    if sum([6 7 8 9]==opts.feat_id)>0
        % apply mask
        pos_dis = 3;
        tmp_S = S(:,:,end);
        tmp_S(tmp_dist2>=pos_dis) = 1;
        S(:,:,end) = tmp_S;
        tmp_S = ((1-S(:,:,end))./sum(S(:,:,1:end-1),3));
        S(:,:,1:end-1) = bsxfun(@times,S(:,:,1:end-1),tmp_S);
    end
end

% for the ease of self-similarity,
% we make the m*n*t video volume -> m*n*chn*t -> m*(n*t)*chn

function [cids1,cids2] = computeCids3d( siz, opts )
    % construct cids lookup for standard features
    radius=opts.radius;
    s=opts.patchSiz;
    nChns=siz(3);
    tsz=opts.tsz;
    
    
    ht=siz(1);
    wd=siz(2);
    assert(numel(siz)==3 || siz(4)==tsz);
    
    nChnFtrs=s*s*nChns;
    fids=uint32(0:nChnFtrs-1);    
    rs=mod(fids,s);
    fids=(fids-rs)/s;    
    cs=mod(fids,s);
    ch=(fids-cs)/s;
    cids = rs + cs*ht + ch*ht*wd;
    
    % temporal jumps    
    %cids = reshape(bsxfun(@plus, cids', uint32((0:tsz-1)*ht*wd*nChns)),1,[]);
   
    if sum([4 6 7 8 9]==opts.feat_id) 
        cids1 = cids;
        cids2 = cids;
        return
    elseif opts.feat_id==5
        nChns=14;
    end
    % construct cids1/cids2 lookup for self-similarity features
    n=opts.nCells;
    m=opts.cellStep;    
    ntf = floor(tsz/opts.ntChns);
    n1=(n-1)/2;
    ind1 = []; ind2 = [];
    k=0;
    for i=1:n*n*ntf-1,
        k1=n*n*ntf-i;
        ind1(k+1:k+k1)=(0:k1-1);
        k=k+k1;
    end
    k=0;
    for i=1:n*n*ntf-1,
        k1=n*n*ntf-i;
        ind2(k+1:k+k1)=(0:k1-1)+i;
        k=k+k1;
    end
            
    ind = reshape(bsxfun(@plus,(radius + (-n1:n1)*m)',ht*(radius + (-n1:n1)*m)),[],1);
    tt= 0:numel(0:opts.ntChns:(opts.tsz-opts.ntChns))-1;
    ind = reshape(bsxfun(@plus,ind,ht*wd*nChns*tt),1,[]);
    
    assert(max(ind2)+1==numel(ind));    
    cids1 = reshape(ind(ind1+1),[],1);
    cids2 = reshape(ind(ind2+1),[],1);
    
    % one channel at a time
    cids1 = reshape(bsxfun(@plus,cids1,ht*wd*(0:nChns-1)),1,[]);    
    cids2 = reshape(bsxfun(@plus,cids2,ht*wd*(0:nChns-1)),1,[]);    

    % combine cids for standard and self-similarity features
    cids1=[cids cids1];
    cids2=uint32([zeros(1,numel(cids)) cids2]);
end
