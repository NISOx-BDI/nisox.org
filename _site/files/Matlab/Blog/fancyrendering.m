function fancy_rendering(arg1)
% Does fancy rendering of intensities of one brain superimposed
% on surface of another
if nargin == 0,
        initialise_rendering;
else,
        if strcmp(lower(arg1),'relight'),
                relight;
        end;
end;
return;

function relight
ax = findobj(0,'Tag','rendering');
l  = findobj(get(ax,'Children'), 'Type', 'light');
delete(l);
l  = camlight(-20, 10);
return;


function initialise_rendering
FV     = load(spm_get(1,'surf_*.mat','Select surface data'));
V      = spm_vol(spm_get(1,'*.img','Select image'));
col    = ones(size(FV.vertices))*0.8;
tmp    = inv(V.mat);
xyz    = (tmp(1:3,:)*[FV.vertices' ; ones(1, size(FV.vertices,1))])';
t      = spm_sample_vol(V, xyz(:,1), xyz(:,2), xyz(:,3), 1);
msk    = find(~finite(t) | t<0);
t(msk) = 0;
mx     = max([eps max(t)]);
colour = [1 0 0];
tmp    = [t*(colour(1)/mx) t*(colour(2)/mx) t*(colour(3)/mx)];
col    = repmat((1-t/mx),[1 3]).*col + tmp;

fg    = spm_figure('GetWin','Graphics');
spm_results_ui('Clear',fg);
ax    = axes('Parent',fg,'Clipping','off','tag','rendering');
p     = patch(FV, 'Parent',ax,...
       'FaceColor', 'interp', 'FaceVertexCData', col,...
       'EdgeColor', 'none',...
       'FaceLighting', 'phong',...
       'SpecularStrength' ,0.7, 'AmbientStrength', 0.1,...
       'DiffuseStrength', 0.7, 'SpecularExponent', 10);
set(0,'CurrentFigure',fg);
set(fg,'CurrentAxes',ax);
l     = camlight(-40, 20);
axis image off;
box on;
rotate3d off;
rotate3d on;
return;
