note
	description: "[
		Containers where values are associated with integer indexes from a continuous interval.
		Immutable interface.
		]"
	author: "Nadia Polikarpova"
	model: sequence, lower_
	manual_inv: true
	false_guards: true

deferred class
	V_SEQUENCE [G]

inherit
	V_CONTAINER [G]
		redefine
			is_empty
		end

feature -- Testing
	test_new_cursorddd: V_SEQUENCE_ITERATOR [G]
			-- New iterator pointing to the first position.
		do
			Result := at (lower)
		end

feature -- Access

	item alias "[]" (i: INTEGER): G
			-- Value at index `i'.
		deferred
		end

	first: G
			-- First element.
		note
		do
			Result := item (lower)
		end

	last: G
			-- Last element.
		do
			Result := item (upper)
		end

feature -- Measurement

	lower: INTEGER
			-- Lower bound of index interval.
		deferred
		end

	upper: INTEGER
			-- Upper bound of index interval.
		do
			Result := lower + count - 1
		end

	count: INTEGER
			-- Number of elements.
		deferred
		end

	has_index (i: INTEGER): BOOLEAN
			-- Is any value associated with `i'?
		do
			Result := lower <= i and i <= upper
		end

feature -- Status report

	is_empty: BOOLEAN
			-- Is container empty?
		do
			Result := count = 0
		end

feature -- Search

	index_of (v: G): INTEGER
			-- Index of the first occurrence of `v';
			-- out of range, if `v' does not occur.			
		do
			if not is_empty then
				Result := index_of_from (v, lower)
			else
				Result := upper + 1
			end
		end

	index_of_from (v: G; i: INTEGER): INTEGER
			-- Index of the first occurrence of `v' starting from position `i';
			-- out of range, if `v' does not occur.
		local
			it: V_SEQUENCE_ITERATOR [G]
		do
			it := at (i)
			it.search_forth (v)
			if it.off then
				Result := upper + 1
			else
				Result := it.target_index
			end
		end

feature -- Iteration

	new_cursor: like at
			-- New iterator pointing to the first position.
		do
			Result := at (lower)
		end

	at_last: like at
			-- New iterator pointing to the last position.
		do
			Result := at (upper)
		end

	at (i: INTEGER): V_SEQUENCE_ITERATOR [G]
			-- New iterator pointing at position `i'.
			-- If `i' is off scope, iterator is off.
		deferred
		end

feature -- Specification

	sequence: MML_SEQUENCE [G]
			-- Sequence of elements.
		note
			status: ghost
			replaces: bag
		attribute
		end

	lower_: INTEGER
			-- Lower bound of index interval.
		note
			status: ghost
		attribute
		end

	upper_: INTEGER
			-- Upper bound of index interval.
		note
			status: functional, ghost, nonvariant
		do
			Result := lower_ + sequence.count - 1
		end

	idx (i: INTEGER): INTEGER
			-- Sequence index of position `i'.
		note
			status: ghost, functional, nonvariant
		do
			Result := i - lower_ + 1
		end

invariant
	lower_constraint: sequence.is_empty implies lower_ = 1
	bag_definition: bag ~ sequence.to_bag

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
