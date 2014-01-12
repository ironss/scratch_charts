
local specfiles=tup.glob('*.spec')
local gpxfiles = tup.glob('gpx/*.gpx')
local projections = { 'EPSG:2193' }
local kapfiledir = '/usr/local/share/charts/LINZ/NewZealand/'


-- Find all the scratch chart specifications, and the associated chart
local specs = {}
local charts = {}
for _, f in pairs(specfiles) do
   local spec = f:match('(.+)%.spec')
   local chart=f:match('(NZ%d+)%-.*%.spec')
   print(f, spec, chart)
   charts[chart] = { chart=chart, filename=kapfiledir .. chart .. '.kap' }
   specs[spec] = { spec=spec, filename=f, chart=chart }
end


-- Find all GPX files
local tracks = {}
for _, f in pairs(gpxfiles) do
   local trackname = f:match('gpx/(.+)%.gpx')
   local t = { filename=f, trackname=trackname }
   tracks[t] = 1
   print(f, trackname)
end


-- Create projected charts for each chart and projection
for c, chart in pairs(charts) do
   for _, projection in pairs(projections) do
      local projected_chart_filename = chart.chart .. '-' .. projection .. '.tiff'
      tup.definerule{
         inputs=nil, outputs={projected_chart_filename},
         command='gdalwarp -of GTiff -co COMPRESS=LZW  -t_srs ' .. projection .. ' ' .. chart.filename .. ' ' .. projected_chart_filename
      }
   end
end


-- Create full-size overlays, one per chart per track
local overlays = {}
for c, chart in pairs(charts) do
   for t, track in pairs(tracks) do
--      tup.definerule{inputs{chart.filename, track.filename
--      overlays[ {chart=c, track=t} ] = 1
   end
end



scratch_charts = {}
for s, spec in pairs(specs) do
   
end
-- Create a list of all scratch charts
-- * one blank one per scratch spec
-- * one per scratch spec per track
-- * one per scratch spec with all tracks

