class
	K1

create
	make

feature
	t0: K2
		do
			Result := test
		end

	test: K2
		do
			if True then
				--x.t
				--Result := w1
				Result := x
				inter
			else
				Result := w2
			end
		end

	inter
		do
			w2 := x
		end

	x: K2
		do
		Result := w1
--		do
--			if True then
--				Result := w1
--			else
--				Result := w2
--			end
		end

	make
		do
			create w1.make
			create w2.make
		end
	w1,w2: K2
end
