## -*- octave -*-

function [tdoa,hSum]=tdoa_generate_maps_new(input, tdoa, plot_info)
  ## (1) make lat,lon grid
  lat = plot_info.lat;
  lon = plot_info.lon;
  m   = length(lat) * length(lon);
  a   = zeros(m,2, 'single');
  k   = 0;
  for i=1:length(lat)
    a(k+[1:length(lon)],1) = lat(i);
    a(k+[1:length(lon)],2) = lon;
    k += length(lon);
  end

  ## (2) compute time differences to each grid point
  n_stn      = length(input);
  n_stn_used = sum(vertcat(input.use));
  for i=1:n_stn
    if isfield(input, 'dt_map')
      dt{i} = interp2(input(i).dt_map.lon, input(i).dt_map.lat, input(i).dt_map.dt, a(:,2), a(:,1), 'pchip');
    else
      dt{i} = 6371*distance_rad(input(i).coord, a)/299792.458;
    end
  end

  ## (3) compute number of std deviations for each pair of receivers for each grid point
  hSum      = [];
  for i=1:n_stn
    for j=1+i:n_stn
      tdoa(i,j).h = interp1(tdoa(i,j).lags, tdoa(i,j).sigma2, dt{i}-dt{j}, '*linear', 0);
      tdoa(i,j).h(tdoa(i,j).h < 0) = 0;
      if isempty(hSum)
        hSum  = tdoa(i,j).h;
      else
        hSum += tdoa(i,j).h;
      end
    end
  end
endfunction
