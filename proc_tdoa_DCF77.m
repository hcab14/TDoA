## -*- octave -*-

function [tdoa,input]=proc_tdoa_DCF77

  input(1).fn    = 'iq/20171127T104156Z_77500_HB9RYZ_iq.wav';
  input(2).fn    = 'iq/20171127T104156Z_77500_F1JEK_iq.wav';
  input(3).fn    = 'iq/20171127T104156Z_77500_DF0KL_iq.wav';

  input = tdoa_read_data(input);

  ## 200 Hz high-pass filter
  b = fir1(1024, 500/12000, 'high');
  n = length(input);
  for i=1:n
    input(i).z      = filter(b,1,input(i).z)(512:end);
  end

  tdoa  = tdoa_compute_lags(input, struct('dt',     12000,            # 1-second cross-correlation intervals
                                          'range',  0.005,            # peak search range is +-5 ms
                                          'dk',    [-2:2],            # use 5 points for peak fitting
                                          'fn', @tdoa_peak_fn_pol2fit # fit a pol2 to the peak
                                         ));
  for i=1:n
    for j=i+1:n
      tdoa(i,j).lags_filter = ones(size(tdoa(i,j).gpssec))==1;
    end
  end

  plot_info = struct('lat', [ 40:0.05:60],
                     'lon', [ -5:0.05:16],
                     'plotname', 'TDoA_77.5',
                     'title', '77.5 kHz 20171127T1041Z',
                     'known_location', struct('coord', [50.0152 9.0112],
                                              'name',  'DCF77')
                    );
  tdoa = tdoa_make_plot(input, tdoa, plot_info);
  tdoa = tdoa_plot_dt(input, tdoa, plot_info, 2.5e-3);
  print png/TDoA_77.5_dt.png -dpng
endfunction
