## -*- octave -*-

function [tdoa,input]=proc_tdoa_kiwi(dir, files, plot_info)
  status = struct;
  try
    status.version = tdoa_get_version();

    for i=1:numel(files)
      input(i).fn = files{i};
    end

    plot_info.dir       = dir;
    plot_info.plotname  = 'TDoA map';
    plot_info.title     = sprintf('%g kHz %s', input(1).freq, input(1).time);
    plot_info.plot_kiwi = true;
    plot_info.visible   = 'on';
    if isfield(plot_info, 'lat_range')
      plot_info.plot_kiwi_json = true;
      ## determine map resolution and create plot_info.lat and plot_info.lon fields
      plot_info = tdoa_autoresolution(plot_info);
    end

    [input,status.input] = tdoa_read_data(plot_info, input, dir);
    [tdoa, status.cross_correlations] = tdoa_compute_lags(input, struct('dt',     12000,            # 1-second cross-correlation intervals
                                                                        'range',  0.020,            # peak search range is +-20 ms
                                                                        'dk',    [-2:2],            # use 5 points for peak fitting
                                                                        'fn', @tdoa_peak_fn_pol2fit # fit a pol2 to the peak
                                                                       ));
    [tdoa,status.cross_correlations]  = tdoa_cluster_lags(plot_info, tdoa, input, status.cross_correlations);
    [tdoa,input,status.constraints]   = tdoa_verify_lags (plot_info, tdoa, input);
    [tdoa,status.position]            = tdoa_plot_map(input, tdoa, plot_info);
    tdoa                              = tdoa_plot_dt (input, tdoa, plot_info, 2.5e-3);
  catch err
    status.octave_error = err;
  end_try_catch

  try
    fid = fopen(fullfile(dir, 'status.json'), 'w');
    json_save_cc(fid, status);
    fclose(fid);
  catch err
    dbstack();
    exit(1);
  end_try_catch
endfunction
