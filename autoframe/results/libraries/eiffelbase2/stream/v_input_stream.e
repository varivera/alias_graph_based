note
	description: "Streams that provide values one by one."
	author: "Nadia Polikarpova"
	model: box
	manual_inv: true
	false_guards: true

deferred class
	V_INPUT_STREAM [G]

feature -- Access

	item: G
			-- Item at current position.
		deferred
		end

feature -- Status report

	off: BOOLEAN
			-- Is current position off scope?
		deferred
		end

feature -- Cursor movement

	forth
			-- Move one position forward.
		note
			modify_model: box, Current_
		deferred
		end

	search (v: G)
			-- Move to the first occurrence of `v' at or after current position.
			-- If `v' does not occur, move `after'.
			-- (Use reference equality.)
		note
			modify_model: box, Current_
		do
			from
			until
				off or else item = v
			loop
				forth
			end
		end

feature -- Specification

	box: MML_SET [G]
			-- Current element in the stream.
		note
			status: ghost
		attribute
		end

invariant
	box_count_constraint: box.count <= 1

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
