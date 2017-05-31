class
	TEST_STR

create
	make

feature

	test
		do
			a.append ("")
		end

	a,b: STRING

	make
		do
			a:=""
			b:=""
		end

end
