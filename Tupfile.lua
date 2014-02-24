-- Generate scratch charts from LINZ NZMariner navigational charts


-- TODO: Add title block to overlayed charts: scratch-chart name, 
--          chart name, panel name, date, scale, warning
-- TODO: Add visual scale to vertical edge: 1 NM, 1km, etc
-- TODO: Handle charts that are smaller than the paper size
-- TODO: Add GPS fixes (time markers) to track
-- TODO: Specify tracks by time, rather than by copying them
--          into this subdirectory


local gpxfiles = tup.glob('gpx/*.gpx')
local projections = { 'EPSG:2193' }
local kapfiledir = '/usr/local/share/charts/LINZ/BSB_ROOT'
local resolution = { horizontal=254, vertical=254 }
local outdir = 'out'
local tmpdir = 'tmp'


-- Utility functions
local function pathconcat(a, b, c)
   local path=''
   if a ~= nil then path = path .. a end
   if b ~= nil then path = path .. '/' .. b end
   if c ~= nil then path = path .. '/' .. c end 
   return path
end


local paperspecs = 
{
   ['A4L']={ name='A4L', width=297, height=210 },
   ['A4P']={ name='A4P', width=210, height=297 },
   ['A3L']={ name='A3L', width=420, height=297 },
   ['A3P']={ name='A4P', width=297, height=420 },
}

local margin = 
{
   top=10, left=10, bottom=10, right=10,
}


local specs = 
{
   ['Port Motueka to Torrent Bay'     ]={ chart='NZ614' , panel='01', paper='A4P', left=2100, top=2700 },
   ['Adele Island to Separation Point']={ chart='NZ614' , panel='01', paper='A4P', left=1500, top= 700 },
   ['Marahau to Separation Point'     ]={ chart='NZ614' , panel='01', paper='A3P', left=1100, top= 800 },

   ['Torrent Bay to Tonga Island'     ]={ chart='NZ6144', panel='01', paper='A4P', left=3800, top=4500 },
   ['Tonga Island to Awaroa Inlet'    ]={ chart='NZ6144', panel='01', paper='A4P', left=3500, top=2700 },
   ['Marahua to Torrent Bay'          ]={ chart='NZ6144', panel='01', paper='A4P', left=3500, top=6400 },
   ['Pitt Head to Awaroa Inlet'       ]={ chart='NZ6144', panel='01', paper='A3P', left=2800, top=3200 },
}


local charts = {}
for name, spec in pairs(specs) do
   local chartname, panelname = spec.chart, spec.panel
   local filename = pathconcat(kapfiledir, chartname, chartname .. panelname .. '.KAP')
   if charts[chartname] == nil then
      charts[chartname] = { name=chartname..'_'..panelname, filename=filename, specs={} }
   end
   local chart = charts[chartname]
   
   spec.name = chartname .. '_' .. panelname .. '-' .. name:gsub(' ', '_')
   spec.chart = chart
   spec.width = math.floor((paperspecs[spec.paper].width - margin.left - margin.right) * resolution.horizontal / 25.4)
   spec.height = math.floor((paperspecs[spec.paper].height - margin.top - margin.bottom)* resolution.vertical / 25.4)
   --print(spec.name, chart.name, chart.filename)
end


-- Full-sized projected charts for each chart and projection
local projected_charts = {}
for c, chart in pairs(charts) do
   for _, projection in pairs(projections) do
      local projected_chart_name = chart.name .. '-' .. projection
      local projected_chart_filename = pathconcat(outdir, projected_chart_name:gsub(':', '_') .. '.tiff')
      if projected_charts[projected_chart_name] == nil then
         projected_charts[projected_chart_name] = { name=projected_chart_name, chart=chart, projection=projection, filename=projected_chart_filename }
      end
      local projected_chart = projected_charts[projected_chart_name]
--      print(projected_chart.name, projected_chart.filename)

      tup.definerule{
         inputs=nil, 
         outputs={ projected_chart_filename },
         command='gdalwarp -of GTiff -co COMPRESS=LZW  -t_srs ' .. projection .. ' ' .. chart.filename .. ' ' .. projected_chart_filename
      }
   end
end


-- For each scratch chart specification, find the projected chart associated 
-- with it, and generate a scratch chart
local scratch_charts = {}
for s, spec in pairs(specs) do
   for c, pchart in pairs(projected_charts) do
--      print(spec.name, spec.chart.name, pchart.chart.name)
      if spec.chart == pchart.chart then
--         print('**', spec.name, spec.chart.name, pchart.chart.name)
         local scratch_chart = {}
         scratch_chart.name = spec.name .. '-' ..  pchart.projection
         scratch_chart.spec = spec
         scratch_chart.chart = pchart.chart
         scratch_chart.projection = pchart.projection
         scratch_chart.filename = pathconcat(outdir, spec.name .. '-' ..  pchart.projection:gsub(':', '_') .. '-scratch.tiff')
         scratch_chart.filename2 = pathconcat(outdir, spec.name .. '.png')
         scratch_charts[#scratch_charts+1] = scratch_chart
--         print(scratch_chart.name, scratch_chart.filename)

         tup.definerule{
            inputs={ pchart.filename },
            outputs={ scratch_chart.filename },
            command='gdal_translate -of GTiff -co COMPRESS=LZW -srcwin ' .. spec.left .. ' ' .. spec.top .. ' ' .. spec.width .. ' ' .. spec.height .. ' ' .. pchart.filename .. ' ' .. scratch_chart.filename
         }
      end
   end
end


-- Find all GPX files
local tracks = {}
for _, f in pairs(gpxfiles) do
   local trackname = f:match('gpx/(.+)%.gpx')
   local tracktime = trackname:match('.+(%d%d%d%d%d%d%d%d_%d%d%d%d)')
   local track = { name=trackname, filename=f, shpfilename='tmp/'..f, time=tracktime }
   tracks[trackname] = track
--   print(f, trackname, tracktime)
end


-- Project each track
local projected_tracks = {}
for p, projection in pairs(projections) do
   for t, track in pairs(tracks) do
      local projected_track_name = track.name .. '-' .. projection
      local projected_track_filename = pathconcat(tmpdir, track.name .. '-' .. projection:gsub(':', '_'))
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
         command=table.concat({
            'ogr2ogr',
            '-f "ESRI Shapefile"',
            '-t_srs ' .. projection,
            projected_track_filename,
            track.filename,
            'tracks',
         }, ' ')
      }
   end
end


-- Create scratch-sized overlays, one per scratch chart per track
for c, pchart in pairs(scratch_charts) do
   for t, ptrack in pairs(projected_tracks) do
--      print(pchart.projection, ptrack.projection)
      if pchart.projection == ptrack.projection then
         local overlay_name = ptrack.track.name .. '-' .. pchart.chart.name .. '-' .. pchart.projection
         local overlay_filename = pathconcat(outdir, ptrack.track.name .. '-' .. pchart.spec.name .. '-' .. pchart.projection:gsub(':', '_') .. '.tiff')
         local overlay_filename2 = pathconcat(outdir, pchart.spec.name .. '-' .. ptrack.track.time .. '.png')
--         print(overlay_name, overlay_filename, pchart.filename, ptrack.filename)
         
         tup.definerule{
            inputs={ pchart.filename, 
                     ptrack.filename..'/tracks.dbf',
                     ptrack.filename..'/tracks.prj',
                     ptrack.filename..'/tracks.shp',
                     ptrack.filename..'/tracks.shx',
                   },
            outputs={ overlay_filename },
            command=table.concat({
               'gdal_translate', '-of GTiff', '-co COMPRESS=LZW', '-scale 0 255 1 1', pchart.filename, overlay_filename,
               '&&',
               'gdal_rasterize', '-b 1 -burn 16', '-l tracks', ptrack.filename, overlay_filename,
               '&&',
               'mogrify', '-morphology Erode Octagon', '-fill red', '-opaque black -transparent white', overlay_filename
            }, ' ')
         }
         
         tup.definerule{
            inputs={ pchart.filename, overlay_filename },
            outputs={ overlay_filename2 },
            command=table.concat({
               'convert',
               '-density ' .. resolution.horizontal..'x'..resolution.vertical,
               pchart.filename,
               overlay_filename,
               '-composite',
               overlay_filename2,
            }, ' ')
         }
      end
   end
end


-- Create a list of all scratch charts
-- * one blank one per scratch spec
-- * one per scratch spec per track
-- * one per scratch spec with all tracks

