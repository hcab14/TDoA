## -*- octave -*-

function [tdoa,status]=tdoa_compute_lags_new(input)
  counter = 1;
  n = length(input);
  for i=1:n
    for j=i+1:n
      tic;
      [tdoa(i,j).lags, tdoa(i,j).sigma2] = ...
      compute_lag(input(i).t, input(i).z, input(i).fs,
                  input(j).t, input(j).z, input(j).fs);
      status.per_pair(counter).idx      = [i j];
      status.per_pair(counter).time_sec = toc();
      printf("tdoa_compute_lags(%d,%d): [%.3f sec]\n", i,j, status.per_pair(counter).time_sec);
      counter += 1;
    end
  end
endfunction

function [lags,sigma2]=compute_lag(t1,z1,fs1, t2,z2,fs2)
  [r,lags] = xcorr(z1, z2, round(6371e3*pi/fs1));
  m        = 1:round(fs1):min(numel(t1),numel(t2));
  dt(2,:)  = t1(m);
  dt(1,:)  = t2(m);
  lags     = mean(diff(dt)) + lags/mean([fs1 fs2]);
  r       /= max(abs(r));
  sigma2   = -2*log(abs(r));
endfunction
