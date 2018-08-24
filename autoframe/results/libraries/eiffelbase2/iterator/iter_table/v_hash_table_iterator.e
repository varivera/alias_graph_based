note
	description: "Iterators over hash tables."
	author: "Nadia Polikarpova"
	model: target, sequence, index_
	manual_inv: true
	false_guards: true

class
	V_HASH_TABLE_ITERATOR [K -> V_HASHABLE, V]

inherit
	V_TABLE_ITERATOR [K, V]
		redefine
			target
		end

create {V_HASH_TABLE}
	make

feature -- Testing

	test_make (t: V_HASH_TABLE [K, V])
			-- Create iterator over `t'.
		note
			modify: Current_
		local
			i_: INTEGER
		do
			target := t
			--list_iterator := t.buckets [1].new_cursor
			from
			until
				True
			loop
				t.lists [i_].add_iterator (list_iterator)
			end
		end


	test_to_next_bucket
		do
			list_iterator.switch_target (target.buckets [bucket_index])
			list_iterator.start
		end


feature {NONE} -- Initialization

	make (t: V_HASH_TABLE [K, V])
			-- Create iterator over `t'.
		note
			modify: Current_
		local
			i_: INTEGER
		do
			target := t
			list_iterator := t.buckets [1].new_cursor
			from
				i_ := 2
			until
				i_ > t.lists.count
			loop
				t.lists [i_].add_iterator (list_iterator)
				i_ := i_ + 1
			end
			bucket_index := 0
			index_ := 0
		end

feature -- Initialization

	copy_ (other: like Current)
			-- Initialize with the same `target' and position as in `other'.
		note
			modify: Current_
		do
			if Current /= other then
				if target /= other.target then
					make (other.target)
				end
				go_to_other (other)
			end
		end

feature -- Access

	target: V_HASH_TABLE [K, V]
			-- Table to iterate over.

	key: K
			-- Key at current position.
		do
			Result := list_iterator.item.left
		end

	item: V
			-- Value at current position.
		do
			Result := list_iterator.item.right
		end

feature -- Measurement		

	index: INTEGER
			-- Current position.
		do
			if after then
				Result := target.count + 1
			elseif not before then
				Result := count_sum (1, bucket_index - 1) + list_iterator.index
			end
		end

feature -- Status report

	before: BOOLEAN
			-- Is current position before any position in `target'?
		do
			Result := bucket_index = 0
		end

	after: BOOLEAN
			-- Is current position after any position in `target'?
		do
			Result := bucket_index > target.capacity
		end

	is_first: BOOLEAN
			-- Is cursor at the first position?
		do
			Result := not off and then (list_iterator.is_first and count_sum (1, bucket_index - 1) = 0)
		end

	is_last: BOOLEAN
			-- Is cursor at the last position?
		do
			Result := not off and then (list_iterator.is_last and count_sum (bucket_index + 1, target.capacity) = 0)
		end

feature -- Comparison

	is_equal_ (other: like Current): BOOLEAN
			-- Is iterator traversing the same container and is at the same position at `other'?
		do
			if target = other.target then
				if bucket_index = other.bucket_index then
					Result := not target.buckets.has_index (bucket_index) or list_iterator.is_equal_ (other.list_iterator)
				end
			end
		end

feature -- Cursor movement

	search_key (k: K)
			-- Move to an element equivalent to `v'.
			-- If `v' does not appear, go after.
			-- (Use object equality.)
		local
			c: V_LINKABLE [MML_PAIR [K, V]]
		do
			bucket_index := target.index (k)
			c := target.cell_equal (target.buckets [bucket_index], k)
			if c = Void then
				bucket_index := target.capacity + 1
				index_ := concat (target.buckets_).count + 1
			else
				list_iterator.switch_target (target.buckets [bucket_index])
				list_iterator.go_to_cell (c)
				index_ := concat (target.buckets_.front (bucket_index - 1)).count + list_iterator.index_
			end
		end

	start
			-- Go to the first position.
		do
			from
				bucket_index := 1
			until
				bucket_index > target.capacity or else not target.buckets [bucket_index].is_empty
			loop
				bucket_index := bucket_index + 1
			variant
				target.lists.count - bucket_index
			end
			if bucket_index <= target.capacity then
				list_iterator.switch_target (target.buckets [bucket_index])
				list_iterator.start
			end
			index_ := 1
		end

	finish
			-- Go to the last position.
		do
			from
				bucket_index := target.capacity
			until
				bucket_index < 1 or else not target.buckets [bucket_index].is_empty
			loop
				bucket_index := bucket_index - 1
			variant
				bucket_index
			end
			if bucket_index >= 1 then
				list_iterator.switch_target (target.buckets [bucket_index])
				list_iterator.finish
			end
			index_ := sequence.count
		end

	forth
			-- Move one position forward.
		do
			list_iterator.forth
			index_ := index_ + 1
			if list_iterator.after then
				to_next_bucket
			end
		end

	back
			-- Go one position backwards.
		do
			list_iterator.back
			index_ := index_ - 1
			if list_iterator.before then
				to_prev_bucket
			end
		end

	go_before
			-- Go before any position of `target'.
		do
			bucket_index := 0
			index_ := 0
		end

	go_after
			-- Go after any position of `target'.
		do
			bucket_index := target.capacity + 1
			index_ := sequence.count + 1
		end

feature -- Replacement

	put (v: V)
			-- Replace item at current position with `v'.
		do
			target.replace_at (Current, v)
		end

feature -- Removal

	remove
			-- Remove element at current position. Move cursor to the next position.
		do
			target.remove_at (Current)
			sequence := concat (target.buckets_)
			value_sequence := value_sequence_from (sequence, target.map)

			if list_iterator.after then
				to_next_bucket
			end
		end

feature {V_CONTAINER, V_ITERATOR, V_LOCK} -- Implementation

	list_iterator: V_LINKED_LIST_ITERATOR [MML_PAIR [K, V]]
			-- Iterator inside current bucket.

	bucket_index: INTEGER
			-- Index of current bucket.

	go_to_other (other: like Current)
			-- Move to the same position as `other'.
		note
			modify_model: index_, Current_
		do
			bucket_index := other.bucket_index
			if 1 <= bucket_index and bucket_index <= target.capacity then
				list_iterator.switch_target (other.list_iterator.target)
				list_iterator.go_to_cell (other.list_iterator.active)
			end
			index_ := other.index_
		end

feature {NONE} -- Implementation

	count_sum (l, u: INTEGER): INTEGER
			-- Total number of elements in buckets `l' to `u'.
		local
			i: INTEGER
		do
			from
				i := l
			until
				i > u
			loop
				Result := Result + target.buckets [i].count
				i := i + 1
			end
		end

	to_next_bucket
			-- Move to the start of next bucket is there is one, otherwise go `after'
		note
			modify_field: bucket_index, closed, box, Current_
			modify: list_iterator
		do
			from
				bucket_index := bucket_index + 1
			until
				bucket_index > target.capacity or else not target.buckets [bucket_index].is_empty
			loop
				bucket_index := bucket_index + 1
			variant
				target.buckets.sequence.count - bucket_index
			end

			if bucket_index <= target.capacity then
				list_iterator.switch_target (target.buckets [bucket_index])
				list_iterator.start
			end
		end

	to_prev_bucket
			-- Move to the end of previous bucket is there is one, otherwise go `before'
		note
			modify_field: bucket_index, box, Current_
			modify: list_iterator
		do
			from
				bucket_index := bucket_index - 1
			until
				bucket_index < 1 or else not target.buckets [bucket_index].is_empty
			loop
				bucket_index := bucket_index - 1
			variant
				bucket_index
			end

			if bucket_index >= 1 then
				list_iterator.switch_target (target.buckets [bucket_index])
				list_iterator.finish
			end
		end

feature {V_CONTAINER, V_ITERATOR} -- Specification

	concat (seqs: like target.buckets_): MML_SEQUENCE [K]
			-- All sequences in `seqs' concatenated together.
		do
			Result := if seqs.is_empty then {MML_SEQUENCE [K]}.empty_sequence else concat (seqs.but_last) + seqs.last end
		end

--	lemma_append (a, b: like target.buckets_)
--			-- Lemma: `concat' distributes over append.
--		note
--			status: lemma, static
--		do
--			use_definition (concat (b))
--			if b.is_empty then
--				check a + b = a end
--			else
--				check (a + b).but_last = a + b.but_last end
--				lemma_append (a, b.but_last)
--				use_definition (concat (a + b))
--			end
--		ensure
--			concat (a + b) = concat (a) + concat (b)
--		end

--	lemma_single_out (seqs: like target.buckets_; i: INTEGER)
--			-- Lemma that singles out `seqs [i]' from `concat (seqs)'.
--		note
--			status: lemma, static
--		require
--			i_in_bounds: 1 <= i and i <= seqs.count
--		do
--			use_definition (concat (seqs.front (i)))
--			check seqs.front (i).but_last = seqs.front (i - 1) end
--			check seqs = seqs.front (i) + seqs.tail (i + 1) end
--			lemma_append (seqs.front (i), seqs.tail (i + 1))
--		ensure
--			concat (seqs) = concat (seqs.front (i - 1)) + seqs [i] + concat (seqs.tail (i + 1))
--		end

--	lemma_empty (seqs: like target.buckets_)
--			-- Lemma: `concat' of empty sequences is an empty sequence.
--		note
--			status: lemma, static
--		require
--			all_empty: across 1 |..| seqs.count as i all seqs [i.item].is_empty end
--		do
--			use_definition (concat (seqs))
--			if seqs.count > 0 then
--				lemma_empty (seqs.but_last)
--			end
--		ensure
--			concat (seqs).is_empty
--		end

--	lemma_content (bs: like target.buckets_; m: like target.map)
--			-- If `m.domain' is the set of elements in `bs', then it is also the set elements in `concat (bs)';
--			-- and the values in `m' are the same as the values in the `m'-image of `concat (bs)'.
--		note
--			status: lemma
--		require
--			target /= Void
--			domain_non_void: m.domain.non_void
--			domain_not_too_small: across 1 |..| bs.count as i all across 1 |..| bs [i.item].count as j all m.domain [(bs [i.item])[j.item]] end end
--			domain_not_too_large: across m.domain as x all across 1 |..| bs.count as i some bs [i.item].has (x.item) end end
--			no_precise_duplicates: across 1 |..| bs.count as i all across 1 |..| bs.count as j all
--					across 1 |..| bs [i.item].count as k all across 1 |..| bs [j.item].count as l all
--							i.item /= j.item or k.item /= l.item implies (bs [i.item])[k.item] /= (bs [j.item])[l.item] end end end end
--		do
--			use_definition (concat (bs))
--			use_definition (value_sequence_from (concat (bs), m))
--			use_definition (target.bag_from (m))
--			if not bs.is_empty then
--				check across 1 |..| (bs.count - 1) as i all bs [i.item] = bs.but_last [i.item] end end
--				check  (m | (m.domain - bs.last.range)).domain = m.domain - bs.last.range end
--				lemma_content (bs.but_last, m | (m.domain - bs.last.range))
--				bs.last.lemma_no_duplicates

--				use_definition (value_sequence_from (concat (bs.but_last), m | (m.domain - bs.last.range)))
--				use_definition (target.bag_from (m | (m.domain - bs.last.range)))
--				check (m | (m.domain - bs.last.range)).sequence_image (concat (bs.but_last)) = m.sequence_image (concat (bs.but_last)) end
--				check m.sequence_image (concat (bs)) = m.sequence_image (concat (bs.but_last)) + m.sequence_image (bs.last) end
--				check m = (m | (m.domain - bs.last.range)) + (m | bs.last.range) end
--				m.lemma_sequence_image_bag (bs.last)
--			else
--				check m.is_empty end
--			end
--		ensure
--			set_constraint: concat (bs).range = m.domain
--			value_sequence_from (concat (bs), m).to_bag ~ target.bag_from (m)
--		end

invariant
	list_iterator_exists: list_iterator /= Void
	bucket_index_in_bounds: 0 <= bucket_index and bucket_index <= target.lists.count + 1
	target_is_bucket: target.lists.has (list_iterator.target)
	target_which_bucket: target.lists.domain [bucket_index] implies list_iterator.target = target.lists [bucket_index]
	list_iterator_not_off: target.lists.domain [bucket_index] implies 1 <= list_iterator.index_ and list_iterator.index_ <= list_iterator.sequence.count
	sequence_implementation: sequence = concat (target.buckets_)
	index_before: bucket_index = 0 implies index_ = 0
	index_after: bucket_index > target.lists.count implies index_ = concat (target.buckets_).count + 1
	index_not_off: target.lists.domain [bucket_index] implies index_ = concat (target.buckets_.front (bucket_index - 1)).count + list_iterator.index_


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
