
kappath=/usr/local/share/charts/LINZ/NewZealand
proj=2193

chart_no=NZ6144
chart_prefix=$(chart_no)-EPSG-$(proj)
chart=$(chart_prefix).tiff

charts=NZ614 NZ6144
charts_gtiff=$(patsubst %,%-EPSG-$(proj).tiff,$(charts))

tracks=$(patsubst gpx/%.gpx,%.gpx,$(wildcard gpx/*.gpx))

track_proj=$(patsubst %,tmp/%,$(tracks))
track_overlays=$(patsubst %,%-$(chart),$(tracks))

scratch_charts=abel_tasman_torrent_tonga
scratch_pngs=$(patsubst %,%-scratch.png,$(scratch_charts))

all: $(scratch_pngs) $(charts_gtiff) $(track_overlays)

#abel_tasman_torrent_tonga.png: abel_tasman_torrent_tonga NZ6144-EPSG-$(proj).tiff
#	./abel_tasman_torrent_tonga NZ6144-EPSG-$(proj).tiff


%-scratch.png: % NZ6144-EPSG-$(proj).tiff
	./$< NZ6144-EPSG-$(proj).tiff $@

overlays: $(track_overlays)


# Create a GTiff with a SRS from a kap file
%-EPSG-$(proj).tiff: $(kappath)/%.kap
	gdalwarp -of GTiff -t_srs EPSG:$(proj) "$<" "$@"

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

