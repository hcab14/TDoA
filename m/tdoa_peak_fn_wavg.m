## -*- octave -*-

function [lag,peak]=tdoa_peak_fn_wavg(t, y)
  ## weighted average peak estimator
  ts   = reshape(t-t(1), size(y));
  lag  = t(1) + sum(y.*ts)/sum(y);
  peak = max(y);
endfunction
