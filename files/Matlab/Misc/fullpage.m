function fullpage(a1,a2,Fig)
% function fullpage([Orient],[Margin],[Fig])
%
% Orient  - 'p' portrait or 'l' landscape (default)
% Margin  - Margin in inches
% Fig     - Figure to set attributes on
% 
% Sets paper size to full letter dimensions and also sets orientation.
%
% @(#)fullpage.m	1.2 04/10/18

Orient = 'l';
Margin = 0;

if (nargin==1) | ( nargin>1 & isempty(a2) )
  if isstr(a1)
    Orient = a1;
  else
    Margin = a1;
  end  
elseif (nargin>=2)
  Orient = a1;
  Margin = a2;
end
if nargin<3
  Fig = gcf;
end

m=Margin;
tmp = get(Fig,'PaperUnits'); set(Fig,'PaperUnits','inches')

set(Fig,'PaperType','usletter'); % just incase those crazy Eurotypes interfere

if (Orient == 'l') | (Orient == 'h')
  set(Fig,'PaperPos',[m m 11-2*m 8.5-2*m],'PaperOrient','landscape')
elseif (Orient == 'p') | (Orient == 'v')
  set(Fig,'PaperPos',[m m 8.5-2*m 11-2*m],'PaperOrient','portrait')
elseif (Orient == 's')
  set(Fig,'PaperPos',[m m+(11/5-8.5/5) 8.5-2*m 8.5-2*m],'PaperOrient','portrait')
else  
  error('Unknown orientation')
end

set(Fig,'PaperUnits',tmp); 
