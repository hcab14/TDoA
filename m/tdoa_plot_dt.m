## -*- octave -*-

function tdoa=tdoa_plot_dt(input, tdoa, plot_info, dt)
  plot_kiwi = false;
  if isfield(plot_info, 'plot_kiwi') && plot_info.plot_kiwi == true
    plot_kiwi = true;
  end

  if plot_kiwi
    set(0, 'defaultaxesposition', [0.1, 0.1, 0.8, 0.8]);
    figure(2, 'position', [200,200, 900,600]);
    colormap('default');
    set (0, "defaultaxesfontsize", 12)
    set (0, "defaulttextfontsize", 16)
  else
    figure(2, 'position', [200,200, 900,600]);
    colormap('default');
  end

  bin_width = 0.25/12001;

  n = length(input);
  for i=1:n
    for j=i+1:n
      tic;
      if plot_kiwi == false
        subplot(n-1,n-1, (n-1)*(i-1)+j-1);
      else
        clf;
      end
      ny   = length(tdoa(i,j).t);
      tmm  = [min(tdoa(i,j).t{1}) max(tdoa(i,j).t{1})];
      nx   = round(diff(tmm)/bin_width);
      bins = tmm(1)+bin_width*(0.5+[0:nx-1]);
      a    = zeros(ny,nx);
      for k=1:ny
        a(k,:)  = interp1(tdoa(i,j).t{k}, abs(tdoa(i,j).r{k}), bins);
        ##a(k,:) /= (1e-10 + max(abs(a(k,:))));
      end
      tdoa(i,j).bins = bins;
      imagesc(1e3*bins, tdoa(i,j).gpssec, a, [0 1]);
      set(colorbar(), 'YLabel', 'correlation coefficient')
      ylabel('GPS seconds');
      xlabel('dt (msec)');
      if plot_kiwi
        title({sprintf('%s-%s', input(i).name, input(j).name),
               plot_info.title});
      else
          title(sprintf('%s-%s', input(i).name, input(j).name));
      end
      [m,k] = max(mean(a));
      t0    = 1e3*bins(k);
      xlim(t0+1e3*dt*[-1 1]);
      if isfield(tdoa(i,j), 'time_cut')
        line(t0+1e3*dt*[-1 1], tdoa(i,j).time_cut(1), 'color', 'red', 'linewidth', 0.2);
        line(t0+1e3*dt*[-1 1], tdoa(i,j).time_cut(2), 'color', 'red', 'linewidth', 0.2);
      end
      if plot_kiwi == false
        set(gca, 'fontsize', 6);
      end
      tdoa(i,j).a = a;

      hold on;
      b = tdoa(i,j).lags_filter;
      plot(1e3*tdoa(i,j).lags,    tdoa(i,j).gpssec,    '*', 'markeredgecolor', 0.85*[1 1 1]);
      plot(1e3*tdoa(i,j).lags,    tdoa(i,j).gpssec,    '*', 'markeredgecolor', 0.85*[1 1 1]);
      plot(1e3*tdoa(i,j).lags(b), tdoa(i,j).gpssec(b), '*r');
      plot(1e3*tdoa(i,j).lags(b), tdoa(i,j).gpssec(b), '*r');
      hold off;
      printf('tdoa_plot_dt(%d,%d) %.2f sec\n', i,j, toc());
      if plot_kiwi
        print('-dpng','-S900,600', sprintf('%s/%s-%s dt.png', plot_info.dir, input(i).fname, input(j).fname));
        print('-dpdf','-S900,600', sprintf('%s/%s-%s dt.pdf', plot_info.dir, input(i).fname, input(j).fname));
      end
    end
  end
  if plot_kiwi == false
    ha = axes('Position', [0 0 1 1], ...
              'Xlim',     [0 1], ...
              'Ylim',     [0 1], ...
              'Box',      'off', ...
              'Visible',  'off', ...
              'Units',    'normalized', ...
              'clipping', 'off');
    text(0.5, 0.98,  plot_info.title, 'fontweight', 'bold', 'horizontalalignment', 'center', 'fontsize', 15);
    print('-dpng','-S900,600', fullfile('png', sprintf('%s_dt.png', plot_info.plotname)));
    print('-dpdf','-S900,600', fullfile('pdf', sprintf('%s_dt.pdf', plot_info.plotname)));
  end
endfunction

