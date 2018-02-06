function T2nltP(a1,a2)
% Write image of -log10 P-values for a T image
%
% FORMAT T2nltP(c)
% c     Contrast number of a T constrast (assumes cwd is a SPM results dir)
%
% FORMAT T2nltP(Timg,df)
% Timg  Filename of T image
% df    Degrees of freedom
%
%
% As per SPM convention, T images are zero masked, and so zeros will have
% P-value NaN.
%
% @(#)T2nltP.m	1.2 T. Nichols 03/07/15

if nargin==1
  c = a1;
  load xCon
  load SPM xX
  if xCon(c).STAT ~= 'T', error('Not a T contrast'); end
  Tnm = sprintf('spmT_%04d',c);
  df = xX.erdf;
else
  Tnm = a1;
  df  = a2;  
end


Tvol = spm_vol(Tnm);

Pvol        = Tvol;
Pvol.dim(4) = spm_type('float');
Pvol.fname  = strrep(Tvol.fname,'spmT','spm_nltP');
if strcmp(Pvol.fname,Tvol.fname)
  Pvol.fname = fullfile(spm_str_manip(Tvol.fname,'H'), ...
			['nltP' spm_str_manip(Tvol.fname,'t')]);
end


Pvol = spm_create_image(Pvol);

for i=1:Pvol.dim(3),
  img         = spm_slice_vol(Tvol,spm_matrix([0 0 i]),Tvol.dim(1:2),0);
  img(img==0) = NaN;
  tmp         = find(isfinite(img));
  if ~isempty(tmp)
    img(tmp)  = -log10(max(eps,1-spm_Tcdf(img(tmp),df)));
  end
  Pvol        = spm_write_plane(Pvol,img,i);
end;

