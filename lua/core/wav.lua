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
	local sample = love.sound.newSoundData(path)
	wave_length = sample:getSize()
	sampleBit = 16
	return sample
end

return wav