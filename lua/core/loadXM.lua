local xm = {}



function xm.load(path)
	local file = assert(io.open(path, "rb"))
	local data = file:read("*all")
	file:close()

	xm_id = data:sub(0+1, 17)
	xm_module_name = data:sub(17+1, 37)
	xm_tracker_name = data:sub(38+1, 58)
	xm_version_number = {data:byte(58+1, 60)}
	xm_header_size = {data:byte(60+1, 64)}
	xm_song_length = {data:byte(64+1, 66)}
	xm_restart_position = {data:byte(66+1, 68)}
	xm_number_of_channels = {data:byte(68+1, 70)}
	xm_number_of_patterns = {data:byte(70+1, 72)}
	xm_number_of_instruments = {data:byte(72+1, 74)}
	xm_flags = {data:byte(74+1, 76)}
	xm_default_tempo = {data:byte(76+1, 78)}
	xm_default_bpm = {data:byte(78+1, 80)}
	local offset = 336
	xm_pattern_order_table = {data:byte(80+1, offset)}
	xm_pattern_header_length = {data:byte(offset+1, offset+4)}
	xm_packing_type = {data:byte(offset+4+1, offset+5)}
	xm_number_of_rows_in_pattern = {data:byte(offset+5+1, offset+7)}
	xm_packed_pattern_data_size = {data:byte(offset+7+1, offset+9)}
	local packed_size = xm_packed_pattern_data_size[1] + xm_packed_pattern_data_size[2]*256
	local offset2 = offset + 9 + packed_size
	xm_packed_pattern_data = {data:byte(offset+9, offset2)}
	xm_instrument_size = {data:byte(offset2+1, offset2+4)}
	xm_instrument_name = data:sub(offset2+4+1, offset2+26)
	xm_instrument_type = {data:byte(offset2+26+1, offset2+27)}
	xm_number_of_samples = {data:byte(offset2+27+1, offset2+29)}
	if ((xm_number_of_samples[1]*256+xm_number_of_samples[2]) > 0) then
		xm_sample_header_size = {data:byte(offset2+29+1, offset2+33)}
		print(xm_sample_header_size[1], xm_sample_header_size[2], xm_sample_header_size[3], xm_sample_header_size[4])
		xm_sample_keymap_assignments = {data:byte(offset2+33+1, offset2+129)}
		xm_points_for_volume_envelope = {data:byte(offset2+129+1, offset2+177)}
		xm_points_for_panning_envelope = {data:byte(offset2+177+1, offset+225)}
		xm_envelope_points = {data:byte(offset2+225+1, offset2+263)}
	end
	local instr_size = xm_instrument_size[1]+xm_instrument_size[2]*256+xm_instrument_size[3]*65536+xm_instrument_size[4]*16777216
	local offset3 = offset2+instr_size
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