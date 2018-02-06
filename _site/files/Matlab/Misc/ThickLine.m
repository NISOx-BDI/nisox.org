function h=ThickLine(w)
% FORMAT [h] = ThickLine([w],...)
% Makes lines on current plot thick
%
% [w]  Width of line.  By default 2.
% 
%
%________________________________________________________________________
% %W% %E%

if (nargin<1)
  w = 2;
end

g = get(gca,'Children');
set(g,'LineWidth',w)

if (nargout>0)
  h=g;
end
