note
	description: "Iterators to read and write from/to a container in linear order."
	author: "Nadia Polikarpova"
	model: target, sequence, index_
	manual_inv: true
	false_guards: true

deferred class
	V_IO_ITERATOR [G]

inherit
	V_ITERATOR [G]
		redefine
			sequence,
			index_
		end

	V_OUTPUT_STREAM [G]

feature -- Replacement

	put (v: G)
			-- Replace item at current position with `v'.
		note
			modify_model: sequence, box, Current_
			modify_model: bag, target
		deferred
		end

	output (v: G)
			-- Replace item at current position with `v' and go to the next position.
		do
			put (v)
			forth
		end

feature -- Specification

	sequence: MML_SEQUENCE [G]
			-- Sequence of elements in `target'.
		note
			status: ghost
			replaces: off_
		attribute
		end

	index_: INTEGER
			-- Current position.
		note
			status: ghost
			replaces: off_
		attribute
		end

invariant
	off_definition: off_ = not sequence.domain [index_]

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
