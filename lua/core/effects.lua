effects = {}

function effects.nextPattern()
	patternPosition = 64*currentPattern
end

function effects.tonePortUp(param, channel)
	local pitch = channels[channel]:getPitch()
	channels[channel]:setPitch(pitch+(param / 128))
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
	local v = math.max(0, math.min(vol / 64, 1))
	channels[channel]:setVolume(v)
end

function effects.volumeSlide(x, y, channel)
	local volume = channels[channel]:getVolume()
	if x > 0 and down == 0 then
		volume = volume + x / 64
	elseif down > 0 and up == 0 then
		volume = volume - y / 64
	elseif up > 0 and down > 0 then
		volume = volume + x / 64
	end
end

function effects.applyPosEffects(effect, param, channel)
	if effect == 0x0 and param > 0 then
		--effects.volume(param)
	end
	if effect == 0x3 then
		--effects.tonePortUp(param, channel)
	end
	if effect == 0xC then
		effects.volume(param, channel)
	end
	if effect == 0xA then
		--effects.volumeSlide(bit.shift(bit.band(param, 0xF0), 4), bit.band(param, 0x0F), channel)
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