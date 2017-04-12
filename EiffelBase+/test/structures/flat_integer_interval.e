class
	FLAT_INTEGER_INTERVAL

inherit
	FLAT_READABLE_INDEXABLE [INTEGER]
		redefine
			copy,
			is_equal
		end

create
	make

feature {NONE} -- Initialization

	make (min_index, max_index: INTEGER_32)
			-- Set up interval to have bounds `min_index' and
			-- `max_index' (empty if `min_index' > `max_index')
		do
			lower_defined := True
			upper_defined := True
			if min_index <= max_index then
				lower_internal := min_index
				upper_internal := max_index
			else
				lower_internal := 1
				upper_internal := 0
			end
		ensure
			lower_defined: lower_defined
			upper_defined: upper_defined
			set_if_non_empty: (min_index <= max_index) implies ((lower = min_index) and (upper = max_index))
			empty_if_not_in_order: (min_index > max_index) implies is_empty
		end

feature -- Initialization

	adapt (other: FLAT_INTEGER_INTERVAL)
			-- Reset to be the same interval as `other'.
		require
			other_not_void: other /= Void
		do
			lower_internal := other.lower_internal
			upper_internal := other.upper_internal
			lower_defined := other.lower_defined
			upper_defined := other.upper_defined
		ensure
			same_lower: lower = other.lower
			same_upper: upper = other.upper
			same_lower_defined: lower_defined = other.lower_defined
			same_upper_defined: upper_defined = other.upper_defined
		end

feature -- Access

	at alias "@" (i: INTEGER_32): INTEGER_32
			-- Entry at index `i', if in index interval
			-- Was declared in FLAT_INTEGER_INTERVAL as synonym of item.
		require -- from TABLE
			valid_key: valid_index (i)
		do
			Result := i
		end

	has (v: INTEGER_32): BOOLEAN
			-- Does `v' appear in interval?
			-- Was declared in FLAT_INTEGER_INTERVAL as synonym of valid_index.
		do
			Result := (upper_defined implies v <= upper) and (lower_defined implies v >= lower)
		ensure -- from CONTAINER
			not_found_in_empty: Result implies not is_empty
			iff_within_bounds: Result = ((upper_defined implies v <= upper) and (lower_defined implies v >= lower))
		end

	item alias "[]" (i: INTEGER_32): INTEGER_32
			-- Entry at index `i', if in index interval
			-- Was declared in FLAT_INTEGER_INTERVAL as synonym of at.
		do
			Result := i
		end

	lower: INTEGER_32
			-- Smallest value in interval
		do
			Result := lower_internal
		end

	lower_defined: BOOLEAN
			-- Is there a lower bound?

	upper: INTEGER_32
			-- Largest value in interval
		do
			Result := upper_internal
		end

	upper_defined: BOOLEAN
			-- Is there an upper bound?

	valid_index (v: INTEGER_32): BOOLEAN
			-- Does `v' appear in interval?
			-- Was declared in FLAT_INTEGER_INTERVAL as synonym of has.
		do
			Result := (upper_defined implies v <= upper) and (lower_defined implies v >= lower)
		end

feature -- Measurement

	capacity: INTEGER_32
			-- Maximum number of items in interval
			-- (here the same thing as count)
		do
			check
				terminal: upper_defined and lower_defined
			end
			Result := count
		ensure -- from BOUNDED
			capacity_non_negative: Result >= 0
		end

	count: INTEGER_32
			-- Number of items in interval
		do
			check
				finite: upper_defined and lower_defined
			end
			if upper_defined and lower_defined then
				Result := upper - lower + 1
			end
		ensure -- from FINITE
			count_non_negative: Result >= 0
			definition: Result = upper - lower + 1
		end

	Growth_percentage: INTEGER_32 = 50
			-- Percentage by which structure will grow automatically
			-- (from RESIZABLE)

	index_set: FLAT_INTEGER_INTERVAL
			-- Range of acceptable indexes
			-- (here: the interval itself)
		do
			Result := Current
		end

	Minimal_increase: INTEGER_32 = 5
			-- Minimal number of additional items
			-- (from RESIZABLE)

	occurrences (v: INTEGER_32): INTEGER_32
			-- Number of times `v' appears in structure
		do
			if has (v) then
				Result := 1
			end
		ensure -- from BAG
			non_negative_occurrences: Result >= 0
			one_iff_in_bounds: Result = 1 implies has (v)
			zero_otherwise: Result /= 1 implies Result = 0
		end

feature -- Comparison

	is_equal (other: like Current): BOOLEAN
			-- Is array made of the same items as `other'?
		do
			Result := (lower_defined implies (other.lower_defined and lower = other.lower)) and (upper_defined implies (other.upper_defined and upper = other.upper))
		ensure then
			iff_same_bounds: Result = ((lower_defined implies (other.lower_defined and lower = other.lower)) and (upper_defined implies (other.upper_defined and upper = other.upper)))
		end


feature -- Status report

	all_cleared: BOOLEAN
			-- Are all items set to default values?
		do
			Result := ((lower = 0) and (upper = 0))
		ensure then
			iff_at_zero: Result = ((lower = 0) and (upper = 0))
		end

	extendible: BOOLEAN
			-- May new items be added?
			-- Answer: yes
		do
			Result := True
		end

	full: BOOLEAN
			-- Is structure full?
			-- (from BOUNDED)
		do
			Result := (count = capacity)
		end

	is_empty: BOOLEAN
			-- Is structure empty?
			-- (from FINITE)
		require -- from  CONTAINER
			True
		do
			Result := (count = 0)
		end

	is_inserted (v: INTEGER_32): BOOLEAN
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
			-- May individual items be removed?
			-- Answer: no
		do
			Result := False
		end

	resizable: BOOLEAN
			-- May capacity be changed? (Answer: yes.)
			-- (from RESIZABLE)
		do
			Result := True
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

feature -- Element change

	extend (v: INTEGER_32)
			-- Make sure that interval goes all the way
			-- to `v' (up or down).
			-- Was declared in FLAT_INTEGER_INTERVAL as synonym of put.
		require -- from COLLECTION
			extendible: extendible
		do
			if v < lower then
				lower_internal := v
			elseif v > upper then
				upper_internal := v
			end
		ensure -- from COLLECTION
			item_inserted: is_inserted (v)
			in_set_already: old has (v) implies (count = old count)
			added_to_set: not old has (v) implies (count = old count + 1)
			extended_down: lower = (old lower).min (v)
			extended_up: upper = (old upper).max (v)
		end

	fill (other: FLAT_DYNAMIC_LIST [INTEGER_32])
			-- Fill with as many items of `other' as possible.
			-- The representations of `other' and current structure
			-- need not be the same.
			-- (from COLLECTION)
		require -- from COLLECTION
			other_not_void: other /= Void
			extendible: extendible
		local
			lin_rep: FLAT_DYNAMIC_LIST [INTEGER_32]
		do
			lin_rep := other.linear_representation
			from
				lin_rep.start
			until
				not extendible or else lin_rep.off
			loop
				extend (lin_rep.item)
				lin_rep.forth
			end
		end

	put (v: INTEGER_32)
			-- Make sure that interval goes all the way
			-- to `v' (up or down).
			-- Was declared in FLAT_INTEGER_INTERVAL as synonym of extend.
		require -- from COLLECTION
			extendible: extendible
		do
			if v < lower then
				lower_internal := v
			elseif v > upper then
				upper_internal := v
			end
		ensure -- from COLLECTION
			item_inserted: is_inserted (v)
			in_set_already: old has (v) implies (count = old count)
			added_to_set: not old has (v) implies (count = old count + 1)
			extended_down: lower = (old lower).min (v)
			extended_up: upper = (old upper).max (v)
		end

feature -- Removal

	changeable_comparison_criterion: BOOLEAN
			-- May object_comparison be changed?
			-- (Answer: only if set empty; otherwise insertions might
			-- introduce duplicates, destroying the set property.)
			-- (from SET)
		do
			Result := is_empty
		ensure then -- from SET
			only_on_empty: Result = is_empty
		end

	wipe_out
			-- Remove all items.
--		require
--			prunable: prunable		
		do
			lower_defined := True
			upper_defined := True
			lower_internal := 1
			upper_internal := 0
		ensure -- from COLLECTION
			wiped_out: is_empty
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

	grow (i: INTEGER_32)
			-- Ensure that capacity is at least `i'.
		require -- from RESIZABLE
			resizable: resizable
		do
			if capacity < i then
				resize (lower, lower + i - 1)
			end
		ensure -- from RESIZABLE
			new_capacity: capacity >= i
			no_loss_from_bottom: lower <= old lower
			no_loss_from_top: upper >= old upper
		end

	resize (min_index, max_index: INTEGER_32)
			-- Rearrange interval to go from at most
			-- `min_index' to at least `max_index',
			-- encompassing previous bounds.
		do
			lower_internal := min_index.min (lower)
			upper_internal := max_index.max (upper)
		end

	resize_exactly (min_index, max_index: INTEGER_32)
			-- Rearrange interval to go from
			-- `min_index' to `max_index'.
		do
			lower_internal := min_index
			upper_internal := max_index
		end

	trim
			-- Decrease capacity to the minimum value.
			-- Apply to reduce allocated storage.
		do
			check
				minimal_capacity: capacity = count
			end
		ensure -- from RESIZABLE
			same_count: count = old count
			minimal_capacity: capacity = count
		end

feature -- Conversion

	as_array: FLAT_ARRAY [INTEGER_32]
			-- Plain array containing interval's items
		local
			i: INTEGER_32
		do
			create Result.make_empty
			Result.rebase (lower)
			from
				i := lower
			until
				i > upper
			loop
				Result.force (i, i)
				i := i + 1
			end
		ensure
			same_lower: Result.lower = lower
			same_upper: Result.upper = upper
		end

	linear_representation: FLAT_DYNAMIC_LIST [INTEGER_32]
			-- Representation as a linear structure
		do
			check
				terminal: upper_defined and lower_defined
			end
			Result := as_array.linear_representation
		end

feature -- Duplication

	copy (other: like Current)
			-- Reset to be the same interval as `other'.
		do
			if other /= Current then
				standard_copy (other)
			end
		end

	subinterval (start_pos, end_pos: INTEGER_32): like Current
			-- Interval made of items of current array within
			-- bounds `start_pos' and `end_pos'.
		do
			create Result.make (start_pos, end_pos)
		end

feature {FLAT_INTEGER_INTERVAL} -- Implementation

	lower_internal: INTEGER_32
			-- See `lower`.

	upper_internal: INTEGER_32
			-- See `upper`.

	additional_space: INTEGER_32
			-- Proposed number of additional items
			-- (from RESIZABLE)
		do
			Result := (capacity // 2).max (Minimal_increase)
		ensure -- from RESIZABLE
			at_least_one: Result >= 1
		end

feature -- Iteration

	do_all (action: PROCEDURE [ANY, TUPLE [INTEGER_32]])
			-- Apply `action' to every item of current interval.
		require
			action_exists: action /= Void
			finite: upper_defined and lower_defined
		local
			i, nb: INTEGER_32
		do
			from
				i := lower
				nb := upper
			until
				i > nb
			loop
				action.call ([i])
				i := i + 1
			end
		end

	exists (condition: PREDICATE [ANY, TUPLE [INTEGER_32]]): BOOLEAN
			-- Does at least one of  interval's values
			-- satisfy `condition'?
		require
			finite: upper_defined and lower_defined
			condition_not_void: condition /= Void
		local
			i: INTEGER_32
		do
			from
				i := lower
			until
				i > upper or else condition.item ([i])
			loop
				i := i + 1
			end
			Result := (i <= upper)
		ensure
			consistent_with_count: Result = (hold_count (condition) > 0)
		end

	exists1 (condition: PREDICATE [ANY, TUPLE [INTEGER_32]]): BOOLEAN
			-- Does exactly one of  interval's values
			-- satisfy `condition'?
		require
			finite: upper_defined and lower_defined
			condition_not_void: condition /= Void
		do
			Result := (hold_count (condition) = 1)
		ensure
			consistent_with_count: Result = (hold_count (condition) = 1)
		end

	for_all (condition: PREDICATE [ANY, TUPLE [INTEGER_32]]): BOOLEAN
			-- Do all interval's values satisfy `condition'?
		require
			finite: upper_defined and lower_defined
			condition_not_void: condition /= Void
		local
			i: INTEGER_32
		do
			from
				Result := True
				i := lower
			until
				(i > upper) or else (not condition.item ([i]))
			loop
				i := i + 1
			end
			Result := (i > upper)
		ensure
			consistent_with_count: Result = (hold_count (condition) = count)
		end

	hold_count (condition: PREDICATE [ANY, TUPLE [INTEGER_32]]): INTEGER_32
			-- Number of  interval's values that
			-- satisfy `condition'
		require
			finite: upper_defined and lower_defined
			condition_not_void: condition /= Void
		local
			i: INTEGER_32
		do
			from
				i := lower
			until
				i > upper
			loop
				if condition.item ([i]) then
					Result := Result + 1
				end
				i := i + 1
			end
		ensure
			non_negative: Result >= 0
		end

invariant
	count_definition: upper_defined and lower_defined implies count = upper - lower + 1
	index_set_is_range: index_set ~ Current
	not_infinite: upper_defined and lower_defined

		-- from RESIZABLE
	increase_by_at_least_one: Minimal_increase >= 1

		-- from BOUNDED
	valid_count: count <= capacity
	full_definition: full = (count = capacity)

		-- from FINITE
	empty_definition: is_empty = (count = 0)

end -- class FLAT_INTEGER_INTERVAL

