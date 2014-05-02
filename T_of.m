function T_of(i,did)
param_init;
switch did
case 1
DD=D_BERK1;
nn='BERK1_';
case 2
DD = D_CMU;
nn='of_';
%nn='CMU_';
end

fns=dir(DD);
fns(1:2)=[];
if ~exist([DD '../of_idm/' nn fns(i).name '.mat'],'file')
    addpath(genpath([D_VLIB 'Util/io']))
    addpath('lib/IDM')
    psz_h = 2;
    warp_h = 5;
    step = 1;%psz_h;
    penalty = 2;
    z2x = repmat(-warp_h:warp_h,2*warp_h+1,1);
    z2y = z2x';

    tmp_fn = U_getims([DD fns(i).name '/']);
    tmp_fn([arrayfun(@(x) tmp_fn(x).name(1)=='g',1:numel(tmp_fn))])=[];
    tcen = U_getTcen([DD fns(i).name],did);
    cc=1;
    % 1 dim first
    im = uint8(U_fns2ims([DD fns(i).name '/'],tmp_fn(tcen+(-2:2))));
    of = cell(1,4);
    dist = cell(1,4);
    for tstep=setdiff(1:5,3)
        [z,dis{cc}] = IDM_map(double(rgb2gray(im(:,:,:,3))),double(rgb2gray(im(:,:,:,tstep))),warp_h,psz_h,step,penalty);
        of{cc} = zeros([size(z) 2],'single');
        of{cc}(:,:,1) = z2x(1+z);
        of{cc}(:,:,2) = z2y(1+z);
        cc=cc+1;
    end
    save([DD '../of_idm/' nn fns(i).name],'of','dis')
end
%{
 PP = pwd;
 system(['./para/p_run.sh 1 1 30 "' PP '/para" "' PP '" "T_of(" ",2);"'])
 system(['./para/p_run.sh 1 1 40 "' PP '/para" "' PP '" "T_of(" ",1);"'])


 z2x = repmat(-warp_h:warp_h,2*warp_h+1,1);
 z2y = z2x';

 
 
 addpath(genpath([D_VLIB 'Util/flow']))
 addpath([D_VLIB 'Low/Filter/bfilter2'])
 w     = [5 5];       % bilateral filter half-width
 sigma = [3 0.1]; % bilateral filter standard deviations
 did = 1;
 if did==1
DD = D_BERK1;
else
DD = D_CMU;
end
DD2 = [DD '../of_idm/'];
im_pre='im';
fns = dir([DD2 '*.mat']);

ddd=3;
tid = setdiff(-2:2,0);
if ddd==2
    nn = ['of_' num2str(did) '/'];
    mkdir(nn)
end
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
    case 3
        of3 = cell(1,numel(of));
        tmp_fn = fns(i).name(find(fns(i).name=='_')+1:end-4);
        im = uint8(U_fns2ims([DD tmp_fn  '/' im_pre]));
        id = U_getTcen([DD tmp_fn '/'],did);
        for j=1:numel(of2)
            of3{j}=of{j};
            for kk=1:2
             of3{j}(:,:,kk) = medfilt2(of{j}(:,:,kk),2*w+1);
         end
        end
        save([DD2 fns(i).name],'of','dis','of2','of3')
    end
end
%{
imagesc(flowToColor(cat(3,max(abs(of_x),[],3),max(abs(of_y),[],3))))
imagesc(flowToColor(cat(3,mean(of_x,3),mean(of_y,3))))
imagesc(flowToColor(cat(3,U_maxabspool(of_x),U_maxabspool(of_y))))
%}
%}
