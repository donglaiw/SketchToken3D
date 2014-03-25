function feat = st3dGetFeature(tmp_im,tmp_ind,opts)

sz = size(tmp_im{1});
psz_h = opts.radius;
psz = 2*psz_h+1;
tsz = opts.tsz;
tsz_h = floor((tsz-1)/2);
num_p = numel(tmp_ind);
p_ind = reshape(bsxfun(@plus,(-psz_h:psz_h),sz(1)*(-psz_h:psz_h)'),[],1);
% assume color image
feat = [];
switch opts.feat_id
    case {0,1,2,3,4}
        tmp_x = zeros(psz,psz,num_p,opts.nChns,tsz,'single');
        % gradient + self-similarity
        for cc = 1:numel(tmp_im)
            chns = reshape(stChns(tmp_im{cc},opts),prod(sz(1:2)),[]);
            tmp_x(:,:,:,:,cc) = ...
                reshape(chns(reshape(bsxfun(@plus,tmp_ind,p_ind),1,[]),:),psz,psz,num_p,[]);
        end
        % 35*35*14*tsz*num
        tmp_x = permute(tmp_x,[1 2 4 5 3]);
        if opts.feat_id==0
            feat = reshape(tmp_x,[],num_p)';
        else
            % 3d self-similarity: texture + flow
            if opts.feat_id<=2
                tmp_x2 = st3dComputeSimFtrs(tmp_x,opts);
                if opts.feat_id==1
                    feat = tmp_x2;
                else
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
            elseif opts.feat_id==4
                % matching cost for the center frame
            end
        end
end

