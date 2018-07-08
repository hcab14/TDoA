## -*- octave -*-

function [lag,peak]=tdoa_peak_fn_pol2fit(t, y)
  ## least-squares pol2 peak estimator
  time_scale = 1e3; # avoid loss of precision
  m   = [];
  for k=1:length(y)
    m(k,1:3) = (time_scale*(t(k)-t(1))).**[0 1 2];
  end
  x    = inv(m'*m)*m'*y; ## least squares
  if abs(x(3)) < 1e-10
    dt = 0;
  else
    dt   = -x(2)/2/x(3);
  end
  lag  = t(1) + dt/time_scale;
  peak = sum(x.*dt.**[0 1 2]);
endfunction
