local editor = {}
local counterY = 0
local selectedChannel = 0
local barPosition = 0
local type_interpolate = "none"
local noteOffset = 0
local localNoteOffset = 0
local finetune = 0
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
    -- Memória da onda (passado)
    x1 = 0, x2 = 0,
    y1 = 0, y2 = 0,
    
    -- Coeficientes matemáticos
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
                 + self.b1 * self.x1 
                 + self.b2 * self.x2
                 - self.a1 * self.y1 
                 - self.a2 * self.y2

        self.x2 = self.x1
        self.x1 = x0
        self.y2 = self.y1
        self.y1 = y0

        buffer[i][2] = y0
    end
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
	sourceSound = love.audio.newQueueableSource(sampleRate1, 8, 2, 8)
end

function editor.sendBuffer(buffer, chunkSize)
    	local sd = love.sound.newSoundData(chunkSize, sampleRate, 8, 2)
	if not sourceSound then
		editor.newQueueableSource(sampleRate)
	end
    	for i = 0, chunkSize-1, 1 do
	    sd:setSample(i, 1, buffer[i+1][1]/256)
	    sd:setSample(i, 2, buffer[i+1][2]/256)
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
	local gridX = 100*numChannels
	local gridY = 360
	for gx = 0, gridX, 100 do
		love.graphics.line(gx+gridPositionX, gridPositionY, gx+gridPositionX, gridY+gridPositionY)
	end
	--[[for gy = 0, gridY, 360 do
		love.graphics.line(gridPositionX, gy+gridPositionY, gridX+gridPositionX, gy+gridPositionY)
	end]]
	--yPos = yPos*patternPosition
	for y = 0, 17 do
		for x = 0, numChannels-1 do
			local data = (y+patternPosition-1)*(numChannels*4) + x*4
			if y+patternPosition-1 < 64*(mod_song__position[currentPattern]+1) then
				if y == barPosition and editor_mod then
					love.graphics.setColor(1, 0, 0, 0.1)
					love.graphics.rectangle("fill", gridPositionX, gridPositionY+barPosition*20, gridX, 20)
				end
				love.graphics.setColor(1, 1, 1)
				local b1 = mod_data_pattern[data+1]
				local b2 = mod_data_pattern[data+2]
				local b3 = mod_data_pattern[data+3]
				local b4 = mod_data_pattern[data+4]
				local period = bit.bor(bit.lshift(bit.band(b1, 0x0F), 8), b2)
				local noteK
				for i=0, #note do
					noteK = (note[period] ~= nil) and note[period] or "---"
					break
				end
				local instrument = bit.bor(bit.band(b1, 0xF0), bit.rshift(bit.band(b3, 0xF0), 4))
				local effect = bit.band(b3, 0x0F)
				local param = b4
				if noteK ~= "---" then
					love.graphics.setColor(0.5, 0.5, 1)
				end 
				love.graphics.print(noteK, 20+x*100, yPos+y*20)
				love.graphics.setColor(1, 1, 1)
				if instrument ~= 0 then
					love.graphics.setColor(0.4, 1, 0.4)
				end
				love.graphics.print((instrument ~= 0) and string.format("%02X", instrument) or "--", 55+x*100, yPos+y*20)
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
				love.graphics.print((effect ~= 0) and string.format("%X", effect) or "-", 80+x*100, yPos+y*20)
				love.graphics.print((effect ~= 0) and string.format("%02X", param) or "--", 90+x*100, yPos+y*20)
				love.graphics.setColor(0.5, 0.5, 0.5)
				love.graphics.print(y+counterY, 0, yPos+y*20)
			end
		end
	end
end

function incCounter(num)
	counterY = (counterY + 1)*num
end

function interpolate(sample, pos, volume)
    if not sample then return 0 end
    local i = math.floor(pos)
    if i < 1 or i >= #sample then
        return 0
    end
    local frac = pos - i
    local a = sample[i]-volume or 0
    local b = sample[i+1]-volume or 0
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

function editor.channelPlay(qChannels)
	if sourceSound and sourceSound:getFreeBufferCount() > 0 then
		local buffer = {}
		local chunkSize = 800
		for i = 1, chunkSize do
			local mixLeft = 0
			local mixRight = 0
			for channel = 0, qChannels-1 do
				local currentChannel = channels[channel+1]
				if currentChannel then
					local sample = mod_sampleDecoded[currentChannel[1]]
					if sample then
						local pitch = currentChannel[2]
						--pitch = math.max(113, math.min(856, pitch))
						local volume = (currentChannel[10]) and currentChannel[3] or 0
						local pos = currentChannel[4]
						local loop = currentChannel[8]
						local length = currentChannel[9]
						local lengthPlay = (loop > 0) and loop+length or #sample

						if pos < lengthPlay then
							local frequency = 7093789.2 / (pitch * 2)
							local advance = frequency/sampleRate
							advance = math.min(4.0, advance)
							--local advance = localNoteOffset/pitch
							if type_interpolate == "linear" then
								if channel == 0 or channel == 2 or channel == 4 or channel == 6 then
									mixLeft = mixLeft+interpolate(sample, pos, 1)
								elseif channel == 1 or channel == 3 or channel == 5 or channel == 7 then
									mixRight = mixRight+interpolate(sample, pos, 1)
								end
							elseif type_interpolate == "none" then
								if channel == 0 or channel == 2 or channel == 4 or channel == 6 then
									--local mixed = lowpass((sample[math.floor(pos)] or 0), 4000, sampleRate)
									--mixLeft = mixLeft+mixed*volume
									mixLeft = mixLeft+(sample[math.floor(pos)] or 0)*volume
								elseif channel == 1 or channel == 3 or channel == 5 or channel == 7 then
									--local mixed = lowpass((sample[math.floor(pos)] or 0), 4000, sampleRate)
									--mixRight = mixRight+mixed*volume
									mixRight = mixRight+(sample[math.floor(pos)] or 0)*volume
end
							end
							currentChannel[4] = pos+advance
						else
							if loop > 0 then
								currentChannel[4] = loop
							else
								currentChannel[1] = 0
								currentChannel[4] = 1
							end
							
						end
					end
				end
			end
			mixLeft = mixLeft
			mixRight = mixRight
			--periodTone = mixLeft+mixRight
			buffer[i] = {mixLeft, mixRight}
		end
		biquadFilter:process(buffer)
		--print(buffer[1], buffer[chunkSize])
		editor.sendBuffer(buffer, chunkSize)
	end
end

function editor.init()
	patternPosition = 1
	ticksPerLine = 6
	bpm = 125
	channels = {}
	lastNote = {}
end

function editor.resetBar()
	barPosition = 0
end

function editor.barDown()
	barPosition = math.min(19, barPosition + 1)
end

function editor.barUp()
	barPosition = math.max(0, barPosition - 1)
end

function editor.left()
	selectedChannel = math.max(0, selectedChannel - 1)
end
function editor.right()
	selectedChannel = math.min(numChannels-1, selectedChannel + 1)
end

function editor.keyMap(key, sampleNum, channels)
	for i = 0, 32 do
		if key == "delete" then
			if editor_mod and not fileSearch then
				local data = (barPosition+patternPosition-1)*(numChannels*4) + selectedChannel*4
				mod_data_pattern[data+1] = 0
				mod_data_pattern[data+2] = 0
				mod_data_pattern[data+3] = 0
				mod_data_pattern[data+4] = 0
			end
			renderPattern = true
		end
		if key == keyMap[i] then
			--editor.REALTIME_PLAY_SAMPLE(keyMap[key], sampleNum, 44010, 1)
			if editor_mod and not fileSearch then
				local data = (barPosition+patternPosition-1)*(numChannels*4) + selectedChannel*4
				mod_data_pattern[data+3] = bit.bor(bit.lshift(bit.band(sampleNum, 0x0F), 4), bit.band(mod_data_pattern[data+3], 0x0F))
				mod_data_pattern[data+1] = bit.band(sampleNum, 0xF0)
				mod_data_pattern[data+1] = bit.rshift(bit.band(keyMap[key], 0xF00), 8)
				mod_data_pattern[data+2] = bit.band(keyMap[key], 0xFF)
				barPosition = barPosition+1
			end
			channels[selectedChannel+1][1] = sampleNum
			channels[selectedChannel+1][2] = keyMap[key]
			channels[selectedChannel+1][3] = 1
			channels[selectedChannel+1][4] = 1
			channels[selectedChannel+1][8] = (mod_samples__info[(channels[selectedChannel+1][1]-1)*6+5][1]*256 + mod_samples__info[(channels[selectedChannel+1][1]-1)*6+5][2])*2
			channels[selectedChannel+1][9] = (mod_samples__info[(channels[selectedChannel+1][1]-1)*6+6][1]*256 + mod_samples__info[(channels[selectedChannel+1][1]-1)*6+6][2])*2
			renderPattern = true
		end
	end
end
return editor
