## -*- octave -*-

function latlon=get_coord(vname, dir)
  d = kiwi_info(dir);
  latlon=getfield(d, vname).coord;
end

