% $Id$

function spmd_ResSMS
% This is a file to generate ResRMS.img ResRMS.hdr and ResRMS.mat files
% required fields of ResMS:
% VResRMS  file struct of ResRMS image handle
% ResRMS.{img, hdr}
%   - estimated square root of residual variance image
% This is a 32-bit (double) image of the RESELs per voxel estimate.
% Voxels outside the analysis mask are given value 0. Thes images
% reflect the nonstationary aspects the spatial autocorrelations.
%
%----------------------------------------------------------------------
% References:
%
% Wen-Lin Luo, Thomas E. Nichols (2002) Diagnosis & Exploration of
%         Massively Univariate fMRI Models
%
%______________________________________________________________________

%-Get ResMS.mat if necessary
%----------------------------------------------------------------------
if exist(fullfile('.','ResMS.mat'),'file') == 0
  swd        = spm_str_manip(spm_select(1,'ResMS.mat','Select ResMS.mat'),'H');
  VResMS     = load(fullfile(swd,'ResMS.mat');
  VResMS.swd = swd;
end

%-Delete files from previous analyses
%----------------------------------------------------------------------
if exist(fullfile('.','ResRMS.img','file') == 2
  
  str   = {'Current directory contains ResRMS estimation files:','''
	   'pwd = ',pwd,...
	   'Existing results will be overwritten!'};
  
  abort = spm_input(str,1,'bd','stop|continue',[1,0],1);
  
  if abort
    spm('FigName','Stats: done',Finter);
    spm('Pointer','Arrow');
    return
  else
    str = sprintf('Overwriting old results\n\t (pwd = %s) ',pwd);
    warning(str);
    drawnow
  end
end

files = { 'ResRMS.???' };



