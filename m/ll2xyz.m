## -*- octave -*-

function xyz=ll2xyz(ll)
  llr = ll.*(pi/180);
  xyz = [cos(llr(:,2)).*cos(llr(:,1)) ...
         sin(llr(:,2)).*cos(llr(:,1)) ...
         sin(llr(:,1))];
endfunction
