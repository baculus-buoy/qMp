#!/usr/bin/lua
--[[
    Copyright (C) 2011 Fundacio Privada per a la Xarxa Oberta, Lliure i Neutral guifi.net

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License along
    with this program; if not, write to the Free Software Foundation, Inc.,
    51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.

    The full GNU General Public License is included in this distribution in
    the file called "COPYING".
--]]

local uci = require "luci.model.uci"
local debug = require "qmp.debug"

model = {}

--- Get a section type or an option
-- @class function
-- @name get
-- @param section	UCI section name
-- @param option	UCI option (optional)
-- @return			UCI value
function model.get(section, option)
	local status, c = pcall(model.raw)
	if not status then 
		debug.logger(c)
		return nil
	else
		if section and option then
			return c:get('qmp', section, option)
		else
			return nil
		end
	end
end


--- Create a new section and initialize it with data.
-- @class function 
-- @name add
-- @param type		UCI section type
-- @param name		UCI section name (optional)
-- @param values	Table of key - value pairs to initialize the section with (optional)
-- @return			Name of created section
function model.add(type, name, values)
	local status, c = pcall(model.raw)
	if not status then 
		debug.logger(c)
		return nil
	else
		if c:section('qmp', type, name, values) then
			model.commit(c)
			return nil, true
		else
			error()
		end
	end
end

--- Create a new anonymous section and initialize it with data.
-- @class function 
-- @name add
-- @param type		UCI section type
-- @param values	Table of key - value pairs to initialize the section with (optional)
-- @return			Name of created section
function model.add_type(type, values)
	return model.add(type, nil, values)
end

--- Deletes a section or an option.
-- @class function
-- @name delete
-- @param section	UCI section name
-- @param option	UCI option (optional)
-- @return			Boolean whether operation succeeded
function model.delete(section, option)
	local status, c = pcall(model.raw)
	if not status then 
		debug.logger(c)
		return nil
	else
		if option then
			if c:delete('qmp', section, option) then
				model.commit(c)
				return nil, true
			else
				return false
			end
		else 
			if c:delete('qmp', section) then
				model.commit(c)
				return true
			else
				return false
			end
		end
	end

end

--- Deletes all the UCI sections of a given type
-- @class function
-- @name delete_type
-- @param type		UCI section type
-- @return			Boolean whether operation succeeded
function model.delete_type(type)
	local status, c = pcall(model.raw)
	if not status then 
		debug.logger(c)
		return nil
	else
		function del (s)
			c:delete('qmp', s['.index'])
		end
		if c:foreach('qmp', type, del) then
			return true
		else
			return false
		end
	end
end

--- Set a value or create a named section.
-- @class function
-- @name set
-- @param section	UCI section name
-- @param option	UCI option or UCI section type
-- @param value		UCI value or nil if you want to create a section
-- @return			Boolean whether operation succeeded
function model.set(section, option, value)
	local status, c = pcall(model.raw)
	if not status then 
		debug.logger(c)
		return nil
	else
		if section and option then
			if c:set('qmp', section, option, value) then
				model.commit(c)
				return true
			else
				false
			end
		else
			return false
		end
	end
end

--- Set given values as list.
-- @class function
-- @name set_list
-- @param section	UCI section name
-- @param option	UCI option
-- @param value		UCI value
-- @return			Boolean whether operation succeeded
function model.set_list(section, option, value)
	local status, c = pcall(model.raw)
	if not status then 
		debug.logger(c)
		return nil
	else
		if section and option then
			if c:set_list('qmp', section, option, value) then
				model.commit(c)
				return nil, true
			else
				error()
			end
		else
			return false
		end
	end
end

--- Get a table with the information of some sections of a given type 
-- @param type		UCI section type
-- @param index		UCI section type index (optional)
-- @param option	UCI option (optional)
-- @return			Table or UCI value
function model.get_type(type, index, option)
	if index then 
		if option then 
			return model.get_type_option(type, index, option)
		else 
			return model.get_type_index(type, index)
		end 
	else
		return model.get_all_type(type)
	end
end

--- Get a table with all the sections of a given type
-- @param type		UCI section type
-- @return			Table 
function model.get_all_type(type)
	local status, c = pcall(model.raw)
	if not status then 
		debug.logger(c)
		return nil
	else
		local gt = {}
		if c:foreach('qmp', type, function (t) table.insert(gt, t) end) then
			return gt
		else
			return false
		end
	end
end

--- Get a table with the information of the section of a given type and index 
-- @param type		UCI section type
-- @param index		UCI section type index
-- @return			Table 
function model.get_type_index(type, index)
	local status, c = pcall(model.raw)
	if not status then 
		debug.logger(c)
		return nil
	else
		local gt = {}
		if c:foreach('qmp', type, function (t) if t['.index'] == tostring(index) then table.insert(gt, t) end end) then
			return gt
		else 
			return false
		end
	end
end

--- Get an option of the section of a given type and index 
--- Get a table with the information of some sections of a given type 
-- @param type		UCI section type
-- @param index		UCI section type index 
-- @param option	UCI option
-- @return			UCI value
function model.get_type_option(type, index, option)
	local status, c = pcall(model.raw)
	if not status then 
		debug.logger(c)
		return nil
	else
		local gt = {}
		if c:foreach('qmp', type, function (t) if t['.index'] == tostring(index) then table.insert(gt, t) end end) then
			return gt[option]
		else 
			return false
		end
	end
end

--- Commit the changed done with a UCI-Cursor
-- @class function
-- @name commit
-- @param c UCI-Cursor
-- @return Boolean whether operation succeeded 
function model.commit(c)
	if not c then
		debug.logger(c)
		return false
	else
		c:commit("qmp")
	end
end

--- Create a new UCI-Cursor
-- @class function
-- @name raw
-- @return UCI-Cursor or an error on failure
function model.raw()
	local c = uci.cursor()
	if c == nil then
		error('There was a problem while trying to get a UCI-Cursor')
	else 
		return c
	end
end

--- Applies UCI configuration changes
-- @param cmd	Don't apply only return the command
function model.apply(cmd)
	local c = uci.cursor()
	c.apply('qmp', cmd)
end

return model

