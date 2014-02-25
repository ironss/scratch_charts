#! /usr/bin/lua

charts = require('charts')

for _, chart in pairs(charts) do
   print(chart:path(), chart:name(), chart:number(), chart:width(), chart:height(), chart:resolution(), chart:scale(), 
      chart:geodetic_datum(), chart:projection(), chart:sounding_unit(), chart:sounding_datum(), chart:dx(), chart:dy() )
end

