## -*- octave -*-

function tdoa=tdoa_plot_dt_new(input, tdoa, plot_info, dt)
  plot_kiwi = false;
  if isfield(plot_info, 'plot_kiwi')
    plot_kiwi = plot_info.plot_kiwi;
  end

  if plot_kiwi
    set(0, 'defaultaxesposition', [0.1, 0.1, 0.8, 0.8]);
    figure(2, 'position', [200,200, 1024,690]/2);
    set(0, "defaultaxesfontsize", 12)
    set(0, "defaulttextfontsize", 16)
  else
    figure(2, 'position', [200,200, 900,600]/2);
  end
  colormap('default');

  n = length(input);
  for i=1:n
    for j=i+1:n
      tic;
      if ~plot_kiwi
        subplot(n-1,n-1, (n-1)*(i-1)+j-1);
      else
        clf;
      end
      [s2min,kmin] = min(tdoa(i,j).sigma2);
      cdt_min      = tdoa(i,j).lags(kmin)*3e5; ## km
      plot(tdoa(i,j).lags*3e5, tdoa(i,j).sigma2, '*-',
           cdt_min, s2min, sprintf('r*;c\\Deltat=%.0f km;', cdt_min))
      xlim([-0.02 0.02]*3e5)
      ylim([0 max(tdoa(i,j).sigma2)])
      xlabel(sprintf('c\Deltat (km)  (1 bin = %.0f km)', diff(tdoa(i,j).lags)(1)*3e5))
      ylabel('\sigma^2')
      if plot_kiwi
        title({sprintf('%s-%s c\\Deltat=%.1f km', input(i).name, input(j).name, cdt_min),
               plot_info.title}, 'fontsize', 16);
      else
          title(sprintf('%s-%s', input(i).name, input(j).name));
          set(gca, 'fontsize', 6);
      end
      if plot_kiwi
        print('-dpng','-S1024,690', sprintf('%s/%s-%s dt.png', plot_info.dir, input(i).fname, input(j).fname));
      end
      printf('tdoa_plot_dt(%d,%d): [%.3f sec]\n', i,j, toc());
    end
  end
  if ~plot_kiwi
   ha = axes('Position', [0 0 1 1], ...
             'Xlim',     [0 1], ...
             'Ylim',     [0 1], ...
             'Box',      'off', ...
             'Visible',  'off', ...
             'Units',    'normalized', ...
             'clipping', 'off');
   text(0.5, 0.98,  plot_info.title, 'fontweight', 'bold', 'horizontalalignment', 'center', 'fontsize', 15);
   print('-dpng','-S900,600', fullfile('png', sprintf('%s_dt.png', plot_info.plotname)));
  end
endfunction

