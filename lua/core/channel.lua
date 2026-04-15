channel = {}

function channel.init(range, channels)
	for i=1, range do
		channels[i] = {0, 1, 64, 1}
	end
end

return channel