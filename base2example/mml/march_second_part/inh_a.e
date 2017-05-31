class
	INH_A
--inherit
--	INH_ZZ
--		redefine test1 end

create
	make_2
feature

	test1
		do
			a := b
		end

	a, b: STRING
	make_2
		do
			a:=""
			b:=""
		end

end
