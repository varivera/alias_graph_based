class
	REC

create
	make

feature
	make
		do
			create a.make
			create b.make
			create c.make
			create d.make
		end

	a,b,c,d: A1F



	tmp
		do
			if True then
				a := b
				a := d
				c := d
			else
				a := b
			end
		end

	test
		do
			--a := b
			f(a)
			b := c
		end

	f (v: A1F)
		do
			c := v.right
			f (c)
		end
	dd
		do
			if True then
				a := b
			end

		end
end
