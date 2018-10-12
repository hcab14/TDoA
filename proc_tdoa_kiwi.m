## -*- octave -*-

## exitcode == 0 ... no errors
## exitcode == 1 ...    error in 1st try-catch block and no error while saving status.json (status.json valid)
## exitcode == 2 ... no error in 1st try-catch block and    error while saving status.json (status.json not valid)
## exitcode == 3 ...    error in 1st try-catch block and    error while saving status.json (status.json not valid)

function [tdoa,input]=proc_tdoa_kiwi(dir, files, config)
  exitcode = 0;
  status   = struct;

  try
    status.version = tdoa_get_version();
    for i=1:numel(files)
      input(i).fn = files{i};
    end

    config.dir       = dir;
    config.plot_kiwi = true;
    if isfield(config, 'lat_range')
      config.plot_kiwi_json = true;
      ## determine map resolution and create config.lat and config.lon fields
      config = tdoa_autoresolution(config);
    end
    if ~isfield(config, 'use_constraints')
      config.use_constraints = false;
    end

    [input,status.input] = tdoa_read_data(config, input, dir);
    [tdoa, status.cross_correlations] = tdoa_compute_lags(input, struct('dt',     12000,            # 1-second cross-correlation intervals
                                                                        'range',  0.020,            # peak search range is +-20 ms
                                                                        'dk',    [-2:2],            # use 5 points for peak fitting
                                                                        'fn', @tdoa_peak_fn_pol2fit,# fit a pol2 to the peak
                                                                        'remove_outliers', ~config.use_constraints
                                                                       ));
    if config.use_constraints
      [tdoa,status.cross_correlations] = tdoa_cluster_lags(config, tdoa, input, status.cross_correlations);
      [tdoa,input,status.constraints]  = tdoa_verify_lags (config, tdoa, input);
    end

    config.plotname = 'TDoA map';
    config.title    = sprintf('%g kHz %s', input(1).freq, input(1).time);

    [tdoa,status.position] = tdoa_plot_map(input, tdoa, config);
    tdoa                   = tdoa_plot_dt (input, tdoa, config, 2.5e-3);
  catch err
    json_save_cc(stderr, err);
    status.octave_error = err;
    exitcode            = 1;
  end_try_catch

  try
    fid = fopen(fullfile(dir, 'status.json'), 'w');
    json_save_cc(fid, status);
    fclose(fid);
  catch err
    json_save_cc(stderr, err);
    exitcode += 2;
  end_try_catch

  if exitcode != 0
    exit(exitcode);
  end
endfunction
