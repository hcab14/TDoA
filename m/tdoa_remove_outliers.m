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
    b           &= abs(lags - mean_lags(i)) < 3*std_lags(i);
    if i>1 && diff(std_lags)(end) == 0
      break
    end
  end
  ##[mean_lags' std_lags']

  ## 3rd step: check if there are two components
  try
    ## start
    m0(1) = mean([min(lags(b)) max(lags(b))]);

    ## iteratively adjust the cut value m0
    for i=2:5
      cut(i,1,:) = b & (lags  > m0(i-1));
      cut(i,2,:) = b & (lags <= m0(i-1));

      m(i,1) = mean(lags(cut(i,1,:)));
      m(i,2) = mean(lags(cut(i,2,:)));
      m0(i) = mean(m(i,:))
      if m0(i) == m0(i-1)
        break;
      end
    end
    s1 = std(lags(cut(end,1,:)));
    s2 = std(lags(cut(end,2,:)));

    ## if the two components are >2.5 sigma different choose the one with more measurements
    if abs(diff(m(end,:)))/sqrt(s1**2+s2**2) > 2.5
      idx = 1 + (sum(cut(end,1,:)) < sum(cut(end,2,:)));
      b = cut(end,idx,:);
    end
  end
endfunction
