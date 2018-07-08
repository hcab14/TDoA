## -*- octave -*-

function [tdoa,input]=proc_tdoa_kiwi(dir, files, plot_info)

  n = length(files);
  for i=1:n
    input(i).fn = files{i};
  end

  [err, input] = tdoa_read_data(input, dir, dir);
  if (err != 0)
    tdoa_err_kiwi(err);
  end

  tdoa  = tdoa_compute_lags(input, struct('dt',     12000,            # 1-second cross-correlation intervals
                                          'range',  0.005,            # peak search range is +-5 ms
                                          'dk',    [-2:2],            # use 5 points for peak fitting
                                          'fn', @tdoa_peak_fn_pol2fit # fit a pol2 to the peak
                                         ));
  n = length(input);
  for i=1:n
    for j=i+1:n
      tdoa(i,j).lags_filter = ones(size(tdoa(i,j).gpssec))==1;
    end
  end

  plot_info.dir = dir;
  plot_info.plotname = 'TDoA map';
  plot_info.title = 'no title';
  tdoa = tdoa_plot_map_kiwi(input, tdoa, plot_info);
  tdoa = tdoa_plot_dt_kiwi (input, tdoa, plot_info, 2.5e-3);

  tdoa_err_kiwi(0);

endfunction
