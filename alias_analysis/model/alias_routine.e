class
	ALIAS_ROUTINE

inherit
	ALIAS_VISITABLE
		rename
			variables as locals
		end

create {ALIAS_GRAPH}
	make

feature {NONE}

	make (a_current_object: like current_object; a_routine: like routine; a_locals: like locals;
					a_caller_path: TWO_WAY_LIST [TWO_WAY_LIST [STRING]])
		require
			a_current_object /= Void
			a_routine /= Void
			a_locals /= Void
			a_caller_path /= Void
		do
			current_object := a_current_object
			routine := a_routine
			locals := a_locals
			caller_path := a_caller_path
			create alias_pos_rec.make

				-- testing
			create map_funct.make (0)
		ensure
			current_object = a_current_object
			routine = a_routine
			locals = a_locals
			caller_path = a_caller_path
		end

feature {ANY}

	current_object: ALIAS_OBJECT

	routine: PROCEDURE_I

	caller_path: TWO_WAY_LIST [TWO_WAY_LIST [STRING]]
			-- holds the entities of the objects which called Current routine
			-- if empty, the entity is Current
			-- 	It is a list of list since a routine can be called by more than one path, e.g.
			--			do
			--				x.set_x
			--			end
			--			
			--			x: T
			--				do
			--					if C then
			--						Result := v
			--					else
			--						Result := w
			--					end
			--				end
			-- 'set_x' is being called from 'v' and 'w': [[previous], [v,w]]

	alias_pos_rec: ALIAS_REC
			-- manages edges and nodes of the graph in case of fixpoint by recursion
			-- alias_pos_rec stands for alias possible recursion

feature -- Test (March 06) TODO
	map_funct: HASH_TABLE [TWO_WAY_LIST [STRING], STRING]
			-- maps a function called to actual return values in attributes


feature {ANY}

	out: STRING_8
		do
			Result := current_object.out + "." + routine.feature_name_32
		end

invariant
	routine /= Void
	current_object /= Void
	caller_path /= Void

note
	copyright: "Copyright (c) 1984-2017, Eiffel Software"
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
