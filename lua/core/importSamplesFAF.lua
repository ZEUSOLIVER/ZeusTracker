importSamplesFAF = {}
local ffi = require("ffi")

local function sampleDecode(data)
    local out = {}
    for i = 1, #data do
        local v = data[i]
        if v >= 128 then v = v - 256 end
        out[i] = v
    end
    return out
end

function importSamplesFAF.load(filePath)
	local file = assert(io.open(filePath, "rb"))
	local data = file:read("*all")
	file:close()

	for i=1, 31 do
		local offset = 20+(30*(i-1))
		samples__info[i][1] = {data:sub(offset+1, offset+22)}
		local cal1 = {data:byte(offset+23, offset+24)}
		samples__info[i][2] = cal1[1]*256+cal1[2]
		local cal4 = bit.band(data:byte(offset+25, offset+25), 0x0F)
		if cal4 > 7 then cal4 = cal4 - 16 end
		local mult = 2^(-cal4/96.0)
		samples__info[i][3] = mult
		samples__info[i][4] = data:byte(offset+26, offset+26)/64
		local cal2 = {data:byte(offset+27, offset+28)}
		samples__info[i][5] = cal2[1]*256+cal2[2]
		local cal3 = {data:byte(offset+29, offset+30)}
		samples__info[i][6] = cal3[1]*256+cal3[2]
	end

	local song__position_L = {data:byte(953, 1080)}
	local songLength_L = data:byte(951)
	local underfined2_L = data:sub(1081, 1084)

	local signature_value_L = 0
	if underfined2_L == "M.K." or underfined2_L == "4CHN" or underfined2_L == "FLT4" then
		signature_value_L = 1024
	elseif underfined2_L == "6CHN" then
		signature_value_L = 1536
	elseif underfined2_L == "8CHN" or underfined2_L == "FLT8" or underfined2_L == "CD81"then
		signature_value_L = 2048
	elseif underfined2_L == "14CH" then
		signature_value_L = 3584
	elseif underfined2_L == "16CH" then
		signature_value_L = 4096
	elseif underfined2_L == "32CH" then
		signature_value_L = 8192
	end
	
	local maxPat = 0
	for i=1, songLength_L do
		local p = song__position_L[i] or 0
		if p > maxPat then maxPat = p end
	end
	local numPatterns = maxPat+1
	local pattern_length = 1086+numPatterns*signature_value_L

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
		sampleDecoded[i] = sampleDecode(sample_data[i])
		offset = offset+sample_length
	end
end

return importSamplesFAF