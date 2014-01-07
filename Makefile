
name='Abel Tasman - Torrent Bay to Tonga'
scale="1:35000"
chart_no=NZ6144
scratch=scratch.png

kappath=/usr/local/share/charts/LINZ/NewZealand
proj=2193
chart_prefix=$(chart_no)-EPSG-$(proj)
chart=$(chart_prefix).tiff

gpxpath=. #/home/stephen/projects/gps/tracks
tracks="holux-1000c-00.1B.C1.06.F5.80-20131220_2219.gpx \
        holux-1000c-00.1B.C1.06.F5.80-20131221_1958.gpx"

all: $(scratch)

$(chart): $(kappath)/$(chart_no).kap
	gdalwarp -of GTiff -t_srs EPSG:$(proj) "$<" "$@"

$(scratch): $(chart)
	convert \
   -size 2240x3508 xc:white \
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
   -annotate +80+3325 "$name"  \
   -font 'Helvetica' \
   -pointsize 8 \
   -annotate +1500+3320 "(from $(chart_no). Not to be used for navigation.)" \
   "$@" 2> /dev/null

clean:
	rm -rf *.tiff *.png
	
