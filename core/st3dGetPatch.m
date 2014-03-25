function [mat_x,mat_y] = st3dGetPatch(opts)
% get data
load(opts.loadmat)

psz_h = opts.radius;
psz = 2*psz_h+1;

switch opts.patch_id
    case 0
        % 2d boundary patches: 1 gts, 1 Is
        num_v= numel(Is)
        for i=1:num_v
            fprintf('   Video %d / %d\n',i,num_v);
            sz = size(gts{i});
            tmp_gts = single(gts{i});
            tcen = 1;
            tmp_dist = U_addnan(single(bwdist(tmp_gts(:,:,tcen)>0)),psz_h);
            % sample pos:
            ind1 = find(tmp_dist<2)';
            tmp_ind1 = randsample(ind1,min(floor(opts.pratio*numel(ind1)),opts.num_pervol));
            % sample neg:
            ind2 = find(tmp_dist>psz)';
            tmp_ind2 = randsample(ind2,opts.num_pervol);
            mat_x{i} = st3dGetFeature(Is(i),[tmp_ind1 tmp_ind2],opts);
            mat_y{i} = [ones(numel(tmp_ind1),1,'uint8'); 2*ones(numel(tmp_ind2),1,'uint8')];
        end
    case 1
        % 3d boundary patches: n gts, n Is (labeled video)
        tstep = opts.tstep;
        tsz = opts.tsz;
        len = cumsum([0 arrayfun(@(x) floor((size(gts{x},3)-tsz+1)/tstep),1:numel(gts))]);
        mat_x = cell(len(end),1);
        mat_y = cell(len(end),1);
        DD = opts.DD;
        fns = dir(DD);
        fns(1:2)=[];
        num_v= numel(fns);
        for i=1:num_v
            fprintf('   Video %d / %d\n',i,num_v);
            tmp_x = cell(1,len(i+1)-len(i));
            tmp_y = cell(1,len(i+1)-len(i));
            tmp_fn = [];
            tmp_fn = U_getims([DD fns(i).name '/']);
            sz = size(gts{i});
            tmp_gts = single(gts{i});
            ind1 =[]; ind2=[]; tmp_im = cell(1,tsz);
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
                cc = 1;
                % 2d edge
                for k= (j-1)*tstep+(1:tsz)
                    tmp_im{cc} = imread([DD fns(i).name '/' tmp_fn(k).name]);
                    %tmp_im = imPad(tmp_im,psz_h,'symmetric');
                    cc = cc + 1;
                end
                tmp_x{j} = st3dGetFeature(tmp_im,[tmp_ind1 tmp_ind2],opts);
                tmp_y{j} = [ones(numel(tmp_ind1),1,'uint8'); 2*ones(numel(tmp_ind2),1,'uint8')];
                %tmp_y{j} = logical([ones(numel(tmp_ind1),1); zeros(numel(tmp_ind2),1)]);
            end
            mat_x(len(i)+1:len(i+1)) = tmp_x;
            mat_y(len(i)+1:len(i+1)) = tmp_y;
        end
    case {2,3,4}
        % 3D boundary: 1 gts, n Is (only 1 frame labeled)
        tscale = opts.tscale;
        tsz = opts.tsz;
        tsz_h = (tsz-1)/2;
        DD = opts.DD;
        fns = dir(DD);
        fns(1:2)=[];
        num_v= numel(fns);
        len = cumsum([0 numel(tscale)*ones(1,num_v)]);
        mat_x = cell(len(end),1);
        mat_y = cell(len(end),1);
        opts.patch_id
        if sum([3,4]==opts.patch_id)>0
            clusters=[];
            load(opts.clusterFnm)
            if opts.patch_id==4
                tmp_center=[];
                for i = 1:opts.nClusters
                    ids = find(clusters.clusterId == i);
                    ids = ids(randperm(length(ids),min(opts.num_pervol,length(ids))));
                    tmp_center = [tmp_center; [clusters.imId(ids),clusters.scaleId(ids),...
                    clusters.ind(ids),clusters.clusterId(ids)]]; %#ok<AGROW>
                end
            end
        end
        for i=1:num_v
            fprintf('   Video %d / %d\n',i,num_v);
            tmp_x = cell(1,len(i+1)-len(i));
            tmp_y = cell(1,len(i+1)-len(i));
            tmp_fn = U_getims([DD fns(i).name '/']);
            sz = size(gts{i});
            tmp_gts = single(gts{i});
            ind1 =[]; ind2=[]; tmp_im = cell(1,tsz);
            tmp_n=dir([DD fns(i).name '/*.mat']);
            tmp_n=tmp_n(1).name;
            im_n = ['image' tmp_n(find(tmp_n=='e',1,'first')+1:find(tmp_n=='.',1,'first')-1) '.png'];
            tcen = find(cell2mat(arrayfun(@(x) strcmp(im_n,tmp_fn(x).name),1:numel(tmp_fn),'UniformOutput',false)));
            for j = 1:numel(tmp_x)
                %parfor j = 1:numel(tmp_x)
                if tcen-tscale(j)*tsz_h>0 && tcen+tscale(j)*tsz_h<=numel(tmp_fn)
                    tmp_dist = U_addnan(single(bwdist(tmp_gts>0)),psz_h);
                    cc = 1;
                    for k= tcen+(-tsz_h*tscale(j):tscale(j):tsz_h*tscale(j))
                        tmp_im{cc} = imread([DD fns(i).name '/' tmp_fn(k).name]);
                        %tmp_im = imPad(tmp_im,psz_h,'symmetric');
                        cc = cc + 1;
                    end
                    if opts.patch_id ==2
                        % sample patch
                        % sample pos:
                        ind1 = find(tmp_dist<2)';
                        tmp_ind1 = randsample(ind1,min(floor(opts.pratio*numel(ind1)),opts.num_pervol));
                        % sample neg:
                        ind2 = find(tmp_dist>psz)';
                        tmp_ind2 = randsample(ind2,opts.num_pervol_n);
                        tmp_x{j} = st3dGetFeature(tmp_im,[tmp_ind1 tmp_ind2],opts);
                        tmp_y{j} = [ones(numel(tmp_ind1),1,'uint8'); 2*ones(numel(tmp_ind2),1,'uint8')];
                        %tmp_y{j} = logical([ones(numel(tmp_ind1),1); zeros(numel(tmp_ind2),1)]);
                    elseif opts.patch_id==3
                        % assign all patches
                        tmp_x{j} = st3dGetFeature(tmp_im,find(tmp_dist<2)',opts);                        
                        tmp_im=[];
                        dis = pdist2(bsxfun(@rdivide,tmp_x{j},clusters.chStd),clusters.clusters);
                        tmp_x{j} = find(tmp_dist<2);
                        tmp_dist=[];
                        [~,tmp_y{j}] = min(dis,[],2);
                    elseif opts.patch_id ==4
                        % sample patch
                        % sample pos:
                        tmp_ind1 = tmp_center(tmp_center(:,1)==i & tmp_center(:,2)==j,3)';
                        % sample neg:
                        ind2 = find(tmp_dist>psz)';
                        tmp_ind2 = randsample(ind2,opts.num_pervol_n);
                        tmp_x{j} = st3dGetFeature(tmp_im,[tmp_ind1 tmp_ind2],opts);
                        tmp_y{j} = [uint8(tmp_center(tmp_center(:,1)==i & tmp_center(:,2)==j,4)); (1+opts.nClusters)*ones(numel(tmp_ind2),1,'uint8')];
                        %tmp_y{j} = logical([ones(numel(tmp_ind1),1); zeros(numel(tmp_ind2),1)]);
                    end
                end
            end
            mat_x(len(i)+1:len(i+1)) = tmp_x;
            mat_y(len(i)+1:len(i+1)) = tmp_y;
        end
end

if sum([1:2 4]==opts.patch_id)>0
    mat_x = cell2mat(mat_x);
    mat_y = cell2mat(mat_y);
end
