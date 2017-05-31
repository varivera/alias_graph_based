class
	A1

create
	make

feature
	make
		do
			a := ""
			b := ""
			create f.make
			create f2.make
		end

	ll
		do
			from

			until
				True
			loop
				a := b
				f := f.right
				f2 := f2.right
			end
		end

	l0
		do
			from
			until
				True
			loop

			end
		end

	a, b: STRING
	f, f2: A1F
	l1
		do
			from
			until
				True
			loop
				a := b
			end
		end

	l2
		do
			from
			until
				True
			loop
				f := f.right
			end
		end



end
