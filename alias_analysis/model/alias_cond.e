note
	description: "Managing conditions."
	legal: "See notice at end of class."
	status: "See notice at end of class."
	date: "$Date: (Fri, 07 Oct 2016) $"
	revision: "$Revision: 98127 $"

class
	ALIAS_COND

inherit

	ALIAS_SUB_GRAPH
		rename
			is_in_structure as is_conditional_branch,
			initialising as init_cond,
			step as init_branch,
			finalising as finalising_cond,
			indexes as n_conditional
		end

create {ALIAS_GRAPH}
	make

feature -- Managing Conditionals Branches

	restoring_state (root, current_routine: ALIAS_ROUTINE)
			-- restores the alias graph as it was before the current conditional branch.
			-- `root' of the graph
			-- `current_routine' routine being analysed
		require
			is_conditional_branch
		do
			if tracing then
				printing_vars (1)
			end
				-- deleting added objects
			from
				additions.go_i_th (n_conditional.last.index_add)
			until
				additions.after
			loop
				across
					additions.item as values
				loop
					if tracing then
						printing_vars (1)
					end
					restore_added (root.current_object, current_routine, values.key.name, values.item.path, 1, values.item.obj)
						--restore_added (objs, values.key, values.item.path, 1, values.item.obj)
				end
				additions.forth
			end

			if tracing then
				printing_vars (1)
			end

				-- adding deleted objects
			from
				deletions.go_i_th (n_conditional.last.index_del)
			until
				deletions.after
			loop
				across
					deletions.item as values
				loop
					restore_deleted (root.current_object, current_routine, values.key.name, values.item.path, 1, values.item.obj)
				end
				deletions.forth
			end
		end

	restore_added (current_object: ALIAS_OBJECT; current_routine: ALIAS_ROUTINE; name_entity: STRING; path: TWO_WAY_LIST [TWO_WAY_LIST [STRING]]; index: INTEGER; new_object: TWO_WAY_LIST [ALIAS_OBJECT])
			-- deletes in `current_object'.`path' the added object: `new_object'
			-- This command is used to restore the state of the graph on exit of conditional branch
		local
			c_objs: TWO_WAY_LIST [ALIAS_OBJECT]
		do
			if tracing then
				print (name_entity)
				io.new_line
				across
					current_object.attributes.current_keys as kk
				loop
					print ("        ")
					print (kk.item)
					io.new_line
				end
			end
			if index > path.count then
				if tracing then
					across
						current_object.attributes as aa
					loop
						print (aa.key)
						print (": ")
						across
							aa.item as bb
						loop
							print (bb.item.out2)
							print (", ")
						end
						io.new_line
						io.new_line
					end
				end
				create c_objs.make
				if tracing then
					print (name_entity)
					io.new_line
				end
				if current_object.attributes.has (create {ALIAS_KEY}.make (name_entity)) then
					c_objs := current_object.attributes.at (create {ALIAS_KEY}.make (name_entity))
				elseif name_entity.ends_with ("_Result") then
					c_objs := current_routine.locals.at (create {ALIAS_KEY}.make ("Result"))
				elseif current_routine.locals.has (create {ALIAS_KEY}.make (name_entity)) then
					c_objs := current_routine.locals.at (create {ALIAS_KEY}.make (name_entity))
				end
				across
					new_object as n_o
				loop
					if tracing then
						print (name_entity)
						io.new_line
						across
							current_object.attributes.current_keys as kk
						loop
							print ("        ")
							print (kk.item)
							io.new_line
						end
					end
					if c_objs.has (n_o.item) then
						if tracing then
							io.new_line
							print (n_o.item)
							io.new_line
							print (c_objs.has (n_o.item))

						end
						c_objs.search (n_o.item)
						c_objs.remove
					end
					if tracing then
						print (name_entity)
						io.new_line
						across
							current_object.attributes.current_keys as kk
						loop
							print ("        ")
							print (kk.item)
							io.new_line
						end
					end
				end

					-- TODO: NO -> it should gives a new val to it
					--				if current_object.attributes.has (name_entity) and current_object.attributes.at (name_entity).count = 0 then
					--					current_object.attributes.remove (name_entity)
					--				elseif current_routine.locals.has (name_entity) and current_routine.locals.at (name_entity).count = 0 then
					--					current_routine.locals.remove (name_entity)
					--				end
			else
				across
					path.at (index) as paths
				loop
					if current_object.attributes.has (create {ALIAS_KEY}.make (paths.item)) then
						c_objs := current_object.attributes.at (create {ALIAS_KEY}.make (paths.item))
					elseif current_routine.locals.has_key (create {ALIAS_KEY}.make (paths.item)) then
						c_objs := current_routine.locals [create {ALIAS_KEY}.make (paths.item)]
					end
					across
						c_objs as objs
					loop
						restore_added (objs.item, current_routine, name_entity, path, index + 1, new_object)
					end
				end
			end
		end

	finalising_cond (root, current_routine: ALIAS_ROUTINE)
			-- it consists of two actions:
			--	i) inserts the union of elements in `additions'
			--	ii) deletes the intersection of elements in `deletions'
			-- the complement of (ii) is stored in `no_added_back' it is needed in case of recursion
			--to `current_alias_routine'
		do
			if tracing then
				printing_vars (1)
			end
			n_conditional.finish

				-- Deleting the intersection of `deletions'
			intersection_deletions_entities
			inter_deletion := deletions.at (n_conditional.last.index_del)
			if tracing then
				printing_vars (1)
			end
				-- deleting added objects
			across
				deletions.at (n_conditional.last.index_del) as values
			loop
				restore_added (root.current_object, current_routine, values.key.name, values.item.path, 1, values.item.obj)
			end
				-- delete the info in deletions and in n_conditional
			from
				deletions.go_i_th (n_conditional.last.index_del)
			until
				deletions.after
			loop
				deletions.remove
			end
			if tracing then
				printing_vars (1)
			end

				-- Inserting the union of `additions'
			from
				additions.go_i_th (n_conditional.item.index_add)
			until
				additions.after
			loop
				across
					additions.item as values
				loop
					restore_deleted (root.current_object, current_routine, values.key.name, values.item.path, 1, values.item.obj)
				end
				additions.forth
			end

				-- delete the info in deletions and in n_conditional
			from
				additions.go_i_th (n_conditional.last.index_add)
			until
				additions.after
			loop
				additions.remove
			end
			n_conditional.remove
			if tracing then
				printing_vars (1)
			end
		end

	intersection_deletions_entities
			-- leaves the intersection in `deletions' (the ones to be deleted from the graph)
			-- it will leave the intersection in n_condition.last.index_del
		local
			i: INTEGER
			keys: ARRAY [ALIAS_KEY]
			stop: BOOLEAN
		do
			keys := deletions.at (n_conditional.last.index_del).current_keys
			across
				keys as k
			loop
				from
					i := n_conditional.last.index_del + 1
					stop := False
				until
					i > deletions.count or stop
				loop
					if deletions.at (i).has (k.item) and deletions.at (n_conditional.last.index_del).at (k.item).abs_name ~ deletions.at (i).at (k.item).abs_name then
						i := i + 1
					else
						stop := True
					end
				end
				if stop then
					deletions.at (n_conditional.last.index_del).remove (k.item)
				end
			end
		end

	forget_att (target_name, source_name: STRING; target_object, source_object: TWO_WAY_LIST [ALIAS_OBJECT]; target_type: BOOLEAN)
			-- used whenever a class attribute is created. It forgets (deletes) the `target_name'
			-- from the additions edges on the graph.
			-- It also updates the set `deletions' accordingly:
			--  deletions -> [`target_name': (`target_name', `target_object', `target_type')]
		require
			is_conditional_branch
		do
				-- Jan 18: TODO
				--			if additions.last.has (target_name) then
				--				printing_add
				--				printing_del

				--				additions.last.remove (target_name)

				--				printing_add
				--				printing_del
				--			end

				--			updating_A_D (target_name, source_name, source_object, target_object, target_type)

				--			printing_add
				--			printing_del

				----			create tup
				----			tup.name := target_name
				----			tup.type := target_type
				----			create obj.make
				----			if attached target_object as target then
				----				across
				----					target as t
				----				loop
				----					obj.force (t.item)
				----				end
				----			end
				----			tup.obj := obj
				----			deletions.last.force (tup, target_name)
		end

	is_conditional_branch: BOOLEAN
		do
			Result := not n_conditional.is_empty
		end

feature -- Information to Recursion

	inter_deletion: HASH_TABLE [TUPLE [name, abs_name: STRING; obj: TWO_WAY_LIST [ALIAS_OBJECT]; path: TWO_WAY_LIST [TWO_WAY_LIST [STRING]]], ALIAS_KEY]
			--after the execution of a conditional, `inter_deletion' will store the entities of those deleted links that
			-- need to be put back on, e.g. if C then a := b else a:= c end: entity 'a' will be in the deletion list
			-- regardless which branch the execution does, 'a' will be pointing to something new

		--	retrieve_no_added_back: TWO_WAY_LIST [STRING]
		--			-- retrieves the atts that will not be added back after finalising the conditional analysis
		--		do
		--			no_added_back.finish
		--			Result := no_added_back.item
		--		end

		--	delete_no_add_back
		--			-- deletes the last entry on no_added_back
		--		do
		--			no_added_back.remove
		--		end
	;

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
