class
	EXTERNAL_FEATURES2

create
	make


feature

	test_vii
		do
			external_vii (a)
		end

	external_vii (v: STRING)
			--
		note
			may_alias: "{(v, c)}"
		external
			"built_in"
		end

	test_vi
		do
			external_vi (a)
		end

	external_vi (v: STRING)
			--
		note
			may_alias: "{(b, v)}"
		external
			"built_in"
		end

	test_v
		do
			a := external_v
		end

	external_v: STRING
			--
		note
			may_alias: "{(Result,b)}"
		external
			"built_in"
		end

	test_iv
		do
			a := external_iv
		end

	external_iv: STRING
			--
		note
			may_alias: "{(Result,+)}"
		external
			"built_in"
		end

	test_iii
		do
			a := b
			external_iii
		end

	external_iii
			--
		note
			may_alias: "{(a,c)}"
		external
			"built_in"
		end

	test_ii
		do
			a := b
			c := d
			d := b
			external_ii
		end

	external_ii
			--
		note
			may_alias: "{(a,+)}"
		external
			"built_in"
		end

	test_i
		do
			external_i
		end

	external_i
			--
		note
			may_alias: "{(b,a), (b,d)}"
		external
			"built_in"
		end

	test_i_a
		do
			a := b
			external_i
		end


	a,b,c,d: STRING
	make
		do
			a := ""
			b := ""
			c := ""
			d := ""
		end

end
