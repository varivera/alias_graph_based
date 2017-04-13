class
	C

create
	make

feature


	t11
		local
			p: STRING
		do
			if True then
				p := a
			end
			t21
		end

	t21
		do
			t11
		end


	t2
		local
			l3: STRING
		do
			l3 := d
			if True then
				a := l3
			else
				b := a
			end
		end

	a,b,d: STRING
	make
		do
			a := ""
			b := ""
			d := ""
		end
end
