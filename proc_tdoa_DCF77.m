## -*- octave -*-

function [tdoa,input]=proc_tdoa_DCF77

  input(1).fn    = 'iq/20171127T104156Z_77500_iq_HB9RYZ.wav';
  input(1).coord = [47.1721 8.42683];
  input(1).name  = 'HB9RYZ';

  input(2).fn    = 'iq/20171127T104156Z_77500_iq_F1JEK.wav';
  input(2).coord = [45.7695,0.598428];
  input(2).name  = 'F1JEK';

  input(3).fn    = 'iq/20171127T104156Z_77500_iq_DF0KL.wav';
  input(3).coord = [53.6458333 7.2916667]
  input(3).name  = 'DF0KL';

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
      tdoa(i,j).lags_orig = tdoa(i,j).lags;
      b = tdoa(i,j).gpssec>124953 & tdoa(i,j).gpssec<124960;
      tdoa(i,j).time_cut  = [124953 124960];
      tdoa(i,j).lags(~b)  = [];
      tdoa(i,j).peaks(~b) = [];
    end
  end

  tdoa = tdoa_make_plot(input, tdoa, struct('lat', [ 40:0.05:60],
                                            'lon', [ -5:0.05:16],
                                            'plotname', 'TDoA_77.5',
                                            'known_location', struct('coord', [50.0152 9.0112],
                                                                     'name',  'DCF77')
                                           ));
  tdoa = tdoa_plot_dt(input, tdoa, 2500);
  print png/TDoA_77.5_dt.png -dpng
endfunction
