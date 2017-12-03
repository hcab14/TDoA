## -*- octave -*-

function tdoa=tdoa_compute_lags(input, peak_search)
  n = length(input);
  for i=1:n
    for j=i+1:n
      [tdoa(i,j).lags, tdoa(i,j).peaks] = compute_lag(input(i).t, input(i).z, input(i).fs,
                                                      input(j).t, input(j).z, input(j).fs,
                                                      peak_search);
    end
  end
endfunction

function [lags,peaks]=compute_lag(t1,z1,fs1, t2,z2,fs2, peak_search)
  dt     = peak_search.dt;
  dk     = peak_search.dk;
  lags  = [];
  peaks = [];
  for i=1:dt:min(length(z1), length(z2))-dt
    [r,lag] = xcorr(z1(i:i+dt), z2(i:i+dt), 2*12000, 'unbiased');
    ar      = abs(r);
    t       = t1(i+12000)-t2(i+12000) + lag/mean([fs1 fs2]);
    idx     = find(abs(t) < peak_search.range);

    [peaks(end+1),j] = max(ar(idx));
    j               += idx(1)-1;

    time_of_lag = peak_search.fn(t(j+dk), ar(j+dk));

    printf('lag: %5d %12.6f [%f %f %f]\n', lag(j), time_of_lag, ar(j-1:j+1)/ar(j));
    lags(end+1) = time_of_lag;
  end
endfunction
