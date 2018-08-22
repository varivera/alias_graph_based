note
	description: "Provides the key for HASH MAP variables"
	date: "August, 2018"
	author: "Victor Rivera"
	

class
	ALIAS_KEY
inherit
	HASHABLE
		rename
			is_equal as is_equal_hashable,
			out as out_hashable
		end

	ANY
		redefine
			is_equal,
			out
		select
			is_equal,
			out
		end

create
	make

feature -- Initialisation
	make (a_key: STRING)
		require
			a_key /= Void implies not a_key.is_empty
		do
			if attached a_key as a then
				name := a
			else
				name := ""
			end
		end

feature
	set_assigned
			-- sets variable assigned
		do
			assigned := True
		end


feature -- Access
	name: STRING
			-- name of the variable

	assigned: BOOLEAN
			-- has the current variable being assigned

feature -- Redefinition
	hash_code: INTEGER
			-- Hash code value
		do
			Result := name.hash_code
		end

	is_equal (other: like Current): BOOLEAN
			-- from {ANY}
		do
			Result := other.name.out ~ name.out
		end

	out: STRING
		do
			Result := name
		end

invariant
	attached name as n and then not n.is_empty

note
	copyright: "Copyright (c) 1984-2018, Eiffel Software"
	license: "GPL version 2 (see http://www.eiffel.com/licensing/gpl.txt)"
	licensing_options: "http://www.eiffel.com/licensing"
	copying: "[
			This file is part of Eiffel Software's Eiffel Development Environment.
			
			Eiffel Software's Eiffel Development Environment is free
			software; you can redistribute it and/or modify it under
			the terms of the GNU General Public License as published
			by the Free Software Foundation, version 2 of the License
			(available at the URL listed under "license" above).
			
			Eiffel Software's Eiffel Development Environment is
			distributed in the hope that it will be useful, but
			WITHOUT ANY WARRANTY; without even the implied warranty
			of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
			See the GNU General Public License for more details.
			
			You should have received a copy of the GNU General Public
			License along with Eiffel Software's Eiffel Development
			Environment; if not, write to the Free Software Foundation,
			Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA
		]"
	source: "[
			Eiffel Software
			5949 Hollister Ave., Goleta, CA 93117 USA
			Telephone 805-685-1006, Fax 805-685-6869
			Website http://www.eiffel.com
			Customer support http://support.eiffel.com
		]"
end
