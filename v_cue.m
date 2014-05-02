function v_cue(i,did,cid)
param_init;
switch did
case 1
DD=D_BERK1;
nn='BERK1_';
case 2
DD = D_CMU;
nn='CMU_';
end

fns=dir(DD);
fns(1:2)=[];
switch cid
case 1
    % phase img
    ff ='../phase/';
    load([DD ff nn fns(i).name '_phase.mat'])
    for sc=1:5
        for or = [0 90]
            for fr = 2:4
            eval(['imwrite(' sprintf('phase_scale%d_orient%d(:,:,%d)/max(max(phase_scale%d_orient%d(:,:,%d)))', sc, or,fr, sc, or,fr) ',''' DD ff nn fns(i).name sprintf('_%d_%d_%d_p.png',sc,or,fr) ''')'])
            %eval(['imwrite(' sprintf('amp_scale%d_orient%d(:,:,%d)/max(max(amp_scale%d_orient%d(:,:,%d)))', sc, or,fr, sc, or,fr) ',''' DD ff nn fns(i).name sprintf('_%d_%d_%d.png',sc,or,fr) ''')'])
            end
        end
    end
case 2
    % of_idm
    addpath([D_VLIB 'Util/flow'])
    ff ='../of_idm/';
    load([DD ff nn fns(i).name])
    for fr = [1 4]
        imwrite(flowToColor(of{fr}),[DD ff nn fns(i).name sprintf('_%d.png',fr)])
    end
    for fr = [1 4]
        imwrite(dis{fr}/max(dis{fr}(:)),[DD ff nn fns(i).name sprintf('_d%d.png',fr)])
    end
    for fr = [1 4]
        imwrite(flowToColor(of2{fr}),[DD ff nn fns(i).name sprintf('_b%d.png',fr)])
    end
case 3
    % of_ce
    addpath([D_VLIB 'Util/flow'])
    ff ='../of_ce/';
    for fb=[1 2]
        load([DD ff nn fns(i).name '_of' num2str(fb)])
        imwrite(flowToColor(flo),[DD ff nn fns(i).name sprintf('_%d.png',fb)])
    end
end

%{
 PP = pwd;
 system(['./para/p_run.sh 1 1 30 "' PP '/para" "' PP '" "v_cue(" ",2,1);"'])
 system(['./para/p_run.sh 1 1 40 "' PP '/para" "' PP '" "T_of(" ",1);"'])


 z2x = repmat(-warp_h:warp_h,2*warp_h+1,1);
 z2y = z2x';

addpath(genpath([D_VLIB 'Util/flow']))
 addpath([D_VLIB 'Low/Filter/bfilter2'])
 w     = [5 5];       % bilateral filter half-width
 sigma = [3 0.1]; % bilateral filter standard deviations
DD = D_CMU;
DD = D_BERK1;
DD2 = [DD '../of_idm/'];
im_pre='im';
fns = dir([DD2 '*.mat']);
ddd=2;
tid = setdiff(-2:2,0);

nn = ['of_' num2str(did) '/'];
mkdir(nn)
for i=1:numel(fns)
    load([DD2 fns(i).name])
    switch ddd
        case 0
        of= cell(1,numel(zs));
        for j=1:numel(zs)
            of{j} = zeros([size(zs{1}) 2],'single');
            of{j}(:,:,1) = z2x(1+zs{j});
            of{j}(:,:,2) = z2y(1+zs{j});
        end
        save([DD2 fns(i).name],'of')
    case 1
        of2 = cell(1,numel(of));
        tmp_fn = fns(i).name(find(fns(i).name=='_')+1:end-4);
        im = uint8(U_fns2ims([DD tmp_fn  '/' im_pre]));
        id = U_getTcen([DD tmp_fn '/'],did);
        for j=1:numel(of2)
            of2{j}=of{j};
            for kk=1:2
             of2{j}(:,:,kk) = U_bila(double(rgb2gray(im(:,:,:,id+tid(j))))/255,double(of{j}(:,:,kk)),2*w+1,sigma);
         end
        end
        save([DD2 fns(i).name],'of','dis','of2')
    case 2
        of_x = arrayfun(@(x) of2{x}(:,:,1),1:numel(of2),'UniformOutput',false);
        of_x = cat(3,of_x{:});
        of_y = arrayfun(@(x) of2{x}(:,:,2),1:numel(of2),'UniformOutput',false);
        of_y = cat(3,of_y{:});
        imwrite(flowToColor(cat(3,U_maxabspool(of_x),U_maxabspool(of_y))),[nn fns(i).name(1:end-3) 'png'])
    end
end
%{
imagesc(flowToColor(cat(3,max(abs(of_x),[],3),max(abs(of_y),[],3))))
imagesc(flowToColor(cat(3,mean(of_x,3),mean(of_y,3))))
imagesc(flowToColor(cat(3,U_maxabspool(of_x),U_maxabspool(of_y))))
%}
        for or = [0 90 135 45]
            for sc = 1:5
                eval(['imwrite(ind2rgb(gray2ind(squeeze(' sprintf('phase_scale%d_orient%d(end/2,:,:))', sc, or) ',255),jet(255)),''hand3' sprintf('_%d_%d_r.png',or,sc) ''')'])
                eval(['imwrite(ind2rgb(gray2ind(squeeze(' sprintf('phase_scale%d_orient%d(:,end/2,:))', sc, or) ',255),jet(255)),''hand3' sprintf('_%d_%d_c.png',or,sc) ''')'])
            %eval(['U_ims2gif(' sprintf('amp_scale%d_orient%d', sc, or) ',''hand3a' sprintf('_%d_%d.gif',or,sc) ''',2)'])
            %eval(['U_ims2gif(' sprintf('phase_scale%d_orient%d', sc, or) ',''hand3' sprintf('_%d_%d.gif',or,sc) ''',2)'])
        end
    end
 
%}
