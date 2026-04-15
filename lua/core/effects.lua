effects = {}

function effects.nextPattern()
	patternPosition = 64*currentPattern
end

function effects.tonePortUp(param, channel)
	local pitch = channels[channel][2]
	pitch = pitch - param*0.1
	pitch = math.max(113, pitch)
	channels[channel][2] = pitch
end

function effects.tonePortDown(param, channel)
	local pitch = channels[channel][2]
	pitch = pitch + param*0.1
	pitch = math.min(856, pitch)
	channels[channel][2] = pitch
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
	channels[channel][3] = vol
end

function effects.volumeSlide(x, y, channel)
	local volume = channels[channel][3]
	if x > 0 then
		volume = volume + x / 64
	elseif y > 0 then
		volume = volume - y / 64
	end
	--volume = math.max(0.0, math.min(1.0, volume))
	channels[channel][3] = volume
end

function effects.applyPosEffects(effect, param, channel)
	if effect == 0x0 and param > 0 then
		--effects.volume(param)
	end
	if effect == 0x3 then
		effects.tonePortUp(param, channel)
	end
	if effect == 0x2 then
		effects.tonePortDown(param, channel)
	end
	if effect == 0xC then
		effects.volume(param, channel)
	end
	if effect == 0xA then
		effects.volumeSlide(bit.rshift(bit.band(param, 0xF0), 4), bit.band(param, 0x0F), channel)
	end
end

function effects.applyPreEffects(effect, param)
	if effect == 0xD then
		effects.nextPattern()
	end
	if effect == 0xF then
		effects.ticksAndBpm(param)
	end
end

return effects