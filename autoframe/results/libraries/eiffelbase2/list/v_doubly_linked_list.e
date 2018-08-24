note
	description: "[
		Doubly linked lists.
		Random access takes linear time.
		Once a position is found, inserting or removing elements to the left and right of it takes constant time
		and doesn't require reallocation of other elements.
		]"
	author: "Nadia Polikarpova"
	model: sequence
	manual_inv: true
	false_guards: true

class
	V_DOUBLY_LINKED_LIST [G]

inherit
	V_LIST [G]
		redefine
			first,
			last,
			put,
			prepend,
			reverse
		end

feature -- testing

	test_append (input: V_LIST_ITERATOR [G])
		local
			cell: V_DOUBLY_LINKABLE [G]
		do
			if True then
				from
				until
					True
				loop
					create cell.put (input.item)
--					if True then
						last_cell.connect_right (cell)
--					end
				end
			end
		end


	test_wipe_out
			-- Remove all elements.
		do
			first_cell := Void
			last_cell := Void
			count_ := 0
			create cells
			create sequence
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

feature -- Access

	item alias "[]" (i: INTEGER): G assign put
			-- Value at position `i'.
		do
			Result := cell_at (i).item
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

	at (i: INTEGER): V_DOUBLY_LINKED_LIST_ITERATOR [G]
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
			c1, c2: V_DOUBLY_LINKABLE [G]
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
			rest, next: V_DOUBLY_LINKABLE [G]
			rest_cells: MML_SEQUENCE [V_DOUBLY_LINKABLE [G]]
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
				reverse_step (first_cell, rest, next)
				first_cell := rest
				cells := cells.prepended (first_cell)
				sequence := sequence.prepended (first_cell.item)
				rest := next
				rest_cells := rest_cells.but_first
			variant
				rest_cells.count
			end
		end

feature -- Extension

	extend_front (v: G)
			-- Insert `v' at the front.
		local
			cell: V_DOUBLY_LINKABLE [G]
		do
			create cell.put (v)
			if first_cell = Void then
				last_cell := cell
			else
				cell.connect_right (first_cell)
			end
			first_cell := cell
			count_ := count_ + 1

			cells := cells.prepended (cell)
			sequence := sequence.prepended (v)
		end

	extend_back (v: G)
			-- Insert `v' at the back.
		local
			cell: V_DOUBLY_LINKABLE [G]
		do
			create cell.put (v)
			if first_cell = Void then
				first_cell := cell
			else
				last_cell.connect_right (cell)
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
				extend_after (create {V_DOUBLY_LINKABLE [G]}.put (v), cell_at (i - 1), i - 1)
			end
		end

	prepend (input: V_ITERATOR [G])
			-- Prepend sequence of values, over which `input' iterates.
		local
			it: V_DOUBLY_LINKED_LIST_ITERATOR [G]
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
			it: V_DOUBLY_LINKED_LIST_ITERATOR [G]
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
		local
			second: like first_cell
		do
			if count_ = 1 then
				last_cell := Void
			else
				second := first_cell.right
				second.put_left (Void)
			end
			first_cell := first_cell.right
			count_ := count_ - 1

			cells := cells.but_first
			sequence := sequence.but_first
		end

	remove_back
			-- Remove last element.
		local
			second_last: like first_cell
		do
			if count_ = 1 then
				first_cell := Void
			else
				second_last := last_cell.left
				second_last.put_right (Void)
			end
			last_cell := last_cell.left
			count_ := count_ - 1

			cells := cells.but_last
			sequence := sequence.but_last
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

	first_cell: V_DOUBLY_LINKABLE [G]
			-- First cell of the list.

	last_cell: V_DOUBLY_LINKABLE [G]
			-- Last cell of the list.

	cell_at (i: INTEGER): V_DOUBLY_LINKABLE [G]
			-- Cell at position `i'.
		local
			j: INTEGER
		do
			if i + i <= count_ then
				from
					j := 1
					Result := first_cell
				until
					j = i
				loop
					Result := Result.right
					j := j + 1
				end
			else
				from
					j := count_
					Result := last_cell
				until
					j = i
				loop
					Result := Result.left
					j := j - 1
				end
			end
		end

	put_cell (v: G; c: V_DOUBLY_LINKABLE [G]; index_: INTEGER)
			-- Put `v' into `c' located at `index_'.
		note
			modify_model: sequence, Current_
		do
			c.put (v)
			sequence := sequence.replaced_at (index_, v)
		end

	extend_after (new, c: V_DOUBLY_LINKABLE [G]; index_: INTEGER)
			-- Add a new cell with value `v' after `c'.
		note
			modify_model: sequence, Current_
			modify: new
		do
			if c.right = Void then
				last_cell := new
				c.connect_right (new)
			else
				c.insert_right (new, new)
			end
			count_ := count_ + 1
			cells := cells.extended_at (index_ + 1, new)
			sequence := sequence.extended_at (index_ + 1, new.item)
		end

	remove_after (c: V_DOUBLY_LINKABLE [G]; index_: INTEGER)
			-- Remove the cell to the right of `c'.
		note
			modify_model: sequence, Current_
		do
			if c.right.right = Void then
				c.put_right (Void)
				last_cell := c
			else
				c.remove_right
			end
			count_ := count_ - 1
			cells := cells.removed_at (index_ + 1)
			sequence := sequence.removed_at (index_ + 1)
		end

	merge_after (other: V_DOUBLY_LINKED_LIST [G]; c: V_DOUBLY_LINKABLE [G]; index_: INTEGER)
			-- Merge `other' into `Current' after cell `c'. If `c' is `Void', merge to the front.
		note
			modify_model: sequence, Current_
			modify_model: sequence, other
		local
			other_first, other_last: V_DOUBLY_LINKABLE [G]
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
						other_last.connect_right (first_cell)
					end
					first_cell := other_first
				else
					if c.right = Void then
						last_cell := other_last
						c.connect_right (other_first)
					else
						c.insert_right (other_first, other_last)
					end
				end
				count_ := count_ + other_count
				cells := cells.front (index_) + other.cells + cells.tail (index_ + 1)
				sequence := sequence.front (index_) + other.sequence + sequence.tail (index_ + 1)
			end
		end

feature {NONE} -- Implementation

	reverse_step (head, rest, next: like first_cell)
			-- One step of list reversal, where
			-- `head' is the head of the already reversed statement,
			-- `rest' is the head of the rest of the list,
			-- `next' is `rest.right'.
		note
			--modify_field ("closed", ([head, next]).to_mml_set / Void)
			modify_model: left, right, rest
		do
			rest.put_right (head)
			rest.put_left (next)
		end

feature -- Specificaton

	cells: MML_SEQUENCE [V_DOUBLY_LINKABLE [G]]
			-- Sequence of linakble cells.
		note
			status: ghost
		attribute
		end

feature {V_DOUBLY_LINKED_LIST, V_DOUBLY_LINKED_LIST_ITERATOR} -- Specificaton	

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
	cells_first: cells.count > 0 implies first_cell = cells.first and then first_cell.left = Void
	cells_last: cells.count > 0 implies last_cell = cells.last and then last_cell.right = Void

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
