## -*- octave -*-

function tdoa=tdoa_cluster_lags(plot_info, tdoa, input)
  status_json   = '  "cross-correlations": {\n    "clusters": [\n';
  json_line_end = [",", " "];

  n      = length(input);
  n_comb = 1;
  for i=1:n
    for j=i+1:n
      tic;
      [tdoa(i,j).cl,tdoa(i,j).lags_filter] = tdoa_cluster_lags_(ones(size(tdoa(i,j).gpssec))==1, ...
                                                                tdoa(i,j).lags, tdoa(i,j).range);
      printf('tdoa_cluster_lags(%d,%d): num_clusters=%d [%.3f sec]\n', ...
             i,j, size(tdoa(i,j).lags_filter, 1), toc());
      n_comb *= size(tdoa(i,j).lags_filter,1);
      status_json = [status_json sprintf('      {"idx":[%d,%d], "cls": [', i,j)];
      m = size(tdoa(i,j).lags_filter, 1);
      for k=1:m
        lags = tdoa(i,j).lags(tdoa(i,j).lags_filter(k,:));
        if isempty(lags)
          dt_usec     = 0;
          rms_dt_usec = Inf;
        else
          dt_usec     = 1e6*mean(lags);
          rms_dt_usec = 1e6*std(lags);
        end
        status_json = [status_json sprintf('{"dt_usec":%f, "rms_dt_usec":%f}%s', ...
                                           dt_usec, rms_dt_usec, json_line_end(1+(k==m)))];
      end
      status_json = [status_json sprintf(']}%s\n', json_line_end(1+(i==j-1 && j==n)))];
    end
  end
  printf('tdoa_cluster_lags: n_comb=%d\n', n_comb);
  status_json = [status_json sprintf('    ],\n    "n_comb": %d\n  },\n', n_comb)];
  plot_info.save_json(plot_info, 'status.json', 'a', status_json);
endfunction

function [cl,b,nsigma]=tdoa_cluster_lags_(b, lags, range)
  for ncls=4:-1:2
    [cl,cl_b,nsigma]=tdoa_cluster_lags_single(b, lags, ncls, range);
    ##nsigma
    ##[vertcat(cl.mean) vertcat(cl.std)  vertcat(cl.fraction)./vertcat(cl.mean_prob)]
    if all(nsigma > 2.5) && all(vertcat(cl.fraction)./vertcat(cl.mean_prob) > 2) && all(vertcat(cl.std) < 1e-3)
      b = cl_b;
      return
    end
  end
  cl     = struct;
  nsigma = NaN;
  [b,cl.mean,cl.std,cl.fraction,cl.mean_prob] = tdoa_remove_outliers(b, lags, 3, 1e-3, 2*range);
  ##[vertcat(cl.mean) vertcat(cl.std)  vertcat(cl.fraction)./vertcat(cl.mean_prob)]
  if cl.mean_prob == 0 || cl.fraction/cl.mean_prob < 2
    b(1:end) = false;
    cl.std   = Inf;
  end
endfunction

function [cl,b,nsigma]=tdoa_cluster_lags_single(b, lags, ncls, range)
  cl_boundaries  (1,1:ncls+1) = [-range linspace(min(lags(b)), max(lags(b)), ncls+1)(2:ncls) range];
  cl_boundaries_use(1:ncls+1) = true;

  for i=2:20
    for j=1:ncls
      cut(i,j,:) = b & (lags >= cl_boundaries(i-1,j)) & (lags < cl_boundaries(i-1,j+1));
    end

    for j=1:ncls
      cl_use(j) = sum(cut(i,j,:)) >= 2;
      if cl_use(j)
        cl_centers(i,j) = median(lags(cut(i,j,:)));
      else
        cl_centers(i,j) = 0;
      end
    end

    cl_boundaries(i,1)      = cl_boundaries(i-1,1);
    cl_boundaries(i,ncls+1) = cl_boundaries(i-1,ncls+1);
    for j=2:ncls
      cl_boundaries(i,j) = mean(cl_centers(i,j+[-1:0]));
    end
    cl_boundaries_use(i,2:end-1) = cl_use(1:ncls-1) & cl_use(2:ncls);
    do_compare = cl_boundaries_use(i,:) & cl_boundaries_use(i-1,:);
    if max(abs(cl_boundaries(i,do_compare) - cl_boundaries(i-1,do_compare))) < 1e-7
      break
    end
  end
  ##cl_boundaries

  cl = struct;
  for j=1:ncls
    b = reshape(cut(end,j,:), size(lags));
    [b,cl(j).mean,cl(j).std] = tdoa_remove_outliers(b, lags, 3, 1, -1);
  end
  nsigma = abs(diff(horzcat(cl.mean))) ./ sqrt(horzcat(cl.std)(1:end-1).**2 + horzcat(cl.std)(2:end).**2);
  b      = squeeze(cut(end,:,:));

  for j=1:ncls
    cl_range = cl_boundaries(end,j+1) - cl_boundaries(end,j);
    [b(j,:),cl(j).mean,cl(j).std,cl(j).fraction,cl(j).mean_prob] = ...
    tdoa_remove_outliers(reshape(cut(end,j,:), size(lags)), lags, 3, 1e-3, cl_range);
  end
endfunction
