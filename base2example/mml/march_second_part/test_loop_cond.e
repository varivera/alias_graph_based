class
	TEST_LOOP_COND

create
	make

feature

	tt
		do
			--c := a

			a := a.right
			a := a.right
		end

	test_loop_cond
		do
			c := a
			if True then
				from
				until
					True
				loop
					a := a.right
				end
			else
				a := b
			end

		end

	test_cond_loop
		do
			d1 := d
			from
			until
				True
			loop
				if True then
					a := b
				elseif True then
					a := c
				else
					a := e
					d := d.right
				end
			end
		end

	a,b,c,d,d1,e:  QQ2

	make
		do
			create a.make
			create b.make
			create c.make
			create d.make
			create d1.make
			create e.make
		end


end
