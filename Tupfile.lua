
local specfiles=tup.glob('*.spec')
local gpxfiles = tup.glob('gpx/*.gpx')
local projections = { 'EPSG:2193' }
local kapfiledir = '/usr/local/share/charts/LINZ/NewZealand/'


-- Find all the scratch chart specifications, and the associated chart
local specs = 
{
   { name='NZ614-Port_Motueka_to_Torrent_Bay-A4', width=2080, height=3148, left=2700, top=3400 },
   { name='NZ6144-Torrent_Bay_to_Tonga-A4', width=2080, height=3148, left=4700, top=5500 },
}

local charts = {}
for _, spec in pairs(specs) do
   local chartname = spec.name:match('(NZ%d+)%-.+')
   local chart = { name=chartname, filename=kapfiledir .. chartname .. '.kap', specs={} }
   spec.filename=spec.name .. '.spec'
   spec.chart = chart
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
local scratch_charts = {}
for s, spec in pairs(specs) do
   for c, pchart in pairs(projected_charts) do
      if spec.chart == pchart.chart then
         local scratch_chart = {}
         scratch_chart.name = spec.name .. '-' ..  pchart.projection
         scratch_chart.spec = spec
         scratch_chart.chart = pchart.chart
         scratch_chart.projection = pchart.projection
         scratch_chart.filename = spec.name .. '-' ..  pchart.projection:gsub(':', '_') .. '-scratch.tiff'
         scratch_chart.filename2 = spec.name .. '-' ..  pchart.projection:gsub(':', '_') .. '-scratch.png'
         scratch_charts[#scratch_charts+1] = scratch_chart
--         print(scratch_chart.filename)

         tup.definerule{
            inputs={ pchart.filename },
            outputs={ scratch_chart.filename },
            command='gdal_translate -of GTiff -co COMPRESS=LZW -srcwin ' .. spec.left .. ' ' .. spec.top .. ' ' .. spec.width .. ' ' .. spec.height .. ' ' .. pchart.filename .. ' ' .. scratch_chart.filename 
         }

         tup.definerule{
            inputs={ spec.filename, pchart.filename },
            outputs={ scratch_chart.filename2 },
            command='./' .. spec.filename .. ' ' .. pchart.filename .. ' ' .. scratch_chart.filename2
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


-- Create scratch-sized overlays, one per scratch chart per track
for c, pchart in pairs(scratch_charts) do
   for t, ptrack in pairs(projected_tracks) do
--      print(pchart.projection, ptrack.projection)
      if pchart.projection == ptrack.projection then
         local overlay_name = ptrack.track.name .. '-' .. pchart.chart.name .. '-' .. pchart.projection
         local overlay_filename = ptrack.track.name .. '-' .. pchart.chart.name .. '-' .. pchart.spec.name .. '-' .. pchart.projection:gsub(':', '_') .. '.tiff'
         local overlay_filename2 = pchart.chart.name .. '-' .. pchart.spec.name .. '-' .. pchart.projection:gsub(':', '_') .. '-' .. ptrack.track.name .. '.png'
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
         
         tup.definerule{
            inputs={ pchart.filename, overlay_filename },
            outputs={ overlay_filename2 },
            command='convert -density 3000x300 ' .. pchart.filename .. ' ' .. overlay_filename .. ' -composite ' .. overlay_filename2
         }
      end
   end
end


-- Create a list of all scratch charts
-- * one blank one per scratch spec
-- * one per scratch spec per track
-- * one per scratch spec with all tracks

