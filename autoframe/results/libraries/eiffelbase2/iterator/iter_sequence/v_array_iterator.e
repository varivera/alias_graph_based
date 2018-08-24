note
	description: "Iterators over mutable sequences that allow only traversal, search and replacement."
	author: "Nadia Polikarpova"
	model: target, index_
	manual_inv: true
	false_guards: true

class
	V_ARRAY_ITERATOR [G]

inherit
	V_INDEX_ITERATOR [G]
		redefine
			target,
			sequence,
			index_
		end

	V_MUTABLE_SEQUENCE_ITERATOR [G]
		undefine
			go_to
		redefine
			target,
			sequence,
			index_
		end

create {V_CONTAINER}
	make
feature -- Testing
	test_make (t: V_MUTABLE_SEQUENCE [G]; i: INTEGER)
		do
			target := t
			target.add_iterator (Current)
			if i < 1 then
				index := 0
			elseif i > t.count then
				index := t.count + 1
			else
				index := i
			end
		end
feature {NONE} -- Initialization

	make (t: V_MUTABLE_SEQUENCE [G]; i: INTEGER)
			-- Create an iterator at position `i' in `t'.
		note
			modify: Current_
		do
			target := t
			target.add_iterator (Current)
			if i < 1 then
				index := 0
			elseif i > t.count then
				index := t.count + 1
			else
				index := i
			end
		end

feature -- Initialization

	copy_ (other: like Current)
			-- Initialize with the same `target' and `index' as in `other'.
		note
			modify: Current_
		do
			if other /= Current then
				target := other.target
				target.add_iterator (Current)
				index := other.index
			end
		end

feature -- Access

	target: V_MUTABLE_SEQUENCE [G]
			-- Target container.

feature -- Replacement

	put (v: G)
			-- Replace item at current position with `v'.
		do
			target.put (v, target.lower + index - 1)
		end

feature -- Specification

	sequence: MML_SEQUENCE [G]
			-- Sequence of elements in `target'.
		note
			status: ghost
		attribute
		end

	index_: INTEGER
			-- Current position.
		note
			status: ghost
		attribute
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
