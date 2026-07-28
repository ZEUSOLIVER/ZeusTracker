-- Copyright (c) 2026 Zeus
-- Licensed under the GNU General Public License v3.0
-- See LICENSE file in the project root for details.

local AMIGA_CLOCK = 7093789.2

local channel = require("lua/core/channel")
local ffi = require("ffi")
local filePicker = require("lua/core/filepicker")
local mod = require("lua/core/loadMod")
local xm = require("lua/core/loadXM")
--local effects = require("lua/core/effects")
local editor = require("lua/core/editor")
local logo = require("lua/core/logo")
local importSamplesFAF = require("lua/core/importSamplesFAF")

local fileSearch = true
editor_mod = false
local loaded_mod = false
auto_play = false
playerFormatXM = false

tickets = 0
ticksPerLine = 6
bpm = 125
rowsInPattern = 64
songLength = 1

screenWidth = love.graphics.getWidth()-40
screenHeight = love.graphics.getHeight()/2

local t = 0

title = ""
samples__info = {}
song__length = {}
underfined = {}
song__position = {0}
underfined2 = "M.K."
signature_value = 1024
data_pattern = {}
sample_data = {{58, 127, 127, 127, 128, 128, 127, 127, 127, 127, 64, 180, 180}, {127, 128, 127, 128, 127, 128, 127, 128, 127, 128, 127, 128, 127, 128, 127, 128, 127, 128, 127, 128, 127, 128, 127, 128, 127, 128, 127, 128, 127, 128, 127, 128, 127, 128, 127, 128}}
sampleDecoded = {}
sampleDecoded2 = {}

local selected_file = ""
canvas = love.graphics.newCanvas( )
canvas:setFilter("linear", "nearest")
canvasPattern = love.graphics.newCanvas( )
canvasPattern:setFilter("linear", "nearest")
canvasUI = love.graphics.newCanvas( )
canvasUI:setFilter("linear", "nearest")
canvasChannelSpec = love.graphics.newCanvas()
canvasUI:setFilter("linear", "nearest")

renderPattern = false
local modFormat = "M.K."

local currentSample = 1
sampleRate = 44100
numChannels = 4
channels = {}

currentPattern = 1
--currentPosition = 0

local mouseSelected = ""
local mouseSelectedColor = 0

local font = love.graphics.newImageFont("gfx/imagefont.png",
    " abcdefghijklmnopqrstuvwxyz" ..
    "ABCDEFGHIJKLMNOPQRSTUVWXYZ0" ..
    "123456789.,!?-+/():;%&`'*#=[]\"")

local offsetKey = 214

local zoomEditor = 1
local zoomEditorTx = 1
local showSample = false
local loadSamples = false

function sampleDecode(data)
    local out = {}
    for i = 1, #data do
        local v = data[i]
        if v >= 128 then v = v - 256 end
        out[i] = v
    end
    return out
end

function oscilationWave(ch, screenWidth, screenHeight)
	love.graphics.setCanvas(canvas)
	love.graphics.clear(0, 0, 0, 0)
	love.graphics.setLineWidth(1)
	love.graphics.setColor(0.11,0.11,0.11, 0.5)
	love.graphics.rectangle("fill", 20, 400, screenWidth, screenHeight-120)
	love.graphics.setColor(0.23,0.23,0.23)
	for gx=20,screenWidth+20,40 do
	    	love.graphics.line(gx,400,gx,280+screenHeight)
	end
	for gy=400,280+screenHeight,20 do
		love.graphics.line(20,gy,screenWidth+20,gy)
	end
	love.graphics.setColor(1, 1, 1)
	local sampleLength = (sampleDecoded[currentSample] == nil) and 1 or #sampleDecoded[currentSample]
	--local sampleLength = samples__info[currentSample][2]*2
	love.graphics.setColor(0.23, 0.23, 0.23)
	if sampleLength > 0 then
		love.graphics.setColor(1, 1, 1)
	end
	local offsetplay = 0
	local offsetAmplitude = 0
	local zoomEditorT = zoomEditor*(screenWidth)/sampleLength
	local wavePrecision = math.min(sampleLength/2, math.floor(zoomEditorTx/zoomEditorT))+1
	--love.graphics.setColor(0, 1, 180/255)
	local lines = {}
	for x=1, sampleLength, wavePrecision do
		local sample = (sampleDecoded[currentSample] ~= nil) and sampleDecoded[currentSample][x] or 0
		local xx = 20+(x-1)*zoomEditorT
		local yy = 190+screenHeight-sample/1.43
		for i = 0, wavePrecision-1 do
			lines[(x+i-1)*2+1] = xx
			lines[(x+i-1)*2+2] = yy
		end
		if lines[(x-1)*2+1] >= screenWidth+20 then
			break
		end
	end
	if #lines > 2 then love.graphics.line(lines) end
	love.graphics.print(currentSample, 20, 400)
	love.graphics.print("Length: " .. sampleLength, 20, screenHeight*2-40)
	love.graphics.setColor(0.03,0.03,0.03, 1)
	love.graphics.setLineWidth(20)
	love.graphics.rectangle("line", 10, 390, screenWidth+20, screenHeight/2+50)
	love.graphics.setCanvas()
end

function love.load()
	logo.load()
	modstable = filePicker.load("./")
	editor.noteOffset(856)
	editor.localNoteOffset(offsetKey)
	love.graphics.setDefaultFilter("nearest", "nearest")
	love.graphics.setFont(font)
	--local font = love.graphics.newFont("gfx/ZeusTracker.ttf", 12)
	--love.graphics.setFont(font)
	editor.sendBuffer({{0, 0}}, 1)
	editor.initEngine(5900, 0.407)
	
	numChannels = 4
	for i=1, 31 do
		samples__info[i] = {"", 0, 0, 0, 0, 0}
	end
	--[[for i = 1, 31 do
		samples__info[i][1] = ""
		samples__info[i][2] = 0
		samples__info[i][3] = 0
		samples__info[i][4] = 0
		samples__info[i][5] = 0
		samples__info[i][6] = 0
	end]]

	samples__info[1][1] = ""
	samples__info[1][2] = 4
	samples__info[1][3] = 2^(0/96.0)
	samples__info[1][4] = 1
	samples__info[1][5] = 0
	samples__info[1][6] = 6
	samples__info[2][1] = "triangle"
	samples__info[2][2] = 4
	samples__info[2][3] = 2^(0/96.0)
	samples__info[2][4] = 1
	samples__info[2][5] = 0
	samples__info[2][6] = 39

	for i = 1, numChannels*4*rowsInPattern do
		data_pattern[i] = 0
	end
	editor.init()
	channel.init(numChannels, channels)
	currentPattern = 1
	currentPosition = 0
	patternPosition = 0
	for i=1, 31 do
		local sample = sample_data[i] or 0
		if sample ~= 0 then
			sampleDecoded[i] = sampleDecode(sample)
		end
	end
	oscilationWave(editor.getSelectedChannel(), screenWidth, screenHeight)
	editor.incCounter(0)
	renderPattern = true
	fileSearch = false
	tickets = 0
	loaded_mod = true
	selected_file = ""

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
		if string.sub(selected_file, #selected_file-3, #selected_file) == ".mod" then
			if loadSamples then
				loadSamples = false
				importSamplesFAF.load(selected_file)
			else
				editor.init()
				channel.init(numChannels, channels)
				playerFormatXM = false
				mod.load(selected_file)
				love.window.setTitle("ZeusTracker - " .. title)
				rowsInPattern = 64
				channel.init(numChannels, channels)
				currentPosition = 0
				currentPattern = 1
				counterY = 0
				patternPosition = 64*(song__position[currentPattern])
				for i=1, 31 do
					local length = sample_data[i] or 0
					if length ~= 0 then
						sampleDecoded[i] = sampleDecode(sample_data[i])
					end
				end
				editor.incCounter(0)
				renderPattern = true
				tickets = 0
				loaded_mod = true
			end
			oscilationWave(editor.getSelectedChannel(), screenWidth, screenHeight)
			fileSearch = false
			selected_file = ""
		elseif string.sub(selected_file, #selected_file-2, #selected_file) == ".xm" then
			playerFormatXM = true
			xm.load(selected_file)
			currentPosition = 0
			currentPattern = 1
			counterY = 0
			patternPosition = rowsInPattern*(song__position[currentPattern])
			--oscilationWave(editor.getSelectedChannel(), screenWidth, screenHeight)
			editor.incCounter(0)
			--renderPattern = true
			fileSearch = false
			tickets = 0
			loaded_mod = true
			selected_file = ""
		end
	end
	--[[loadMod("aftershc.mod")
	for i=1, 31 do
		local length = sample_data[i] or 0
		if length ~= 0 then
			sampleDecoded[i] = sampleDecode(sample_data[i])
		end
	end]]

	local x, y = love.mouse.getPosition()
	local cal = screenWidth*0.09
	if x < cal and y < 20 then
		mouseSelected = "button1"
	elseif x > cal+4 and x < screenWidth*0.2+screenWidth*0.2 and y < 20 then
		mouseSelected = "button2"
	else
		mouseSelected = ""
	end

	local mLeftButton = love.mouse.isDown(1)
	if mLeftButton and showSample and x > 20 and y > screenHeight+100 and x < screenWidth then
		local sample = sampleDecoded[currentSample] or {}
		local length = #sample
		local x1 = #sample/zoomEditor
		local x2 = screenWidth/(x-20)
		local x3 = x1/x2
		local y1 = screenHeight/(y-500)
		local cursorRation = #sample/(zoomEditor*400)
		for i = -cursorRation, cursorRation do
			sample[math.min(math.floor(x3+i+1), #sample)] = 400/-y1
		end
		--sample[math.min(math.floor(x3+1), #sample)] = 600/y1
		oscilationWave(editor.getSelectedChannel(), screenWidth, screenHeight)
	end

	t = t + 1
	editor.channelPlay(numChannels)
	--logo.update(dt/2+math.min(1, (math.abs(periodTone)/2020)))
	logo.update(dt/2)
	--screenWidth = love.graphics.getWidth()-40
	--screenHeight = love.graphics.getHeight()/2
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
			for i = 0, numChannels-1 do
				channel_instrument[i] = 0
				channel_position[i] = 0
			end
		else
			auto_play = true
			editor.resetBar()
			patternPosition = rowsInPattern*song__position[currentPattern]
			editor.incCounter(0)
			tickets = -1
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
		for i = 0, numChannels-1 do
			channel_instrument[i] = 0
			channel_position[i] = 0
		end
		--editor.resetBar()
		renderPattern = true
	end

	if key == "down" then
		if fileSearch then
			filePicker.down()
		else
			editor.barDown()
			renderPattern = true
		end
	end

	if key == "up" then
		if fileSearch then
			filePicker.up()
		else
			editor.barUp()
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
		if showSample then
			currentSample = math.min(currentSample + 1, 31)
			oscilationWave(editor.getSelectedChannel(), screenWidth, screenHeight)
		else
			editor.right()
			renderPattern = true
		end
	end

	if key == "left" then
		if showSample then
			currentSample = math.max(currentSample - 1, 1)
			oscilationWave(editor.getSelectedChannel(), screenWidth, screenHeight)
		else
			editor.left()
			renderPattern = true
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
	local cal = screenWidth*0.09
	if x > cal+4 and x < screenWidth*0.2+screenWidth*0.2 and y < 20 then
		loadSamples = true
		mouseSelectedColor = 255
	end
	local offsetCh = editor.getOffsetCh()
	for i = 0, math.min(7, numChannels-1) do
		if x > 20+100*i and y > 160 and x < 120+100*i and y < 220 then
			if channel_muted[i+offsetCh] then
				channel_muted[i+offsetCh] = false
			else
				channel_muted[i+offsetCh] = true
			end
		end
	end
end

function love.wheelmoved(x, y)
	if y > 0 then
		if fileSearch then
			filePicker.up()
		elseif showSample then
			zoomEditor = zoomEditor*1.2
			zoomEditorTx = zoomEditorTx/1.2
			oscilationWave(editor.getSelectedChannel(), screenWidth, screenHeight)
		else
			if counterY > 0 then
				patternPosition = patternPosition - 1
				editor.counterYUp()
				renderPattern = true
			end
		end
	end
	if y < 0 then
		if fileSearch then
			filePicker.down()
		elseif showSample then
			if zoomEditorTx < 1 then
				zoomEditor = zoomEditor/1.2
				zoomEditorTx = zoomEditorTx*1.2
			end
			oscilationWave(editor.getSelectedChannel(), screenWidth, screenHeight)
		else
			patternPosition = patternPosition + 1
			editor.counterYDown()
			renderPattern = true
		end
	end
end

local distance = 0

function love.draw(dt)
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
	love.graphics.setColor(1, 1, 1)
	local x, y = love.mouse.getPosition()
	if mouseSelected == "button1" then
		love.graphics.setColor(120/255, 120/255, (120+mouseSelectedColor)/255)
	end
	love.graphics.rectangle("fill", 0, 0, screenWidth*0.09, 20)
	love.graphics.setColor(0, 0, 0)
	love.graphics.print("Sample", 0, 0)
	love.graphics.setColor(1, 1, 1)
	if mouseSelected == "button2" then
		love.graphics.setColor(120/255, 120/255, (120+mouseSelectedColor)/255)
	end
	local cal = screenWidth*0.09
	love.graphics.rectangle("fill", cal+4, 0, screenWidth*0.2, 20)
	love.graphics.setColor(0, 0, 0)
	love.graphics.print("Load Samples", cal+4, 0)
	mouseSelectedColor = 0
	if loaded_mod then
		love.graphics.setColor(20/255, 20/255, 120/255)
		love.graphics.rectangle("fill", 200+screenWidth/2, 20, 200, screenHeight-140)
		love.graphics.setColor(1, 1, 1)
		for i=1, 11 do
			love.graphics.print(samples__info[i][1],200+screenWidth/2,(i-1)*14+20)
		end
		if renderPattern then
			love.graphics.setCanvas(canvasPattern)
			love.graphics.clear(0, 0, 0, 0)
			renderPattern = false
			editor.drawPattern(32)
			love.graphics.setCanvas()
		end
		for i = 0, numChannels-1 do
			if i < 8 then
				local offsetCh = editor.getOffsetCh()
				channel.specView(i+offsetCh, 20+i*100, 200, t, offsetCh)
			end
		end
		love.graphics.setColor(1, 1, 1)
		love.graphics.draw(canvasChannelSpec, 0, 0)
		love.graphics.draw(canvasPattern, 0, 0)
	end
	if showSample then
		love.graphics.draw(canvas, 0, 0)
		love.graphics.setColor(0, 1, 180/255)
		local ch1 = nil
		local searchSample = nil
		for ch = 0, numChannels-1 do
			if channel_instrument[ch] == currentSample then
				searchSample = channel_instrument[ch]
				ch1 = ch
			end
		end
		local sample = sampleDecoded[searchSample]
		if sample then
			local pos = math.min(screenWidth, channel_position[ch1]*zoomEditor/(#sample/screenWidth))
			love.graphics.line(20+pos, 100+screenHeight, 20+pos, 200+screenHeight+80)
		end
		local sreplen = samples__info[currentSample][6]*2
		if sreplen > 2 then
			local srepeat = samples__info[currentSample][5]*2
			local sample = sampleDecoded[currentSample]
			local ecx = srepeat*zoomEditor/(#sample/screenWidth)
			local edx = math.min(screenWidth, (srepeat+sreplen)*zoomEditor/(#sample/screenWidth))
			love.graphics.setColor(1, 1, 0, 0.02)
			love.graphics.rectangle("fill", 20+ecx, 100+screenHeight, edx-ecx, 100+80)
			love.graphics.setColor(1, 1, 0)
			love.graphics.line(20+ecx, 100+screenHeight, 20+ecx, 200+screenHeight+80)
			love.graphics.line(20+edx, 100+screenHeight, 20+edx, 200+screenHeight+80)
		end
		love.graphics.setColor(1, 1, 1)
	end
	love.graphics.print("CurrentPattern: " .. currentPattern, 200, 0)
	love.graphics.print("Position: " .. editor.getPosition(), 600, 0)
	love.graphics.print("Position: " .. patternPosition, 400, 0)
	--love.graphics.print("ModPosition: " .. (song__position[currentPattern+1] or 0), 550, 0)
	love.graphics.print("BPM: " .. bpm, 200, 100)
	love.graphics.print("Tickets: " .. ticksPerLine, 400, 100)
end