class
	AA

create
	make

feature
	make
		do
			create bb.make
			a:=  ""
		end

	a:STRING
	bb:BB

	f
		do
			bb.set_a (a)
		end

end
