---
layout: post
title: "FWHM & RESEL details for SPM and FSL"
---
## Executive Summary

Random Field Theory depends on a measure called the RESEL count to determine corrected P-values. How RESELs are reported on in SPM and FSL, however, differs. This post reviews the basics of RESELs and FWHM and details how to interpret the values reported by each software.

## Background

Random Field Theory (RFT) is the method used in both FSL and SPM to make inference on statistic images. Specifically, it finds thresholds that control the chance of false positives while searching the brain for activations or group differences. The magic of RFT, unlike other methods, like Bonferroni, is that it accounts for the spatial smoothness of the data; as a result, a less severe correction is applied to highly smooth data while a more stringent correction is applied to relatively rough data.

The details of how RFT measures smoothness are technical (it is the inverse square root of the determinant of the variance-covariance matrix of the gradient of the component fields), but fortunately Keith Worsley introduced the notion of FWHM and RESELs [1] to make matters simplier.

For RFT, the FWHM is defined as the Full Width at Half Maximum of the Gaussian kernel required to smooth independent, white noise data to have the same “smoothness” as your data. Here, “smoothness” refers to the technical definition involving the “square root of the determinant…”. Crucially, FWHM is not the applied smoothness, e.g. the Gaussian kernel smoothing applied as part of preprocessing. It is the smoothness of the data fed into the GLM, which is a combination of the intrinsic smoothness of the data (affected by things like image reconstruction parameters and physiological noise). As we have 3-D data, FWHM is usually represented as a 3-vector, [FWHMx FWHMY FWHMZ], though be careful to check whether the units are in voxels or mm.

RESEL stands for RESolution ELement, and is a virtual voxel with dimensions [FWHMx FWHMY FWHMZ]. The RESEL count is the number of RESELs that fit into your search volume; in math mode:

R = V / ( FWHMX × FWHMY × FWHMZ )

where V is the search volume; note that V can be in voxels or mm3 (or whatever) as long as FWHMX, FWHMY & FWHMZ have the same units.

Note a possible source of confusion: A “RESEL” is 3D object, a cuboid; the “RESEL count” is a scalar, your search volume in units of RESELs.

## SPM
SPM provides the most complete reporting of FWHM and RESEL-related quantities. In the Results figure, in the footer of the P-value table, SPM lists [FWHMx FWHMY FWHMZ] in both voxel and mm units. It also lists the search volume in RESELs (along with the same in mm3 and voxel units). Finally, it reports the size of one RESEL measured in voxels.

Note, if you check SPM’s arithmetic, you may find that R is not exactly V / ( FWHMX × FWHMY × FWHMZ ). The reason is that a more sophisticated method for measuring the search volume is used that involves counting voxel edges and faces, etc; see spm/src/spm_resels_vol.c & [2] for more details.

## FSL

FSL provides no information about RESELs or FWHM in its HTML output. There is some information available, however, buried in the *.feat directories.

In each *.feat directory there is a stats subdirectory. In that directory you’ll find a file called smoothness that contains three lines, one each labeled DLH, VOLUME, RESELS.

DLH is the unintuitive parameter that describes image roughness; precisely it is

DLH = (4 log(2))3/2 / ( FWHMX × FWHMY × FWHMZ)

where FWHMX, FWHMY and FWHMZ are in voxel units.

VOLUME is the search volume in units of voxels. And, as a source of great possible confusion, RESELS is not the RESEL count, but rather, the size of one RESEL in voxel units

RESELS = FWHMX × FWHMY × FWHMZ

Sadly, the FWHMX, FWHMY and FWHMZ are never individually computed or saved. Note, however, the geometric mean of the FWHM’s is available as

AvgFWHM = RESELS1/3

which is some consolation.

Update: The verbose option to smoothest, -V, it will report the individual FWHMx, FWHMx, & FWHMy. But, again, this isn’t saved as part of feat output.

## Who cares?

Any neuroimaging researcher should always check the estimated FWHM of their analysis. The reason is that if, for some reason the FWHM smoothness is less than 3 in any dimension, the accuracy of the RFT results can be very poor [3]. While the FSL user can’t examine the 3 individual FHWM, they can at least compute AvgFWHM and check this.

Another reason is to understand differences in corrected P-values. For example, say you conduct 2 studies each with 20 subjects. You notice that, despite having similar T-values, the two studies have quite different FWE corrected P-values. The difference must be due to different RESEL counts, which in turn can be explained by either a difference in search volume (V) or smoothness (FWHM).

Finally, one more reason to check the RESELs is when you are getting bizarre results, like insanely significant results for modest cluster sizes. For example, if VBM results are poorly masked it can happen that the analysis includes a large boundary of air voxels outside the brain. Not only is this unnecessarily increasing your search volume (possibly increasing your multiple testing correction), but the smoothness estimate in air will be dramatically lower than in brain tissue, and thus corrupt the accuracy of the inferences. A bizarre value for RESEL size or FWHM will reveal this problem.

## Further Reading
For a light-touch introduction to Random Field Theory, see [3]; for more detail (but less than the mathematical papers) see the relevant chapters in these books [4,5,6].

## References
[1] Worsley, K. J., Evans, A. C., Marrett, S., & Neelin, P. (1992). A three-dimensional statistical analysis for CBF activation studies in human brain. Journal of Cerebral Blood Flow and Metabolism, 12(6), 900–918. Preprint

[2] Worsley, K. J., Marrett, S., Neelin, P., Vandal, A. C., Friston, K. J., & Evans, A. C. (1996). A unified statistical approach for determining significant signals in images of cerebral activation. Human brain mapping, 4(1), 58–73.

[3] Nichols, T. E., & Hayasaka, S. (2003). Controlling the familywise error rate in functional neuroimaging: a comparative review. Statistical Methods in Medical Research, 12(5), 419–446.

[4] Poldrack, R. A., Mumford, J. A., & Nichols, T. E. (2011). Handbook of fMRI Data Analysis (p. 450). Cambridge University Press.

[5] Penny, W. D., Friston, K. J., Ashburner, J. T., Kiebel, S. J., & Nichols, T. E. (2006). Statistical Parametric Mapping: The Analysis of Functional Brain Images (p. 656). Academic Press. [Previous version available free]

[6] Jezzard, P., Matthews, P. M., & Smith, S. M. (2002). Functional MRI: An Introduction to Methods (p. 432). Oxford University Press.