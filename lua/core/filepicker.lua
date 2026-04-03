local filePicker = {}

local currentPath = ""
local filePathReturn = 1
local modstable = {}
local folderstable = {}
local selected = 1
local counterFolders = 0
local heigth = 7
local y = 0
local q = 1

function filePicker.load(path)
	counterFolders = 0
	modstable = {"./.."} 
	--[[local command 
	if package.config:sub(1,1) == "\\" then
		command = 'dir "' .. path .. '" /b *.mod' 
	else
		command = 'find "' .. path .. '" -maxdepth 1 -type d' 
	end
	local handle = io.popen(command)
	for line in handle:lines() do 
		table.insert(modstable, line) 
		counterFolders = counterFolders+1
	end
	table.remove(modstable, 2)]]
	local command 
	if package.config:sub(1,1) == "\\" then
		command = 'dir "' .. path .. '" /b *.mod' 
	else
		command = 'find "' .. path .. '" -maxdepth 1 -type f -name "*.mod"' 
	end
	local handle = io.popen(command)
	for line in handle:lines() do 
		table.insert(modstable, line) 
	end
	handle:close() 
	return modstable
end

function filePicker.draw(t)
	local p = 1
    	for i, f in ipairs(modstable) do
		if i <= heigth then
			if p == selected then
                		love.graphics.setColor(1, 1, 0.4) -- amarelo
            		else
                		love.graphics.setColor(1, 1, 1) -- branco
            		end
            		love.graphics.print((modstable[i+y] ~= nil) and modstable[i+y] or "none", 20, 20 + p * 20)
			p = p+1
		end
        end
	--print("selected: " .. selected .. " counterFolders: " .. counterFolders)
	q = p-1
end

function filePicker.down()
	if selected < heigth and selected < #modstable then
		selected = selected + 1
	else
		if y+1 < #modstable-heigth+1 then
			y = y+1
		else
			selected = 1
			y = 0
		end
	end
end

function filePicker.up()
	if selected > 1 then
		selected = selected - 1
	else
		if y-1 >= 0 then
			y = y-1
		--[[else
			if #modstable > heigth then
				selected = #modstable-heigth+7
				y = #modstable-heigth
			else
				selected = #modstable
			end
			print(selected, #modstable)]]
		end
	end
end

function filePicker.select()
	if selected > counterFolders-y then
		local file = modstable[selected+y]
		if modstable[selected+y] ~= "./.." then
			return file
		else
			local path = currentPath
			if filePathReturn == 1 then
				path = path .. "./.."
			else
				path = path .. "/.."
			end
			filePicker.load(path)
			filePathReturn = filePathReturn + 1
			return 0
		end
	else
		currentPath = modstable[selected+y]
		filePicker.load(currentPath)
		--filePathReturn = filePathReturn + 1
		selected = 1
		y = 0
		return 0
	end
end

return filePicker