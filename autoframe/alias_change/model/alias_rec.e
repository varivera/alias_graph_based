note
	description: "[
		Keep track of the changes of the grap when the execution is
		analysing a recursion call. The alias graph after the conditional
		will change according to Recursion rules
	]"
	date: "August, 2018"
	author: "Victor Rivera"

class
	ALIAS_REC

inherit

	ALIAS_LOOP
		rename
			finalising_loop as finalising_recursion
		redefine
			make, checking_fixpoint, finalising_recursion
		end

create {ALIAS_NORMAL_CHANGES}
	make, make_empty

feature  -- Initialisation

	make
		do
			Precursor
			iter
		end

	make_empty
		do
			create additions.make
			create deletions.make
		end

feature -- From ALIAS_LOOP
	checking_fixpoint
			-- fix point is checked globally
		do
			do_nothing
		end

	finalising_recursion
		do
			fixpoint_reached := 3 -- TODO Magic number
				-- invert additions and deletions: [[1][2][3]] -> [[3][2][1]]

			Precursor
				-- put all deleted links to deletions.first (delete the rest)
			if deletions.count > 1 then
				from
					deletions.start
					deletions.forth -- from second position
				until
					deletions.after
				loop
					across
						deletions.item as edges
					loop -- very expensive
						if not across deletions.first as e some e.item.is_deep_equal_edge (edges.item) end then
							deletions.first.force (edges.item)
						end
					end
					deletions.forth
				end
				from
					deletions.start
					deletions.forth
				until
					deletions.after
				loop
					deletions.remove
				end
			end
		end

;note
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
