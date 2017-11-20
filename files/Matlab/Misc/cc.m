function r = icc(x,y)
% Correlation Coefficient
%
% Provided to complement the madcc.m function.  Differs from Matlab's
% corrcoef in that NaN's in either variable result in that entry being
% omitted, and the unique off-diagonal correlation coefficient is
% returned (instead ofa 2x2 matrix).
%
% 2014-07-08
% Thomas Nichols http://warwick.ac.uk/tenichols

I=find(all(~isnan([x(:) y(:)]),2));
if isempty(I)
  r=NaN;
else
  mx    = mean(x(I));
  my    = mean(y(I));
  sx    = std(x(I));
  sy    = std(y(I));

  if sx==0 || sy==0
    r = NaN;
  else
    r = sum((x(I)-mx).*(y(I)-my)) / sx / sy / (length(I)-1);
  end

end
