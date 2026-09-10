local editor = {}

local AMIGA_PAL_CLOCK = 3546894.6

local ffi = require("ffi")

local effects = require("lua/core/effects")

local samplesUntilNextTick = 0
local cursorPos = 1
counterY = 0
local selectedChannel = 0
local barPosition = 0
local type_interpolate = "linear"
local noteOffset = 0
local localNoteOffset = 0
local finetune = 0
local currentPosition = 0
local offsetCh = 0
local currentKey = 0
local keyMap = {
	["q"] = 428,
	["w"] = 381,
	["e"] = 339,
	["r"] = 320,
	["t"] = 285,
	["y"] = 254,
	["u"] = 226,
	["i"] = 214,
	["o"] = 190,
	["2"] = 404,
	["3"] = 360,
	["5"] = 302,
	["6"] = 269,
	["7"] = 240,
	["9"] = 202,
	["0"] = 180,
	[","] = 428,
	["."] = 381,
	[";"] = 339,
	["/"] = 320,
	["m"] = 453,
	["n"] = 508,
	["b"] = 570,
	["v"] = 640,
	["c"] = 678,
	["x"] = 762,
	["z"] = 856,
	["j"] = 480,
	["h"] = 538,
	["g"] = 604,
	["d"] = 720,
	["s"] = 808,
	"q", "w", "e", "r", "t", "y", "u", "i", "o", "2", "3", "5", "6", "7", "9", "0",
	"/", ";", ".", ",", "m", "n", "b", "v", "c", "x", "z", "j", "h", "g", "d", "s"
}

local numHex = {
	["a"] = 10,
	["b"] = 11,
	["c"] = 12,
	["d"] = 13,
	["e"] = 14,
	["f"] = 15,
	["0"] = 0,
	["1"] = 1,
	["2"] = 2,
	["3"] = 3,
	["4"] = 4,
	["5"] = 5,
	["6"] = 6,
	["7"] = 7,
	["8"] = 8,
	["9"] = 9,
	"a", "b", "c", "d", "e", "f", "1", "2", "3", "4", "5", "6", "7", "8", "9", "0"
}

local note = {
	[856] = "C-3",
	[808] = "C#3",
	[762] = "D-3",
	[720] = "D#3",
	[678] = "E-3",
	[640] = "F-3",
	[604] = "F#3",
	[570] = "G-3",
	[538] = "G#3",
	[508] = "A-3",
	[480] = "A#3",
	[453] = "B-3",
	[428] = "C-4",
	[404] = "C#4",
	[381] = "D-4",
	[360] = "D#4",
	[339] = "E-4",
	[320] = "F-4",
	[302] = "F#4",
	[285] = "G-4",
	[269] = "G#4",
	[254] = "A-4",
	[240] = "A#4",
	[226] = "B-4",
	[214] = "C-5",
	[202] = "C#5",
	[190] = "D-5",
	[180] = "D#5",
	[170] = "E-5",
	[160] = "F-5",
	[151] = "F#5",
	[143] = "G-5",
	[135] = "G#5",
	[127] = "A-5",
	[120] = "A#5",
	[113] = "B-5"
}

local yPos = 220

patternPositionY = 0

local biquadFilter = {
    -- Memory
    x1 = 0, x2 = 0,
    y1 = 0, y2 = 0,
    x1_2 = 0, x2_2 = 0,
    y1_2 = 0, y2_2 = 0,
    
    b0 = 0, b1 = 0, b2 = 0,
    a1 = 0, a2 = 0
}

function biquadFilter:setLowpass(cutoff_Hz, resonance_Q, sampleRate)
    cutoff_Hz = math.max(10, math.min(cutoff_Hz, sampleRate / 2.1))
    resonance_Q = math.max(0.1, resonance_Q)

    local w0 = 2 * math.pi * cutoff_Hz / sampleRate
    local alpha = math.sin(w0) / (2 * resonance_Q)
    local cosw0 = math.cos(w0)

    local a0 = 1 + alpha
    self.b0 = ((1 - cosw0) / 2) / a0
    self.b1 = (1 - cosw0) / a0
    self.b2 = ((1 - cosw0) / 2) / a0
    self.a1 = (-2 * cosw0) / a0
    self.a2 = (1 - alpha) / a0
end

function biquadFilter:process(buffer)
    for i = 1, #buffer do
        local x0 = buffer[i][1]

        local y0 = self.b0 * x0 
                 + self.b1 * self.x1 
                 + self.b2 * self.x2
                 - self.a1 * self.y1 
                 - self.a2 * self.y2

        self.x2 = self.x1
        self.x1 = x0
        self.y2 = self.y1
        self.y1 = y0

        buffer[i][1] = y0

	local x0 = buffer[i][2]

        local y0 = self.b0 * x0 
                 + self.b1 * self.x1_2 
                 + self.b2 * self.x2_2
                 - self.a1 * self.y1_2 
                 - self.a2 * self.y2_2

        self.x2_2 = self.x1_2
        self.x1_2 = x0
        self.y2_2 = self.y1_2
        self.y1_2 = y0

        buffer[i][2] = y0
    end
end

function editor.getOffsetCh()
	return offsetCh
end

function editor.initEngine(f, r)
	biquadFilter:setLowpass(f, r, sampleRate)
end

function editor.noteOffset(offset)
	noteOffset = offset
end

function editor.localNoteOffset(offset)
	localNoteOffset = offset
end

function editor.newQueueableSource(sampleRate1)
	sourceSound = love.audio.newQueueableSource(sampleRate1, 16, 2, 8)
end

function editor.sendBuffer(buffer, chunkSize)
    	local sd = love.sound.newSoundData(chunkSize, sampleRate, 16, 2)
	if not sourceSound then
		editor.newQueueableSource(sampleRate)
	end
    	for i = 0, chunkSize-1 do
	    sd:setSample(i, 1, buffer[i+1][1])
	    sd:setSample(i, 2, buffer[i+1][2])
    	end
	--[[if sourceSound.getFreeBufferCount then
		local free = sourceSound:getFreeBufferCount()
		if free > 0 then
			
		end
	end]]
    	sourceSound:queue(sd, sd:getSize())
    	if not sourceSound:isPlaying() then
    	    sourceSound:play()
    	end
end

function editor.drawPattern(q)
	local gridPositionX = 20
	local gridPositionY = 220
	local gridX = math.min(800, 100*numChannels)
	local gridY = 360

	love.graphics.setColor(1, 1, 1)
	for gx = 0, gridX, 100 do
		love.graphics.line(gx+gridPositionX, gridPositionY, gx+gridPositionX, gridY+gridPositionY)
	end
	--[[for gy = 0, gridY, 360 do
		love.graphics.line(gridPositionX, gy+gridPositionY, gridX+gridPositionX, gy+gridPositionY)
	end]]
	--yPos = yPos*patternPosition
	for y = 0, 17 do
		for x = 0, math.min(7, numChannels-1) do
			local data = (y+patternPosition)*(numChannels*4) + (x+offsetCh)*4
			if playerFormatXM then
				data = (y+patternPosition)*(numChannels*5) + x*5
			end
			if y+patternPosition < rowsInPattern*(song__position[currentPattern]+1) then
				if y == barPosition and x == 0 then
					love.graphics.setColor(1, 0, 0, 0.2)
					if editor_mod then
						love.graphics.setColor(1, 0, 0, 0.5)
					end
					love.graphics.rectangle("fill", gridPositionX, gridPositionY+barPosition*20, gridX, 20)
					love.graphics.setColor(1, 0, 0.4, 0.6)
					if cursorPos > 3 then
						love.graphics.rectangle("fill", 24+(cursorPos+3)*10+selectedChannel*4*25, gridPositionY+barPosition*20, 10, 20)
					elseif cursorPos == 1 then
						love.graphics.rectangle("fill", 20+(cursorPos-1)*33+selectedChannel*4*25, gridPositionY+barPosition*20, 30, 20)
					else
						love.graphics.rectangle("fill", 20+(cursorPos-1)*33+selectedChannel*4*25, gridPositionY+barPosition*20, (cursorPos == 3) and 10 or 20, 20)
					end
				end
				love.graphics.setColor(1, 1, 1)
				local period
				local instrument
				local volume
				local effect
				local param
				if playerFormatXM then
					local b1 = data_pattern[data]
					local b2 = data_pattern[data+1]
					local b3 = data_pattern[data+2]
					local b4 = data_pattern[data+3]
					local b4 = data_pattern[data+4]
					period = b1
					instrument = b2
					volume = b3
					effect = b4
					param = b5
				else
					local b1 = data_pattern[data]
					local b2 = data_pattern[data+1]
					local b3 = data_pattern[data+2]
					local b4 = data_pattern[data+3]
					period = bit.bor(bit.lshift(bit.band(b1, 0x0F), 8), b2)
					instrument = bit.bor(bit.band(b1, 0xF0), bit.rshift(bit.band(b3, 0xF0), 4))
					effect = bit.band(b3, 0x0F)
					param = b4
				end
				local noteK
				for i=0, #note do
					noteK = (note[period] ~= nil) and note[period] or "---"
					break
				end
				if noteK ~= "---" then
					love.graphics.setColor(0.5, 0.5, 1)
				end 
				love.graphics.print(noteK, 20+x*100, yPos+y*20)
				love.graphics.setColor(1, 1, 1)
				if instrument ~= 0 then
					love.graphics.setColor(0.4, 1, 0.4)
				end
				love.graphics.print((instrument ~= 0) and string.format("%02X", instrument) or "--", 53+x*100, yPos+y*20)
				love.graphics.setColor(1, 1, 1)
				if effect == 0xF then
					love.graphics.setColor(1, 1, 0)
				end
				if effect == 0xC then
					love.graphics.setColor(0, 1, 1)
				end
				if effect == 0xD then
					love.graphics.setColor(0, 1, 1)
				end
				if effect == 0xE then
					love.graphics.setColor(1, 0.4, 0.4)
				end
				--local varL = 0.5
				local varL = (bit.band(y+counterY, 0x0F) == 0 or bit.band(y+counterY, 0x0F) == 4 or bit.band(y+counterY, 0x0F) == 8 or bit.band(y+counterY, 0x0F) == 12) and 1 or 0.5
				love.graphics.print((effect ~= 0) and string.format("%X", effect) or "-", 86+x*100, yPos+y*20)
				love.graphics.print((effect ~= 0) and string.format("%02X", param) or "--", 95+x*100, yPos+y*20)
				love.graphics.setColor(varL, varL, varL)
				love.graphics.print(y+counterY, 0, yPos+y*20)
			end
		end
	end
end

function editor.incCounter(num)
	counterY = (counterY + 1)*num
end

function interpolate(sample, pos, volume, srepeat, pan)
    if #sample == 0 then return 0 end
    local i = math.floor(pos)
    local frac = pos - i
    local a = (sample[i] or 0)/128*volume*pan
    local b
    if i >= #sample then
        b = sample[srepeat]/128*volume*pan
    else
    	b = sample[i+1]/128*volume*pan
    end
    return a*(1-frac) + b*frac
end

function lowpass(arg1, arg2, arg3)
	local RC = 1.0 / (arg2 * 2 * math.pi)
	local dt = 1.0 / arg3
	local alpha = dt / (RC + dt)
	local out = 0
	out = out + alpha * (arg1 - out)
	return out
end

function processTrackerTick()
	if tickets == 0 then
		if patternPosition >= rowsInPattern*(song__position[currentPattern]+1) then
			editor.resetPosition()
			currentPattern = currentPattern+1
			if song__position[currentPattern] == nil or currentPattern > songLength then
				currentPattern = 1
				tickets = -1
			end
			patternPosition = rowsInPattern*song__position[currentPattern]
			editor.incCounter(0)
		end
		for ch=0, numChannels-1 do
			local base = patternPosition*numChannels*4 + ch*4
			if formatPlayerXM then
				data = (y+patternPosition)*(numChannels*5) + x*5
			end
			--print(base, data_pattern[base+1])
			--print(currentPattern, patternPosition, rowsInPattern*(song__position[currentPattern]+1)+1, "realPosition Pattern: " .. song__position[currentPattern])
			local b1 = data_pattern[base]
			local b2 = data_pattern[base+1]
			local b3 = data_pattern[base+2]
			local b4 = data_pattern[base+3]
			local period = bit.bor(bit.lshift(bit.band(b1, 0x0F), 8), b2)
			local instrument = bit.bor(bit.band(b1, 0xF0), bit.rshift(bit.band(b3, 0xF0), 4))
			local effect = bit.band(b3, 0x0F)
			local param = b4
			--print(toBinary(b1, 8), toBinary(b2, 8), toBinary(b3, 8), toBinary(period, 12))
			--print("ticks: " .. ticksPerLine .. " bpm: " .. bpm)
			if effect == 0x3 then
				if period > 0 then
					if param > 0 then
						channel_effects_portamentoSpeed[ch] = param
						--channel_volume[ch] = samples__info[channel_instrument[ch]][4]
					end
					local channelFinetune = channel_instrument[ch]
					if channelFinetune == 0 then
						channel_effects_portamentoTargetPitch[ch] = period
					else
						channel_effects_portamentoTargetPitch[ch] = period*samples__info[channelFinetune][3]	
					end
				end
			else
				if instrument > 0 then
					channel_instrument[ch] = instrument
					channel_volume[ch] = samples__info[instrument][4]
					channel_srepeat[ch] = samples__info[instrument][5]*2
					channel_sreplen[ch] = samples__info[instrument][6]*2
				end
				if period > 0 then
					local currentInst = channel_instrument[ch]

					if currentInst > 0 then
						channel_period[ch] = period*samples__info[channel_instrument[ch]][3]
						channel_position[ch] = 1
						--channel_effects_portamentoSpeed[ch] = 0
						channel_effects_vibratorPosition[ch] = 0
						--[[channel_effects_vibratorSpeed[ch] = 0
						channel_effects_vibratorDepth[ch] = 0
						channel_effects_vibratorValue[ch] = 0]]
					end
				end
			end
			effects.applyPreEffects(effect, param, ch)
		end
		editor.incrementPosition()
	else
		for ch=0, numChannels-1 do
			local base = patternPosition*numChannels*4 + ch*4
			local b3 = data_pattern[base+2]
			local b4 = data_pattern[base+3]
			local effect = bit.band(b3, 0x0F)
			local param = b4
			effects.applyPosEffects(effect, param, ch)
			if effect == 0xD then
				if tickets+1 >= ticksPerLine then
					effects.nextPattern(param)
				end
			elseif effect == 0xB then
				if tickets+1 >= ticksPerLine then
					effects.defineCurrentPattern(param)
				end
			end
		end
	end
	tickets = tickets + 1
	if tickets >= ticksPerLine then
		patternPosition = patternPosition + 1
		editor.incCounter(1)
		tickets = 0
		renderPattern = true
	end
end

local buffer = {}

function editor.channelPlay(qChannels)
	if sourceSound and sourceSound:getFreeBufferCount() > 0 then
		local chunkSize = 1024
		for i = 1, chunkSize do
			if auto_play then
				if samplesUntilNextTick <= 0 then
					processTrackerTick()
					local samplesPerTick = (sampleRate*2.5) / bpm
					samplesUntilNextTick = samplesUntilNextTick + samplesPerTick
				end
				samplesUntilNextTick = samplesUntilNextTick - 1
			end
			--local qPlayingChannel = 0
			local mixLeft = 0
			local mixRight = 0
			for ch = 0, qChannels-1 do
				if true then
					local sample = sampleDecoded[channel_instrument[ch]]
					if sample then
						local period = channel_period[ch]+channel_effects_vibratorValue[ch]
						local volume = (channel_muted[ch]) and 0 or channel_volume[ch]
						if period < 113 and period > 856 then
							volume = 0
						end
						local panLeft = channel_volumeLeft[ch]
						local panRight = channel_volumeRight[ch]
						local pos = channel_position[ch]
						local srepeat = channel_srepeat[ch]
						local sreplen = channel_sreplen[ch]

						local pitch = AMIGA_PAL_CLOCK / period * 2
						local advance = pitch/sampleRate
						advance = math.min(4.0, advance)
						--local advance = localNoteOffset/period
						if type_interpolate == "linear" then
							mixLeft = mixLeft+interpolate(sample, pos, volume, srepeat, panLeft)
							mixRight = mixLeft+interpolate(sample, pos, volume, srepeat, panRight)
						elseif type_interpolate == "none" then
							mixLeft = mixLeft+(sample[math.floor(pos)] or 0)/128*volume*panLeft
							mixRight = mixRight+(sample[math.floor(pos)] or 0)/128*volume*panRight
						end
						pos = pos+advance
						if sreplen > 2 then
							if not channel_oneShoot[ch] and pos >= #sample then
								pos = srepeat
								channel_oneShoot[ch] = true
							elseif channel_oneShoot[ch] and pos >= srepeat+sreplen then
								pos = srepeat
							end
						else
							if  pos > #sample then
								channel_instrument[ch] = 0
								pos = 0
							end
						end
						channel_position[ch] = pos
						--qPlayingChannel = qPlayingChannel+1
					end
				end
			end
			--print(mixLeft, mixRight)
			mixLeft = math.tanh(mixLeft*0.4)
			mixRight = math.tanh(mixRight*0.4)
			--qPlayingChannel = 0
			--periodTone = mixLeft+mixRight
			buffer[i] = {mixLeft, mixRight}
			--buffer[(i-1)*2+1] = mixLeft
			--buffer[(i-1)*2+2] = mixRight
		end
		biquadFilter:process(buffer)
		--print(buffer[1], buffer[chunkSize])
		editor.sendBuffer(buffer, chunkSize)
	end
end

function editor.init()
	patternPosition = 0
	ticksPerLine = 6
	bpm = 125
	channels = {}
	lastNote = {}
	offsetCh = 0
	selectedChannel = 0
end

function editor.resetPosition()
	currentPosition = 0
end

function editor.incrementPosition()
	currentPosition = currentPosition+1
end

function editor.getPosition()
	return currentPosition
end

function editor.counterYUp()
	counterY = counterY-1
end

function editor.counterYDown()
	counterY = counterY+1
end

function editor.resetBar()
	barPosition = 0
	counterY = 0
end

function editor.barDown()
	barPosition = math.min(17, barPosition + 1)
	if barPosition >= 17 then
		if rowsInPattern-(currentPosition+barPosition) > 1 then
			patternPosition = patternPosition + 1
			counterY = counterY + 1
		end
	end
end

function editor.barUp()
	if barPosition == 0 then
		if counterY > 0 then
			patternPosition = patternPosition - 1
			counterY = counterY - 1
		end
	end
	barPosition = math.max(0, barPosition - 1)
end

function editor.left()
	if cursorPos == 1 then
		selectedChannel = math.max(0, selectedChannel - 1)
		if selectedChannel > 5 then
			offsetCh = math.max(0, offsetCh-1)
		end
		cursorPos = 6
	end
	cursorPos = math.max(1, cursorPos - 1)
end
function editor.right()
	--[[local pos = 0
	for i=1, numChannels do
		if cursorPos < pos
		selectedChannel = math.min(numChannels-1, selectedChannel + 1)
	end]]
	cursorPos = cursorPos + 1
	if cursorPos == 6 then
		selectedChannel = math.min(numChannels-1, selectedChannel + 1)
		if selectedChannel > 6 and selectedChannel < numChannels-1 then
			offsetCh = offsetCh+1
		end
		cursorPos = 1
	end
end

function editor.getSelectedChannel()
	return selectedChannel
end

function editor.keyMap(key, sampleNum, channels)
	if key == "delete" then
		if editor_mod and not fileSearch then
			local data = (barPosition+patternPosition)*(numChannels*4) + selectedChannel*4
			if cursorPos == 2 then
				data_pattern[data] = bit.bor(bit.lshift(0x00, 4), bit.band(data_pattern[data], 0x0F))
				data_pattern[data+2] = bit.bor(bit.lshift(0x00, 4), bit.band(data_pattern[data+2], 0x0F))
			elseif cursorPos == 3 then
				data_pattern[data+2] = bit.bor(bit.band(data_pattern[data+2], 0xF0), bit.rshift(0x00, 4))
			elseif cursorPos == 4 then
				data_pattern[data+3] = bit.bor(bit.band(data_pattern[data+3], 0x0F), bit.lshift(0x00, 4))
			elseif cursorPos == 5 then
				data_pattern[data+3] = bit.bor(bit.rshift(0x00, 4), bit.band(data_pattern[data+3], 0xF0))
			else
				data_pattern[data] = 0
				data_pattern[data+1] = 0
				data_pattern[data+2] = 0
				data_pattern[data+3] = 0
			end
		end
		renderPattern = true
	end
	if key == "tab" then
		if selectedChannel > 6 then
			if offsetCh+1 >= numChannels then
				selectedChannel = 0
			end
			offsetCh = (offsetCh+1)%numChannels
		else
			selectedChannel = selectedChannel+1
		end
		cursorPos = 1
		renderPattern = true
	end
	for i = 0, 32 do
		if key == numHex[i] and editor_mod then
			local base = (patternPosition+barPosition)*numChannels*4 + selectedChannel*4
			if cursorPos == 3 then
				data_pattern[base+cursorPos-1] = bit.bor(bit.band(data_pattern[base+cursorPos-1], 0xF0), numHex[key])
			end
			if cursorPos == 4 then
				data_pattern[base+3] = bit.bor(bit.lshift(numHex[key], 4), bit.band(data_pattern[base+3], 0x0F))
			end
			if cursorPos == 5 then
				data_pattern[base+3] = bit.bor(numHex[key], bit.band(data_pattern[base+3], 0xF0))
			end
			renderPattern = true
		end
		if key == keyMap[i] and cursorPos == 1 then
			--editor.REALTIME_PLAY_SAMPLE(keyMap[key], sampleNum, 44010, 1)
			if editor_mod and not fileSearch then
				local data = (barPosition+patternPosition)*(numChannels*4) + selectedChannel*4
				data_pattern[data+2] = bit.bor(bit.lshift(bit.band(sampleNum, 0x0F), 4), bit.band(data_pattern[data+3], 0x0F))
				data_pattern[data] = bit.bor(bit.band(sampleNum, 0xF0), bit.rshift(bit.band(keyMap[key], 0xF00), 8))
				data_pattern[data+1] = bit.band(keyMap[key], 0xFF)
				if not auto_play then
					barPosition = barPosition+1
				end
			end
			currentKey = (currentKey+1)%numChannels
			local playChannel = (selectedChannel+currentKey-1)%numChannels
			if editor_mod then
				playChannel = selectedChannel
				currentKey = 0
			end
			channel_instrument[playChannel] = sampleNum
			channel_period[playChannel] = keyMap[key]
			channel_volume[playChannel] = 1
			channel_position[playChannel] = 1
			channel_srepeat[playChannel] = samples__info[channel_instrument[playChannel]][5]*2
			channel_sreplen[playChannel] = samples__info[channel_instrument[playChannel]][6]*2
			channel_instrument[playChannel+1] = sampleNum
			channel_period[playChannel+1] = keyMap[key]
			channel_volume[playChannel+1] = 1
			channel_position[playChannel+1] = 1
			channel_srepeat[playChannel+1] = samples__info[channel_instrument[playChannel]][5]*2
			channel_sreplen[playChannel+1] = samples__info[channel_instrument[playChannel]][6]*2
			renderPattern = true
		end
	end
end
return editor
