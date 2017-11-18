
% Script for creating customised templates and priors
% ___________________________________________________
% John Ashburner 18/12/02

spm_defaults
global defaults
dseg                   = defaults.segment;
dseg.write.wrt_cor     = 0;
dnrm                   = defaults.normalise;
dnrm.write.vox         = [1 1 1];
dnrm.write.bb          = reshape([-90 90 -126 90 -72 108],2,3);
dnrm.estimate.graphics = 0;   % Crashes otherwise

V   = spm_vol(spm_get(Inf,'*.IMAGE','Select images'));
VG0 = spm_vol(fullfile(spm('Dir'),'templates','T1.mnc'));
VG1 = spm_vol(deblank(dseg.estimate.priors(1,:)));

% Initialise the totals to zero
d = [prod(VG0.dim(1:2)) VG0.dim(3)];
n = zeros(d);
g = zeros(d);
w = zeros(d);
c = zeros(d);
s = zeros(d)+eps;

for i=1:length(V),
  % Estimate spatial normalisation parameters
  % by matching GM with a GM template
  VT  = spm_segment(V(i),VG0,dseg);
  VT  = VT(1);
  prm = spm_normalise(VG1,VT,'','','',dnrm.estimate);
  clear VT

  % Create a spatially normalised version of the original image
  VN  = spm_write_sn(V(i),prm,dnrm.write);

  % Segment the spatially normalised image
  VT  = spm_segment(VN,eye(4),dseg);

  % Subsample to a lower resolution, and add the
  % current images to the totals.
  for p=1:VG0.dim(3),
    M   = VN.mat\VG0.mat*spm_matrix([0 0 p]);
    tn  = spm_slice_vol(VN   ,M,VG0.dim(1:2),1);
    tg  = spm_slice_vol(VT(1),M,VG0.dim(1:2),1);
    tw  = spm_slice_vol(VT(2),M,VG0.dim(1:2),1);
    tc  = spm_slice_vol(VT(3),M,VG0.dim(1:2),1);
    msk = find(finite(tn));
    tmp = n(:,p); tmp(msk) = tmp(msk) + tn(msk); n(:,p) = tmp;
    tmp = g(:,p); tmp(msk) = tmp(msk) + tg(msk); g(:,p) = tmp;
    tmp = w(:,p); tmp(msk) = tmp(msk) + tw(msk); w(:,p) = tmp;
    tmp = c(:,p); tmp(msk) = tmp(msk) + tc(msk); c(:,p) = tmp;
    tmp = s(:,p); tmp(msk) = tmp(msk) + 1;       s(:,p) = tmp;
  end;
end;

% Write out the averages (dividing the totals by the number
% of finite observations).
clear VN VT
VN = struct('fname','',...
            'dim',[VG0.dim(1:3) spm_type('uint8')],...
            'mat',VG0.mat,...
            'descrip','');

n=reshape(n./s,VG0.dim(1:3));
g=reshape(g./s,VG0.dim(1:3));
w=reshape(w./s,VG0.dim(1:3));
c=reshape(c./s,VG0.dim(1:3));

VN.fname = 'template.img' ; VN.descrip = 'Customised Template'; spm_write_vol(VN,n);
VN.fname =     'gray.img' ; VN.descrip =   'Grey matter prior'; spm_write_vol(VN,g);
VN.fname =    'white.img' ; VN.descrip =  'White matter prior'; spm_write_vol(VN,w);
VN.fname =      'csf.img' ; VN.descrip =           'CSF prior'; spm_write_vol(VN,c);

