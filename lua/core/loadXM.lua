local xm = {}



function xm.load(path)
	local file = assert(io.open(path, "rb"))
	local data = file:read("*all")
	file:close()

	--xm_id = data:sub(1, 17)
	title = data:sub(17+1, 37)
	print(title)
	--xm_id01 = data:byte(37+1, 38)
	--xm_tracker_name = data:sub(38+1, 58)
	--xm_version_number = {data:byte(58+1, 60)}
	--xm_header_size = {data:byte(60+1, 64)}
	song__length = {data:byte(64+1, 66)}
	--xm_restart_position = {data:byte(66+1, 68)}
	local cal1 = {data:byte(68+1, 70)}
	numChannels = cal1[1]+cal1[2]*256
	print(numChannels)
	xm_number_of_patterns = {data:byte(70+1, 72)}
	xm_number_of_instruments = {data:byte(72+1, 74)}
	xm_flags = {data:byte(74+1, 76)}
	local cal2 = {data:byte(76+1, 78)}
	ticketsPerLine = cal2[1]+cal2[2]*256
	print(ticketsPerLine)
	local cal3 = {data:byte(78+1, 80)}
	bpm = cal3[1]+cal3[2]*256
	print(bpm)
	local offset = 336
	song__length = {data:byte(80+1, offset)}
	xm_pattern_header_length = {data:byte(offset+1, offset+4)}
	xm_packing_type = {data:byte(offset+4+1, offset+5)}
	local cal4 = {data:byte(offset+5+1, offset+7)}
	rowsInPattern = cal4[1]+cal4[2]*256
	print(rowsInPattern)
	local cal5 = {data:byte(offset+7+1, offset+9)}
	xm_packed_pattern_data_size = cal5[1]+cal5[2]*256
	local offset2 = offset + 9 + xm_packed_pattern_data_size
	xm_packed_pattern_data = {data:byte(offset+9, offset2)}
	local cal6 = {data:byte(offset2+1, offset2+4)}
	xm_instrument_size = cal6[1]+cal6[2]*256+cal6[3]*65536+cal6[4]*16777216
	xm_instrument_name = data:sub(offset2+4+1, offset2+26)
	xm_instrument_type = {data:byte(offset2+26+1, offset2+27)}
	local cal7 = {data:byte(offset2+27+1, offset2+29)}
	xm_number_of_samples = cal7[1]+cal7[2]*256
	if xm_number_of_samples > 0 then
		xm_sample_header_size = {data:byte(offset2+29+1, offset2+33)}
		xm_sample_keymap_assignments = {data:byte(offset2+33+1, offset2+129)}
		xm_points_for_volume_envelope = {data:byte(offset2+129+1, offset2+177)}
		xm_points_for_panning_envelope = {data:byte(offset2+177+1, offset+225)}
		xm_envelope_points = {data:byte(offset2+225+1, offset2+263)}
	end
	local offset3 = offset2+xm_instrument_size
	xm_sample_length = {data:byte(offset3+1, offset3+4)}
	xm_sample_loop_start = {data:byte(offset3+4+1, offset3+8)}
	xm_sample_loop_length = {data:byte(offset3+8+1, offset3+12)}
	xm_sample_loop_table = {data:byte(offset3+12+1, offset3+18)}
	xm_sample_name = data:sub(offset3+18+1, offset3+40)



	sample_header_size = xm_sample_header_size[1]+xm_sample_header_size[2]*256+xm_sample_header_size[3]*65536+xm_sample_header_size[4]*16777216



	sample_length = xm_sample_length[1]+xm_sample_length[2]*256+xm_sample_length[3]*65536+xm_sample_length[4]*16777216



	local offset4 = offset3+40+sample_length
	local chunkSize = 4024
	for pos = offset3+41, offset4, chunkSize do
		local chunkEnd = math.min(pos+chunkSize-1, offset4)
		local bytes = {data:byte(pos, chunkEnd)}
		for i=1, #bytes do
			xm_sample_data[#xm_sample_data+1] = bytes[i]
		end
	end
end

return xm