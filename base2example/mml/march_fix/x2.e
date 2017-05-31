class
	X2 [G]
inherit
	V_DEFAULT [G]

create
	make

feature

	t2 alias "[]" (i: INTEGER): G
		do
			if attached s1 as res then
				Result := res
			else
				Result := default_value
			end
		end

	s1, s2: G
	d: G
		note
			
		do
			Result := s1
		end

	make
		do
			s1 := default_value
			s2 := default_value
		end

end
