function save_parameters(V)
%
% By John Ashburner, from SPM List message
% Fri, 23 Apr 2004 11:25:27 +0000 (07:25 EDT)
%

name = [spm_str_manip(prepend(V(1).fname,'rp_'),'s') '.txt'];
n = length(V);
Q = zeros(n,6);
for j=1:n,
        qq     = spm_imatrix(V(j).mat/V(1).mat);
        Q(j,:) = qq(1:6);
end;

save(fname,'Q','-ascii');

return;
