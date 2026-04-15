local editor = {}
increment = 1
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
	[180] = "D#5"
}

queuedCounter = 1

patternPositionY = 0

function editor.noteOffset(offset)
	noteOffset = offset
end

function editor.localNoteOffset(offset)
	localNoteOffset = offset
end

function editor.newQueueableSource(sampleRate1)
	sourceSound = love.audio.newQueueableSource(sampleRate1, 8, 1, 8)
end

function editor.sendBuffer(buffer, chunkSize)
    	local sd = love.sound.newSoundData(chunkSize, sampleRate, 8, 1)
	if not sourceSound then
		editor.newQueueableSource(sampleRate)
	end
    	for i = 0, chunkSize-1 do
    	    sd:setSample(i, buffer[i+1]/256)
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
	local gridPositionY = 180
	local gridX = 100*numChannels 
	local gridY = 400
	for gx = 0, gridX, 100 do
		love.graphics.line(gx+gridPositionX, gridPositionY, gx+gridPositionX, gridY+gridPositionY)
	end
	for gy = 0, gridY, 20 do
		love.graphics.line(gridPositionX, gy+gridPositionY, gridX+gridPositionX, gy+gridPositionY)
	end
	for y = 0, 19 do
		for x = 0, numChannels-1 do
			local data = (y+patternPosition-1)*(numChannels*4) + x*4
			love.graphics.setColor(1, 1, 1)
			if y+patternPosition-1 < 64*(mod_song__position[currentPattern]+1)+1 then
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
				love.graphics.print(noteK, 20+x*100, 180+y*20)
				love.graphics.setColor(1, 1, 1)
				if instrument ~= 0 then
					love.graphics.setColor(0.4, 1, 0.4)
				end
				love.graphics.print((instrument ~= 0) and string.format("%02X", instrument) or "--", 55+x*100, 180+y*20)
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
				love.graphics.print((effect ~= 0) and string.format("%X", effect) or "-", 80+x*100, 180+y*20)
				love.graphics.print((effect ~= 0) and string.format("%02X", param) or "--", 90+x*100, 180+y*20)
			end
		end
	end
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

function editor.channelPlay(qChannels)
	if sourceSound and sourceSound:getFreeBufferCount() > 0 then
		local buffer = {}
		local chunkSize = 1024
		for i = 1, chunkSize do
			local mix = 0
			for channel = 0, qChannels-1 do
				local currentChannel = channels[channel+1]
				if currentChannel then
					local sample = mod_sampleDecoded[currentChannel[1]]
					if sample then
						local pitch = currentChannel[2]
						local volume = currentChannel[3]
						local pos = currentChannel[4]
	
						if pos < #sample then
							local frequency = 7093789.2 / (pitch * 2)
							local advance = frequency/sampleRate
							if type_interpolate == "linear"then
								mix = mix+interpolate(sample, pos, 1)
							elseif type_interpolate == "none" then
								mix = mix+sample[math.floor(pos)]*(volume/64)
							end
							currentChannel[4] = pos+advance
						else
							local loop = (mod_samples__info[(currentChannel[1]-1)*6+5][1]*256 + mod_samples__info[(currentChannel[1]-1)*6+5][2])*2
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
			mix = mix*0.25
			buffer[i] = mix
		end
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

function editor.keyMap(key, sampleNum, channels)
	
	for i = 0, 32 do
		if key == keyMap[i] then
			--editor.REALTIME_PLAY_SAMPLE(keyMap[key], sampleNum, 44010, 1)
			channels[increment][1] = sampleNum
			channels[increment][2] = keyMap[key]
			channels[increment][3] = 64
			channels[increment][4] = 1
			if increment >= numChannels then
				increment = increment + 1
			else
				increment = 1
			end
		end
	end
end
return editor
