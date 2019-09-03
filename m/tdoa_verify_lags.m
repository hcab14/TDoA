## -*- octave -*-

function [tdoa,input,status,idx,xdi,eqs,c,nsigma]=tdoa_verify_lags(plot_info, tdoa, input)
  tic;
  n = numel(input);
  if n < 3
    ## select the cluster with the most entries
    [_,idx_min] = min(vertcat(tdoa(1,2).cl.std));
    tdoa(1,2).lags_filter = tdoa(1,2).lags_filter(idx_min,:);
    printf('tdoa_verify_lags: [%.3f sec]\n', toc());
    status.status = 'OK';
    status.message = 'no constraits for 2 stations';
    return
  end

  [idx,xdi]    = make_combinations(n);
  [eqs,eqs_id] = make_equations(n, idx);

  c = cell;
  for i=1:size(idx,1)
    c{end+1} = 1:size(tdoa(idx(i,1), idx(i,2)).lags_filter, 1);
  end

  combinations = cartesianProduct(c); ## (n x size(idx,1))
  assert(size(combinations,2) == size(idx,1));

  sign2str  = @(x) '-0+'(2+sign(x));
  get_comb  = @(ii, i) combinations(i, xdi(ii(1), ii(2)));
  get_cl_ii = @(j,comb_idx) tdoa(eqs(j).ii(1), eqs(j).ii(2)).cl(get_comb(eqs(j).ii, comb_idx));
  get_cl_jj = @(j,comb_idx) tdoa(eqs(j).jj(1), eqs(j).jj(2)).cl(get_comb(eqs(j).jj, comb_idx));
  get_cl_kk = @(j,comb_idx) tdoa(eqs(j).kk(1), eqs(j).kk(2)).cl(get_comb(eqs(j).kk, comb_idx));

  nsigma   = zeros(size(combinations,1), numel(eqs), 'single');
  for j=1:numel(eqs)
    comb_idx  = [xdi(eqs(j).ii(1), eqs(j).ii(2)), ...
                 xdi(eqs(j).jj(1), eqs(j).jj(2)), ...
                 xdi(eqs(j).kk(1), eqs(j).kk(2))];
    [_,ci,cj] = unique(combinations(:, comb_idx), 'rows');
    _nsigma   = zeros(numel(ci),1);
    for k=1:numel(ci)
      ## ci(k) -> comb_idx
      comb_idx = ci(k);
      cls_mean = [get_cl_ii(j,comb_idx).mean; get_cl_jj(j,comb_idx).mean; get_cl_kk(j,comb_idx).mean];
      cls_std  = [get_cl_ii(j,comb_idx).std   get_cl_jj(j,comb_idx).std   get_cl_kk(j,comb_idx).std ];
      if max(cls_std) != Inf
        _nsigma(k) = eqs(j).sgn * cls_mean / sqrt(sum(cls_std.**2));
      else
        _nsigma(k) = Inf;
      end
      printf('tdoa_verify_lags: comb_num=%2d nsigma(%s(%d,%d) %s(%d,%d) %s(%d,%d)) = %7.3f\n', ...
             i, ...
             sign2str(eqs(j).sgn(1)), eqs(j).ii(1), eqs(j).ii(2),
             sign2str(eqs(j).sgn(2)), eqs(j).jj(1), eqs(j).jj(2),
             sign2str(eqs(j).sgn(3)), eqs(j).kk(1), eqs(j).kk(2),
             _nsigma(k));
    end
    ## inject _nsigma -> nsigma (see the call to 'unique' above)
    nsigma(:,j) = _nsigma(cj);
  end

  ## find combination with minimum sum(nsigma**2)
  [comb_idx, max_nsigma, sum_nsigma2] = find_min_nsigma(tdoa, input, idx, xdi, combinations, nsigma);

  ## if necessary exclude stations
  ndf      = size(nsigma,2);
  idx_excl = [];
  if max_nsigma > 3
    c = cell;
    for i=4:n
      ## generate all permutations for excluding i-3 stations
      c{end+1} = [1:n];
      idx_excl = unique(sort(cartesianProduct(c), 2), 'rows');
      ## loop over all permutations and recompute max_nsigma for each of them
      for j=1:size(idx_excl,1)
        b(j,:) = delete_stations(eqs, idx_excl(j,:));
        [comb_idx(j,1), max_nsigma(j,1), sum_nsigma2(j,1)] = find_min_nsigma(tdoa, input, idx, xdi, combinations, nsigma(:, b(j,:)));
      end
      [max_nsigma, min_idx] = min(max_nsigma);
      sum_nsigma2           = sum_nsigma2(min_idx);
      comb_idx              = comb_idx(min_idx);
      idx_excl              = idx_excl(min_idx,:);
      ndf                   = sum(b(min_idx,:));
      ## stop excluding stations when min_max_nsigma < 3
      if max_nsigma < 3
        break
      end
    end
  end

  ##combinations(comb_idx,:)
  m = numel(eqs);
  for j=1:m
    cls_mean = [get_cl_ii(j,comb_idx).mean; get_cl_jj(j,comb_idx).mean; get_cl_kk(j,comb_idx).mean];
    cls_std  = [get_cl_ii(j,comb_idx).std   get_cl_jj(j,comb_idx).std   get_cl_kk(j,comb_idx).std];

    dt_usec     = 1e6*[-1 +1 -1]*cls_mean;
    err_dt_usec = 1e6*sqrt(sum(cls_std.**2));
    printf('test1 %3d: (%d,%d) (%d,%d) (%d,%d) [%+f,%+f,%+f] %+f %+f\n', ...
           j, eqs(j).ii, eqs(j).jj, eqs(j).kk, cls_mean, dt_usec, dt_usec/err_dt_usec);
    status.equations(j).status = 'OK';
    if ~isempty(idx_excl) && any(any([eqs(j).ii eqs(j).jj, eqs(j).kk] == idx_excl'))
      status.equations(j).status = 'excluded';
    end
    status.equations(j).idx         = [eqs(j).ii eqs(j).jj(2)];
    status.equations(j).dt_usec     = dt_usec;
    status.equations(j).rms_dt_usec = err_dt_usec;
    status.equations(j).nsigma      = dt_usec/err_dt_usec;
  end

  ## prune lags_filter
  for i=1:size(idx,1)
    b = tdoa(idx(i,1), idx(i,2)).lags_filter;
    if ~isempty(idx_excl) && any(any(idx(i,:) == idx_excl'))
      tdoa(idx(i,1), idx(i,2)).lags_filter = logical(zeros(size(b(1,:)))); ## all false
    else
      tdoa(idx(i,1), idx(i,2)).lags_filter = b(combinations(comb_idx,i), :);
    end
  end

  if ~isempty(idx_excl)
    printf('tdoa_verify_lags: exluding ');
    for i=1:numel(idx_excl)
      input(idx_excl(i)).use = false;
      printf('%s(%d) ', input(idx_excl(i)).name, idx_excl(i));
      status.excluded(i).idx  = idx_excl(i);
      status.excluded(i).name = input(idx_excl(i)).name;
    end
    printf('\n');
  end

  msg = {'OK', 'Warning'};
  printf('tdoa_verify_lags: max(abs(nsigma))=%6.3f chi2/ndf=%.3f/%d=%6.3f %s [%.3f sec]\n',
         max_nsigma, sum_nsigma2,ndf, sum_nsigma2/ndf, msg{1+(max_nsigma > 3)}, toc());
  status.status = 'OK';
  status.message = '';
  if max_nsigma > 3
    status.status = 'Warning';
    status.message = 'abs(nsigma)>3';
  end
  status.detail.max_abs_nsigma = max_nsigma;
  status.detail.chi2 = sum_nsigma2;
  status.detail.ndf = ndf;
  status.detail.chi2_ndf = sum_nsigma2/ndf;
endfunction

function [comb_idx,max_nsigma,sum_nsigma2]=find_min_nsigma(tdoa, input, idx, xdi, combinations, nsigma)
  [sum_nsigma2,nsigma_idx]   = sort(sum(nsigma.**2, 2));
  [sum_nsigma2_unique,ii,jj] = unique(sum_nsigma2);
  n_sum = size(nsigma, 2);
  b     = sum_nsigma2_unique/n_sum < 3;
  ## __find_min_nsigma = sum(b)
  ## __xx = sum_nsigma2_unique(1:min(numel(sum_nsigma2_unique),10))'/n_sum
  ## when there is more than one solution with chi2/ndf < 3 select the one with maximum overlap
  if any(b)
    sum_nsigma2 = sum_nsigma2_unique(b);
    metric      = zeros(size(sum_nsigma2));
    for i=1:numel(sum_nsigma2)
      comb_idx = nsigma_idx(ii)(b)(i); # assert(sum_nsigma2(i) == sum(nsigma(comb_idx,:).**2))
      bf       = [];
      for j=1:size(idx,1)
        k = idx(j,1);
        l = idx(j,2);
        if ~all([input(k).use input(l).use])
          continue;
        end
        if isempty(bf)
          bf  = tdoa(k,l).lags_filter(combinations(comb_idx,xdi(k,l)), :);
        else
          bf &= tdoa(k,l).lags_filter(combinations(comb_idx,xdi(k,l)), :);
        end
      end
      metric(i) = sum(bf);
    end
    ##__metric = metric'
    [max_metric,idx_max] = max(metric);
    comb_idx = nsigma_idx(ii)(b)(idx_max);
  else
    idx_max  = 1;
    comb_idx = nsigma_idx(ii)(idx_max);
  end
  max_nsigma  = max(abs(nsigma(comb_idx,:)));
  sum_nsigma2 = sum_nsigma2(idx_max);
endfunction

function b=delete_stations(eqs, stn_idx)
  n = size(eqs,2);
  b = logical(zeros(1,n));
  for i=1:n
    b(i) = ~any([any(any(eqs(i).ii == stn_idx'))
                 any(any(eqs(i).jj == stn_idx'))
                 any(any(eqs(i).kk == stn_idx'))]);
  end
endfunction

function [idx,xdi]=make_combinations(n)
  idx = []; ## counter -> (i,j)
  xdi = []; ## (i,j) -> counter
  for i=1:n
    for j=i+1:n
      idx(end+1,1:2) = [i,j];
      xdi(i,j)       = size(idx,1);
    end
  end
endfunction

function [equations,equation_ids]=make_equations(n, idx)
  m            = size(idx,1);
  sign2str     = @(x) '-0+'(2+sign(x));
  ## interpret combinations as 2-digit base-n numbers
  comb_id      = @(i) (i-1)*[n;1]; ## maximum is (n-1)*(n+1) = n**2-1
  ## interpret equations as 3-digit base-(n^2-1) numbers
  equation_id  = @(ii,jj,kk) sort([comb_id(ii) comb_id(jj) comb_id(kk)]) * (n**2-1).**[2;1;0];
  equations    = struct;
  eq_counter   = 1;
  equation_ids = [];
  for i=1:m
    ii = idx(i,:);
    for j=i+1:m
      jj = idx(j,:);
      if ii(1) == jj(1)     ## -(Z,x)+(Z,y)=(x,y) (after pruning only this combination is used)
        kk  = [ii(2) jj(2)];
        sgn = [-1 +1 -1];
      elseif ii(2) == jj(2) ## +(x,Z)-(y,Z)=(x,y)
        kk  = [ii(1) jj(1)];
        sgn = [+1 -1 -1];
      elseif ii(1) == jj(2) ## -(Z,x)-(y,Z)=(x,y)
        kk  = [ii(2) jj(1)];
        sgn = [-1 -1 -1];
      elseif ii(2) == jj(1) ## +(x,Z)+(Z,y)=(x,y)
        kk  = [ii(1) jj(2)];
        sgn = [+1 +1 -1];
      else
        continue;
      end
      eq_id_new = equation_id(ii,jj,kk);
      ## the following makes sure that only independent equations are generated
      if isempty(find(eq_id_new == equation_ids))
        ##printf('%s(%d,%d) %s(%d,%d) = (%d,%d) | %4d\n', sign2str(sgn(1)),ii,sign2str(sgn(2)),jj,kk, eq_id_new);
        equation_ids(end+1)       = eq_id_new;
        equations(eq_counter).ii  = ii;
        equations(eq_counter).jj  = jj;
        equations(eq_counter).kk  = kk;
        equations(eq_counter).sgn = sgn;
        eq_counter += 1;
      end
    end
  end
endfunction

## taken from https://stackoverflow.com/questions/4165859/generate-all-possible-combinations-of-the-elements-of-some-vectors-cartesian-pr
function result=cartesianProduct(sets)
  N      = numel(sets);
  v      = cell(N,1);
  [v{:}] = ndgrid(sets{:});
  result = reshape(cat(N+1, v{:}), [], N);
end
