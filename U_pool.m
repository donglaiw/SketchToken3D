function y=U_pool(mat,opt)
% max pool w.r.t. abs value
switch opt
case 1
    % max abs pool
    sz = size(mat);
    [~,of_idx]=max(abs(mat),[],3);
    y = zeros(sz(1:2),'single');
    for i=1:size(mat,3)
        tmp_of = mat(:,:,i);
        y(of_idx==i) = tmp_of(of_idx==i);
    end
case 2
    % max pool
    y=max(mat,[],3);
case 3
    % mean pool
    y=mean(mat,3);
case 4
    % mean/std stat pool
    y=cat(3,mean(mat,3),std(mat,[],3));
end

