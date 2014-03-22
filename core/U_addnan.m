function im=U_addnan(im,psz)

im(1:psz,:)=nan;
im(end-psz+1:end,:)=nan;
im(:,1:psz,:)=nan;
im(:,end-psz+1:end)=nan;