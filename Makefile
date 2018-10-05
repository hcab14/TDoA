all run: kiwi_extension

install:
	mkoctfile kiwiclient/read_kiwi_iq_wav.cc

update:
	git pull --recurse-submodules

read_kiwi_iq_wav.oct: kiwiclient/read_kiwi_iq_wav.cc
	mkoctfile kiwiclient/read_kiwi_iq_wav.cc

kiwi_extension: read_kiwi_iq_wav.oct
	@mkdir -p ../files/00000
	@cp iq/* ../files/00000
	@cp gnss_pos/*.txt ../files/00000
	-octave-cli --eval "proc_tdoa_kiwi('../files/00000',{'../files/00000/20171127T104156Z_77500_DF0KL_iq.wav','../files/00000/20171127T104156Z_77500_HB9RYZ_iq.wav','../files/00000/20171127T104156Z_77500_F1JEK_iq.wav'},struct('lat',[41:0.05:56],'lon',[-25:0.05:22],'known_location',struct('coord',[50.0152,9.0112],'name','DCF77')));"

dcf77: read_kiwi_iq_wav.oct
	octave-cli --eval proc_tdoa_DCF77;

clean:
	rm -f pdf/*.pdf png/*.png
