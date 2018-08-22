note
	description: "[
		Keep track of the changes of the grap when the execution is 
		analysing a branch of a conditional. The alias graph after the conditional
		will change according to Conditional rules
	]"
	date: "August, 2018"
	author: "Victor Rivera"

class
	ALIAS_COND

inherit

	ALIAS_CHANGES
		rename
			step as init_branch,
			finalising as finalising_cond
		end

create {ALIAS_GRAPH, ALIAS_ROUTINE}
	make

feature -- Managing Conditionals Branches
	restoring_state
			-- restores the alias graph as it was before the current conditional branch
			-- (i.e. additions.last and deletions.last).
		do
				-- delete added objects
			across
				additions.last as added
			loop
				remove_edge (added.item)
			end

				-- add deleted objects
			across
				deletions.last as deleted
			loop
				add_edge (deleted.item)
			end
		end

	finalising_cond
			-- it consists of two actions:
			--	i) deletes the intersection of elements in `deletions'
			--	ii) inserts the union of elements in `additions'
		do
				-- delete the intersection of `deletions'
			intersection_deletions
			check deletions.count <= 1 then
					-- delete added objects
				across
					deletions.first as deleted
				loop
					remove_edge (deleted.item)
				end
			end

				-- Inserting the union of `additions'
			union_additions

			check additions.count <= 1 then
						-- add added objects
				across
					additions.first as added
				loop
					add_edge (added.item)
				end
			end
		end

	intersection_deletions
			-- leaves the intersection in `deletions' (the ones to be deleted from the graph)
			-- it will leave the intersection in deletions.first (deletions will contain only one element)
		local
			i: INTEGER
			stop: BOOLEAN
		do
			from
				deletions.first.start
			until
				deletions.first.after
			loop
				from
					i := 2 -- from second element, if any
					stop := False
				until
					i > deletions.count or stop
				loop
					if across deletions.at (i) as edges some edges.item.is_equal_edge (deletions.first.item) end then
						i := i + 1
					else
						stop := True
					end
				end
				if stop then
					deletions.first.remove
				else
					deletions.first.forth
				end
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

	union_additions
			-- leaves the union of `additions' in additions.first (the ones to be added to the graph)
			-- (additions will contain only one element)
		local
			i: INTEGER
		do


			from
				i := 2
			until
				i > additions.count
			loop
				additions.at (1).merge_right (additions.at (i))
				i := i + 1
			end

			from
				additions.start
				additions.forth
			until
				additions.after
			loop
				additions.remove
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
