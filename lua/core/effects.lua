effects = {}
local ffi = require("ffi")
--local editor = require("lua/core/editor")

local sineTable = ffi.new("uint8_t[32]", {
    0,  24,  49,  74,  97, 120, 141, 161, 
  180, 197, 212, 224, 235, 244, 250, 253, 
  255, 253, 250, 244, 235, 224, 212, 197, 
  180, 161, 141, 120,  97,  74,  49,  24
})

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

function effects.vibratoSet(x, y, ch)
	if x > 0 or y > 0 then
		channel_effects_vibratorSpeed[ch] = x
		channel_effects_vibratorDepth[ch] = y
	end
end

function effects.vibratoProcess(ch)
	local speed = channel_effects_vibratorSpeed[ch]
	local depth = channel_effects_vibratorDepth[ch]
	local period = channel_period[ch]
	local vibratoPos = channel_effects_vibratorPosition[ch]
	local tableIndex = vibratoPos%32
	local sineValue = sineTable[tableIndex+1]
	if vibratoPos >= 32 then
		sineValue = -sineValue
	end
	local vibratoValue = (sineValue*depth)/128
	channel_effects_vibratorValue[ch] = vibratoValue
	channel_effects_vibratorPosition[ch] = (vibratoPos+speed)%64
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

function effects.portUp(param, ch)
	local pitch = channel_period[ch]
	pitch = pitch - param
	pitch = math.max(113, pitch)
	channel_period[ch] = pitch
end

function effects.portDown(param, ch)
	local pitch = channel_period[ch]
	pitch = pitch + param
	pitch = math.min(856, pitch)
	channel_period[ch] = pitch
end

function effects.tonePort(ch)
	local currentPitch = channel_period[ch]
	local targetPitch = channel_effects_portamentoTargetPitch[ch]
	local speed = channel_effects_portamentoSpeed[ch] or 0
	
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

	channel_period[ch] = currentPitch
end

function effects.samplePosition(param, ch)
	if param > 0 then	
		channel_effects_samplePosition[ch] = param
	end
	local positionEffect = channel_effects_samplePosition[ch] or 0
	channel_position[ch] = positionEffect*256
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

function effects.volume(vol, ch)
	channel_volume[ch] = vol/64 or 0
end

function effects.volumeSlide(x, y, ch)
	local volume = channel_volume[ch]
	if x > 0 then
		volume = volume + x / 64
	elseif y > 0 then
		volume = volume - y / 64
	end
	channel_volume[ch] = math.max(0.0, math.min(1.0, volume))
end

function effects.fineVolumeSlideUp(param, ch)
	if param > 0 then
		local volumeCh = channel_volume[ch]
		volumeCh = volumeCh + param/64
		channel_volume[ch] = math.max(0, math.min(1.0, volumeCh))
	end
end

function effects.fineVolumeSlideDown(param, ch)
	if param > 0 then
		local volumeCh = channel_volume[ch]
		volumeCh = volumeCh - param/64
		channel_volume[ch] = math.max(0, math.min(1.0, volumeCh))
	end
end

function effects.applyPosEffects(effect, param, ch)
	--[[if effect == 0x0 and param > 0 then
		--effects.volume(param)
	end]]
	if effect == 0x1 then
		effects.portUp(param, ch)
	end
	if effect == 0x2 then
		effects.portDown(param, ch)
	end
	if effect == 0x3 then
		effects.tonePort(ch)
	end
	if effect == 0x4 then
		effects.vibratoProcess(ch)
	end
	if effect == 0xA then
		effects.volumeSlide(bit.rshift(bit.band(param, 0xF0), 4), bit.band(param, 0x0F), ch)
	end
	if effect == 0x5 then
		effects.tonePort(ch)
		effects.volumeSlide(bit.rshift(bit.band(param, 0xF0), 4), bit.band(param, 0x0F), ch)
	end
	if effect == 0x6 then
		effects.vibratoProcess(ch)
		effects.volumeSlide(bit.rshift(bit.band(param, 0xF0), 4), bit.band(param, 0x0F), ch)
	end
end

function effects.applyPreEffects(effect, param, ch)
	if effect == 0xF then
		effects.ticksAndBpm(param)
	end
	if effect == 0xC then
		effects.volume(param, ch)
	end
	if effect == 0x4 then
		effects.vibratoSet(bit.rshift(bit.band(param, 0xF0), 4), bit.band(param, 0x0F), ch)
	else
		if channel_effects_vibratorValue[ch] ~= 0 and effect ~= 0x6 then
			channel_effects_vibratorPosition[ch] = 0
			channel_effects_vibratorSpeed[ch] = 0
			channel_effects_vibratorDepth[ch] = 0
			channel_effects_vibratorValue[ch] = 0
		end
	end
	--[[if channel == 1 then
		print(channel_effects_vibratorValue[ch])
	end]]
	if effect == 0x9 then
		effects.samplePosition(param, ch)
	end
	if effect == 0xE then
		if bit.band(param, 0xF0) == 0xA0 then
			effects.fineVolumeSlideUp(bit.band(param, 0x0F), ch)
		end
		if bit.band(param, 0xF0) == 0xB0 then
			effects.fineVolumeSlideDown(bit.band(param, 0x0F), ch)
		end
	end
end

return effects