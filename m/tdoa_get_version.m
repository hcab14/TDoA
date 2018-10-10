## -*- octave -*-

function version=tdoa_get_version
  [status,git.branch] = system('git symbolic-ref -q --short HEAD');
  [status,git.hash]   = system('git rev-parse --short HEAD;');
  [status,git.tag]    = system('git describe HEAD 2>>/dev/null'); ## --tags --exact-match
  if status != 0
    git.tag = sprintf('none-g%s', git.hash(1:end-1));
  end
  version.TDoA.branch = git.branch(1:end-1);
  version.TDoA.hash   = git.hash(1:end-1);
  version.TDoA.tag    = git.tag(1:end-1);
  version.octave      = OCTAVE_VERSION;
endfunction
