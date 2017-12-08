## -*- octave -*-

function input=tdoa_read_data(input)
  n = length(input);
  for i=1:n
    input(i).name    = get_name(input(i).fn);
    input(i).coord   = get_coord(input(i).name);
    [x,xx,fs,gpsfix] = proc(input(i).fn, 255);
    input(i).t       = cat(1,xx.t)(1000:end);
    tmin(i)          = min(input(i).t);
    tmax(i)          = max(input(i).t);
    input(i).z       = cat(1,xx.z)(1000:end);
    input(i).gpssec  = cat(1,x.gpssec)+1e-9*cat(1,x.gpsnsec);
    input(i).fs      = 512/mean(diff(input(i).gpssec)(2:end));
    printf('%-40s %3d\n', input(i).fn, gpsfix);
  end
  t0 = max(tmin);
  t1 = min(tmax);
  for i=1:n
    b = input(i).t<t0 | input(i).t>t1;
    input(i).t(b) = [];
    input(i).z(b) = [];
  end
endfunction

function name=get_name(fn)
  ## fn='iq/20171206T201521Z_5613000_iqG8JNJ.wav'
  fn   = fn(3:end);                     ## remove trailing 'iq/'
  name = fn(strfind(fn, 'iq')+2:end-4); ## extract name
  if name(1) == '_'
    name(1) = [];
  end
end
