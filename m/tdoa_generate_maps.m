## -*- octave -*-

function [tdoa,hSum]=tdoa_generate_maps(input, tdoa, plot_info)
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
      b = tdoa(i,j).lags_filter;
      tdoa(i,j).a = a;
      if ~input(i).use || ~input(j).use || sum(b)==0
        tdoa(i,j).h = 20**2 * ones(size(dt{i}), 'single');
        continue;
      end
      xlag = sum(tdoa(i,j).peaks(b).**2 .* tdoa(i,j).lags(b))              / sum(tdoa(i,j).peaks(b).**2);
      slag = sum(tdoa(i,j).peaks(b).**2 .* (tdoa(i,j).lags(b) - xlag).**2) / sum(tdoa(i,j).peaks(b).**2);
      tdoa(i,j).h = single((dt{i}-dt{j}-xlag).**2 / slag);
      if isempty(hSum)
        hSum  = tdoa(i,j).h;
      else
        hSum += tdoa(i,j).h;
      end
    end
  end
endfunction
