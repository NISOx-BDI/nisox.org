function h = SetDefLines(h,w)
% function h = SetDefLines(h,w)
%
% Sets default lines on plot given plot handle h.  Returns h for
% convenience. Optionally width can be specified.
%
% Used to make a plot suitable for grayscale printing.
%
%________________________________________________________________________
% Based on SetDefMarks.m,v 1.2
% $Id: SetDefLines.m,v 1.1 2000/08/09 01:35:53 nicholst Exp $

Lines = str2mat('-','-.','--',':');
if (nargin<=1)
  w = [];
end

for i = 1:length(h)
  set(h(i),'LineStyle',deblank(Lines(rem(i-1,length(Lines))+1,:)))
  if ~isempty(w)
    set(h(i),'LineWidth',w)
  end
end

if (nargout==0)
  clear h
end
