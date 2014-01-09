#! /bin/sh

chart=$1
name=$2

convert \
   -size 2240x3350 xc:white \
   -density 300x300 \
       "$chart[2080x3148+4700+5500]" -geometry +80+60    -composite \
       "$chart[2072x60+4700+594]"    -geometry +80+0     -composite \
       "$chart[2072x60+4700+12336]"  -geometry +80+3208  -composite \
       "$chart[80x3148+427+5500]"    -geometry +0+60     -composite \
       "$chart[80x3148+7999+5500]"   -geometry +2152+60  -composite \
   -stroke black -fill none \
   -draw "polyline 80,60 2152,60 2152,3208 80,3208 80,60" \
   -stroke black -fill black \
   -font 'Helvetica-Bold' \
   -pointsize 16 \
   -annotate +80+3325 "Abel Tasman - Torrent Bay to Tonga"  \
   -font 'Helvetica' \
   -pointsize 8 \
   -annotate +1500+3320 "(from NZ 6144. Not to be used for navigation.)" \
   -pointsize 5 \
   -annotate +2152+3208 "176\n267" \
   "$name"

