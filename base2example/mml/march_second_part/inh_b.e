class
	INH_B

inherit
	INH_A
		redefine test1 end



create
	make_3
feature

	test1
		do
			c := d
			--a := b
			--Precursor
		end

	c, d: STRING

	make_3
		do
			a:=""
			b:=""
			c := ""
			d:=""
		end

end
