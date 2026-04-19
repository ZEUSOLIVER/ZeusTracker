effects = {}

function effects.nextPattern()
	patternPosition = 64*currentPattern
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

function effects.tonePort(param, channel)
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
	--volume = math.max(0.0, math.min(1.0, volume))
	channels[channel][3] = volume
end

function effects.applyPosEffects(effect, param, channel)
	if effect == 0x0 and param > 0 then
		--effects.volume(param)
	end
	if effect == 0x1 then
		effects.portUp(param, channel)
	end
	if effect == 0x2 then
		effects.portDown(param, channel)
	end
	if effect == 0x3 then
		effects.tonePort(param, channel)
	end
	if effect == 0xA then
		effects.volumeSlide(bit.rshift(bit.band(param, 0xF0), 4), bit.band(param, 0x0F), channel)
	end
end

function effects.applyPreEffects(effect, param, channel)
	if effect == 0xD then
		effects.nextPattern()
	end
	if effect == 0xC then
		effects.volume(param, channel)
	end
	if effect == 0xF then
		effects.ticksAndBpm(param)
	end
end

return effects