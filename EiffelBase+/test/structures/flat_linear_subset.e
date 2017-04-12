deferred class
	FLAT_LINEAR_SUBSET [G]

feature -- Access

	has (v: G): BOOLEAN
			-- Does structure include `v'?
			-- (Reference or object equality,
			-- based on object_comparison.)
			-- (from CONTAINER)
		deferred
		ensure -- from CONTAINER
			not_found_in_empty: Result implies not is_empty
		end

	index: INTEGER_32
			-- Current index
		deferred
		end

	item: G
			-- Current item
			-- (from TRAVERSABLE_SUBSET)
		require -- from TRAVERSABLE_SUBSET
			not_off: not off
		deferred
		end

feature -- Measurement

	count: INTEGER_32
			-- Number of items
			-- (from TRAVERSABLE_SUBSET)
		deferred
		end

feature -- Comparison

	disjoint (other: FLAT_LINEAR_SUBSET [G]): BOOLEAN
			-- Do current set and `other' have no
			-- items in common?
			-- (from TRAVERSABLE_SUBSET)
		require -- from SUBSET
			set_exists: other /= Void
			same_rule: object_comparison = other.object_comparison
		local
			s: FLAT_SUBSET_STRATEGY [G]
		do
			if not is_empty and not other.is_empty then
				s := subset_strategy (other)
				Result := s.disjoint (Current, other)
			else
				Result := True
			end
		end

	is_subset (other: FLAT_LINEAR_SUBSET [G]): BOOLEAN
			-- Is current set a subset of `other'?
			-- (from TRAVERSABLE_SUBSET)
		require -- from SUBSET
			set_exists: other /= Void
			same_rule: object_comparison = other.object_comparison
		do
			if not other.is_empty and then count <= other.count then
				from
					start
				until
					off or else not other.has (item)
				loop
					forth
				end
				if off then
					Result := True
				end
			elseif is_empty then
				Result := True
			end
		end

	is_superset (other: FLAT_LINEAR_SUBSET [G]): BOOLEAN
			-- Is current set a superset of `other'?
			-- (from SUBSET)
		require -- from SUBSET
			set_exists: other /= Void
			same_rule: object_comparison = other.object_comparison
		do
			Result := other.is_subset (Current)
		end

feature -- Status report

	after: BOOLEAN
			-- Is cursor behind last item?
			-- (from TRAVERSABLE_SUBSET)
		deferred
		end

	before: BOOLEAN
			-- Is cursor at left from first item?
		deferred
		end

	extendible: BOOLEAN
			-- May new items be added?
			-- (from COLLECTION)
		deferred
		end

	is_empty: BOOLEAN
			-- Is container empty?
			-- (from TRAVERSABLE_SUBSET)
		deferred
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

	islast: BOOLEAN
			-- Is cursor at last item?
		deferred
		end

	object_comparison: BOOLEAN
			-- Must search operations use equal rather than `='
			-- for comparing references? (Default: no, use `='.)
			-- (from CONTAINER)

	off: BOOLEAN
			-- Is cursor off the active items?
			-- (from TRAVERSABLE_SUBSET)
		deferred
		end

	prunable: BOOLEAN
			-- May items be removed?
			-- (from COLLECTION)
		deferred
		end

	valid_index (n: INTEGER_32): BOOLEAN
			-- Is `n' a valid index?
		deferred
		ensure
			index_valid: 0 <= n and n <= count + 1
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

	forth
			-- Move cursor to next element.
			-- (from TRAVERSABLE_SUBSET)
		require -- from TRAVERSABLE_SUBSET
			not_after: not after
		deferred
		end

	go_i_th (i: INTEGER_32)
			-- Move cursor to `i'-th item.
		require
			valid_index: valid_index (i)
		deferred
		ensure
			cursor_moved: index = i
		end

	start
			-- Move cursor to first item.
			-- (from TRAVERSABLE_SUBSET)
		deferred
		end

feature -- Element change

	extend (v: G)
			-- Ensure that set includes `v'.
			-- Was declared in SET as synonym of put.
			-- (from SET)
		require -- from COLLECTION
			extendible: extendible
		deferred
		ensure -- from COLLECTION
			item_inserted: is_inserted (v)
			in_set_already: old has (v) implies (count = old count)
			added_to_set: not old has (v) implies (count = old count + 1)
		end

	fill (other: FLAT_LINEAR_SUBSET [G])
			-- Fill with as many items of `other' as possible.
			-- The representations of `other' and current structure
			-- need not be the same.
			-- (from COLLECTION)
		require -- from COLLECTION
			other_not_void: other /= Void
			extendible: extendible
		local
			lin_rep: FLAT_LINEAR_SUBSET [G]
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

	merge (other: FLAT_LINEAR_SUBSET [G])
			-- Add all items of `other'.
			-- (from TRAVERSABLE_SUBSET)
		require -- from SUBSET
			set_exists: other /= Void
			same_rule: object_comparison = other.object_comparison
		local
			l: FLAT_LINEAR_SUBSET [G]
		do
			if attached {FLAT_LINEAR_SUBSET [G]} other as lin_rep then
				l := lin_rep
			else
				l := other.linear_representation
			end
			from
				l.start
			until
				l.off
			loop
				extend (l.item)
				l.forth
			end
		end

	move_item (v: G)
			-- Move `v' to the left of cursor.
		require
			item_exists: v /= Void
			item_in_set: has (v)
		local
			idx: INTEGER_32
			found: BOOLEAN
		do
			idx := index
			from
				start
			until
				found or after
			loop
				if object_comparison then
					found := v ~ item
				else
					found := (v = item)
				end
				if not found then
					forth
				end
			end
			check
				found: found and not after
			end
			remove
			go_i_th (idx)
			put_left (v)
		end

	put (v: G)
			-- Ensure that set includes `v'.
			-- Was declared in SET as synonym of extend.
			-- (from SET)
		require -- from COLLECTION
			extendible: extendible
		deferred
		ensure -- from COLLECTION
			item_inserted: is_inserted (v)
			in_set_already: old has (v) implies (count = old count)
			added_to_set: not old has (v) implies (count = old count + 1)
		end

	put_left (v: G)
			-- Insert `v' before the cursor.
		require
			item_exists: v /= Void
			not_before: not before
		deferred
		ensure
			cursor_position_unchanged: index = old index + 1
		end

feature -- Removal

	changeable_comparison_criterion: BOOLEAN
			-- May object_comparison be changed?
			-- (Answer: only if set empty; otherwise insertions might
			-- introduce duplicates, destroying the set property.)
			-- (from SET)
		require -- from  CONTAINER
			True
		do
			Result := is_empty
		ensure then -- from SET
			only_on_empty: Result = is_empty
		end

	prune (v: G)
			-- Remove `v' if present.
			-- (from SET)
		require -- from COLLECTION
			prunable: prunable
		deferred
		ensure then -- from SET
			removed_count_change: old has (v) implies (count = old count - 1)
			not_removed_no_count_change: not old has (v) implies (count = old count)
			item_deleted: not has (v)
		end

	prune_all (v: G)
			-- Remove all occurrences of `v'.
			-- (Reference or object equality,
			-- based on object_comparison.)
			-- (from COLLECTION)
		require -- from COLLECTION
			prunable: prunable
		do
			from
			until
				not has (v)
			loop
				prune (v)
			end
		ensure -- from COLLECTION
			no_more_occurrences: not has (v)
		end

	remove
			-- Remove current item.
			-- (from TRAVERSABLE_SUBSET)
		require -- from TRAVERSABLE_SUBSET
			not_off: not off
		deferred
		end

	wipe_out
			-- Remove all items.
			-- (from COLLECTION)
		require -- from COLLECTION
			prunable: prunable
		deferred
		ensure -- from COLLECTION
			wiped_out: is_empty
		end

feature -- Conversion

	linear_representation: FLAT_LINEAR_SUBSET [G]
			-- Representation as a linear structure
			-- (from CONTAINER)
		deferred
		end

feature -- Duplication

	duplicate (n: INTEGER_32): FLAT_LINEAR_SUBSET [G]
			-- New structure containing min (`n', count)
			-- items from current structure
			-- (from SUBSET)
		require -- from SUBSET
			non_negative: n >= 0
		deferred
		ensure -- from SUBSET
			correct_count_1: n <= count implies Result.count = n
			correct_count_2: n >= count implies Result.count = count
		end

feature -- Basic operations

	intersect (other: FLAT_LINEAR_SUBSET [G])
			-- Remove all items not in `other'.
			-- No effect if `other' is_empty.
			-- (from TRAVERSABLE_SUBSET)
		require -- from SUBSET
			set_exists: other /= Void
			same_rule: object_comparison = other.object_comparison
		do
			if not other.is_empty then
				from
					start
					other.start
				until
					off
				loop
					if other.has (item) then
						forth
					else
						remove
					end
				end
			else
				wipe_out
			end
		ensure -- from SUBSET
			is_subset_other: is_subset (other)
		end

	subtract (other: FLAT_LINEAR_SUBSET [G])
			-- Remove all items also in `other'.
			-- (from TRAVERSABLE_SUBSET)
		require -- from SUBSET
			set_exists: other /= Void
			same_rule: object_comparison = other.object_comparison
		do
			if not (other.is_empty or is_empty) then
				from
					start
					other.start
				until
					off
				loop
					if other.has (item) then
						remove
					else
						forth
					end
				end
			end
		ensure -- from SUBSET
			is_disjoint: disjoint (other)
		end

	symdif (other: FLAT_LINEAR_SUBSET [G])
			-- Remove all items also in `other', and add all
			-- items of `other' not already present.
			-- (from TRAVERSABLE_SUBSET)
		require -- from SUBSET
			set_exists: other /= Void
			same_rule: object_comparison = other.object_comparison
		local
			s: FLAT_SUBSET_STRATEGY [G]
		do
			if not other.is_empty then
				if is_empty then
					from
						other.start
					until
						other.after
					loop
						extend (other.item)
					end
				else
					s := subset_strategy (other)
					s.symdif (Current, other)
				end
			end
		end

feature {NONE} -- Implementation

	subset_strategy (other: FLAT_LINEAR_SUBSET [G]): FLAT_SUBSET_STRATEGY [G]
			-- Subset strategy suitable for the type of the contained elements.
			-- (from TRAVERSABLE_SUBSET)
		require -- from TRAVERSABLE_SUBSET
			not_empty: not is_empty
		do
			start
			check
				not_off: not off
			end
			Result := subset_strategy_selection (item, other)
		end

	subset_strategy_selection (v: G; other: FLAT_LINEAR_SUBSET [G]): FLAT_SUBSET_STRATEGY [G]
			-- Strategy to calculate several subset features selected depending
			-- on the dynamic type of `v' and `other'
		require -- from TRAVERSABLE_SUBSET
			item_exists: v /= Void
			other_exists: other /= Void
		do
			if attached {HASHABLE} v as h then
				create {FLAT_SUBSET_STRATEGY_HASHABLE [G]} Result
			else
				create {FLAT_SUBSET_STRATEGY_GENERIC [G]} Result
			end
		ensure -- from TRAVERSABLE_SUBSET
			strategy_set: Result /= Void
		end

invariant
	before_definition: before = (index = 0)

		-- from TRAVERSABLE_SUBSET
	empty_definition: is_empty = (count = 0)
	count_range: count >= 0

end -- class LINEAR_SUBSET

