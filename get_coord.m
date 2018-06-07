## -*- octave -*-

function latlon=get_coord(name)
  d = kiwi_info();
  latlon=getfield(d, name).coord;
end

