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

function editor.noteOffset(offset)
	noteOffset = offset
end

function editor.localNoteOffset(offset)
	localNoteOffset = offset
end

function editor.PLAY_NEW_SAMPLE(arg1, arg2, arg3, channel)
	if channels[channel] ~= nil then
		channels[channel]:stop()
		channels[channel]:setVolume(1)
		channels[channel] = nil
	end
	lastNote[channel] = channels[channel]
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
	local gridPositionX = 20
	local gridPositionY = 20
	local gridX = 400
	local gridY = 400
	for gx = 0, gridX, 100 do
		love.graphics.line(gx+gridPositionX, gridPositionY, gx+gridPositionX, gridX+gridPositionY)
	end
	for gy = 0, gridY, 20 do
		love.graphics.line(gridPositionX, gy+gridPositionY, gridY+gridPositionX, gy+gridPositionY)
	end
	for y = 1, q do
		for x = 0, numChannels-1 do
			love.graphics.print(mod_data_pattern[x*numChannels+(y-1)*(numChannels*numChannels)+2], x*50, (y-1)*10)
		end
	end
end

function editor.keyMap(key, sampleNum)
	for i = 0, 32 do
		if key == keyMap[i] then
			editor.REALTIME_PLAY_SAMPLE(keyMap[key], sampleNum, 44010, 1)
		end
	end
end
return editor
