## -*- octave -*-

function input=tdoa_read_data(input)
  for i=1:length(input)
    [x,xx,fs,gpsfix] = proc(input(i).fn);
    input(i).t       = cat(1,xx.t)(1000:end);
    input(i).z       = cat(1,xx.z)(1000:end);
    input(i).gpssec  = cat(1,x.gpssec)+1e-9*cat(1,x.gpsnsec);
    input(i).fs      = 512/mean(diff(input(i).gpssec)(2:end));
    printf("%-40s %3d\n", input(i).fn, gpsfix);
  end
endfunction

