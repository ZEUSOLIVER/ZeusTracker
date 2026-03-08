effects = {}

function effects.nextPattern()
	patternPosition = 64*currentPattern
end

function effects.toneNoteUp(param, channel)
	local pitch = channels[channel]:getPitch()
	print(pitch)
	local lastPitch = lastNote[channel]:getPitch()
	print(lastPitch)
	channels[channel]:setPitch(pitch+(lastPitch*(param/100)))
	print("NoteUP: " .. param, pitch+(lastPitch*(param/100)))
end

function effects.ticksAndBpm(param)
	if param < 0x20 then
		ticksPerLine = param
	elseif param > 0x20 then
		bpm = param
	end
end

function effects.volume(vol, channel)
	channels[channel]:setVolume(vol/40)
end

function effects.volumeSlide(x, y, channel)
	local volume = channels[channel]:getVolume()
	if x > 0 then
		channels[channel]:setVolume(volume+(x/40))
	elseif y > 0 then
		channels[channel]:setVolume(volume-(y/40))
	end
end

function effects.applyPosEffects(effect, param, channel)
	if effect == 0x0 then
		--effects.volume(param)
	end
	if effect == 0x3 then
		effects.toneNoteUp(param, channel)
	end
	if effect == 0xC then
		effects.volume(param, channel)
	end
	if effect == 0xA then
		effects.volumeSlide(bit.band(param, 0xF0), bit.band(param, 0x0F), channel)
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