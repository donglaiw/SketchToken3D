param_init
fns = dir(D_CMU);fns(1:2)=[];
id = 10;
ims = U_fns2ims([D_CMU fns(id).name '/img']);

subplot(221),imagesc(ims(:,:,1))
subplot(222),imagesc(squeeze(ims(100,:,1,:)))
subplot(223),imagesc(squeeze(ims(400,:,1,:)))
subplot(224),imagesc(squeeze(ims(:,200,1,:)))
