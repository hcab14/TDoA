## -*- octave -*-

function input=tdoa_read_data(input)
  n = length(input);
  for i=1:n
    [name,time,freq] = parse_iq_filename(input(i).fn);
    input(i).name    = name;
    input(i).time    = time;
    input(i).freq    = freq;
    input(i).coord   = get_coord(input(i).name);
    [x,xx,fs,gpsfix] = proc_kiwi_iq_wav(input(i).fn, 255);
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

function [name,time,freq]=parse_iq_filename(fn)
  [dir, filename, ext] = fileparts(fn);
  if ~strcmp(ext, '.wav')
    error(sprintf('wrong extension: %s'), fn);
  end
  tokens = strsplit(filename, '_');
  if length(tokens) < 4
    error(sprintf('malformed filename: %s'), fn);
  end
  if ~strcmp(tokens{4}, 'iq')
    error(sprintf('filename does not indicate an IQ recording: %s'), fn);
  end
  time = tokens{1};
  freq = 1e-3 * str2double(tokens{2});
  name = tokens{3};
end
