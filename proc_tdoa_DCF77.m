## -*- octave -*-

function [tdoa,input]=proc_tdoa_DCF77
  input(1).fn = fullfile('iq', '20171127T104156Z_77500_HB9RYZ_iq.wav');
  input(2).fn = fullfile('iq', '20171127T104156Z_77500_F1JEK_iq.wav');
  input(3).fn = fullfile('iq', '20171127T104156Z_77500_DF0KL_iq.wav');

  plot_info    = struct('lat_range', [ 45 55],
                        'lon_range', [ -2 12],
                        'known_location', struct('coord', [50.0152 9.0112],
                                                 'name',  'DCF77'),
                        'dir', 'png',
                        'plot_kiwi', true
                       );
  plot_info.save_json = @save_json;

  [_, input] = tdoa_read_data(plot_info, input, 'gnss_pos');

  plot_info.plotname = sprintf('TDoA_%g', input(1).freq);
  plot_info.title    = sprintf('%g kHz %s', input(1).freq, input(1).time);

  ## 200 Hz high-pass filter
  b = fir1(1024, 500/12000, 'high');
  n = numel(input);
  for i=1:n
    input(i).z = filter(b,1,input(i).z)(512:end);
  end

  tdoa = tdoa_compute_lags(input, ...
                           struct('dt',     12000,            # 1-second cross-correlation intervals
                                  'range',  0.005,            # peak search range is +-5 ms
                                  'dk',    [-2:2],            # use 5 points for peak fitting
                                  'fn', @tdoa_peak_fn_pol2fit # fit a pol2 to the peak
                                 ));

  tdoa         = tdoa_cluster_lags(plot_info, tdoa, input);
  [tdoa,input] = tdoa_verify_lags (plot_info, tdoa, input);
  plot_info.plot_kiwi_json = true;
  ## determine map resolution and create plot_info.lat and plot_info.lon fields
  plot_info    = tdoa_autoresolution(plot_info);
  tdoa         = tdoa_plot_map(input, tdoa, plot_info);
  return
  tdoa         = tdoa_plot_dt (input, tdoa, plot_info, 2.5e-3);
endfunction

function save_json(plot_info, fn, mode, str)
  fid = fopen(fullfile(plot_info.dir, fn), mode);
  str = strrep(str,  ':Inf',  ':"Infinity"');
  str = strrep(str, ':-Inf', ':"-Infinity"');
  fprintf(fid, str);
  fclose(fid);
endfunction
