local mod = {}

ticksPerLine_enabled = false
bpm_enabled = false

local signature_value = 0

function mod.load(path)
	--///////////////////LOAD MOD////////////////////
	local file = assert(io.open(path, "rb"))
	local data = file:read("*all")
	file:close()

	local dataSize = #data

	title = data:sub(0+1, 20)
	for i=1, 31 do
		local offset = 20+(30*(i-1))
		samples__info[i][1] = {data:sub(offset+1, offset+22)}
		local cal1 = {data:byte(offset+23, offset+24)}
		samples__info[i][2] = cal1[1]*256+cal1[2]
		samples__info[i][3] = data:byte(offset+25, offset+25)
		samples__info[i][4] = data:byte(offset+26, offset+26)
		local cal2 = {data:byte(offset+27, offset+28)}
		samples__info[i][5] = cal2[1]*256+cal2[2]
		local cal3 = {data:byte(offset+29, offset+30)}
		samples__info[i][6] = cal3[1]*256+cal3[2]
	end
	local songLength = data:byte(951)
	--print(songLength)
	song__length[1] = songLength
	underfined[1] = data:byte(952)
	song__position = {data:byte(953, 1080)}
	underfined2 = data:sub(1081, 1084) --
	if underfined2 == "M.K." or underfined2 == "4CHN" or underfined2 == "FLT4" then
		signature_value = 1024
		numChannels = 4
	elseif underfined2 == "6CHN" then
		signature_value = 1536
		numChannels = 6
	elseif underfined2 == "8CHN" or underfined2 == "FLT8" or underfined2 == "CD81"then
		signature_value = 2048
		numChannels = 8
	elseif underfined2 == "16CH" then
		signature_value = 4096
		numChannels = 16
	elseif underfined2 == "32CH" then
		signature_value = 8192
		numChannels = 32
	end
	print(underfined2)
	local maxPat = 0
	for i=1, songLength do
		local p = song__position[i] or 0
		if p > maxPat then maxPat = p end
	end
	local numPatterns = maxPat+1
	local pattern_length = 1086+numPatterns*signature_value
	local out = {}
	local k = 1
	local chunkSize = 4024
	for pos = 1085, 1086+pattern_length, chunkSize do
		local chunkEnd = math.min(pos+chunkSize-1, 1086+pattern_length)
		local bytes = {data:byte(pos, chunkEnd)}
		for j=1, #bytes do
			out[k] = bytes[j]
			k=k+1
		end
	end
	data_pattern = out
	local offset = pattern_length
	for i=1, 31 do
		local sample_length = samples__info[i][2]*2
		local out = {}
		local k = 1
		local chunkSize = 4024
		for pos = offset+1, offset+sample_length, chunkSize do
			local chunkEnd = math.min(pos+chunkSize-1, offset+sample_length)
			local bytes = {data:byte(pos, chunkEnd)}
			for j=1, #bytes do
				out[k] = bytes[j]
				k=k+1
			end
		end
		sample_data[i] = out
		offset = offset+sample_length
	end
end

return mod