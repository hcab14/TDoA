## -*- octave -*-

function [tdoa,hSum]=tdoa_generate_maps(input, tdoa, plot_info)
  ## (1) make lat,lon grid
  lat = plot_info.lat;
  lon = plot_info.lon;
  m   = length(lat) * length(lon);
  a   = zeros(m,2);
  k   = 0;
  for i=1:length(lat)
    a(k+[1:length(lon)],1) = lat(i);
    a(k+[1:length(lon)],2) = lon;
    k += length(lon);
  end

  f=@(dist, rE,h) 2*sqrt((rE+h)**2 + rE**2 - 2*rE*(rE+h)*cos(dist/rE/2));

  ## (2) compute time differences to each grid point
  n = length(input);
  height = 110;
  height = 200;
  height = 350;
  max_skip = 2100;
  max_skip = 3400;
  for i=1:n
    dist  = deg2km(distance(input(i).coord, a));
    dt{i} =   f(dist,     6371, height)/299792.458;
    for j=1:4
      b = dist>j*max_skip*0.9**(j-1);
      dt{i}(b) = (j+1)*f(dist(b)/(j+1),6371, height)/299792.458;
    end
    dt{i} = dist/299792.458;
  end


  ## (3) compute number of std deviations for each pair of receivers for each grid point
  hSum      = zeros(size(dt{1}));
  for i=1:n
    for j=1+i:n
      b = tdoa(i,j).lags_filter;
      xlag = sum(tdoa(i,j).peaks(b).**2 .* tdoa(i,j).lags(b))              / sum(tdoa(i,j).peaks(b).**2);
      slag = sum(tdoa(i,j).peaks(b).**2 .* (tdoa(i,j).lags(b) - xlag).**2) / sum(tdoa(i,j).peaks(b).**2);
      tdoa(i,j).a = a;
      tdoa(i,j).h = (dt{i}-dt{j}-xlag).**2 / slag;
      if isequal([i j], [1 2])
        hSum  = tdoa(i,j).h;
      else
        hSum += tdoa(i,j).h;
      end
    end
  end

endfunction
