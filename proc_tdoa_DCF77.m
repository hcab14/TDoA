## -*- octave -*-

function [tdoa,input]=proc_tdoa_DCF77
  status = struct;
  try
    status.version = tdoa_get_version();

    input(1).fn = fullfile('iq', '20171127T104156Z_77500_HB9RYZ_iq.wav');
    input(2).fn = fullfile('iq', '20171127T104156Z_77500_F1JEK_iq.wav');
    input(3).fn = fullfile('iq', '20171127T104156Z_77500_DF0KL_iq.wav');

    config = struct('lat_range', [ 45 55],
                    'lon_range', [ -2 12],
                    'known_location', struct('coord', [50.0152 9.0112],
                                             'name',  'DCF77'),
                    'dir', 'png',
                    'plot_kiwi', true,
                    'plot_kiwi_json', true,
                    'visible', 'on',
                    'use_constraints', ~true
                   );

    ## determine map resolution and create config.lat and config.lon fields
    config = tdoa_autoresolution(config);

    [input,status.input] = tdoa_read_data(config, input, 'gnss_pos');

    config.plotname = sprintf('TDoA_%g', input(1).freq);
    config.title    = sprintf('%g kHz %s', input(1).freq, input(1).time);

    ## 200 Hz high-pass filter
    b = fir1(1024, 500/12000, 'high');
    n = numel(input);
    for i=1:n
      input(i).z = filter(b,1,input(i).z)(512:end);
    end

    [tdoa, status.cross_correlations] = tdoa_compute_lags(input, ...
                                                          struct('dt',     12000,            # 1-second cross-correlation intervals
                                                                 'range',  0.005,            # peak search range is +-5 ms
                                                                 'dk',    [-2:2],            # use 5 points for peak fitting
                                                                 'fn', @tdoa_peak_fn_pol2fit,# fit a pol2 to the peak
                                                                 'remove_outliers', ~config.use_constraints,
                                                                ));

    if config.use_constraints
      [tdoa,status.cross_correlations] = tdoa_cluster_lags(config, tdoa, input, status.cross_correlations);
      [tdoa,input,status.constraints]  = tdoa_verify_lags (config, tdoa, input);
    end
    [tdoa,status.position] = tdoa_plot_map(input, tdoa, config);
    tdoa                   = tdoa_plot_dt (input, tdoa, config, 2.5e-3);
  catch err
    status.octave_error = err;
  end_try_catch

  try
    fid = fopen(fullfile('png', 'status.json'), 'w');
    json_save_cc(fid, status);
    fclose(fid);
  catch err
    err
    dbstack();
    exit(1);
  end_try_catch
endfunction
