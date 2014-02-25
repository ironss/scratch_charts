#! /usr/bin/lua

local lfs = require('lfs')

-- Find all charts, etc
local kapfiledir = '/usr/local/share/charts/LINZ/BSB_ROOT'
local resolution = { horizontal=254, vertical=254 }


local function os_path_join(a, b, c)
   local path=''
   if a ~= nil then path = path .. a end
   if b ~= nil then path = path .. '/' .. b end
   if c ~= nil then path = path .. '/' .. c end 
   return path
end


local function os_walk(top)
   local root=top
   for f in lfs.dir(top) do
   end
   return lfs.dir(top)
end


local function create_scanned_param(self, name)
   self[name] = function(self)
      if not self._is_scanned then
         self:_scan()
      end
      return self['_'..name]
   end
end

local function scan_if_needed(self)
   if not self._is_scanned then
      self:_scan()
   end
end


local function Chart(path)
   local chart={ }

   chart._path=path
   create_scanned_param(chart, 'path')
   create_scanned_param(chart, 'name')
   create_scanned_param(chart, 'number')
   create_scanned_param(chart, 'width')
   create_scanned_param(chart, 'height')
   create_scanned_param(chart, 'resolution')
   create_scanned_param(chart, 'scale')
   create_scanned_param(chart, 'geodetic_datum')
   create_scanned_param(chart, 'projection')
   create_scanned_param(chart, 'sounding_unit')
   create_scanned_param(chart, 'sounding_datum')
   create_scanned_param(chart, 'dx')
   create_scanned_param(chart, 'dy')

   chart._scan=function(self)
--         print(self._path)
         local f=io.open(self._path)
         local content = f:read('*a')
         self._name, self._number, self._width, self._height, self._resolution = content:match([[BSB/NA=(.-)[,%c]%s*NU=(.-)[,%c]%s*RA=(%d-),(%d-)[,%c]%s*DU=(%d-)[,%c]%s*]])
--         print(self._name, self._number, self._width, self._height, self._resolution)
         self._scale, self._geodetic_datum, self._projection, self._sounding_unit, self._sounding_datum, self._dx, self._dy = content:match([[KNP/SC=(%d+)[,%c]%s*GD=(.-)[,%c]%s*PR=(.-)[,%c]%s*.-UN=(.-)[,%c]%s*SD=(.-)[,%c]%s*DX=(.-)[,%c]%s*DY=(.-)[,%c]%s*]])
--         print(self._scale, self._geodetic_datum, self._projection, 'un:'..self._sounding_unit, 'sd:'..self._sounding_datum, self._dx, self._dy)
         f:close()
         self._is_scanned = true
   end
   chart._scan_if_needed=scan_if_needed
   
   return chart
end



local charts={}
function kap_dir(root)
   for filename in lfs.dir(root) do
      if filename ~= '.' and filename ~= '..' then
         local filepath = os_path_join(root, filename)
         local attr = lfs.attributes(filepath)
         if attr.mode == 'directory' then
            kap_dir(filepath)
         else
            if filepath:match('(\.KAP)') then
               charts[#charts+1] = Chart(filepath)
            end
         end
      end
   end
   
   return charts
end


local charts = kap_dir(kapfiledir)
for _, chart in pairs(charts) do
--   c = chart:path()
   print(chart:path(), chart:name(), chart:width(), chart:height(), chart:resolution(), chart:scale(), 
      chart:geodetic_datum(), chart:projection(), chart:sounding_unit(), chart:sounding_datum(), chart:dx(), chart:dy() )
end

return charts

