-- Copyright (c) 2026 Zeus
-- Licensed under the GNU General Public License v3.0
-- See LICENSE file in the project root for details.

local AMIGA_CLOCK = 7093789.2

local channel = require("lua/core/channel")
local ffi = require("ffi")
local filePicker = require("lua/core/filepicker")
local mod = require("lua/core/loadMod")
local editor = require("lua/core/editor")
local effects = require("lua/core/effects")
local logo = require("lua/core/logo")

fileSearch = true
editor_mod = false
loaded_mod = false
local auto_play = false

tickets = 0
ticksPerLine = 6
bpm = 125

screenWidth = love.graphics.getWidth()-40
screenHeight = love.graphics.getHeight()/2

mod_title = {}
mod_samples__info = {}
mod_song__length = {}
mod_underfined = {}
mod_song__position = {}
mod_underfined2 = {}
mod_data_pattern = {}
mod_sample_data = {}
mod_sampleDecoded = {}
mod_sampleDecoded2 = {}

selected_file = ""
canvas = love.graphics.newCanvas( )
canvas:setFilter("linear", "nearest")
canvasPattern = love.graphics.newCanvas( )
canvasPattern:setFilter("linear", "nearest")
canvasUI = love.graphics.newCanvas( )
canvasUI:setFilter("linear", "nearest")

renderPattern = false
local modFormat = "M.K."

local currentSample = 1
sampleRate = 44100
numChannels = 4
channels = {}
channelPositions = {}
releaseChannel = {}
lastNote = {}
periodTone = 0

currentPattern = 1

mouseSelected = ""
mouseSelectedColor = 0

local font = love.graphics.newImageFont("gfx/imagefont.png",
    " abcdefghijklmnopqrstuvwxyz" ..
    "ABCDEFGHIJKLMNOPQRSTUVWXYZ0" ..
    "123456789.,!?-+/():;%&`'*#=[]\"")

local offsetKey = 214
t=0

local zoomEditor = 1
local showSample = false

function sampleDecode(data, amplitudex)
    local out = {}
    for i = 1, #data do
        local v = data[i]
        if v >= 128 then v = v - 256 end
        out[i] = v
    end
    return out
end

function oscilationWave(screenWidth, screenHeight)
	love.graphics.setCanvas(canvas)
	love.graphics.clear(0, 0, 0, 0)
	local offsetplay = 0
	local offsetAmplitude = 0
	local length = (mod_sampleDecoded[currentSample] == nil) and 1 or #mod_sampleDecoded[currentSample]
	local zoomEditorT = zoomEditor*(screenWidth)/length
	local wavePrecision = math.max(math.floor(zoomEditorT), 1)
	print(wavePrecision)
	love.graphics.setColor(0, 1, 180/255)
	local lines = {}
	for x=1, length-1, 1 do
		if offsetplay >= screenWidth then
			break
		end
		lines[(x-1)*2+1] = 20+(x-1)*zoomEditorT+zoomEditorT
		lines[(x-1)*2+2] = 200+screenHeight+mod_sampleDecoded[currentSample][x+1]/4
	end
	if #lines > 0 then love.graphics.line(lines) end
	love.graphics.setCanvas()
end

function love.load()
	logo.load()
	modstable = filePicker.load("./")
	editor.noteOffset(856)
	editor.localNoteOffset(offsetKey)
	love.graphics.setFont(font)
	editor.sendBuffer({{0, 0}}, 1)
	editor.initEngine(4900, 0.707)
end

local beatTimer = 0
patternPosition = 0

function toBinary(n, bits)
    local s = ""
    for i = bits-1, 0, -1 do
        local mask = bit.lshift(1, i)
        s = s .. (bit.band(n, mask) ~= 0 and "1" or "0")
    end
    return s
end


function love.update(dt)
	if selected_file ~= "" then
		editor.init()
		mod.load(selected_file)
		channel.init(numChannels, channels)
		currentPattern = 1
		patternPosition = 64*(mod_song__position[currentPattern])+1
		for i=1, 31 do
			local length = mod_sample_data[i] or 0
			if length ~= 0 then
				mod_sampleDecoded[i] = sampleDecode(mod_sample_data[i])
			end
		end
		oscilationWave(screenWidth, screenHeight)
		incCounter(0)
		renderPattern = true
		fileSearch = false
		tickets = 0
		loaded_mod = true
		selected_file = ""
	end
	--[[loadMod("aftershc.mod")
	for i=1, 31 do
		local length = mod_sample_data[i] or 0
		if length ~= 0 then
			mod_sampleDecoded[i] = sampleDecode(mod_sample_data[i])
		end
	end]]

	local x, y = love.mouse.getPosition()
	if x < 60 and y < 20 then
		mouseSelected = "button1"
	else
		mouseSelected = ""
	end

	if loaded_mod and auto_play then
		beatTimer = beatTimer + dt
		local tickTime = 2.5 / bpm
		while beatTimer >= tickTime do
			beatTimer = beatTimer - tickTime
			if tickets == 0 then
				if patternPosition >= 64*(mod_song__position[currentPattern]+1)+1 then
					currentPattern = currentPattern+1
					patternPosition = 64*(mod_song__position[currentPattern])+1
					incCounter(0)
				end
				for channel=0, numChannels-1 do
					local base = (patternPosition-1)*numChannels*4 + channel*4
					--print(base, mod_data_pattern[base+1])
					--print(currentPattern, patternPosition, 64*(mod_song__position[currentPattern]+1)+1, "realPosition Pattern: " .. mod_song__position[currentPattern])
					local b1 = mod_data_pattern[base+1]
					local b2 = mod_data_pattern[base+2]
					local b3 = mod_data_pattern[base+3]
					local b4 = mod_data_pattern[base+4]
					local period = bit.bor(bit.lshift(bit.band(b1, 0x0F), 8), b2)
					local instrument = bit.bor(bit.band(b1, 0xF0), bit.rshift(bit.band(b3, 0xF0), 4))
					local effect = bit.band(b3, 0x0F)
					local param = b4
					--print(toBinary(b1, 8), toBinary(b2, 8), toBinary(b3, 8), toBinary(period, 12))
					--print("ticks: " .. ticksPerLine .. " bpm: " .. bpm)
					if period > 0 then
						if effect == 0x3 then
							if param > 0 then
								channels[channel+1][6] = param
								channels[channel+1][3] = 1
							end
							channels[channel+1][5] = period
						else
							if instrument > 0 then
								channels[channel+1][1] = instrument
								channels[channel+1][2] = period
								channels[channel+1][3] = 1
								channels[channel+1][4] = 1
								channels[channel+1][8] = (mod_samples__info[(channels[channel+1][1]-1)*6+5][1]*256 + mod_samples__info[(channels[channel+1][1]-1)*6+5][2])*2
								channels[channel+1][9] = (mod_samples__info[(channels[channel+1][1]-1)*6+6][1]*256 + mod_samples__info[(channels[channel+1][1]-1)*6+6][2])*2
							end
						end
					end
					effects.applyPreEffects(effect, param, channel+1)
				end
				renderPattern = true
			else
				for channel=0, numChannels-1 do
					local base = (patternPosition-1)*numChannels*4 + channel*4
					local b3 = mod_data_pattern[base+3]
					local b4 = mod_data_pattern[base+4]
					local effect = bit.band(b3, 0x0F)
					local param = b4
					effects.applyPosEffects(effect, param, channel+1)
				end
			end
			tickets = tickets + 1
			if tickets >= ticksPerLine then
				patternPosition = patternPosition + 1
				incCounter(1)
				tickets = 0
			end
		end
	end
	editor.channelPlay(numChannels)
	t=t+1
	--logo.update(dt/2+math.min(1, (math.abs(periodTone)/2020)))
	logo.update(dt/2)
end


function love.keypressed(key, scancode, isrepeat)
	editor.keyMap(key, currentSample, channels)

   	if key == "escape" then
		if fileSearch == false then
			fileSearch = true
		else
			collectgarbage()
      			love.event.quit()
		end
   	end

	if key == "rctrl" then
		if auto_play then
			auto_play = false
			for i = 1, numChannels do
				channels[i][1] = 0
			end
		else
			auto_play = true
			editor.resetBar()
		end
		renderPattern = true
	end
	
	if key == "space" then
		if editor_mod then
			editor_mod = false
		else
			editor_mod = true
		end
		auto_play = false
		for i = 1, numChannels do
			channels[i][1] = 0
		end
		--editor.resetBar()
		renderPattern = true
	end

	if key == "down" then
		if fileSearch then
			filePicker.down()
		else
			if editor_mod then
				editor.barDown()
			else
				patternPosition = patternPosition+1
			end
			renderPattern = true
		end
	end

	if key == "up" then
		if fileSearch then
			filePicker.up()
		else
			if editor_mod then
				editor.barUp()
			else
				patternPosition = patternPosition-1
			end
			renderPattern = true
		end
	end

	if key == "return" then
		selected_file = (filePicker.select() ~= 0) and filePicker.select() or ""
	end

	if key == "f1" then
		editor.localNoteOffset(53.5)
	end
	if key == "f2" then
		editor.localNoteOffset(107)
	end
	if key == "f3" then
		editor.localNoteOffset(214)
	end

	if key == "f4" then
		editor.localNoteOffset(428)
	end

	if key == "f5" then
		editor.localNoteOffset(856)
	end

	if key == "f6" then
		editor.localNoteOffset(1712)
	end

	if key == "f7" then
		editor.localNoteOffset(3424)
	end

	if key == "f8" then
		editor.localNoteOffset(6848)
	end

	if key == "f9" then
		editor.localNoteOffset(13696)
	end

	if key == "f10" then
		
	end

	if key == "right" then
		if editor_mod then
			editor.right()
		else
			currentSample = math.min(currentSample + 1, 31)
			oscilationWave(screenWidth, screenHeight)
		end
	end

	if key == "left" then
		if editor_mod then
			editor.left()
		else
			currentSample = math.max(currentSample - 1, 1)
			oscilationWave(screenWidth, screenHeight)
		end
	end
end

function love.mousepressed(x, y, button, istouch, presses)
	if x < 60 and y < 20 then
		if showSample then
			showSample = false
		else
			showSample = true
		end
		mouseSelectedColor = 255
	end
	for i = 0, numChannels-1 do
		if x > 20+100*i and y > 160 and x < 120+100*i and y < 220 then
			if channels[i+1][10] then
				channels[i+1][10] = false
			else
				channels[i+1][10] = true
			end
		end
	end
end

function love.wheelmoved(x, y)
	if y > 0 then
		if showSample then
			zoomEditor = zoomEditor*2
			oscilationWave(screenWidth, screenHeight)
		else
			patternPosition = patternPosition - 1
			renderPattern = true
		end
	end
	if y < 0 then
		if showSample then
			zoomEditor = zoomEditor/2
			oscilationWave(screenWidth, screenHeight)
		else
			patternPosition = patternPosition + 1
			renderPattern = true
		end
	end
end

distance = 0

function love.draw()
	love.graphics.clear(0, 0, 0)
	love.graphics.setColor(1, 1, 1)
	logo.draw("", 0, 0, 0, 0, 0, 500, 20)
	local x = 0
	local y = 0
	local z = -15
	local angle_x = t/40
	local angle_y = 2
	local ys = 0
	if distance < 120 then
		distance = t/10
	else
		ys = -80
	end
	logo.ASCIIZ(x, y, z, angle_x, angle_y, 500, distance)
	logo.ASCIIE(x, y, z, angle_x, angle_y, 500, distance)
	logo.ASCIIU(x, y, z+17, angle_x, angle_y, 500, distance)
	logo.ASCIIS(x, y, z+27, angle_x, angle_y, 500, distance)
	filePicker.draw(t)
	love.graphics.setLineWidth(1)
	love.graphics.setLineStyle("rough")
	love.graphics.setColor(255, 255, 255)
	local x, y = love.mouse.getPosition()
	if mouseSelected == "button1" then
		love.graphics.setColor(120/255, 120/255, (120+mouseSelectedColor)/255)
	end
	love.graphics.rectangle("fill", 0, 0, screenWidth/20, 20)
	love.graphics.print("Sample")
	mouseSelectedColor = 0
	if loaded_mod then
		love.graphics.setColor(20/255, 20/255, 120/255)
		love.graphics.rectangle("fill", 200+screenWidth/2, 20, 200, screenHeight-140)
		love.graphics.setColor(1, 1, 1)
		for i=1, 11 do
			love.graphics.print(mod_samples__info[(i-1)*6+1],200+screenWidth/2,(i-1)*14+20)
		end
		if renderPattern then
			love.graphics.setCanvas(canvasPattern)
			love.graphics.clear(0, 0, 0, 0)
			renderPattern = false
			editor.drawPattern(32)
			love.graphics.setCanvas()
		end
		for i = 1, numChannels do
			channel.specView(i, 20+(i-1)*100, 200)
		end
		love.graphics.draw(canvasPattern, 0, 0)
	end
	if showSample then
		love.graphics.setColor(10/255,10/255,10/255)
		love.graphics.rectangle("fill", 0, 380, screenWidth+40, screenHeight)
		love.graphics.setColor(30/255,30/255,30/255)
		love.graphics.rectangle("fill", 20, 400, screenWidth, screenHeight-120)
		love.graphics.setColor(60/255,60/255,60/255)
		for gx=20,screenWidth+20,40 do
		    	love.graphics.line(gx,400,gx,280+screenHeight)
		end
		for gy=400,280+screenHeight,20 do
			love.graphics.line(20,gy,screenWidth+20,gy)
		end
		local sampleLength = 0
		if loaded_mod then
			sampleLength = (mod_samples__info[(currentSample-1)*6+2][1]*256+mod_samples__info[(currentSample-1)*6+2][2])*2
		end
		if sampleLength > 0 then
			love.graphics.setColor(20/255, 20/255, 120/255)
			love.graphics.setColor(1, 1, 1)
		end
		love.graphics.draw(canvas, 0, 0)
		love.graphics.print(currentSample, 20, 400)
		love.graphics.print("Length: " .. sampleLength, 20, screenHeight*2-40)
	end
	love.graphics.print("CurrentPattern: " .. currentPattern, 200, 0)
	love.graphics.print("Position: " .. patternPosition, 400, 0)
	love.graphics.print("ModPosition: " .. (mod_song__position[currentPattern+1] or 0), 550, 0)
	love.graphics.print("BPM: " .. bpm, 200, 100)
	love.graphics.print("Tickets: " .. ticksPerLine, 400, 100)
end
