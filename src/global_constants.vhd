package global_constants is
	constant word_width:    natural := 16;
	constant bus_width:     natural := word_width;
	constant address_width: natural := word_width - 4;
	constant io_width:      natural := word_width / 2;
end global_constants;
