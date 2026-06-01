effects = {}
--local editor = require("lua/core/editor")

local sineTable = {
    0,  24,  49,  74,  97, 120, 141, 161, 
  180, 197, 212, 224, 235, 244, 250, 253, 
  255, 253, 250, 244, 235, 224, 212, 197, 
  180, 161, 141, 120,  97,  74,  49,  24
}

function effects.defineCurrentPattern(pat)
	currentPattern = pat+1
	if song__position[currentPattern] == nil then
		currentPattern = 1
	end
	patternPosition = rowsInPattern*song__position[currentPattern]
	counterY = 0
	currentPosition = 0
	tickets = -1
end

function effects.vibratoSet(x, y, channel)
	if x > 0 or y > 0 then
		channels[channel][13] = x
		channels[channel][14] = y
	end
end

function effects.vibratoProcess(channel)
	local speed = channels[channel][13]
	local depth = channels[channel][14]
	local period = channels[channel][2]
	local vibratoPos = channels[channel][12]
	local tableIndex = vibratoPos%32
	local sineValue = sineTable[tableIndex+1]
	if vibratoPos >= 32 then
		sineValue = -sineValue
	end
	local vibratoValue = (sineValue*depth)/128
	channels[channel][15] = vibratoValue
	channels[channel][12] = (vibratoPos+speed)%64
	--print("Channel: " .. channel+1 .. " speed: " .. speed .. " depth: " .. depth .. " VibratoValue: " .. vibratoValue .. " VibratoPos: " .. channels[channel][12])
end

function effects.nextPattern(param)
	currentPattern = currentPattern+1
	if song__position[currentPattern] == nil or currentPattern > songLength then
		currentPattern = 1
	end
	patternPosition = (rowsInPattern-currentPosition)*song__position[currentPattern]+param
	counterY = param
	currentPosition = param
	tickets = -1
end

function effects.portUp(param, channel)
	local pitch = channels[channel][2]
	pitch = pitch - param
	pitch = math.max(113, pitch)
	channels[channel][2] = pitch
end

function effects.portDown(param, channel)
	local pitch = channels[channel][2]
	pitch = pitch + param
	pitch = math.min(856, pitch)
	channels[channel][2] = pitch
end

function effects.tonePort(channel)
	local currentPitch = channels[channel][2]
	local targetPitch = channels[channel][5]
	local speed = channels[channel][6] or 0
	
	if not targetPitch or currentPitch == targetPitch then
		return
	end

	if currentPitch > targetPitch then
		currentPitch = currentPitch - speed
		if currentPitch < targetPitch then
			currentPitch = targetPitch
		end
	elseif currentPitch < targetPitch then
		currentPitch = currentPitch + speed
		if currentPitch > targetPitch then
			currentPitch = targetPitch
		end
	end

	channels[channel][2] = currentPitch
end

function effects.samplePosition(param, channel)
	if param > 0 then	
		channels[channel][7] = param
	end
	local positionEffect = channels[channel][7] or 0
	channels[channel][4] = positionEffect*256
end

function effects.ticksAndBpm(param)
	if param == 0 then
		ticksPerLine = 1
	elseif param < 0x20 then
		ticksPerLine = param
	else
		bpm = param
	end
end

function effects.volume(vol, channel)
	channels[channel][3] = vol/64
end

function effects.volumeSlide(x, y, channel)
	local volume = channels[channel][3]
	if x > 0 then
		volume = volume + x / 64
	elseif y > 0 then
		volume = volume - y / 64
	end
	volume = math.max(0.0, math.min(1.0, volume))
	channels[channel][3] = volume
end

function effects.applyPosEffects(effect, param, channel)
	--[[if effect == 0x0 and param > 0 then
		--effects.volume(param)
	end]]
	if effect == 0x1 then
		effects.portUp(param, channel)
	end
	if effect == 0x2 then
		effects.portDown(param, channel)
	end
	if effect == 0x3 then
		effects.tonePort(channel)
	end
	if effect == 0x4 then
		effects.vibratoProcess(channel)
	end
	if effect == 0xA then
		effects.volumeSlide(bit.rshift(bit.band(param, 0xF0), 4), bit.band(param, 0x0F), channel)
	end
	if effect == 0x5 then
		effects.tonePort(channel)
		effects.volumeSlide(bit.rshift(bit.band(param, 0xF0), 4), bit.band(param, 0x0F), channel)
	end
	if effect == 0x6 then
		effects.vibratoProcess(channel)
		effects.volumeSlide(bit.rshift(bit.band(param, 0xF0), 4), bit.band(param, 0x0F), channel)
	end
end

function effects.applyPreEffects(effect, param, channel)
	if effect == 0xF then
		effects.ticksAndBpm(param)
	end
	if effect == 0xC then
		effects.volume(param, channel)
	end
	if effect == 0x4 then
		effects.vibratoSet(bit.rshift(bit.band(param, 0xF0), 4), bit.band(param, 0x0F), channel)
	else
		if channels[channel][15] ~= 0 and effect ~= 0x6 then
			channels[channel][12] = 0
			channels[channel][13] = 0
			channels[channel][14] = 0
			channels[channel][15] = 0
		end
	end
	--[[if channel == 1 then
		print(channels[channel][15])
	end]]
	if effect == 0x9 then
		effects.samplePosition(param, channel)
	end
end

return effects