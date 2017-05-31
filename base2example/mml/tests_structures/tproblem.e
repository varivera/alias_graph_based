class
	TPROBLEM

create
	make

feature

	make
		do
			create v1.make
			create v2.make
			create v3.make
			v := ""
		end

	v1, v2, v3: T
	v: STRING

	t3
		do
			if True then
				v1.make
			end
		end


	t
		do
			if True then
				v1 := v2
				create v2.make
			end
		end


	t11 (i: INTEGER): T
		do
			Result := v2
			create Result.make
--			if i = 1 then
--				Result := v2
--				create Result.make
--			else
--				Result := v3
--				create Result.make
--			end
		end

	t211
		local
			i: INTEGER
		do
			i := 10
			t11 (i).set_w (v)
			--t.set_w (v)
		end

end
