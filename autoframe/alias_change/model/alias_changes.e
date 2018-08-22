note
	description: "[
		This class managing sub-alias-graph when need it: the main the functionality to add/delete/restore the Alias graph when the
		analysis enters in structures such as conditionals, loops, recursions or handling 'dynamic binding'
		This class provides mechanisms to manipulate the graph and to restore it. Also mechanismos to subsume nodes.
	]"
	date: "August, 2018"
	author: "Victor Rivera"

deferred class
	ALIAS_CHANGES

inherit

	TRACING

feature {NONE} -- Initialiasation

	make
			-- Initialises an {ALIAS_CHANGES} and descendants
		do
			create additions.make
			create deletions.make
		end

feature -- Updating

	updating_A_D (target_object: ALIAS_VISITABLE;
				source_new_object, source_old_object: TWO_WAY_LIST [ALIAS_OBJECT];
				tag_name: STRING)
			-- updates the sets `additions' and `deletions' accordingly
			-- refer to the documentation that describes the calculus
		require
			tag_name /= Void and then not tag_name.is_empty
			target_object /= Void
		local
		do
			additions.last.force (create {ALIAS_EDGE}.make (target_object, source_new_object, tag_name))
			deletions.last.force (create {ALIAS_EDGE}.make (target_object, source_old_object, tag_name))
		end

feature -- Managing Branches

	step
			-- initialises a step of a structure: e.g. a conditional branch
		do
			additions.force (create {
				TWO_WAY_LIST [ALIAS_EDGE]}.make)
			deletions.force (create {
				TWO_WAY_LIST [ALIAS_EDGE]}.make)
		end

	finalising
			-- it consists of two actions:
			--	i) inserts the union of elements in `additions'
			--	ii) deletes the intersection of elements in `deletions'
			--to `current_alias_routine'
		deferred
		ensure
			additions.count = 1
		end

feature -- Modifying the graph

	remove_edge (edge: ALIAS_EDGE)
			-- remove 'edge'.tag from `edge.target' (successors) and `edge.source' (predecesors)
		require
			--edge.target.attributes.has (create {ALIAS_KEY}.make (edge.tag))
		local
			k: ALIAS_KEY
			pred: HASH_TABLE [TWO_WAY_LIST [ALIAS_VISITABLE], ALIAS_KEY]
		do
			if edge.target.variables.has (create {ALIAS_KEY}.make (edge.tag)) then
				create k.make (edge.tag)

				across
					edge.sources as sources
				loop
						-- remove sources.item from edge.target [edge.tag]
					from
						edge.target.variables.at (k).start
					until
						edge.target.variables.at (k).after
					loop
						if edge.target.variables.at (k).item ~ sources.item then
							edge.target.variables.at (k).remove
						else
							edge.target.variables.at (k).forth
						end
					end

						-- remove edge.target from sources.item.predecessors
					if sources.item.predecessors.has (k) then
						pred := sources.item.predecessors
					elseif sources.item.predecessors_param.has (k) then
						pred := sources.item.predecessors_param
					else
						check False end
					end

					from
						pred.at (k).start
					until
						pred.at (k).after
					loop
						if pred.at (k).item ~ edge.target then

							pred.at (k).remove
						else
							pred.at (k).forth
						end
					end
				end
			end
		end

	add_edge (edge: ALIAS_EDGE)
			-- adds `edge'.tag to `edge.target' (successors) and `edge.source' (predecesors)
		require
--			edge.target.attributes.has (create {ALIAS_KEY}.make (edge.tag))
		local
			k: ALIAS_KEY
		do
			if edge.target.variables.has (create {ALIAS_KEY}.make (edge.tag)) then
				create k.make (edge.tag)

				across
					edge.sources as source
				loop
						-- succesors of edge.target
					--if across edge.target.attributes.at (k) as obj all obj.item /~ source.item end then
					if across edge.target.variables.at (k) as obj all obj.item /= source.item end then
						edge.target.variables.at (k).force (source.item)
					end
						-- predecesors of source.item
					if source.item.predecessors.has (k) then
						if across source.item.predecessors.at (k) as obj all obj.item /~ edge.target end then
							source.item.predecessors.at (k).force (edge.target)
						end
					elseif source.item.predecessors_param.has (k) then
						if across source.item.predecessors_param.at (k) as obj all obj.item /~ edge.target end then
							source.item.predecessors_param.at (k).force (edge.target)
						end
					else
						check False end
					end
				end
			end
		end

	restoring_state
			-- restores the alias graph as it was before
			-- (i.e. additions.last and deletions.last).
		deferred
		end

feature -- Managing merging nodes (for loops and recursion)

	subsume
			-- checks if there are nodes to be subsumed (use additions for doing so). If so, it subsumes them
			-- TODO: this feature checks the last two iterations: is it enough?
		require
			attached additions and then additions.count > 1 and then
			additions.at (additions.count).count = additions.at (additions.count - 1).count
		local
			look_up_nodes: HASH_TABLE [TWO_WAY_LIST [ALIAS_OBJECT], ALIAS_OBJECT]
		do
			create look_up_nodes.make (0)
			across
				1 |..| additions.last.count as i
			loop
				if additions.at (additions.count).at (i.item).tag /~ "Result" -- do not subsume Result
					and then
						not additions.at (additions.count).at (i.item).is_deep_equal_edge (additions.at (additions.count - 1).at (i.item))
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

	subsume_nodes (n2, n1: ALIAS_OBJECT)
			-- subsumes node `n2' by `n1' in the graph
			-- it comprises 3 steps
			-- i. for_all i | i \in Nodes and i /= 2 and n_2 -->_t n_i then n_1 -->_t n_i
			-- ii. for_all i | i \in Nodes and i /= 2 and n_i -->_t n_2 then n_i -->_t n_1
			-- iii. for_all n_2 -->_t n_2 then n_1 -->_t n_1
		local
			source: TWO_WAY_LIST [ALIAS_OBJECT]
			self_source: TWO_WAY_LIST [ALIAS_KEY]
		do
				-- (i)
			create self_source.make
			across
				n2.attributes as att
			loop
				create source.make
				across
					att.item as obj
				loop
					if obj.item.is_equal (n2) then
						self_source.force (att.key)
					else
						source.force (obj.item)
					end
				end
				if source.count /= 0 then
					remove_edge (create {ALIAS_EDGE}.make (n2, source, att.key.name))
				end
				if not n1.attributes.has (att.key) then
					n1.attributes.force (create {TWO_WAY_LIST [ALIAS_OBJECT]}.make, att.key)
				end

				add_edge (create {ALIAS_EDGE}.make (n1, source, att.key.name))
			end
				-- (ii)
			across
				n2.predecessors as att
			loop
				across
					att.item as obj
				loop
					create source.make
					source.force (n2)
					remove_edge (create {ALIAS_EDGE}.make (obj.item, source, att.key.name))


					if not n1.attributes.has (att.key) then
						n1.attributes.force (create {TWO_WAY_LIST [ALIAS_OBJECT]}.make, att.key)
					end

					create source.make
					source.force (n1)

					if not n1.predecessors.has (att.key) then
						n1.predecessors.force (create {TWO_WAY_LIST [ALIAS_VISITABLE]}.make, att.key)
					end

					add_edge (create {ALIAS_EDGE}.make (obj.item, source, att.key.name))
				end
			end

				-- (iii)

			across
				self_source as ss
			loop
				if not n1.attributes.has (ss.item) then
					n1.attributes.force (create {TWO_WAY_LIST [ALIAS_OBJECT]}.make, ss.item)
				end
				create source.make
				source.force (n1)
				add_edge (create {ALIAS_EDGE}.make (n1, source, ss.item.name))
			end
		end

feature{NONE} -- Helper

feature -- Access

	additions: TWO_WAY_LIST [TWO_WAY_LIST [ALIAS_EDGE]];
		-- stores the edges added by a step (A_i in the def)

	deletions: like additions
		-- stores the edges deleted by a step (D_i in the def)

feature --{NONE} -- For debugging purposes

	print_atts_depth (c: HASH_TABLE [TWO_WAY_LIST [ALIAS_OBJECT], ALIAS_KEY])
		do
			if tracing then
				print ("Atts Deep%N")
				print_atts_depth_help (c, 1)
				reset (c)
				print ("-------------------------------------------------%N")
			end
		end

	reset (in: HASH_TABLE [TWO_WAY_LIST [ALIAS_OBJECT], ALIAS_KEY])
		do
			across
				in as links
			loop
				across
					links.item as vals
				loop
					if vals.item.visited then
						vals.item.visited := false
						reset (vals.item.attributes)
					end
				end
			end
		end

	print_atts_depth_help (in: HASH_TABLE [TWO_WAY_LIST [ALIAS_OBJECT], ALIAS_KEY]; i: INTEGER)
		local
			tab: STRING
		do
			if tracing then
				create tab.make_filled (' ', i)
				across
					in as links
				loop
					print (tab)
					print (links.key.name + ": [")
					across
						links.item as vals
					loop
						print (vals.item.out2)
						print (":")
						io.new_line
						if not vals.item.visited then
							vals.item.visited := true
							print_atts_depth_help (vals.item.attributes, i + 2)
						end
					end
					print (tab)
					print ("]")
					io.new_line
					io.new_line
				end
			end
		end

	printing_vars (va: INTEGER)
			-- va
			--		(1): additions and deletions
			--      (2): deletions
			--		(3): additions
			--		(4): nothing
		require
			va = 1 or va = 2 or va = 3 or va = 4
		local
			ttt: TWO_WAY_LIST [TWO_WAY_LIST [ALIAS_EDGE]]
		do
			if tracing then
				if va = 4 then
				else
					if va = 1 or va = 3 then
						print ("%N%NAdditions%N%N")
						ttt := additions
					else
						print ("%N%NDeletions%N%N")
						ttt := deletions
					end
					across
						ttt as added
					loop
						print ("--%N")
						across
							added.item as edge
						loop
							print (edge.item.out_edge)
							print (" , ")
						end

						io.new_line
					end
					if va = 1 then
						printing_vars (2)
					elseif va = 2 or va = 3 then
						printing_vars (4)
					end
				end
			end
		end


	printing_va (v: like additions)
			-- va
			--		(1): additions and deletions
			--      (2): deletions
			--		(3): additions
			--		(4): nothing
		local
			ttt: TWO_WAY_LIST [TWO_WAY_LIST [ALIAS_EDGE]]
			va: INTEGER
		do
			va := 1
			if tracing then
				if va = 4 then
				else
					if va = 1 or va = 3 then
						print ("%N%NAdditions%N%N")
						ttt := v
					end
					across
						ttt as added
					loop
						print ("--%N")
						across
							added.item as edge
						loop
							print (edge.item.out_edge)
							print (" , ")
						end
						io.new_line
					end
				end
			end
		end

feature {NONE}

	n_fixpoint: INTEGER = 3
			-- `n_fixpoint' is a fix number: upper bound for loops and rec

invariant
	additions /= Void
	deletions /= Void

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
