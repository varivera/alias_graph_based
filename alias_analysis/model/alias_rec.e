note
	description: "Managing recursion."
	legal: "See notice at end of class."
	status: "See notice at end of class."
	date: "$Date: (Fri, 07 Oct 2016) $"
	revision: "$Revision: 98127 $"

class
	ALIAS_REC

inherit

	ALIAS_SUB_GRAPH
		export
			{NONE} initialising
		redefine
			make
		end

create {ALIAS_ROUTINE}
	make

feature {ALIAS_ROUTINE} -- Initialisation

	make
		do
			Precursor
			initialising
			step
		end

feature -- Managing recursion

	finalising_recursive_call (root, current_routine: ALIAS_ROUTINE; add, del: TWO_WAY_LIST [HASH_TABLE [TUPLE [name, abs_name: STRING; obj: TWO_WAY_LIST [ALIAS_OBJECT];
						path: TWO_WAY_LIST [TWO_WAY_LIST [STRING]]], ALIAS_KEY]])
			-- restores the graph
		do
			additions := add
			deletions := del
			if tracing then
				printing_vars (1)
			end
				-- Merge `other' into current structure after cursor
				-- position. Do not move cursor. Empty `other'.
			finalising (root, current_routine)
		end

	finalising (root, current_routine: ALIAS_ROUTINE)
		do
				-- i. add deleted links
			add_deleted_links (root, current_routine)

				-- ii. subsume nodes
			subsume (root)
		end

	is_in_structure: BOOLEAN
		do
			Result := True
		end

feature --	Updating deletions (needed in case of conditionals)

	update_del (to_add_del: HASH_TABLE [TUPLE [name, abs_name: STRING; obj: TWO_WAY_LIST [ALIAS_OBJECT]; path: TWO_WAY_LIST [TWO_WAY_LIST [STRING]]], ALIAS_KEY])
			-- Updates `deletions' list with information gathered from {ALIAS_COND} -> `to_add_del'
		do
			across
				to_add_del as values
			loop
				if not deletions.at (1).has (values.key) then
					deletions.at (1).force (values.item, values.key)
				else
					across
						values.item.obj as objects
					loop
						if not deletions.at (1).at (values.key).obj.has (objects.item) then
							deletions.at (1).at (values.key).obj.force (objects.item)
						end
					end
				end
			end
		end;

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
