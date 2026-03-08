core = {}
local noteOffset = 0
local localNoteOffset = 0
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

function core.noteOffset(offset)
	noteOffset = offset
end

function core.localNoteOffset(offset)
	localNoteOffset = offset
end


function core.PLAY_NEW_SAMPLE(arg1, arg2, arg3, arg4, right, left)
	pitch = noteOffset/arg1
	sampleRate = arg4
	arg3 = (arg3 > 0) and arg3 or 1
	local soundData = love.sound.newSoundData(arg3, sampleRate*pitch, 8, 2)
	sourceSound = love.audio.newQueueableSource(sampleRate*pitch, 8, 2, 8)
	for i = 1, arg3-1, 1 do
		i = i
    		local val = arg2[i]/(128/right) --Volume %
    		soundData:setSample(i-1, 1, val)
		local val = arg2[i]/(128/left) --Volume %
		soundData:setSample(i-1, 2, val)
	end
	success = sourceSound:queue(soundData, soundData:getSize())
	sourceSound:play()
	--source = love.audio.newSource(soundData)
	--source:play()
end

function core.REALTIME_PLAY_SAMPLE(arg1, arg2, arg3, arg4, right, left)
	pitch = localNoteOffset/arg1
	sampleRate = arg4
	arg3 = (arg3 > 0) and arg3 or 1
	local soundData = love.sound.newSoundData(arg3, sampleRate*pitch, 8, 2)
	sourceSound = love.audio.newQueueableSource(sampleRate*pitch, 8, 2, 8)
	for i = 1, arg3-1, 1000 do
		i = i
    		local val = arg2[i]/(128/right) --Volume %
    		soundData:setSample(i-1, 1, val)
		local val = arg2[i]/(128/left) --Volume %
		soundData:setSample(i-1, 2, val)
	end
	success = sourceSound:queue(soundData, soundData:getSize())
	sourceSound:play()
	--source = love.audio.newSource(soundData)
	--source:play()
end

function core.keyMap(key, sampleNum)
	for i = 0, 32 do
		if key == keyMap[i] then
			core.REALTIME_PLAY_SAMPLE(keyMap[key], mod_sampleDecoded[sampleNum], #mod_sampleDecoded[sampleNum], 44010, 0.80, 0.80)
		end
	end
end
return core
