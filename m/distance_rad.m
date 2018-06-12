## -*- octave -*-

function d=distance_rad(ll1, ll2)
  if size(ll1,2) != 2 || size(ll2,2) != 2
    error('size(ll1,2) != 2 || size(ll2,2) != 2');
  end
  a = ll2xyz(ll1);
  b = ll2xyz(ll2);
  if size(a,1) == 1 && size(b,1) != 1
    a = ones(size(b,1),1) * a;
  end
  if size(b,1) == 1 && size(a,1) != 1
    b = ones(size(a,1),1) * b;
  end
  d = safe_acos(dot(a,b,2));
endfunction

function y=safe_acos(x)
  b    = abs(x) > 1;
  x(b) = sign(x(b));
  y    = acos(x);
endfunction
