function ftrs = st3dComputeSimFtrs( mat_x, opts )
% Compute self-similarity features.
    n=opts.nCells;
    if(n==0),
        ftrs=[];
        return;
    end
    
    
    nChns=opts.nChns;
    
    m=size(mat_x,5);
    nt=size(mat_x,4);
    ntf = floor(nt/opts.ntChns);
    
    st_chns = zeros([n*n,ntf,nChns,m],'single');
    cc = 1;
    for i=1:opts.ntChns:(nt-opts.ntChns+1)
        tmp_chns = zeros(n*n,nChns,m,'single');
        for j= i:(i+opts.ntChns-1)
            chns= squeeze(mat_x(:,:,:,j,:));
            m=size(chns,4);    
            inds = ((1:n)-(n+1)/2)*opts.cellStep+opts.radius+1;    
            chns=reshape(chns,opts.patchSiz,opts.patchSiz,nChns*m);        
            chns=convBox(chns,opts.cellRad);    
            chns=reshape(chns(inds,inds,:),n*n,nChns,m);
            tmp_chns = tmp_chns+ chns;
        end
        st_chns(:,cc,:,:) = tmp_chns;
        cc = cc + 1;
    end
            
    st_chns = reshape(st_chns,n*n*ntf,nChns*m);
    n,ntf  
    n_combo = (n*n*ntf*(n*n*ntf-1)/2);
    ftrs=zeros(n_combo,nChns*m,'single');
    %{
    parfor i=1:m
        ftrs(:,i) = pdist(st_chns(:,:,i),'cityblock')';
    end
    %}
    k = 0;
    for i=1:(n*n*ntf)
        k1=(n*n*ntf)-i;
        ftrs(k+1:k+k1,:)=st_chns(1:end-i,:)-st_chns(i+1:end,:);
        k=k+k1;
    end
    ftrs = reshape(ftrs,[],m)';    
    % % For m=1, the above should be identical to the following:
    % [cids1,cids2]=computeCids(size(chns),opts); % see stDetect.m
    % chns=convBox(chns,opts.cellRad); k=opts.nChnFtrs;
    % cids1=cids1(k+1:end)-k+1; cids2=cids2(k+1:end)-k+1;
    % ftrs=chns(cids1)-chns(cids2);
end
