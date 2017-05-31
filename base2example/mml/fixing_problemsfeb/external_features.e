class
	EXTERNAL_FEATURES

create
	make

feature
	f
	do

	end
	test_i
		-- alias:
		--		1. a:b
		do
			a := external_i (b)
		end

	external_i (v: STRING): STRING
			--
		note
			may_alias: "{(Result,v)}"
		external
			"built_in"
		end

	test_ii
			-- alias:
			--		1. a:b
			--		2. nothing
		do
			a := b
			external_ii
		end

	external_ii
			-- a will be aliased to a new object. Previous aliases will be lost
		note
			may_alias: "{(a,+)}"
		external
			"built_in"
		end

	test_iii
			-- alias:
			--		1. a:c
		do
			a := external_iii
		end

	external_iii: STRING
			-- Result aliased to c
		note
			may_alias: "{(Result,c)}"
		external
			"built_in"
		end


	test_iv
		-- alias:
				--		1. a:b
				--		2. c:b
		do
			a := b
			external_iv
		end

	external_iv
			--
		note
			may_alias: "{(c,b)}"
		external
			"built_in"
		end

	test_v
		-- alias:
				--		1. a:b
				--		2. nothing
		do
			a := b
			a := external_v
		end

	external_v: STRING
			-- Result aliased to new object STRING
		note
			may_alias: "{(Result,+)}"
		external
			"built_in"
		end

	test_vi
		-- alias:
				--		1. a:b
				--		2. a:b
		do
			a := b
			external_vi
		end

	external_vi
			-- no alias is performed
		note
			may_alias: "{}"
		external
			"built_in"
		end

	a,b,c:STRING

	d:detachable SPECIAL [STRING]

	make
		do
			a := ""
			b := ""
			c := ""
		end
end
