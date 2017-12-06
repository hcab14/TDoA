## -*- octave -*-

function tdoa=tdoa_plot_dt(input, tdoa, dt)
  n = length(input);
  for i=1:n
    for j=i+1:n
      subplot(n-1,n-1, 1+ (n-1)*(i-1)+(n-j));
      ny = length(tdoa(i,j).t);
      for k=1:ny
        nx = length(tdoa(i,j).t{k});
        di = round(min(tdoa(i,j).t{k})*12001);
        a(k,1+round(tdoa(i,j).t{k}(1:nx)*12001)-di) = abs(tdoa(i,j).r{k}(1:nx));
      end
      imagesc(1e6*tdoa(i,j).t{1}, tdoa(i,j).gpssec,a(:,1:nx));
      ylabel('GPS seconds');
      xlabel('dt (usec)');
      title(sprintf("%s-%s", input(i).name, input(j).name));
      [m,k] = max(mean(a));
      t0    = 1e6*tdoa(i,j).t{1}(k);
      xlim(t0+dt*[-1 1]);
      if isfield(tdoa(i,j), 'time_cut')
        line(t0+dt*[-1 1], tdoa(i,j).time_cut(1), 'color', 'red', 'linewidth', 0.2);
        line(t0+dt*[-1 1], tdoa(i,j).time_cut(2), 'color', 'red', 'linewidth', 0.2);
      end
      set(gca, 'fontsize', 8);
      tdoa(i,j).a = a;

      hold on;
      plot(1e6*tdoa(i,j).lags_orig, tdoa(i,j).gpssec, '.r');
      hold off;
    end
  end
endfunction
