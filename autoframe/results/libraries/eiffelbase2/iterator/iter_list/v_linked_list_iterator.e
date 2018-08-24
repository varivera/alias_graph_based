note
	description: "Iterators over linked lists."
	author: "Nadia Polikarpova"
	model: target, index_
	manual_inv: true
	false_guards: true

frozen class
	V_LINKED_LIST_ITERATOR [G]

inherit
	V_LIST_ITERATOR [G]
		redefine
			target,
			off
		end

create {V_CONTAINER, V_ITERATOR}
	make

feature -- Test
	test_switch_target (list: V_LINKED_LIST [G])
		do
			target := list
		end

	test_start
		do
			active := target.first_cell
		end

feature {V_CONTAINER, V_ITERATOR} -- Initialization

	make (list: V_LINKED_LIST [G])
			-- Create iterator over `list'.
		note
			modify: Current_
		do
			target := list
			target.add_iterator (Current)
		end

	switch_target (list: V_LINKED_LIST [G])
			-- Set target to `list'.
		note
			modify_model: target, index_, sequence, Current_
		do
			target := list
			active := Void
			after_ := False
			index_ := 0
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
				active := other.active
				index_ := other.index_
				after_ := other.after_
			end
		end

feature -- Access

	target: V_LINKED_LIST [G]
			-- Container to iterate over.

	item: G
			-- Item at current position.
		do
			Result := active.item
		end

feature -- Measurement

	index: INTEGER
			-- Current position.
		do
			if after then
				Result := target.count + 1
			elseif is_last then
				Result := target.count
			elseif active /= Void then
				Result := active_index
			end
		end

feature -- Status report

	off: BOOLEAN
			-- Is current position off scope?
		do
			Result := active = Void
		end

	after: BOOLEAN
			-- Is current position after the last container position?
		do
			Result := after_
		end

	before: BOOLEAN
			-- Is current position before the first container position?
		do
			Result := active = Void and not after_
		end

	is_first: BOOLEAN
			-- Is cursor at the first position?
		do
			Result := active /= Void and active = target.first_cell
		end

	is_last: BOOLEAN
			-- Is cursor at the last position?
		do
			Result := active /= Void and then active = target.last_cell
		end

feature -- Comparison

	is_equal_ (other: like Current): BOOLEAN
			-- Is iterator traversing the same container and is at the same position at `other'?		
		do
			Result := target = other.target and active = other.active and after_ = other.after_
		end

feature -- Cursor movement

	start
			-- Go to the first position.
		do
			active := target.first_cell
			after_ := active = Void
			index_ := 1
		end

	finish
			-- Go to the last position.
		do
			active := target.last_cell
			after_ := False
			index_ := target.sequence.count
		end

	forth
			-- Move one position forward.		
		do
			active := active.right
			index_ := index_ + 1
			after_ := active = Void
		end

	back
			-- Go one position backwards.
		local
			old_active: V_LINKABLE [G]
		do
			if is_first then
				go_before
			else
				old_active := active
				from
					start
				until
					active.right = old_active
				loop
					forth
				end
			end
		end

	go_before
			-- Go before any position of `target'.
		do
			active := Void
			after_ := False
			index_ := 0
		end

	go_after
			-- Go after any position of `target'.
		do
			active := Void
			after_ := True
			index_ := target.count + 1
		end

feature -- Replacement

	put (v: G)
			-- Replace item at current position with `v'.
		do
			target.put_cell (v, active, index_)
		end

feature -- Extension

	extend_left (v: G)
			-- Insert `v' to the left of current position. Do not move cursor.
		note
			explicit: wrapping
		do
			if is_first then
				target.extend_front (v)
				index_ := index_ + 1
			else
				back
				extend_right (v)
				forth
				forth
			end
		end

	extend_right (v: G)
			-- Insert `v' to the right of current position. Do not move cursor.
		do
			target.extend_after (create {V_LINKABLE [G]}.put (v), active, index_)
		end

	insert_left (other: V_ITERATOR [G])
			-- Append sequence of values, over which `input' iterates to the left of current position. Do not move cursor.
		do
			if is_first then
				target.prepend (other)
				index_ := index_ --+ other.sequence.tail (other.index_.old_).count
			else
				back
				insert_right (other)
				forth
			end
		end

	insert_right (other: V_ITERATOR [G])
			-- Append sequence of values, over which `input' iterates to the right of current position. Move cursor to the last element of inserted sequence.
		local
			v: G
			s: like sequence
		do
			from
			until
				other.after
			loop
				v := other.item
				extend_right (v)
				s := s & v
				forth
				other.forth
			variant
				other.sequence.count - other.index_
			end
		end

	merge (other: V_LINKED_LIST [G])
			-- Merge `other' into `target' after current position. Do not copy elements. Empty `other'.
		note
			modify_model: sequence, Current_
			modify_model: sequence, target
			modify_model: sequence, other
		do
			target.merge_after (other, active, index_)
		end

feature -- Removal

	remove
			-- Remove element at current position. Move cursor to the next position.
		do
			if is_first then
				target.remove_front
				active := target.first_cell
				after_ := active = Void
			else
				back
				remove_right
				forth
			end
		end

	remove_left
			-- Remove element to the left of current position. Do not move cursor.
		do
			back
			remove
		end

	remove_right
			-- Remove element to the right of current position. Do not move cursor.
		do
			target.remove_after (active, index_)
		end

feature {V_ITERATOR} -- Implementation

	active: V_LINKABLE [G]
			-- Cell at current position.

	after_: BOOLEAN
			-- Is current position after the last container position?			

	active_index: INTEGER
			-- Distance from `target.first_cell' to `active'.
		local
			c: V_LINKABLE [G]
		do
			from
				c := target.first_cell
				Result := 1
			until
				c = active
			loop
				Result := Result + 1
				c := c.right
			variant
				target.count_ - Result
			end
		end

	go_to_cell (c: V_LINKABLE [G])
			-- Move to cell `c'.
		note
			modify_model: index_, Current_
		do
			active := c
			after_ := False
			index_ := target.cells.index_of (c)
		end

invariant
	after_definition: after_ = (index_ = sequence.count + 1)
	cell_off: (index_ < 1 or sequence.count < index_) = (active = Void)
	target_cells_domain: target.cells.count = sequence.count
	cell_not_off: 1 <= index_ and index_ <= sequence.count implies active = target.cells [index_]
	target_cells_distinct: target.cells.no_duplicates

note
	copyright: "Copyright (c) 1984-2015, Eiffel Software and others"
	license: "Eiffel Forum License v2 (see http://www.eiffel.com/licensing/forum.txt)"
	source: "[
			Eiffel Software
			5949 Hollister Ave., Goleta, CA 93117 USA
			Telephone 805-685-1006, Fax 805-685-6869
			Website http://www.eiffel.com
			Customer support http://support.eiffel.com
		]"
end
