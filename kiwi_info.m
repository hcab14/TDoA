## -*- octave -*-

function d=kiwi_info(dir)
  [_,a]=system(sprintf('cat %s/*.txt', dir));
  #printf('kiwi_info: %s\n', a);
  eval(a);
end
