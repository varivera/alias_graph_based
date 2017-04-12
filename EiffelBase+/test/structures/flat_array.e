class
	FLAT_ARRAY [G]

inherit
	FLAT_READABLE_INDEXABLE [G]
		redefine
			copy,
			is_equal
		end

create
	make_empty,
	make,
	make_filled

create {FLAT_ARRAY, FLAT_ARRAYED_LIST, FLAT_ARRAYED_SET}
	make_from_array,
	make_from_special

feature -- Initialization

	make (min_index, max_index: INTEGER_32)
			-- Allocate array; set index interval to
			-- `min_index' .. `max_index'; set all values to default.
			-- (Make array empty if `min_index' = `max_index' + 1).
		require
			valid_bounds: min_index <= max_index + 1
			has_default: min_index <= max_index implies ({G}).has_default
		do
			lower := min_index
			upper := max_index
			if min_index <= max_index then
				make_filled_area (({G}).default, max_index - min_index + 1)
			else
				make_empty_area (0)
			end
		ensure
			lower_set: lower = min_index
			upper_set: upper = max_index
			items_set: all_default
		end

	make_empty
			-- Allocate empty array starting at `1'.
		do
			lower := 1
			upper := 0
			make_empty_area (0)
		ensure
			lower_set: lower = 1
			upper_set: upper = 0
			items_set: all_default
		end

	make_filled (a_default_value: G; min_index, max_index: INTEGER_32)
			-- Allocate array; set index interval to
			-- `min_index' .. `max_index'; set all values to default.
			-- (Make array empty if `min_index' = `max_index' + 1).
		require
			valid_bounds: min_index <= max_index + 1
		local
			n: INTEGER_32
		do
			lower := min_index
			upper := max_index
			if min_index <= max_index then
				n := max_index - min_index + 1
			end
			make_filled_area (a_default_value, n)
		ensure
			lower_set: lower = min_index
			upper_set: upper = max_index
			items_set: filled_with (a_default_value)
		end

feature {NONE} -- Initialization

	make_from_array (a: FLAT_ARRAY [G])
			-- Initialize from the items of `a'.
			-- (Useful in proper descendants of class `FLAT_ARRAY',
			-- to initialize an array-like object from a manifest array.)
		require
			array_exists: a /= Void
		do
			set_area (a.area)
			lower := a.lower
			upper := a.upper
		end

	make_from_special (a: SPECIAL [G])
			-- Initialize Current from items of `a'.
		require
			special_attached: a /= Void
		do
			set_area (a)
			lower := 1
			upper := a.count
		ensure
			shared: area = a
			lower_set: lower = 1
			upper_set: upper = a.count
		end

	make_empty_area (n: INTEGER_32)
			-- Creates a special object for `n' entries.
			-- (from TO_SPECIAL)
		require -- from TO_SPECIAL
			non_negative_argument: n >= 0
		do
			create area.make_empty (n)
		ensure -- from TO_SPECIAL
			area_allocated: area /= Void
			capacity_set: area.capacity = n
			count_set: area.count = 0
		end

	make_filled_area (a_default_value: G; n: INTEGER_32)
			-- Creates a special object for `n' entries.
			-- (from TO_SPECIAL)
		require -- from TO_SPECIAL
			non_negative_argument: n >= 0
		do
			create area.make_filled (a_default_value, n)
		ensure -- from TO_SPECIAL
			area_allocated: area /= Void
			capacity_set: area.capacity = n
			count_set: area.count = n
			area_filled: area.filled_with (a_default_value, 0, n - 1)
		end

feature -- Access

	at alias "@" (i: INTEGER_32): G assign put
			-- Entry at index `i', if in index interval
			-- Was declared in FLAT_ARRAY as synonym of item.
		require -- from TABLE
			valid_key: valid_index (i)
		do
			Result := area.item (i - lower)
		end

	entry (i: INTEGER_32): G
			-- Entry at index `i', if in index interval
		require
			valid_key: valid_index (i)
		do
			Result := item (i)
		end

	has (v: G): BOOLEAN
			-- Does `v' appear in array?
			-- (Reference or object equality,
			-- based on object_comparison.)
		local
			i, nb: INTEGER_32
			l_area: like area
		do
			l_area := area
			nb := upper - lower
			if object_comparison and v /= Void then
				from
				until
					i > nb or Result
				loop
					Result := l_area.item (i) ~ v
					i := i + 1
				end
			else
				from
				until
					i > nb or Result
				loop
					Result := l_area.item (i) = v
					i := i + 1
				end
			end
		ensure -- from CONTAINER
			not_found_in_empty: Result implies not is_empty
		end

	item alias "[]" (i: INTEGER_32): G assign put
			-- Entry at index `i', if in index interval
			-- Was declared in FLAT_ARRAY as synonym of at.
		do
			Result := area.item (i - lower)
		end

feature -- Measurement

	capacity: INTEGER_32
			-- Number of available indices
			-- Was declared in FLAT_ARRAY as synonym of count.
		do
			Result := upper - lower + 1
		ensure -- from BOUNDED
			capacity_non_negative: Result >= 0
			consistent_with_bounds: Result = upper - lower + 1
		end

	count: INTEGER_32
			-- Number of available indices
			-- Was declared in FLAT_ARRAY as synonym of capacity.
		do
			Result := upper - lower + 1
		ensure -- from FINITE
			count_non_negative: Result >= 0
			consistent_with_bounds: Result = upper - lower + 1
		end

	Growth_percentage: INTEGER_32 = 50
			-- Percentage by which structure will grow automatically
			-- (from RESIZABLE)

	index_set: FLAT_INTEGER_INTERVAL
			-- Range of acceptable indexes
		do
			create Result.make (lower, upper)
		ensure then
			same_count: Result.count = count
			same_bounds: ((Result.lower = lower) and (Result.upper = upper))
		end

	lower: INTEGER_32
			-- Minimum index

	Minimal_increase: INTEGER_32 = 5
			-- Minimal number of additional items
			-- (from RESIZABLE)

	occurrences (v: G): INTEGER_32
			-- Number of times `v' appears in structure
		local
			i: INTEGER_32
		do
			if object_comparison then
				from
					i := lower
				until
					i > upper
				loop
					if item (i) ~ v then
						Result := Result + 1
					end
					i := i + 1
				end
			else
				from
					i := lower
				until
					i > upper
				loop
					if item (i) = v then
						Result := Result + 1
					end
					i := i + 1
				end
			end
		ensure -- from BAG
			non_negative_occurrences: Result >= 0
		end

	upper: INTEGER_32
			-- Maximum index

feature -- Comparison

	is_equal (other: like Current): BOOLEAN
			-- Is array made of the same items as `other'?
		local
			i: INTEGER_32
		do
			if other = Current then
				Result := True
			elseif lower = other.lower and then upper = other.upper and then object_comparison = other.object_comparison then
				if object_comparison then
					from
						Result := True
						i := lower
					until
						not Result or i > upper
					loop
						Result := item (i) ~ other.item (i)
						i := i + 1
					end
				else
					Result := area.same_items (other.area, 0, 0, count)
				end
			end
		end


feature -- Status report

	all_default: BOOLEAN
			-- Are all items set to default values?
		do
			if count > 0 then
				Result := ({G}).has_default and then area.filled_with (({G}).default, 0, upper - lower)
			else
				Result := True
			end
		ensure
			definition: Result = (count = 0 or else ((not attached item (upper) as i or else i = ({G}).default) and subarray (lower, upper - 1).all_default))
		end

	changeable_comparison_criterion: BOOLEAN
			-- May object_comparison be changed?
			-- (Answer: yes by default.)
			-- (from CONTAINER)
		do
			Result := True
		end

	extendible: BOOLEAN
			-- May items be added?
			-- (Answer: no, although array may be resized.)
		do
			Result := False
		end

	filled_with (v: G): BOOLEAN
			-- Are all itms set to `v'?
		do
			Result := area.filled_with (v, 0, upper - lower)
		ensure
			definition: Result = (count = 0 or else (item (upper) = v and subarray (lower, upper - 1).filled_with (v)))
		end

	full: BOOLEAN
			-- Is structure filled to capacity? (Answer: yes)
		require -- from  BOX
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
		do
			Result := has (v)
		end

	object_comparison: BOOLEAN
			-- Must search operations use equal rather than `='
			-- for comparing references? (Default: no, use `='.)
			-- (from CONTAINER)

	prunable: BOOLEAN
			-- May items be removed? (Answer: no.)
		do
			Result := False
		end

	resizable: BOOLEAN
			-- Can array be resized automatically?
		require -- from  BOUNDED
			True
		do
			Result := ({G}).has_default
		end

	same_items (other: like Current): BOOLEAN
			-- Do `other' and Current have same items?
		require
			other_not_void: other /= Void
		do
			if count = other.count then
				Result := area.same_items (other.area, 0, 0, count)
			end
		ensure
			definition: Result = ((count = other.count) and then (count = 0 or else (item (upper) = other.item (other.upper) and subarray (lower, upper - 1).same_items (other.subarray (other.lower, other.upper - 1)))))
		end


	valid_index (i: INTEGER_32): BOOLEAN
			-- Is `i' within the bounds of the array?
		do
			Result := (lower <= i) and then (i <= upper)
		end

	valid_index_set: BOOLEAN
		do
			Result := index_set.count = count
		end

feature -- Status setting

	compare_objects
			-- Ensure that future search operations will use equal
			-- rather than `=' for comparing references.
			-- (from CONTAINER)
		do
			object_comparison := True
		ensure -- from CONTAINER
			object_comparison
		end

	compare_references
			-- Ensure that future search operations will use `='
			-- rather than equal for comparing references.
			-- (from CONTAINER)
		do
			object_comparison := False
		ensure -- from CONTAINER
			reference_comparison: not object_comparison
		end

feature -- Element change

	enter (v: like item; i: INTEGER_32)
			-- Replace `i'-th entry, if in index interval, by `v'.
		require
			valid_key: valid_index (i)
		do
			area.put (v, i - lower)
		end

	fill_with (v: G)
			-- Set items between lower and upper with `v'.
		do
			area.fill_with (v, 0, upper - lower)
		ensure
			same_capacity: capacity = old capacity
			count_definition: count = old count
			filled: filled_with (v)
		end

	force (v: like item; i: INTEGER_32)
			-- Assign item `v' to `i'-th entry.
			-- Resize the array if `i' falls out of currently defined bounds; preserve existing items.
			-- In void-safe mode, if ({G}).has_default does not hold, then you can only insert at either
			-- `lower - 1' or `upper + 1' position in the FLAT_ARRAY.
		require
			has_default: ({G}).has_default or else i = lower - 1 or else i = upper + 1
		local
			old_size, new_size: INTEGER_32
			new_lower, new_upper: INTEGER_32
			offset: INTEGER_32
			l_increased_by_one: BOOLEAN
		do
			new_lower := lower.min (i)
			new_upper := upper.max (i)
			new_size := new_upper - new_lower + 1
			l_increased_by_one := (i = upper + 1) or (i = lower - 1)
			if empty_area then
				make_empty_area (new_size.max (additional_space))
				if not l_increased_by_one then
					area.fill_with (({G}).default, 0, new_size - 2)
				end
				area.extend (v)
			else
				old_size := area.capacity
				if new_size > old_size then
					set_area (area.aliased_resized_area (new_size.max (old_size + additional_space)))
				end
				if new_lower < lower then
					offset := lower - new_lower
					area.move_data (0, offset, capacity)
					if not l_increased_by_one then
						area.fill_with (({G}).default, 1, offset - 2)
					end
					area.put (v, 0)
				else
					if new_size > area.count then
						if not l_increased_by_one then
							area.fill_with (({G}).default, area.count, new_size - 2)
						end
						area.extend (v)
					else
						area.put (v, i - lower)
					end
				end
			end
			lower := new_lower
			upper := new_upper
		ensure
			inserted: item (i) = v
			higher_count: count >= old count
			lower_set: lower = (old lower).min (i)
			upper_set: upper = (old upper).max (i)
		end

	put (v: like item; i: INTEGER_32)
			-- Replace `i'-th entry, if in index interval, by `v'.
		require -- from TABLE
			valid_key: valid_index (i)
		do
			area.put (v, i - lower)
		ensure -- from TABLE
			inserted: item (i) = v
		end

	subcopy (other: FLAT_ARRAY [like item]; start_pos, end_pos, index_pos: INTEGER_32)
			-- Copy items of `other' within bounds `start_pos' and `end_pos'
			-- to current array starting at index `index_pos'.
		require
			other_not_void: other /= Void
			valid_start_pos: start_pos >= other.lower
			valid_end_pos: end_pos <= other.upper
			valid_bounds: start_pos <= end_pos + 1
			valid_index_pos: index_pos >= lower
			enough_space: (upper - index_pos) >= (end_pos - start_pos)
		do
			area.copy_data (other.area, start_pos - other.lower, index_pos - lower, end_pos - start_pos + 1)
		end

feature {FLAT_ARRAY} -- Element change

	set_area (other: like area)
			-- Make `other' the new area
			-- (from TO_SPECIAL)
		do
			area := other
		ensure -- from TO_SPECIAL
			area_set: area = other
		end

feature -- Removal

	clear_all
			-- Reset all items to default values.
		require
			has_default: ({G}).has_default
		do
			area.fill_with (({G}).default, 0, area.count - 1)
		ensure
			stable_lower: lower = old lower
			stable_upper: upper = old upper
			default_items: all_default
		end

	discard_items
			-- Reset all items to default values with reallocation.
		require
			has_default: ({G}).has_default
		do
			create area.make_filled (({G}).default, capacity)
		ensure
			default_items: all_default
		end

	keep_head (n: INTEGER_32)
			-- Remove all items except for the first `n';
			-- do nothing if `n' >= count.
		require
			non_negative_argument: n >= 0
		do
			if n < count then
				upper := lower + n - 1
				area := area.aliased_resized_area (n)
			end
		ensure
			new_count: count = n.min (old count)
			same_lower: lower = old lower
		end

	keep_tail (n: INTEGER_32)
			-- Remove all items except for the last `n';
			-- do nothing if `n' >= count.
		require
			non_negative_argument: n >= 0
		local
			nb: INTEGER_32
		do
			nb := count
			if n < nb then
				area.overlapping_move (nb - n, 0, n)
				lower := upper - n + 1
				area := area.aliased_resized_area (n)
			end
		ensure
			new_count: count = n.min (old count)
			same_upper: upper = old upper
		end

	remove_head (n: INTEGER_32)
			-- Remove first `n' items;
			-- if `n' > count, remove all.
		require
			n_non_negative: n >= 0
		do
			if n > count then
				upper := lower - 1
				area := area.aliased_resized_area (0)
			else
				keep_tail (count - n)
			end
		ensure
			new_count: count = (old count - n).max (0)
			same_upper: upper = old upper
		end

	remove_tail (n: INTEGER_32)
			-- Remove last `n' items;
			-- if `n' > count, remove all.
		require
			n_non_negative: n >= 0
		do
			if n > count then
				upper := lower - 1
				area := area.aliased_resized_area (0)
			else
				keep_head (count - n)
			end
		ensure
			new_count: count = (old count - n).max (0)
			same_lower: lower = old lower
		end

feature -- Resizing

	automatic_grow
			-- Change the capacity to accommodate at least
			-- Growth_percentage more items.
			-- (from RESIZABLE)
		require -- from RESIZABLE
			resizable: resizable
		do
			grow (capacity + additional_space)
		ensure -- from RESIZABLE
			increased_capacity: capacity >= old capacity + old additional_space
		end

	conservative_resize (min_index, max_index: INTEGER_32)
		obsolete " `conservative_resize' is not void-safe statically. Use `conservative_resize_with_default' instead. [07-2010]"
			-- Rearrange array so that it can accommodate
			-- indices down to `min_index' and up to `max_index'.
			-- Do not lose any previously entered item.
		require
			good_indices: min_index <= max_index
			has_default: ({G}).has_default
		do
			conservative_resize_with_default (({G}).default, min_index, max_index)
		ensure
			no_low_lost: lower = min_index or else lower = old lower
			no_high_lost: upper = max_index or else upper = old upper
		end

	conservative_resize_with_default (a_default_value: G; min_index, max_index: INTEGER_32)
			-- Rearrange array so that it can accommodate
			-- indices down to `min_index' and up to `max_index'.
			-- Do not lose any previously entered item.
		require
			good_indices: min_index <= max_index
		local
			new_size: INTEGER_32
			new_lower, new_upper: INTEGER_32
			offset: INTEGER_32
		do
			if empty_area then
				set_area (area.aliased_resized_area_with_default (a_default_value, max_index - min_index + 1))
				lower := min_index
				upper := max_index
			else
				new_lower := min_index.min (lower)
				new_upper := max_index.max (upper)
				new_size := new_upper - new_lower + 1
				if new_size > area.count then
					set_area (area.aliased_resized_area_with_default (a_default_value, new_size))
				end
				if new_lower < lower then
					offset := lower - new_lower
					area.move_data (0, offset, upper - lower + 1)
					area.fill_with (a_default_value, 0, offset - 1)
				end
				lower := new_lower
				upper := new_upper
			end
		ensure
			no_low_lost: lower = min_index or else lower = old lower
			no_high_lost: upper = max_index or else upper = old upper
		end

	grow (i: INTEGER_32)
			-- Change the capacity to at least `i'.
		require -- from RESIZABLE
			resizable: resizable
		do
			if i > capacity then
				conservative_resize_with_default (({G}).default, lower, upper + i - capacity)
			end
		ensure -- from RESIZABLE
			new_capacity: capacity >= i
		end

	rebase (a_lower: like lower)
			-- Without changing the actual content of `Current' we set lower to `a_lower'
			-- and upper accordingly to `a_lower + count - 1'.
		local
			l_old_lower: like lower
		do
			l_old_lower := lower
			lower := a_lower
			upper := a_lower + (upper - l_old_lower)
		ensure
			lower_set: lower = a_lower
			upper_set: upper = a_lower + old count - 1
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
			if n < capacity then
				area := area.aliased_resized_area (n)
			end
		ensure -- from RESIZABLE
			same_count: count = old count
			minimal_capacity: capacity = count
			same_items: same_items (old twin)
		end

feature -- Conversion

	linear_representation: FLAT_DYNAMIC_LIST [G]
			-- Representation as a linear structure
		local
			temp: FLAT_ARRAYED_LIST [G]
			i: INTEGER_32
		do
--			create temp.make (capacity)
--			from
--				i := lower
--			until
--				i > upper
--			loop
--				temp.extend (item (i))
--				i := i + 1
--			end
--			Result := temp
		end

feature -- Duplication

	copy (other: like Current)
			-- Reinitialize by copying all the items of `other'.
			-- (This is also used by clone.)
		do
			if other /= Current then
				standard_copy (other)
				set_area (other.area.twin)
			end
		ensure then
			equal_areas: area ~ other.area
		end

	subarray (start_pos, end_pos: INTEGER_32): FLAT_ARRAY [G]
			-- Array made of items of current array within
			-- bounds `start_pos' and `end_pos'.
		require
			valid_start_pos: valid_index (start_pos)
			valid_end_pos: end_pos <= upper
			valid_bounds: (start_pos <= end_pos) or (start_pos = end_pos + 1)
		do
			if start_pos <= end_pos then
				create Result.make_filled (item (start_pos), start_pos, end_pos)
				Result.subcopy (Current, start_pos, end_pos, start_pos)
			else
				create Result.make_empty
				Result.rebase (start_pos)
			end
		ensure
			lower: Result.lower = start_pos
			upper: Result.upper = end_pos
		end

feature {FLAT_ARRAY, FLAT_ARRAYED_LIST, FLAT_ARRAYED_SET} -- Implementation

	area: SPECIAL [G]
			-- Special data zone
			-- (from TO_SPECIAL)

	additional_space: INTEGER_32
			-- Proposed number of additional items
			-- (from RESIZABLE)
		do
			Result := (capacity // 2).max (Minimal_increase)
		ensure -- from RESIZABLE
			at_least_one: Result >= 1
		end

	to_c: ANY
			-- Address of actual sequence of values,
			-- for passing to external (non-Eiffel) routines.
		require
			not_is_dotnet: not {PLATFORM}.is_dotnet
		do
			Result := area
		end

	to_special: SPECIAL [G]
			-- 'area'.
		do
			Result := area
		ensure
			to_special_not_void: Result /= Void
		end

feature {NONE} -- Implementation

	empty_area: BOOLEAN
			-- Is area empty?
		do
			Result := area = Void or else area.capacity = 0
		end

feature -- Iteration

	do_all (action: PROCEDURE [ANY, TUPLE [G]])
			-- Apply `action' to every item, from first to last.
			-- Semantics not guaranteed if `action' changes the structure;
			-- in such a case, apply iterator to clone of structure instead.
		require
			action_not_void: action /= Void
		do
			area.do_all_in_bounds (action, 0, count - 1)
		end

	do_all_with_index (action: PROCEDURE [ANY, TUPLE [G, INTEGER_32]])
			-- Apply `action' to every item, from first to last.
			-- `action' receives item and its index.
			-- Semantics not guaranteed if `action' changes the structure;
			-- in such a case, apply iterator to clone of structure instead.
		local
			i, j, nb: INTEGER_32
			l_area: like area
		do
			from
				i := 0
				j := lower
				nb := count - 1
				l_area := area
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
		require
			action_not_void: action /= Void
			test_not_void: test /= Void
		do
			area.do_if_in_bounds (action, test, 0, count - 1)
		end

	do_if_with_index (action: PROCEDURE [ANY, TUPLE [G, INTEGER_32]]; test: PREDICATE [ANY, TUPLE [G]])
			-- Apply `action' to every item that satisfies `test', from first to last.
			-- `action' and `test' receive the item and its index.
			-- Semantics not guaranteed if `action' or `test' changes the structure;
			-- in such a case, apply iterator to clone of structure instead.
		local
			i, j, nb: INTEGER_32
			l_area: like area
		do
			from
				i := 0
				j := lower
				nb := count - 1
				l_area := area
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
		require
			test_not_void: test /= Void
		do
			Result := area.for_all_in_bounds (test, 0, count - 1)
		end

	there_exists (test: PREDICATE [ANY, TUPLE [G]]): BOOLEAN
			-- Is `test' true for at least one item?
		require
			test_not_void: test /= Void
		do
			Result := area.there_exists_in_bounds (test, 0, count - 1)
		end

invariant
	area_exists: area /= Void
	consistent_size: capacity = upper - lower + 1
	non_negative_count: count >= 0
	index_set_has_same_count: valid_index_set

		-- from RESIZABLE
	increase_by_at_least_one: Minimal_increase >= 1

		-- from BOUNDED
	valid_count: count <= capacity
	full_definition: full = (count = capacity)

		-- from FINITE
	empty_definition: is_empty = (count = 0)

end -- class FLAT_ARRAY
