
name='Abel Tasman - Torrent Bay to Tonga'
scale="1:35000"
chart_no=NZ6144
scratch=scratch.png

kappath=/usr/local/share/charts/LINZ/NewZealand
proj=2193
chart_prefix=$(chart_no)-EPSG-$(proj)
chart=$(chart_prefix).tiff

tracks=$(patsubst gpx/%.gpx,%.gpx,$(wildcard gpx/*.gpx))

track_proj=$(patsubst %,tmp/%,$(tracks))
track_overlays=$(patsubst %,%-$(chart),$(tracks))

all: $(scratch) $(track_overlays)

overlays: $(track_overlays)

$(chart): $(kappath)/$(chart_no).kap
	gdalwarp -of GTiff -t_srs EPSG:$(proj) "$<" "$@"


$(scratch): $(chart)
	convert \
   -size 2240x3350 xc:white \
   -density 300x300 \
       "$(chart)[2080x3148+4700+5500]" -geometry +80+60    -composite \
       "$(chart)[2072x60+4700+594]"    -geometry +80+0     -composite \
       "$(chart)[2072x60+4700+12336]"  -geometry +80+3208  -composite \
       "$(chart)[80x3148+427+5500]"    -geometry +0+60     -composite \
       "$(chart)[80x3148+7999+5500]"   -geometry +2152+60  -composite \
   -stroke black -fill none \
   -draw "polyline 80,60 2152,60 2152,3208 80,3208 80,60" \
   -stroke black -fill black \
   -font 'Helvetica-Bold' \
   -pointsize 16 \
   -annotate +80+3325 $(name)  \
   -font 'Helvetica' \
   -pointsize 8 \
   -annotate +1500+3320 "(from $(chart_no). Not to be used for navigation.)" \
   -pointsize 5 \
   -annotate +2152+3208 "176\n267" \
   "$@" 2> /dev/null

tmp/%: gpx/%
	rm -rf $@
	mkdir -p $@
	ogr2ogr -t_srs EPSG:$(proj) $@ $< tracks
	
%-$(chart): tmp/% $(chart)
	gdal_translate -of GTiff -scale 0 255 0 0 $(chart) $@
	gdal_rasterize -b 1 -burn 8 -l tracks $< $@


clean:
	rm -rf *.tiff *.png
	rm -rf tmp
