class
	XX1

create
	make

feature

	test: XX1
		do
			if True then
				Result := w2
			else
				Result := w.t
			end
		end

	t2: XX1
		do
			if True then
				Result := v
			else
				Result := x
			end
		end

	w: XX1
		do
			if True then
				Result := w3.w5
			else
				Result := w4
			end
		end

	t: XX1
		do
			if True then
				Result := a
			else
				Result := b.t2
			end
		end

	x: XX1
		do
			Result := z
		end

	w2, w3, w4, w5, a, b, v, z: XX1

	make
		do
			create w2.make
			create w3.make
			create w4.make
			create w5.make
			create a.make
			create b.make
			create v.make
			create z.make
		end

end
