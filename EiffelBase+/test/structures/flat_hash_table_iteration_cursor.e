class
	FLAT_HASH_TABLE_ITERATION_CURSOR [G, K -> detachable HASHABLE]

create
	make

feature {NONE} -- Initialization

	make (s: like target)
			-- Initialize cursor using structure `s'.
		require
			s_attached: s /= Void
		do
			target := s
			if attached {VERSIONABLE} s as l_versionable then
				version := l_versionable.version
			else
				version := 0
			end
			step := 1
			is_reversed := False
		ensure
			structure_set: target = s
			is_valid: is_valid
			default_step: step = 1
			ascending_traversal: not is_reversed
		end

feature -- Access

	item: G
			-- Item at current cursor position.
		require -- from ITERATION_CURSOR
			valid_position: not after
		do
			Result := target.content [iteration_position]
		end

	key: K
			-- Key at current cursor position
		require
			valid_position: not after
		do
			Result := target.keys [iteration_position]
		end

	target: FLAT_HASH_TABLE [G, K]
			-- Associated structure used for iteration.			

	cursor_index: INTEGER_32
			-- Index position of cursor in the iteration.
		do
			if is_reversed then
				Result := index_set.upper - iteration_position + 1
			else
				Result := iteration_position - index_set.lower + 1
			end
		ensure
			positive_index: Result >= 0
		end

	decremented alias "-" (n: like step): like Current
			-- Copy of Current with step decreased by `n'.
		require
			n_valid: step > n
		do
			Result := twin
			Result.set_step (step - n)
		ensure
			is_incremented: Result.step = step - n
			same_structure: Result.target = target
			same_direction: Result.is_reversed = is_reversed
		end

	incremented alias "+" (n: like step): like Current
			-- Copy of Current with step increased by `n'.
		require
			n_valid: step + n > 0
		do
			Result := twin
			Result.set_step (step + n)
		ensure
			is_incremented: Result.step = step + n
			same_structure: Result.target = target
			same_direction: Result.is_reversed = is_reversed
		end

	new_cursor: FLAT_HASH_TABLE_ITERATION_CURSOR [G, K]
			-- Restarted copy of Current.
		do
			Result := twin
			Result.start
		ensure -- from ITERABLE
			result_attached: Result /= Void
		end

	reversed alias "-": like Current
			-- Reversed copy of Current.
		do
			Result := twin
			Result.reverse
		ensure
			is_reversed: Result.is_reversed = not is_reversed
			same_structure: Result.target = target
			same_step: Result.step = step
		end

	step: INTEGER_32
			-- Distance between successive iteration elements.

	iteration_position: INTEGER_32
			-- Index position of target for current iteration.

	with_step (n: like step): like Current
			-- Copy of Current with step set to `n'.
		require
			n_positive: n > 0
		do
			Result := twin
			Result.set_step (n)
		ensure
			step_set: Result.step = n
			same_structure: Result.target = target
			same_direction: Result.is_reversed = is_reversed
		end

feature -- Measurement

	version: NATURAL_32
			-- Current version.
		note
			option: transient
		attribute
		end

feature -- Status report

	after: BOOLEAN
			-- Are there no more items to iterate over?
		local
			l_pos: like iteration_position
		do
			l_pos := iteration_position
			Result := not is_valid or l_pos < 0 or l_pos >= target.keys.count
		end

	is_reversed: BOOLEAN
			-- Are we traversing target backwards?

	is_valid: BOOLEAN
			-- Is the cursor still compatible with the associated underlying object?
		do
			Result := attached {VERSIONABLE} target as l_versionable implies l_versionable.version = version
		end

feature -- Status setting

	reverse
			-- Flip traversal order.
		do
			is_reversed := not is_reversed
		ensure
			is_reversed: is_reversed = not old is_reversed
		end

	set_step (v: like step)
			-- Set increment step to `v'.
		require
			v_positive: v > 0
		do
			step := v
		ensure
			step_set: step = v
		end

feature -- Cursor movement

	forth
			-- Move to next position.
		require -- from ITERATION_CURSOR
			valid_position: not after
		local
			i, nb: like step
			l_pos: like iteration_position
		do
			l_pos := iteration_position
			nb := step
			if is_reversed then
				from
					i := 1
				until
					i > nb or else l_pos < 0
				loop
					l_pos := target.previous_iteration_position (l_pos)
					i := i + 1
				end
			else
				from
					i := 1
				until
					i > nb or else l_pos >= target.keys.count
				loop
					l_pos := target.next_iteration_position (l_pos)
					i := i + 1
				end
			end
			iteration_position := l_pos
		ensure then
			cursor_index_advanced: cursor_index = old cursor_index + 1
		end

	start
		require -- from  ITERATION_CURSOR
			True
		do
			if is_reversed then
				iteration_position := index_set.upper
			else
				iteration_position := index_set.lower
			end
		ensure then
			cursor_index_set_to_one: cursor_index = 1
		end


feature {FLAT_READABLE_INDEXABLE} -- Implementation

	index_set: FLAT_INTEGER_INTERVAL
			-- Range of acceptable indexes for target.
		do
			Result := target.iteration_index_set
		end

invariant
	target_attached: target /= Void
	step_positive: step > 0

end
