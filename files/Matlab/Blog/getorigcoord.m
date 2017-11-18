function orig_coord = get_orig_coord(coord, matname,PN,PU)
% Determine corresponding co-ordinate in un-normalised image.
% FORMAT orig_coord = get_orig_coord(coord, matname,PN,PU)
% coord      - [x y z] in normalised image (voxel).
% matname    - File containing transformation information (_sn3d.mat).
% PN         - Name of normalised image
% PU         - Name of un-normalised image
% orig_coord - Co-ordinate in un-normalised image (voxel).
%
% For SPM99 only.
%
%_______________________________________________________________________
% %W% John Ashburner %E%

[Dims,Affine,MF,MG,Tr] = load_params(matname);

VN = spm_vol(PN);
VU = spm_vol(PU);

Mat = MG\VN.mat;

coord = coord(:);

x = Mat(1,:)*[coord' 1]';
y = Mat(2,:)*[coord' 1]';
z = Mat(3,:)*[coord' 1]';

if (prod(size(Tr)) == 0),
        affine_only = 1;
        basX = 0; tx = 0;
        basY = 0; ty = 0;
        basZ = 0; tz = 0;
else,
        affine_only = 0;
        basX = spm_dctmtx(Dims(1,1),size(Tr,1),x-1);
        basY = spm_dctmtx(Dims(1,2),size(Tr,2),y-1);
        basZ = spm_dctmtx(Dims(1,3),size(Tr,3),z-1);
end;

Mult = VU.mat\MF*Affine;
if affine_only,
	x2 = Mult(1,:)*[x y z 1]';
	y2 = Mult(2,:)*[x y z 1]';
	z2 = Mult(3,:)*[x y z 1]';
else,
	tx = reshape(...
		reshape(Tr(:,:,:,1),size(Tr,1)*size(Tr,2),size(Tr,3))...
		*basZ', size(Tr,1), size(Tr,2) );
	ty = reshape(...
		reshape(Tr(:,:,:,2),size(Tr,1)*size(Tr,2),size(Tr,3))...
		*basZ', size(Tr,1), size(Tr,2) );
	tz = reshape(...
		reshape(Tr(:,:,:,3),size(Tr,1)*size(Tr,2),size(Tr,3))...
		*basZ', size(Tr,1), size(Tr,2) );
	x1 = x + basX*tx*basY';
	y1 = y + basX*ty*basY';
	z1 = z + basX*tz*basY';

	x2 = Mult(1,:)*[x1 y1 z1 1]';
	y2 = Mult(2,:)*[x1 y1 z1 1]';
	z2 = Mult(3,:)*[x1 y1 z1 1]';
end;
orig_coord = [x2 y2 z2];

return;

function [Dims,Affine,MF,MG,Tr] = load_params(matname)
load(deblank(matname))
if (exist('mgc') ~= 1)
        error(['Matrix file ' matname ' is the wrong type.']);
end
if (mgc ~= 960209)
        error(['Matrix file ' matname ' is the wrong type.']);
end
Tr = reshape(Transform,[Dims(2,:) 3]);
return;

