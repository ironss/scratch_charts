
charts = 
charts += NZ63 
charts += NZ632 
charts += NZ6321 
charts += NZ6321_1 
charts += NZ6324 
charts += NZ6324_1 
charts += NZ64

srcdir = /usr/local/share/charts/LINZ/NewZealand

pngdir = png
pngfiles = $(patsubst %,$(pngdir)/%.png,$(charts))

allpngfiles: $(pngfiles)

$(pngdir)/%.kap: $(srcdir)/%.kap
	mkdir -p $(pngdir)
	cp $< $@
	
$(pngdir)/%.png: $(pngdir)/%.kap
	gdal_translate -of PNG "$<" "$@"

