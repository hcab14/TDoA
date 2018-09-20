## -*- octave -*-

function [err,input]=tdoa_read_data(plot_info, input, dir)
  if nargin == 1
    dir = 'gnss_pos';
    printf('using default dir="gnss_pos"\n');
  end

  err = 0;
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
    if gpsfix == 255
      printf('tdoa_read_data: %-40s no GPS timestamps\n', input(i).fn);
      input(i).message = 'no GNSS timestamps';
      continue
    end

    if gpsfix == 254
      printf('tdoa_read_data: %-40s no recent GPS timestamps\n', input(i).fn);
      input(i).message = 'no recent GNSS timestamps';
      continue
    end

    input(i).t      = cat(1,xx.t)(1000:end);
    input(i).z      = cat(1,xx.z)(1000:end);
    input(i).gpssec = cat(1,x.gpssec)+1e-9*cat(1,x.gpsnsec);
    if numel(input(i).t) == 0 || numel(input(i).gpssec) <= 2
      printf('tdoa_read_data: %-40s number of samples = %d == 0 || number of blocks = %d <= 2\n', ...
             input(i).fn, numel(input(i).t), numel(input(i).gpssec));
      input(i).message = sprintf('number of samples = %d == 0 || number of blocks = %d <= 2', ...
                                 numel(input(i).t), numel(input(i).gpssec));
      continue
    end
    if max(input(i).z) == 0
      printf('tdoa_read_data: %-40s max(z)==0\n', input(i).fn);
      input(i).message = 'max(z)==0';
      continue;
    end
    if max(abs(diff(input(i).t))) > 2/fs
      printf('tdoa_read_data: %-40s max(abs(diff(input(i).t))) = %f > %f\n', ...
             input(i).fn, max(abs(diff(input(i).t))), 2/fs);
      input(i).message = sprintf('max(abs(diff(input(i).t))) = %f > %f', ...
                                 max(abs(diff(input(i).t))), 2/fs);
      continue
    end
    tmin(i)      = min(input(i).t);
    tmax(i)      = max(input(i).t);
    input(i).fs  = 512/mean(diff(input(i).gpssec)(2:end));
    input(i).use = true;
    _toc         = toc;
    printf('tdoa_read_data: %-40s %s last_gnss_fix=%3d [%.3f sec]\n', ...
           input(i).fn, input(i).name, gpsfix, _toc);
    input(i).message = sprintf('last_gnss_fix=%3d [%.3f sec]', ...
                               gpsfix, _toc);
  end

  ## exclude bad stations
  b_use = vertcat(input.use);
  tmin  = tmin(b_use);
  tmax  = tmax(b_use);
  n     = numel(input);

  ## truncate all data to the same common time interval
  t0 = max(tmin);
  t1 = min(tmax);
  json_line_end = [",", " "];
  for i=1:n
    if ~input(i).use
      continue
    end
    b = input(i).t<t0 | input(i).t>t1;
    input(i).t(b) = [];
    input(i).z(b) = [];
    input(i).use  = numel(input(i).z)/12000 > 10;
    if ~input(i).use
      printf('tdoa_read_data: %-40s excluded (%.2f sec < %g sec overlap)\n', ...
             input(i).fn, numel(input(i).z)/12000, 10);
      input(i).message = sprintf('excluded (%.2f sec < %g sec overlap)', numel(input(i).z)/12000, 10);
    end
  end

  ## generate json info for each station
  status_json = sprintf('{ "input": {\n    "per_file": [\n');
  counter=1;
  stn_status = {"BAD", "GOOD"};
  for i=1:n
    if ~input(i).use
      idx = -1;
    else
      idx      = counter;
      counter += 1;
    end
    status_json = [status_json sprintf('      {"name":"%s", "idx":%d, "status":"%s", "message":"%s"}%s\n', ...
                                       input(i).name, idx, stn_status{1+input(i).use}, input(i).message, json_line_end(1+(i==n)))];
  end
  status_json = [status_json '    ],\n'];

  ## exlude bad stations
  input = input(vertcat(input.use));

  if numel(input) < 2
    printf('tdoa_read_data: n=%d < 2 good stations found\n', numel(input));
    status_json = [status_json sprintf('    "result": {"status": "BAD", "message": "%d/%d good stations < 2"}\n  }\n}\n', numel(input), n)];
    err = 3;
  else
    status_json = [status_json sprintf('    "result": {"status": "OK", "message": "%d/%d good stations"}\n  },\n', numel(input), n)];
  end
  plot_info.save_json(plot_info, 'status.json', 'w', status_json);
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
