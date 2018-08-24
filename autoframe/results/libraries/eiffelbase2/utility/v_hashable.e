note
	description: "Hahsable object."
	author: "Nadia Polikarpova"

deferred class
	V_HASHABLE

feature -- Access

	hash_code: INTEGER
			-- Hash code.
		deferred
		end

feature -- Specification

	hash_code_: INTEGER
			-- Hash code in terms of abstract state.
		deferred
		end

	is_model_equal (other: like Current): BOOLEAN
			-- Is the abstract state of `Current' equal to that of `other'?
		deferred
		end

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
