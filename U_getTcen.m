function tcen = U_getTcen(DD,did)
switch did
    case 1
    % berk
    tmp_fn = U_getims(DD);
<<<<<<< HEAD
    tmp_n=dir([DD '*.mat']);
=======
    tmp_n=dir([DD '/*.mat']);
>>>>>>> 38611fee6d1a0a178fcc4ba52ad5e378c50324bb
    tmp_n=tmp_n(1).name;
    im_n = ['image' tmp_n(find(tmp_n=='e',1,'first')+1:find(tmp_n=='.',1,'first')-1) '.png'];
    tcen = find(cell2mat(arrayfun(@(x) strcmp(im_n,tmp_fn(x).name),1:numel(tmp_fn),'UniformOutput',false)));
    case 2
        % cmu
        fn  = dir([DD '/ground_truth*']);
        tcen = str2double(fn.name(find(fn.name=='_',1,'last')+1:end-4))+1;
end

