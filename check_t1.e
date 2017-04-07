class
	CHECK_T1

create
	make

feature
	problem1
		do
			if True then
				t2
			else
				a := b
			end
		end

	t2
		local
			p: like a
		do
			p := a
			p.t1
		end

	problem2
		do
			if True then
				t3
			else
				a := b
			end
		end

	t3
		do
			a.t1
		end

	problem3
		do
			if True then
				t4
			else
				a := b
			end
		end

	t4
		do
			if attached a as p then
				a.t1
			end

		end

	a, b, c: CHECK_T2

	make
		do
			create a.make
			create b.make
			create c.make
		end

end
