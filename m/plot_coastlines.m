## -*- octave -*-

function plot_info=plot_coastlines(plot_info, lonlat_min, lonlat_max)
  if isfield(plot_info, 'clipped_coastlines')
    c = plot_info.clipped_coastlines;
    for i=1:length(c)
      plot(c{i}(:,1), c{i}(:,2), '-', 'color', 0.7*[1 1 1]);
    end
  else
    c  = plot_info.coastlines_c;
    cc = cell;
    j  = 1;
    for i=1:length(c)
      if isempty(c{i})
	continue
      end
      b = c{i} > lonlat_min & c{i} < lonlat_max;
      if any(b(:,1)+b(:,2) == 2)
	cc{j} = c{i};
	j    += 1;
	plot(c{i}(:,1), c{i}(:,2), '-', 'color', 0.7*[1 1 1]);
      end
    end
    plot_info.clipped_coastlines = cc;
  end
endfunction
