## -*- octave -*-

function tdoa=tdoa_plot_map(input_data, tdoa, plot_info)

  [tdoa,hSum] = tdoa_generate_maps(input_data, tdoa, plot_info);

  colormap([linspace(1,0,100)' linspace(0,1,100)' zeros(100,1)  ## green to red
            linspace(0,1,100)' ones(100,1)   linspace(0,1,100)' ## red to white
            1 1 1]);                                            ## white

  coastlines = load('coastline/world_50m.mat').c;

  set(0,'defaultaxesposition', [0.05, 0.05, 0.9, 0.9]);
  figure(1, 'position', [100,100, 900,600]);


  n = length(input_data);

  if ~isfield(plot_info, 'known_location')
    most_likely_pos = get_most_likely_pos(plot_info,
                                          reshape(sqrt(hSum)/n,
                                                  length(plot_info.lon),
                                                  length(plot_info.lat))');
    plot_info.known_location.coord = most_likely_pos;
    plot_info.known_location.name  = sprintf('%.2fN %.2fE', most_likely_pos);
  end

  allnames = '';
  for i=1:n
    allnames = [input_data(i).name '-' allnames];
    for j=1+i:n
      tic;
      subplot(n-1,n-1, (n-1)*(i-1)+j-1);

      b = tdoa(i,j).lags_filter;
      titlestr = { sprintf('%s-%s', input_data(i).name, input_data(j).name),
                   sprintf('dt=%.0fus RMS(dt)=%.0fus', mean(tdoa(i,j).lags(b))*1e6, std(tdoa(i,j).lags(b))*1e6)
                 };
      plot_map(plot_info,
               reshape(sqrt(tdoa(i,j).h), length(plot_info.lon), length(plot_info.lat))',
               titlestr,
               coastlines,
               false);
      printf('tdoa_plot_map(%d,%d) %.2f sec\n', i,j, toc());
    end
  end

  for i=1:n
    for j=1+i:n
      subplot(n-1,n-1, (n-1)*(i-1)+j-1);
      plot_location(input_data(i).coord, input_data(i).name, false);
      plot_location(input_data(j).coord, input_data(j).name, false);
      set(colorbar(), 'XLabel', '\sigma')
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

  tic;
  plot_map(plot_info,
           reshape(sqrt(hSum)/n, length(plot_info.lon), length(plot_info.lat))',
           allnames(1:end-1),
           coastlines,
           true);

  for i=1:n
    plot_location(input_data(i).coord, input_data(i).name, false);
  end

  set(colorbar(),'XLabel', '\chi^2/ndf')
  printf('tdoa_plot_map_combined %.2f sec\n', toc());

  ha = axes('Position',[0 0 1 1],'Xlim',[0 1],'Ylim',[0  1],'Box','off','Visible','off','Units','normalized', 'clipping' , 'off');
  text(0.5, 0.98,  plot_info.title, 'fontweight', 'bold', 'horizontalalignment', 'center', 'fontsize', 15);

  print('-dpng','-S900,600', fullfile('png', sprintf('%s.png', plot_info.plotname)));
  print('-dpdf','-S900,600', fullfile('pdf', sprintf('%s.pdf', plot_info.plotname)));
endfunction

function pos=get_most_likely_pos(plot_info, h)
  [_m,  _i] = min(h);
  [_mm, _j] = min(_m);
  _i = _i(_j);
  pos = [plot_info.lat(_i) plot_info.lon(_j)];
  printf('most likely position: lat = %.2f deg  lon = %.2f deg\n', pos);
endfunction

function plot_map(plot_info, h, titlestr, coastlines, do_plot_contour)
  imagesc(plot_info.lon([1 end]), plot_info.lat([1 end]), h, [0 20]);
  set(gca,'YDir','normal');
  xlabel('longitude (deg)');
  ylabel('latitude (deg)');
  title(titlestr);
  hold on;
  if do_plot_contour
    contour(plot_info.lon, plot_info.lat, h, [1 3 5 10 15], '--', 'linecolor', 0.7*[1 1 1]);
  end
  plot_coastlines(coastlines,
                  [plot_info.lon(1)   plot_info.lat(1)],
                  [plot_info.lon(end) plot_info.lat(end)]);
  if isfield(plot_info, 'known_location')
    for k=1:length(plot_info.known_location)
      plot_location(plot_info.known_location(k).coord, plot_info.known_location(k).name, true);
    end
  end

end

function plot_location(coord, label, is_known_location)
  markers = { 'b*', 'kx' };
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
