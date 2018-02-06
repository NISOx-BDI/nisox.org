function SPMsel(ver)
%
% Change SPM path.  Removes current SPM paths and adds desired version 
%
if ~isstr(ver), ver=num2str(ver); end

%
% Edit paths below before using!!
%
SPMdir{99} = {...
    % Add any other SPM99-specific paths here
    '/my/path/to/spm/spm99',...
    };
SPMdir{2} = {...
    % Add any other SPM2-specific paths here
    '/my/path/to/spm/spm2',...
    };
SPMdir{5} = {...
    % Add any other SPM5-specific paths here
    '/my/path/to/spm/spm5',...
    };

warning('All local and global variables cleared');
clear all

% 
% Turn off warnings
%
tmp = version;
if (tmp(1) == '6')
  Rest = warning('off','MATLAB:rmpath:DirNotFound');
else
  warning off
end

%
% Change paths
%
switch ver
 case '99'
  
  MyRm(SPMdir{2})
  MyRm(SPMdir{5})
  MyAdd(SPMdir{99})

 case '2'

  MyRm(SPMdir{99})
  MyRm(SPMdir{5})
  MyAdd(SPMdir{2})

 case '5'

  MyRm(SPMdir{99})
  MyRm(SPMdir{2})
  MyAdd(SPMdir{5})

otherwise
  error(['Unknown SPM version:' ver])
end

%
% Reset warnings
%
if (tmp(1) == '6')
  warning(Rest)
else
  warning on
end


return

function MyRm(cp)
  for i=1:length(cp)
    rmpath(cp{i})
  end
return

function MyAdd(cp)
  for i=1:length(cp)
    addpath(cp{i})
  end
return

