## -*- octave -*-

function b = tdoa_remove_outliers(b, lags)
  ## 1st step: cut on the deviation from the median
  _lags  = lags(b);
  if isempty(_lags)
    return
  end
  b     &= abs(lags - median(_lags)) < 1e-3;

  ## 2nd step: remove outliers iteratively cutting on 3*std
  std_lags  = [];
  mean_lags = [];
  for i=1:10
    _lags        = lags(b);
    if isempty(_lags)
      return
    end
    mean_lags(i) = mean(_lags);
    std_lags(i)  = std(_lags);
    b           &= abs(lags - mean_lags(i)) < 2*std_lags(i);
    if i>1 && diff(std_lags)(end) == 0
      break
    end
  end
  ##[mean_lags' std_lags']
endfunction
