## -*- octave -*-

## types of plots:
##  plot_info.plot_type_octave = 'orig', 'kiwi', ''
##  plot_info.plot_kiwi_json = true, false

function [tdoa,status]=tdoa_plot_map(input_data, tdoa, plot_info)
  plot_kiwi = false;
  if isfield(plot_info, 'plot_kiwi')
    plot_kiwi = plot_info.plot_kiwi;
  end

  if ~isfield(plot_info, 'plot_kiwi_json')
    plot_info.plot_kiwi_json = false;
  end

  cmap = [linspace(1,0,100)' linspace(0,1,100)' zeros(100,1)     ## red to green
          linspace(0,1,100)' ones(100,1)   linspace(0,1,100)'];  ## green to white
  colormap(cmap);
  plot_info.cmap = cmap;

  plot_info.h_max = 20;
  plot_info.z_to_rgb = @(h, h_max, cmap) single(ind2rgb(1+round(h/(1e-10+h_max)*(size(cmap,1)-1)), cmap));

  if plot_info.new
    [tdoa,hSum] = tdoa_generate_maps_new(input_data, tdoa, plot_info);
  else
    [tdoa,hSum] = tdoa_generate_maps(input_data, tdoa, plot_info);
  end

  if ~plot_kiwi
    if ~isfield(plot_info, 'coastlines')
      plot_info.coastlines = 'coastline/world_50m.mat';
    end
    plot_info.coastlines_c = load(plot_info.coastlines).c;
  end

  if ~plot_kiwi
    set(0,'defaultaxesposition', [0.05, 0.05, 0.90, 0.9])
    figure(1, 'position', [100,100, 900,600])
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
      h = reshape(sqrt(tdoa(i,j).h), length(plot_info.lon), length(plot_info.lat))';
      if ~plot_kiwi
        tic;
        subplot(n_stn-1,n_stn-1, (n_stn-1)*(i-1)+j-1);
        title_extra = '';
        titlestr{1} = sprintf('%s-%s %s', input_data(i).name, input_data(j).name, title_extra);
        if ~plot_info.new
          b = tdoa(i,j).lags_filter;
          titlestr{2} = sprintf('dt=%.0fus RMS(dt)=%.0fus', mean(tdoa(i,j).lags(b))*1e6, std(tdoa(i,j).lags(b))*1e6);
        end
        plot_info = plot_map(plot_info,
                             h,
                             titlestr,
                             false);
        printf('tdoa_plot_map(%d,%d): [%.3f sec]\n', i,j, toc())
      end
      if plot_info.plot_kiwi_json
        [bb_lon, bb_lat] = save_as_png_for_map(plot_info,
                                               sprintf('%s/%s-%s_for_map.png', plot_info.dir, input_data(i).fname, input_data(j).fname),
                                               h);
        figure(2);
        [h,h_max] = adjust_scale(plot_info, h);
        [~,h] = contour(plot_info.lon, plot_info.lat, h, [1 3 5 10 15], '--', 'linecolor', 0.7*[1 1 1]);
        save_as_json_for_map(sprintf('%s/%s-%s_contour_for_map.json', plot_info.dir, input_data(i).fname, input_data(j).fname),
                             sprintf('%s/%s-%s_for_map.png', plot_info.dir, input_data(i).fname, input_data(j).fname),
                             h, h_max, bb_lon, bb_lat, plot_info, ~false);
        if ~plot_kiwi
          figure(1);
        end
      end
    end
  end

  if ~plot_kiwi
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
  end

  h = reshape(sqrt(hSum)/n_stn_used, length(plot_info.lon), length(plot_info.lat))';
  if ~plot_kiwi
    titlestr = allnames(1:end-1);
    plot_info = plot_map(plot_info,
                         h,
                         titlestr,
                         true);
    for i=1:n_stn
      plot_location(plot_info, input_data(i).coord, input_data(i).name, false);
    end
    set(colorbar(),'XLabel', 'sqrt(\chi^2)/ndf')
    printf('tdoa_plot_map_combined: [%.3f sec]\n', toc());
    ha = axes('Position', [0 0 1 1], ...
              'Xlim',     [0 1], ...
              'Ylim',     [0 1], ...
              'Box',      'off', ...
              'Visible',  'off', ...
              'Units',    'normalized', ...
              'clipping', 'off');
    text(0.5, 0.98,  plot_info.title, ...
         'fontweight', 'bold', ...
         'horizontalalignment', 'center', ...
         'fontsize', 15);
    print('-dpng','-S900,600', fullfile('png', sprintf('%s.png', plot_info.plotname)));
    print('-dpdf','-S900,600', fullfile('pdf', sprintf('%s.pdf', plot_info.plotname)));
  end
  if plot_info.plot_kiwi_json
    [h,h_max] = adjust_scale(plot_info, h);
    [bb_lon, bb_lat] = save_as_png_for_map(plot_info, sprintf('%s/%s_for_map.png', plot_info.dir, plot_info.plotname), h);
    figure(2)
    [~,h] = contour(plot_info.lon, plot_info.lat, h, [1 3 5 10 15], '--', 'linecolor', 0.7*[1 1 1]);
    save_as_json_for_map(sprintf('%s/%s_contour_for_map.json', plot_info.dir, plot_info.plotname),
                         sprintf('%s/%s_for_map.png', plot_info.dir, plot_info.plotname),
                         h, h_max, bb_lon, bb_lat, plot_info, true);
    close(2);
  end
endfunction

function [h,h_max] = adjust_scale(plot_info, h)
  if plot_info.new
    ## subtract minimum
    h_min = min(min(h));
    h    -= h_min;
    ## dynamically adjust the scale such that the median is 4
    h_max = median(reshape(h,1,numel(h)));
    h    *= plot_info.h_max/h_max;
  end
  h_max = plot_info.h_max;
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

function plot_info=plot_map(plot_info, h, titlestr, do_plot_contour)
  h(h>plot_info.h_max) = plot_info.h_max;
  imagesc('xdata', plot_info.lon([1 end]),
          'ydata', plot_info.lat([1 end]),
          'cdata', h);##, [0 20]);
  hold on
  set(gca,'YDir','normal');
  xlabel('longitude (deg)');
  ylabel('latitude (deg)');
  xlim(plot_info.lon([1 end]));
  ylim(plot_info.lat([1 end]));
  title(titlestr, 'fontsize', plot_info.titlefontsize);
  if do_plot_contour
    contour(plot_info.lon, plot_info.lat, h, [1 3 5 10 15]*plot_info.h_max/20, '--', 'linecolor', 0.7*[1 1 1]);
  end
  plot_info = plot_coastlines(plot_info,
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

  ## apply map projection
  h = correct_for_projection(h, bb_lat);

  ## save as png (ground overlay for google maps)
  h        = flipud(h);
  rgb      = plot_info.z_to_rgb(h, min(plot_info.h_max, max(max(h))), plot_info.cmap);
  alpha    = single(h != plot_info.h_max);
  ## fade out starting with sigma=6
  b        = h > 0.3*plot_info.h_max & h < plot_info.h_max;
  alpha(b) = (plot_info.h_max-h(b))/(plot_info.h_max*(1-0.3));

  ## write the png image
  imwrite(rgb, filename, 'Alpha', alpha);
endfunction

function h=correct_for_projection(h, bb_lat)
  ## latitude array in bounding box
  n    = size(h,1);
  lats = bb_lat(1) + diff(bb_lat) * (0:n-1)/(n-1);

  ## latitude inverse Mercator projection function
  f    = @(y) 2*atan(exp(y)) - pi/2;

  ## y(lats) \in [0,1]
  d2r  = @(x) x/180*pi; ## deg2rad
  y    = @(lat) (f(d2r(lat)) - f(d2r(bb_lat(1)))) / diff(f(d2r(bb_lat)));

  ## lookup indices
  idx  = 1 + round((n-1) * y(lats));

  ## apply the transformation to the latitude dimension of h
  for j=1:size(h,2)
    h(:,j) = h(idx,j);
  end
endfunction

function save_as_json_for_map(filename, pfn, h, h_max, bb_lon, bb_lat, plot_info, plot_contour)
  s.filename     = pfn;
  s.imgBounds    = struct('south', bb_lat(1),
                          'north', bb_lat(2),
                          'east',  bb_lon(1),  ## NOTE: east and west were reversed before
                          'west',  bb_lon(2));
  s.plot_coutour = plot_contour;
  get_rgb = @(x) round(255*(plot_info.z_to_rgb(x, min(plot_info.h_max, h_max), plot_info.cmap)));
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
