## -*- octave -*-

function d=kiwi_info()
  [_,a]=system('cat gnss_pos/*.txt');
  eval(a);
end

