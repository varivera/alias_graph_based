class
	FLAT_LINKED_STACK [G]

inherit
	ANY
		redefine
			copy,
			is_equal
		end

create
	make

feature -- Initialization

	make
			-- Create an empty list.
			-- (from LINKED_LIST)
		do
			before := True
		ensure -- from LINKED_LIST
			is_before: before
		end

feature -- Access

	has (v: like item): BOOLEAN
			-- Does chain include `v'?
			-- (Reference or object equality,
			-- based on object_comparison.)
			-- (from CHAIN)
		require -- from  CONTAINER
			True
		local
			pos: FLAT_CURSOR
		do
			pos := cursor
			Result := sequential_has (v)
			go_to (pos)
		ensure -- from CONTAINER
			not_found_in_empty: Result implies not is_empty
		end

	item: G
			-- Item at the first position
		require -- from ACTIVE
			readable: readable
		local
			f: like first_element
		do
			check
				not_empty: not is_empty
			end
			f := first_element
			check
				f_attached: f /= Void
			end
			Result := f.item
		end

feature {FLAT_LINKED_STACK} -- Access

	cursor: FLAT_LINKED_LIST_CURSOR [G]
			-- Current cursor position
			-- (from LINKED_LIST)
		do
			create Result.make (active, after, before)
		ensure -- from CURSOR_STRUCTURE
			cursor_not_void: Result /= Void
		end

	first_element: like new_cell
			-- Head of list
			-- (from LINKED_LIST)

	index: INTEGER_32
			-- Index of current position
			-- (from LINKED_LIST)
		local
			l_active, l_active_iterator: like active
		do
			if after then
				Result := count + 1
			elseif not before then
				from
					Result := 1
					l_active := active
					l_active_iterator := first_element
				until
					l_active_iterator = l_active or else l_active_iterator = Void
				loop
					l_active_iterator := l_active_iterator.right
					Result := Result + 1
				end
			end
		end

	ll_item: G
			-- Current item
			-- (from LINKED_LIST)
		require -- from TRAVERSABLE
			not_off: not off
--		require -- from ACTIVE
--			readable: readable
		local
			a: like active
		do
			a := active
			check
				a_attached: a /= Void
			end
			Result := a.item
		end

feature {NONE} -- Access

	first: like item
			-- Item at first position
			-- (from LINKED_LIST)
		require -- from CHAIN
			not_empty: not is_empty
		local
			f: like first_element
		do
			f := first_element
			check
				f_attached: f /= Void
			end
			Result := f.item
		end

	sequential_has (v: like ll_item): BOOLEAN
			-- Does structure include an occurrence of `v'?
			-- (Reference or object equality,
			-- based on object_comparison.)
			-- (from LINEAR)
		require -- from  CONTAINER
			True
		do
			start
			if not off then
				search (v)
			end
			Result := not exhausted
		ensure -- from CONTAINER
			not_found_in_empty: Result implies not is_empty
		end

	i_th alias "[]" (i: INTEGER_32): like item
			-- Item at `i'-th position
			-- Was declared in CHAIN as synonym of at.
			-- (from CHAIN)
		require -- from TABLE
			valid_key: valid_index (i)
		local
			pos: FLAT_CURSOR
		do
			pos := cursor
			go_i_th (i)
			Result := item
			go_to (pos)
		end

	index_of (v: like item; i: INTEGER_32): INTEGER_32
			-- Index of `i'-th occurrence of item identical to `v'.
			-- (Reference or object equality,
			-- based on object_comparison.)
			-- 0 if none.
			-- (from CHAIN)
		require -- from LINEAR
			positive_occurrences: i > 0
		local
			pos: FLAT_CURSOR
		do
			pos := cursor
			Result := sequential_index_of (v, i)
			go_to (pos)
		ensure -- from LINEAR
			non_negative_result: Result >= 0
		end

	sequential_index_of (v: like ll_item; i: INTEGER_32): INTEGER_32
			-- Index of `i'-th occurrence of `v'.
			-- 0 if none.
			-- (Reference or object equality,
			-- based on object_comparison.)
			-- (from LINEAR)
		require -- from LINEAR
			positive_occurrences: i > 0
		local
			occur, pos: INTEGER_32
		do
			if object_comparison and v /= Void then
				from
					start
					pos := 1
				until
					exhausted or (occur = i)
				loop
					if ll_item ~ v then
						occur := occur + 1
					end
					forth
					pos := pos + 1
				end
			else
				from
					start
					pos := 1
				until
					exhausted or (occur = i)
				loop
					if ll_item = v then
						occur := occur + 1
					end
					forth
					pos := pos + 1
				end
			end
			if occur = i then
				Result := pos - 1
			end
		ensure -- from LINEAR
			non_negative_result: Result >= 0
		end

	item_for_iteration: G
			-- Item at current position
			-- (from LINEAR)
		require -- from LINEAR
			not_off: not off
		do
			Result := ll_item
		end

	last: like item
			-- Item at last position
			-- (from LINKED_LIST)
		require -- from CHAIN
			not_empty: not is_empty
		local
			l: like last_element
		do
			l := last_element
			check
				l_attached: l /= Void
			end
			Result := l.item
		end

	sequential_occurrences (v: like ll_item): INTEGER_32
			-- Number of times `v' appears.
			-- (Reference or object equality,
			-- based on object_comparison.)
			-- (from LINEAR)
		require -- from  BAG
			True
		do
			from
				start
				search (v)
			until
				exhausted
			loop
				Result := Result + 1
				forth
				search (v)
			end
		ensure -- from BAG
			non_negative_occurrences: Result >= 0
		end

	sequential_search (v: like ll_item)
			-- Move to first position (at or after current
			-- position) where item and `v' are equal.
			-- (Reference or object equality,
			-- based on object_comparison.)
			-- If no such position ensure that exhausted will be true.
			-- (from LINEAR)
		do
			if object_comparison then
				from
				until
					exhausted or else v ~ ll_item
				loop
					forth
				end
			else
				from
				until
					exhausted or else v = ll_item
				loop
					forth
				end
			end
		ensure -- from LINEAR
			object_found: (not exhausted and object_comparison) implies v ~ ll_item
			item_found: (not exhausted and not object_comparison) implies v = ll_item
		end

feature -- Measurement

	count: INTEGER_32
			-- Number of items
			-- (from LINKED_LIST)

	occurrences (v: like item): INTEGER_32
			-- Number of times `v' appears.
			-- (Reference or object equality,
			-- based on object_comparison.)
			-- (from CHAIN)
		local
			pos: FLAT_CURSOR
		do
			pos := cursor
			Result := sequential_occurrences (v)
			go_to (pos)
		ensure -- from BAG
			non_negative_occurrences: Result >= 0
		end

feature {NONE} -- Measurement

	index_set: FLAT_INTEGER_INTERVAL
			-- Range of acceptable indexes
			-- (from CHAIN)
		do
			create Result.make (1, count)
		ensure -- from READABLE_INDEXABLE
			not_void: Result /= Void
--		ensure then -- from CHAIN
			count_definition: Result.count = count
		end

feature -- Comparison

	is_equal (other: FLAT_LINKED_STACK [G]): BOOLEAN
			-- Does `other' contain the same elements?
			-- (from LIST)
		do
			if Current = other then
				Result := True
			else
				Result := (is_empty = other.is_empty) and (object_comparison = other.object_comparison) and (count = other.count)
				if Result and not is_empty then
					if attached {FLAT_CURSOR} cursor as c1 and then attached {FLAT_CURSOR} other.cursor as c2 then
						from
							start
							other.start
						until
							after or not Result
						loop
							if object_comparison then
								Result := item ~ other.item
							else
								Result := item = other.item
							end
							forth
							other.forth
						end
						go_to (c1)
						other.go_to (c2)
					else
						check
							cursors_exist: False
						end
					end
				elseif is_empty and other.is_empty and object_comparison = other.object_comparison then
					Result := True
				end
			end
		ensure then -- from LIST
			indices_unchanged: index = old index and other.index = old other.index
			true_implies_same_size: Result implies count = other.count
		end

feature -- Status report

	changeable_comparison_criterion: BOOLEAN
			-- May object_comparison be changed?
			-- (Answer: yes by default.)
			-- (from CONTAINER)
		do
			Result := True
		end

	extendible: BOOLEAN
			-- May new items be added? (Answer: yes.)
			-- (from DYNAMIC_CHAIN)
		require -- from  COLLECTION
			True
		do
			Result := True
		end

	Full: BOOLEAN = False
			-- Is structured filled to capacity? (Answer: no.)
			-- (from LINKED_LIST)

	is_empty: BOOLEAN
			-- Is structure empty?
			-- (from FINITE)
		require -- from  CONTAINER
			True
		do
			Result := (count = 0)
		end

	is_inserted (v: G): BOOLEAN
			-- Has `v' been inserted by the most recent insertion?
			-- (By default, the value returned is equivalent to calling
			-- `has (v)'. However, descendants might be able to provide more
			-- efficient implementations.)
			-- (from COLLECTION)
		do
			Result := has (v)
		end

	object_comparison: BOOLEAN
			-- Must search operations use equal rather than `='
			-- for comparing references? (Default: no, use `='.)
			-- (from CONTAINER)

	prunable: BOOLEAN
			-- May items be removed? (Answer: yes.)
			-- (from DYNAMIC_CHAIN)
		require -- from  COLLECTION
			True
		do
			Result := True
		end

	readable: BOOLEAN
			-- Is there a current item that may be read?
			-- (from DISPENSER)
		require -- from  ACTIVE
			True
		do
			Result := not is_empty
		end

	replaceable: BOOLEAN
			-- Can current item be replaced?
			-- (from ACTIVE)
		do
			Result := True
		end

	writable: BOOLEAN
			-- Is there a current item that may be modified?
			-- (from DISPENSER)
		require -- from  ACTIVE
			True
		do
			Result := not is_empty
		end

feature {FLAT_LINKED_STACK} -- Status report

	before: BOOLEAN
			-- Is there no valid cursor position to the left of cursor?
			-- (from LINKED_LIST)

	exhausted: BOOLEAN
			-- Has structure been completely explored?
			-- (from LINEAR)
		do
			Result := off
		ensure -- from LINEAR
			exhausted_when_off: off implies Result
		end

	isfirst: BOOLEAN
			-- Is cursor at first position?
			-- (from LINKED_LIST)
		do
			Result := not after and not before and (active = first_element)
		ensure -- from CHAIN
			valid_position: Result implies not is_empty
		end

	islast: BOOLEAN
			-- Is cursor at last position?
			-- (from LINKED_LIST)
		local
			a: like active
		do
			if not after and then not before then
				a := active
				Result := a /= Void and then a.right = Void
			end
		ensure -- from CHAIN
			valid_position: Result implies not is_empty
		end

	valid_cursor_index (i: INTEGER_32): BOOLEAN
			-- Is `i' correctly bounded for cursor movement?
			-- (from CHAIN)
		do
			Result := (i >= 0) and (i <= count + 1)
		ensure -- from CHAIN
			valid_cursor_index_definition: Result = ((i >= 0) and (i <= count + 1))
		end

	valid_index (i: INTEGER_32): BOOLEAN
			-- Is `i' within allowable bounds?
			-- (from CHAIN)
		do
			Result := (i >= 1) and (i <= count)
		ensure -- from READABLE_INDEXABLE
			only_if_in_index_set: Result implies ((i >= index_set.lower) and (i <= index_set.upper))
--		ensure then -- from CHAIN
			valid_index_definition: Result = ((i >= 1) and (i <= count))
		end

feature {FLAT_LINKED_STACK} -- Status report

	after: BOOLEAN
			-- Is there no valid cursor position to the right of cursor?
			-- (from LINKED_LIST)

	off: BOOLEAN
			-- Is there no current item?
			-- (from LINKED_LIST)
		require -- from  TRAVERSABLE
			True
		do
			Result := after or before
		end

	valid_cursor (p: FLAT_CURSOR): BOOLEAN
			-- Can the cursor be moved to position `p'?
			-- (from LINKED_LIST)
		local
			temp, sought: like first_element
		do
			if attached {like cursor} p as ll_c then
				from
					temp := first_element
					sought ?= ll_c.active
					Result := ll_c.after or else ll_c.before
				until
					Result or else temp = Void
				loop
					Result := (temp = sought)
					temp := temp.right
				end
			end
		end

feature -- Status setting

	compare_objects
			-- Ensure that future search operations will use equal
			-- rather than `=' for comparing references.
			-- (from CONTAINER)
		require -- from CONTAINER
			changeable_comparison_criterion: changeable_comparison_criterion
		do
			object_comparison := True
		ensure -- from CONTAINER
			object_comparison
		end

	compare_references
			-- Ensure that future search operations will use `='
			-- rather than equal for comparing references.
			-- (from CONTAINER)
		require -- from CONTAINER
			changeable_comparison_criterion: changeable_comparison_criterion
		do
			object_comparison := False
		ensure -- from CONTAINER
			reference_comparison: not object_comparison
		end

feature {FLAT_LINKED_STACK} -- Cursor movement

	forth
			-- Move cursor to next position.
			-- (from LINKED_LIST)
		require -- from LINEAR
			not_after: not after
		local
			a: like active
		do
			if before then
				before := False
				if is_empty then
					after := True
				end
			else
				a := active
				if a /= Void and then a.right /= Void then
					active := a.right
				else
					after := True
				end
			end
		ensure then -- from LIST
			moved_forth: index = old index + 1
		end

	go_to (p: FLAT_CURSOR)
			-- Move cursor to position `p'.
			-- (from LINKED_LIST)
		require -- from CURSOR_STRUCTURE
			cursor_position_valid: valid_cursor (p)
		do
			if attached {like cursor} p as ll_c then
				after := ll_c.after
				before := ll_c.before
				if before then
					active := first_element
				elseif after then
					active := last_element
				else
					active ?= ll_c.active
				end
			else
				check
					correct_cursor_type: False
				end
			end
		end

	start
			-- Move cursor to first position.
			-- (from LINKED_LIST)
		do
			if first_element /= Void then
				active := first_element
				after := False
			else
				after := True
			end
			before := False
		ensure then -- from CHAIN
			at_first: not is_empty implies isfirst
--		ensure then -- from LINKED_LIST
			empty_convention: is_empty implies after
		end

	back
			-- Move to previous item.
			-- (from LINKED_LIST)
		require -- from BILINEAR
			not_before: not before
		do
			if is_empty then
				before := True
				after := False
			elseif after then
				after := False
			elseif isfirst then
				before := True
			else
				active := previous
			end
		end

	finish
			-- Move cursor to last position.
			-- (Go before if empty)
			-- (from LINKED_LIST)
		require -- from  LINEAR
			True
		local
			p: like new_cell
		do
			from
				p := active
			until
				p = Void
			loop
				active := p
				p := p.right
			end
			after := False
			before := (active = Void)
		ensure then -- from CHAIN
			at_last: not is_empty implies islast
--		ensure then -- from LINKED_LIST
			empty_convention: is_empty implies before
		end

	go_i_th (i: INTEGER_32)
			-- Move cursor to `i'-th position.
			-- (from LINKED_LIST)
		require -- from CHAIN
			valid_cursor_index: valid_cursor_index (i)
		do
			if i = 0 then
				before := True
				after := False
				active := first_element
			elseif i = count + 1 then
				before := False
				after := True
				active := last_element
			else
				move (i - index)
			end
		ensure -- from CHAIN
			position_expected: index = i
		end

	move (i: INTEGER_32)
			-- Move cursor `i' positions. The cursor
			-- may end up off if the offset is too big.
			-- (from LINKED_LIST)
		require -- from  CHAIN
			True
		local
			counter, new_index: INTEGER_32
			p: like first_element
		do
			if i > 0 then
				if before then
					before := False
					counter := 1
				end
				from
					p := active
				until
					(counter = i) or else (p = Void)
				loop
					active := p
					p := p.right
					counter := counter + 1
				end
				if p = Void then
					after := True
				else
					active := p
				end
			elseif i < 0 then
				new_index := index + i
				before := True
				after := False
				active := first_element
				if (new_index > 0) then
					move (new_index)
				end
			end
		ensure -- from CHAIN
			too_far_right: (old index + i > count) implies exhausted
			too_far_left: (old index + i < 1) implies exhausted
			expected_index: (not exhausted) implies (index = old index + i)
--		ensure then -- from LINKED_LIST
			moved_if_inbounds: ((old index + i) >= 0 and (old index + i) <= (count + 1)) implies index = (old index + i)
			before_set: (old index + i) <= 0 implies before
			after_set: (old index + i) >= (count + 1) implies after
		end

	search (v: like ll_item)
			-- Move to first position (at or after current
			-- position) where item and `v' are equal.
			-- If structure does not include `v' ensure that
			-- exhausted will be true.
			-- (Reference or object equality,
			-- based on object_comparison.)
			-- (from BILINEAR)
		do
			if before and not is_empty then
				forth
			end
			sequential_search (v)
		ensure -- from LINEAR
			object_found: (not exhausted and object_comparison) implies v ~ ll_item
			item_found: (not exhausted and not object_comparison) implies v = ll_item
		end

feature -- Element change

	append (s: FLAT_DYNAMIC_LIST [G])
			-- Append a copy of `s'.
			-- (Synonym for fill)
			-- (from DISPENSER)
		require -- from SEQUENCE
			argument_not_void: s /= Void
--		require -- from DISPENSER
--			s_not_void: s /= Void
--			extendible: extendible
		do
			fill (s)
		ensure -- from SEQUENCE
			new_count: count >= old count
		end

	extend (v: like item)
			-- Push `v' onto top.
		require -- from COLLECTION
			extendible: extendible
		do
			put_front (v)
		ensure -- from COLLECTION
			item_inserted: is_inserted (v)
--		ensure then -- from STACK
			item_pushed: item = v
		end

	fill (other: FLAT_DYNAMIC_LIST [G])
			-- Fill with as many items of `other' as possible.
			-- Fill items with greatest index from `other' first.
			-- Items inserted with lowest index (from `other') will
			-- always be on the top of stack.
			-- The representations of `other' and current structure
			-- need not be the same.
			-- (from STACK)
		require -- from COLLECTION
			other_not_void: other /= Void
			extendible: extendible
		local
			temp: ARRAYED_STACK [G]
		do
			create temp.make (0)
			from
				other.start
			until
				other.off
			loop
				temp.extend (other.item)
				other.forth
			end
			from
			until
				temp.is_empty or else not extendible
			loop
				extend (temp.item)
				temp.remove
			end
		end

	force (v: like item)
			-- Push `v' onto top.
		require -- from DISPENSER
			extendible: extendible
		do
			put_front (v)
		ensure -- from DISPENSER
			item_inserted: is_inserted (v)
--		ensure then -- from STACK
			item_pushed: item = v
--		ensure then -- from SEQUENCE
			new_count: count = old count + 1
			item_inserted: has (v)
		end

	put (v: like item)
			-- Push `v' onto top.
		require -- from COLLECTION
			extendible: extendible
		do
			put_front (v)
		ensure -- from COLLECTION
			item_inserted: is_inserted (v)
--		ensure then -- from STACK
			item_pushed: item = v
		end

	replace (v: like item)
			-- Replace current item by `v'.
			-- (from LINKED_LIST)
		require -- from ACTIVE
			writable: writable
			replaceable: replaceable
		local
			a: like active
		do
			a := active
			if a /= Void then
				a.put (v)
			end
		ensure -- from ACTIVE
			item_replaced: item = v
		end

feature {FLAT_LINKED_STACK} -- Element change

	put_front (v: like item)
			-- Add `v' to beginning.
			-- Do not move cursor.
			-- (from LINKED_LIST)
		require -- from DYNAMIC_CHAIN
			extendible: extendible
		local
			p: like new_cell
		do
			p := new_cell (v)
			p.put_right (first_element)
			first_element := p
			if before or is_empty then
				active := p
			end
			count := count + 1
		ensure -- from DYNAMIC_CHAIN
			new_count: count = old count + 1
			item_inserted: first = v
		end

	put_right (v: like item)
			-- Add `v' to the right of cursor position.
			-- Do not move cursor.
			-- (from LINKED_LIST)
		require -- from DYNAMIC_CHAIN
			extendible: extendible
			not_after: not after
		local
			p: like new_cell
			a: like active
		do
			p := new_cell (v)
			check
				is_empty implies before
			end
			if before then
				p.put_right (first_element)
				first_element := p
				active := p
			else
				a := active
				if a /= Void then
					p.put_right (a.right)
					a.put_right (p)
				end
			end
			count := count + 1
		ensure -- from DYNAMIC_CHAIN
			new_count: count = old count + 1
			same_index: index = old index
--		ensure then -- from LINKED_LIST
			next_exists: next /= Void
			item_inserted: not old before implies (attached next as n and then n.item = v)
			item_inserted_before: old before implies (attached active as c and then c.item = v)
		end

feature -- Removal

	remove
			-- Remove item on top.
		require -- from ACTIVE
			prunable: prunable
			writable: writable
		do
			start
			ll_remove
		end

	wipe_out
			-- Remove all items.
			-- (from LINKED_LIST)
		require -- from COLLECTION
			prunable: prunable
		do
			internal_wipe_out
		ensure -- from COLLECTION
			wiped_out: is_empty
--		ensure then -- from DYNAMIC_LIST
			is_before: before
		end

feature {NONE} -- Removal

	ll_remove
			-- Remove current item.
			-- Move cursor to right neighbor
			-- (or after if no right neighbor).
			-- (from LINKED_LIST)
		require -- from ACTIVE
			prunable: prunable
			writable: writable
		local
			succ: like first_element
			removed: like active
			a: like active
			p: like previous
		do
			removed := active
			if removed /= Void then
				if isfirst then
					first_element := removed.right
					removed.forget_right
					active := first_element
					if count = 1 then
						check
							no_active: active = Void
						end
						after := True
					end
				elseif islast then
					active := previous
					a := active
					if a /= Void then
						a.forget_right
					end
					after := True
				else
					succ := removed.right
					p := previous
					if p /= Void then
						p.put_right (succ)
					end
					removed.forget_right
					active := succ
				end
				count := count - 1
				cleanup_after_remove (removed)
			end
		ensure then -- from DYNAMIC_LIST
			after_when_empty: is_empty implies after
		end

feature -- Conversion

	linear_representation: FLAT_ARRAYED_LIST [G]
			-- Representation as a linear structure
			-- (order is reverse of original order of insertion)
		require -- from  CONTAINER
			True
		local
			old_cursor: FLAT_CURSOR
		do
			old_cursor := cursor
			from
				create Result.make (count)
				start
			until
				after
			loop
				Result.extend (ll_item)
				forth
			end
			go_to (old_cursor)
		end

feature -- Duplication

	copy (other: FLAT_LINKED_STACK [G])
			-- Update current object using fields of object attached
			-- to `other', so as to yield equal objects.
			-- (from LINKED_LIST)
		local
			cur: FLAT_LINKED_LIST_CURSOR [G]
		do
			if other /= Current then
				standard_copy (other)
				if not other.is_empty then
					internal_wipe_out
					if attached {FLAT_LINKED_LIST_CURSOR [G]} other.cursor as l_cur then
						cur := l_cur
					end
					from
						other.start
					until
						other.off
					loop
						extend (other.item)
						finish
						other.forth
					end
					if cur /= Void then
						other.go_to (cur)
					end
				end
			end
		end

	duplicate (n: INTEGER_32): like Current
			-- New stack containing the `n' latest items inserted
			-- in current stack.
			-- If `n' is greater than count, identical to current stack.
		require -- from CHAIN
			valid_subchain: n >= 0
		local
			counter: INTEGER_32
			old_cursor: FLAT_CURSOR
			list: FLAT_LINKED_STACK [G]
		do
			if not is_empty then
				old_cursor := cursor
				from
					create Result.make
					list := Result
					start
				until
					after or counter = n
				loop
					list.finish
					list.put_right (ll_item)
					counter := counter + 1
					forth
				end
				go_to (old_cursor)
			end
		end

feature {NONE} -- Implementation

	active: like first_element
			-- Element at cursor position
			-- (from LINKED_LIST)

	cleanup_after_remove (v: like first_element)
			-- Clean-up a just removed cell.
			-- (from LINKED_LIST)
		require -- from LINKED_LIST
			non_void_cell: v /= Void
		do
		end

	frozen internal_wipe_out
			-- Remove all items.
			-- (from LINKED_LIST)
		require -- from LINKED_LIST
			prunable
		do
			active := Void
			first_element := Void
			before := True
			after := False
			count := 0
		ensure -- from LINKED_LIST
			wiped_out: is_empty
			is_before: before
		end

	new_cell (v: like item): FLAT_LINKABLE [like item]
			-- A newly created instance of the same type as first_element.
			-- This feature may be redefined in descendants so as to
			-- produce an adequately allocated and initialized object.
			-- (from LINKED_LIST)
		do
			create Result.put (v)
		ensure -- from LINKED_LIST
			result_exists: Result /= Void
		end

	new_chain: FLAT_LINKED_STACK [G]
			-- A newly created instance of the same type.
			-- This feature may be redefined in descendants so as to
			-- produce an adequately allocated and initialized object.
			-- (from LINKED_LIST)
		do
			create Result.make
		ensure -- from DYNAMIC_CHAIN
			result_exists: Result /= Void
		end

	next: like first_element
			-- Element right of cursor
			-- (from LINKED_LIST)
		local
			a: like active
		do
			if before then
				Result := active
			else
				a := active
				if a /= Void then
					Result := a.right
				end
			end
		end

	previous: like first_element
			-- Element left of cursor
			-- (from LINKED_LIST)
		local
			p: like first_element
		do
			if after then
				Result := active
			elseif not (isfirst or before) then
				from
					p := first_element
				until
					p = Void or else p.right = active
				loop
					p := p.right
				end
				Result := p
			end
		end

feature {FLAT_LINKED_STACK} -- Implementation

	last_element: like first_element
			-- Tail of list
			-- (from LINKED_LIST)
		local
			p: like first_element
		do
			from
				p := active
			until
				p = Void
			loop
				Result := p
				p := p.right
			end
		end

invariant
		-- from DISPENSER
	readable_definition: readable = not is_empty
	writable_definition: writable = not is_empty

		-- from ACTIVE
	writable_constraint: writable implies readable
	empty_constraint: is_empty implies (not readable) and (not writable)

		-- from FINITE
	empty_definition: is_empty = (count = 0)

		-- from LINKED_LIST
	prunable: prunable
	empty_constraint: is_empty implies ((first_element = Void) and (active = Void))
	not_void_unless_empty: (active = Void) implies is_empty
	before_constraint: before implies (active = first_element)
	after_constraint: after implies (active = last_element)

		-- from LIST
	before_definition: before = (index = 0)
	after_definition: after = (index = count + 1)

		-- from CHAIN
	non_negative_index: index >= 0
	index_small_enough: index <= count + 1
	off_definition: off = ((index = 0) or (index = count + 1))
	isfirst_definition: isfirst = ((not is_empty) and (index = 1))
	islast_definition: islast = ((not is_empty) and (index = count))
	item_corresponds_to_index: (not off) implies (item = i_th (index))
	index_set_has_same_count: index_set.count = count

		-- from BILINEAR
	not_both: not (after and before)
	before_constraint: before implies off

		-- from LINEAR
	after_constraint: after implies off

		-- from TRAVERSABLE
	empty_constraint: is_empty implies off

end -- class LINKED_STACK

