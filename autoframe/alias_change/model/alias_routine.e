note
	description: "[
		It represents a type of node (fake one) that holds 
		routines, arguments and local variables.
		
		The class also manages Recursion
	]"
	date: "August, 2018"
	author: "Victor Rivera"

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

	make (a_current_object: like current_object; a_routine: like routine; a_locals: like locals)
		require
			a_current_object /= Void
			a_routine /= Void
			a_locals /= Void
		do
			current_object := a_current_object
			routine := a_routine
			locals := a_locals
			create graph_changes.make
			graph_changes.force (create {ALIAS_NORMAL_CHANGES}.make)

			create map_funct.make (0)


		ensure
			current_object = a_current_object
			routine = a_routine
			locals = a_locals
		end

feature {ANY}

	current_object: ALIAS_OBJECT
			-- contains the class attributes of the current object

	routine: PROCEDURE_I
			-- refers to the routine the current object is in

feature {ALIAS_GRAPH, ALIAS_ROUTINE} -- manages changes of the routine
	graph_changes: TWO_WAY_LIST [ALIAS_CHANGES]
			-- stores all changes in the graph by this routine. This is used when
			-- the graph is restored after a conditional, loop, or a recursion. It is
			-- implemented as a stack since it is possible to have nested
			-- conditionals/loops/recursions
			-- TODO: better name for it

feature -- Test (March 06) TODO
	map_funct: HASH_TABLE [TWO_WAY_LIST [STRING], ALIAS_KEY]
			-- maps a function called to actual return values in attributes


feature -- Managing Conditionals

	is_conditional_branch: BOOLEAN
		do
			Result := attached {ALIAS_COND} graph_changes.last
		end

	init_cond
			-- initialises the counter for branches in a conditional and
			-- stores the initial state of the graph
		do
			graph_changes.force (create {ALIAS_COND}.make)
		end

	init_cond_branch
			-- initialises a branch for a conditional.
		do
			if attached {ALIAS_COND} graph_changes.last as alias_cond then
				alias_cond.init_branch
			end
		end

	restore_graph
			-- restores the alias graph as it was before the current conditional branch
		require
			is_conditional_branch
		do
			graph_changes.last.restoring_state
		end

	finalising_cond
			-- finalises the operations of conditionals
		require
			is_conditional_branch
		do
			graph_changes.last.finalising
			transfer_additions
			transfer_deletions

			graph_changes.finish
			graph_changes.remove
		end

	transfer_additions
			-- transfer the information about additions from the top of
			-- graph_changes to the next one
		do
			check graph_changes.count > 1 and then graph_changes.last.additions.count = 1 then
				transfer_changes (graph_changes.at (
								graph_changes.count - 1).additions.last, graph_changes.last.additions)
			end
		end

	transfer_deletions
			-- transfer the information of deletions from the top of
			-- graph_changes to the next one
		do
			check graph_changes.count > 1 and then graph_changes.last.deletions.count = 1 then
				transfer_changes (graph_changes.at (
								graph_changes.count - 1).deletions.last, graph_changes.last.deletions)
			end
		end

feature -- Managing changing
	finalising_transfer (a: ALIAS_ROUTINE)
			-- transfer additions and deletions when a function (call) finished
			-- takes care of tracking changes when recursion and finalising recursion if needed
		require
			no_more_than_one_in_graph_changes: graph_changes_count = 1
		do
			if attached {ALIAS_NORMAL_CHANGES} graph_changes.first as rec then
				if attached rec.rec then
					if rec.rec.additions.count >= 1 and then rec.rec.deletions.count >= 1 and then
						rec.rec.additions.first.count = 0 and then rec.rec.deletions.first.count = 0
					then
						transfer_changes (rec.rec.additions.first, rec.additions)
						transfer_changes (rec.rec.deletions.first, rec.deletions)
						if rec.rec.additions.count = 3 then -- TODO: magic number
							finalising_recursion
							transfer_changes (a.graph_changes.last.additions.last, rec.rec.additions)
							transfer_changes (a.graph_changes.last.deletions.last, rec.rec.deletions)
						else
							check attached {ALIAS_NORMAL_CHANGES} a.graph_changes.first as a_rec then
								transfer_rec_changes (a_rec, rec)
							end
						end
					else
						transfer_changes (a.graph_changes.last.additions.last, rec.additions)
						transfer_changes (a.graph_changes.last.deletions.last, rec.deletions)

						check attached {ALIAS_NORMAL_CHANGES} a.graph_changes.first as a_rec then
							transfer_rec_changes (a_rec, rec)
						end
					end
				else
					transfer_changes (a.graph_changes.last.additions.last, graph_changes.last.additions)
					transfer_changes (a.graph_changes.last.deletions.last, graph_changes.last.deletions)
				end
			end
		end

	finalising_routine
			-- finalise recursion if needed
		require
			no_more_than_one_in_graph_changes: graph_changes_count = 1
		do
			if attached {ALIAS_NORMAL_CHANGES} graph_changes.first as rec then
				if attached rec.rec then
					if rec.rec.additions.count >= 1 and then rec.rec.deletions.count >= 1 and then
						rec.rec.additions.first.count = 0 and then rec.rec.deletions.first.count = 0
					then
						transfer_changes (rec.rec.additions.first, rec.additions)
						transfer_changes (rec.rec.deletions.first, rec.deletions)
						if rec.rec.additions.count = 3 then -- TODO: magic number
							finalising_recursion
						end
					end
				end
			end
		end

	transfer_changes (holder: TWO_WAY_LIST [ALIAS_EDGE]; from_changes: TWO_WAY_LIST [TWO_WAY_LIST [ALIAS_EDGE]])
			-- transfer the information in `from_changes' to `holder'
		require
			from_changes.count = 1
		do
			across
				from_changes.first as changes
			loop
				holder.force (changes.item)
			end

			from_changes.start
			from_changes.remove


		ensure
			from_changes.count = 0
		end

	registering_changes (a_target_obj: ALIAS_VISITABLE; a_new_source_objs, a_old_source_objs: TWO_WAY_LIST [ALIAS_OBJECT];
								a_tag: STRING)
			-- updates the sets `additions' and `deletions' accordingly.
		do
			graph_changes.last.updating_A_D (a_target_obj, a_new_source_objs, a_old_source_objs, a_tag)
		end

	registering_changes_param (a_target_obj: ALIAS_VISITABLE; a_new_source_objs, a_old_source_objs: TWO_WAY_LIST [ALIAS_OBJECT];
								a_tag: STRING)
			-- updates the sets `additions' and `deletions' accordingly and sets the edge as parameter
		do
			registering_changes (a_target_obj, a_new_source_objs, a_old_source_objs, a_tag)
		end


feature -- Managing Loops

	is_alias_loop: BOOLEAN
		do
			Result := attached {ALIAS_LOOP} graph_changes.last
		end

	init_loop
			-- Initialiases a loop	
		do
			graph_changes.force (create {ALIAS_LOOP}.make)
		end

	iter
			-- initialises another iteraction in the loop
		require
			is_alias_loop
		do
			graph_changes.last.step
		end

	finalising_loop
			-- adds the deleted nodes to the graph
		require
			is_alias_loop
		do
			if attached {ALIAS_LOOP} graph_changes.last as loop_l  then
				loop_l.set_current_routine (Current)
				loop_l.finalising_loop
			end
				-- transfer addition information (loops do not delete edges)
			transfer_additions
				-- TODO: transfering deletions (can be improved)
			transfer_deletions
			graph_changes.finish
			graph_changes.remove
		end

	fixpoint_reached: INTEGER
			-- `fixpoint_reached' stores the type of reachpoint reached:
			--		0: no fixpoint
			--		1: the body of the loop does not change the graph
			-- 		2: the graph did not change from last iteraction
			-- 		3: fixpoint associated to N

		do
			if attached {ALIAS_LOOP} graph_changes.last as last_loop then
				Result := last_loop.fixpoint_reached
			end
		end

	checking_fixpoint
			-- checks (and updates accordingly) if the loop analysis has reached a checkpoint
		do
			if attached {ALIAS_LOOP} graph_changes.last as last_loop then
				last_loop.checking_fixpoint
			end
		end

feature -- Managing Recursion

	is_alias_recursion: BOOLEAN
		do
			Result :=
				attached {ALIAS_NORMAL_CHANGES} graph_changes.last as last and then attached last.rec as rec and then
					rec.additions.count = 3 and then rec.deletions.count = 3 -- Magic number
					and then last.additions.count = 0 and then last.deletions.count = 0
 		end

	init_rec
			-- Iniitialises the process to track changes in the presence of recursion
		do
			if attached {ALIAS_NORMAL_CHANGES} graph_changes.first as rec then
				rec.init_rec
			end

		end

	transfer_rec_changes (next_routine_changes, to_delete_routine_changes: ALIAS_NORMAL_CHANGES)
			-- transfer the tracked changes for recursion
		do
			if next_routine_changes.rec = Void then
				next_routine_changes.init_rec_empty
			end
			across
				to_delete_routine_changes.rec.additions as additions
			loop
				next_routine_changes.rec.additions.force (additions.item)
			end
			across
				to_delete_routine_changes.rec.deletions as deletions
			loop
				next_routine_changes.rec.deletions.force (deletions.item)
			end
--			next_routine_changes.rec.additions.finish
--			next_routine_changes.rec.additions.merge_right (to_delete_routine_changes.rec.additions)
--			next_routine_changes.rec.deletions.finish
--			next_routine_changes.rec.deletions.merge_right (to_delete_routine_changes.rec.deletions)
		end

	finalising_recursion
			-- adds the deleted nodes to the graph
		require
			is_alias_recursion
		do
			check attached {ALIAS_NORMAL_CHANGES} graph_changes.first as normal then
				normal.rec.set_current_routine (Current)
				normal.rec.finalising_recursion
			end
		end

feature -- Managing Dynamic Binding
	is_dyn_bin: BOOLEAN
		do
			Result := attached {ALIAS_DYN_BIND} graph_changes.last
		end

	init_dyn_bin
			-- Initialiases a dyn bin	
		do
			graph_changes.force (create {ALIAS_DYN_BIND}.make)
		end


	init_feature_version
			-- initialises a branch for a conditional.
		require
			is_dyn_bin
		do
			graph_changes.last.step
		end

	restore_graph_dyn (root_routine: ALIAS_ROUTINE)
			-- restores the alias graph as it was before the current feature version
		do
			if attached {ALIAS_DYN_BIND} graph_changes.last as last_bind then
				--1 last_bind.restoring_state (root_routine, Current)
			end
		end

	finalising_dyn_bind (root_routine: ALIAS_ROUTINE)
			-- finalises the operations of feature versions
		do
--			if attached {ALIAS_DYN_BIND} graph_changes.last as last_din then
--				last_din.finalising_dyn_bind (root_routine, Current)

--					-- transfer Additions and Deletions
--				across
--					last_din.deletions.first as del_to_add
--				loop
--					graph_changes.go_i_th (graph_changes.count-1)
--					if not graph_changes.item.deletions.last.has (del_to_add.key) then
--						graph_changes.item.deletions.last.force (del_to_add.item, del_to_add.key)
--					else
--						graph_changes.item.deletions.last.at (del_to_add.key).obj_target := del_to_add.item.obj_target
--						graph_changes.item.deletions.last.at (del_to_add.key).obj_source.append (del_to_add.item.obj_source)
--					end
--				end

--				transfer_additions
--			end
--			graph_changes.finish
--			graph_changes.remove
		end

feature -- Helper
	graph_changes_count: INTEGER
		do
				-- do no TODO
			Result := graph_changes.count
		end

feature -- Updating

	update_call
			-- updates the name of the caller if the current routine is a function
			-- e.g. in x.feat, where 'x:T do Result := a end', the caller of 'feat' is not Result but 'a': a.feat
		local
			atts_mapped: TWO_WAY_LIST [STRING]
		do
			if not routine.is_attribute then
				if routine.is_function then
					create atts_mapped.make
					across
						locals.at (create {ALIAS_KEY}.make ("Result")) as objs
					loop
						across
							current_object.attributes as attributes
						loop
							if attributes.item.has (objs.item) then
								atts_mapped.force (attributes.key.name)
									-- TODO: move cursor to the end
							end
						end
					end
					if not atts_mapped.is_empty then
						map_funct.force (atts_mapped, create {ALIAS_KEY}.make (routine.e_feature.name_32))
					else -- treat the function (i.e. add it) as a local in stack.at (stack.count - 1)
						locals.force (locals.at (create {ALIAS_KEY}.make ("Result")),
							create {ALIAS_KEY}.make (routine.e_feature.name_32))
						create atts_mapped.make
						atts_mapped.force (routine.e_feature.name_32)
						map_funct.force (atts_mapped, create {ALIAS_KEY}.make (routine.e_feature.name_32))
					end

				end
			end
		end

feature -- Detachable vars
--TODO: there should be an easy way to check whether an attributes is detachable or not

	det_atts: HASH_TABLE [BOOLEAN, STRING]
			-- updates the class detachable attributes of the class
		once
			create Result.make (current_object.type.base_class.skeleton.count)
			across
				routine.access_class.skeleton as att
				--current_object.type.base_class.skeleton as att
			loop
				Result.force (att.item.type_i.has_detachable_mark, att.item.attribute_name)
			end
		end

feature {ANY}

	out: STRING_8
		do
			--Result := current_object.out + "." + routine.feature_name_32
			--Result := tagged_out
			if tagged_out.split ('%N').count > 0 then
				Result := tagged_out.split ('%N').at (1)
			else
				Result := tagged_out
			end
		end

feature -- For Debugging purposes
	out2: STRING
		do
			Result := "r. " + out
		end

	print_last_graph_changes
		do
			graph_changes.last.printing_vars (1)
		end


	print_graph_changes
		do
			across
				graph_changes as gc
			loop
				print ("Type: " + gc.item.out)
				io.new_line
				print ("&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&%N")
				gc.item.printing_vars (1)
				print ("&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&%N")
			end
			print ("$&&&&&&&&&&&&&&&&REC&&&&&&&&&&&&&&&&&&&&%N")
			if attached {ALIAS_NORMAL_CHANGES} graph_changes.first as f then
				if attached f.rec as r then
					r.printing_vars (1)
				else
					print ("Rec No defined%N")
				end

			else
				print ("ERROR%N")
			end
			print ("$&&&&&&&&&&&&&&&&REC&&&&&&&&&&&&&&&&&&&&%N")
		end

	print_atts_depth (c: HASH_TABLE [TWO_WAY_LIST [ALIAS_OBJECT], ALIAS_KEY])
		do
			if tracing then
				print ("Atts Deep%N")
				print_atts_depth_help (c, 1)
				print ("-------------------------------------------------%N")
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
					print (links.key.name)
					if links.key.assigned then
						print ("*")
					end
					print (": [")
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

invariant
	routine /= Void
	current_object /= Void
	--caller_path /= Void
	graph_changes /= Void and graph_changes.count > 0 and then attached {ALIAS_NORMAL_CHANGES} graph_changes.first

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
