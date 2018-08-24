note
	description: "Iterators over arrayed lists."
	author: "Nadia Polikarpova"
	model: target, index_
	manual_inv: true
	false_guards: true

class
	V_ARRAYED_LIST_ITERATOR [G]

inherit
	V_LIST_ITERATOR [G]
		undefine
			go_to
		redefine
			target,
			sequence,
			index_
		end

	V_INDEX_ITERATOR [G]
		redefine
			target,
			sequence,
			index_
		end

create {V_ARRAYED_LIST}
	make

feature -- TEsting
	test_extend_left (v: G)
			-- Insert `v' to the left of current position. Do not move cursor.
		do
			target.extend_at (v, index)
			index := index + 1
		end

feature {NONE} -- Initialization

	make (list: V_ARRAYED_LIST [G]; i: INTEGER)
			-- Create an iterator at position `i' in `list'.
		note
			modify: Current_
		do
			target := list
			target.add_iterator (Current)
			if i < 1 then
				index := 0
			elseif i > list.count then
				index := list.count + 1
			else
				index := i
			end
		end

feature -- Initialization

	copy_ (other: like Current)
			-- Initialize with the same `target' and position as in `other'.
		note
			modify: Current_
		do
			if Current /= other then
				target := other.target
				target.add_iterator (Current)
				index := other.index
			end
		end

feature -- Access

	target: V_ARRAYED_LIST [G]
			-- Container to iterate over.

feature -- Replacement

	put (v: G)
			-- Replace item at current position with `v'.
		do
			target.put (v, index)
		end

feature -- Extension

	extend_left (v: G)
			-- Insert `v' to the left of current position. Do not move cursor.
		do
			target.extend_at (v, index)
			index := index + 1
		end

	extend_right (v: G)
			-- Insert `v' to the right of current position. Do not move cursor.
		do
			target.extend_at (v, index + 1)
		end

	insert_left (other: V_ITERATOR [G])
			-- Append sequence of values, over which `input' iterates to the left of current position. Do not move cursor.
		local
			old_other_count: INTEGER
		do
			old_other_count := other.target.count - other.index + 1
			target.insert_at (other, index)
			index := index + old_other_count
		end

	insert_right (other: V_ITERATOR [G])
			-- Append sequence of values, over which `input' iterates to the right of current position. Move cursor to the last element of inserted sequence.
		local
			old_other_count: INTEGER
		do
			old_other_count := other.target.count - other.index + 1
			target.insert_at (other, index + 1)
			index := index + old_other_count
		end

feature -- Removal

	remove
			-- Remove element at current position. Move cursor to the next position.
		do
			target.remove_at (index)
		end

	remove_left
			-- Remove element to the left current position. Do not move cursor.
		do
			target.remove_at (index - 1)
			index := index - 1
		end

	remove_right
			-- Remove element to the right current position. Do not move cursor.
		do
			target.remove_at (index + 1)
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
