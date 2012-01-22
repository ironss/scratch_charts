
banks_charts = 
banks_charts += NZ61
banks_charts += NZ614
banks_charts += NZ614_1
banks_charts += NZ614_2
banks_charts += NZ6142_1
banks_charts += NZ6142_2
banks_charts += NZ6143
banks_charts += NZ6144
banks_charts += NZ6144_1

abel_charts = 
abel_charts += NZ63 
abel_charts += NZ632 
abel_charts += NZ6321 
abel_charts += NZ6321_1 
abel_charts += NZ6324 
abel_charts += NZ6324_1 
abel_charts += NZ64

charts =
charts += $(banks_charts)
charts += $(abel_charts)


srcdir = /usr/local/share/charts/LINZ/NewZealand

pngdir = png
outdir = out

pngfiles = $(patsubst %,$(pngdir)/%.png,$(charts))
kapfiles = $(patsubst %,$(pngdir)/%.kap,$(charts))
dbfiles = $(patsubst %,$(outdir)/%/OruxMapsImages.db,$(charts))

infiles: allkapfiles allpngfiles $(outdir)
outfiles: OruxMapsImages.db

Abel/OruxMapsImages.db: $(patsubst %,$(outdir)/%/OruxMapsImages.db,$(abel_charts))
	./create_charts_step2_abel
	
Banks/OruxMapsImages.db: $(patsubst %,$(outdir)/%/OruxMapsImages.db,$(banks_charts))
	./create_charts_step2_banks

$(outdir):
	mkdir -p "$(outdir)"
	
allpngfiles: $(pngfiles)
allkapfiles: $(kapfiles)

$(pngdir)/%.kap: $(srcdir)/%.kap
	mkdir -p "$(pngdir)"
	cp "$<" "$@"
	
$(pngdir)/%.png: $(pngdir)/%.kap
	gdal_translate -of PNG "$<" "$@"

clean:
	rm -rf "$(outdir)"
	rm -rf "$(pngdir)"
	
