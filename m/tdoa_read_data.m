## -*- octave -*-

function [err,input]=tdoa_read_data(input, dir)
  if nargin == 1
    dir = 'gnss_pos';
    printf('using default dir="gnss_pos"\n');
  end
  err = 0;
  n = numel(input);
  for i=1:n
    tic;
    [input(i).name, ...
     input(i).vname, ...
     input(i).fname, ...
     input(i).time, ...
     input(i).freq]  = parse_iq_filename(input(i).fn);
    input(i).coord   = get_coord(input(i).vname, dir);
    [x,xx,fs,gpsfix] = proc_kiwi_iq_wav(input(i).fn, 255);
    input(i).gpsfix  = gpsfix;
    input(i).use     = false;
    tmin(i)          = NaN;
    tmax(i)          = NaN;
    if gpsfix == 255
      printf('tdoa_read_data: %-40s no GPS timestamps\n', input(i).fn);
      continue
    end

    if gpsfix == 254
      printf('tdoa_read_data: %-40s no recent GPS timestamps\n', input(i).fn);
      continue
    end

    input(i).t      = cat(1,xx.t)(1000:end);
    input(i).z      = cat(1,xx.z)(1000:end);
    input(i).gpssec = cat(1,x.gpssec)+1e-9*cat(1,x.gpsnsec);
    if numel(input(i).t) == 0 || numel(input(i).gpssec) <= 2
      printf('tdoa_read_data: %-40s number of samples = %d == 0 || number of blocks = %d <= 2\n', ...
             input(i).fn, numel(input(i).t), numel(input(i).gpssec));
      continue
    end
    if max(input(i).z) == 0
      printf('tdoa_read_data: %-40s max(z)==0 %s\n', input(i).fn);
      continue;
    end
    if max(abs(diff(input(i).t))) > 2/fs
      printf('tdoa_read_data: max(abs(diff(input(i).t))) = %f > %f %s\n', ...
             input(i).fn, max(abs(diff(input(i).t))), 2/fs);
      continue
    end
    tmin(i)      = min(input(i).t);
    tmax(i)      = max(input(i).t);
    input(i).fs  = 512/mean(diff(input(i).gpssec)(2:end));
    input(i).use = true;
    printf('tdoa_read_data: %-40s %s last_gnss_fix=%3d [%.3f sec]\n', ...
           input(i).fn, input(i).name, gpsfix, toc);
  end

  ## exclude bad stations
  tmin  = tmin (vertcat(input.use));
  tmax  = tmax (vertcat(input.use));
  input = input(vertcat(input.use));
  n     = numel(input);

  ## truncate all data to the same common time interval
  t0 = max(tmin);
  t1 = min(tmax);
  for i=1:n
    b = input(i).t<t0 | input(i).t>t1;
    input(i).t(b) = [];
    input(i).z(b) = [];
    input(i).use  = numel(input(i).z)/12000 > 10;
    if ~input(i).use
      printf('tdoa_read_data: %-40s excluded (%.2f sec < %g sec overlap)\n', ...
             input(i).fn, numel(input(i).z)/12000, 10);
    end
  end
  input = input(vertcat(input.use));

  if numel(input) < 2
    printf('tdoa_read_data: n=%d < 2 good stations found\n', numel(input));
    err = 3;
    return;
  end

endfunction

# e.g. fn = '../files/02697/20180707T211018Z_77500_F1JEK-P_iq.wav'
function [name,vname,fname,time,freq]=parse_iq_filename(fn)
  [_, filename, ext] = fileparts(fn);
  if ~strcmp(ext, '.wav')
    error(sprintf('wrong extension: %s'), fn);
  end
  tokens = strsplit(filename, '_');
  if numel(tokens) < 4
    error(sprintf('malformed filename: %s'), fn);
  end
  if ~strcmp(tokens{4}, 'iq')
    error(sprintf('filename does not indicate an IQ recording: %s'), fn);
  end
  time  = tokens{1};
  freq  = 1e-3 * str2double(tokens{2});
  fname = tokens{3};
  name  = strrep(fname, '-', '/');            ## recover encoded slashes
  vname = strrep(fname, '-', '_');
end
