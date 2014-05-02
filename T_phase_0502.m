param_init



fns = dir(D_CMU);fns(1:2)=[];

<<<<<<< HEAD
for id=1:30;

load([D_CMU '../phase/CMU_' fns(id).name '_phase'])
load([D_CMU '../bd_st/CMU_' fns(id).name '_s2d'])

dd=1;
for ss = [1 3 4]
    cc=1;
    mask2 = bwdist(s_bd{ss}>0.6)<3;
    gg = zeros([size(mask2) 4]);
    for rr = [0:45:135]
        subplot(3,2,cc),eval(sprintf('tmp = bsxfun(@times,phase_scale%d_orient%d,mask2);',dd,rr));
        gg(:,:,cc) = max(abs(tmp(:,:,2:end-1)-tmp(:,:,3:end)),[],3);
        imagesc(gg(:,:,cc)),axis off
        cc = cc+1;
    end
    %subplot(3,2,cc),imagesc(mask2),axis off
    subplot(3,2,cc),imagesc(s_bd{ss}),axis off
    subplot(3,2,cc+1),imagesc(max(gg,[],3)),axis off
    saveas(gca,sprintf('phase_%d_%d_%d.png',id,dd,cc))
    dd= dd+1;
end
end

arrayfun(@(x) mean(mean(phase_scale2_orient135(:,:,x))),1:5)
id=13;



addpath(genpath([D_VLIB 'Util/flow']))
opts.tsz=  tsz_h*2+1;
of = U_getOF(phase_scale1_orient90,opts);
for i=1:4;subplot(2,2,i),imagesc(flowToColor(of{i}));end


% paper
addpath([D_VLIB 'Low/Flow/phase-flow'])
[O,LE,FV] = optical_flow(double(vid(:,:,2:3)), 0, 0.01, 7);
imagesc(flowToColor(O))

