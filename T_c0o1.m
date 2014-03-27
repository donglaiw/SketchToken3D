param_init;

addpath(genpath([D_VLIB 'Util/io']))
addpath('lib/IDM')
psz_h = 2;
warp_h = 5;
step = 1;%psz_h;
penalty = 2;

fns = dir([D_CMU 'clips']);
fns(1:2)=[];
ff = setdiff(-2:2,0);
for i=1:numel(fns)
    clf
    ha =U_timg2(2,2,[.01 .01],[.01 .01],[.01 .01]);
    im = uint8(U_fns2ims([D_CMU 'clips/' fns(i).name '/img_']));
    fn  = dir([D_CMU 'clips/' fns(i).name '/ground_truth*']);
    id = str2double(fn.name(find(fn.name=='_',1,'last')+1:end-4))+1;

       cc=1;
        zs = cell(1,4);
        for tstep=ff
            zs{cc} = IDM_map(double(im(:,:,1,id)),double(im(:,:,1,id+tstep)),warp_h,psz_h,step,penalty);
            cc=cc+1;
        end
        for j=1:4;axes(ha(j));imagesc(zs{j});axis equal;axis off;end
        %for i=1:4;subplot(2,2,i);imagesc(zs{i});title(['frame ' num2str(ff(i))]);axis equal;axis off;end
        saveas(gcf,['idm_' fns(i).name '.png']);
end

            %{
            fx = z2x(1+z);
            fy = z2y(1+z);
            [g1,g2]=gradient(fx);
            [g3,g4]=gradient(fy);
            gb=abs(g1)+abs(g2)+abs(g3)+abs(g4);
            %gb=sqrt(g1.^2+g2.^2+g3.^2+g4.^2);
            gb2 = imfilter(gb,H);
            %}
