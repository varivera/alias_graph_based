class
	B

create
	make

feature
	v: C
	make
		do
			create v.make
		end

	f2
		do
			v.f3
		end

end
