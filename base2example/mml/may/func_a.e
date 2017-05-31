class
	FUNC_A

create
	make

feature

	test
		do
			tt.b (c1)
		end

	a: FUNC_B
		do
			Result := tt
		end

	tt: FUNC_B
		do
			create Result.make
		end

	c1: STRING
	make
		do
			c1 := ""
		end

end
