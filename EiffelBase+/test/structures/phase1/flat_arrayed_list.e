class
	FLAT_ARRAYED_LIST [G]

inherit
	FLAT_DYNAMIC_LIST [G]
		redefine
			at,
			first,
			has,
			i_th,
			is_equal,
			last,
			is_inserted,
			copy,
			finish,
			go_i_th,
			move,
			search,
			start,
			append,
			force,
			merge_left,
			merge_right,
			put_i_th,
			put_left,
			prune,
			prune_all,
			wipe_out,
			swap,
			duplicate,
			do_all, do_if, for_all, there_exists
		end

create
	make,
	make_filled

feature -- Initialization

	make (n: INTEGER_32)
			-- Allocate list with `n' items.
			-- (`n' may be zero for empty list.)
		require
			valid_number_of_items: n >= 0
		do
			index := 0
			create area_v2.make_empty (n)
		ensure
			correct_position: before
			is_empty: is_empty
		end

	make_filled (n: INTEGER_32)
			-- Allocate list with `n' items.
			-- (`n' may be zero for empty list.)
			-- This list will be full.
		require
			valid_number_of_items: n >= 0
			has_default: ({G}).has_default
		do
			index := 0
			make_filled_area (({G}).default, n)
		ensure
			correct_position: before
			filled: full
		end

feature {NONE} -- Initialization		

	make_from_array (a: FLAT_ARRAY [G])
			-- Create list from array `a'.
		require
			array_exists: a /= Void
		do
			index := 0
			area_v2 := a.area
		ensure then
			correct_position: before
			filled: count = a.count
		end

	make_empty_area (n: INTEGER_32)
			-- Creates a special object for `n' entries.
			-- (from TO_SPECIAL)
		require -- from TO_SPECIAL
			non_negative_argument: n >= 0
		do
			create area_v2.make_empty (n)
		ensure -- from TO_SPECIAL
			area_allocated: area_v2 /= Void
			capacity_set: area_v2.capacity = n
			count_set: area_v2.count = 0
		end

	make_filled_area (a_default_value: G; n: INTEGER_32)
			-- Creates a special object for `n' entries.
			-- (from TO_SPECIAL)
		require -- from TO_SPECIAL
			non_negative_argument: n >= 0
		do
			create area_v2.make_filled (a_default_value, n)
		ensure -- from TO_SPECIAL
			area_allocated: area_v2 /= Void
			capacity_set: area_v2.capacity = n
			count_set: area_v2.count = n
			area_filled: area_v2.filled_with (a_default_value, 0, n - 1)
		end

feature -- Access

	array_at (i: INTEGER_32): G assign array_put
			-- Entry at index `i', if in index interval
			-- Was declared in TO_SPECIAL as synonym of item.
			-- (from TO_SPECIAL)
		require -- from TO_SPECIAL
			valid_index: array_valid_index (i)
		do
			Result := area_v2.item (i)
		end

	at alias "@" (i: INTEGER_32): like item assign put_i_th
			-- Item at `i'-th position
			-- Was declared in FLAT_ARRAYED_LIST as synonym of i_th.
		do
			Result := area_v2.item (i - 1)
		end

	cursor: FLAT_ARRAYED_LIST_CURSOR
			-- Current cursor position
		do
			create Result.make (index)
		end

	first: like item
			-- Item at first position
		do
			Result := area_v2.item (0)
		end

	has (v: like item): BOOLEAN
			-- Does current include `v'?
			-- (Reference or object equality,
			-- based on object_comparison.)
		local
			l_area: like area_v2
			i, nb: INTEGER_32
		do
			l_area := area_v2
			nb := count - 1
			if object_comparison and v /= Void then
				from
				until
					i > nb or Result
				loop
					Result := v ~ l_area.item (i)
					i := i + 1
				end
			else
				from
				until
					i > nb or Result
				loop
					Result := v = l_area.item (i)
					i := i + 1
				end
			end
		end

	i_th alias "[]" (i: INTEGER_32): like item assign put_i_th
			-- Item at `i'-th position
			-- Was declared in FLAT_ARRAYED_LIST as synonym of at.
		do
			Result := area_v2.item (i - 1)
		end

	index: INTEGER_32
			-- Index of item, if valid.

	array_item (i: INTEGER_32): G assign array_put
			-- Entry at index `i', if in index interval
			-- Was declared in TO_SPECIAL as synonym of at.
			-- (from TO_SPECIAL)
		require -- from TO_SPECIAL
			valid_index: array_valid_index (i)
		do
			Result := area_v2.item (i)
		end

	item: G
			-- Current item
		do
			Result := area_v2.item (index - 1)
		end

	last: like first
			-- Item at last position
		do
			Result := area_v2.item (count - 1)
		end

feature -- Measurement

	capacity: INTEGER_32
			-- Number of items that may be stored
		do
			Result := area_v2.capacity
		ensure -- from BOUNDED
			capacity_non_negative: Result >= 0
		end

	count: INTEGER_32
			-- Number of items
		do
			Result := area_v2.count
		end

	Growth_percentage: INTEGER_32 = 50
			-- Percentage by which structure will grow automatically
			-- (from RESIZABLE)

	Lower: INTEGER_32 = 1
			-- Lower bound for accessing list items via indexes

	Minimal_increase: INTEGER_32 = 5
			-- Minimal number of additional items
			-- (from RESIZABLE)

	upper: INTEGER_32
			-- Upper bound for accessing list items via indexes
		do
			Result := area_v2.count
		end

feature -- Comparison

	is_equal (other: like Current): BOOLEAN
			-- Is array made of the same items as `other'?
		local
			i: INTEGER_32
		do
			if other = Current then
				Result := True
			elseif count = other.count and then object_comparison = other.object_comparison then
				if object_comparison then
					from
						Result := True
						i := Lower
					until
						not Result or i > upper
					loop
						Result := i_th (i) ~ other.i_th (i)
						i := i + 1
					end
				else
					Result := area_v2.same_items (other.area_v2, 0, 0, count)
				end
			end
		ensure then -- from LIST
			indices_unchanged: index = old index and other.index = old other.index
			true_implies_same_size: Result implies count = other.count
		end

feature -- Status report

	all_default: BOOLEAN
			-- Are all items set to default values?
		require
			has_default: ({G}).has_default
		do
			Result := area_v2.filled_with (({G}).default, 0, area_v2.upper)
		end

	full: BOOLEAN
			-- Is structure full?
			-- (from BOUNDED)
		do
			Result := (count = capacity)
		end

	is_inserted (v: G): BOOLEAN
			-- Has `v' been inserted at the end by the most recent put or
			-- extend?
		do
			if not is_empty then
				Result := (v = last) or else (not off and then (v = item))
			end
		end

	resizable: BOOLEAN
			-- May capacity be changed? (Answer: yes.)
			-- (from RESIZABLE)
		do
			Result := True
		end

	valid_cursor (p: FLAT_CURSOR): BOOLEAN
			-- Can the cursor be moved to position `p'?
		do
			if attached {FLAT_ARRAYED_LIST_CURSOR} p as al_c then
				Result := valid_cursor_index (al_c.index)
			end
		end

	array_valid_index (i: INTEGER_32): BOOLEAN
			-- Is `i' within the bounds of Current?
			-- (from TO_SPECIAL)
		do
			Result := area_v2.valid_index (i)
		end

feature -- Cursor movement

	back
			-- Move cursor one position backward.
		do
			index := index - 1
		end

	finish
			-- Move cursor to last position if any.
		do
			index := count
		ensure then -- from CHAIN
			at_last: not is_empty implies islast
			before_when_empty: is_empty implies before
		end

	forth
			-- Move cursor one position forward.
		do
			index := index + 1
		end

	go_i_th (i: INTEGER_32)
			-- Move cursor to `i'-th position.
		do
			index := i
		end

	--go_to (p: FLAT_ARRAYED_LIST_CURSOR)
		go_to (p: FLAT_CURSOR)
			-- Move cursor to position `p'.
		do
			if attached {FLAT_ARRAYED_LIST_CURSOR} p as al_c then
				index := al_c.index
			else
				check
					correct_cursor_type: False
				end
			end
		end

	move (i: INTEGER_32)
			-- Move cursor `i' positions.
		do
			index := index + i
			if (index > count + 1) then
				index := count + 1
			elseif (index < 0) then
				index := 0
			end
		end

	search (v: like item)
			-- Move to first position (at or after current
			-- position) where item and `v' are equal.
			-- If structure does not include `v' ensure that
			-- exhausted will be true.
			-- (Reference or object equality,
			-- based on object_comparison.)
		local
			l_area: like area_v2
			i, nb: INTEGER_32
			l_found: BOOLEAN
		do
			l_area := area_v2
			nb := count - 1
			i := (index - 1).max (0)
			if object_comparison and v /= Void then
				from
				until
					i > nb or l_found
				loop
					l_found := v ~ l_area.item (i)
					i := i + 1
				end
			else
				from
				until
					i > nb or l_found
				loop
					l_found := v = l_area.item (i)
					i := i + 1
				end
			end
			if l_found then
				index := i
			else
				index := i + 1
			end
		end

	start
			-- Move cursor to first position if any.
		do
			index := 1
		ensure then -- from CHAIN
			at_first: not is_empty implies isfirst
			after_when_empty: is_empty implies after
		end

feature -- Element change

	append (s: FLAT_DYNAMIC_LIST [G])
			-- Append a copy of `s'.
		local
			c, old_count, new_count: INTEGER_32
		do
			if attached {FLAT_ARRAYED_LIST [G]} s as al then -- Optimization for arrayed lists
				c := al.count
					-- If `s' is empty nothing to be done.
				if c > 0 then
					old_count := count
					new_count := old_count + al.count
					if new_count > area_v2.capacity then
						area_v2 := area_v2.aliased_resized_area (new_count)
					end
					area_v2.copy_data (al.area_v2, 0, old_count, c)
				end
			else
				Precursor {FLAT_DYNAMIC_LIST} (s)
			end
		end

	extend (v: like item)
			-- Add `v' to end.
			-- Do not move cursor.
			-- Was declared in FLAT_ARRAYED_LIST as synonym of force.
		local
			i: INTEGER_32
			l_area: like area_v2
		do
			i := count + 1
			l_area := area_v2
			if i > l_area.capacity then
				l_area := l_area.aliased_resized_area (i + additional_space)
				area_v2 := l_area
			end
			l_area.extend (v)
		end

	force (v: like item)
			-- Add `v' to end.
			-- Do not move cursor.
			-- Was declared in FLAT_ARRAYED_LIST as synonym of extend.
		local
			i: INTEGER_32
			l_area: like area_v2
		do
			i := count + 1
			l_area := area_v2
			if i > l_area.capacity then
				l_area := l_area.aliased_resized_area (i + additional_space)
				area_v2 := l_area
			end
			l_area.extend (v)
		end

	merge_left (other: FLAT_ARRAYED_LIST [G])
			-- Merge `other' into current structure before cursor.
		local
			old_index: INTEGER_32
			old_other_count: INTEGER_32
		do
			old_index := index
			old_other_count := other.count
			index := index - 1
			merge_right (other)
			index := old_index + old_other_count
		end

	merge_right (other: FLAT_ARRAYED_LIST [G])
			-- Merge `other' into current structure after cursor.
		local
			l_new_count, l_old_count: INTEGER_32
		do
			if not other.is_empty then
				l_old_count := count
				l_new_count := l_old_count + other.count
				if l_new_count > area_v2.capacity then
					area_v2 := area_v2.aliased_resized_area (l_new_count)
				end
				area_v2.insert_data (other.area_v2, 0, index, other.count)
				other.wipe_out
			end
		end

	array_put (v: G; i: INTEGER_32)
			-- Replace `i'-th entry, if in index interval, by `v'.
			-- (from TO_SPECIAL)
		require -- from TO_SPECIAL
			valid_index: array_valid_index (i)
		do
			area_v2.put (v, i)
		ensure -- from TO_SPECIAL
			inserted: array_item (i) = v
		end

	put_front (v: like item)
			-- Add `v' to the beginning.
			-- Do not move cursor.
		do
			if is_empty then
				extend (v)
			else
				insert (v, 1)
			end
			index := index + 1
		end

	put_i_th (v: like i_th; i: INTEGER_32)
			-- Replace `i'-th entry, if in index interval, by `v'.
		do
			area_v2.put (v, i - 1)
		end

	put_left (v: like item)
			-- Add `v' to the left of current position.
			-- Do not move cursor.
		do
			if after or is_empty then
				extend (v)
			else
				insert (v, index)
			end
			index := index + 1
		end

	put_right (v: like item)
			-- Add `v' to the right of current position.
			-- Do not move cursor.
		do
			if index = count then
				extend (v)
			else
				insert (v, index + 1)
			end
		end

	replace (v: like first)
			-- Replace current item by `v'.
		do
			put_i_th (v, index)
		end

feature {NONE} -- Element change

	set_area (other: like area_v2)
			-- Make `other' the new area
			-- (from TO_SPECIAL)
		do
			area_v2 := other
		ensure -- from TO_SPECIAL
			area_set: area_v2 = other
		end

feature -- Removal

	prune (v: like item)
			-- Remove first occurrence of `v', if any,
			-- after cursor position.
			-- Move cursor to right neighbor.
			-- (or after if no right neighbor or `v' does not occur)
		do
			if before then
				index := 1
			end
			if object_comparison then
				from
				until
					after or else item ~ v
				loop
					forth
				end
			else
				from
				until
					after or else item = v
				loop
					forth
				end
			end
			if not after then
				remove
			end
		end

	prune_all (v: like item)
			-- Remove all occurrences of `v'.
			-- (Reference or object equality,
			-- based on object_comparison.)
		local
			i, nb: INTEGER_32
			offset: INTEGER_32
			res: BOOLEAN
			obj_cmp: BOOLEAN
			l_area: like area_v2
		do
			obj_cmp := object_comparison
			from
				l_area := area_v2
				i := 0
				nb := count
			until
				i = count
			loop
				if i < nb - offset then
					if offset > 0 then
						l_area.put (l_area.item (i + offset), i)
					end
					if obj_cmp then
						res := v ~ l_area.item (i)
					else
						res := v = l_area.item (i)
					end
					if res then
						offset := offset + 1
					else
						i := i + 1
					end
				else
					i := i + 1
				end
			end
			l_area.remove_tail (offset)
			index := count + 1
		ensure then
			is_after: after
		end

	remove
			-- Remove current item.
			-- Move cursor to right neighbor
			-- (or after if no right neighbor)
		do
			if index < count then
				area_v2.move_data (index, index - 1, count - index)
			end
			area_v2.remove_tail (1)
		ensure then -- from DYNAMIC_LIST
			index: index = old index
		end

	remove_left
			-- Remove item to the left of cursor position.
			-- Do not move cursor.
		do
			index := index - 1
			remove
		end

	remove_right
			-- Remove item to the right of cursor position
			-- Do not move cursor
		do
			index := index + 1
			remove
			index := index - 1
		end

	wipe_out
			-- Remove all items.
		do
			area_v2.wipe_out
			index := 0
		end

feature -- Resizing

	automatic_grow
			-- Change the capacity to accommodate at least
			-- Growth_percentage more items.
			-- (from RESIZABLE)
		do
			grow (capacity + additional_space)
		ensure -- from RESIZABLE
			increased_capacity: capacity >= old capacity + old additional_space
		end

	grow (i: INTEGER_32)
			-- Change the capacity to at least `i'.
		do
			if i > area_v2.capacity then
				area_v2 := area_v2.aliased_resized_area (i)
			end
		ensure -- from RESIZABLE
			new_capacity: capacity >= i
		end

	resize (new_capacity: INTEGER_32)
			-- Resize list so that it can contain
			-- at least `n' items. Do not lose any item.
		require
			resizable: resizable
			new_capacity_large_enough: new_capacity >= capacity
		do
			grow (new_capacity)
		ensure
			capacity_set: capacity >= new_capacity
		end

	trim
			-- Decrease capacity to the minimum value.
			-- Apply to reduce allocated storage.
		require -- from  RESIZABLE
			True
		local
			n: like count
		do
			n := count
			if n < area_v2.capacity then
				area_v2 := area_v2.aliased_resized_area (n)
			end
		ensure -- from RESIZABLE
			same_count: count = old count
			minimal_capacity: capacity = count
			same_items: to_array.same_items (old to_array)
		end

feature -- Transformation

	swap (i: INTEGER_32)
			-- Exchange item at `i'-th position with item
			-- at cursor position.
		local
			old_item: like item
		do
			old_item := item
			replace (area_v2.item (i - 1))
			area_v2.put (old_item, i - 1)
		end

feature -- Duplication

	copy (other: like Current)
			-- Reinitialize by copying all the items of `other'.
			-- (This is also used by clone.)
		do
			if other /= Current then
				standard_copy (other)
				set_area (other.area_v2.twin)
			end
		ensure then
			equal_areas: area_v2 ~ other.area_v2
		end

	duplicate (n: INTEGER_32): like Current
			-- Copy of sub-list beginning at current position
			-- and having min (`n', count - index + 1) items.
		local
			end_pos: INTEGER_32
		do
			if after then
				Result := new_filled_list (0)
			else
				end_pos := count.min (index + n - 1)
				Result := new_filled_list (end_pos - index + 1)
				Result.area_v2.copy_data (area_v2, index - 1, 0, end_pos - index + 1)
			end
		end

feature {NONE} -- Inapplicable

	new_chain: like Current
			-- Unused
		do
			Result := Current
		end

feature {FLAT_ARRAYED_LIST, FLAT_ARRAYED_SET} -- Implementation
	-- Moved here from various public feature clauses:

	area: SPECIAL [G]
			-- Access to internal storage of arrayed list
		do
			Result := area_v2
		end

	area_v2: SPECIAL [G]
			-- Special data zone
			-- (from TO_SPECIAL)

	additional_space: INTEGER_32
			-- Proposed number of additional items
			-- (from RESIZABLE)
		do
			Result := (capacity // 2).max (Minimal_increase)
		end

	to_array: FLAT_ARRAY [G]
			-- Share content to be used as an ARRAY.
			-- Note that although the content is shared, it might
			-- not be shared when a resizing occur in either ARRAY or Current.
		do
			create Result.make_from_special (area_v2)
		ensure
			to_array_attached: Result /= Void
			array_lower_set: Result.lower = 1
			array_upper_set: Result.upper = count
		end

feature {NONE} -- Implementation

	force_i_th (v: like i_th; pos: INTEGER_32)
		do
			if count + 1 > capacity then
				grow (count + additional_space)
			end
			area_v2.force (v, pos)
		end

	insert (v: like item; pos: INTEGER_32)
			-- Add `v' at `pos', moving subsequent items
			-- to the right.
		require
			index_small_enough: pos <= count
			index_large_enough: pos >= 1
		do
			if count + 1 > capacity then
				grow (count + additional_space)
			end
			area_v2.move_data (pos - 1, pos, count - pos + 1)
			put_i_th (v, pos)
		ensure
			new_count: count = old count + 1
			index_unchanged: index = old index
			insertion_done: i_th (pos) = v
		end

	new_filled_list (n: INTEGER_32): like Current
			-- New list with `n' elements.
		require
			n_non_negative: n >= 0
		do
			create Result.make (n)
		ensure
			new_filled_list_not_void: Result /= Void
			new_filled_list_count_set: Result.count = 0
			new_filled_list_before: Result.before
		end

feature -- Iteration

	do_all (action: PROCEDURE [ANY, TUPLE [G]])
			-- Apply `action' to every item, from first to last.
			-- Semantics not guaranteed if `action' changes the structure;
			-- in such a case, apply iterator to clone of structure instead.
		do
			area_v2.do_all_in_bounds (action, 0, area_v2.count - 1)
		end

	do_all_with_index (action: PROCEDURE [ANY, TUPLE [G, INTEGER_32]])
			-- Apply `action' to every item, from first to last.
			-- `action' receives item and its index.
			-- Semantics not guaranteed if `action' changes the structure;
			-- in such a case, apply iterator to clone of structure instead.
		require
			action_not_void: action /= Void
		local
			i, j, nb: INTEGER_32
			l_area: like area_v2
		do
			from
				i := 0
				j := Lower
				nb := count - 1
				l_area := area_v2
			until
				i > nb
			loop
				action.call ([l_area.item (i), j])
				j := j + 1
				i := i + 1
			end
		end

	do_if (action: PROCEDURE [ANY, TUPLE [G]]; test: PREDICATE [ANY, TUPLE [G]])
			-- Apply `action' to every item that satisfies `test', from first to last.
			-- Semantics not guaranteed if `action' or `test' changes the structure;
			-- in such a case, apply iterator to clone of structure instead.
		do
			area_v2.do_if_in_bounds (action, test, 0, area_v2.count - 1)
		end

	do_if_with_index (action: PROCEDURE [ANY, TUPLE [G, INTEGER_32]]; test: PREDICATE [ANY, TUPLE [G]])
			-- Apply `action' to every item that satisfies `test', from first to last.
			-- `action' and `test' receive the item and its index.
			-- Semantics not guaranteed if `action' or `test' changes the structure;
			-- in such a case, apply iterator to clone of structure instead.
		require
			action_not_void: action /= Void
			test_not_void: test /= Void
		local
			i, j, nb: INTEGER_32
			l_area: like area_v2
		do
			from
				i := 0
				j := Lower
				nb := count - 1
				l_area := area_v2
			until
				i > nb
			loop
				if test.item ([l_area.item (i), j]) then
					action.call ([l_area.item (i), j])
				end
				j := j + 1
				i := i + 1
			end
		end

	for_all (test: PREDICATE [ANY, TUPLE [G]]): BOOLEAN
			-- Is `test' true for all items?
		do
			Result := area_v2.for_all_in_bounds (test, 0, area_v2.count - 1)
		end

	there_exists (test: PREDICATE [ANY, TUPLE [G]]): BOOLEAN
			-- Is `test' true for at least one item?
		do
			Result := area_v2.there_exists_in_bounds (test, 0, area_v2.count - 1)
		end

invariant
	prunable: prunable
	starts_from_one: Lower = 1

		-- from RESIZABLE
	increase_by_at_least_one: Minimal_increase >= 1

		-- from BOUNDED
	valid_count: count <= capacity
	full_definition: full = (count = capacity)

		-- from FINITE
	empty_definition: is_empty = (count = 0)

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

end -- class FLAT_ARRAYED_LIST

