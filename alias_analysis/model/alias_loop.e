note
	description: "Managing loops."
	legal: "See notice at end of class."
	status: "See notice at end of class."
	date: "$Date: (Fri, 07 Oct 2016) $"
	revision: "$Revision: 98127 $"

class
	ALIAS_LOOP

inherit

	ALIAS_SUB_GRAPH
		rename
			is_in_structure as is_loop_iter,
			initialising as init_loop,
			step as iter,
			finalising as finalising_loop,
			indexes as n_loop
		redefine
			add_deleted_links
		end

create {ALIAS_GRAPH}
	make

feature -- Managing Loop Iterations

	checking_fixpoint
			-- checks (and updates accordingly) if the loop analysis has reached a checkpoint
		require
			is_loop_iter
		do
			if additions.last.count = 0 then
					-- fixpoint: the body of the loop does not change the graph
				fixpoint_reached := 1
			elseif compare_loop_iter then -- TODO: maybe not worthy, it is very expensive (in case of small value for N)
					-- fix point: the graph did not change from last iteration
				fixpoint_reached := 2
			elseif additions.count - n_loop.last.index_add >= n_fixpoint then
					--					-- fixpoint associated to N
				fixpoint_reached := 3
			end
		end

	finalising_loop (root, current_routine: ALIAS_ROUTINE)
			-- adds the deleted nodes to the graph
		local
				output_file: PLAIN_TEXT_FILE
		do
			if tracing then
				printing_vars (1)
			end
			if fixpoint_reached = 2 then
					-- remove the last two iteration: they are the same
				deletions.finish
				deletions.remove
				deletions.finish
				deletions.remove
			end

				-- i. add deleted links
			add_deleted_links (root, current_routine)

				-- ii. subsume nodes (if any): subsume(n1, n2) (n2 will become n1)
			if fixpoint_reached = 3 then
					-- Subsuming corresponding nodes
				subsume (root)
			end
		end

	fixpoint_reached: INTEGER
			-- `fixpoint_reached' stores the type of reachpoint reached:
			--		0: no fixpoint
			--		1: the body of the loop does not change the graph
			-- 		2: the graph did not change from last iteraction
			-- 		3: fixpoint associated to N

	is_loop_iter: BOOLEAN
		do
			Result := not n_loop.is_empty
		end

	set_cond_add (add_cond: detachable like additions)
		do
			cond_add := add_cond
		end

feature {NONE} -- Helpers

	compare_loop_iter: BOOLEAN
			-- compares loop iteractions seeking for fixpoint
			-- Are the last two iteractions the same?
			-- TODO: Maybe better to work with additions
		require
			is_loop_iter
		local
			iter_loop_1, iter_loop_2: HASH_TABLE [TUPLE [name, abs_name, feat_name: STRING; obj: TWO_WAY_LIST [ALIAS_OBJECT]; path: TWO_WAY_LIST [TWO_WAY_LIST [STRING]]], ALIAS_KEY]
		do
			if tracing then
				printing_vars (3)
			end
			if additions.count - n_loop.last.index_add > 0 then -- compares the last 2 iters
				iter_loop_1 := additions.at (additions.count)
				iter_loop_2 := additions.at (additions.count - 1)
				Result := across iter_loop_1 as vals1 all iter_loop_2.at (vals1.key).abs_name ~ vals1.item.abs_name and iter_loop_2.at (vals1.key).obj.count = vals1.item.obj.count and across vals1.item.obj as objs_1 all iter_loop_2.at (vals1.key).obj.has (objs_1.item) end end
			end
		end

	add_links (n, m: ALIAS_OBJECT)
			-- adds m's links to n
		do
			across
				m.attributes as links
			loop
				if not n.attributes.has (links.key) then
					n.attributes.force (create {TWO_WAY_LIST [ALIAS_OBJECT]}.make, links.key)
				end
				across
					links.item as val
				loop
					if not n.attributes.at (links.key).has (val.item) then
						if val.item = m then -- reference to itself
							n.attributes.at (links.key).force (n)
						else
							n.attributes.at (links.key).force (val.item)
						end
					end
				end
			end
		end

	replace (v1, v2: ALIAS_OBJECT; in: HASH_TABLE [TWO_WAY_LIST [ALIAS_OBJECT], ALIAS_KEY])
			-- replaces v1 by v2 in in.values (recursively)
		do
			across
				in as links
			loop
				across
					links.item as vals
				loop
					if vals.item = v1 then
						links.item.go_i_th (vals.cursor_index)
						if links.item.writable then
							links.item.replace (v2)
						end
					end
					if not vals.item.visited then
						vals.item.visited := True
						replace (v1, v2, vals.item.attributes)
					end
				end
			end
		end

	intersection (s1, s2: ARRAY [STRING]): ARRAY [STRING]
			-- returns s1 /\ s2
			-- TODO: the computation can be improved
		do
			create Result.make_empty
			across
				s1 as e
			loop
				if s2.has (e.item) then
					Result.force (e.item, Result.count + 1)
				end
			end
		end

	add_deleted_links (root, current_routine: ALIAS_ROUTINE)
			-- from {ALIAS_SUB_GRAPH}
			-- it changes its behaviour if the loop is inside a condtional: in such case
			-- `add_deleted_links' also adds them to the conditional additions
		do
			if tracing then
				printing_vars (1)
			end
			if n_loop.last.index_del <= deletions.count then
					-- Inserting deleted links
				from
					deletions.go_i_th (n_loop.last.index_del)
				until
					deletions.after
				loop
					across
						deletions.item as values
					loop
						restore_deleted (
							root.current_object,
							current_routine,
							values.key.name,
							current_routine.routine.e_feature.name_32+"_",
							values.item.path,
							values.item.path_locals,
							1, values.item.obj)
						if attached cond_add as conditional then
							across
								values.item.obj as to_add
							loop
								if tracing then
									print ("%N%N%N-DELETIONS------------------------------%N%N%N")
									printing_vars (1)
									print ("%N%N%N-CONDITIONAL-------------------------------%N%N%N")
									printing_va (conditional)
									print ("%N%N%NDone-------------------------------%N%N%N")
									print ("count: ")
									print (conditional.count)
									print ("%N%N%NDone-------------------------------%N%N%N")
									print (conditional.last)
									print ("%N%N%NDone-------------------------------%N%N%N")
									print (values.key)
									print ("%N%N%NDone-------------------------------%N%N%N")
									print (conditional.last.at (values.key))
									print ("%N%N%NDone-------------------------------%N%N%N")
									print (conditional.last.at (values.key).obj)
									print ("%N%N%NDone-------------------------------%N%N%N")
									print (conditional.last.at (values.key).obj.has (to_add.item))
									print ("%N%N%NDone-------------------------------%N%N%N")

								end
								if not conditional.last.at (values.key).obj.has (to_add.item) then
									conditional.last.at (values.key).obj.force (to_add.item)
								end
							end

						end
					end
					deletions.forth
				end
				n_loop.finish
				n_loop.remove
			end
		end

feature -- Access
	cond_add: detachable like additions
		-- contains a alias to additions in conditionals (in case of loop inside a conditional) so to
		-- update the corresponing added links

invariant
	possible_fix_point_loop: fixpoint_reached >= 0 and then fixpoint_reached <= 3

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
