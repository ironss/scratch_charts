
local specfiles=tup.glob('*.spec')
local gpxfiles = tup.glob('gpx/*.gpx')
local projections = { 'EPSG:2193' }
local kapfiledir = '/usr/local/share/charts/LINZ/NewZealand/'


-- Find all the scratch chart specifications, and the associated chart
local specs = {}
local charts = {}
for _, f in pairs(specfiles) do
   local specname = f:match( '(NZ%d+%-.+)%.spec')
   local chartname = f:match('(NZ%d+)%-.+%.spec')
   local chart = { name=chartname, filename=kapfiledir .. chartname .. '.kap', specs={} }
   local spec = { name=specname, filename=f, chart=chart }
   specs[specname] = spec
   charts[chartname] = chart
--   print(f, specname, chartname)
end


-- Create projected charts for each chart and projection
local projected_charts = {}
for c, chart in pairs(charts) do
   for _, projection in pairs(projections) do
      local projected_chart_name = chart.name .. '-' .. projection
      local projected_chart_filename = projected_chart_name:gsub(':', '_') .. '.tiff'
      local projected_chart = { name=projected_chart_name, chart=chart, projection=projection, filename=projected_chart_filename }
      projected_charts[projected_chart_name] = projected_chart
--      print(projected_chart_filename)
      
      tup.definerule{
         inputs=nil, 
         outputs={ projected_chart_filename },
         command='gdalwarp -of GTiff -co COMPRESS=LZW  -t_srs ' .. projection .. ' ' .. chart.filename .. ' ' .. projected_chart_filename
      }
   end
end


-- For each scratch chart specification, find the projected charts associated 
-- with it, and generate a scratch chart
for s, spec in pairs(specs) do
   for c, pchart in pairs(projected_charts) do
      if spec.chart == pchart.chart then
         local scratch_chart_name = spec.name .. '-' ..  pchart.projection
         local scratch_chart_filename = spec.name .. '-' ..  pchart.projection:gsub(':', '_') .. '-scratch.png'
--         print(scratch_chart_filename)
         tup.definerule{
            inputs={ spec.filename, pchart.filename },
            outputs={ scratch_chart_filename },
            command='./' .. spec.filename .. ' ' .. pchart.filename .. ' ' .. scratch_chart_filename
         }
      end
   end
end


-- Find all GPX files
local tracks = {}
for _, f in pairs(gpxfiles) do
   local trackname = f:match('gpx/(.+)%.gpx')
   local track = { name=trackname, filename=f, shpfilename='tmp/'..f }
   tracks[trackname] = track
--   print(f, trackname)
end


-- Project each track
local projected_tracks = {}
for p, projection in pairs(projections) do
   for t, track in pairs(tracks) do
      local projected_track_name = track.name .. '-' .. projection
      local projected_track_filename = 'tmp/' .. track.name .. '-' .. projection:gsub(':', '_')
      local projected_track = { name=projected_track_name, filename=projected_track_filename, track=track, projection=projection }
      projected_tracks[projected_track_name] = projected_track
--      print(projected_track_name, projected_track_filename)

      tup.definerule{
         inputs={ track.filename },
         outputs={ --projected_track_filename, 
                   projected_track_filename..'/tracks.dbf', 
                   projected_track_filename..'/tracks.prj', 
                   projected_track_filename..'/tracks.shp',
                   projected_track_filename..'/tracks.shx',
                 },
         command='ogr2ogr -f "ESRI Shapefile" -t_srs ' .. projection .. ' ' .. projected_track_filename .. ' ' .. track.filename .. ' tracks'
      }
   end
end


-- Create full-size overlays, one per projected chart per track
for c, pchart in pairs(projected_charts) do
   for t, ptrack in pairs(projected_tracks) do
--      print(pchart.projection, ptrack.projection)
      if pchart.projection == ptrack.projection then
         local overlay_name = ptrack.track.name .. '-' .. pchart.chart.name .. '-' .. pchart.projection
         local overlay_filename = ptrack.track.name .. '-' .. pchart.chart.name .. '-' .. pchart.projection:gsub(':', '_') .. '.tiff'
--         print(overlay_name, overlay_filename, pchart.filename, ptrack.filename)
         
         tup.definerule{
            inputs={ pchart.filename, 
                     ptrack.filename..'/tracks.dbf',
                     ptrack.filename..'/tracks.prj',
                     ptrack.filename..'/tracks.shp',
                     ptrack.filename..'/tracks.shx',
                   },
            outputs={ overlay_filename },
            command='gdal_translate -of GTiff -co COMPRESS=LZW  -scale 0 255 0 0 ' .. pchart.filename .. ' ' .. overlay_filename .. ' && ' ..
                    'gdal_rasterize -b 1 -burn 8 -l tracks ' .. ptrack.filename .. ' ' .. overlay_filename .. ' && ' ..
                    'mogrify -morphology Erode Octagon -fill red -opaque black -transparent white ' .. overlay_filename
         }
      end
   end
end



-- Create a list of all scratch charts
-- * one blank one per scratch spec
-- * one per scratch spec per track
-- * one per scratch spec with all tracks

