
    param_init




fns = dir(D_CMU);fns(1:2)=[];

id=13;



addpath(genpath([D_VLIB 'Util/flow']))
opts.tsz=  tsz_h*2+1;
of = U_getOF(phase_scale1_orient90,opts);
for i=1:4;subplot(2,2,i),imagesc(flowToColor(of{i}));end


% paper
addpath([D_VLIB 'Low/Flow/phase-flow'])
[O,LE,FV] = optical_flow(double(vid(:,:,2:3)), 0, 0.01, 7);
imagesc(flowToColor(O))

