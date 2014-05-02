%{
    param_init
addpath(genpath('/home/Stephen/Desktop/AMM/Neal'))

DD=D_CMU;
fns = dir(DD);fns(1:2)=[];


im_pre = 'im';

id=2;
vid = uint8(U_fns2ims([DD fns(id).name '/' im_pre]));
tcen = U_getTcen([DD fns(id).name '/'],2);
tsz_step = 1;
tsz_h=2;
vid = vid(:,:,:,tcen+(-tsz_h*tsz_step:tsz_step:tsz_h*tsz_step));
vid = 0.2989 * vid(:,:,1,:) + 0.5870 * vid(:,:,2,:) + 0.1140 * vid(:,:,3,:);


vid =cat(3,vid(:,:,1),vid,vid(:,:,end));
T_phase(vid,'test.mat');


%}
function T_phase(vid,fn)
buildPyr = @buildSCFpyr;
for k = 1:size(vid,4)
   [pyrs(:,k),pind] = buildPyr(vid(:,:,1,k));
   pyrVid = pyrVid2CellVid(pyrs, pind);
end



angles = [0 135 90 45];
phaseScalars = [1.72 0.86 0.44 0.22 0.11];
nn={};
kk=1;
tcen = ceil((1+size(vid,4))/2);
for sc = 1:5
    for or = 1:4   
        bandIDX = 1+or+(sc-1)*4;
        eval(sprintf('amp_scale%d_orient%d =  squeeze(abs(pyrVid{bandIDX}));', sc, angles(or)));
        nn{kk}=sprintf('amp_scale%d_orient%d', sc, angles(or));kk=kk+1;
        temp = angle(pyrVid{bandIDX});
        temp = mod(pi+bsxfun(@minus, temp, temp(:,:,:,tcen)),2*pi)-pi;
        temp = squeeze(temp./phaseScalars(sc));
        eval(sprintf('phase_scale%d_orient%d =  temp;', sc, angles(or)));
        nn{kk}=sprintf('phase_scale%d_orient%d', sc, angles(or));kk=kk+1;
    end
end
save(fn,nn{:})
%{
addpath(genpath([D_VLIB 'Util/flow']))
opts.tsz=  tsz_h*2+1;
of = U_getOF(phase_scale1_orient90,opts);
for i=1:4;subplot(2,2,i),imagesc(flowToColor(of{i}));end


% paper
addpath([D_VLIB 'Low/Flow/phase-flow'])
[O,LE,FV] = optical_flow(double(vid(:,:,2:3)), 0, 0.01, 7);
imagesc(flowToColor(O))

%}
