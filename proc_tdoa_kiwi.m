## -*- octave -*-

function [tdoa,input]=proc_tdoa_kiwi(dir, files, plot_info)

  n = length(files);
  for i=1:n
    input(i).fn = files{i};
  end

  [err, input] = tdoa_read_data(input, dir, dir);
  if err != 0
    tdoa_err_kiwi(err);
  end

  tdoa  = tdoa_compute_lags(input, struct('dt',     12000,            # 1-second cross-correlation intervals
                                          'range',  0.020,            # peak search range is +-20 ms
                                          'dk',    [-2:2],            # use 5 points for peak fitting
                                          'fn', @tdoa_peak_fn_pol2fit # fit a pol2 to the peak
                                         ));

  tdoa         = tdoa_cluster_lags(tdoa, input);
  [tdoa,input] = tdoa_verify_lags(n, tdoa, input);
  ##save('-mat', 'tdoa.mat', 'input', 'tdoa');

  plot_info.dir       = dir;
  plot_info.plotname  = 'TDoA map';
  plot_info.title     = sprintf('%g kHz %s', input(1).freq, input(1).time);
  plot_info.plot_kiwi = true;

  if isfield(plot_info, 'lat_range')
    plot_info.plot_kiwi_json = true;
    ### determine map resolution and create plot_info.lat and plot_info.lon fields
    plot_info = tdoa_autoresolution(plot_info);
    tdoa = tdoa_plot_map(input, tdoa, plot_info);
    tdoa = tdoa_plot_dt (input, tdoa, plot_info, 2.5e-3);
  else
    plot_info.coastlines = 'coastline/world_110m.mat';
    ##tdoa = tdoa_plot_map_kiwi(input, tdoa, plot_info);
    ##tdoa = tdoa_plot_dt_kiwi (input, tdoa, plot_info, 2.5e-3);
    tdoa = tdoa_plot_map(input, tdoa, plot_info);
    tdoa = tdoa_plot_dt (input, tdoa, plot_info, 2.5e-3);
  end

  tdoa_err_kiwi(0);
endfunction
