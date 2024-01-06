## -*- octave -*-

function [input,status]=tdoa_read_data(plot_info, input, dir)
  if nargin == 1
    dir = 'gnss_pos';
    printf('using default dir="gnss_pos"\n');
  end

  n   = numel(input);
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
    status.per_file(i).name      = input(i).name;
    status.per_file(i).file_name = input(i).fn;
    status.per_file(i).time_sec  = toc;
    status.per_file(i).message   = '';
    status.per_file(i).last_gnss_fix = gpsfix;
    if gpsfix == 255
      printf('tdoa_read_data: %-40s no GPS timestamps\n', input(i).fn);
      status.per_file(i).message = 'no GNSS timestamps';
      continue
    end

    if gpsfix == 254
      printf('tdoa_read_data: %-40s no recent GPS timestamps\n', input(i).fn);
      status.per_file(i).message = 'no recent GNSS timestamps';
      continue
    end

    if gpsfix == 253
      printf('tdoa_read_data: %-40s sample rate error\n', input(i).fn);
      status.per_file(i).message = 'sample rate error';
      continue
    end

    input(i).t      = cat(1,xx.t);
    input(i).z      = cat(1,xx.z);
    input(i).gpssec = cat(1,x.gpssec)+1e-9*cat(1,x.gpsnsec);
    if numel(input(i).t) == 0 || numel(input(i).gpssec) <= 2
      printf('tdoa_read_data: %-40s number of samples = %d == 0 || number of blocks = %d <= 2\n', ...
             input(i).fn, numel(input(i).t), numel(input(i).gpssec));
      status.per_file(i).message = sprintf('number of samples = %d == 0 || number of blocks = %d <= 2', ...
                                           numel(input(i).t), numel(input(i).gpssec));
      continue
    end
    if max(input(i).z) == 0
      printf('tdoa_read_data: %-40s max(z)==0\n', input(i).fn);
      status.per_file(i).message = 'max(z)==0';
      continue;
    end
    if max(abs(diff(input(i).t))) > 2/fs
      printf('tdoa_read_data: %-40s max(abs(diff(input(i).t))) = %f > %f\n', ...
             input(i).fn, max(abs(diff(input(i).t))), 2/fs);
      status.per_file(i).message = sprintf('max(abs(diff(input(i).t))) = %f > %f', ...
                                           max(abs(diff(input(i).t))), 2/fs);
      continue
    end
    tmin(i)      = min(input(i).t);
    tmax(i)      = max(input(i).t);
    input(i).fs  = 512/mean(diff(input(i).gpssec)(2:end));
    input(i).use = true;
    printf('tdoa_read_data: %-40s %s last_gnss_fix=%3d\n', ...
           input(i).fn, input(i).name, gpsfix);
  end

  ## exclude bad stations
  b_use = vertcat(input.use);
  tmin  = tmin(b_use);
  tmax  = tmax(b_use);
  n     = numel(input);

  ## truncate all data to the same common time interval
  t0 = max(tmin);
  t1 = min(tmax);
  for i=1:n
    if ~input(i).use
      continue
    end
    b = input(i).t<t0 | input(i).t>t1;
    input(i).t(b) = [];
    input(i).z(b) = [];
    input(i).use  = numel(input(i).z)/input(i).fs > 10;
    if ~input(i).use
      printf('tdoa_read_data: %-40s excluded (%.2f sec < %g sec overlap)\n', ...
             input(i).fn, numel(input(i).z)/input(i).fs, 10);
      status.per_file(i).message = sprintf('excluded (%.2f sec < %g sec overlap)', numel(input(i).z)/12000, 10);
    end
  end

  ## generate json info for each station
  counter=1;
  stn_status = {'BAD', 'GOOD'};
  for i=1:n
    if ~input(i).use
      status.per_file(i).idx    = -1;
      status.per_file(i).status = 'BAD';
    else
      status.per_file(i).idx    = counter;
      status.per_file(i).status = 'GOOD';
      counter += 1;
    end
  end

  ## exclude bad stations
  input = input(vertcat(input.use));

  if numel(input) < 2
    printf('tdoa_read_data: n=%d < 2 good stations found\n', numel(input));
    status.result = struct('status', 'BAD',
                           'message', sprintf('%d/%d good stations < 2', numel(input), n));
  else
    status.result = struct('status', 'GOOD',
                           'message', sprintf('%d/%d good stations', numel(input), n));
  end

  ## resample if necessary (20.25 kHz vs. 12 kHz modes)
  [input,status] = resample_ifneeded(input,status);
endfunction

function [input,status]=resample_ifneeded(input, status)
  ## round sampling frequencies to nearest multiple of 10 Hz
  fs        = round(cat(1,input.fs)/10)*10;
  [fs0,idx] = min(fs);
  for i=1:numel(input)
    if i==idx
      continue
    end
    if abs(fs(i)/fs0-1) > 0.1
      status.per_file(i).message = sprintf('resampled %g kHz to %g kHz', 1e-3*[fs(i) fs0]);
      input(i).z   = resample(input(i).z, fs0, fs(i)); ## factor fs0/fs(i)
      dt = mean(diff(input(i).t)) *fs(i)/fs0;
      input(i).t   = input(i).t(1) + [0:numel(input(i).z)]*dt;
      input(i).fs  = 1/dt;
    end
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
