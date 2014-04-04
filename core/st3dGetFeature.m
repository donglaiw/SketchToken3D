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
                of_x = of(:,:,4:5:end);
                of_y = of(:,:,5:5:end);
                sz = size(of_x);
                [~,of_idx]=max(abs(of_x),[],3);
                [~,of_idy]=max(abs(of_y),[],3);
                tmp_ofx = zeros(sz(1:2),'single');
                tmp_ofy = zeros(sz(1:2),'single');
                for i=1:size(of_x,3)
                    tmp_of = of_x(:,:,i);
                    tmp_ofx(of_idx==i) = tmp_of(of_idx==i);
                    tmp_of = of_y(:,:,i);
                    tmp_ofy(of_idy==i) = tmp_of(of_idy==i);
                end
                chns = reshape(stChns(cat(3,tmp_ofx,tmp_ofy),opts),prod(sz(1:2)),[]);
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
end

