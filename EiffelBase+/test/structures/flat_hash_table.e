class
	FLAT_HASH_TABLE [G, K -> HASHABLE]

inherit
	ANY
		redefine
			copy,
			is_equal
		end

create
	make

feature -- Initialization

	accommodate (n: INTEGER_32)
			-- Reallocate table with enough space for `n' items;
			-- keep all current items.
		require
			n >= 0
		local
			i, nb: INTEGER_32
			new_table: like Current
			l_content: like content
			l_keys: like keys
		do
			from
				new_table := empty_duplicate (keys.count.max (n))
				l_content := content
				l_keys := keys
				nb := l_keys.count
			until
				i = nb
			loop
				if occupied (i) then
					new_table.put (l_content.item (i), l_keys.item (i))
				end
				i := i + 1
			end
			if has_default then
				i := indexes_map.item (capacity)
				new_table.put (l_content.item (i), keys.item (i))
			end
			set_content (new_table.content)
			set_keys (new_table.keys)
			set_deleted_marks (new_table.deleted_marks)
			set_indexes_map (new_table.indexes_map)
			capacity := new_table.capacity
			iteration_position := new_table.iteration_position
		ensure
			count_not_changed: count = old count
			breathing_space: count < capacity
		end

	make (n: INTEGER_32)
			-- Allocate hash table for at least `n' items.
			-- The table will be resized automatically
			-- if more than `n' items are inserted.
		require
			n_non_negative: n >= 0
		local
			clever: PRIMES
			l_default_value: G
			l_default_key: K
			l_size: INTEGER_32
		do
			create clever
			l_size := n.max (Minimum_capacity)
			l_size := l_size + l_size // 2 + 1
			l_size := clever.higher_prime (l_size)
			capacity := l_size
			create content.make_empty (n + 1)
			create keys.make_empty (n + 1)
			create deleted_marks.make_filled (False, n + 1)
			create indexes_map.make_filled (Ht_impossible_position, l_size + 1)
			iteration_position := n + 1
			count := 0
			deleted_item_position := Ht_impossible_position
			control := 0
			found_item := l_default_value
			has_default := False
			item_position := 0
			ht_lowest_deleted_position := Ht_max_position
			ht_deleted_item := l_default_value
			ht_deleted_key := l_default_key
		ensure
			breathing_space: n < capacity
			more_than_minimum: capacity > Minimum_capacity
			no_status: not special_status
		end

feature -- Access

	at alias "@" (key: K): G assign force
			-- Item associated with `key', if present
			-- otherwise default value of type `G'
			-- Was declared in FLAT_HASH_TABLE as synonym of item.
		require -- from TABLE
			valid_key: valid_key (key)
		local
			old_control, old_position: INTEGER_32
		do
			old_control := control
			old_position := item_position
			internal_search (key)
			if found then
				Result := content.item (position)
			end
			control := old_control
			item_position := old_position
		ensure then
			default_value_if_not_present: (not (has (key))) implies (Result = computed_default_value)
		end

	current_keys: FLAT_ARRAY [K]
			-- New array containing actually used keys, from 1 to count
		local
			j: INTEGER_32
			old_iteration_position: INTEGER_32
		do
			if is_empty then
				create Result.make_empty
			else
				old_iteration_position := iteration_position
				from
					start
					create Result.make_filled (key_for_iteration, 1, count)
					j := 1
					forth
				until
					off
				loop
					j := j + 1
					Result.put (key_for_iteration, j)
					forth
				end
				iteration_position := old_iteration_position
			end
		ensure
			good_count: Result.count = count
		end

	cursor: FLAT_HASH_TABLE_CURSOR
			-- Current cursor position
		do
			create {FLAT_HASH_TABLE_CURSOR} Result.make (iteration_position)
		ensure
			cursor_not_void: Result /= Void
		end

	found_item: G
			-- Item, if any, yielded by last search operation

	has (key: K): BOOLEAN
			-- Is there an item in the table with key `key'?
		local
			old_control, old_position: INTEGER_32
		do
			old_control := control
			old_position := item_position
			internal_search (key)
			Result := found
			control := old_control
			item_position := old_position
		ensure then
			default_case: (key = computed_default_key) implies (Result = has_default)
		end

	has_item (v: G): BOOLEAN
			-- Does structure include `v'?
			-- (Reference or object equality,
			-- based on object_comparison.)
		local
			i, nb: INTEGER_32
			l_content: like content
		do
			if has_default then
				Result := (v = content.item (indexes_map.item (capacity)))
			end
			if not Result then
				l_content := content
				nb := l_content.count
				if object_comparison then
					from
					until
						i = nb or else Result
					loop
						Result := occupied (i) and then (v ~ l_content.item (i))
						i := i + 1
					end
				else
					from
					until
						i = nb or else Result
					loop
						Result := occupied (i) and then (v = l_content.item (i))
						i := i + 1
					end
				end
			end
		ensure -- from CONTAINER
			not_found_in_empty: Result implies not is_empty
		end

	has_key (key: K): BOOLEAN
			-- Is there an item in the table with key `key'? Set found_item to the found item.
		local
			old_position: INTEGER_32
			l_default_value: G
		do
			old_position := item_position
			internal_search (key)
			Result := found
			if Result then
				found_item := content.item (position)
			else
				found_item := l_default_value
			end
			item_position := old_position
		ensure then
			default_case: (key = computed_default_key) implies (Result = has_default)
			found: Result = found
			item_if_found: found implies (found_item = item (key))
		end

	item alias "[]" (key: K): G assign force
			-- Item associated with `key', if present
			-- otherwise default value of type `G'
			-- Was declared in FLAT_HASH_TABLE as synonym of at.
		require -- from TABLE
			valid_key: valid_key (key)
		local
			old_control, old_position: INTEGER_32
		do
			old_control := control
			old_position := item_position
			internal_search (key)
			if found then
				Result := content.item (position)
			end
			control := old_control
			item_position := old_position
		ensure then
			default_value_if_not_present: (not (has (key))) implies (Result = computed_default_value)
		end

	item_for_iteration: G
			-- Element at current iteration position
		require
			not_off: not off
		do
			Result := content.item (iteration_position)
		end

	new_cursor: FLAT_HASH_TABLE_ITERATION_CURSOR [G, K]
			-- Fresh cursor associated with current structure
		do
			create Result.make (Current)
			Result.start
		ensure -- from ITERABLE
			result_attached: Result /= Void
		end

	iteration_item (i: INTEGER_32): G
			-- Entry at position `i'
		require
			valid_index: valid_iteration_index (i)
		do
			Result := content.item (i)
		end

	key_for_iteration: K
			-- Key at current iteration position
		require
			not_off: not off
		do
			Result := keys.item (iteration_position)
		end

feature -- Measurement

	capacity: INTEGER_32
			-- Number of items that may be stored.

	count: INTEGER_32
			-- Number of items in table

	iteration_index_set: FLAT_INTEGER_INTERVAL
			-- Range of acceptable indexes
		do
			create Result.make (next_iteration_position (-1), previous_iteration_position (keys.count))
		ensure
			not_void: Result /= Void
		end

	occurrences (v: G): INTEGER_32
			-- Number of table items equal to `v'.
		local
			old_iteration_position: INTEGER_32
		do
			old_iteration_position := iteration_position
			if object_comparison then
				from
					start
				until
					off
				loop
					if item_for_iteration ~ v then
						Result := Result + 1
					end
					forth
				end
			else
				from
					start
				until
					off
				loop
					if item_for_iteration = v then
						Result := Result + 1
					end
					forth
				end
			end
			iteration_position := old_iteration_position
		ensure -- from BAG
			non_negative_occurrences: Result >= 0
		end

feature -- Comparison

	is_equal (other: like Current): BOOLEAN
			-- Does table contain the same information as `other'?
		do
			Result := keys ~ other.keys and content ~ other.content and (has_default = other.has_default)
		end

	same_keys (a_search_key, a_key: K): BOOLEAN
			-- Does `a_search_key' equal to `a_key'?
		require
			valid_search_key: valid_key (a_search_key)
			valid_key: valid_key (a_key)
		do
			Result := a_search_key ~ a_key
		end

feature -- Status report

	after: BOOLEAN
			-- Is cursor past last item?
			-- Was declared in FLAT_HASH_TABLE as synonym of off.
		do
			Result := iteration_position >= keys.count
		end

	changeable_comparison_criterion: BOOLEAN
			-- May object_comparison be changed?
			-- (Answer: yes by default.)
			-- (from CONTAINER)
		do
			Result := True
		end

	conflict: BOOLEAN
			-- Did last operation cause a conflict?
		do
			Result := (control = Conflict_constant)
		end

	Extendible: BOOLEAN = False
			-- May new items be added?

	found: BOOLEAN
			-- Did last operation find the item sought?
		do
			Result := (control = Found_constant)
		end

	Full: BOOLEAN = False
			-- Is structure filled to capacity?

	inserted: BOOLEAN
			-- Did last operation insert an item?
		do
			Result := (control = Inserted_constant)
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
			Result := has_item (v)
		end

	not_found: BOOLEAN
			-- Did last operation fail to find the item sought?
		do
			Result := (control = Not_found_constant)
		end

	object_comparison: BOOLEAN
			-- Must search operations use equal rather than `='
			-- for comparing references? (Default: no, use `='.)
			-- (from CONTAINER)

	off: BOOLEAN
			-- Is cursor past last item?
			-- Was declared in FLAT_HASH_TABLE as synonym of after.
		do
			Result := iteration_position >= keys.count
		end

	prunable: BOOLEAN
			-- May items be removed?
		do
			Result := True
		end

	removed: BOOLEAN
			-- Did last operation remove an item?
		do
			Result := (control = Removed_constant)
		end

	replaced: BOOLEAN
			-- Did last operation replace an item?
		do
			Result := (control = Replaced_constant)
		end

	valid_cursor (c: FLAT_HASH_TABLE_CURSOR): BOOLEAN
			-- Can cursor be moved to position `c'?
		require
			c_not_void: c /= Void
		do
			if attached {FLAT_HASH_TABLE_CURSOR} c as ht_cursor then
				Result := valid_iteration_index (ht_cursor.position)
			end
		end

	valid_iteration_index (i: INTEGER_32): BOOLEAN
			-- Is `i' a valid index?
		do
			Result := (is_off_position (i)) or else ((i >= 0) and (i <= keys.count) and then truly_occupied (i))
		ensure
			only_if_in_index_set: Result implies ((i >= iteration_index_set.lower) and (i <= iteration_index_set.upper))
		end

	valid_key (k: K): BOOLEAN
			-- Is `k' a valid key?
		local
			l_internal: INTERNAL
			l_default_key: K
			l_index, i, nb: INTEGER_32
			l_name: STRING_8
			l_cell: CELL [K]
		do
			Result := True
			debug ("prevent_hash_table_catcall")
				if k /= l_default_key then
					create l_internal
					create l_cell.put (l_default_key)
					from
						i := 1
						nb := l_internal.field_count (l_cell)
						l_name := "item"
					until
						i > nb
					loop
						if l_internal.field_name (i, l_cell) ~ l_name then
							l_index := i
							i := nb + 1
						end
						i := i + 1
					end
					if l_index > 0 and then k /= Void then
						Result := l_internal.field_static_type_of_type (l_index, l_internal.dynamic_type (l_cell)) = l_internal.dynamic_type (k)
					end
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

feature -- Cursor movement

	forth
			-- Advance cursor to next occupied position,
			-- or off if no such position remains.
		require
			not_off: not off
		do
			iteration_position := next_iteration_position (iteration_position)
		end

	go_to (c: FLAT_HASH_TABLE_CURSOR)
			-- Move to position `c'.
		require
			c_not_void: c /= Void
			valid_cursor: valid_cursor (c)
		do
			if attached {FLAT_HASH_TABLE_CURSOR} c as ht_cursor then
				iteration_position := ht_cursor.position
			end
		end

	search (key: K)
			-- Search for item of key `key'.
			-- If found, set found to true, and set
			-- found_item to item associated with `key'.
		local
			old_position: INTEGER_32
			l_default_value: G
		do
			old_position := item_position
			internal_search (key)
			if found then
				found_item := content.item (position)
			else
				found_item := l_default_value
			end
			item_position := old_position
		ensure
			found_or_not_found: found or not_found
			item_if_found: found implies (found_item = item (key))
		end

	start
			-- Bring cursor to first position.
		do
			iteration_position := -1
			forth
		end

feature {FLAT_HASH_TABLE_ITERATION_CURSOR} -- Cursor movement

	next_iteration_position (a_position: like iteration_position): like iteration_position
			-- Given an iteration position, advanced to the next one taking into account deleted
			-- slots in the content and keys structures.
		require
			a_position_big_enough: a_position >= -1
			a_position_small_enough: a_position < keys.count
		local
			l_deleted_marks: like deleted_marks
			l_table_size: INTEGER_32
		do
			Result := a_position + 1
			l_deleted_marks := deleted_marks
			l_table_size := content.count
			from
			until
				Result >= l_table_size or else not l_deleted_marks.item (Result)
			loop
				Result := Result + 1
			end
		end

	previous_iteration_position (a_position: like iteration_position): like iteration_position
			-- Given an iteration position, go to the previous one taking into account deleted
			-- slots in the content and keys structures.
		require
			a_position_big_enough: a_position >= 0
			a_position_small_enough: a_position <= keys.count
		local
			l_deleted_marks: like deleted_marks
			l_table_size: INTEGER_32
		do
			Result := a_position - 1
			l_deleted_marks := deleted_marks
			l_table_size := content.count
			from
			until
				Result <= 0 or else not l_deleted_marks.item (Result)
			loop
				Result := Result - 1
			end
		end

feature -- Element change

	extend (new: G; key: K)
			-- Assuming there is no item of key `key',
			-- insert `new' with `key'.
			-- Set inserted.
			--
			-- To choose between various insert/replace procedures,
			-- see `instructions' in the Indexing clause.
		require
			not_present: not has (key)
		local
			l_default_key: K
			l_new_pos, l_new_index_pos: like position
		do
			search_for_insertion (key)
			if soon_full then
				add_space
				search_for_insertion (key)
			end
			if deleted_item_position /= Ht_impossible_position then
				l_new_pos := deleted_position (deleted_item_position)
				l_new_index_pos := deleted_item_position
				deleted_marks.force (False, l_new_pos)
			else
				l_new_pos := keys.count
				l_new_index_pos := item_position
			end
			indexes_map.put (l_new_pos, l_new_index_pos)
			content.force (new, l_new_pos)
			keys.force (key, l_new_pos)
			if key = l_default_key then
				has_default := True
			end
			count := count + 1
			control := Inserted_constant
		ensure
			inserted: inserted
			insertion_done: item (key) = new
			one_more: count = old count + 1
			default_property: has_default = ((key = computed_default_key) or (old has_default))
		end

	fill (other: FLAT_HASH_TABLE [G, K])
			-- Fill with as many items of `other' as possible.
			-- The representations of `other' and current structure
			-- need not be the same.
			-- (from COLLECTION)
		require -- from COLLECTION
			other_not_void: other /= Void
			extendible: Extendible
		local
			lin_rep: FLAT_DYNAMIC_LIST [G]
		do
			lin_rep := other.linear_representation
			from
				lin_rep.start
			until
				not Extendible or else lin_rep.off
			loop
				collection_extend (lin_rep.item)
				lin_rep.forth
			end
		end

	force (new: G; key: K)
			-- Update table so that `new' will be the item associated
			-- with `key'.
			-- If there was an item for that key, set found
			-- and set found_item to that item.
			-- If there was none, set not_found and set
			-- found_item to the default value.
			--
			-- To choose between various insert/replace procedures,
			-- see `instructions' in the Indexing clause.
		require -- from TABLE
			valid_key: valid_key (key)
		local
			l_default_key: K
			l_default_value: G
			l_new_pos, l_new_index_pos: like position
		do
			internal_search (key)
			if not_found then
				if soon_full then
					add_space
					internal_search (key)
				end
				if deleted_item_position /= Ht_impossible_position then
					l_new_pos := deleted_position (deleted_item_position)
					l_new_index_pos := deleted_item_position
					deleted_marks.force (False, l_new_pos)
				else
					l_new_pos := keys.count
					l_new_index_pos := item_position
				end
				indexes_map.put (l_new_pos, l_new_index_pos)
				keys.force (key, l_new_pos)
				if key = l_default_key then
					has_default := True
				end
				count := count + 1
				found_item := l_default_value
			else
				l_new_pos := position
				found_item := content.item (l_new_pos)
			end
			content.force (new, l_new_pos)
		ensure -- from TABLE
			inserted: item (key) = new
			insertion_done: item (key) = new
			now_present: has (key)
			found_or_not_found: found or not_found
			not_found_if_was_not_present: not_found = not (old has (key))
			same_count_or_one_more: (count = old count) or (count = old count + 1)
			found_item_is_old_item: found implies (found_item = old (item (key)))
			default_value_if_not_found: not_found implies (found_item = computed_default_value)
			default_property: has_default = ((key = computed_default_key) or ((key /= computed_default_key) and (old has_default)))
		end

	merge (other: FLAT_HASH_TABLE [G, K])
			-- Merge `other' into Current. If `other' has some elements
			-- with same key as in `Current', replace them by one from
			-- `other'.
		require
			other_not_void: other /= Void
		do
			from
				other.start
			until
				other.after
			loop
				force (other.item_for_iteration, other.key_for_iteration)
				other.forth
			end
		ensure
			inserted: other.current_keys.linear_representation.for_all (agent has)
		end

	put (new: G; key: K)
			-- Insert `new' with `key' if there is no other item
			-- associated with the same key.
			-- Set inserted if and only if an insertion has
			-- been made (i.e. `key' was not present).
			-- If so, set position to the insertion position.
			-- If not, set conflict.
			-- In either case, set found_item to the item
			-- now associated with `key' (previous item if
			-- there was one, `new' otherwise).
			--
			-- To choose between various insert/replace procedures,
			-- see `instructions' in the Indexing clause.
		require -- from TABLE
			valid_key: valid_key (key)
		local
			l_default_key: K
			l_new_pos, l_new_index_pos: like position
		do
			internal_search (key)
			if found then
				set_conflict
				found_item := content.item (position)
			else
				if soon_full then
					add_space
					internal_search (key)
					check
						not_present: not found
					end
				end
				if deleted_item_position /= Ht_impossible_position then
					l_new_pos := deleted_position (deleted_item_position)
					l_new_index_pos := deleted_item_position
					deleted_marks.force (False, l_new_pos)
				else
					l_new_pos := keys.count
					l_new_index_pos := item_position
				end
				indexes_map.put (l_new_pos, l_new_index_pos)
				content.force (new, l_new_pos)
				keys.force (key, l_new_pos)
				if key = l_default_key then
					has_default := True
				end
				count := count + 1
				found_item := new
				control := Inserted_constant
			end
		ensure then
			conflict_or_inserted: conflict or inserted
			insertion_done: inserted implies item (key) = new
			now_present: inserted implies has (key)
			one_more_if_inserted: inserted implies (count = old count + 1)
			unchanged_if_conflict: conflict implies (count = old count)
			same_item_if_conflict: conflict implies (item (key) = old (item (key)))
			found_item_associated_with_key: found_item = item (key)
			new_item_if_inserted: inserted implies (found_item = new)
			old_item_if_conflict: conflict implies (found_item = old (item (key)))
			default_property: has_default = ((inserted and (key = computed_default_key)) or ((conflict or (key /= computed_default_key)) and (old has_default)))
		end

	replace (new: G; key: K)
			-- Replace item at `key', if present,
			-- with `new'; do not change associated key.
			-- Set replaced if and only if a replacement has been made
			-- (i.e. `key' was present); otherwise set not_found.
			-- Set found_item to the item previously associated
			-- with `key' (default value if there was none).
			--
			-- To choose between various insert/replace procedures,
			-- see `instructions' in the Indexing clause.
		local
			l_default_item: G
		do
			internal_search (key)
			if found then
				found_item := content.item (position)
				content.put (new, position)
				control := Replaced_constant
			else
				found_item := l_default_item
			end
		ensure
			replaced_or_not_found: replaced or not_found
			insertion_done: replaced implies item (key) = new
			no_change_if_not_found: not_found implies item (key) = old (item (key))
			found_item_is_old_item: found_item = old (item (key))
		end

	replace_key (new_key: K; old_key: K)
			-- If there is an item of key `old_key' and no item of key
			-- `new_key', replace the former's key by `new_key',
			-- set replaced, and set found_item to the item
			-- previously associated with `old_key'.
			-- Otherwise set not_found or conflict respectively.
			-- If conflict, set found_item to the item previously
			-- associated with `new_key'.
			--
			-- To choose between various insert/replace procedures,
			-- see `instructions' in the Indexing clause.
		local
			l_item: G
		do
			internal_search (new_key)
			if not found then
				internal_search (old_key)
				if found then
					l_item := content.item (position)
					remove (old_key)
					put (l_item, new_key)
					control := Replaced_constant
				end
			else
				set_conflict
				found_item := content.item (position)
			end
		ensure
			same_count: count = old count
			replaced_or_conflict_or_not_found: replaced or conflict or not_found
			old_absent: (replaced and not same_keys (new_key, old_key)) implies (not has (old_key))
			new_present: (replaced or conflict) = has (new_key)
			new_item: replaced implies (item (new_key) = old (item (old_key)))
			not_found_implies_no_old_key: not_found implies old (not has (old_key))
			conflict_iff_already_present: conflict = old (has (new_key))
			not_inserted_if_conflict: conflict implies (item (new_key) = old (item (new_key)))
		end

feature -- Removal

	prune (v: G)
			-- Remove first occurrence of `v', if any,
			-- after cursor position.
			-- Move cursor to right neighbor.
			-- (or after if no right neighbor or `v' does not occur)
		require -- from COLLECTION
			prunable: prunable
		do
			if object_comparison then
				from
				until
					after or else item_for_iteration ~ v
				loop
					forth
				end
			else
				from
				until
					after or else item_for_iteration = v
				loop
					forth
				end
			end
			if not after then
				remove (key_for_iteration)
			end
		end

	remove (key: K)
			-- Remove item associated with `key', if present.
			-- Set removed if and only if an item has been
			-- removed (i.e. `key' was present);
			-- if so, set position to index of removed element.
			-- If not, set not_found.
			-- Reset found_item to its default value if removed.
		local
			l_default_key: K
			l_default_value: G
			l_pos: like position
			l_nb_removed_items: INTEGER_32
		do
			internal_search (key)
			if found then
				l_pos := position
				if key = l_default_key then
					has_default := False
				end
				deleted_marks.put (True, l_pos)
				indexes_map.put (- l_pos + Ht_deleted_position, item_position)
				if iteration_position = l_pos then
					forth
				end
				count := count - 1
				ht_lowest_deleted_position := l_pos.min (ht_lowest_deleted_position)
				if (ht_lowest_deleted_position = count) then
					l_nb_removed_items := content.count - ht_lowest_deleted_position
					content.remove_tail (l_nb_removed_items)
					keys.remove_tail (l_nb_removed_items)
					deleted_marks.fill_with (False, ht_lowest_deleted_position, deleted_marks.count - 1)
					ht_deleted_item := l_default_value
					ht_deleted_key := l_default_key
					ht_lowest_deleted_position := Ht_max_position
				elseif attached ht_deleted_item as l_item and attached ht_deleted_key as l_key then
					content.put (l_item, l_pos)
					keys.put (l_key, l_pos)
				else
					ht_deleted_item := content.item (l_pos)
					ht_deleted_key := keys.item (l_pos)
				end
				control := Removed_constant
				found_item := l_default_value
			end
		ensure
			removed_or_not_found: removed or not_found
			not_present: not has (key)
			one_less: found implies (count = old count - 1)
			default_case: (key = computed_default_key) implies (not has_default)
			non_default_case: (key /= computed_default_key) implies (has_default = old has_default)
		end

	wipe_out
			-- Reset all items to default values; reset status.
		require -- from COLLECTION
			prunable: prunable
		local
			l_default_value: G
		do
			content.wipe_out
			keys.wipe_out
			deleted_marks.fill_with (False, 0, deleted_marks.upper)
			indexes_map.fill_with (Ht_impossible_position, 0, capacity)
			found_item := l_default_value
			count := 0
			item_position := 0
			iteration_position := keys.count
			control := 0
			has_default := False
		ensure -- from COLLECTION
			wiped_out: is_empty
			position_equal_to_zero: item_position = 0
			count_equal_to_zero: count = 0
			has_default_set: not has_default
			no_status: not special_status
		end

feature {NONE} -- Removal

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
				not has_item (v)
			loop
				prune (v)
			end
		ensure -- from COLLECTION
			no_more_occurrences: not has_item (v)
		end

feature -- Conversion

	linear_representation: FLAT_ARRAYED_LIST [G]
			-- Representation as a linear structure
		require -- from  CONTAINER
			True
		local
			old_iteration_position: INTEGER_32
		do
			old_iteration_position := iteration_position
			from
				create Result.make (count)
				start
			until
				off
			loop
				Result.extend (item_for_iteration)
				forth
			end
			iteration_position := old_iteration_position
		ensure then
			result_exists: Result /= Void
			good_count: Result.count = count
		end

feature -- Duplication

	copy (other: like Current)
			-- Re-initialize from `other'.
		do
			if other /= Current then
				standard_copy (other)
				set_content (other.content.twin)
				set_keys (other.keys.twin)
				set_deleted_marks (other.deleted_marks.twin)
				set_indexes_map (other.indexes_map.twin)
			end
		end

feature {NONE} -- Duplication

	empty_duplicate (n: INTEGER_32): like Current
			-- Create an empty copy of Current that can accommodate `n' items
		require
			n_non_negative: n >= 0
		do
			create Result.make (n)
		ensure
			empty_duplicate_attached: Result /= Void
		end

feature {NONE} -- Inapplicable

	bag_put (v: G)
			-- Ensure that structure includes `v'.
			-- (from TABLE)
		require -- from COLLECTION
			extendible: Extendible
		do
		ensure -- from COLLECTION
			item_inserted: is_inserted (v)
		end

	collection_extend (v: G)
			-- Insert a new occurrence of `v'.
		require -- from COLLECTION
			extendible: Extendible
		do
		ensure -- from COLLECTION
			item_inserted: is_inserted (v)
		end

feature {NONE} -- Implementation

	add_space
			-- Increase capacity.
		do
			accommodate (count + count // 2)
		ensure
			count_not_changed: count = old count
			breathing_space: count < capacity
		end

	computed_default_key: K
			-- Default key
			-- (For performance reasons, used only in assertions;
			-- elsewhere, see use of local entity `l_default_key'.)
		do
		end

	computed_default_value: G
			-- Default value of type G
			-- (For performance reasons, used only in assertions;
			-- elsewhere, see use of local entity `l_default_value'.)
		do
		end

	Conflict_constant: INTEGER_32 = 1
			-- Could not insert an already existing key

	default_key_value: G
			-- Value associated with the default key, if any
		require
			has_default: has_default
		do
			Result := content [indexes_map [capacity]]
		end

	deleted (i: INTEGER_32): BOOLEAN
			-- Is position `i' that of a deleted item?
		require
			in_bounds: i >= 0 and i <= capacity
		do
			Result := indexes_map.item (i) <= Ht_deleted_position
		end

	deleted_position (a_pos: INTEGER_32): INTEGER_32
			-- Given the position of a deleted item at `a_pos' gives the associated position
			-- in `content/keys'.
		require
			deleted: deleted (a_pos)
		do
			Result := - indexes_map.item (a_pos) + Ht_deleted_position
			Result := Result.min (keys.count)
		ensure
			deleted_position_non_negative: Result >= 0
			deleted_position_valid: Result <= keys.count and Result <= content.count
		end

	Found_constant: INTEGER_32 = 2
			-- Key found

	ht_deleted_item: G

	ht_deleted_key: K
			-- Store the item and key that will be used to replace an element of the FLAT_HASH_TABLE
			-- that will be removed. If elements being removed are at the end of content or keys
			-- then they are both Void. It is only used when removing an element at a position strictly
			-- less than count.

	Ht_deleted_position: INTEGER_32 = -2
			-- Marked a deleted position.

	Ht_impossible_position: INTEGER_32 = -1
			-- Position outside the array indices.

	ht_lowest_deleted_position: INTEGER_32
			-- Index of the lowest deleted position thus far.

	Ht_max_position: INTEGER_32 = 2147483645
			-- Maximum possible position

	initial_position (hash_value: INTEGER_32): INTEGER_32
			-- Initial position for an item of hash code `hash_value'
		do
			Result := (hash_value \\ capacity)
		end

	Inserted_constant: INTEGER_32 = 4
			-- Insertion successful

	internal_search (key: K)
			-- Search for item of key `key'.
			-- If successful, set position to index
			-- of item with this key (the same index as the key's index).
			-- If not, set position to possible position for insertion,
			-- and set status to found or not_found.
		local
			l_default_key: K
			hash_value, increment, l_pos, l_item_pos, l_capacity: INTEGER_32
			l_first_deleted_position: INTEGER_32
			stop: INTEGER_32
			l_keys: like keys
			l_indexes: like indexes_map
			l_deleted_marks: like deleted_marks
			l_key: K
		do
			l_first_deleted_position := Ht_impossible_position
			if key = l_default_key or key = Void then
				item_position := capacity
				if has_default then
					control := Found_constant
				else
					control := Not_found_constant
				end
			else
				from
					l_keys := keys
					l_indexes := indexes_map
					l_deleted_marks := deleted_marks
					l_capacity := capacity
					stop := l_capacity
					hash_value := key.hash_code
					increment := 1 + hash_value \\ (l_capacity - 1)
					l_item_pos := (hash_value \\ l_capacity) - increment
					control := Not_found_constant
				until
					stop = 0
				loop
					l_item_pos := (l_item_pos + increment) \\ l_capacity
					l_pos := l_indexes [l_item_pos]
					if l_pos >= 0 then
						l_key := l_keys.item (l_pos)
						debug ("detect_hash_table_catcall")
							check
								catcall_detected: l_key /= Void and then l_key.same_type (key)
							end
						end
						if same_keys (l_key, key) then
							stop := 1
							control := Found_constant
						end
					elseif l_pos = Ht_impossible_position then
						stop := 1
					elseif l_first_deleted_position = Ht_impossible_position then
						l_pos := - l_pos + Ht_deleted_position
						check
							l_pos_valid: l_pos < l_deleted_marks.count
						end
						if not l_deleted_marks [l_pos] then
							stop := 1
						else
							l_first_deleted_position := l_item_pos
						end
					end
					stop := stop - 1
				end
				item_position := l_item_pos
			end
			deleted_item_position := l_first_deleted_position
		ensure
			found_or_not_found: found or not_found
			deleted_item_at_deleted_position: (deleted_item_position /= Ht_impossible_position) implies (deleted (deleted_item_position))
			default_iff_at_capacity: (item_position = capacity) = (key = computed_default_key)
		end

	is_off_position (pos: INTEGER_32): BOOLEAN
			-- Is `pos' a cursor position past last item?
		do
			Result := pos >= keys.count
		end

	key_at (n: INTEGER_32): K
			-- Key at position `n'
		do
			if keys.valid_index (n) then
				Result := keys.item (n)
			end
		end

	Minimum_capacity: INTEGER_32 = 2

	Not_found_constant: INTEGER_32 = 8
			-- Key not found

	occupied (i: INTEGER_32): BOOLEAN
			-- Is position `i' occupied by a non-default key and a value?
		require
			in_bounds: deleted_marks.valid_index (i)
		do
			if has_default then
				Result := i /= indexes_map.item (capacity) and then not deleted_marks.item (i)
			else
				Result := not deleted_marks.item (i)
			end
		end

	position_increment (hash_value: INTEGER_32): INTEGER_32
			-- Distance between successive positions for hash code
			-- `hash_value' (computed for no cycle: capacity is prime)
		do
			Result := 1 + hash_value \\ (capacity - 1)
		end

	Removed_constant: INTEGER_32 = 16
			-- Remove successful

	Replaced_constant: INTEGER_32 = 32
			-- Replaced value

	search_for_insertion (key: K)
			-- Assuming there is no item of key `key', compute
			-- position at which to insert such an item.
		require
			not_present: not has (key)
		local
			l_default_key: K
			hash_value, increment, l_pos, l_item_pos, l_capacity: INTEGER_32
			l_first_deleted_position: INTEGER_32
			stop: INTEGER_32
			l_keys: like keys
			l_indexes: like indexes_map
			l_deleted_marks: like deleted_marks
		do
			l_first_deleted_position := Ht_impossible_position
			if key = l_default_key or key = Void then
				check
					not has_default
				end
				item_position := capacity
			else
				from
					l_keys := keys
					l_indexes := indexes_map
					l_deleted_marks := deleted_marks
					l_capacity := capacity
					stop := l_capacity
					hash_value := key.hash_code
					increment := 1 + hash_value \\ (l_capacity - 1)
					l_item_pos := (hash_value \\ l_capacity) - increment
				until
					stop = 0
				loop
					l_item_pos := (l_item_pos + increment) \\ l_capacity
					l_pos := l_indexes [l_item_pos]
					if l_pos >= 0 then
					elseif l_pos = Ht_impossible_position then
						stop := 1
					elseif l_first_deleted_position = Ht_impossible_position then
						l_pos := - l_pos + Ht_deleted_position
						check
							l_pos_valid: l_pos < l_deleted_marks.count
						end
						if not l_deleted_marks [l_pos] then
							stop := 1
						else
							l_first_deleted_position := l_item_pos
						end
					end
					stop := stop - 1
				end
				item_position := l_item_pos
			end
			deleted_item_position := l_first_deleted_position
		ensure
			deleted_item_at_deleted_position: (deleted_item_position /= Ht_impossible_position) implies (deleted (deleted_item_position))
			default_iff_at_capacity: (item_position = capacity) = (key = computed_default_key)
		end

	set_conflict
			-- Set status to conflict.
		do
			control := Conflict_constant
		ensure
			conflict: conflict
		end

	set_content (c: like content)
			-- Assign `c' to content.
		require
			c_attached: c /= Void
		do
			content := c
		ensure
			content_set: content = c
		end

	set_deleted_marks (d: like deleted_marks)
			-- Assign `c' to content.
		require
			d_attached: d /= Void
		do
			deleted_marks := d
		ensure
			deleted_marks_set: deleted_marks = d
		end

	set_found
			-- Set status to found.
		do
			control := Found_constant
		ensure
			found: found
		end

	set_indexes_map (v: like indexes_map)
			-- Assign `v' to indexes_map.
		do
			indexes_map := v
		ensure
			indexes_map_set: indexes_map = v
		end

	set_inserted
			-- Set status to inserted.
		do
			control := Inserted_constant
		ensure
			inserted: inserted
		end

	set_keys (c: like keys)
			-- Assign `c' to keys.
		require
			c_attached: c /= Void
		do
			keys := c
		ensure
			keys_set: keys = c
		end

	set_no_status
			-- Set status to normal.
		do
			control := 0
		ensure
			default_status: not special_status
		end

	set_not_found
			-- Set status to not found.
		do
			control := Not_found_constant
		ensure
			not_found: not_found
		end

	set_removed
			-- Set status to removed.
		do
			control := Removed_constant
		ensure
			removed: removed
		end

	set_replaced
			-- Set status to replaced.
		do
			control := Replaced_constant
		ensure
			replaced: replaced
		end

	special_status: BOOLEAN
			-- Has status been set to some non-default value?
		do
			Result := (control > 0)
		ensure
			Result = (control > 0)
		end

	truly_occupied (i: INTEGER_32): BOOLEAN
			-- Is position `i' occupied by a key and a value?
		do
			if i >= 0 and i < keys.count then
				Result := (has_default and i = indexes_map.item (capacity)) or else occupied (i)
			end
		ensure
			normal_key: (i >= 0 and i < keys.count and i /= indexes_map.item (capacity)) implies (occupied (i) implies Result)
			default_key: (i = indexes_map.item (capacity)) implies (Result = has_default)
		end

feature {FLAT_HASH_TABLE, FLAT_HASH_TABLE_ITERATION_CURSOR} -- Implementation: content attributes and preservation

	content: SPECIAL [G]
			-- Array of contents

	keys: SPECIAL [K]
			-- Array of keys

feature {FLAT_HASH_TABLE} -- Implementation: content attributes and preservation

	deleted_marks: SPECIAL [BOOLEAN]
			-- Indexes of deleted positions in content and keys.

	has_default: BOOLEAN
			-- Is the default key present?

	indexes_map: SPECIAL [INTEGER_32]
			-- Indexes of items in content, and keys.
			-- If item is not present, then it has `ht_mpossible_position'.
			-- If item is deleted, then it has Ht_deleted_position.

	item_position: INTEGER_32
			-- Position in indexes_map for item at position position. Set by internal_search.

feature {FLAT_HASH_TABLE} -- Implementation: search attributes

	control: INTEGER_32
			-- Control code set by operations that may produce
			-- several possible conditions.

	deleted_item_position: INTEGER_32
			-- Place where a deleted element was found during a search

	iteration_position: INTEGER_32
			-- Cursor for iteration primitives

	position: INTEGER_32
			-- Hash table cursor, updated after each operation:
			-- put, remove, has, replace, force, change_key...
		do
			Result := indexes_map.item (item_position)
		end

	soon_full: BOOLEAN
			-- Is table close to being filled to current capacity?
		do
			Result := keys.count = keys.capacity
		ensure
			Result = (keys.count = keys.capacity)
		end

invariant
	keys_not_void: keys /= Void
	content_not_void: content /= Void
	keys_enough_capacity: keys.count <= capacity + 1
	content_enough_capacity: content.count <= capacity + 1
	valid_iteration_position: off or truly_occupied (iteration_position)
	control_non_negative: control >= 0
	special_status: special_status = (conflict or inserted or replaced or removed or found or not_found)
	count_big_enough: 0 <= count
	count_small_enough: count <= capacity
	slot_count_big_enough: 0 <= count

		-- from FINITE
	empty_definition: is_empty = (count = 0)

end -- class FLAT_HASH_TABLE

