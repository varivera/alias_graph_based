note
	description: "[
		Iterators to read from a container in linear order.
		Indexing starts from 1.
	]"
	author: "Nadia Polikarpova"
	model: target, sequence, index_
	manual_inv: true
	false_guards: true

deferred class
	V_ITERATOR [G]

inherit
	V_INPUT_STREAM [G]
		rename
			search as search_forth
		redefine
			item,
			search_forth
		end

	ITERATION_CURSOR [G]
		rename
			after as off
		redefine
			item
		end

feature -- Access

	target: V_CONTAINER [G]
			-- Container to iterate over.

	item: G
			-- Item at current position.
		deferred
		end

feature -- Measurement

	index: INTEGER
			-- Current position.
		require
		deferred
		end

	valid_index (i: INTEGER): BOOLEAN
			-- Is `i' a valid position for a cursor?
		do
			Result := 0 <= i and i <= target.bag.count + 1
		end

feature -- Status report

	before: BOOLEAN
			-- Is current position before any position in `target'?
		deferred
		end

	after: BOOLEAN
			-- Is current position after any position in `target'?
		deferred
		end

	off: BOOLEAN
			-- Is current position off scope?
		do
			Result := before or after
		end

	is_first: BOOLEAN
			-- Is cursor at the first position?
		deferred
		end

	is_last: BOOLEAN
			-- Is cursor at the last position?
		deferred
		end

feature -- Cursor movement

	start
			-- Go to the first position.
		note
			modify_model: index_, Current_
		deferred
		end

	finish
			-- Go to the last position.
		note
			modify_model: index_, Current_
		deferred
		end

	forth
			-- Go one position forward.
		deferred
		end

	back
			-- Go one position backward.
		note
			modify_model: index_, Current_
		deferred
		end

	go_to (i: INTEGER)
			-- Go to position `i'.
		note
			modify_model: index_, Current_
		local
			j: INTEGER
		do
			if i = 0 then
				go_before
			elseif i = target.count + 1 then
				go_after
			elseif i = target.count then
				finish
			else
				from
					start
					j := 1
				until
					j = i
				loop
					forth
					j := j + 1
				end
			end
		end

	go_before
			-- Go before any position of `target'.
		note
			modify_model: index_, Current_
		deferred
		end

	go_after
			-- Go after any position of `target'.
		note
			modify_model: index_, Current_
		deferred
		end

	search_forth (v: G)
			-- Move to the first occurrence of `v' at or after current position.
			-- If `v' does not occur, move `after'.
			-- (Use reference equality.)
		do
			if before then
				start
			end
			from
			until
				after or else item = v
			loop
				forth
			variant
				sequence.count - index_
			end
		end

	search_back (v: G)
			-- Move to the last occurrence of `v' at or before current position.
			-- If `v' does not occur, move `before'.
			-- (Use reference equality.)
		note
			modify_model: index_, Current_
		do
			if after then
				finish
			end
			from
			until
				before or else item = v
			loop
				back
			end
		end

feature -- Specification

	sequence: MML_SEQUENCE [G]
			-- Sequence of elements in `target'.
		note
			status: ghost
		attribute
		end

	index_: INTEGER
			-- Current position.
		note
			status: ghost
			replaces: box
		attribute
		end

invariant
	target_exists: target /= Void
	target_bag_constraint: target.bag ~ sequence.to_bag
	index_constraint: 0 <= index_ and index_ <= sequence.count + 1
	box_definition: box ~ if sequence.domain [index_] then create {MML_SET [G]}.singleton (sequence [index_]) else {MML_SET [G]}.empty_set end

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
