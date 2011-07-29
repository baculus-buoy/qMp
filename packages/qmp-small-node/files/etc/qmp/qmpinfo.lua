#!/usr/bin/lua

iwinfo = require "iwinfo"

qmpinfo = {}

function qmpinfo.get_modes(dev)
	local iw = iwinfo[iwinfo.type(dev)]
	local ma = "" -- modes avaiable
	return iw.hwmodelist(dev)
	
end

function qmpinfo.get_channels(dev)
	local iw = iwinfo[iwinfo.type(dev)]

	local freqs = iw.freqlist(dev) --freqs list
	local c -- current channel
	local nc = 0 -- next channel
	local pc = 0 -- previous channel
	local clist = {} -- output channel list
	local adhoc

	for i,f in ipairs(freqs) do
		c = f.channel
		ch = {}
		ch.channel = c
		ch.ht40p = false
		ch.ht40m = false
		ch.adhoc = false

		-- 2.4Ghz band
		if c < 15 then
			if c < 4 then 
				ch.ht40p = true
				ch.adhoc = true 
			
			elseif c < 10 then 
				ch.ht40m = true  
				ch.ht40p = true
				ch.adhoc = true
			else 
				ch.ht40m = true
				ch.adhoc = true
			end
		  
		-- 5Ghz band
		elseif c > 14 then
			if #freqs == i then nc = nil
			else nc = freqs[i+1].channel
			end

			if i == 1 then pc = nil
			else pc = freqs[i-1].channel
			end

			if nc ~= nil and nc-c == 4 then 
				ch.ht40p = true 
			end
	
			if pc ~= nil and c-pc == 4 then
				ch.ht40m = true
			end

			adhoc = os.execute("iw list | grep \"no IBSS\" | grep -v disabled | grep -q " .. f.mhz .. " 2>/dev/null")
			if adhoc ~= 0 then
				ch.adhoc = true
			end
		end
		table.insert(clist,ch)
	end	
	return clist
end

return qmpinfo
