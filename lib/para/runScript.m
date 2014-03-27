function [] = runScript(directory, cmd)
%disp(cmd);
cd(directory);
%disp(pwd);
%disp(cmd);
eval(cmd);
exit;
