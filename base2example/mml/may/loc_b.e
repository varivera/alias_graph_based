class
	LOC_B

create
	make

feature

	ff
		do
			if True then
				r := t
			else
				y := u
			end
		end

	f_t2 (s: STRING)
		do
			if True then
				r := s
			end
		end

	v2: LOC_C
	v1: LOC_B

	tt: LOC_C
		do
			Result := v2
		end

	tt2
		do
			v2.t3
		end
	r,t, y, u: STRING
	make
		do
			create v2.make
			create v1.make
			r := ""
			t := ""
			y := ""
			u := ""
		end

end
