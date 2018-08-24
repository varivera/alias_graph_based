note
	description: "Iterators over hash sets."
	author: "Nadia Polikarpova"
	model: target, sequence, index_
	manual_inv: true
	false_guards: true

class
	V_HASH_SET_ITERATOR [G -> V_HASHABLE]

inherit
	V_SET_ITERATOR [G]
		redefine
			target
		end

create {V_HASH_SET}
	make

feature -- Testing
	test_make (t: V_HASH_SET [G])
		do
			target := t
			iterator := t.table.new_cursor
		end

feature {NONE} -- Initialization

	make (t: V_HASH_SET [G])
			-- Create iterator over `t'.
		note
			modify: Current_
		do
			target := t
			iterator := t.table.new_cursor
		end

feature -- Initialization

	copy_ (other: like Current)
			-- Initialize with the same `target' and position as in `other'.
		note
			modify: Current_
		do
			if Current /= other then
				if target /= other.target then
					make (other.target)
				end
				iterator.go_to_other (other.iterator)
			end
		end

feature -- Access

	target: V_HASH_SET [G]
			-- Set to iterate over.

	item: G
			-- Item at current position.
		do
			Result := iterator.key
		end

feature -- Measurement		

	index: INTEGER
			-- Current position.
		do
			Result := iterator.index
		end

feature -- Status report

	before: BOOLEAN
			-- Is current position before any position in `target'?
		do
			Result := iterator.before
		end

	after: BOOLEAN
			-- Is current position after any position in `target'?
		do
			Result := iterator.after
		end

	is_first: BOOLEAN
			-- Is cursor at the first position?
		do
			Result := iterator.is_first
		end

	is_last: BOOLEAN
			-- Is cursor at the last position?
		do
			Result := iterator.is_last
		end

feature -- Comparison

	is_equal_ (other: like Current): BOOLEAN
			-- Is iterator traversing the same container and is at the same position at `other'?
		do
			Result := iterator.is_equal_ (other.iterator)
		end

feature -- Cursor movement

	search (v: G)
			-- Move to an element equivalent to `v'.
			-- If `v' does not appear, go after.
			-- (Use object equality.)
		do
			iterator.search_key (v)
		end

	start
			-- Go to the first position.
		do
			iterator.start
		end

	finish
			-- Go to the last position.
		do
			iterator.finish
		end

	forth
			-- Move one position forward.
		do
			iterator.forth
		end

	back
			-- Go one position backwards.
		do
			iterator.back
		end

	go_before
			-- Go before any position of `target'.
		do
			iterator.go_before
		end

	go_after
			-- Go after any position of `target'.
		do
			iterator.go_after
		end

feature -- Removal

	remove
			-- Remove element at current position. Move cursor to the next position.
		do
			iterator.remove
		end

feature {V_CONTAINER, V_ITERATOR, V_LOCK} -- Implementation

	iterator: V_HASH_TABLE_ITERATOR [G, ANY]
			-- Iterator over the storage.		

invariant
	iterator_exists: iterator /= Void
	targets_connected: target.table = iterator.target
	same_sequence: sequence ~ iterator.sequence
	same_index: index_ = iterator.index_

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
