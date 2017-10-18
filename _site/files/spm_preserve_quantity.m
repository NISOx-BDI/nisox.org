Return-path: <spm-request@mailbase.ac.uk>
X-Andrew-Authenticated-as: 0;andrew.cmu.edu;Network-Mail
Received: from po4.andrew.cmu.edu via trymail
          ID </afs/andrew.cmu.edu/usr14/tn0o/Mailbox/ctU3dFG00Udc1J3E40>;
          Thu, 27 Jul 2000 09:34:09 -0400 (EDT)
Received: from mailout2.mailbase.ac.uk (mailout2.mailbase.ac.uk [128.240.226.12])
	by po4.andrew.cmu.edu (8.9.3/8.9.3) with ESMTP id JAA21768
	for <tn0o+@andrew.cmu.edu>; Thu, 27 Jul 2000 09:34:07 -0400 (EDT)
Received: from naga.mailbase.ac.uk (naga.mailbase.ac.uk [128.240.226.3])
	by mailout2.mailbase.ac.uk (8.9.1a/8.9.1) with ESMTP id OAA13917;
	Thu, 27 Jul 2000 14:33:54 +0100 (BST)
Received: (from daemon@localhost) 
        by naga.mailbase.ac.uk (8.8.x/Mailbase) id OAA04915;
        Thu, 27 Jul 2000 14:29:31 +0100 (BST)
Received: from fil.ion.ucl.ac.uk (cream.fil.ion.ucl.ac.uk [193.62.66.20]) 
        by naga.mailbase.ac.uk (8.8.x/Mailbase) with ESMTP id OAA04847;
        Thu, 27 Jul 2000 14:29:26 +0100 (BST)
Received: from zappa.fil.ion.ucl.ac.uk by fil.ion.ucl.ac.uk (8.8.8+Sun/SMI-SVR4)
	id OAA19545; Thu, 27 Jul 2000 14:28:38 +0100 (BST)
Received: from zappa by zappa.fil.ion.ucl.ac.uk (8.8.8+Sun/SMI-SVR4)
	id OAA04354; Thu, 27 Jul 2000 14:28:39 +0100 (BST)
Message-Id: <200007271328.OAA04354@zappa.fil.ion.ucl.ac.uk>
Date: Thu, 27 Jul 2000 14:28:39 +0100 (BST)
Reply-To: John Ashburner <john@fil.ion.ucl.ac.uk>
MIME-Version: 1.0
Content-Type: MULTIPART/mixed; BOUNDARY=Stare_of_Owls_758_000
X-Mailer: dtmail 1.2.1 CDE Version 1.2.1 SunOS 5.6 sun4m sparc 
Subject: Re: matlab question & VBM
From: John Ashburner <john@fil.ion.ucl.ac.uk>
To: spm@mailbase.ac.uk, x.chitnis@iop.kcl.ac.uk
X-List: spm@mailbase.ac.uk
X-Unsub: To leave, send text 'leave spm' to mailbase@mailbase.ac.uk
X-List-Unsubscribe: <mailto:mailbase@mailbase.ac.uk?body=leave%20spm>
Sender: spm-request@mailbase.ac.uk
Errors-To: spm-request@mailbase.ac.uk
Precedence: list
X-filter: ifile 1.0.0 => CompSys/SPM

--Stare_of_Owls_758_000
Content-Type: TEXT/plain; charset=us-ascii
Content-MD5: 4q7JrMv3+lYXET+z6todXg==

| Following on from John Ashburner's recent reply, is there a matlab function
| that enables you to adjust spatially normalised images in order to preserve
| original tissue volume for VBM?

The function attached to this email will do this.  Type the following bit of
code into Matlab to run it:

	Mats   = spm_get(Inf,'*_sn3d.mat','Select sn3d.mat files');
	Images = spm_get(size(Mats,1),'*.img','Select images to modulate');

	for i=1:size(Mats,1),
	        spm_preserve_quantity(deblank(Mats(i,:)),deblank(Images(i,:)));
	end;

| 
| Additionally, I have matlab 5.3, but not 4.2. Does SnPM run under matlab 5
| if I wanted to try using it?

I'm afraid not.

Best regards,
-John
 

--Stare_of_Owls_758_000
Content-Type: TEXT/plain; name="spm_preserve_quantity.m"; charset=us-ascii; x-unix-mode=0644
Content-Description: spm_preserve_quantity.m
Content-MD5: zjv8kyo3GexL4tGCa0uM0w==

function spm_preserve_quantity(matname,infile)
% Modulate spatially normalized images in order to preserve `counts'.
% FORMAT spm_preserve_quantity(matname,infile)
% matname  - the `_sn3d.mat' file containing the spatial normalization
%            parameters.
% infile   - the spatially normalized image to be modulated.
%
% After nonlinear spatial normalization, the relative volumes of some
% brain structures will have decreased, whereas others will increase.
% The resampling of the images preserves the concentration of pixel
% units in the images, so the total counts from structures that have
% reduced volumes after spatial normalization will be reduced by an
% amount proportional to the volume reduction.
%
% This routine rescales images after spatial normalization, so that
% the total counts from any structure are preserved.  It was written
% as an optional step in performing voxel based morphometry.
%
%_______________________________________________________________________
% %W% John Ashburner %E%

load(deblank(matname))
if (exist('mgc') ~= 1)
	error(['Matrix file ' matname ' is the wrong type.']);
end
if (mgc ~= 960209)
	error(['Matrix file ' matname ' is the wrong type.']);
end

V      = spm_vol(infile);

% Assume transverse images, and obtain
% position of pixels in millimeters.
%----------------------------------------------------------------------------
x = (1:V.dim(1))*V.mat(1,1) + V.mat(1,4);
y = (1:V.dim(2))*V.mat(2,2) + V.mat(2,4);
z = (1:V.dim(3))*V.mat(3,3) + V.mat(3,4);

% Convert to voxel space of template.
%----------------------------------------------------------------------------
x = x/Dims(3,1) + Dims(4,1);
y = y/Dims(3,2) + Dims(4,2);
z = z/Dims(3,3) + Dims(4,3);

X = x'*ones(1,V.dim(2));
Y = ones(V.dim(1),1)*y;

bbX = spm_dctmtx(Dims(1,1),Dims(2,1),x-1);
bbY = spm_dctmtx(Dims(1,2),Dims(2,2),y-1);
bbZ = spm_dctmtx(Dims(1,3),Dims(2,3),z-1);

dbX = spm_dctmtx(Dims(1,1),Dims(2,1),x-1,'diff');
dbY = spm_dctmtx(Dims(1,2),Dims(2,2),y-1,'diff');
dbZ = spm_dctmtx(Dims(1,3),Dims(2,3),z-1,'diff');

% Start progress plot
%----------------------------------------------------------------------------
spm_progress_bar('Init',length(z),'Modulating by determinants of Jacobian','planes completed');

M   = MF*Affine*inv(MG);
sgn = sign(det(M(1:3,1:3)));

img = zeros(V.dim(1:3));
% Cycle over planes
%----------------------------------------------------------------------------
for j=1:length(z)

	% Nonlinear deformations
	%----------------------------------------------------------------------------
	% 2D transforms for each plane
	tbx = reshape( reshape(Transform(:,1),Dims(2,1)*Dims(2,2),Dims(2,3)) *bbZ(j,:)', Dims(2,1), Dims(2,2) );
	tby = reshape( reshape(Transform(:,2),Dims(2,1)*Dims(2,2),Dims(2,3)) *bbZ(j,:)', Dims(2,1), Dims(2,2) );
	tbz = reshape( reshape(Transform(:,3),Dims(2,1)*Dims(2,2),Dims(2,3)) *bbZ(j,:)', Dims(2,1), Dims(2,2) );

	tdx = reshape( reshape(Transform(:,1),Dims(2,1)*Dims(2,2),Dims(2,3)) *dbZ(j,:)', Dims(2,1), Dims(2,2) );
	tdy = reshape( reshape(Transform(:,2),Dims(2,1)*Dims(2,2),Dims(2,3)) *dbZ(j,:)', Dims(2,1), Dims(2,2) );
	tdz = reshape( reshape(Transform(:,3),Dims(2,1)*Dims(2,2),Dims(2,3)) *dbZ(j,:)', Dims(2,1), Dims(2,2) );

	% Jacobian of transformation from template
	% to affine registered image.
	%---------------------------------------------
	j11 = dbX*tbx*bbY' + 1;
	j12 = bbX*tbx*dbY';
	j13 = bbX*tdx*bbY';

	j21 = dbX*tby*bbY';
	j22 = bbX*tby*dbY' + 1;
	j23 = bbX*tdy*bbY';

	j31 = dbX*tbz*bbY';
	j32 = bbX*tbz*dbY';
	j33 = bbX*tdz*bbY' + 1;

	% Combine Jacobian of transformation from
	% template to affine registered image, with
	% Jacobian of transformation from affine
	% registered image to original image.
	%---------------------------------------------
	J11 = M(1,1)*j11 + M(1,2)*j21 + M(1,3)*j31;
	J12 = M(1,1)*j12 + M(1,2)*j22 + M(1,3)*j32;
	J13 = M(1,1)*j13 + M(1,2)*j23 + M(1,3)*j33;

	J21 = M(2,1)*j11 + M(2,2)*j21 + M(2,3)*j31;
	J22 = M(2,1)*j12 + M(2,2)*j22 + M(2,3)*j32;
	J23 = M(2,1)*j13 + M(2,2)*j23 + M(2,3)*j33;

	J31 = M(3,1)*j11 + M(3,2)*j21 + M(3,3)*j31;
	J32 = M(3,1)*j12 + M(3,2)*j22 + M(3,3)*j32;
	J33 = M(3,1)*j13 + M(3,2)*j23 + M(3,3)*j33;

	% The determinant of the Jacobian reflects relative volume changes.
	%------------------------------------------------------------------
	detJ = J11.*(J22.*J33 - J23.*J32) - J21.*(J12.*J33 - J13.*J32) + J31.*(J12.*J23 - J13.*J22);

	img(:,:,j) = spm_slice_vol(V,spm_matrix([0 0 j]),V.dim(1:2),1).*detJ*sgn;
	%img(:,:,j) = detJ*sgn;

	spm_progress_bar('Set',j);
end

% Write the data
%------------------------------------------------------------------
VO = V;
[pth,nm,xt,vr] = fileparts(deblank(V.fname));
VO.fname       = fullfile(pth,['m' nm xt vr]);
if isfield(VO,'descrip'),
	VO.descrip = [VO.descrip ' - Jacobian modulated'];
else,
	VO.descrip = ['spm - Jacobian modulated'];
end;
VO = spm_write_vol(VO, img);
spm_progress_bar('Clear');
return;
%_______________________________________________________________________

--Stare_of_Owls_758_000--
