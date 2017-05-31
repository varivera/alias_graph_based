class
	XX2

create
	make

feature

	test: XX2
		do
			Result := w.t2
			-- To check Result := Result.t2
		end

	t2: XX2
		do
			if True then
				Result := b
			else
				Result := c
			end
		end

	w: XX2
		do
			Result := a
		end

	a, b, c: XX2

	make
		do
			create a.make
			create b.make
			create c.make
		end

end
