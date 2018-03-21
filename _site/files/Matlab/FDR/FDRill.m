function FDRill(Timg,df,alpha,FDPplot)
% Show two plots illustrating the FDR threshold
% FDRill(Timg,df,alpha,FDPplot)
% Timg   - Filename of T or F statistic image
%          (If omitted, user is prompted)
% df     - Degrees of freedom; scalar for T, 2-vector for F statstic
%          If Timg isn't from SPM, df must be specified.  If df=NaN, 
%          Timg are asssumed to be p-values.
% alpha  - Level at which to control FDR (0.05 default)
% FDPplot- If 0, top plot is a histogram (default).
%          If 1, top plot is a cumulative plot, showing, for each
%          possible threshold, the observed and expected number of
%          detections and the estimated false discovery proportion (FDP).
%
% Alternate usage:  
%         FDRill('FDPplot')    or          FDRill FDPplot
% is equivalent to FDRill('',[],[],1)
%
% Top plot is a root-o-gram, a histogram where square-root counts (or
% frequency) are plotted instead of counts.  It has the effect of
% magnifying the tails relative to the rest of the distribution.
%
% The bottom plot is the log-log pp-plot that defines the Benjamini &
% Hochberg FDR rule.
%
% Works with either SPM99 or SPM2.
%
%________________________________________________________________________
% $Id: FDRill.m,v 1.12 2006/05/08 14:57:42 nichols Exp $

figure

if nargin>1 & strcmp(Timg,'FDPplot')
  Timg = '';
  FDPplot = 1;
elseif nargin<4
  FDPplot = 0;
end

% Get statistic image
if nargin<1 | isempty(Timg)
  Timg = sf_spm_get(1,'spm*img','Select Statistic Image');
end
if isstr(Timg)
  V = spm_vol(Timg);
else
  V = Timg; % OK to pass T-values directly
end


% Get DF (hopefully from image comment field)
if nargin<2 | isempty(df)
  df = sf_GetDF(V);
  if isempty(df)
    df = spm_input('Enter DF (df,[df1 df2], or 0 try SPM.mat)','+1','r');
    if (df==0)
      warning('Assuming T statistic image; manually specify DF if F image');
      SPM  = sf_spm_get(1,'SPM.mat','Select SPM.mat'); 
      SPM  = load(SPM);
      if isfield(SPM,'SPM')
	% For SPM2
	SPM = SPM.SPM;
      end
      df = SPM.xX.erdf;
      clear SPM
    end
  elseif any(isnan(df))
    df = NaN;
  end
end
if nargin<3 | isempty(alpha)
  alpha    = 0.05;
end
if nargin<4 & isempty(FDPplot)
  FDPplot = 0;
end
  

%
% Load and condition the T statistic image data
%
if isstruct(V)
  T    = spm_read_vols(V); T=T(:); T(isnan(T))=[]; T(T==0)=[];
else
  T    = V;
end

%
% Get p-values, FDR threshold
%
if length(df)>1
  Tp   = 1-spm_Fcdf(T,df);
  STAT = 'F';
elseif isnan(df)
  Tp   = T;
  T    = spm_invNcdf(1-Tp);
  STAT = 'P';
elseif isfinite(df)
  Tp   = 1-spm_Tcdf(T,df);
  STAT = 'T';
else
  Tp   = 1-spm_Ncdf(T);
  STAT = 'Z';
end
Ts   = sort(T);
Tps  = sort(Tp);
iv   = (1:length(T))/length(T);
Tpt  = myFDR(Tp,alpha);
if isempty(Tpt)
  Tpt = NaN;
  Tt = NaN;
else
  if length(df)>1
    Tt   = spm_invFcdf(1-Tpt,df);
  elseif isfinite(df)
    Tt   = spm_invTcdf(1-Tpt,df);
  else
    Tt   = spm_invNcdf(1-Tpt);
  end
end

V = length(Tps);

%
% Root-o-gram & PP plots
%
ax = []; h = [];

ax = [subplot(2,1,1) subplot(2,1,2)];
axes(ax(1));
% ax = axes('position',[ 0.13    0.64    0.80    0.28]);
[n,x]=hist(T,100);n=n/sum(n)/(x(2)-x(1)); 
if length(df)>1
  NullPDF = spm_Fpdf(x,df);
elseif isfinite(df)
  NullPDF = spm_Tpdf(x,df);
else
  NullPDF = spm_Npdf(x);
end
h = [h bar(x,sqrt(n))];
hold on; 
h = [h plot(x,sqrt(NullPDF),'color','Green','LineWidth',2)];
hold off
myabline('v',0)
myabline('v',Tt,'LineStyle','-','Color',[0.3 0.3 0.3]);
tmp = get(gca,'Ylim'); tmp = tmp(2)-diff(tmp)*0.15;
if ~isnan(Tt)
  text(Tt+.25,tmp,sprintf('%c_{FDR}=%3.3g',STAT,Tt),'color',[0.3 0.3 0.3],'FontSize', 14)
end
ylabel('Sqrt-Frequency')
if STAT=='T'
  str = sprintf('T_{%d}',df);
elseif STAT=='Z'
  str = 'Z';
elseif STAT=='F'
  str = sprintf('F_{%d,%d}',df);
elseif STAT=='P'
  str = sprintf('P-value',df);
end
title(['Null & Observed ' str ' dist^{n}s'],'FontSize',14)

if FDPplot
  %
  % Plot of emperical FDR, the estimated FDP
  %

  % First, 'background' the histogram
  ylabel('')
  set(ax(1),'Ytick',[])
  % Change histogram to light blue and gray
  % This will surely break in other old ML versions
  set(h(1),'FaceColor',[0.8 0.8 0.95],'EdgeColor',[0.8 0.8 0.8])
  for i = 2:length(h)
    set(h(i),'Color',[0.8 0.8 0.8]+get(h(i),'color')*.2)
  end

  if length(df)>1
    NullCDF = spm_Fcdf(Ts,df);
  elseif isfinite(df)
    NullCDF = spm_Tcdf(Ts,df);
  else
    NullCDF = spm_Ncdf(Ts);
  end
  nNulRej = V*flipud(Tps);
  nRej    = flipud((1:V)');
  FDPhat  = min(1,nNulRej./nRej);
  ax2 = axes('position',get(ax(1),'position'),...
		'color','none','Xtick',[]);
  h2 = semilogy(Ts,1-NullCDF,Ts,(V:-1:1)/V,Ts,FDPhat,'Linewidth',2);
  set(gca,'color','none',...
	  'Xtick',[],...
	  'Xlim',get(ax(1),'Xlim')) 
  % set(gca,'Ylim',[0 1])  % Needed if not semilog
  set(h2(1),'color','Green');
  set(h2(2),'color','Blue'); 
  set(h2(3),'color',[1 .5 0])
  ylabel('Percent')
  myabline('h',alpha,'color','red','linewidth',1,'linestyle','--')
  hl=legend('% Detected, Ho-expected',...
	    '% Detected, actual',...
	    'False Discovery Proportion');
  set(hl,'Color',[1 1 1]);
end



%ax = [ax axes('position',[  0.13    0.11    0.80    0.30])];
subplot(2,1,2)
h = [h loglog(iv,Tps,'-o')];
axis image
set(get(gca,'children'),'LineWidth',2,'MarkerSize',4)
myabline(0,1,'color','green','linestyle','-');
myabline(0,alpha,'LineStyle','--','color','red')
if ~isnan(Tpt)
  myabline('h',Tpt,'LineStyle','-','Color',[0.3 0.3 0.3]);
end
title('Ordered p-value plots - loglog','FontSize',14)
text(10^(-4.75),Tpt*4,sprintf('P_{FDR}=%3.3g',Tpt),'color',[0.3 0.3 0.3],'FontSize',14)
xlabel('index/V'); ylabel('Ordered p-value')



function [pID,pN] = myFDR(p,alpha)
% 
% p   - vector of p-values
% alpha   - False Discovery Rate level
%
% pID - p-value threshold based on independence or positive dependence
% pN  - "Nonparametric" (any covariance structure) p-value threshold
%______________________________________________________________________________
% Based on FDR.m     1.4 Tom Nichols 02/07/02


p = sort(p(:));
V = length(p);
I = (1:V)';

cVID = 1;
cVN = sum(1./(1:V));

pID = p(max(find(p<=I/V*alpha/cVID)));
pN  = p(max(find(p<=I/V*alpha/cVN)));

return


function h=myabline(b,m,varargin)
% FORMAT h = abline(b,m,...)
% Plots y=a*x+b in dotted line
%
% ...  Other graphics options
%
% Like Splus' abline
%
% To plot a horizontal line at y:    abline('h',y)   
% To plot a vertical line at x:      abline('v',x)   
%
% @(#)abline.m	1.4 02/02/13

if (nargin==2) & isstr(b)
  b = lower(b);
else

  if (nargin<1)
    b = 0;
  end
  if (nargin<2)
    m = 0;
  end
  
end

XX=get(gca,'Xlim');
YY=get(gca,'Ylim');

if isstr(b) & (b=='h')

  g=line(XX,[m m],'LineStyle',':',varargin{:});

elseif isstr(b) & (b=='v')

  g=line([m m],YY,'LineStyle',':',varargin{:});

else

  g=line(XX,m*XX+b,'LineStyle',':',varargin{:});

end

if (nargout>0)
  h=g;
end

function df = sf_GetDF(V)
%
% Infer DF from comment field of statistic image
%

if ~isstruct(V)
  df=[];
  return
end

Fdf = sscanf(V.descrip,'SPM{F_[%f,%f]}');
Tdf = sscanf(V.descrip,'SPM{T_[%f]}');

if (length(Fdf) == 2)
  df = Fdf';
elseif (length(Tdf)==1)
  df = Tdf;
else
  df = [];
end

return

function P = sf_spm_get(n,wildcard,prompt)
switch spm('ver')
 case 'SPM99'
  P = spm_get(n,wildcard,prompt);
 case 'SPM2'
  if max(findstr(wildcard,'*img')) == length(wildcard)-length('*img')+1
    wildcard = [wildcard(1:end-4) '*IMAGE'];
  end
  P = spm_get(n,wildcard,prompt);
 case {'SPM5','SPM8'}
  wildcard = strrep(wildcard,'*','.*');
  P = spm_select(n,'image',prompt,'',pwd,wildcard);
end

