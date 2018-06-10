## -*- octave -*-

function tdoa=tdoa_make_plot(input, tdoa, plot_info)
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
  allnames  = [];

  colormap([linspace(1,0,100)' linspace(0,1,100)' zeros(100,1)
            linspace(0,1,100)' ones(100,1)   linspace(0,1,100)'
            1 1 1]);
  cl=load('coastline/world_50m.mat');
  cl=cl.c;
  set(0,'defaultaxesposition', [0.05, 0.05, 0.9, 0.9]);
  figure(1, 'position', [100,100, 900, 600]);

  allnames = '';
  for i=1:n
    allnames = [input(i).name '-' allnames];
    for j=1+i:n
      subplot(n-1,n-1, (n-1)*(i-1)+j-1);
      printf('%d,%d, %d\n', i,j, (n-1)*(i-1)+j-1);

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

      imagesc(lon([1 end]), lat([1 end]), reshape(sqrt(tdoa(i,j).h), length(lon), length(lat))', [0 20]);
      set(gca,'YDir','normal');
      xlabel 'longitude (deg)'
      ylabel 'latitude (deg)'
      title({sprintf('%s-%s', input(i).name, input(j).name), ...
             sprintf('dt=%.0fus RMS(dt)=%.0fus', mean(tdoa(i,j).lags(b))*1e6, std(tdoa(i,j).lags(b))*1e6)});
      hold on
      plot_coastlines(cl, [lon(1) lat(1)], [lon(end) lat(end)]);
      plot_location(input(i).coord, input(i).name, false);
      plot_location(input(j).coord, input(j).name, false);
      if isfield(plot_info, 'known_location')
        for k=1:length(plot_info.known_location)
          plot_location(plot_info.known_location(k).coord, plot_info.known_location(k).name, true);
        end
      end
    end
  end

  for i=1:n
    for j=1+i:n
      subplot(n-1,n-1, (n-1)*(i-1)+j-1);
      c = colorbar();
      set(c,'XLabel', '\sigma')
    end
  end

  switch n
    case {3}
      subplot(2,2,3);
    case {4}
      subplot(3,3,7);
    case {5}
      subplot(2,2,3);
    case {6}
      subplot(3,3,7);
    otherwise
      error(sprintf('n=%d is not supported'));
  end

  imagesc(lon([1 end]), lat([1 end]), reshape(sqrt(hSum)/n, length(lon), length(lat))', [0 20]);
  set(gca,'YDir','normal');
  xlabel 'longitude (deg)'
  ylabel 'latitude (deg)'
  title(allnames(1:end-1));
  c = colorbar();
  set(c,'XLabel', '\chi^2/ndf')
  hold on
  contour(lon, lat, reshape(sqrt(hSum)/n, length(lon), length(lat))', [1 3 5 10 15], '--', 'linecolor', 0.7*[1 1 1]);
  plot_coastlines(cl, [lon(1) lat(1)], [lon(end) lat(end)]);
  for i=1:n
    plot_location(input(i).coord, input(i).name, false);
  end
  if isfield(plot_info, 'known_location')
    for k=1:length(plot_info.known_location)
      plot_location(plot_info.known_location(k).coord, plot_info.known_location(k).name, true);
    end
  end

  ha = axes('Position',[0 0 1 1],'Xlim',[0 1],'Ylim',[0  1],'Box','off','Visible','off','Units','normalized', 'clipping' , 'off');
  text(0.5, 0.98,  plot_info.title, 'fontweight', 'bold', 'horizontalalignment', 'center', 'fontsize', 15);

  print('-dpng','-S900,600', sprintf('png/%s.png', plot_info.plotname));
  print('-dpdf','-S900,600', sprintf('pdf/%s.pdf', plot_info.plotname));

endfunction

function plot_location(coord, label, is_known_location)
  markers = { 'b*', 'k*' };
  colors  = { 'blue', 'black' };
  plot(coord(2), coord(1), markers{1+is_known_location});
  texthandle = text(coord(2), coord(1), label,
                    'fontsize', 7.5, 'color', colors{1+is_known_location}, 'horizontalalignment', 'center', 'verticalalignment', 'baseline');
  extent = get(texthandle, 'extent');
  set(texthandle, 'position', extent(1:2) + extent(3:4)/2);
end

function [lat,lon]=plot_circle(s)
  lat1 = s.coord(1)/180*pi;
  lon1 = s.coord(2)/180*pi;
  d    = s.dist/6371.2; # radial distance

  tc=0:2*pi/100:2*pi;
  for i=1:length(tc)
    lat(i) = asin(sin(lat1)*cos(d)+cos(lat1)*sin(d)*cos(tc(i)));
    if cos(lat(i))==0
      lon(i) = lon1;
    else
      lon(i) = mod(lon1-asin(sin(tc(i))*sin(d)/cos(lat(i)))+pi,2*pi)-pi;
    end
  end
  lat *= 180/pi;
  lon *= 180/pi;
endfunction
