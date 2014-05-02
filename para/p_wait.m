function done = p_wait(nn,t_int,f_all,t_out,dsp)
        num_f =0;
        t_0 =0;
        if dsp
            tic;
        end
        num_f=numel(dir(nn))

        while num_f~=f_all && t_0<t_out
            pause(t_int)
            num_f=numel(dir(nn));
            t_0 = t_0+t_int;
            if dsp
                disp([num2str(num_f) ': ' num2str(toc)])
            end
        end
done=num_f==f_all;
