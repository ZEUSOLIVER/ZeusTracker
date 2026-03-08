local ffi = require("ffi")
local filePicker = require("lua/core/filepicker")
local mod = require("lua/core/loadMod")
local editor = require("lua/core/editor")
local effects = require("lua/core/effects")

loaded_mod = false
local auto_play = false

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

local modFormat = "M.K."

local currentSample = 1
local sampleRate = 44100
numChannels = 4
channels = {}
releaseChannel = {}
lastNote = {}

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

function lowpass(arg1, arg2, arg3)
	local RC = 1.0 / (arg2 * 2 * math.pi)
	local dt = 1.0 / arg3
	local alpha = dt / (RC + dt)
	local out = {}
	out[1] = arg1[1]
	for i = 2, #arg1 do
		out[i] = out[i-1] + alpha * (arg1[i] - out[i-1])
	end
	return out
end

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
	love.graphics.setColor(0, 1, 180/255)
	for x=1, length-1, 1 do
		if offsetplay < screenWidth then
			love.graphics.line(20+offsetplay, 200+screenHeight+offsetAmplitude, 20+(x-1)*zoomEditorT+zoomEditorT, 200+screenHeight+mod_sampleDecoded[currentSample][x+1]/2)
			offsetplay = (x-1)*zoomEditorT+zoomEditorT
			offsetAmplitude = mod_sampleDecoded[currentSample][x+1]/2
		end
	end
	love.graphics.setCanvas()
end

function love.load()
	modstable = filePicker.load("./")
	editor.noteOffset(856)
	editor.localNoteOffset(offsetKey)
	love.graphics.setFont(font)
end

local beatTimer = 0
patternPosition = 1

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
		ticksPerLine = 6
		bpm = 125
		mod.load(selected_file)
		for i=1, 31 do
			local length = mod_sample_data[i] or 0
			if length ~= 0 then
				mod_sampleDecoded[i] = sampleDecode(mod_sample_data[i])
				mod_sampleDecoded[i] = lowpass(mod_sampleDecoded[i], 3300, sampleRate)
			end
		end
		oscilationWave(screenWidth, screenHeight)
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
		local lineTime = ticksPerLine * tickTime
		if beatTimer >= lineTime then 
			beatTimer = beatTimer - lineTime
			if patternPosition >= 64*(mod_song__position[currentPattern]+1) then
				currentPattern = currentPattern+1
				patternPosition = 64*(mod_song__position[currentPattern])
			end
			for channel=0, numChannels-1 do
				local base = (patternPosition-1)*numChannels*4 + channel*4
				print(base, mod_data_pattern[base+1])
				local b1 = mod_data_pattern[base+1]
				local b2 = mod_data_pattern[base+2]
				local b3 = mod_data_pattern[base+3]
				local b4 = mod_data_pattern[base+4]
				local period = bit.bor(bit.lshift(bit.band(b1, 0x0F), 8), b2)
				local instrument = bit.bor(bit.band(b1, 0xF0), bit.rshift(bit.band(b3, 0xF0), 4))
				local effect = bit.band(b3, 0x0F)
				local param = b4
				effects.applyPreEffects(effect, param)
				print(toBinary(b1, 8), toBinary(b2, 8), toBinary(b3, 8), toBinary(period, 12))
				print("tick: " .. ticksPerLine .. " bpm: " .. bpm .. " Channels: " .. numChannels)
				if period > 0 and instrument > 0 then
					editor.PLAY_NEW_SAMPLE(period, instrument, 44100, channel)
					effects.applyPosEffects(effect, param, channel)
				end
			end
			patternPosition=patternPosition+1
		end
	elseif loaded_mod then
		currentPattern = 1
		patternPosition = 64*mod_song__position[currentPattern]+1
	end
	t=t+1
end


function love.keypressed(key, scancode, isrepeat)
	editor.keyMap(key, currentSample)

   	if key == "escape" then
		collectgarbage()
      		love.event.quit()
   	end

	if key == "space" then
		if auto_play then
			auto_play = false
		else
			auto_play = true
		end
	end

	if key == "down" then
		filePicker.down()
	end

	if key == "up" then
		filePicker.up()
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
		currentSample = math.min(currentSample + 1, 31)
		oscilationWave(screenWidth, screenHeight)
	end

	if key == "left" then
		currentSample = math.max(currentSample - 1, 1)
		oscilationWave(screenWidth, screenHeight)
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
end

function love.wheelmoved(x, y)
	if y > 0 then
		zoomEditor = zoomEditor*2
		oscilationWave(screenWidth, screenHeight)
	end
	if y < 0 then
		zoomEditor = zoomEditor/2
		oscilationWave(screenWidth, screenHeight)
	end
end

function love.draw()
	love.graphics.clear(1, 0, 1)
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
		--editor.drawPattern(32)
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
end
