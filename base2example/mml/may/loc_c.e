class
	LOC_C

create
	make

feature

	f_t3
		do
			from

			until
				True
			loop
				a := b
			end
--			if True then
--				a := b
--			else
--				c := d
--			end
		end

	t3
		do
			if True then
				a := b
			else
				c := d
			end
		end


	a,b,c,d: STRING
	make
		do
			a := ""
			b := ""
			c := ""
			d := ""
		end

end
