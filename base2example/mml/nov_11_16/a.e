class
	A
create
	make

feature
	q: B
	a, b, v, w: STRING
	make
		do
			create q.make
			a := ""
			v := ""
			w:= ""
			b := ""
		end

	f
		do
			if True then
				q.f2
			else

			end
		end

	test
		do
			if True then
				a := v
				b := w
			else
				a := w
			end
		end

end
