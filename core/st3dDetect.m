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
    chns = zeros([2*opts.radius+sizeOrig(1:2) opts.nChns opts.tsz],'single');
    for i=1:opts.tsz
        I = imPad(Is(:,:,:,i),opts.radius,'symmetric');
        chns(:,:,:,i) = stChns( I, opts );
    end
    sz = size(chns);
    [cids1,cids2] = computeCids3d(sz,opts);
    
    if opts.nCells
        chnsSs = chns;
        for i=1:opts.tsz
            chnsSs(:,:,:,i) = convBox(chns(:,:,:,i),opts.cellRad);
        end
        if opts.ntChns>1
            chnsSs = squeeze(sum(reshape(chnsSs(:,:,:,1:opts.ntChns*opts.tstep),[sz(1:end-1) 2 opts.ntChns]),numel(sz)));
        end
    else
        chnsSs = [];
    end

    % run forest on image
    nChnFtrs=opts.patchSiz*opts.patchSiz*opts.nChns*opts.tsz;
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

end

% for the ease of self-similarity,
% we make the m*n*t video volume -> m*n*chn*t -> m*(n*t)*chn

function [cids1,cids2] = computeCids3d( siz, opts )
    % construct cids lookup for standard features
    radius=opts.radius;
    s=opts.patchSiz;
    nChns=opts.nChns;
    tsz=opts.tsz;
    
    
    ht=siz(1);
    wd=siz(2);
    assert(siz(3)==nChns);
    assert(numel(siz)==3 || siz(4)==tsz);
    
    nChnFtrs=s*s*nChns;
    fids=uint32(0:nChnFtrs-1);    
    rs=mod(fids,s);
    fids=(fids-rs)/s;    
    cs=mod(fids,s);
    ch=(fids-cs)/s;
    cids = rs + cs*ht + ch*ht*wd;
    
    % temporal jumps    
    cids = reshape(bsxfun(@plus, cids', uint32((0:tsz-1)*ht*wd*nChns)),1,[]);
    
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
    ind = bsxfun(@plus,ind,ht*wd*nChns*tt);    
    
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
