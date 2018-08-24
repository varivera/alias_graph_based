note
	description: "[
		Containers for a finite number of values.
		Immutable interface.
		]"
	author: "Nadia Polikarpova"
	model: bag
	manual_inv: true
	false_guards: true

deferred class
	V_CONTAINER [G]

inherit
	ITERABLE [G]

feature -- Measurement

	count: INTEGER
			-- Number of elements.
		deferred
		end

feature -- Status report

	is_empty: BOOLEAN
			-- Is container empty?
		do
			Result := count = 0
		end

feature -- Search

	has (v: G): BOOLEAN
			-- Is value `v' contained?
			-- (Uses reference equality.)
		local
			it: V_ITERATOR [G]
		do
			it := new_cursor
			it.search_forth (v)
			Result := not it.after
		end

	occurrences (v: G): INTEGER
			-- How many times is value `v' contained?
			-- (Uses reference equality.)
		local
			it: V_ITERATOR [G]
			s: MML_SEQUENCE [G]
		do
			from
				it := new_cursor
			invariant
				1 <= it.index_ and it.index_ <= it.sequence.count + 1
				s = it.sequence.front (it.index_ - 1)
				Result = s.occurrences (v)
			until
				it.off
			loop
				if it.item = v then
					Result := Result + 1
				end
				s := s & it.item
				it.forth
			variant
				it.sequence.count - it.index_
			end
		end

feature -- Iteration

	new_cursor: V_ITERATOR [G]
			-- New iterator pointing to a position in the container, from which it can traverse all elements by going `forth'.
		deferred
		end

feature -- Specification

	bag: MML_BAG [G]
			-- Bag of elements.

feature {V_CONTAINER, V_ITERATOR} -- Specification

	add_iterator (it: V_ITERATOR [G])
			-- Add `it' to `observers'.
		note
			status: ghost
		do
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
