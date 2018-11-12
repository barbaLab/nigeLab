function [out,skip] = RandSelect(in, num)
%% Randomly selects specified subset of indices from "in"

N = length(in);

out = in;
if num>N
    warning('Not a random subset.')
    skip = true;
    return;
end

num_remove = N - num;
if num_remove > 10 * num
    temp = in;
    out = [];
    for ii = 1:num
        sel = randi(length(temp));
        out = [out, temp(sel)];
        temp = temp(temp~=temp(sel));
    end
    skip = false;
    return;
end


for ii = 1:num_remove
    remov = randi(length(out));
    vec = 1:length(out);
    vec = vec(vec~=remov);
    out = out(vec);
end
skip = false;
end