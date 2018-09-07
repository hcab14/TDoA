## -*- octave -*-

function [idx,xdi,eqs,c,nsigma, tdoa, input]=tdoa_verify_lags(n, tdoa, input)
  tic;
  [idx,xdi] = make_combinations(n);
  eqs       = make_equations(n, idx);

  c = cell;
  for i=1:size(idx,1)
    c{end+1} = 1:size(tdoa(idx(i,1), idx(i,2)).lags_filter, 1);
  end

  combinations = cartesianProduct(c); ## (n x size(idx,1))
  assert(size(combinations,2) == size(idx,1));

  get_comb = @(ii, i) combinations(i, xdi(ii(1), ii(2)));
  get_lags = @(ii, i) tdoa(ii(1), ii(2)).lags(tdoa(ii(1), ii(2)).lags_filter(get_comb(ii, i), :));
  sign2str = @(x) '-0+'(2+sign(x));

  nsigma   = [];
  for i=1:size(combinations,1)
    for j=1:numel(eqs)
      lags_ii = get_lags(eqs(j).ii, i);
      lags_jj = get_lags(eqs(j).jj, i);
      lags_kk = get_lags(eqs(j).kk, i);
      if ~isempty(lags_ii) && ~isempty(lags_jj) && ~isempty(lags_kk)
        nsigma(i,j) = eqs(j).sgn * [mean(lags_ii);mean(lags_jj);mean(lags_kk)] / sqrt(sum([std(lags_ii) std(lags_jj) std(lags_kk)].**2));
      else
        nsigma(i,j) = Inf;
      end
      printf('tdoa_verify_lags: comb_num=%2d nsigma(%s(%d,%d) %s(%d,%d) %s(%d,%d)) = %7.3f\n', ...
             i, ...
             sign2str(eqs(j).sgn(1)), eqs(j).ii(1), eqs(j).ii(2),
             sign2str(eqs(j).sgn(2)), eqs(j).jj(1), eqs(j).jj(2),
             sign2str(eqs(j).sgn(3)), eqs(j).kk(1), eqs(j).kk(2),
             nsigma(i,j));
    end
  end
  ##__nsigma__= nsigma

  ## find combination with minimum nsigma
  [min_max_nsigma,comb_idx] = min(max(abs(nsigma), [], 2));

  ## if necessary exclude stations
  idx_excl = [];
  if min_max_nsigma > 3.0
    c = cell;
    for i=4:n
      ## generate all permutations for excluding i-3 stations
      c{end+1} = [1:n];
      idx_excl = unique(sort(cartesianProduct(c), 2), 'rows');
      ## loop over all permutations and recompute min_max_nsigma for each of them
      for j=1:size(idx_excl,1)
        b(j,:) = delete_stations(eqs, idx_excl(j,:));
        [min_max_nsigma(j,1), comb_idx(j,1)] = min(max(abs(nsigma(:,b(j,:))), [], 2));
      end
      [min_max_nsigma, min_idx] = min(min_max_nsigma);
      comb_idx              = comb_idx(min_idx);
      idx_excl              = idx_excl(min_idx,:);
      ## stop excluding stations when min_max_nsigma < 3
      if min_max_nsigma < 3
        break
      end
    end
  end

  #combinations(comb_idx,:)
  #idx_excl
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
    input(idx_excl).use = false;
    printf('tdoa_verify_lags: exluding ');
    for i=1:numel(idx_excl)
      printf('%s(%d) ', input(idx_excl(i)).name, idx_excl(i));
    end
    printf('\n');
  end

  msg = {'OK', 'Warning: abs(nsigma)>3'};
  printf('tdoa_verify_lags: max(abs(nsigma))=%6.3f %s [%.3f sec]\n',
         min_max_nsigma, msg{1+(min_max_nsigma > 3)}, toc());
endfunction

function b=delete_stations(eqs, stn_idx)
  n = size(eqs,2);
  b = logical(zeros(1,n));
  for i=1:n
    b(i) = ~any([any(eqs(i).ii == stn_idx');
                 any(eqs(i).jj == stn_idx');
                 any(eqs(i).kk == stn_idx');]);
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

