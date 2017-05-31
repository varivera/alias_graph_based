class
	FP1

create
	make

feature

--	issue3_a
--		do
--			h_issue3 (a,2)
--		end
	issue3 (n:FP2)
		do
			a := n+n
			--h_issue3 (n*n)
		end
--	h_issue3 (j: STRING; asd: INTEGER)
--		do
--			b := j
--		end


--	issue2
--		do
--			check test: True then
--				a := b
--				t1 := t2
--			end
--		end
	a: STRING
--	b: STRING
--	c: INTEGER
--	ff:FP2

	make
		do
--			t1 := {INTEGER}
--			t2 := {INTEGER}
			a := ""
--			b := ""
--			create ff.make
		end

--	t1,t2: TYPE [INTEGER]

--	aa
--		do
--			a := ""
--		end

--	bb
--		do
--			a := ""
--		end
end
