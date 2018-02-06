function h = SetDefMarks(h,LinSty)
% function h = SetDefMarks(h[,LineStyle])
%---------------------------------------------------------------------
%
% Sets default marks on plot given plot handle h.  Returns h for
% convenience. 
%
% Used to make a plot suitable for grayscale printing.
%
%_____________________________________________________________________
% $Id: SetDefMarks.m,v 1.3 2000/08/09 01:35:17 nicholst Exp $

if (nargin<2)
  LinSty = '';
end

Marks = '+o*xsdv^><ph';

for i = 1:length(h)
  set(h(i),'Marker',Marks(rem(i-1,length(Marks))+1))
  if (~isempty(LinSty))
    set(h(i),'LineStyle',LinSty)
  end    
end

if (nargout==0)
  clear h
end
