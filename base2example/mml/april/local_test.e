class
	LOCAL_TEST

create
	make

feature

	t3
		do
			if True then
				t4
				a := b
			end
		end

	t4
		do
			if attached f2 as fresh_one then
				fresh_one.tt
				f3 := fresh_one
			else
				a := b
			end
		end

	t5
		do
			a := b
		end

	t1
		local
			d : STRING
		do
			if True then
				d := a
			    t2
			end
		end

	t2
		local
			d:STRING
		do
			d := f
		end

	a, b, f, r: STRING
	f2, f3: LOCAL_TEST2

	make
		do
			a := ""
			b := ""
			f := ""
			r := ""
			create f2.make
			create f3.make
		end

end
