class
	TT3

create
	make

feature
	make
		do
			create h.make
		end
	h: TT4

	set_h (w: STRING)
		local
			d: TT3
		do
			get_h.set_hh (w)
		end

	get_h: TT4
		do
			Result := h
		end

end
