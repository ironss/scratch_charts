
charts = 
charts += NZ61
charts += NZ614
charts += NZ614_1
charts += NZ614_2
charts += NZ6142_1
charts += NZ6142_2
charts += NZ6143
charts += NZ6144
charts += NZ6144_1

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
kapfiles = $(patsubst %,$(pngdir)/%.kap,$(charts))

outdir = out

all: allkapfiles allpngfiles $(outdir)

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
	
