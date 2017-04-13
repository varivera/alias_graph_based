class
	A
create
	make
feature
	t0
		do
			tt
		end

	tt
		local
			l1: B
		do
			create l1
			if True then
				l1.t
			else
				a := b
			end
		end

	a,b: STRING

	make
		do
			a:= ""
			b := ""
		end
end
