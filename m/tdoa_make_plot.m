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

  ## (2) compute time differences to each grid point
  n = length(input);
  for i=1:n
    dt{i} = deg2km(distance(input(i).coord, a))/299792.458;
  end

  ## (3) compute number of std deviations for each pair of receivers for each grid point
  hSum      = zeros(size(dt{1}));
  allnames  = [];
  for i=1:n
    allnames = sprintf('%s %s', allnames, input(i).name);
    for j=1+i:n
      b = tdoa(i,j).lags_filter;
      xlag = sum(tdoa(i,j).peaks(b).**2 .* tdoa(i,j).lags(b))              / sum(tdoa(i,j).peaks(b).**2);
      slag = sum(tdoa(i,j).peaks(b).**2 .* (tdoa(i,j).lags(b) - xlag).**2) / sum(tdoa(i,j).peaks(b).**2);
      slag = max((50e-6)**2, slag);
      ##      tdoa(i,j).h = (dt{i}-dt{j}-mean(tdoa(i,j).lags)).**2 / std(tdoa(i,j).lags)**2;
      tdoa(i,j).h = (dt{i}-dt{j}-xlag).**2 / slag;
      [fid, tdoa(i,j).dn] = mkstemp('data-XXXXXX', 'delete');
      fprintf(fid, '%g %g %g\n', [a(:,1:2) min(20, sqrt(tdoa(i,j).h))]');
      fclose(fid);
      idx = sqrt(tdoa(i,j).h)<20;
      [fid, tdoa(i,j).dns] = mkstemp('data-XXXXXX', 'delete');
      fprintf(fid, '%g %g %g\n', [a(idx,1:2) sqrt(tdoa(i,j).h(idx))]');
      fclose(fid);
      [fid, tdoa(i,j).cn] = mkstemp('coord-XXXXXX', 'delete');
      if isfield(plot_info, 'known_location')
        for k=1:length(plot_info.known_location)
          fprintf(fid, '%f %f %s\n', plot_info.known_location(k).coord, plot_info.known_location(k).name);
        end
      end
      fprintf(fid, '%f %f %s\n', input(i).coord, input(i).name);
      fprintf(fid, '%f %f %s\n', input(j).coord, input(j).name);
      fclose(fid);
      b = tdoa(i,j).lags_filter;
      tdoa(i,j).title   = sprintf('%s-%s:  dt=%.0fus RMS(dt)=%.0fus',
                                  input(i).name, input(j).name, mean(tdoa(i,j).lags(b))*1e6, std(tdoa(i,j).lags(b))*1e6);
      tdoa(i,j).xrange  = [min(a(:,2)), max(a(:,2))];
      tdoa(i,j).yrange  = [min(a(:,1)), max(a(:,1))];
      tdoa(i,j).cbrange = [0 20];
      tdoa(i,j).cblabel = 'sigma';
      hSum             += tdoa(i,j).h;
    end
  end
  allnames(allnames==" ") = '-';

  ## (4) compute chi2 for all pairs of receivers for each grid point
  [fid, tdoa(n-1,2).cn] = mkstemp('coord-XXXXXX', 'delete');
  if isfield(plot_info, 'known_location')
    for k=1:length(plot_info.known_location)
      fprintf(fid, '%f %f %s\n', plot_info.known_location(k).coord, plot_info.known_location(k).name);
    end
  end
  for i=1:n
    fprintf(fid, '%f %f %s\n', input(i).coord, input(i).name);
  end
  fclose(fid);

  [fid, tdoa(n-1,2).dn] = mkstemp('data-XXXXXX', 'delete');
  fprintf(fid, '%f %f %f\n', [a(:,1:2) min(20, sqrt(hSum)/n)]');
  fclose(fid);
  idx = sqrt(hSum)/n<20;
  [fid, tdoa(n-1,2).dns] = mkstemp('data-XXXXXX', 'delete');
  fprintf(fid, '%g %g %g\n', [a(idx,1:2) sqrt(hSum(idx))/n]');
  fclose(fid);
  tdoa(n-1,2).title   = allnames(2:end);
  tdoa(n-1,2).xrange  = [min(a(:,2)), max(a(:,2))];
  tdoa(n-1,2).yrange  = [min(a(:,1)), max(a(:,1))];
  tdoa(n-1,2).cbrange = [0 20];
  tdoa(n-1,2).cblabel = 'chi2/ndf';

  ## (5) generate gnuplot script and run gnuplot
  plot_contour = false;
  if isfield(plot_info, 'plot_contours')
    plot_contour = plot_info.plot_contours;
  end
  do_plot(tdoa, plot_info.plotname, plot_contour, plot_info.title);
endfunction

function do_plot(plot_data, plot_filename, plot_contour, plot_title)
  [n,m] = size(plot_data);
  [fid, name] = mkstemp('gnuplot-XXXXXX', 'delete');
  fprintf(fid, 'set output "png/%s.png"\n', plot_filename);
  fprintf(fid, 'set terminal png size %d,%d enhanced font "Helvetica,18"\n', 1.0*[800 600].*[n n]);

  fprintf(fid, 'set multiplot title "%s"\n', plot_title);
  fprintf(fid, 'set palette model RGB\n');
  fprintf(fid, 'set palette defined ( 0 "red", 0.5 "green", 1 "white" )\n');

  for i=1:m
    jrange = i+1:m;
    if i==m-1
      jrange = [2 jrange];
    end
    for j=jrange
      largePlot = (i==m-1 && j==2 && n==4);
      fprintf(fid, 'set origin   %f,%f\n', ([i-1 j-2] - largePlot*[1 0])/n .* [1 0.98]);
      fprintf(fid, 'set size     %f,%f\n', ([1 1]+largePlot*[1 1])/n .* [1 0.98]);
      fprintf(fid, 'set xrange  [%f:%f]\n', plot_data(i,j).xrange);
      fprintf(fid, 'set yrange  [%f:%f]\n', plot_data(i,j).yrange);
      fprintf(fid, 'set cbrange [%f:%f]\n', plot_data(i,j).cbrange);
      fprintf(fid, 'set xlabel  "longitude (deg)"\n');
      fprintf(fid, 'set ylabel  "latitude (deg)"\n');
      fprintf(fid, 'set cblabel "%s"\n', plot_data(i,j).cblabel);
      fprintf(fid, 'set title   "%s"\n', plot_data(i,j).title);
      fprintf(fid, 'set grid\n');
      if plot_contour
        fprintf(fid, 'set contour\n');
        fprintf(fid, 'unset surface\n');
        fprintf(fid, 'set cntrparam order 8\n');
        fprintf(fid, 'set cntrparam bspline\n');
        fprintf(fid, 'set isosamples 100,100\n');
        fprintf(fid, 'set cntrparam levels discrete 1,3,5,19\n');
        fprintf(fid, 'set dgrid3d 100,100,4\n');
        [_, cntr_name] = mkstemp('contour-XXXXXX', 'delete');
        fprintf(fid, 'set table "%s"\n', cntr_name);
        fprintf(fid, 'splot "%s" u 2:1:3 not\n', plot_data(i,j).dns);
        fprintf(fid, 'unset table\n');
        fprintf(fid, 'unset contour\n');

        fprintf(fid, 'plot "%s" using 2:1:3 w image t "", "<bzip2 -dc coastline/world_10m.txt.bz2" with lines linestyle 1 lc "gray" t "", "%s" using 2:1:3 w labels font ",12" offset .3,.3 point pt 71 lc "blue" not, "%s" u 1:($3<19 ? $2 : 1/0) lc 0 w l not, "<awk %s//{if ((NR%%160)==0 && $3<19){print}}%s %s" w labels font ",9" tc "gray" not\n',
                plot_data(i,j).dn, plot_data(i,j).cn, cntr_name, "'", "'", cntr_name);
      else
        fprintf(fid, 'plot "%s" using 2:1:3 w image t "", "<bzip2 -dc coastline/world_10m.txt.bz2" with lines linestyle 1 lc "gray" t "", "%s" using 2:1:3 w labels font ",12" offset .3,.3 point pt 71 lc "blue" not\n', plot_data(i,j).dn, plot_data(i,j).cn);
      end
    end
  end
  fprintf(fid, 'unset multiplot\n');
  fclose(fid);
  system(sprintf('gnuplot < %s', name));
endfunction

