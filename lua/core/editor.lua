editor = {}
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

patternPositionY = 0

function editor.noteOffset(offset)
	noteOffset = offset
end

function editor.localNoteOffset(offset)
	localNoteOffset = offset
end

function editor.PLAY_NEW_SAMPLE(arg1, arg2, arg3, channel)
	if channels[channel] ~= nil then
		lastNote[channel] = channels[channel]
		channels[channel]:stop()
		channels[channel]:setVolume(1)
		channels[channel] = nil
	end
	local samples = mod_sampleDecoded[arg2]
	local length_sample = #mod_sampleDecoded[arg2]
	local finetune 
= mod_samples__info[arg2*6+3]
	pitch = (8363*428)/arg1
	--pitch = pitch / 8363
	pitch = pitch*(2^-(finetune/96))
	sampleRate = arg3
	length_sample = (length_sample > 0) and length_sample or 1
	local soundData = love.sound.newSoundData(length_sample, sampleRate, 8, 2)
	sourceSound = love.audio.newQueueableSource(sampleRate, 8, 2, 8)
	sourceSound:setPitch(pitch/sampleRate)
	for i = 1, length_sample-1, 1 do
		i = i
    		local val = samples[i]/256 --Left
    		soundData:setSample(i-1, 1, val)
		local val = samples[i]/256 --Right
		soundData:setSample(i-1, 2, val)
	end
	success = sourceSound:queue(soundData, soundData:getSize())
	sourceSound:play()
	channels[channel] = sourceSound
	--source = love.audio.newSource(soundData)
	--source:play()
end

function editor.REALTIME_PLAY_SAMPLE(arg1, arg2, arg3, channel)
	if channels[channel] ~= nil then
		channels[channel]:stop()
		channels[channel] = nil
	end
	local samples = mod_sampleDecoded[arg2]
	local length_sample = #mod_sampleDecoded[arg2]
	local finetune = mod_samples__info[arg2*6+3]
	pitch = (8363*localNoteOffset)/arg1
	pitch = pitch / 8363
	pitch = pitch*(2^-(finetune/96))
	sampleRate = arg3
	length_sample = (length_sample > 0) and length_sample or 1
	local soundData = love.sound.newSoundData(length_sample, sampleRate, 8, 2)
	sourceSound = love.audio.newQueueableSource(sampleRate, 8, 2, 8)
	sourceSound:setPitch(pitch)
	for i = 1, length_sample-1, 1 do
		i = i
    		local val = samples[i]/256 --Volume %
    		soundData:setSample(i-1, 1, val)
		local val = samples[i]/256 --Volume %
		soundData:setSample(i-1, 2, val)
	end
	success = sourceSound:queue(soundData, soundData:getSize())
	sourceSound:play()
	channels[channel] = sourceSound
	--source = love.audio.newSource(soundData)
	--source:play()
end

function editor.drawPattern(q)
	local gridSizeX = 100
	local gridSizeY = 20
	local gridPositionX = 20
	local gridPositionY = 180
	local gridX = gridSizeX*numChannels 
	local gridY = 400
	for gx = 0, gridX, gridSizeX do
		love.graphics.line(gx+gridPositionX, gridPositionY, gx+gridPositionX, gridY+gridPositionY)
	end
	for gy = 0, gridY, gridSizeY do
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
				love.graphics.print((instrument ~= 0) and string.format("%02X", instrument) or "--", 55+x*gridSizeX, 180+y*gridSizeY)
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
				love.graphics.print((effect ~= 0) and string.format("%X", effect) or "-", 80+x*gridSizeX, 180+y*gridSizeY)
				love.graphics.print((effect ~= 0) and string.format("%02X", param) or "--", 90+x*gridSizeX, 180+y*gridSizeY)
			end
		end
	end
end

function editor.init()
	patternPosition = 1
	ticksPerLine = 6
	bpm = 125
	channels = {}
	lastNote = {}
end

function editor.keyMap(key, sampleNum)
	for i = 0, 32 do
		if key == keyMap[i] then
			editor.REALTIME_PLAY_SAMPLE(keyMap[key], sampleNum, 44010, 1)
		end
	end
end
return editor
