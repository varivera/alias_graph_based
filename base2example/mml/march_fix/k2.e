class
	K2

create
	make

feature
	t2: STRING
		do
			if True then
				Result := a
			else
				Result := b
			end
		end

	t
		do
			xx := 10
		end
	xx:INTEGER
	a,b: STRING
	make
		do
			a := ""
			b := ""
		end

end
