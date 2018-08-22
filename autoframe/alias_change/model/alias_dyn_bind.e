note
	description: "Managing dynamic binding."
	date: "August, 2018"
	author: "Victor Rivera"

class
	ALIAS_DYN_BIND

inherit

	ALIAS_CHANGES
		rename
			step as init_feat_version,
			finalising as finalising_dyn_bind
		end

create {ALIAS_ROUTINE, ALIAS_GRAPH} --TODO: To take out ALIAS_GRAPH
	make

feature -- Managing Feature Versions

	restoring_state
			-- restores the alias graph as it was before the current version feature.
			-- `root' of the graph
			-- `current_routine' routine being analysed
		do
			--TODO
--			if tracing then
--				printing_vars (1)
--			end
--				-- deleting added objects
--			from
--				additions.start
--			until
--				additions.after
--			loop
--				across
--					additions.item as values
--				loop
--					if tracing then
--						printing_vars (1)
--					end
--					restore_added (root.current_object, current_routine, values.key.name, current_routine.routine.e_feature.name_32+"_",  values.item.path, 1, values.item.obj)
--						--restore_added (objs, values.key, values.item.path, 1, values.item.obj)
--					if tracing then
--						print_atts_depth (root.current_object.attributes)
--					end
--				end
--				additions.forth
--			end

--			if tracing then
--				printing_vars (1)
--			end

--				-- adding deleted objects
--			from
--				deletions.start
--			until
--				deletions.after
--			loop
--				across
--					deletions.item as values
--				loop
--					restore_deleted (
--						root.current_object,
--						current_routine,
--						values.key.name,
--						current_routine.routine.e_feature.name_32,
--						values.item.path,
--						values.item.path_locals,
--						1, values.item.obj)
--				end
--				deletions.forth
--			end
		end

	restore_added (current_object: ALIAS_OBJECT; current_routine: ALIAS_ROUTINE; name_entity, feat_name: STRING; path: TWO_WAY_LIST [TWO_WAY_LIST [STRING]]; index: INTEGER; new_object: TWO_WAY_LIST [ALIAS_OBJECT])
			-- deletes in `current_object'.`path' the added object: `new_object'
			-- This command is used to restore the state of the graph on exit of conditional branch
		local
			c_objs: TWO_WAY_LIST [ALIAS_OBJECT]
			real_name: STRING
		do
			create real_name.make_from_string (name_entity)
			real_name.replace_substring_all (feat_name, "")
			if index > path.count then

				create c_objs.make
				if current_object.attributes.has (create {ALIAS_KEY}.make (name_entity)) then
					c_objs := current_object.attributes.at (create {ALIAS_KEY}.make (name_entity))
				elseif name_entity.ends_with ("_Result") then
					c_objs := current_routine.locals.at (create {ALIAS_KEY}.make ("Result"))
				elseif current_routine.locals.has (create {ALIAS_KEY}.make (real_name)) then
					c_objs := current_routine.locals.at (create {ALIAS_KEY}.make (real_name))
				end
				across
					new_object as n_o
				loop
					if c_objs.has (n_o.item) then
						c_objs.start
						c_objs.search (n_o.item)
						c_objs.remove
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
						restore_added (objs.item, current_routine, name_entity, feat_name, path, index + 1, new_object)
					end
				end
			end
		end

	finalising_dyn_bind --(root, current_routine: ALIAS_ROUTINE)
			-- it consists of two actions:
			--	i) inserts the union of elements in `additions'
			--	ii) deletes the intersection of elements in `deletions'
		do
--			if tracing then
--				printing_vars (1)
--			end

--				-- Deleting the intersection of `deletions'
--			intersection_deletions_entities

--			if tracing then
--				printing_vars (1)
--			end
--				-- deleting added objects
--			across
--				deletions.first as values
--			loop
--				restore_added (root.current_object, current_routine, values.key.name, current_routine.routine.e_feature.name_32+"_",  values.item.path, 1, values.item.obj)
--			end
--				-- delete the info in deletions and in n_dyb_bind

--			if tracing then
--				printing_vars (1)
--			end

--				-- Inserting the union of `additions'
--			from
--				additions.start
--			until
--				additions.after
--			loop
--				across
--					additions.item as values
--				loop
--					restore_deleted (
--						root.current_object,
--						current_routine,
--						values.key.name,
--						current_routine.routine.e_feature.name_32,
--						values.item.path,
--						values.item.path_locals,
--						1, values.item.obj)
--				end
--				additions.forth
--			end
--			if tracing then
--				printing_vars (1)
--			end
		end

	intersection_deletions_entities
			-- leaves the intersection in `deletions' (the ones to be deleted from the graph)
			-- it will leave the intersection in n_condition.last.index_del
		local
--			i: INTEGER
--			keys: ARRAY [ALIAS_KEY]
--			stop: BOOLEAN
		do
--			keys := deletions.first.current_keys
--			across
--				keys as k
--			loop
--				from
--					i := 2 -- starting from the second element, if any
--					stop := False
--				until
--					i > deletions.count or stop
--				loop
--					if deletions.at (i).has (k.item) and deletions.at (1).at (k.item).abs_name ~ deletions.at (i).at (k.item).abs_name then
--						i := i + 1
--					else
--						stop := True
--					end
--				end
--				if stop then
--					deletions.at (0).remove (k.item)
--				end
--			end
		end

	forget_att (target_name, source_name: STRING; target_object, source_object: TWO_WAY_LIST [ALIAS_OBJECT]; target_type: BOOLEAN)
			-- used whenever a class attribute is created. It forgets (deletes) the `target_name'
			-- from the additions edges on the graph.
			-- It also updates the set `deletions' accordingly:
			--  deletions -> [`target_name': (`target_name', `target_object', `target_type')]
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
