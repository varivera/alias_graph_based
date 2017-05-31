class
	X1 [G]
create
	make

feature

	ta: G
		do
			Result := t
		end

	t: G
		do
			--Result := tt [2]
			--Result := tt.t2 (2)
			Result := tt.d
		end

	tt: X2 [G]

	make
		do
			create tt.make
		end

end
