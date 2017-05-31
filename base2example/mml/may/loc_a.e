class
	LOC_A

create
	make

feature

	test_def (v: LOC_D)
		do
			from
			until
				True
			loop
				ff := v.s
			end
		end

	f_test
		do
			if True then
				b := x
				b.ff
			end
		end


	f_t1 (v: LOC_D)
		do
			if True then
				from
				until
					True
				loop
					b.f_t2 (v.s)
				end
			end
		end

	t2
		local
			dd: LOC_C
		do
			--t.t3
			dd := t
		end

	t: LOC_C
		do
			if True then
				create Result.make
			else
				create Result.make
			end

		end


	test3
		do
			b.v1.v2.t3
			test2
			test
		end

	test
		do
			b.tt.t3
		end

	test2
		do
			b.v2.t3
		end

	b,x: LOC_B
	ff: STRING
	make
		do
			create b.make
			create x.make
			ff := ""
		end

end
