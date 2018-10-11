## -*- octave -*-

function [tdoa,status]=tdoa_plot_map(input_data, tdoa, plot_info)
  plot_kiwi = false;
  if isfield(plot_info, 'plot_kiwi') && plot_info.plot_kiwi == true
    plot_kiwi = true;
  end

  if ~isfield(plot_info, 'plot_kiwi_json')
    plot_info.plot_kiwi_json = false;
  end

  cmap = single([linspace(1,0,100)' linspace(0,1,100)' zeros(100,1)     ## red to green
                 linspace(0,1,100)' ones(100,1)   linspace(0,1,100)']); ## green to white
  colormap(cmap);

  plot_info.h_max    = 20;
  plot_info.z_to_rgb = @(h) single(ind2rgb(1+round(h/plot_info.h_max*(size(cmap,1)-1)), cmap));

  [tdoa,hSum] = tdoa_generate_maps(input_data, tdoa, plot_info);

  if ~isfield(plot_info, 'coastlines')
    plot_info.coastlines = 'coastline/world_50m.mat';
  end
  coastlines = load(plot_info.coastlines).c;

  if plot_kiwi
    set(0,'defaultaxesposition', [0.08, 0.08, 0.90, 0.85]);
    figure(1, 'position', [100,100, 1024,690]);
    set(1, 'visible', plot_info.visible);
    set(0, "defaultaxesfontsize", 12)
    set(0, "defaulttextfontsize", 16)
    plot_info.titlefontsize = 16;
    plot_info.labelfontsize = 16;
  else
    set(0,'defaultaxesposition', [0.05, 0.05, 0.90, 0.9]);
    figure(1, 'position', [100,100, 900,600]);
    plot_info.titlefontsize = 10;
    plot_info.labelfontsize =  7.5;
  end

  n_stn      = length(input_data);
  n_stn_used = sum(vertcat(input_data.use));

  most_likely_pos = get_most_likely_pos(plot_info,
                                        reshape(sqrt(hSum)/n_stn_used,
                                                length(plot_info.lon),
                                                length(plot_info.lat))');

  status.likely_position.lat = most_likely_pos(1);
  status.likely_position.lng = most_likely_pos(2);
  if plot_kiwi
    printf('likely=%.2f,%.2f\n', most_likely_pos);
  end
  if ~isfield(plot_info, 'known_location')
    plot_info.known_location.coord = most_likely_pos;
    plot_info.known_location.name  = sprintf('%.2fN %.2fE', most_likely_pos);
  end

  allnames = '';
  for i=1:n_stn
    if input_data(i).use
      allnames = [input_data(i).name '-' allnames];
    else
      continue
    end
    for j=1+i:n_stn
      if ~input_data(j).use
        continue
      end
      tic;
      title_extra = '';
      if plot_kiwi == false
        subplot(n_stn-1,n_stn-1, (n_stn-1)*(i-1)+j-1);
      else
        title_extra = plot_info.title;
        clf;
      end
      b = tdoa(i,j).lags_filter;
      titlestr = { sprintf('%s-%s %s', input_data(i).name, input_data(j).name, title_extra),
                   sprintf('dt=%.0fus RMS(dt)=%.0fus', mean(tdoa(i,j).lags(b))*1e6, std(tdoa(i,j).lags(b))*1e6)
                 };
      h = reshape(sqrt(tdoa(i,j).h), length(plot_info.lon), length(plot_info.lat))';
      plot_info = plot_map(plot_info,
                           h,
                           titlestr,
                           coastlines,
                           ~false);
      printf('tdoa_plot_map(%d,%d): [%.3f sec]\n', i,j, toc());
      if plot_kiwi
        plot_location(plot_info, input_data(i).coord, input_data(i).name, false);
        plot_location(plot_info, input_data(j).coord, input_data(j).name, false);
        set(colorbar(), 'XLabel', '\sigma')
        print(sprintf('%s/%s-%s map.png', plot_info.dir, input_data(i).fname, input_data(j).fname), ...
              '-dpng', '-S1024,690');
        print(sprintf('%s/%s-%s map.pdf', plot_info.dir, input_data(i).fname, input_data(j).fname), ...
              '-dpdf', '-S1024,690');
        if plot_info.plot_kiwi_json
          [bb_lon, bb_lat] = save_as_png_for_map(plot_info,
                                                 sprintf('%s/%s-%s_for_map.png', plot_info.dir, input_data(i).fname, input_data(j).fname),
                                                 h);
          [_,h]=contour(plot_info.lon, plot_info.lat, h, [1 3 5 10 15], '--', 'linecolor', 0.7*[1 1 1]);
          save_as_json_for_map(sprintf('%s/%s-%s_contour_for_map.json', plot_info.dir, input_data(i).fname, input_data(j).fname),
                               sprintf('%s/%s-%s_for_map.png', plot_info.dir, input_data(i).fname, input_data(j).fname),
                               h, bb_lon, bb_lat, plot_info, ~false);
        end
      end
    end
  end
  if plot_kiwi == false
    for i=1:n_stn
      for j=1+i:n_stn
        subplot(n_stn-1,n_stn-1, (n_stn-1)*(i-1)+j-1);
        plot_location(plot_info, input_data(i).coord, input_data(i).name, false);
        plot_location(plot_info, input_data(j).coord, input_data(j).name, false);
        set(colorbar(), 'XLabel', '\sigma')
      end
    end

    switch n_stn
      case {3}
        subplot(2,2,3);
      case {4}
        subplot(3,3,7);
      case {5}
        subplot(2,2,3);
      case {6}
        subplot(3,3,7);
      otherwise
        error(sprintf('n_stn=%d is not supported', n_stn));
    end
  else
    clf;
  end

  tic;
  titlestr = allnames(1:end-1)
  if plot_kiwi
    titlestr = [titlestr ' ' plot_info.title];
  end

  h = reshape(sqrt(hSum)/n_stn_used, length(plot_info.lon), length(plot_info.lat))';

  plot_info = plot_map(plot_info,
                       h,
                       titlestr,
                       coastlines,
                       true);

  for i=1:n_stn
    plot_location(plot_info, input_data(i).coord, input_data(i).name, false);
  end

  set(colorbar(),'XLabel', '\chi^2/ndf')
  printf('tdoa_plot_map_combined: [%.3f sec]\n', toc());

  if plot_kiwi == false
    ha = axes('Position', [0 0 1 1], ...
              'Xlim',     [0 1], ...
              'Ylim',     [0 1], ...
              'Box',      'off', ...
              'Visible',  plot_info.visible, ...
              'Units',    'normalized', ...
              'clipping', 'off');
    text(0.5, 0.98,  plot_info.title, ...
         'fontweight', 'bold', ...
         'horizontalalignment', 'center', ...
         'fontsize', 15);
    print('-dpng','-S900,600', fullfile('png', sprintf('%s.png', plot_info.plotname)));
    print('-dpdf','-S900,600', fullfile('pdf', sprintf('%s.pdf', plot_info.plotname)));
  else
    print('-dpng','-S1024,690', sprintf('%s/%s.png', plot_info.dir, plot_info.plotname));
    print('-dpdf','-S1024,690', sprintf('%s/%s.pdf', plot_info.dir, plot_info.plotname));
    if plot_info.plot_kiwi_json
      [bb_lon, bb_lat] = save_as_png_for_map(plot_info, sprintf('%s/%s_for_map.png', plot_info.dir, plot_info.plotname), h);
      [_,h]=contour(plot_info.lon, plot_info.lat, h, [1 3 5 10 15], '--', 'linecolor', 0.7*[1 1 1]);
      save_as_json_for_map(sprintf('%s/%s_contour_for_map.json', plot_info.dir, plot_info.plotname),
                           sprintf('%s/%s_for_map.png', plot_info.dir, plot_info.plotname),
                           h, bb_lon, bb_lat, plot_info, true);
    end
  end
endfunction

function pos=get_most_likely_pos(plot_info, h)
  [_m,  _i] = min(h);
  [_mm, _j] = min(_m);
  _i = _i(_j);
  pos = [plot_info.lat(_i) plot_info.lon(_j)];
  printf('most likely position: lat = %.2f deg  lon = %.2f deg\n', pos);
endfunction

function [bb_lon, bb_lat, idx_lon, idx_lat] = find_bounding_box(plot_info, h)
  h(h>plot_info.h_max) = plot_info.h_max;
  if min(min(h)) == max(max(h))
    idx_lon = 1:length(plot_info.lon);
    idx_lat = 1:length(plot_info.lat);
  else
    idx_lon = find(min(h ) < plot_info.h_max);
    idx_lat = find(min(h') < plot_info.h_max);
    ## idx_lon,lat may not be contiguous
    idx_lon = idx_lon(1):1:idx_lon(end);
    idx_lat = idx_lat(1):1:idx_lat(end);
  end
  bb_lon  = plot_info.lon(idx_lon([1 end]));
  bb_lat  = plot_info.lat(idx_lat([1 end]));
endfunction


function plot_info=plot_map(plot_info, h, titlestr, coastlines, do_plot_contour)
  imagesc(plot_info.lon([1 end]), plot_info.lat([1 end]), h, [0 20]);
  set(gca,'YDir','normal');
  xlabel('longitude (deg)');
  ylabel('latitude (deg)');
  title(titlestr, 'fontsize', plot_info.titlefontsize);
  hold on;
  if do_plot_contour
    [_,h]=contour(plot_info.lon, plot_info.lat, h, [1 3 5 10 15], '--', 'linecolor', 0.7*[1 1 1]);
  end
  plot_info = plot_coastlines(plot_info, coastlines,
                              [plot_info.lon(1)   plot_info.lat(1)],
                              [plot_info.lon(end) plot_info.lat(end)]);
  if isfield(plot_info, 'known_location')
    for k=1:length(plot_info.known_location)
      plot_location(plot_info, plot_info.known_location(k).coord, plot_info.known_location(k).name, true);
    end
  end

end

function [bb_lon,bb_lat]=save_as_png_for_map(plot_info, filename, h)
  h(h>plot_info.h_max) = plot_info.h_max;

  ## find bounding box
  [bb_lon, bb_lat, idx_lon, idx_lat] = find_bounding_box(plot_info, h);

  ## truncate h to the bounding box
  h = h(idx_lat, idx_lon);

  ## save as png (ground overlay for google maps)
  h        = flipud(h);
  rgb      = plot_info.z_to_rgb(h);
  alpha    = single(h != plot_info.h_max);
  ## fade out starting with sigma=6
  b        = h > 0.3*plot_info.h_max & h < plot_info.h_max;
  alpha(b) = (plot_info.h_max-h(b))/(plot_info.h_max*(1-0.3));

  ## write the png image
  imwrite(rgb, filename, 'Alpha', alpha);
endfunction

function save_as_json_for_map(filename, pfn, h, bb_lon, bb_lat, plot_info, plot_contour)
  s.filename     = pfn;
  s.imgBounds    = struct('south', bb_lat(1),
                          'north', bb_lat(2),
                          'east',  bb_lon(1),  ## NOTE: east and west were reversed before
                          'west',  bb_lon(2));
  s.plot_coutour = plot_contour;
  get_rgb = @(x) round(255*(plot_info.z_to_rgb(x)));
  c = get(h);
  for i=1:length(c.children)
    ci = get(c.children(i));
    if ~isnan(ci.vertices(end,end)) ## closed contours -> polygons
      s.polygons{end+1} = struct('lng', num2cell(ci.vertices(:,1)),
                                 'lat', num2cell(ci.vertices(:,2)));
      s.polygon_colors{end+1} = sprintf('#%02x%02x%02x', get_rgb(ci.cdata));
    else                            ## open  contours -> polylines
      s.polylines{end+1} = struct('lng', num2cell(ci.vertices(1:end-1,1)),
                                  'lat', num2cell(ci.vertices(1:end-1,2)));
      s.polyline_colors{end+1} = sprintf('#%02x%02x%02x', get_rgb(ci.cdata));
    end
  end
  fid = fopen(filename, 'w');
  json_save_cc(fid, s, false); ## compact JSON (without space/tab/crlf)
  fclose(fid);
endfunction

function plot_location(plot_info, coord, label, is_known_location)
  markers = { 'b*', 'kx' };
  colors  = { 'blue', 'black' };
  plot(coord(2), coord(1), markers{1+is_known_location});
  texthandle = text(coord(2), coord(1), label, ...
                    'fontsize', plot_info.labelfontsize, ...
                    'color', colors{1+is_known_location}, ...
                    'horizontalalignment', 'center', ...
                    'verticalalignment', 'baseline');
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
