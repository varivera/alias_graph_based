class
	T3

create
	make

feature

	make
		do
			create v1.make
			create v2.make
			create v3.make
			create v4.make
			create v5.make
			v := ""
		end

	v1, v2, v3, v4, v5: T
	v: STRING

--	t2
--		do
--			if True then
--				v1 := v2
--			else
--				v1 := v3
--			end
--		end

	t (i: INTEGER; vv: T): T
	--t: T
		--local
		--	d:INTEGER
		do

			if True then
				v3 := v4
				Result := v2
			else
				Result := vv
			end


			--if True then
			--v3 := v4
			--Result := v2
			--else
			--	Result := v2
			--v1 := Result
			--end
--			if i = 1 then
--				--v2 := v1
--				Result := v1
--			else
--				--v3 := v1
--				Result := v2
--			end
			--d := 10
		end

	tt
		local
			i: INTEGER
		do
		--	i := 10
			-- to check
			--t (1).set_w (v)
			-- to check
			v1 := t (i, v5)

		end

--	ff: T
--		do
--			Result := v2
--		end

end
