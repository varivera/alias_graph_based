class
	FUNC_B

create
	make

feature

	b (v: STRING)
		do
			if True then
				d1 := v
			else
				d3 := d4
			end
		end

	d1, d2, d3, d4: STRING
	make
		do
			d1 := ""
			d2 := ""
			d3 := ""
			d4 := ""
		end

end
