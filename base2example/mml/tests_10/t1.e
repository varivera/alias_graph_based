class
	T1

create
	make

feature
	make
		do
			s1 := ""
			s2 := ""
		end

	s1, s2: detachable STRING
	i: INTEGER

	test
		do
			from

			until
				True
			loop
				i := i + 3
				check aa: attached s1 as r then
					s2 := r
				end
			end

		end

end
