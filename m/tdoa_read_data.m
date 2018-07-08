## -*- octave -*-

function [err,input]=tdoa_read_data(input, dir, prefix)
  err = 0;
  n = length(input);
  for i=1:n
    [input(i).name, input(i).vname, input(i).fname] = get_name(input(i).fn, prefix);
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
    
    input(i).t       = cat(1,xx.t)(1000:end);
    tmin(i)          = min(input(i).t);
    tmax(i)          = max(input(i).t);
    input(i).z       = cat(1,xx.z)(1000:end);
    input(i).gpssec  = cat(1,x.gpssec)+1e-9*cat(1,x.gpsnsec);
    input(i).fs      = 512/mean(diff(input(i).gpssec)(2:end));
    printf('%-40s %s %3d\n', input(i).fn, input(i).name, gpsfix);
  end
  t0 = max(tmin);
  t1 = min(tmax);
  for i=1:n
    b = input(i).t<t0 | input(i).t>t1;
    input(i).t(b) = [];
    input(i).z(b) = [];
  end
endfunction

# e.g. fn = '../files/02697/20180707T211018Z_77500_F1JEK-P_iq.wav'
function [name,vname,fname]=get_name(fn, prefix)
  fn   = fn((length(prefix)+1):end);        ## remove prefix
  idx  = strfind(fn, '_')(2:3) + [1 -1];
  fname = fn(idx(1):idx(2));
  if fname(1) == '_'
    fname(1) = [];
  end
  name = strrep(fname, '-', '/');            ## recover encoded slashes
  vname = strrep(fname, '-', '_');
end
