channel = {}

function channel.init(range, channels)
	for i=1, range do
		channels[i] = {0, 1, 64, 1}
	end
end

function channel.specView(ch, x, y)
	love.graphics.setColor(0, 1, 1)
	local currentChannel = channels[ch]
	local pos = math.floor(currentChannel[4])
	local volume = currentChannel[3] or 0
	volume = volume*0.25
	local sample = mod_sampleDecoded[currentChannel[1]] or {}
	--local value = sample[pos] or 0
	local offsetY = volume*(sample[pos] or 0)
	local length = 40
	local offset = 100/length
	for i = length, 0, -1 do
		love.graphics.line(x+i*offset, y+offsetY, x+(i-1)*offset, y+volume*(sample[pos+i] or 0))
		offsetY = volume*(sample[pos+i] or 0)
	end
	love.graphics.setColor(1, 1, 1)
end

return channel