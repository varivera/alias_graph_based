note
	description: "Iterators over linked queues."
	author: "Nadia Polikarpova"
	model: target, index_
	manual_inv: true
	false_guards: true

class
	V_LINKED_QUEUE_ITERATOR [G]

inherit
	V_ITERATOR [G]
		redefine
			target
		end

create {V_CONTAINER}
	make


feature -- TEsting
	test_make (t: V_LINKED_QUEUE [G])
			-- Create iterator over `t'.
		do
			target := t
			iterator := t.list.test_new_cursor
		end

feature {NONE} -- Initialization

	make (t: V_LINKED_QUEUE [G])
			-- Create iterator over `t'.
		note
			modify: Current_
		do
			target := t
			iterator := t.list.new_cursor
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
				go_to_other (other)
			end
		end

feature -- Access

	target: V_LINKED_QUEUE [G]
			-- Stack to iterate over.

	item: G
			-- Item at current position.
		do
			Result := iterator.item
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

feature {V_CONTAINER, V_ITERATOR} -- Implementation

	iterator: V_LINKED_LIST_ITERATOR [G]
			-- Iterator over the storage.

	go_to_other (other: like Current)
			-- Move to the same position as `other'.
		note
			modify_model: index_, Current_
		do
			if other.iterator.before then
				iterator.go_before
			elseif other.iterator.after then
				iterator.go_after
			else
				iterator.go_to_cell (other.iterator.active)
			end
		end

feature -- Specification

	is_model_equal (other: like Current): BOOLEAN
			-- Is the abstract state of `Current' equal to that of `other'?
		note
			status: ghost, functional, nonvariant
		do
			Result := target = other.target and index_ = other.index_
		end

invariant
	sequence_definition: sequence ~ target.sequence
	iterator_exists: iterator /= Void
	targets_connected: target.list = iterator.target
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
