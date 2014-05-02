function y=U_resize(ims,ratio)

sz = size(ims);
sz2 = [ceil(sz(1:end-1)*ratio) sz(end)];

y = zeros(sz2,'uint8');
for i=1:sz(end)
	if numel(sz)==3
		y(:,:,i) = imresize(ims(:,:,i),sz2(1:end-1));
	else
		y(:,:,:,i) = imresize(ims(:,:,:,i),sz2(1:end-1));			
	end
end