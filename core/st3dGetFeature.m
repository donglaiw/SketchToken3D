function feat = st3dGetFeature(tmp_im,tmp_ind,opts)

sz = size(tmp_im{1});
psz_h = opts.radius;
psz = 2*psz_h+1;
tsz = opts.tsz;
tsz_h = floor((tsz-1)/2);
num_p = numel(tmp_ind);
if num_p==0
    num_p = prod(sz(1:2));
    psz=1;
end
p_ind = reshape(bsxfun(@plus,(-psz_h:psz_h),sz(1)*(-psz_h:psz_h)'),[],1);
% assume color image
feat = [];
switch opts.feat_id
    case {-1,0,1,2,3,4,5}
        tmp_x = zeros(psz,psz,num_p,opts.nChns,tsz,'single');
        % gradient + self-similarity
        for cc = 1:numel(tmp_im)
            chns = reshape(stChns(uint8(tmp_im{cc}(:,:,1:3)),opts),prod(sz(1:2)),[]);
            if isempty(tmp_ind)
                tmp_x(:,:,:,:,cc) = ...
                    reshape(chns,psz,psz,num_p,[]);
            else
                tmp_x(:,:,:,:,cc) = ...
                    reshape(chns(reshape(bsxfun(@plus,tmp_ind,p_ind),1,[]),:),psz,psz,num_p,[]);
            end
        end
        % 35*35*14*tsz*num
        tmp_x = permute(tmp_x,[1 2 4 5 3]);
        if opts.feat_id==0
            feat = reshape(tmp_x,[],num_p)';
        else
            % 3d self-similarity: texture + flow
            if opts.feat_id<=2
                tmp_x2 = st3dComputeSimFtrs(tmp_x,opts);
                switch opts.feat_id
                case -1
                    feat = [reshape(tmp_x(:,:,:,(1+tsz)/2,:),[],num_p)' tmp_x2];
                case 1
                    feat = tmp_x2;
                case 2
                    feat = [reshape(tmp_x,[],num_p)' tmp_x2];
                end
            elseif opts.feat_id==3
                % direct matching cost
                chns = bsxfun(@minus, tmp_x(:,:,:,setdiff(1:tsz,tsz_h+1),:), tmp_x(:,:,:,tsz_h+1,:));
                chns=reshape(chns,psz,psz,[]);
                chns=convBox(chns,opts.cellRad);    
                n=opts.nCells;
                inds = ((1:n)-(n+1)/2)*opts.cellStep+opts.radius+1;    
                feat=reshape(chns(inds,inds,:),n*n*opts.nChns*(tsz-1),[])';
            elseif sum([4,5]==opts.feat_id)>0
                % of boundary
                % max-pool motion
                of = cat(3,tmp_im{1:end-1});
                num_c = size(tmp_im{1},3);
                of_x = of(:,:,num_c-1:num_c:end);
                of_y = of(:,:,num_c:num_c:end);
                chns = reshape(stChns(cat(3,U_pool(of_x,opts.pool_id),U_pool(of_y,opts.pool_id)),opts),prod(sz(1:2)),[]);
            if isempty(tmp_ind)
                feat_of = permute(reshape(chns,psz^2,num_p,[]),[1 3 2]);
            else
                feat_of = permute(reshape(chns(reshape(bsxfun(@plus,tmp_ind,p_ind),1,[]),:),psz^2,num_p,[]),[1 3 2]);
            end
                if opts.feat_id==4
                    feat=[reshape(tmp_x,[],num_p)' reshape(feat_of,[],num_p)'];
                else
                    feat=[reshape(tmp_x,[],num_p)' reshape(feat_of,[],num_p)' st3dComputeSimFtrs(tmp_x,opts)];
                end
            end
        end
    case {6,7,8,9}
        % 2D st + of
        num_c = size(tmp_im{1},3);

        st = cat(3,tmp_im{1:opts.drf});
        st = st(:,:,1:num_c:end);
        switch opts.feat_id
        case {6,7,9}
            chns = reshape(st,prod(sz(1:2)),[]);
        case {8}
            chns = reshape(stChns(st,opts),prod(sz(1:2)),[]);
        end

        if isempty(tmp_ind)
            feat_st = chns';
        else
            feat_st = permute(reshape(chns(reshape(bsxfun(@plus,tmp_ind,p_ind),1,[]),:),psz^2,num_p,[]),[1 3 2]);
        end

        if sum([6,9] ==opts.feat_id)
            of = cat(3,tmp_im{1:end-1});
            of_y = of(:,:,num_c:num_c:end);
            switch opts.of_fn
            case {'of_idm','of_idm3'}
                of_x = of(:,:,num_c-1:num_c:end);
                vol = cat(3,U_pool(of_x,opts.pool_id),U_pool(of_y,opts.pool_id));
            case 'of_idm2'
                vol = U_pool(of_y,opts.pool_id);
            end
            if sum([6] ==opts.feat_id)
                chns_of = reshape(stChns(vol,opts),prod(sz(1:2)),[]);
            else
                chns_of = reshape(vol,prod(sz(1:2)),[]);
            end

            if isempty(tmp_ind)
                feat_of = permute(reshape(chns_of,psz^2,num_p,[]),[1 3 2]);
            else
                feat_of = permute(reshape(chns_of(reshape(bsxfun(@plus,tmp_ind,p_ind),1,[]),:),psz^2,num_p,[]),[1 3 2]);
            end
            feat=[reshape(feat_st,[],num_p)' reshape(feat_of,[],num_p)'];
        else 
            feat=[reshape(feat_st,[],num_p)'];
        end
end

