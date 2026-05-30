channel = {}

function channel.init(range, channels)
	for i=1, range do
		channels[i] = {0, 1, 64, 1, false, 0, 0, 0, 0, true, false, 0, 0, 0, 0}
	end
end

function channel.specView(ch, x, y)
	love.graphics.setColor(0, 0.4, 0.4)
	if channels[ch][10] then
		love.graphics.setColor(0, 1, 1)
	end
	local currentChannel = channels[ch]
	local pos = math.floor(currentChannel[4])
	local volume = currentChannel[3] or 0
	volume = volume*0.25
	local sample = sampleDecoded[currentChannel[1]] or {}
	--local value = sample[pos] or 0
	local offsetY = volume*(sample[pos] or 0)
	local length = (#sample < 40 and #sample > 0) and #sample or 40
	local offset = 100/length
	local buffer = {}
	for i = 1, length do
		buffer[i] = 0
	end
	local lines = {}
	for i = length, 0, -1 do
		lines[i*2+1] = x+(i-1)*offset+2
		lines[i*2+2] = y+volume*(sample[pos+i] or 0)
	end
	love.graphics.line(lines)
	love.graphics.setColor(1, 1, 1)
	love.graphics.print(ch, x+(ch-1), y-40)
end

return channel