%
% Demonstration of robust estimation of standard deviation and AR(1)
% autocorrelation parameter
%
%
% Note, for computing AR correlation parameter, the mean and standard
% deviation of Y(1:end-1) and Y(2:end) should naturally be assumed to be
% the same.  Hence, instead of the usual Pearson's correlation
% coefficient, the Intra-Class Correlation Coefficient is used (which
% assumes equal mean and variance of the two variates).
%
% Requires SPM and the Matlab Statistics toolbox
%
% 2014-07-08
% Thomas Nichols http://warwick.ac.uk/tenichols

rho  = 0.5;
nT   = 250;
SD   = 10;
pBad = 0.2;  % Proportion of bad obs

% Serial AR1 autocorrelation 
V0   = full(spm_Q(rho,nT));
% Random data
Y    = sqrtm(V0)*randn(nT,1)*SD;
% Add outliers
nBad = round(pBad*nT);
Y(randperm(nT,nBad)',:) = randn(nBad,1)*SD*5;

SD_hat          = std(Y);
SD_hat_robust   = diff(quantile(Y,[0.25 0.75])) / (2*norminv(0.75));  % IQR / 1.349

rho_hat         = icc(Y(1:end-1),Y(2:end));
rho_hat_robust  = madicc(Y(1:end-1),Y(2:end));

fprintf('nT=%d  P(Bad)=%0.2f | rho=%0.2f  ICC=%0.2f   MADICC=%0.2f | SD=%0.2f  StdEst=%0.2f  StdRob=%0.2f\n',...
	nT,pBad,rho,rho_hat,rho_hat_robust,SD,SD_hat,SD_hat_robust)



