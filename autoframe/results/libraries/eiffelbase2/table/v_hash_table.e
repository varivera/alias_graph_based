note
	description: "[
			Hash tables with hash function provided by HASHABLE and object equality.
			Implementation uses chaining.
			Search, extension and removal are amortized constant time.
		]"
	author: "Nadia Polikarpova"
	model: map, lock
	manual_inv: true
	false_guards: true

frozen class
	V_HASH_TABLE [K -> V_HASHABLE, V]

inherit
	V_TABLE [K, V]
		redefine
			map,
			lock
		end

create
	make
feature -- Testing
	test__make_empty_buckets (n: INTEGER)
			-- Create an empty set with `buckets' of size `n'.
		note
			modify_field: buckets, count_, map, lists, buckets_, locked, bag, Current_
		local
			i: INTEGER
		do
			create buckets.make (1, n)
			from
				i := 1
			until
				i > n
			loop
				buckets [i] := create {V_LINKED_LIST [MML_PAIR [K, V]]}
				i := i + 1
			end

			count_ := 0
			create map
			create buckets_.constant ({MML_SEQUENCE [K]}.empty_sequence, buckets.sequence.count)
			--create buckets_.constant (create {MML_SEQUENCE [K]}.default_create, buckets.sequence.count)
		end
	test_new_cursor: V_HASH_TABLE_ITERATOR [K, V]
		do
			create Result.make (Current)
			Result.start
		end

	test_make_empty_buckets (k: K)
		local
			d: STRING
		do
			--create d.make_empty
			--create buckets_.constant ({MML_SEQUENCE [K]}.empty_sequence, buckets.sequence.count)
			create buckets_.constant (create {MML_SEQUENCE [K]}.default_create, buckets.sequence.count)
			map := map.removed ((buckets_ [index (k)]) [0])
		end

	test_copy_ (other: V_HASH_TABLE [K, V])
		local
			it: V_HASH_TABLE_ITERATOR [K, V]
		do
			if other /= Current then
				make_empty_buckets (other.capacity)
			end
		end
feature {NONE} -- Initialization

	make (l: V_HASH_LOCK [K])
			-- Create an empty table with lock `l'.
		note
			modify: Current_
		do
			lock := l
			lock.add_client (Current)
			make_empty_buckets (default_capacity)
		end

feature -- Initialization

	copy_ (other: V_HASH_TABLE [K, V])
			-- Initialize by copying all the items of `other'.
		note
			modify_model: map, Current_
		local
			it: V_HASH_TABLE_ITERATOR [K, V]
		do
			if other /= Current then
				make_empty_buckets (other.capacity)
				from
					it := other.new_cursor
				until
					it.after
				loop
					it.forth
				variant
					it.sequence.count - it.index_
				end
			end
		end

feature -- Measurement

	count: INTEGER
			-- Number of elements.
		do
			Result := count_
		end

feature -- Search

	has_key (k: K): BOOLEAN
			-- Is key `k' contained?
			-- (Uses object equality.)
		do
			Result := cell_for_key (k) /= Void
		end

	key (k: K): K
			-- Element of `map.domain' equivalent to `v' according to object equality.
		do
			Result := cell_for_key (k).item.left
		end

	item alias "[]" (k: K): V assign force
			-- Value associated with `k'.
		do
			Result := cell_for_key (k).item.right
		end

feature -- Iteration

	new_cursor: V_HASH_TABLE_ITERATOR [K, V]
			-- New iterator pointing to a position in the map, from which it can traverse all elements by going `forth'.
		do
			create Result.make (Current)
			Result.start
		end

	at_key (k: K): V_HASH_TABLE_ITERATOR [K, V]
			-- New iterator pointing to a position with key `k'.
			-- If key does not exist, iterator is off.
		do
			create Result.make (Current)
			Result.search_key (k)
		end

feature -- Comparison

	is_equal_ (other: like Current): BOOLEAN
			-- Is the abstract state of Current equal to that of `other'?
		local
			i: INTEGER
			l: V_LINKED_LIST [MML_PAIR [K, V]]
		do
			if count_ = other.count_ then
				from
					Result := True
					i := 1
				until
					i > buckets.count or not Result
				loop
					l := buckets [i]
					Result := has_list (l, other)
					i := i + 1
				variant
					lists.count - i
				end
			end
			if Result then
				other.map.domain.lemma_subset (map.domain)
			end
		end

feature -- Extension

	extend (v: V; k: K)
			-- Extend table with key-value pair <`k', `v'>.
		do
			auto_resize (count_ + 1)
			simple_extend (v, k)
		end

feature -- Removal

	remove (k: K)
			-- Remove key `k' and its associated value.
		local
			idx, i_: INTEGER
		do
			idx := index (k)
			i_ := remove_equal (buckets [idx], k)
			count_ := count_ - 1
			map := map.removed ((buckets_ [idx]) [i_])
			buckets_ := buckets_.replaced_at (idx, buckets_ [idx].removed_at (i_))
			auto_resize (count_)
		end

	wipe_out
			-- Remove all elements.
		do
			make_empty_buckets (default_capacity)
		end

feature {NONE} -- Performance parameters

	default_capacity: INTEGER = 16
			-- Default size of `buckets'.		

	target_load_factor: INTEGER = 75
			-- Approximate percentage of elements per bucket that bucket array has after automatic resizing.

	growth_rate: INTEGER = 2
			-- Rate by which bucket array grows and shrinks.			

feature {V_CONTAINER, V_ITERATOR, V_LOCK} -- Implementation

	buckets: V_ARRAY [V_LINKED_LIST [MML_PAIR [K, V]]]
		-- Element storage.
		attribute
		end

	count_: INTEGER
			-- Number of elements.
		attribute
		end

	capacity: INTEGER
			-- Bucket array size.
		do
			Result := buckets.count
		end

	bucket_index (hc, n: INTEGER): INTEGER
			-- The bucket an item with hash code `hc' belongs,
			-- if there are `n' buckets in total.
		do
			Result := hc \\ n + 1
		end

	index (k: K): INTEGER
			-- Index of `k' into in `buckets'.
		do
			Result := bucket_index (k.hash_code, capacity)
		end

	cell_for_key (k: K): V_LINKABLE [MML_PAIR [K, V]]
			-- Cell of one of the buckets where the key is equal to `k' according to object equality.
			-- Void if the list has no such cell.
		do
			Result := cell_equal (buckets [index (k)], k)
		end

	cell_equal (list: V_LINKED_LIST [MML_PAIR [K, V]]; k: K): V_LINKABLE [MML_PAIR [K, V]]
			-- Cell of `list' where the key is equal to `k' according to object equality.
			-- Void if the list has no such cell.
		do
			if not list.is_empty then
				Result := cell_before (list, k)
				if Result = Void then
					Result := list.first_cell
				else
					Result := Result.right
				end
			end
		end

	cell_before (list: V_LINKED_LIST [MML_PAIR [K, V]]; k: K): V_LINKABLE [MML_PAIR [K, V]]
			-- Cell of `list' to the left of the cell where the key is equal to `k' according to object equality.
			-- Void if the first list element is equal to `k'; last cell if no list element is equal to `k'.
		local
			j_: INTEGER
		do
			--if not k.is_equal_ (list.first_cell.item.left) then
			if True then
				from
					j_ := 1
					Result := list.first_cell
				until
					--Result.right = Void or else k.is_equal_ (Result.right.item.left)
					True
				loop
					Result := Result.right
					j_ := j_ + 1
				variant
					list.sequence.count - j_
				end
			end
		end

	make_empty_buckets (n: INTEGER)
			-- Create an empty set with `buckets' of size `n'.
		note
			modify_field: buckets, count_, map, lists, buckets_, locked, bag, Current_
		local
			i: INTEGER
		do
			create buckets.make (1, n)
			from
				i := 1
			until
				i > n
			loop
				buckets [i] := create {V_LINKED_LIST [MML_PAIR [K, V]]}
				i := i + 1
			end

			count_ := 0
			create map
			create buckets_.constant ({MML_SEQUENCE [K]}.empty_sequence, buckets.sequence.count)
		end

	remove_at (it: V_HASH_TABLE_ITERATOR [K, V])
			-- Remove element to which `it' points.
		note
			modify_model: map, Current_
			--modify_model (["index_", "sequence"], it.list_iterator)
		local
			idx_, i_: INTEGER
		do
			idx_ := it.bucket_index
			i_ := it.list_iterator.index_
			it.list_iterator.remove

			count_ := count_ - 1
			map := map.removed ((buckets_ [idx_]) [i_])
			buckets_ := buckets_.replaced_at (idx_, buckets_ [idx_].removed_at (i_))
		end

	remove_equal (list: V_LINKED_LIST [MML_PAIR [K, V]]; k: K): INTEGER
			-- Remove an element where key is equal to `k' from `list'; return the index of the element in the prestate.
		note
			modify_model: sequence, list
		local
			c: V_LINKABLE [MML_PAIR [K, V]]
		do
			c := cell_before (list, k)
			if c = Void then
				Result := 1
				list.remove_front
			else
				Result := list.cells.index_of (c) + 1
				list.remove_after (c, Result - 1)
			end
		end

	replace_at (it: V_HASH_TABLE_ITERATOR [K, V]; v: V)
			-- Replace the value at the element to which `it' points.
		note
			modify_field: map, bag, Current_
			--modify_model: sequence, box, it.list_iterator
		local
			idx_, i_: INTEGER
			x: K
		do
			idx_ := it.bucket_index
			i_ := it.list_iterator.index_
			x := it.list_iterator.item.left
			it.list_iterator.put (create {MML_PAIR [K, V]}.make (x, v))

			map := map.updated (x, v)
		end

	simple_extend (v: V; k: K)
			-- Extend table with key-value pair <`k', `v'> without resizing the buckets.
		note
			modify_model: map, Current_
		local
			idx: INTEGER
			list: V_LINKED_LIST [MML_PAIR [K, V]]
		do
			idx := index (k)
			list := buckets [idx]
			list.extend_back (create {MML_PAIR [K, V]}.make (k, v))
			buckets_ := buckets_.replaced_at (idx, buckets_ [idx] & k)
			map := map.updated (k, v)
			count_ := count_ + 1
		end

	auto_resize (new_count: INTEGER)
			-- Resize `buckets' to an optimal size for `new_count'.
		note
			modify_model: map, Current_
		do
			if new_count * target_load_factor // 100 > growth_rate * capacity then
				resize (capacity * growth_rate)
			elseif capacity > default_capacity and new_count * target_load_factor // 100 < capacity // growth_rate then
				resize (capacity // growth_rate)
			end
		end

	resize (c: INTEGER)
			-- Resize `buckets' to `c'.
		note
			modify_model: map, Current_
		local
			i: INTEGER
			b: like buckets
			it: V_LINKED_LIST_ITERATOR [MML_PAIR [K, V]]
		do
			b := buckets
			make_empty_buckets (c)
			from
				i := 1
			until
				i > b.count
			loop
				from
					it := b [i].new_cursor
				until
					it.after
				loop
					it.forth
				end
				i := i + 1
			end
		end

	has_list (list: V_LINKED_LIST [MML_PAIR [K, V]]; other: like Current): BOOLEAN
			-- Does `other' contain all elements stored in the bucket `list'?
		local
			c: V_LINKABLE [MML_PAIR [K, V]]
			i_: INTEGER
		do
			from
				Result := True
				c := list.first_cell
				i_ := 1
			until
				c = Void or not Result
			loop
				Result := other.has_key (c.item.left) and then
					(other.key (c.item.left) = c.item.left and other.item (c.item.left) = c.item.right)
				if other.domain_has (c.item.left) and not Result then

				end
				c := c.right
				i_ := i_ + 1
			variant
				list.sequence.count - i_
			end
		end

feature -- Specification

	map: MML_MAP [K, V]
			-- Map of keys to values.
		note
			status: ghost
		attribute
		end

	buckets_: MML_SEQUENCE [MML_SEQUENCE [K]]
			-- Abstract element storage.
		note
			status: ghost
		attribute
		end

	lock: V_HASH_LOCK [K]
			-- Helper object for keeping items consistent.
		note
			status: ghost
		attribute
		end

feature {V_CONTAINER, V_ITERATOR, V_LOCK} -- Specification

	lists: MML_SEQUENCE [V_LINKED_LIST [MML_PAIR [K, V]]]
			-- Cache of `buckets.sequence' (required in the invariant of the iterator).
		note
			status: ghost
		attribute
		end

invariant
		-- Abstract state:
	buckets_non_empty: not buckets_.is_empty
	valid_buckets: across map.domain as x all lock.hash.domain [x.item] and then lock.hash [x.item] >= 0 and then
		buckets_ [bucket_index (lock.hash [x.item], buckets_.count)].has (x.item) end
	domain_not_too_small: across 1 |..| buckets_.count as i all
		across 1 |..| buckets_ [i.item].count as j all map.domain [(buckets_ [i.item])[j.item]] end end
	no_precise_duplicates: across 1 |..| buckets_.count as i all
		across 1 |..| buckets_.count as j all
			across 1 |..| buckets_ [i.item].count as k all
				across 1 |..| buckets_ [j.item].count as l all
					i.item /= j.item or k.item /= l.item implies (buckets_ [i.item])[k.item] /= (buckets_ [j.item])[l.item] end end end end
		-- Concrete state:
	count_definition: count_ = map.count
	buckets_exist: buckets /= Void
	buckets_lower: buckets.lower_ = 1
	lists_definition: lists = buckets.sequence
	all_lists_exist: lists.non_void
	buckets_count: buckets_.count = lists.count
	lists_distinct: lists.no_duplicates
	lists_counts: across 1 |..| buckets_.count as i all lists [i.item].sequence.count = buckets_ [i.item].count end
	buckets_content: across 1 |..| buckets_.count as i all across 1 |..| buckets_ [i.item].count as j all
		(buckets_ [i.item]) [j.item] = lists [i.item].sequence [j.item].left end end
	map_implementation: across 1 |..| buckets_.count as i all across 1 |..| buckets_ [i.item].count as j all
		map [(buckets_ [i.item]) [j.item]] = lists [i.item].sequence [j.item].right end end
		-- Iterators:

note
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
