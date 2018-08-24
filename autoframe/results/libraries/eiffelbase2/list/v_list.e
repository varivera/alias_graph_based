note
	description: "[
		Indexable containers, where elements can be inserted and removed at any position. 
		Indexing starts from 1.
		]"
	author: "Nadia Polikarpova"
	model: sequence
	manual_inv: true
	false_guards: true

deferred class
	V_LIST [G]

inherit
	V_MUTABLE_SEQUENCE [G]
		redefine
			item,
			at
		end
feature -- Testing
	test_new_cursor2: like at
			-- New iterator pointing to the first position.
		do
			Result := new_cursor
		end
feature -- Access

	item alias "[]" (i: INTEGER): G
			-- Value at index `i'.
		deferred
		end

feature -- Measurement

	lower: INTEGER
			-- Lower bound of index interval.
		do
			Result := 1
		end

	count: INTEGER
			-- Number of elements.
		do
			Result := count_
		end

feature -- Iteration

	at (i: INTEGER): V_LIST_ITERATOR [G]
			-- New iterator pointing at position `i'.
		deferred
		end

feature -- Extension

	extend_front (v: G)
			-- Insert `v' at the front.
		note
			modify_model: sequence, Current_
		deferred
		end

	extend_back (v: G)
			-- Insert `v' at the back.
		note
			modify_model: sequence, Current_
		deferred
		end

	extend_at (v: G; i: INTEGER)
			-- Insert `v' at position `i'.
		note
			modify_model: sequence, Current_
		deferred
		end

	append (input: V_ITERATOR [G])
			-- Append sequence of values produced by `input'.
		note
			modify_model: sequence, Current_
			modify_model: index_, input
		do
			from
			until
				input.after
			loop
				extend_back (input.item)
				input.forth
			variant
				input.sequence.count - input.index_
			end
		end

	prepend (input: V_ITERATOR [G])
			-- Prepend sequence of values produced by `input'.
		note
			modify_model: sequence, Current_
			modify_model: index_, input
		deferred
		end

	insert_at (input: V_ITERATOR [G]; i: INTEGER)
			-- Insert starting at position `i' sequence of values produced by `input'.
		note
			modify_model: sequence, Current_
			modify_model: index_, input
		deferred
		end

feature -- Removal

	remove_front
			-- Remove first element.
		note
			modify_model: sequence, Current_
		deferred
		end

	remove_back
			-- Remove last element.
		note
			modify_model: sequence, Current_
		deferred
		end

	remove_at (i: INTEGER)
			-- Remove element at position `i'.
		note
			modify_model: sequence, Current_
		deferred
		end

	remove (v: G)
			-- Remove the first occurrence of `v'.
		note
			modify_model: sequence, Current_
		local
			i: V_LIST_ITERATOR [G]
		do
			i := new_cursor
			i.search_forth (v)
			i.remove
		end

	remove_all (v: G)
			-- Remove all occurrences of `v'.
		note
			modify_model: sequence, Current_
		local
			i: V_LIST_ITERATOR [G]
			n_, j_: INTEGER
		do
			from
				i := new_cursor
				i.search_forth (v)
			until
				i.after
			loop
				i.remove
				j_ := i.index_

				i.search_forth (v)

				n_ := n_ + 1
			variant
				i.sequence.count - i.index_
			end
		end

	wipe_out
			-- Remove all elements.
		note
			modify_model: sequence, Current_
		deferred
		end

feature {V_LIST, V_LIST_ITERATOR} -- Implementation

	count_: INTEGER
			-- Number of elements.		

feature -- Specification

	is_model_equal (other: like Current): BOOLEAN
			-- Is the abstract state of `Current' equal to that of `other'?
		note
			status: ghost, functional, nonvariant
		do
			Result := sequence ~ other.sequence
		end

	removed_all (s: like sequence; x: G): like sequence
			-- Sequence `s' with all occurrences of `x' removed.
		do
			Result := if s.is_empty then s else
				if s.last = x then removed_all (s.but_last, x) else removed_all (s.but_last, x) & s.last end end
		end

invariant
	lower_definition: lower_ = 1
	count_definition: count_ = sequence.count

note
	copyright: "Copyright (c) 1984-2016, Eiffel Software and others"
	license: "Eiffel Forum License v2 (see http://www.eiffel.com/licensing/forum.txt)"
	source: "[
			Eiffel Software
			5949 Hollister Ave., Goleta, CA 93117 USA
			Telephone 805-685-1006, Fax 805-685-6869
			Website http://www.eiffel.com
			Customer support http://support.eiffel.com
		]"
end
