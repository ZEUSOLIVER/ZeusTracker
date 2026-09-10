local wav = {}

local ffi = require("ffi")

local wave_length
local sampleBit

ffi.cdef[[
    typedef struct {
        char id[4];
        uint32_t size;
    } ChunkHeader;

    typedef struct {
        uint16_t audioFormat;
        uint16_t numChannels;
        uint32_t sampleRate;
        uint32_t byteRate;
        uint16_t blockAlign;
        uint16_t bitsPerSample;
    } FmtChunk;
]]

function wav.getLength()
	return wave_length
end

function wav.getBitsPerSample()
	return sampleBit
end

function wav.openWav(path)
	local file = io.open(path, "rb")
	if not file then print("error: invalid file!") return end

	local headerBytes = file:read(12)
	
	local header
	local dataSize
	
	while true do
		local chunkHeadBytes = file:read(8)
		
		local chunkHead = ffi.cast("ChunkHeader*", chunkHeadBytes)
		local id = ffi.string(chunkHead.id, 4)
		local size = chunkHead.size
		if id == "fmt " then
			local fmtBytes = file:read(size)
			header = ffi.cast("FmtChunk*", fmtBytes)
		elseif id == "data" then
			dataSize = size
			break
		else
			file:seek("cur", size)
		end
	end
	
	local rawData = file:read(dataSize)
	file:close()

	print("--- SAMPLE INFO ---")
	print("Channels: " .. header.numChannels)
	print("Frequency: " .. header.sampleRate .. " Hz")
	print("Resolution: " .. header.bitsPerSample .. " bits")
	print("Size: " .. dataSize .. " bytes")
	
	local sampleBuffer = ffi.new("uint" .. header.bitsPerSample .. "_t[?]", dataSize)
	
	-- Transforma a string em um ponteiro de bytes sem sinal (0 a 255)
    	local bytes = ffi.cast("const uint" .. header.bitsPerSample .. "_t*", rawData)
    
    	ffi.copy(sampleBuffer, bytes, dataSize)
    	
    	wave_length = dataSize
    	sampleBit = header.bitsPerSample
    	
    	rawData = {}
	
	return sampleBuffer
end

return wav