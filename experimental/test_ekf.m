# -*- octave -*-

function [_x,z,P,Q,G]=test_ekf
  pkg load optim
  addpath ("../iri-octave")
  addpath ("../geographiclib-octave")
  ##
  load tdoa.mat
  tdoa.fn

  ## WGS84 -> spherical
#  for i=1:length(tdoa)
#    tdoa(i).coord = xyz2ll(1e3*ll2xyz_wgs84(tdoa(i).coord));
#  end

  ## WGS84->XYZ->Spherical (-0.2,0.0)
  ## Spherical->XYZ->WGS84 (+0.2,0.0)
  [34.621; 32.946]
  xyz2ll(1e3*ll2xyz_wgs84([34.621; 32.946]))
  xyz2ll_wgs84(1e3*ll2xyz([34.621; 32.946]))

  iri_config.jf       = [1 0 0 0 1 0 1 1 1 1 ...
                         1 1 1 1 1 1 1 1 1 1 ...
                         0 1 0 1 1 1 1 0 0 0 ...
                         1 1 0 1 0 1 1 1 0 1 ...
                         1 1 1 1 1 1 1 1 1 1 ...
                         1]; ## see src/irisub.for
  iri_config.data_dir = '../iri-octave/data';

  f = @(x) x;
 #  h = @(x) compute_dt(tdoa, x);
  h = @(x) compute_dt_wgs84(tdoa, x);
#  h = @(x) compute_dt_iono(tdoa, x', iri_config);
  x = [34.621; 32.946]; ## state
#  x += [-1; 1];
#
#  x = [46; 45];
  z = extract_measurements(input, tdoa);


  P = diag([1 1])*0.1000**2;
  Q = diag([1 1])*0.0100**2;
  R = make_R(length(input), input) ##*80**2

  for j=1:5
    for i=1:min(60,size(z,2))
      [x,P]= ekf(z(:,i),x,P,Q,R,f,h);
      _x(end+1,:)=x;
    end
  end
  x
  P
endfunction

function [x,P]=ekf(z,x,P,Q,R,f,h)
  hook.diffp = [1 1]*1e-3;
  Phi = dfpdp(x, f);
  printf("eval of dfpdp(x,h) [%f,%f]\n", x);
  H   = dfpdp(x, h, hook);
  xp  = f(x);
  printf("eval of h [%f,%f]\n", x);
  fflush(stdout);
  zp  = h(xp);
  Pp  = Phi*P*Phi' + Q;
  G   = Pp*H' / (H*Pp*H' + R);
  x   = xp + G*(z - zp);
  P   = (eye(size(Q)) - G*H)*Pp;
endfunction


function dt=compute_dt(tdoa, x)
  x = xyz2ll(1e3*ll2xyz_wgs84(x))';
  n = length(tdoa);
  dt=[];
  for i=1:n
    for j=i+1:n
      dt(end+1,1) = 1e6*deg2km(distance(x', tdoa(i).coord) - distance(x', tdoa(j).coord))/299792.458;
    end
  end
endfunction

function dt=compute_dt_wgs84(tdoa, x)
  n = length(tdoa);
  f=1;##1.01;
  dt=[];
  for i=1:n
    dt_1 = 1e6*dist_wgs84(x,tdoa(i).coord')/299792458/f;
    for j=i+1:n
      dt_2 = 1e6*dist_wgs84(x,tdoa(j).coord')/299792458/f;
      dt(end+1,1) = dt_1 - dt_2;
    end
  end
endfunction

function dt=compute_dt_iono(tdoa, x, iri_config)
  x = xyz2ll(1e3*ll2xyz_wgs84(x));
  n = length(tdoa);
  dt=[];
  freq=17.030e6;
  for i=1:n
    dt_1  = 1e6*iri_dt(iri_config, x, tdoa(i).coord, 2018, 113, 11+26/60, 1, freq);
    for j=i+1:n
      dt_2  = 1e6*iri_dt(iri_config, x, tdoa(j).coord, 2018, 113, 11+26/60, 1, freq);
      printf("%d,%d %e,%e  [%f,%f] [%f,%f] [%f,%f]\n", i,j, dt_1(1), dt_2(1),x, tdoa(i).coord, tdoa(j).coord);
      dt(end+1,1) = dt_1(1) - dt_2(1);
##      dt(end+1,1) = dt_1_(1) - dt_2_(1);
    end
  end
  fflush(stdout);
endfunction

function R=make_R(n, input)
  m = n*(n-1)/2;
  for i=1:n
    for j=i+1:n
      idx(end+1,1:2) = [i j];
    end
  end

  for i=1:m
    for j=1:m
      _R(i,j) = sum(idx(i,:)==idx(j,:)) - sum(idx(i,:)==idx(j,2:-1:1));
      R(i,j) = 1e12*cov(input(idx(i,1), idx(i,2)).lags,
                        input(idx(j,1), idx(j,2)).lags);
    end
  end
  R .*= (_R!=0);
  ##  R = eye(m);
endfunction

function z=extract_measurements(input, tdoa)
  b = [];
  n = length(tdoa)
  for i=1:n
    for j=i+1:n
      if isempty(b)
        b  = input(i,j).lags_filter;
      else
        b &= input(i,j).lags_filter;
      end
    end
  end
  z=[]; ## measurements
  for i=1:n
    for j=i+1:n
      z(end+1,:) = 1e6*input(i,j).lags(b);
    end
  end
end

function ll=xyz2ll_wgs84(xyz)
  ## WGS83 ellipsoid
  a = 6378137;
  b = 6356752.314245;
  f = 1/298.257223563;

  e2   = 2*f - f**2
  eps2 = e2 / (1 - e2)
  p = sqrt(sum(xyz(1:2).**2));
  R = sqrt(sum(xyz.**2));

  tanbeta = b*xyz(3) / (a*p) * (1 + eps2*b/R);
  sinbeta = tanbeta/sqrt(1-tanbeta**2);
  cosbeta = sinbeta / tanbeta;

  beta = atan2(xyz(3)*a, p*b);
  sinbeta = sin(beta);
  cosbeta = cos(beta);
  phi = 0;
  if !isnan(cosbeta)
    phi = atan2(xyz(3) + eps2*b*sinbeta**3, p - e2*a*cosbeta**3);
  end
  lambda = atan2(xyz(2),xyz(1));

    ## // height above ellipsoid (Bowring eqn 7) [not currently used]
    ## var sinφ = Math.sin(φ), cosφ = Math.cos(φ);
    ## var ν = a/Math.sqrt(1-e2*sinφ*sinφ); // length of the normal terminated by the minor axis
    ## var h = p*cosφ + z*sinφ - (a*a/ν);

  ll = [phi lambda]/pi*180;
endfunction

function xyz=ll2xyz_wgs84(ll)
  phi    = ll(1)/180*pi; # lat
  lambda = ll(2)/180*pi; # lon
  h =0;
  ## WGS84 ellipsoid
  a = 6378137;
  b = 6356752.314245;
  f = 1/298.257223563;

  eSq = 2*f - f**2;
  nu  = a / sqrt(1 - eSq*sin(phi)**2);

  xyz = [ (nu+h)*cos(phi)*cos(lambda);
          (nu+h)*cos(phi)*sin(lambda);
          (nu*(1-eSq)+h)*sin(phi)];
endfunction

function xyz=ll2xyz(ll)
  llr = deg2rad(ll);
  xyz = 6371*[cos(llr(2))*cos(llr(1))
              sin(llr(2))*cos(llr(1))
              sin(llr(1))];
endfunction
function ll=xyz2ll(xyz)
  ll = rad2deg([atan2(xyz(3), sqrt(sum(xyz(1:2).**2))) atan2(xyz(2), xyz(1))]);
endfunction
