note
	description: "Sequences where values can be updated."
	author: "Nadia Polikarpova"
	model: sequence, lower_

deferred class
	V_MUTABLE_SEQUENCE [G]

inherit
	V_SEQUENCE [G]
		redefine
			item
		end
feature -- testing
	test_copy_range (other: V_SEQUENCE [G]; other_first, other_last, index: INTEGER)
		local
			other_it: V_SEQUENCE_ITERATOR [G]
			it: V_MUTABLE_SEQUENCE_ITERATOR [G]
			j, n: INTEGER
		do
			n := other_last - other_first + 1
			from
				j := 0
				other_it := other.at (other_first)
				it := at (index)
			until
				True
			loop
				it.put (other_it.item)
				other_it.forth
				it.forth
				j := j + 1
			end
		end
feature -- Access

	item alias "[]" (i: INTEGER): G assign put
			-- Value at position `i'.
		deferred
		end

feature -- Iteration

	at (i: INTEGER): V_MUTABLE_SEQUENCE_ITERATOR [G]
			-- New iterator pointing at position `i'.
	deferred
	end

feature -- Replacement

	put (v: G; i: INTEGER)
			-- Replace value at position `i' with `v'.
		note
			modify_model: sequence, Current_
		deferred
		end

	swap (i1, i2: INTEGER)
			-- Swap values at positions `i1' and `i2'.
		note
			modify_model: sequence, Current_
		local
			v: G
		do
			v := item (i1)
			put (item (i2), i1)
			put (v, i2)
		end

	fill (v: G; l, u: INTEGER)
			-- Put `v' at positions [`l', `u'].
		note
			modify_model: sequence, Current_
		local
			it: V_MUTABLE_SEQUENCE_ITERATOR [G]
			j: INTEGER
		do
			from
				it := at (l)
				j := l
			until
				j > u
			loop
				it.put (v)
				it.forth
				j := j + 1
			end
		end

	clear (l, u: INTEGER)
			-- Put default value at positions [`l', `u'].
		do
			fill (({G}).default, l, u)
		end

	copy_range (other: V_SEQUENCE [G]; other_first, other_last, index: INTEGER)
			-- Copy items of `other' within bounds [`other_first', `other_last'] to current sequence starting at index `index'.
		note
			modify_model: sequence, Current_
		local
			other_it: V_SEQUENCE_ITERATOR [G]
			it: V_MUTABLE_SEQUENCE_ITERATOR [G]
			j, n: INTEGER
		do
			n := other_last - other_first + 1
			from
				j := 0
				other_it := other.at (other_first)
				it := at (index)
			until
				j >= n
			loop
				it.put (other_it.item)
				other_it.forth
				it.forth
				j := j + 1
			end
		end

	reverse
			-- Reverse the order of elements.
		note
			modify_model: sequence, Current_
		local
			j, k: INTEGER
		do
			from
				j := lower
				k := upper
			until
				j >= k
			loop
				swap (j, k)
				j := j + 1
				k := k - 1
			end
		end

note
	copyright: "Copyright (c) 1984-2014, Eiffel Software and others"
	license: "Eiffel Forum License v2 (see http://www.eiffel.com/licensing/forum.txt)"
	source: "[
			Eiffel Software
			5949 Hollister Ave., Goleta, CA 93117 USA
			Telephone 805-685-1006, Fax 805-685-6869
			Website http://www.eiffel.com
			Customer support http://support.eiffel.com
		]"
end
