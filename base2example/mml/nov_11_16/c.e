class
	C

create
	make

feature
	x, y: STRING
	make
		do
			x := ""
			y := x
		end

	f3
		do
			x := y
		end

end
