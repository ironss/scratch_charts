
kappath=/usr/local/share/charts/LINZ/NewZealand
proj=2193

chart_no=NZ6144
chart_prefix=$(chart_no)-EPSG-$(proj)
chart=$(chart_prefix).tiff

charts=NZ614 NZ6144
charts_gtiff=$(patsubst %,%-EPSG-$(proj).tiff,$(charts))

scratch_charts=NZ6144_Torrent_Bay_to_Tonga
scratch_pngs=$(patsubst %,%-scratch.png,$(scratch_charts))


tracks=$(patsubst gpx/%.gpx,%.gpx,$(wildcard gpx/*.gpx))
tracks_georef=$(patsubst %,tmp/%,$(tracks))
track_overlays=$(patsubst %,%-$(chart),$(tracks))
scratch_overlay_pngs=$(patsubst %,%-overlay.png,$(scratch_charts))


# General targets
all: $(scratch_pngs) $(charts_gtiff) $(track_overlays) $(scratch_overlay_pngs)
overlays: $(track_overlays)


# Dependencies for individual scratch charts
NZ6144_Torrent_Bay_to_Tonga-scratch.png: NZ6144_Torrent_Bay_to_Tonga.spec  NZ6144-EPSG-$(proj).tiff
	./$^ $@

# Overlays
NZ6144_Torrent_Bay_to_Tonga-overlay.png: NZ6144_Torrent_Bay_to_Tonga.spec  NZ6144-EPSG-$(proj)-overlay.tiff
	./$^ $@

NZ6144-EPSG-$(proj)-overlay.tiff: NZ6144-EPSG-$(proj).tiff $(track_overlays)
	convert $< $(patsubst %,% -composite,$(track_overlays)) $@


# Create a GTiff (with a SRS) from a kap file
%-EPSG-$(proj).tiff: $(kappath)/%.kap
	gdalwarp -of GTiff -co COMPRESS=LZW  -t_srs EPSG:$(proj) "$<" "$@"

# Project a GPX file to a ESRI shapefile with a specified projections
tmp/%: gpx/%
	rm -rf $@
	mkdir -p $@
	ogr2ogr -f "ESRI Shapefile" -t_srs EPSG:$(proj) $@ $< tracks

# Create an overlay-chart 
%-$(chart): tmp/% $(chart)
	gdal_translate -of GTiff -co COMPRESS=LZW  -scale 0 255 0 0 $(chart) $@
	gdal_rasterize -b 1 -burn 8 -l tracks $< $@
	mogrify -morphology Erode Octagon -fill red -opaque black -transparent white  $@


clean:
	rm -rf *.tiff *.png
	rm -rf tmp

