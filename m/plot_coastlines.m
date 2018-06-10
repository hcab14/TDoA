## -*- octave -*-

function plot_coastlines(c, lonlat_min, lonlat_max)
  for i=1:length(c);
    if isempty(c{i})
      continue
    end
    b = c{i} > lonlat_min & c{i} < lonlat_max;
    if any(b(:,1)+b(:,2) == 2)
      plot(c{i}(:,1), c{i}(:,2), '-', 'color', 0.7*[1 1 1]);
    end
  end
endfunction
