note
	description: "[
		Keep track of the changes of the grap when the execution is
		analysing a loop iteration. The alias graph after the loop
		will change according to Loop rules
	]"
	date: "August, 2018"
	author: "Victor Rivera"

class
	ALIAS_LOOP

inherit

	ALIAS_CHANGES
		rename
			step as iter,
			finalising as finalising_loop
		redefine
			subsume
		end

create {ALIAS_ROUTINE, ALIAS_GRAPH} --TODO: totake out ALIAS_GRAPH
	make

feature -- Managing Loop Iterations

	checking_fixpoint
			-- checks (and updates accordingly) if the loop analysis has reached a checkpoint
		do
			if additions.last.count = 0 then
					-- fixpoint: the body of the loop does not change the graph
				fixpoint_reached := 1
			elseif compare_loop_iter then -- TODO: maybe not worthy, it is very expensive (in case of small value for N)
					-- fix point: the graph did not change from last iteration
				fixpoint_reached := 2
			elseif additions.count >= n_fixpoint then
					--					-- fixpoint associated to N
				fixpoint_reached := 3
			end
		end

	finalising_loop
			-- adds the deleted nodes to the graph
		do

			if fixpoint_reached = 2  then
					-- remove the last iteration: the last 2 iterations are the same
				deletions.finish
				deletions.remove
				additions.finish
				additions.remove
			end
				-- i. add deleted links
			add_deleted_links

				-- ii. subsume nodes (if any): subsume(n1, n2) (n2 will become n1)
			if fixpoint_reached = 3 then
					-- Subsuming corresponding nodes
				subsume
			end


				-- put all added links to additions.first (delete the rest)
			transfer_to_first (additions)
			transfer_to_first (deletions)
		end

	transfer_to_first (l: TWO_WAY_LIST [TWO_WAY_LIST [ALIAS_EDGE]])
			-- put all added/deleted (i.e. `l') links to (additions/deletions).first (i.e. `l'.first) (delete the rest)
		do

			if l.count > 1 then
				from
					l.start
					l.forth -- from second position
				until
					l.after
				loop
					across
						l.item as edges
					loop -- very expensive
						if not across l.first as e some e.item.is_deep_equal_edge (edges.item) end then
							l.first.force (edges.item)
						end
					end
					l.forth
				end
				from
					l.start
					l.forth
				until
					l.after
				loop
					l.remove
				end
			end
		end

	fixpoint_reached: INTEGER
			-- `fixpoint_reached' stores the type of reachpoint reached:
			--		0: no fixpoint
			--		1: the body of the loop does not change the graph
			-- 		2: the graph did not change from last iteraction
			-- 		3: fixpoint associated to N

feature {NONE} -- Helpers

	compare_loop_iter: BOOLEAN
			-- compares loop iteractions seeking for fixpoint
			-- Are the last two iteractions the same? this happens when no added value is done in the loop
		local
			i: INTEGER
		do

			if additions.count >= 2 and additions.at (additions.count).count = additions.at (additions.count - 1).count then
					-- comparison can be done one by one
				from
					i := 1
					Result := True
				until
					i > additions.last.count or not Result
				loop
					if not additions.at (additions.count).at (i).is_deep_equal_edge (additions.at (additions.count - 1).at (i)) then
						Result := False
					else
						i := i + 1
					end
				end
			end
		end

	add_deleted_links
			-- adds all deleted links
		do
			across
				deletions as iteration
			loop
				across
					iteration.item as deleted_edge
				loop
					add_edge (deleted_edge.item)
				end
			end
		end

	restoring_state
			-- loops do not restore the state of the graph in each iteration
			-- it is done at the end
		do
			do_nothing
		end

	subsume
			-- checks if there are nodes to be subsumed (use additions for doing so). If so, it subsumes them
			-- TODO: this feature checks the last two iterations: is it enough?
		local
			look_up_nodes: HASH_TABLE [TWO_WAY_LIST [ALIAS_OBJECT], ALIAS_OBJECT]
		do
			create look_up_nodes.make (0)
			across
				1 |..| additions.last.count as i
			loop

				if (additions.at (additions.count).at (i.item).tag ~ "Result" implies
					additions.at (additions.count).at (i.item).target = additions.at (additions.count-1).at (i.item).target
				)-- do not subsume Result
					and then
					not
						additions.at (additions.count).at (i.item).is_deep_equal_edge (additions.at (additions.count - 1).at (i.item))
					and then
					(
						(
						additions.at (additions.count - 1).at (i.item).sources.first.attributes.has (
								create {ALIAS_KEY}.make (additions.at (additions.count-1).at (i.item).tag))
								and then (
								across additions.at (additions.count - 1).at (i.item).sources.first.attributes.at (
																	create {ALIAS_KEY}.make (additions.at (additions.count-1).at (i.item).tag))
											as s some s.item ~ additions.at (additions.count).at (i.item).sources.first end

								)
						)
					or
--						(locals.has (additions.at (additions.count-1).at (i.item).tag) and then
--										locals.at (additions.at (additions.count-1).at (i.item).tag) ~
--										additions.at (additions.count-1).at (i.item).target)
						(attached current_routine as cr and then attached {ALIAS_ROUTINE} additions.at (additions.count-1).at (i.item).target as target and then
							target.current_object = cr.current_object and then
							cr.locals.has (create {ALIAS_KEY}.make (additions.at (additions.count-1).at (i.item).tag))
						)
					)
				then
					if not look_up_nodes.has (additions.at (additions.count).at (i.item).sources.first) then
						look_up_nodes.force (create {TWO_WAY_LIST [ALIAS_OBJECT]}.make, additions.at (additions.count).at (i.item).sources.first)
						look_up_nodes.at (additions.at (additions.count).at (i.item).sources.first).force (additions.at (additions.count - 1).at (i.item).sources.first)
							-- TODO: missing the rest of AO in source
						subsume_nodes (additions.at (additions.count).at (i.item).sources.first,
										additions.at (additions.count - 1).at (i.item).sources.first)
					elseif across look_up_nodes.at (additions.at (additions.count).at (i.item).sources.first)
								as l all additions.at (additions.count - 1).at (i.item).sources.first /~ l.item end then
						look_up_nodes.at (additions.at (additions.count).at (i.item).sources.first).force (additions.at (additions.count - 1).at (i.item).sources.first)
							-- TODO: missing the rest of AO in source
						subsume_nodes (additions.at (additions.count).at (i.item).sources.first,
										additions.at (additions.count - 1).at (i.item).sources.first)
					end


				else
						-- nodes should not be subsumed
					do_nothing
				end
			end
		end

feature -- managing locals

	current_routine: ALIAS_ROUTINE
		-- alias routine of the current routine (to take into consideration when subsume)

	set_current_routine (a_current_routine: ALIAS_ROUTINE)
		do
			current_routine := a_current_routine
		end

invariant
	possible_fix_point_loop: fixpoint_reached >= 0 and then fixpoint_reached <= 3

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
