note
	description: "Streams where values can be output one by one."
	author: "Nadia Polikarpova"
	model: off_
	manual_inv: true
	false_guards: true

deferred class
	V_OUTPUT_STREAM [G]

feature -- Status report

	off: BOOLEAN
			-- Is current position off scope?
		deferred
		end

feature -- Replacement

	output (v: G)
			-- Put `v' into the stream and move to the next position.
		note
			modify_model: off_, Current_
		deferred
		end

	pipe (input: V_INPUT_STREAM [G])
			-- Copy values from `input' until either `Current' or `input' is `off'.
		note
			modify_model: box, input
		do
			from
			until
				off or input.off
			loop
				output (input.item)
				input.forth
			end
		end

	pipe_n (input: V_INPUT_STREAM [G]; n: INTEGER)
			-- Copy `n' elements from `input'; stop if either `Current' or `input' is `off'.
		note
			modify_model: box, input
		local
			i: INTEGER
		do
			from
				i := 1
			until
				i > n or off or input.off
			loop
				output (input.item)
				input.forth
				i := i + 1
			variant
				n - i
			end
		end

feature -- Specification

	off_: BOOLEAN
		note
			status: ghost
		attribute
		end

invariant

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
