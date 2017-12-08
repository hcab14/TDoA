## -*- octave -*-

function latlon=get_coord(name)
  ll.SM1OII    = [57.1873598, 18.2434909];
  ll.SM2BYC    = [65.9651988, 24.0333205];
  ll.Jusdalen  = [61.082117,  11.598090 ];
  ll.Kaustinen = [63.553000,  23.715000 ];
  ll.G8JNJ     = [50.9499466, -2.7232854];
  ll.DF0KL     = [53.6458333,  7.2916667];
  ll.Khimki    = [55.9367557, 37.2271294];
  ll.F1JEK     = [45.7695,     0.598428 ];
  ll.GE0EZY    = [51.895560,  -2.046899 ];
  ll.RZ3DVP    = [55.800118,  36.8552651];
  ll.CS5SEL    = [38.7568,    -9.11667  ];
  ll.HG5ACZ    = [47.504274,  19.1349829];
  ll.HB9RYZ    = [47.1721,     8.42683  ];

  latlon = getfield(ll, name);
end

