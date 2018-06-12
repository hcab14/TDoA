BEGIN {
  printf("function c=%s\n c={single([", name);
}
// {
  if (NF==2) {
    printf("%f %f\n",$1,$2)
  }
}
// {
  if (NF==0) {
    printf("]),single([")
  }
}
END {
  printf("])};\nend\n")
}
