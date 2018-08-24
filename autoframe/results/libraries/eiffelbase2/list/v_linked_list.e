note
	description: "[
		Singly linked lists.
		Random access takes linear time. 
		Once a position is found, inserting or removing elements to the right of it takes constant time 
		and doesn't require reallocation of other elements.
		]"
	author: "Nadia Polikarpova"
	model: sequence
	manual_inv: true
	false_guards: true

frozen class
	V_LINKED_LIST [G]

inherit
	V_LIST [G]
		redefine
			first,
			last,
			new_cursor,
			put,
			prepend,
			reverse
		end

feature -- Testing

	test_reverse
		local
			rest, next: V_LINKABLE [G]
		do
			from
				last_cell := first_cell
				rest := first_cell
				first_cell := Void
			until
				True
			loop
				next := rest.right
				rest.put_right (first_cell)
				first_cell := rest
--				rest := next
			end
		end

	test_test_copy_ (other: V_LIST [G]; i: V_LIST_ITERATOR [G])
		local

		do
			if True then
				--i := other.new_cursor
				ttest_append (i)
			end
		end

	ttest_append (input: V_ITERATOR [G])
		do
			from
			until
				True
			loop
				input.forth
			end
		end


	test_new_cursor_hhh: V_LINKED_LIST_ITERATOR [G]
			-- New iterator pointing to the first position.
		do
			Result := at (1)
		end

	ttt (v: G)
		local
		do
			if not attached first_cell then
				create first_cell.put (v)
			else
				first_cell.put (v)
			end
		end

	tes2_new_cursor
		local
			t: like at
			-- New iterator pointing to the first position.
		do
			create t.make (Current)
			--t.start
		end

	test_new_cursor: like at
			-- New iterator pointing to the first position.
		do
			create Result.make (Current)
			Result.start
		end

feature -- Initialization

	copy_ (other: V_LIST [G])
			-- Initialize by copying all the items of `other'.
		note
			modify_model: sequence, Current_
		local
			i: V_LIST_ITERATOR [G]
		do
			if other /= Current then
				wipe_out
				i := other.new_cursor
				append (i)
			end
		end

	test_copy_ (other: V_LINKED_LIST [G])
		-- Initialize by copying all the items of `other'.
			note
				modify_model: sequence, Current_
			local
				i: V_LIST_ITERATOR [G]
			do
				if other /= Current then
					wipe_out
					--i := other.new_cursor
					--append (i)
				end
			end

feature -- Access

	item alias "[]" (i: INTEGER): G assign put
			-- Value at position `i'.
		do
			if i = count then
				Result := last
			else
				Result := cell_at (i).item
			end
		end

	first: G
			-- First element.
		do
			Result := first_cell.item
		end

	last: G
			-- Last element.
		do
			Result := last_cell.item
		end

feature -- Iteration

	new_cursor: like at
			-- New iterator pointing to the first position.
		do
			create Result.make (Current)
			Result.start
		end

	at (i: INTEGER): V_LINKED_LIST_ITERATOR [G]
			-- New iterator pointing at position `i'.
		do
			create Result.make (Current)
			if i < 1 then
				Result.go_before
			elseif i > count then
				Result.go_after
			else
				Result.go_to (i)
			end
		end

feature -- Comparison

	is_equal_ (other: like Current): BOOLEAN
			-- Is list made of the same values in the same order as `other'?
			-- (Use reference comparison.)
		local
			c1, c2: V_LINKABLE [G]
			i_: INTEGER
		do
			if other = Current then
				Result := True
			elseif count = other.count then
				from
					Result := True
					c1 := first_cell
					c2 := other.first_cell
					i_ := 1
				until
					c1 = Void or not Result
				loop
					Result := c1.item = c2.item
					c1 := c1.right
					c2 := c2.right
					i_ := i_ + 1
				variant
					sequence.count - i_
				end
			end
		end

feature -- Replacement

	put (v: G; i: INTEGER)
			-- Associate `v' with index `i'.
		do
			put_cell (v, cell_at (i), i)
		end

	reverse
			-- Reverse the order of elements.
		local
			rest, next: V_LINKABLE [G]
			rest_cells: MML_SEQUENCE [V_LINKABLE [G]]
		do
			from
				last_cell := first_cell
				rest := first_cell
				rest_cells := cells
				first_cell := Void
				create cells
				create sequence
			until
				rest = Void
			loop
				next := rest.right
				rest.put_right (first_cell)
				first_cell := rest
				cells := cells.prepended (first_cell)
				sequence := sequence.prepended (first_cell.item)
				rest := next
				rest_cells := rest_cells.but_first
			end
		end

feature -- Extension

	extend_front (v: G)
			-- Insert `v' at the front.
		local
			cell: V_LINKABLE [G]
		do
			create cell.put (v)
			if first_cell = Void then
				last_cell := cell
			else
				cell.put_right (first_cell)
			end
			first_cell := cell
			count_ := count_ + 1

			cells := cells.prepended (cell)
			sequence := sequence.prepended (v)
		end

	extend_back (v: G)
			-- Insert `v' at the back.
		local
			cell: V_LINKABLE [G]
		do
			create cell.put (v)
			if first_cell = Void then
				first_cell := cell
			else
				last_cell.put_right (cell)
			end
			last_cell := cell
			count_ := count_ + 1

			cells := cells & cell
			sequence := sequence & v
		end

	extend_at (v: G; i: INTEGER)
			-- Insert `v' at position `i'.
		do
			if i = 1 then
				extend_front (v)
			elseif i = count + 1 then
				extend_back (v)
			else
				extend_after (create {V_LINKABLE [G]}.put (v), cell_at (i - 1), i - 1)
			end
		end

	prepend (input: V_ITERATOR [G])
			-- Prepend sequence of values, over which `input' iterates.
		local
			it: V_LINKED_LIST_ITERATOR [G]
		do
			if not input.after then
				extend_front (input.item)
				input.forth

				from
					it := new_cursor
				until
					input.after
				loop
					it.extend_right (input.item)
					it.forth
					input.forth
				variant
					input.sequence.count - input.index_
				end
			end
		end

	insert_at (input: V_ITERATOR [G]; i: INTEGER)
			-- Insert sequence of values, over which `input' iterates, starting at position `i'.
		local
			it: V_LINKED_LIST_ITERATOR [G]
			s: like sequence
		do
			if i = 1 then
				prepend (input)
			else
				from
					it := at (i - 1)
				until
					input.after
				loop
					it.extend_right (input.item)
					s := s & input.item
					it.forth
					input.forth
				variant
					input.sequence.count - input.index_
				end
			end
		end

feature -- Removal

	remove_front
			-- Remove first element.
		do
			if count_ = 1 then
				last_cell := Void
			end
			first_cell := first_cell.right
			count_ := count_ - 1

			cells := cells.but_first
			sequence := sequence.but_first
		end

	remove_back
			-- Remove last element.
		do
			if count = 1 then
				wipe_out
			else
				remove_after (cell_at (count - 1), count - 1)
			end
		end

	remove_at  (i: INTEGER)
			-- Remove element at position `i'.
		do
			if i = 1 then
				remove_front
			else
				remove_after (cell_at (i - 1), i - 1)
			end
		end

	wipe_out
			-- Remove all elements.
		do
			first_cell := Void
			last_cell := Void
			count_ := 0
			create cells
			create sequence
		end

feature {V_CONTAINER, V_ITERATOR} -- Implementation

	first_cell: V_LINKABLE [G]
			-- First cell of the list.

	last_cell: V_LINKABLE [G]
			-- Last cell of the list.

	cell_at (i: INTEGER): V_LINKABLE [G]
			-- Cell at position `i'.
		local
			j: INTEGER
		do
			from
				j := 1
				Result := first_cell
			until
				j = i
			loop
				Result := Result.right
				j := j + 1
			end
		end

	put_cell (v: G; c: V_LINKABLE [G]; index_: INTEGER)
			-- Put `v' into `c' located at `index_'.
		note
			modify_model: sequence, Current_
		do
			c.put (v)
			sequence := sequence.replaced_at (index_, v)
		end

	extend_after (new, c: V_LINKABLE [G]; index_: INTEGER)
			-- Add a new cell with value `v' after `c'.
		note
			modify_model: sequence, Current_
			modify_model: right, new_
		do
			if c.right = Void then
				last_cell := new
			else
				new.put_right (c.right)
			end
			c.put_right (new)
			count_ := count_ + 1

			cells := cells.extended_at (index_ + 1, new)
			sequence := sequence.extended_at (index_ + 1, new.item)
		end

	remove_after (c: V_LINKABLE [G]; index_: INTEGER)
			-- Remove the cell to the right of `c'.
		note
			modify_model: sequence, Current_
		do
			c.put_right (c.right.right)
			if c.right = Void then
				last_cell := c
			end
			count_ := count_ - 1

			cells := cells.removed_at (index_ + 1)
			sequence := sequence.removed_at (index_ + 1)
		end

	merge_after (other: V_LINKED_LIST [G]; c: V_LINKABLE [G]; index_: INTEGER)
			-- Merge `other' into `Current' after cell `c'. If `c' is `Void', merge to the front.
		note
			modify_model: sequence, Current_
			modify_model: sequence, other
		local
			other_first, other_last: V_LINKABLE [G]
			other_count: INTEGER
		do
			if other.count_ > 0 then
				other_first := other.first_cell
				other_last := other.last_cell
				other_count := other.count_
				other.wipe_out

				if c = Void then
					if first_cell = Void then
						last_cell := other_last
					else
						other_last.put_right (first_cell)
					end
					first_cell := other_first
				else
					if c.right = Void then
						last_cell := other_last
					else
						other_last.put_right (c.right)
					end
					c.put_right (other_first)
				end
				count_ := count_ + other_count
				cells := cells.front (index_) + other.cells + cells.tail (index_ + 1)
				sequence := sequence.front (index_) + other.sequence + sequence.tail (index_ + 1)
			end
		end

feature -- Specificaton

	cells: MML_SEQUENCE [V_LINKABLE [G]]
			-- Sequence of linakble cells.
		note
			status: ghost
		attribute
		end

feature {V_CONTAINER, V_ITERATOR} -- Specificaton	

	is_linked (cs: like cells): BOOLEAN
			-- Are adjacent cells of `cs' liked to each other?
		do
			Result := across 1 |..| cs.count as i all
				across 1 |..| cs.count as j all
					i.item + 1 = j.item implies cs [i.item].right = cs [j.item] end end
		end

invariant
	cells_domain: sequence.count = cells.count
	first_cell_empty: cells.is_empty = (first_cell = Void)
	last_cell_empty: cells.is_empty = (last_cell = Void)
	cells_exist: cells.non_void
	sequence_implementation: across 1 |..| cells.count as i all sequence [i.item] = cells [i.item].item end
	cells_linked: is_linked (cells)
	cells_first: cells.count > 0 implies first_cell = cells.first
	cells_last: cells.count > 0 implies last_cell = cells.last and then last_cell.right = Void

note
	explicit: observers
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
