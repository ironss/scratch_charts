
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
   print(f, specname, chartname)
end


-- Find all GPX files
local tracks = {}
for _, f in pairs(gpxfiles) do
   local trackname = f:match('gpx/(.+)%.gpx')
   local track = { name=trackname, filename=f }
   tracks[trackname] = track
--   print(f, trackname)
end


-- Create projected charts for each chart and projection
local projected_charts = {}
for c, chart in pairs(charts) do
   for _, projection in pairs(projections) do
      local projected_chart_name = chart.name .. '-' .. projection
      local projected_chart_filename = projected_chart_name:gsub(':', '_') .. '.tiff'
      local projected_chart = { name=projected_chart_name, chart=chart, projection=projection, filename=projected_chart_filename }
      projected_charts[projected_chart_name] = projected_chart
      print(projected_chart_filename)
      
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
         local scratch_chart_filename = spec.name .. '-' ..  pchart.projection .. '-scratch.png'
         print(scratch_chart_filename)
         tup.definerule{
            inputs={ spec.filename, pchart.filename },
            outputs={ scratch_chart_filename },
            command='./' .. spec.filename .. ' ' .. pchart.filename .. ' ' .. scratch_chart_filename
         }
      end
   end
end


-- Create full-size overlays, one per chart per track
for c, chart in pairs(charts) do
   for t, track in pairs(tracks) do
--      tup.definerule{
--         inputs={chart.filename, track.filename},
--         outputs={
--      overlays[ {chart=c, track=t} ] = 1
   end
end



-- Create a list of all scratch charts
-- * one blank one per scratch spec
-- * one per scratch spec per track
-- * one per scratch spec with all tracks

