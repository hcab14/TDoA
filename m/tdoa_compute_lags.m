## -*- octave -*-

function [tdoa,status]=tdoa_compute_lags(input, peak_search)
  counter = 1;
  n = length(input);
  for i=1:n
    for j=i+1:n
      tic;
      [tdoa(i,j).lags, tdoa(i,j).peaks, tdoa(i,j).t, tdoa(i,j).r, tdoa(i,j).gpssec] = ...
      compute_lag(input(i).t, input(i).z, input(i).fs,
                  input(j).t, input(j).z, input(j).fs,
                  peak_search);
      tdoa(i,j).range       = peak_search.range;
      tdoa(i,j).lags_filter = ~isnan(tdoa(i,j).lags);
      if peak_search.remove_outliers
        tdoa(i,j).lags_filter = tdoa_remove_outliers(tdoa(i,j).lags_filter, tdoa(i,j).lags, 3, 1e-3, 0);
        lags_filtered         = tdoa(i,j).lags(tdoa(i,j).lags_filter);
	status.per_pair(counter).cls.dt_usec     = 1e6*mean(lags_filtered);
	status.per_pair(counter).cls.rms_dt_usec = 1e6*std(lags_filtered);
      end
      status.per_pair(counter).idx      = [i j];
      status.per_pair(counter).time_sec = toc();
      printf("tdoa_compute_lags(%d,%d): [%.3f sec]\n", i,j, status.per_pair(counter).time_sec);
      counter += 1;
    end
  end
endfunction

function [lags,peaks,ts,rs,gpssec]=compute_lag(t1,z1,fs1, t2,z2,fs2, peak_search)
  dt     = peak_search.dt;
  dk     = peak_search.dk;
  lags   = [];
  peaks  = [];
  ts     = {};
  rs     = {};
  gpssec = [];
  for i=1:dt:min(length(z1), length(z2))-dt
    [r,lag] = xcorr(z1(i:i+dt), z2(i:i+dt), 2*dt, 'coeff');
    ar      = abs(r);
    t       = t1(i+dt)-t2(i+dt) + lag/mean([fs1 fs2]);
    idx     = find(abs(t) < peak_search.range);
    if isempty(idx)
      continue
    end
    [peaks(end+1),j] = max(ar(idx));
    j               += idx(1)-1;

    time_of_lag = peak_search.fn(t(j+dk), ar(j+dk));

    ## fprintf(stdout, 'lag: %5d %12.6f [%f %f %f]\n', lag(j), time_of_lag, ar(j-1:j+1)/(1e-10 + ar(j)));
    ## fflush(stdout);
    lags(end+1) = time_of_lag;

    ts{end+1}     = t(idx);
    rs{end+1}     = r(idx);
    gpssec(end+1) = mean([t1(i+dt), t2(i+dt)]);
  end
endfunction
