channel = {}
local barLines = {}
local dPosCh = {}
local ffi = require("ffi")

function channel.init(range, channels)
	channel_instrument = ffi.new("uint8_t[?]", range)
	channel_period = ffi.new("uint32_t[?]", range)
	channel_volume = ffi.new("float[?]", range)
	channel_position = ffi.new("float[?]", range)
	channel_srepeat = ffi.new("uint32_t[?]", range)
	channel_sreplen = ffi.new("uint32_t[?]", range)
	channel_oneShoot = ffi.new("bool[?]", range)
	channel_volumeLeft = ffi.new("float[?]", range)
	channel_volumeRight = ffi.new("float[?]", range)
	channel_muted = ffi.new("bool[?]", range)
	channel_effects_portamentoTargetPitch = ffi.new("uint32_t[?]", range)
	channel_effects_portamentoSpeed = ffi.new("uint8_t[?]", range)
	channel_effects_samplePosition = ffi.new("int[?]", range)
	channel_effects_vibratorPosition = ffi.new("float[?]", range)
	channel_effects_vibratorSpeed = ffi.new("uint8_t[?]", range)
	channel_effects_vibratorDepth = ffi.new("uint8_t[?]", range)
	channel_effects_vibratorValue = ffi.new("float[?]", range)
	for ch = 0, range-1 do
		if ch%4 == 0 then
			channel_volumeLeft[ch] = 1
			channel_volumeRight[ch] = 0.75
		elseif ch%4 == 3 then
			channel_volumeRight[ch] = 1
			channel_volumeLeft[ch] = 0.75
		else
			channel_volumeLeft[ch] = 1
			channel_volumeRight[ch] = 1
		end
	end
end

function channel.specView(ch, x, y, t, offsetCh)
	if t%2 == 0 then
		love.graphics.setCanvas(canvasChannelSpec)
		if ch == offsetCh then
			love.graphics.clear(0, 0, 0, 0)
		end
		love.graphics.setColor(0, 0.4, 0.4)
		if not channel_muted[ch] then
			love.graphics.setColor(0, 1, 1)
		end
		local pos = math.floor(channel_position[ch])
		local volume = channel_volume[ch] or 0
		volume = volume*0.25
		local sample = sampleDecoded[channel_instrument[ch]] or {}
		--local value = sample[pos] or 0
		local offsetY = volume*(sample[pos] or 0)
		local length = (#sample < 40 and #sample > 0) and #sample or 40
		local offset = 100/length
		local buffer = {}
		for i = 1, length do
			buffer[i] = 0
		end
		local lines = {}
		local xp = 0
		local offsetA = y
		for i = 0, length do
			--[[lines[i*2+1] = x+i*offset
			lines[i*2+2] = y+volume*-(sample[pos+i+1] or 0)]]
			local xx = x+(i+1)*offset
			local yy = y+volume*-(sample[pos+i+1] or 0)
			love.graphics.line(x+i*offset, offsetA, xx-2, yy)
			--love.graphics.rectangle("fill", xx, yy, 1, 1)
			offsetA = y+volume*-(sample[pos+i+1] or 0)
			xp = xp+1
		end
		--love.graphics.line(lines)
		love.graphics.setColor(1, 1, 1)
		love.graphics.print(ch, x+(ch-1), y-40)
		--local lastfreq = volume*(sample[pos-1] or 0)
		local barYPos = barLines[ch] or 0
		local dPos = dPosCh[ch] or 0
		love.graphics.setColor(0, barYPos*0.1, 0)
		local offsetYMath = math.abs(dPos-offsetY)
		if offsetYMath >= barYPos then
			barYPos = offsetYMath
		else
			barYPos = math.max(barYPos-4, 0)
		end
		dPosCh[ch] = offsetY
		--print(dPos, offsetY)
		love.graphics.rectangle("fill", x, y+20, 4, -barYPos)
		barLines[ch] = barYPos
		love.graphics.setColor(1, 1, 1)
		love.graphics.setCanvas()
	end
end

return channel