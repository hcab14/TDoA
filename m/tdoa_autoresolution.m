## -*- octave -*-

function plot_info=tdoa_autoresolution(plot_info)
  ## predefined bin widths
  bin_widths = [ 0.01 0.02 0.05 0.1 0.2 0.5 1 2 5];

  ## lat and lon intervals
  dlat = diff(plot_info.lat_range);
  dlon = diff(plot_info.lon_range);

  ## number of pixels in lat and lon for all bin widths
  nlat = dlat ./ bin_widths;
  nlon = dlon ./ bin_widths;

  ## total number of pixels for all bin widths
  n    = nlat .* nlon;

  ## limit image size to 200k pixels
  idx  = find(n < 200e3)(1);

  ## add lat and lon fields to plot_info with the determined bin width
  plot_info.lat = single([plot_info.lat_range(1):bin_widths(idx):plot_info.lat_range(2)]);
  plot_info.lon = single([plot_info.lon_range(1):bin_widths(idx):plot_info.lon_range(2)]);
endfunction
