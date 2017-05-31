class
	CHECK_T2

create
	make

feature
	t1
		do
			x := v
		end

	x, v: STRING

	make
		do
			x := ""
			v := ""
		end

end
