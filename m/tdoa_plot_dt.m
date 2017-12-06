## -*- octave -*-

function tdoa=tdoa_plot_dt(input, tdoa, dt)
  bin_width = 0.25/12001;

  n = length(input);
  for i=1:n
    for j=i+1:n
      subplot(n-1,n-1, 1+ (n-1)*(i-1)+(n-j));
      ny   = length(tdoa(i,j).t);
      tmm  = [min(tdoa(i,j).t{1}) max(tdoa(i,j).t{1})];
      nx   = round(diff(tmm)/bin_width);
      bins = tmm(1)+bin_width*(0.5+[0:nx-1]);
      a    = zeros(ny,nx);
      for k=1:ny
        a(k,:) = interp1(tdoa(i,j).t{k}, abs(tdoa(i,j).r{k}), bins);
      end
      imagesc(1e6*bins, tdoa(i,j).gpssec, a);
      ylabel('GPS seconds');
      xlabel('dt (usec)');
      title(sprintf("%s-%s", input(i).name, input(j).name));
      [m,k] = max(mean(a));
      t0    = 1e6*bins(k);
      xlim(t0+dt*[-1 1]);
      if isfield(tdoa(i,j), 'time_cut')
        line(t0+dt*[-1 1], tdoa(i,j).time_cut(1), 'color', 'red', 'linewidth', 0.2);
        line(t0+dt*[-1 1], tdoa(i,j).time_cut(2), 'color', 'red', 'linewidth', 0.2);
      end
      set(gca, 'fontsize', 8);
      tdoa(i,j).a = a;

      hold on;
      plot(1e6*tdoa(i,j).lags_orig, tdoa(i,j).gpssec, '.r');
      plot(1e6*tdoa(i,j).lags_orig, tdoa(i,j).gpssec, '.r');
      hold off;
    end
  end
endfunction
