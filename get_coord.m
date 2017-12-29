## -*- octave -*-

function latlon=get_coord(name)
  ll.SM1OII    = [57.1873598, 18.2434909];
  ll.SM2BYC    = [65.9651988, 24.0333205];
  ll.Jusdalen  = [61.082117,  11.598090 ];
  ll.Kaustinen = [63.553000,  23.715000 ];
  ll.G8JNJ     = [50.9499466, -2.7232854];
  ll.DF0KL     = [  53.664812, 7.284788];##53.6458333,  7.2916667];
  ll.Khimki    = [55.9367557, 37.2271294];
  ll.F1JEK     = [45.7695,     0.598428 ];
  ll.GE0EZY    = [53.569271,  -1.061656 ]; # http://g0ezy-kiwisdr.ddns.net:8073/
  ll.RZ3DVP    = [55.800118,  36.8552651];
  ll.CS5SEL    = [38.7568,    -9.11667  ];
  ll.HG5ACZ    = [47.694347,  17.229556];
               ##[47.504274,  19.1349829];
  ll.HB9RYZ    = [47.1721,     8.42683  ];
  ll.IW2NKE    = [43.6624,    13.137    ];
  ll.Emerald   = [52.868484,  -6.858527 ];
  ll.JI1WSZ    = [35.772468, 139.8036965]; # http://kiwisdr.hirokinet.com:8074/
  ll.Tokyo     = [35.6708613,139.8070336]; # http://ractor.ddns.net:8073
  ll.Krageroe  = [58.8651958,  9.4564333]; # http://kiwisdr.kvitle.net:8073/
  ll.Kongsfjord= [70.720756,  29.319640 ]; # http://kongsdr.proxy.kiwisdr.com:8073/
  ll.SM2KOT    = [65.079120,  18.637727 ]; # http://aspliden.mooo.com:8073/
  latlon = getfield(ll, name);
end

