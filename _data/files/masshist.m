function MassHist(P,PrName,Trunc,RootOGram)
% MassHist(P,PrName,Trunc,RootOGram)
% Produces a mass of histograms
%   P        - File name list
%   PrName   - Filename to print to
%   Trunc    - Percentile (e.g. 98) at which to truncate intensities
%              (default 100, i.e. none).
%   RootOGram - Plot square root counts instead of counts (default 1, yes)
%_________________________________________________________________________________
% T. Nichols 4 Feb  2015

nCol=2;
nRow=5;
nBin=50;

try, P;      catch P={};      end
try, PrName; catch PrName=''; end
try, Trunc;  catch Trunc=100; end
try, RootOGram; catch RootOGram=1; end

if isempty(P)
  P = spm_select(Inf,'image');
end
if ~iscell(P)
  P = cellstr(P);
end


clf
set(gcf,'PaperOrient','portrait',...
	'PaperType','a4')
PaperDim=get(gcf,'PaperSize');
Marg = -0.3333;
set(gcf,'PaperPos',[Marg Marg PaperDim(1)-2*Marg PaperDim(2)-2*Marg])

nImg = length(P);
Pg   = 1;

for i=1:nImg
  subplot(nRow,nCol,1+rem(i-1,nRow*nCol));

  disp(P{i})
  try,
    V = spm_vol(P{i});
    a = spm_read_vols(V);
  catch
    box on
    title([spm_str_manip(P{i},'k30') ' - NOT FOUND'],'interpreter','none','interpreter','none');
    continue
  end
  a = a(:);
  a(~isfinite(a)) = []; 
  if Trunc<100
    [~,I]=sort(a);
    Th=a(I(ceil(Trunc/100*length(a))));
    a(a>=Th)=[];
  end

  [n x] = hist(a,nBin);
  if RootOGram
    h=bar(x,sqrt(n/sum(n)/(x(2)-x(1))));
    ylabel('Sq. Rt. Rel. Freq.')
  else
    h=bar(x,n/sum(n)/(x(2)-x(1)));
    ylabel('Rel. Freq.')
  end
  set(gca,'FontSize',8,'TickDir','out')
  title(spm_str_manip(P{i},'k40'),'interpreter','none','FontName','Courier','FontSize',9);
%   mn = mean(a);
%   sd = std(a);
%   XX = min(a):((max(a)-min(a))/50):max(a);
%   hold on;
%     line(XX,spm_Npdf(XX,mn,sd),'color','red');
%   hold off
%   if ~isempty(m)
%     if iscell(m)
%       if ~isempty(m{i})
% 	abline('v',m(i))
%       end
%     else
%       abline('v',m(i))
%     end
%   end

  drawnow
  if (i==nImg || rem(i,nRow*nCol)==0)
    if isempty(PrName) 
      if i<nImg
	input('Press <RETURN> to continue');
      end
    else
      print('-dpdf',sprintf('%s_%02.pdf',PrName,Pg))
      Pg=Pg+1;
    end
  end
end



