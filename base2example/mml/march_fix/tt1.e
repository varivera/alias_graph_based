class
	TT1

create
	make

feature

	tt0
		do
			tt1
		end

	tt1
		do
			if True then
				b := get_b2
			end
		end

	get_b2: STRING
		do
--			if True then
--				Result := b2
--			else
--				Result := b3
--			end
			Result := b2
		end

	t0
		do
			t1
		end

	t1
		do
			c.set_x (b)
		end
	a: TT3
	c: TT2
	b3, b2, b: STRING


	make
		do
			create a.make
			create c.make
			b := ""
			b2 := ""
			b3 := ""
		end
end
