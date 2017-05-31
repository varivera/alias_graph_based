class
	QQ1

create
	make

feature

	test_loop_cond
		do
			d2 := d
			if True then
				from
				until
					True
				loop
					d := d.right
				end
			else
				d := d3
			end

		end

	test_loop
		do
			from

			until
				True
			loop
				d := d.right
			end
		end
	test_loop2_a
		do
			test_loop2
		end
	test_loop2
		do

			from
			until
				True
			loop
				if attached d as qwA then
					d := qwA.right
				end
			end
		end

	test_recursion
		do
			make
		end


	test_void
		do

--			from
--			until
--				True
--			loop
				if attached a as qwA then
					a := qwA.right
--					-- TO Check: it is not subsuming
				end
--			end
		end


	a,c:detachable QQ2
	d, d2,d3: QQ2

	make
		do
			create a.make
			create c.make
			create d.make
			create d2.make
			create d3.make
		end

--	test_go_to (i: INTEGER)
--		do
--			if i = 0 then
--				go_before
--			end
--		end

--	go_before
--			-- Go before any position of `target'.
--		do
--			a := Void
--		end


--	test
--		do
--			from

--			until
--				True
--			loop
--				if True then
--					r := r.right
--				end

--			end
--		end

--	t2
--		do
--			from
--			until
--				True
--			loop
--				if True then
--					a := b
--				else
--					a := c
--				end
--			end
--		end

--	t3
--		do
--			if True then
--				a := b
--			else
--				a := c
--			end
--		end
--	a,b,c: detachable STRING
--	make
--		do
--			create r.make
--			a := ""
--			b := ""
--			c := ""
--		end
--	r: QQ2



end
