class
	TT2

create
	make

feature
	x: TT3
	make
		do
			create x.make
		end

	set_x (v: STRING)
		do
			if True then
				get_x.set_h (v)
			end
		end

	get_x: TT3
		do
			Result := x
		end
end
