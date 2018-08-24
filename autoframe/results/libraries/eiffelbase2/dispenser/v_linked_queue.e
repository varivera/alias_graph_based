note
	description: "Linked implementation of queues."
	author: "Nadia Polikarpova"
	model: sequence
	manual_inv: true
	false_guards: true

frozen class
	V_LINKED_QUEUE [G]

inherit
	V_QUEUE [G]
		redefine
			default_create
		end

feature -- Test
	test_copy_ (other: like Current)
		do
			if other /= Current then
				list.copy_ (other.list)
			end
		end

feature {NONE} -- Initialization

	default_create
			-- Create an empty queue.
		do
			create list
		end

feature -- Initialization

	copy_ (other: like Current)
			-- Initialize by copying all the items of `other'.
		note
			modify_model: sequence, Current_
		do
			if other /= Current then
				list.copy_ (other.list)
			end
		end

feature -- Access

	item: G
			-- The top element.
		do
			Result := list.first
		end

feature -- Measurement

	count: INTEGER
			-- Number of elements.
		do
			Result := list.count
		end

feature -- Iteration

	new_cursor: V_LINKED_QUEUE_ITERATOR [G]
			-- New iterator pointing to a position in the container, from which it can traverse all elements by going `forth'.
		do
			create Result.make (Current)
		end

feature -- Comparison

	is_equal_ (other: like Current): BOOLEAN
			-- Is queue made of the same values in the same order as `other'?
			-- (Use reference comparison.)
		do
			Result := list.is_equal_ (other.list)
		end

feature -- Extension

	extend (v: G)
			-- Push `v' on the stack.
		do
			list.extend_back (v)
		end

feature -- Removal

	remove
			-- Pop the top element.
		do
			list.remove_front
		end

	wipe_out
			-- Pop all elements.
		do
			list.wipe_out
		end

feature {V_CONTAINER, V_ITERATOR} -- Implementation

	list: V_LINKED_LIST [G]
			-- Underlying list.
			-- Should not be reassigned after creation.

feature -- Specification


invariant
	list_exists: list /= Void
	sequence_implementation: sequence ~ list.sequence

note
	explicit: observers
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
