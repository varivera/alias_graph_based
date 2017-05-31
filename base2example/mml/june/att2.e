class
	ATT2

create
	make

feature
	tt 
		do
			if True then
				a := v.a
			else
				a := v.b
			end
		end

	a,b: STRING
	v2: ATT2
	v: ATT3

	make
		do
			a := ""
			b := ""
			create v2.make
			create v.make
		end

end
