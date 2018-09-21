## -*- octave -*-

function [b,mean_lags,std_lags,fraction,mean_prob]=tdoa_remove_outliers(b, lags, nsigma, max_dist_median, range)
  mean_lags = 0;
  std_lags  = Inf;
  fraction  = 0;
  mean_prob = 0;
  if sum(b) < 2
    return
  end

  frange = @(x) diff([min(x) max(x)]);

  datapoints_before = sum(b);
  interval_before   = range;

  ## 1st step: cut on the deviation from the median
  b &= abs(lags-median(lags(b))) < max_dist_median;
  if sum(b) < 2
    return
  end

  ## 2nd step: remove outliers iteratively cutting on nsigma*std
  mean_lags(1) = mean(lags(b));
  std_lags(1)  = std (lags(b));

  for i=2:20
    b &= abs(lags - mean_lags(i-1)) < nsigma*std_lags(i-1);
    mean_lags(i) = mean(lags(b));
    std_lags(i)  = std (lags(b));
    if abs(mean_lags(i)-mean_lags(i-1)) < 1e-12
      break
    end
  end
  mean_lags = mean_lags(end);
  std_lags  = std_lags(end);
  if range > 0
    mean_prob = frange(lags(b))/interval_before;
    fraction  = sum(b)/datapoints_before;
  end
endfunction
