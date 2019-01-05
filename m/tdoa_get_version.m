## -*- octave -*-

function version=tdoa_get_version
  [version.TDoA, status] = get_version_from_git();
  if status != 0
    version = load(fullfile('mat','version.mat')).v;
  end
  version.octave = OCTAVE_VERSION;
endfunction

function [v,status]=get_version_from_git
  [status,git.branch] = system('git symbolic-ref -q --short HEAD');
  if status != 0
    v = struct;
    return
  end
  [status,git.hash] = system('git rev-parse --short HEAD;');
  [status,git.tag]  = system('git describe HEAD 2>>/dev/null'); ## --tags --exact-match
  if status != 0
    git.tag = sprintf('none-g%s', git.hash(1:end-1));
  end
  v.branch = git.branch(1:end-1);
  v.hash   = git.hash(1:end-1);
  v.tag    = git.tag(1:end-1);
endfunction
