deferred class
	FLAT_DYNAMIC_LIST [G]

inherit
	FLAT_READABLE_INDEXABLE [G]
		rename
			item as i_th alias "[]"
		redefine
			is_equal
		end

feature -- Access

	at alias "@" (i: INTEGER_32): like item assign put_i_th
			-- Item at `i'-th position
			-- Was declared in CHAIN as synonym of i_th.
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

	cursor: FLAT_CURSOR
			-- Current cursor position
			-- (from CURSOR_STRUCTURE)
		deferred
		ensure -- from CURSOR_STRUCTURE
			cursor_not_void: Result /= Void
		end

	first: like item
			-- Item at first position
			-- (from CHAIN)
		require -- from CHAIN
			not_empty: not is_empty
		local
			pos: FLAT_CURSOR
		do
			pos := cursor
			start
			Result := item
			go_to (pos)
		end


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

	i_th alias "[]" (i: INTEGER_32): like item assign put_i_th
			-- Item at `i'-th position
			-- Was declared in CHAIN as synonym of at.
			-- (from CHAIN)
		local
			pos: FLAT_CURSOR
		do
			pos := cursor
			go_i_th (i)
			Result := item
			go_to (pos)
		end

	index: INTEGER_32
			-- Index of current position
			-- (from LINEAR)
		deferred
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

	item: G
			-- Current item
			-- (from ACTIVE)
		require -- from TRAVERSABLE
			not_off: not off
		deferred
		end

	item_for_iteration: G
			-- Item at current position
			-- (from LINEAR)
		require -- from LINEAR
			not_off: not off
		do
			Result := item
		end

	last: like item
			-- Item at last position
			-- (from CHAIN)
		require -- from CHAIN
			not_empty: not is_empty
		local
			pos: FLAT_CURSOR
		do
			pos := cursor
			finish
			Result := item
			go_to (pos)
		end

feature {NONE} -- Access

	sequential_has (v: like item): BOOLEAN
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

	sequential_index_of (v: like item; i: INTEGER_32): INTEGER_32
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
					if item ~ v then
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
					if item = v then
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

	sequential_occurrences (v: like item): INTEGER_32
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

	sequential_search (v: like item)
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
					exhausted or else v ~ item
				loop
					forth
				end
			else
				from
				until
					exhausted or else v = item
				loop
					forth
				end
			end
		ensure -- from LINEAR
			object_found: (not exhausted and object_comparison) implies v ~ item
			item_found: (not exhausted and not object_comparison) implies v = item
		end

feature -- Measurement

	count: INTEGER_32
			-- Number of items
			-- (from FINITE)
		deferred
		ensure -- from FINITE
			count_non_negative: Result >= 0
		end

	index_set: FLAT_INTEGER_INTERVAL
			-- Range of acceptable indexes
			-- (from CHAIN)
		do
			create Result.make (1, count)
		ensure then -- from CHAIN
			count_definition: Result.count = count
		end

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

feature -- Comparison

	is_equal (other: like Current): BOOLEAN
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

	after: BOOLEAN
			-- Is there no valid cursor position to the right of cursor?
			-- (from LIST)
		require -- from  LINEAR
			True
		do
			Result := (index = count + 1)
		end

	before: BOOLEAN
			-- Is there no valid cursor position to the left of cursor?
			-- (from LIST)
		require -- from  BILINEAR
			True
		do
			Result := (index = 0)
		end

	changeable_comparison_criterion: BOOLEAN
			-- May object_comparison be changed?
			-- (Answer: yes by default.)
			-- (from CONTAINER)
		do
			Result := True
		end

	exhausted: BOOLEAN
			-- Has structure been completely explored?
			-- (from LINEAR)
		do
			Result := off
		ensure -- from LINEAR
			exhausted_when_off: off implies Result
		end

	extendible: BOOLEAN
			-- May new items be added? (Answer: yes.)
			-- (from DYNAMIC_CHAIN)
		require -- from  COLLECTION
			True
		do
			Result := True
		end

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
		deferred
--		do
--			Result := has (v)
		-- Changed to deferred, because of different semantics in all observable descendants
		end

	isfirst: BOOLEAN
			-- Is cursor at first position?
			-- (from CHAIN)
		do
			Result := not is_empty and (index = 1)
		ensure -- from CHAIN
			valid_position: Result implies not is_empty
		end

	islast: BOOLEAN
			-- Is cursor at last position?
			-- (from CHAIN)
		do
			Result := not is_empty and (index = count)
		ensure -- from CHAIN
			valid_position: Result implies not is_empty
		end

	object_comparison: BOOLEAN
			-- Must search operations use equal rather than `='
			-- for comparing references? (Default: no, use `='.)
			-- (from CONTAINER)

	off: BOOLEAN
			-- Is there no current item?
			-- (from CHAIN)
		require -- from  TRAVERSABLE
			True
		do
			Result := (index = 0) or (index = count + 1)
		end

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
			-- (from SEQUENCE)
		require -- from  ACTIVE
			True
		do
			Result := not off
		end

	replaceable: BOOLEAN
			-- Can current item be replaced?
			-- (from ACTIVE)
		do
			Result := True
		end

	valid_cursor (p: FLAT_CURSOR): BOOLEAN
			-- Can the cursor be moved to position `p'?
			-- (from CURSOR_STRUCTURE)
		deferred
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
		ensure then -- from CHAIN
			valid_index_definition: Result = ((i >= 1) and (i <= count))
		end

	writable: BOOLEAN
			-- Is there a current item that may be modified?
			-- (from SEQUENCE)
		require -- from  ACTIVE
			True
		do
			Result := not off
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

feature -- Cursor movement

	back
			-- Move to previous position.
			-- (from BILINEAR)
		require -- from BILINEAR
			not_before: not before
		deferred
		end

	finish
			-- Move cursor to last position.
			-- (No effect if empty)
			-- (from CHAIN)
		require -- from  LINEAR
			True
		do
			if not is_empty then
				go_i_th (count)
			end
		ensure then -- from CHAIN
			at_last: not is_empty implies islast
		end

	forth
			-- Move to next position; if no next position,
			-- ensure that exhausted will be true.
			-- (from LIST)
		require -- from LINEAR
			not_after: not after
		deferred
		ensure then -- from LIST
			moved_forth: index = old index + 1
		end

	go_i_th (i: INTEGER_32)
			-- Move cursor to `i'-th position.
			-- (from CHAIN)
		require -- from CHAIN
			valid_cursor_index: valid_cursor_index (i)
		do
			move (i - index)
		ensure -- from CHAIN
			position_expected: index = i
		end

	go_to (p: FLAT_CURSOR)
			-- Move cursor to position `p'.
			-- (from CURSOR_STRUCTURE)
		require -- from CURSOR_STRUCTURE
			cursor_position_valid: valid_cursor (p)
		deferred
		end

	move (i: INTEGER_32)
			-- Move cursor `i' positions. The cursor
			-- may end up off if the absolute value of `i'
			-- is too big.
			-- (from CHAIN)
		local
			counter, pos, final: INTEGER_32
		do
			if i > 0 then
				from
				until
					(counter = i) or else after
				loop
					forth
					counter := counter + 1
				end
			elseif i < 0 then
				final := index + i
				if final <= 0 then
					start
					back
				else
					from
						start
						pos := 1
					until
						pos = final
					loop
						forth
						pos := pos + 1
					end
				end
			end
		ensure -- from CHAIN
			too_far_right: (old index + i > count) implies exhausted
			too_far_left: (old index + i < 1) implies exhausted
			expected_index: (not exhausted) implies (index = old index + i)
		end

	search (v: like item)
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
			object_found: (not exhausted and object_comparison) implies v ~ item
			item_found: (not exhausted and not object_comparison) implies v = item
		end

	start
			-- Move cursor to first position.
			-- (No effect if empty)
			-- (from CHAIN)
		require -- from  TRAVERSABLE
			True
		do
			if not is_empty then
				go_i_th (1)
			end
		ensure then -- from CHAIN
			at_first: not is_empty implies isfirst
		end

feature -- Element change

	append (s: FLAT_DYNAMIC_LIST [G])
			-- Append a copy of `s'.
			-- (from CHAIN)
		require -- from SEQUENCE
			argument_not_void: s /= Void
		local
			l: like s
			l_cursor: FLAT_CURSOR
		do
			l := s
			if s = Current then
				l := twin
			end
			from
				l_cursor := cursor
				l.start
			until
				l.exhausted
			loop
				extend (l.item)
				finish
				l.forth
			end
			go_to (l_cursor)
		ensure -- from SEQUENCE
			new_count: count >= old count
		end

	extend (v: G)
			-- Add a new occurrence of `v'.
			-- (from BAG)
		deferred
		ensure -- from COLLECTION
			item_inserted: is_inserted (v)
		end

	fill (other: FLAT_DYNAMIC_LIST [G])
			-- Fill with as many items of `other' as possible.
			-- The representations of `other' and current structure
			-- need not be the same.
			-- (from CHAIN)
		require -- from COLLECTION
			other_not_void: other /= Void
		local
			lin_rep: FLAT_DYNAMIC_LIST [G]
			l_cursor: FLAT_CURSOR
		do
			lin_rep := other.linear_representation
			from
				l_cursor := cursor
				lin_rep.start
			until
				not extendible or else lin_rep.off
			loop
				extend (lin_rep.item)
				finish
				lin_rep.forth
			end
			go_to (l_cursor)
		end

	force (v: like item)
			-- Add `v' to end.
			-- (from SEQUENCE)
		do
			extend (v)
		ensure then -- from SEQUENCE
			new_count: count = old count + 1
			item_inserted: has (v)
		end

	merge_left (other: like Current)
			-- Merge `other' into current structure before cursor
			-- position. Do not move cursor. Empty `other'.
		require -- from DYNAMIC_CHAIN
			not_before: not before
			other_exists: other /= Void
			not_current: other /= Current
		do
			from
				other.start
			until
				other.is_empty
			loop
				put_left (other.item)
				other.remove
			end
		ensure -- from DYNAMIC_CHAIN
			new_count: count = old count + old other.count
			new_index: index = old index + old other.count
			other_is_empty: other.is_empty
		end

	merge_right (other: like Current)
			-- Merge `other' into current structure after cursor
			-- position. Do not move cursor. Empty `other'.
		require -- from DYNAMIC_CHAIN
			not_after: not after
			other_exists: other /= Void
			not_current: other /= Current
		do
			from
				other.finish
			until
				other.is_empty
			loop
				put_right (other.item)
				other.back
				other.remove_right
			end
		ensure -- from DYNAMIC_CHAIN
			new_count: count = old count + old other.count
			same_index: index = old index
			other_is_empty: other.is_empty
		end

	put (v: like item)
			-- Replace current item by `v'.
			-- (Synonym for replace)
			-- (from CHAIN)
		require -- from CHAIN
			writeable: writable
		do
			replace (v)
		ensure -- from CHAIN
			same_count: count = old count
			is_inserted: is_inserted (v)
		end

	sequence_put (v: like item)
			-- Add `v' to end.
			-- (from SEQUENCE)
		do
			extend (v)
		ensure -- from COLLECTION
			item_inserted: is_inserted (v)
			new_count: count = old count + 1
		end

	put_front (v: like item)
			-- Add `v' at beginning.
			-- Do not move cursor.
			-- (from DYNAMIC_CHAIN)
		deferred
		ensure -- from DYNAMIC_CHAIN
			new_count: count = old count + 1
			item_inserted: first = v
		end

	put_i_th (v: like item; i: INTEGER_32)
			-- Put `v' at `i'-th position.
			-- (from CHAIN)
		require -- from TABLE
			valid_key: valid_index (i)
		local
			pos: FLAT_CURSOR
		do
			pos := cursor
			go_i_th (i)
			replace (v)
			go_to (pos)
		ensure -- from TABLE
			inserted: i_th (i) = v
		end

	put_left (v: like item)
			-- Add `v' to the left of cursor position.
			-- Do not move cursor.
		require -- from DYNAMIC_CHAIN
			not_before: not before
		local
			temp: like item
		do
			if is_empty then
				put_front (v)
			elseif after then
				back
				put_right (v)
				move (2)
			else
				temp := item
				replace (v)
				put_right (temp)
				forth
			end
		ensure -- from DYNAMIC_CHAIN
			new_count: count = old count + 1
			new_index: index = old index + 1
		end

	put_right (v: like item)
			-- Add `v' to the right of cursor position.
			-- Do not move cursor.
		require -- from DYNAMIC_CHAIN
			not_after: not after
		deferred
		ensure -- from DYNAMIC_CHAIN
			new_count: count = old count + 1
			same_index: index = old index
		end

	replace (v: G)
			-- Replace current item by `v'.
			-- (from ACTIVE)
		require -- from ACTIVE
			writable: writable
		deferred
		ensure -- from ACTIVE
			item_replaced: item = v
		end

feature -- Removal

	prune (v: like item)
			-- Remove first occurrence of `v', if any,
			-- after cursor position.
			-- If found, move cursor to right neighbor;
			-- if not, make structure exhausted.
			-- (from DYNAMIC_CHAIN)
		require -- from COLLECTION
			prunable: prunable
		do
			search (v)
			if not exhausted then
				remove
			end
		end

	prune_all (v: like item)
			-- Remove all occurrences of `v'.
			-- (Reference or object equality,
			-- based on object_comparison.)
			-- Leave structure exhausted.
			-- (from DYNAMIC_CHAIN)
		do
			from
				start
				search (v)
			until
				exhausted
			loop
				remove
				search (v)
			end
		ensure -- from COLLECTION
			no_more_occurrences: not has (v)
			is_exhausted: exhausted
		end

	remove
			-- Remove current item.
			-- Move cursor to right neighbor
			-- (or after if no right neighbor).
		require -- from ACTIVE
			writable: writable
		deferred
		ensure then
			after_when_empty: is_empty implies after
		end

	remove_left
			-- Remove item to the left of cursor position.
			-- Do not move cursor.
		require -- from DYNAMIC_CHAIN
			left_exists: index > 1
		deferred
		ensure -- from DYNAMIC_CHAIN
			new_count: count = old count - 1
			new_index: index = old index - 1
		end

	remove_right
			-- Remove item to the right of cursor position.
			-- Do not move cursor.
		require -- from DYNAMIC_CHAIN
			right_exists: index < count
		deferred
		ensure -- from DYNAMIC_CHAIN
			new_count: count = old count - 1
			same_index: index = old index
		end

	wipe_out
			-- Remove all items.
		do
			chain_wipe_out
			back
		ensure -- from COLLECTION
			wiped_out: is_empty
			is_before: before
		end

feature {NONE} -- Removal

	chain_wipe_out
			-- Remove all items.
			-- (from DYNAMIC_CHAIN)
		do
			from
				start
			until
				is_empty
			loop
				remove
			end
		ensure -- from COLLECTION
			wiped_out: is_empty
		end

feature -- Transformation

	swap (i: INTEGER_32)
			-- Exchange item at `i'-th position with item
			-- at cursor position.
			-- (from CHAIN)
		require -- from CHAIN
			not_off: not off
			valid_index: valid_index (i)
		local
			old_item, new_item: like item
			pos: FLAT_CURSOR
		do
			pos := cursor
			old_item := item
			go_i_th (i)
			new_item := item
			replace (old_item)
			go_to (pos)
			replace (new_item)
		ensure -- from CHAIN
			swapped_to_item: item = old i_th (i)
			swapped_from_item: i_th (i) = old item
		end

feature -- Conversion

	linear_representation: FLAT_DYNAMIC_LIST [G]
			-- Representation as a linear structure
			-- (from LINEAR)
		do
			Result := Current
		end

feature -- Duplication

	duplicate (n: INTEGER_32): like Current
			-- Copy of sub-chain beginning at current position
			-- and having min (`n', `from_here') items,
			-- where `from_here' is the number of items
			-- at or to the right of current position.
			-- (from DYNAMIC_CHAIN)
		require -- from CHAIN
			not_off_unless_after: off implies after
			valid_subchain: n >= 0
		local
			pos: FLAT_CURSOR
			counter: INTEGER_32
		do
			from
				Result := new_chain
				if object_comparison then
					Result.compare_objects
				end
				pos := cursor
			until
				(counter = n) or else exhausted
			loop
				Result.extend (item)
				forth
				counter := counter + 1
			end
			go_to (pos)
		end

feature {DYNAMIC_CHAIN} -- Implementation

	new_chain: FLAT_DYNAMIC_LIST [G]
			-- A newly created instance of the same type.
			-- This feature may be redefined in descendants so as to
			-- produce an adequately allocated and initialized object.
			-- (from DYNAMIC_CHAIN)
		deferred
		ensure -- from DYNAMIC_CHAIN
			result_exists: Result /= Void
		end

feature -- Iteration

	do_all (action: PROCEDURE [ANY, TUPLE [G]])
			-- Apply `action' to every item.
			-- Semantics not guaranteed if `action' changes the structure;
			-- in such a case, apply iterator to clone of structure instead.
			-- (from LINEAR)
		require -- from TRAVERSABLE
			action_exists: action /= Void
		local
			c: FLAT_CURSOR
			cs: FLAT_DYNAMIC_LIST [G]
		do
			if attached {FLAT_DYNAMIC_LIST [G]} Current as acs then
				cs := acs
				c := acs.cursor
			end
			from
				start
			until
				after
			loop
				action.call ([item])
				forth
			end
			if cs /= Void and c /= Void then
				cs.go_to (c)
			end
		end

	do_if (action: PROCEDURE [ANY, TUPLE [G]]; test: PREDICATE [ANY, TUPLE [G]])
			-- Apply `action' to every item that satisfies `test'.
			-- Semantics not guaranteed if `action' or `test' changes the structure;
			-- in such a case, apply iterator to clone of structure instead.
			-- (from LINEAR)
		require -- from TRAVERSABLE
			action_exists: action /= Void
			test_exists: test /= Void
		local
			c: FLAT_CURSOR
			cs: FLAT_DYNAMIC_LIST [G]
		do
			if attached {FLAT_DYNAMIC_LIST [G]} Current as acs then
				cs := acs
				c := acs.cursor
			end
			from
				start
			until
				after
			loop
				if test.item ([item]) then
					action.call ([item])
				end
				forth
			end
			if cs /= Void and c /= Void then
				cs.go_to (c)
			end
		end

	for_all (test: PREDICATE [ANY, TUPLE [G]]): BOOLEAN
			-- Is `test' true for all items?
			-- Semantics not guaranteed if `test' changes the structure;
			-- in such a case, apply iterator to clone of structure instead.
			-- (from LINEAR)
		require -- from TRAVERSABLE
			test_exists: test /= Void
		local
			c: FLAT_CURSOR
			cs: FLAT_DYNAMIC_LIST [G]
		do
			if attached {FLAT_DYNAMIC_LIST [G]} Current as acs then
				cs := acs
				c := acs.cursor
			end
			from
				start
				Result := True
			until
				after or not Result
			loop
				Result := test.item ([item])
				forth
			end
			if cs /= Void and c /= Void then
				cs.go_to (c)
			end
		ensure then -- from LINEAR
			empty: is_empty implies Result
		end

	there_exists (test: PREDICATE [ANY, TUPLE [G]]): BOOLEAN
			-- Is `test' true for at least one item?
			-- Semantics not guaranteed if `test' changes the structure;
			-- in such a case, apply iterator to clone of structure instead.
			-- (from LINEAR)
		require -- from TRAVERSABLE
			test_exists: test /= Void
		local
			c: FLAT_CURSOR
			cs: FLAT_DYNAMIC_LIST [G]
		do
			if attached {FLAT_DYNAMIC_LIST [G]} Current as acs then
				cs := acs
				c := acs.cursor
			end
			from
				start
			until
				after or Result
			loop
				Result := test.item ([item])
				forth
			end
			if cs /= Void and c /= Void then
				cs.go_to (c)
			end
		end


invariant
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

		-- from ACTIVE
	writable_constraint: writable implies readable
	empty_constraint: is_empty implies (not readable) and (not writable)

		-- from BILINEAR
	not_both: not (after and before)
	before_constraint: before implies off

		-- from LINEAR
	after_constraint: after implies off

		-- from TRAVERSABLE
	empty_constraint: is_empty implies off

		-- from FINITE
	empty_definition: is_empty = (count = 0)

end -- class FLAT_DYNAMIC_LIST

