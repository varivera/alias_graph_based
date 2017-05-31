class
	ATT1
create
	make

feature

	test (var1: ATT2)
		do
			---Problem1 --var1.tt--: does not give the right answer: it is missing var1.a: var1.v.a
			---Problem1 var1.v2.tt

			var2.v2.tt

		end


	var2: ATT2

	make
		do
--			create var1.make
			create var2.make
		end

end
