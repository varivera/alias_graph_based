note
	description: "[
		Lists implemented as ring buffers.
		The size of list might be smaller than the size of underlying array.
		Random access is constant time. Inserting or removing elements at front or back is amortized constant time.
		Inserting or removing elements in the middle is linear time.
		]"
	author: "Nadia Polikarpova"
	model: sequence
	manual_inv: true
	false_guards: true

class
	V_ARRAYED_LIST [G]

inherit
	V_LIST [G]
		redefine
			item,
			default_create,
			put,
			prepend
		end
feature -- Test
	test_reserve (n: INTEGER)
			-- Make sure `array' can accommodate `n' elements;
		do
			--swap (1,2)
			reserve (1)
		end

	test_extend_front (v: G)
		do
			reserve (count_ + 1)
--			if count_ = 0 then
--				array [0] := v
--				first_index := 0
--			else
--				first_index := mod_capacity (first_index - 1)
--				array [first_index] := v
--			end
		end

	test_circular_copy (array2: V_ARRAY [G])
		do
			if True then
				from
				until
					True
				loop
					array.put (array2.item (1) ,1)
				end
			else
				array.put (array2.item (1) ,1)
			end
		end
	test_extend_at (v: G; i: INTEGER)
			-- Insert `v' at position `i'.
		do
			if i = 1 then
				extend_front (v)
		--	elseif i = count_ + 1 then
		--		extend_back (v)
--			else
--				reserve (count_ + 1)
--				count_ := count_ + 1
--				circular_copy (i, i + 1, count_ - i)
--				array [array_index (i)] := v
--				sequence := sequence.extended_at (i, v)
			end
		end

feature {NONE} -- Initialization

	default_create
			-- Create an empty list with default `capacity' and `growth_rate'.
		do
			create array.make (0, default_capacity - 1)
		end

feature -- Initialization

	copy_ (other: like Current)
			-- Initialize by copying all the items of `other'.
		note
			modify_model: sequence, Current_
		do
			if other /= Current then
				create array.copy_ (other.array)
				first_index := other.first_index
				count_ := other.count_
				sequence := other.sequence
			end
		end

feature -- Access

	item alias "[]" (i: INTEGER): G assign put
			-- Value associated with `i'.
		do
			Result := array [array_index (i)]
		end

feature -- Iteration

	at (i: INTEGER): V_ARRAYED_LIST_ITERATOR [G]
			-- New iterator pointing at position `i'.
		do
			create Result.make (Current, i)
		end

feature -- Comparison

	is_equal_ (other: like Current): BOOLEAN
			-- Is list made of the same values in the same order as `other'?
			-- (Use reference comparison.)
		local
			i: INTEGER
		do
			if other = Current then
				Result := True
			elseif count = other.count then
				from
					Result := True
					i := 1
				until
					i > count_ or not Result
				loop
					Result := item (i) = other.item (i)
					i := i + 1
				variant
					sequence.count - i
				end
			end
		end

feature -- Replacement

	put (v: G; i: INTEGER)
			-- Associate `v' with index `i'.
		do
			array.put (v, array_index (i))
			sequence := sequence.replaced_at (i, v)
		end

feature -- Extension

	extend_front (v: G)
			-- Insert `v' at the front.
		do
			reserve (count_ + 1)
			if count_ = 0 then
				array [0] := v
				first_index := 0
			else
				first_index := mod_capacity (first_index - 1)
				array [first_index] := v
			end
			count_ := count_ + 1
			sequence := sequence.prepended (v)
		end

	extend_back (v: G)
			-- Insert `v' at the back.
		note
			explicit: wrapping
		do
			reserve (count_ + 1)
			count_ := count_ + 1
			array [array_index (count_)] := v
			sequence := sequence & v
		end

	extend_at (v: G; i: INTEGER)
			-- Insert `v' at position `i'.
		do
			if i = 1 then
				extend_front (v)
			elseif i = count_ + 1 then
				extend_back (v)
			else
				reserve (count_ + 1)
				count_ := count_ + 1
				circular_copy (i, i + 1, count_ - i)
				array [array_index (i)] := v
				sequence := sequence.extended_at (i, v)
			end
		end

	prepend (input: V_ITERATOR [G])
			-- Prepend sequence of values, over which `input' iterates.
		do
			insert_at (input, 1)
		end

	insert_at (input: V_ITERATOR [G]; i: INTEGER)
			-- Insert sequence of values, over which `input' iterates, starting at position `i'.
		local
			ic, j, new_capacity: INTEGER
		do
			ic := input.target.count - input.index + 1
			reserve (count_ + ic)
			if i < count_ + 1 then
				circular_copy (i, i + ic, count_ - i + 1)
			end
			new_capacity := array.sequence.count
			sequence := sequence.front (i - 1) + input.sequence.tail (input.index) + sequence.tail (i)

			from
				j := 0
			until
				input.after
			loop
				array [array_index (i + j)] := input.item
				j := j + 1
				input.forth
			variant
				ic - j
			end
			count_ := count_ + ic
		end

feature -- Removal

	remove_front
			-- Remove first element.
		do
			first_index := mod_capacity (first_index + 1)
			count_ := count_ - 1
			sequence := sequence.but_first
		end

	remove_back
			-- Remove last element.
		do
			count_ := count_ - 1
			sequence := sequence.but_last
		end

	remove_at (i: INTEGER)
			-- Remove element at position `i'.
		do
			if i = 1 then
				remove_front
			elseif i = count_ then
				remove_back
			else
				circular_copy (i + 1, i, count_ - i)
				count_ := count_ - 1
				sequence := sequence.removed_at (i)
			end
		end

	wipe_out
			-- Remove all elements.
		do
			count_ := 0
			create sequence
		end

feature {V_CONTAINER, V_ITERATOR} -- Implementation

	array: V_ARRAY [G]
			-- Element storage.

	first_index: INTEGER
			-- Index of the first list element in `array'.

feature {NONE} -- Implementation

	frozen capacity: INTEGER
			-- Size of the underlying array.
		do
			Result := array.count
		end

	default_capacity: INTEGER = 8
			-- Default value for `capacity'.

	growth_rate: INTEGER = 2
			-- Minimum number by which underlying array grows when resized.

	frozen mod_capacity (i: INTEGER): INTEGER
			-- `i' modulo `capacity' in range [`0', `capacity' - 1].
		do
			Result := (i + capacity) \\ capacity
		end

	frozen array_index (i: INTEGER): INTEGER
			-- Position in `array' of `i'th list element.
		do
			Result := mod_capacity (i - 1 + first_index)
		end

	circular_copy (src, dest, n: INTEGER)
			-- Copy `n' elements from position `src' to position `dest'.
		note
			modify_model: sequence, array
		local
			i: INTEGER
		do
			if src < dest then
				from
					i := n
				until
					i < 1
				loop
					array [array_index (dest + i - 1)] := array [array_index (src + i - 1)]
					i := i - 1
				end
			elseif src > dest then
				from
					i := 1
				until
					i > n
				loop
					array [array_index (dest + i - 1)] := array [array_index (src + i - 1)]
					i := i + 1
				end
			end
		end

	reserve (n: INTEGER)
			-- Make sure `array' can accommodate `n' elements;
			-- Do not resize by less than `growth_rate'.
		note
			modify_field: first_index, Current_
		local
			old_size, new_size: INTEGER
		do
			if capacity < n then
				old_size := capacity
				new_size := n.max (capacity * growth_rate)
				array.resize (0, new_size - 1)
				if first_index + count_ > old_size then
					array.copy_range_within (first_index, old_size - 1, new_size - old_size + first_index)
					array.clear (first_index, (old_size - 1).min (new_size - old_size + first_index - 1))
					first_index := new_size - old_size + first_index
				end
			end
		end

feature {NONE} -- Specification

	array_seq_index (i: INTEGER): INTEGER
			-- Index in `array.sequence' that corresponds to index `i' in `sequence'.
		do
			Result := if i + first_index <= array.sequence.count then i + first_index else i + first_index - array.sequence.count end
		end

	list_index (i: INTEGER): INTEGER
			-- Index in `sequence' that corresponds to index `i' in `array.sequence'.
		do
			Result := if i - first_index >= 1 then i - first_index else i - first_index + array.sequence.count end
		end

	array_index_set (lo, hi: INTEGER): MML_SET [INTEGER]
			-- Set of indexes in `array_sequence' that corresponds to index interval `i'..`j' in `sequence'.
		do
			Result := create {MML_INTERVAL}.from_range (lo + first_index, (hi + first_index).min (array.sequence.count)) +
				create {MML_INTERVAL}.from_range ((lo + first_index - array.sequence.count).max (1), hi + first_index - array.sequence.count)
		end

invariant
	array_exists: array /= Void
	array_non_empty: array.sequence.count > 0
	array_starts_from_zero: array.lower_ = 0
	first_index_in_bounds: 0 <= first_index and first_index < array.sequence.count
	sequence_count_constraint: sequence.count <= array.sequence.count
	sequence_implementation: across 1 |..| sequence.count as i all sequence [i.item] = array.sequence [array_seq_index (i.item)] end

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
