
kappath=/usr/local/share/charts/LINZ/NewZealand
proj=2193

chart_no=NZ6144
chart_prefix=$(chart_no)-EPSG-$(proj)
chart=$(chart_prefix).tiff

charts=NZ614 NZ6144
charts_gtiff=$(patsubst %,%-EPSG-$(proj).tiff,$(charts))

tracks=$(patsubst gpx/%.gpx,%.gpx,$(wildcard gpx/*.gpx))
tracks_georef=$(patsubst %,tmp/%,$(tracks))

track_overlays=$(patsubst %,%-$(chart),$(tracks))

scratch_charts=abel_tasman_torrent_tonga
scratch_pngs=$(patsubst %,%-scratch.png,$(scratch_charts))
scratch_overlay_pngs=$(patsubst %,%-overlay.png,$(scratch_charts))

all: $(scratch_pngs) $(charts_gtiff) $(track_overlays) $(scratch_overlay_pngs)

abel_tasman_torrent_tonga-scratch.png: abel_tasman_torrent_tonga NZ6144-EPSG-$(proj).tiff
	./$< NZ6144-EPSG-$(proj).tiff $@

abel_tasman_torrent_tonga-overlay.png: abel_tasman_torrent_tonga NZ6144-EPSG-$(proj)-overlay.tiff
	./abel_tasman_torrent_tonga NZ6144-EPSG-$(proj)-overlay.tiff $@

NZ6144-EPSG-$(proj)-overlay.tiff: NZ6144-EPSG-$(proj).tiff $(tracks_georef)
	./overlay $@ $^

overlays: $(track_overlays)


# Create a GTiff with a SRS from a kap file
%-EPSG-$(proj).tiff: $(kappath)/%.kap
	gdalwarp -of GTiff -t_srs EPSG:$(proj) "$<" "$@"

tmp/%: gpx/%
	rm -rf $@
	mkdir -p $@
	ogr2ogr -f "ESRI Shapefile" -t_srs EPSG:$(proj) $@ $< tracks

%-$(chart): tmp/% $(chart)
	gdal_translate -of GTiff -scale 0 255 0 0 $(chart) $@
	gdal_rasterize -b 1 -burn 8 -l tracks $< $@


clean:
	rm -rf *.tiff *.png
	rm -rf tmp

