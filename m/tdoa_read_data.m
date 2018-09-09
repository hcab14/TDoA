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

    if gpsfix == 255
      printf('no GPS timestamps: %s\n', input(i).fn);
      err = 3;
      return
    end

    if gpsfix == 254
      printf('no recent GPS timestamps: %s\n', input(i).fn);
      err = 4;
      return
    end

    input(i).use     = true;
    input(i).t       = cat(1,xx.t)(1000:end);
    tmin(i)          = min(input(i).t);
    tmax(i)          = max(input(i).t);
    input(i).z       = cat(1,xx.z)(1000:end);
    input(i).gpssec  = cat(1,x.gpssec)+1e-9*cat(1,x.gpsnsec);
    input(i).fs      = 512/mean(diff(input(i).gpssec)(2:end));
    if max(input(i).z) == 0
      printf('max(z)==0 %s\n', input(i).fn);
      err = 5;
      return;
    end
    printf('tdoa_read_data: %-40s %s last_gnss_fix=%3d [%.3f sec]\n', input(i).fn, input(i).name, gpsfix, toc);
  end

  ## truncate all data to the same common time interval
  t0 = max(tmin);
  t1 = min(tmax);
  for i=1:n
    b = input(i).t<t0 | input(i).t>t1;
    input(i).t(b) = [];
    input(i).z(b) = [];
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
