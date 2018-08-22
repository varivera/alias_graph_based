note
	description: "[
		Implementation of a rooted-directed graph. Its nodes correspond to 
		Object executions and edges to object variables.
	]"
	date: "August, 2018"
	author: "Victor Rivera"


class
	ALIAS_GRAPH

inherit

	TRACING

create
	make--, update_class_atts

feature {NONE} -- Initialisation

	make (a_routine: PROCEDURE_I)
			-- Initialises an ALIAS_GRAPH with `a_routine' as root. it will contain (initially) all references to class fields.
		require
			a_routine /= Void
		do
			create alias_dyn.make
			create stack.make
			stack_push (create {ALIAS_OBJECT}.make (a_routine.written_class.actual_type), a_routine, False)
		ensure
			stack /= Void
			stack.count = 1
		end

feature -- Implementtion

	current_routine, stack_top: ALIAS_ROUTINE
			-- Returns the current object's context
		do
			Result := stack.last
		end

	previous_routine: ALIAS_ROUTINE
			-- Returns the current object's context
		do
			if stack.count > 1 then
				Result := stack.at (stack.count-1)
			end

		end

	root_routine: ALIAS_ROUTINE
			-- Returns the current object's context
		do
			Result := stack.first
		end

	stack_push (a_current_object: ALIAS_OBJECT; a_routine: PROCEDURE_I; qualified_call: BOOLEAN)
			-- adds a context `a_routine' to the ALIAS_GRAPH having a ref to `a_current_object'
			--  routine `a_routine' was called in `qualified_call'
		do
			-- TODO: this is the case where the routine was already created
			stack.extend (create {ALIAS_ROUTINE}.make (
						a_current_object, a_routine,
						-- TODO: why we need this?: locals_alias_object (a_routine),
						create {HASH_TABLE [TWO_WAY_LIST [ALIAS_OBJECT], ALIAS_KEY]}.make (16)))

--			stack.extend (create {ALIAS_ROUTINE}.make (
--						a_current_object, a_routine, create {HASH_TABLE [TWO_WAY_LIST [ALIAS_OBJECT], ALIAS_KEY]}.make (16),
--						l_ent, l_local_ent))

				-- to retrieve the class in which a_routine is
--			if qualified_call or stack.count = 1 then
--				update_class_atts_routine (a_routine)
--			end

			update_feat_signature (a_routine)
		end

	update_feat_signature (a_routine: PROCEDURE_I)
			-- updates, in the graph, the `a_routine's signature
			-- it adds a Void reference to those detachable references.
		local
			l_obj: TWO_WAY_LIST [ALIAS_OBJECT]
			ob: ALIAS_OBJECT
			k: ALIAS_KEY
			i: INTEGER
		do
				-- Arguments
			if attached a_routine.e_feature.arguments as args and then attached a_routine.e_feature.argument_names as args_names then
				from
					i := 1
				until
					i > args.count
				loop
					if attached args.at (i) as type then
						create l_obj.make
						create ob.make (type)
						create k.make (args_names.at (i))
						ob.predecessors.force (create {TWO_WAY_LIST [ALIAS_VISITABLE]}.make, k)
						--ob.predecessors.at (k).force (stack_top.current_object)
						ob.predecessors.at (k).force (stack_top)
						l_obj.force (ob)
						stack_top.locals.force (l_obj, k)
					end
					i := i + 1
				end
			end

				-- Return value
			if a_routine.e_feature.has_return_value then
				if attached a_routine.e_feature.type as type then
					create l_obj.make
					create k.make ("Result")
					create ob.make (type)
					ob.predecessors.force (create {TWO_WAY_LIST [ALIAS_VISITABLE]}.make, k)
					--ob.predecessors.at (k).force (stack_top.current_object)
					ob.predecessors.at (k).force (stack_top)
					l_obj.force (ob)
						stack_top.locals.force (l_obj, k)
				else
						-- TODO
				end
			end
		end

	stack_pop
			-- removes the last context
		do
				-- if it is not the last routine in the STACK, transfer additions and deletions
			if stack.count > 1 then
				stack.last.finalising_transfer (stack.at (stack.count - 1))
			end
			stack.finish
			stack.remove
		end

	stack_pop_noaction
			-- removes the last context
		do
			stack.finish
			stack.remove
		end

	finalising_initial_routine
			-- it finalises the initial routine
		require
			is_last_routine
		do
			stack.last.finalising_routine
		end

	to_string: STRING_8
			-- Returns the string representation of the Alias Graph
		local
			l_cycles: STRING_8
		do
			create l_cycles.make_empty
			create Result.make_empty
			compute_aliasing_info (stack.last, create {TWO_WAY_LIST [TUPLE [ALIAS_VISITABLE, STRING]]}.make, l_cycles)
			collect_aliasing_info (stack.last, Result)
			reset_visiting (stack.last)
			if not l_cycles.is_empty then
				Result.append ("%N%N-- Cycles:%N")
				Result.append (l_cycles)
			end
		end


	to_graph: STRING_8
			-- Returns the graph representation of the Alias Graph (constructs a digraph to be drawn by other tools)
		local
			cur_change: CELL [BOOLEAN]
		do
			create cur_change.put (False)
			change_graph (stack.last, create {TWO_WAY_LIST [ALIAS_KEY]}.make, cur_change)

			create Result.make_empty
			Result.append ("digraph g {%N")
			Result.append ("%Tnode [shape=box]%N")
			print_nodes (stack.last, 0, create {CELL [NATURAL_32]}.put (0), Result)
			print_edges (stack.last, Result, cur_change)
			Result.append ("}%N")
		end

	change_atts: TWO_WAY_LIST [STRING_8]
			-- Returns the set of attributes being changed (ignoring remote attributes)
		local
			cur_change: CELL [BOOLEAN]
		do
			create cur_change.put (False)
			change_graph (stack.last, create {TWO_WAY_LIST [ALIAS_KEY]}.make, cur_change)
			create Result.make

			across
				stack.last.current_object.attributes as atts
			loop
				if atts.key.assigned and across Result as e all e.item /~ atts.key.name end then
					Result.force (atts.key.name)
				end
			end

		end


feature -- Updating

	restore_graph
			-- restores the alias graph as it was before the current conditional branch
		do
			stack_top.restore_graph
		end

	is_nested_call: BOOLEAN
			-- is nested call?
		do
			Result := stack.count > 1
		end

feature {NONE} -- Computing

	compute_aliasing_info (a_cur_node: ALIAS_VISITABLE; a_cur_path: TWO_WAY_LIST [TUPLE [av: ALIAS_VISITABLE; name: STRING]]; a_info: STRING_8)
			-- It reads the information in the Alias Graph and bulids the Alias info
		require
			a_cur_node /= Void
			a_cur_path /= Void
			a_info /= Void
		local
			l_cycle_head: like a_cur_path
		do
			a_cur_node.add_visiting_data (path_to_string (a_cur_path))
			if not a_cur_node.visited then
				a_cur_node.visited := True
				if attached {ALIAS_ROUTINE} a_cur_node as l_ar then
					compute_aliasing_info (l_ar.current_object, a_cur_path, a_info)
				end
				across
					a_cur_node.variables as c
				loop
					a_cur_path.extend ([a_cur_node, c.key.name])
					across
						c.item as vars
					loop
						compute_aliasing_info (vars.item, a_cur_path, a_info)
					end
					a_cur_path.finish
					a_cur_path.remove
				end
				a_cur_node.visited := False
			else
				if not a_info.is_empty then
					a_info.append ("%N")
				end
				a_info.append (path_to_string (a_cur_path))
				a_info.append (" -> ")
				create l_cycle_head.make
				across
					a_cur_path as c
				until
					l_cycle_head = Void
				loop
					if c.item.av = a_cur_node then
						a_info.append (path_to_string (l_cycle_head))
						l_cycle_head := Void
					else
						l_cycle_head.extend (c.item)
					end
				end
			end
		end

	path_to_string (a_path: TWO_WAY_LIST [TUPLE [av: ALIAS_VISITABLE; name: STRING]]): STRING_8
			-- converts the path of the attribute to string, e.g. a: [b] -> {Type(a)}.a.{Type(b)}.b
		require
			a_path /= Void
		do
			if a_path.is_empty then
				Result := "Current"
			else
				Result := ""
				across
					a_path as c
				loop
					if c.target_index > 1 then
						Result.append (".")
					end
					Result.append (c.item.av.out)
					Result.append (".")
					Result.append (c.item.name)
				end
			end
		end

	collect_aliasing_info (a_cur_node: ALIAS_VISITABLE; a_info: STRING_8)
			-- collects the aliasing information
		require
			a_cur_node /= Void
			a_info /= Void
		do
			if not a_cur_node.visited then
				a_cur_node.visited := True
				if a_cur_node.visiting_data.count >= 2 then
					if not a_info.is_empty then
						a_info.append ("%N")
					end
					across
						a_cur_node.visiting_data as c
					loop
						if c.target_index > 1 then
							a_info.append (", ")
						end
						a_info.append (c.item)
					end
				end
				if attached {ALIAS_ROUTINE} a_cur_node as l_ar then
					collect_aliasing_info (l_ar.current_object, a_info)
				end
				across
					a_cur_node.variables as c
				loop
					across
						c.item as vars
					loop
						collect_aliasing_info (vars.item, a_info)
					end
				end
			end
		end

	reset_visiting (a_cur_node: ALIAS_VISITABLE)
			-- resets all visiting vars
		require
			a_cur_node /= Void
		do
			if a_cur_node.visited then
				a_cur_node.visited := False
				a_cur_node.clear_visiting_data
				if attached {ALIAS_ROUTINE} a_cur_node as l_ar then
					reset_visiting (l_ar.current_object)
				end
				across
					a_cur_node.variables as c
				loop
					across
						c.item as vars
					loop
						reset_visiting (vars.item)
					end
				end
			end
		end

	info_node (a_cur_node: ALIAS_VISITABLE): STRING
		do
			if true then -- For debugging purposes
				Result := a_cur_node.out2.twin
				Result.replace_substring_all ("ALIAS_OBJECT [0x", "")
				Result.replace_substring_all ("]", "")
			else
				Result := a_cur_node.out
			end
		end


	print_nodes (a_cur_node: ALIAS_VISITABLE;
				root_n: INTEGER;
				a_id: CELL [NATURAL_32]; a_output: STRING_8)
		require
			a_cur_node /= Void
			a_id /= Void
			a_output /= Void
--			(
--				root_n = 0 -- init one
--			or
--				root_n = 1 -- root + locals
--			or
--				root_n = 2 -- normal
--			)
		do
			if not a_cur_node.visited then
				a_cur_node.visited := True
				a_id.put (a_id.item + 1)
				a_cur_node.add_visiting_data ("b" + a_id.item.out)
				if root_n = 0 then
					a_output.append ("%T" + a_cur_node.visiting_data.last + "[color=purple label=<" + info_node (a_cur_node) + ">]%N")
				elseif root_n = 1 then
					a_output.append ("%T" + a_cur_node.visiting_data.last + "[color=blue label=<" + info_node (a_cur_node) + ">]%N")
				elseif root_n = 2 then
					a_output.append ("%T" + a_cur_node.visiting_data.last + "[label=<" + info_node (a_cur_node) + ">]%N")
				end
				if attached {ALIAS_ROUTINE} a_cur_node as l_ar then
					--print ("%N"+a_cur_node.out+"%N")
					print_nodes (l_ar.current_object, 1, a_id, a_output)
				end
				across
					a_cur_node.variables as c
				loop
					across
						c.item as vars
					loop
						if attached {ALIAS_ROUTINE} a_cur_node as l_ar then
							print_nodes (vars.item, 1, a_id, a_output)
						else
							print_nodes (vars.item, 2, a_id, a_output)
						end
						--print_nodes (vars.item, 2, a_id, a_output)
					end
				end
			end
		end

	print_edges (a_cur_node: ALIAS_VISITABLE; a_output: STRING_8; cur_change: CELL [BOOLEAN])
		require
			a_cur_node /= Void
			a_output /= Void
		do
			if a_cur_node.visited then
				a_cur_node.visited := False
				if attached {ALIAS_ROUTINE} a_cur_node as l_ar then
					a_output.append ("%T" + a_cur_node.visiting_data.last + "->" + l_ar.current_object.visiting_data.last + "["+
					if cur_change.item then
							"color=red "
						else
							""
						end
					+"label=<Current>]%N")
					print_edges (l_ar.current_object, a_output, cur_change)
				end
				across
					a_cur_node.variables as c
				loop
					across
						c.item as vars
					loop
						a_output.append ("%T" + a_cur_node.visiting_data.last + "->" + vars.item.visiting_data.last + "["+
						if c.key.assigned then
							"color=red "
						else
							""
						end
						+"label=<" + c.key.name + ">]%N")
						print_edges (vars.item, a_output, cur_change)
					end
				end
			end
		end

	change_graph (a_cur_node: ALIAS_VISITABLE; path: TWO_WAY_LIST [ALIAS_KEY]; cur_change: CELL [BOOLEAN])
			-- complete the graph with 'changed' information: updates the graph so entities
			-- 		marked nodes are reachable from 'root'
		require
			a_cur_node /= Void
			path /= Void
		local
			tmp: TWO_WAY_LIST [ALIAS_KEY]
		do
			if not a_cur_node.visited then
				a_cur_node.visited := True
				if attached {ALIAS_ROUTINE} a_cur_node as l_ar then
					change_graph (l_ar.current_object, path, cur_change)
				end
				across
					a_cur_node.variables as c
				loop
					across
						c.item as vars
					loop
						create tmp.make
						across
							path as p
						loop
							tmp.force (p.item)
						end
						if c.key.assigned then
							if not cur_change.item then
								cur_change.put (True)
							end
							across
								tmp as p
							loop
								p.item.set_assigned
							end
						else
							tmp.force (c.key)
							change_graph (vars.item, tmp,cur_change)

						end
					end
				end
				a_cur_node.visited := False
			end
		end

feature -- Managing Recursion

	is_last_routine: BOOLEAN
		do
			Result := stack.count = 1
		end

	check_recursive_fix_point (routine_name: STRING; a_target: ALIAS_OBJECT)
			-- checks whether a fix point was reached in a recursive call. It sets variable
			--	`is_recursive_fix_point' to True in case of fix point reached
			-- It also creates ALIAS_REC in graph_changes of the routine involves.
		local
			i: INTEGER
			times: INTEGER
			routine_involved: ARRAYED_LIST [ALIAS_ROUTINE]
			routine_involved2: ARRAYED_LIST [ALIAS_ROUTINE] -- Routine by other means
		do
			from
				create routine_involved.make (fix_point)
				create routine_involved2.make (fix_point)
				i := stack.count -- starting from the last one: the current routine has not been added
			until
				i < 1 or times = fix_point
			loop
				if stack.at (i).routine.feature_name_32 ~ routine_name then
					times := times + 1
					if a_target ~ stack.at (i).current_object then
						routine_involved.force (stack.at (i))
					else
						if across routine_involved2 as m all
							m.item.current_object /= a_target end
						then
							routine_involved2.force (stack.at (i))
						end
					end
				end
				i := i - 1
			end

			is_recursive_fix_point := times = fix_point
			if is_recursive_fix_point then
					-- add ALIAS_REC to all routines involved
				across
					if routine_involved.count = times then
						routine_involved else
						routine_involved2 end as r
				loop
					r.item.init_rec
				end
			end
		end

	is_recursive_fix_point: BOOLEAN
			-- is the analysis in a recursion and it already reached a fix point?

	fix_point: INTEGER = 3
			-- `n_fixpoint' is a fix number: upper bound for rec
			-- TODO: make use of the new feature of Eiffel: static calls: Loops and Recursion should have the same fix point

	finalising_recursion
			-- finalises the operations of recursion in case of fix pont
		require
			is_recursive_fix_point;
		do
				-- retrieve additions and deletions
				-- TODO: should I delete them as well? (additions and deletions of previous calls)

			--1: stack_top.alias_pos_rec.set_g (Current)
			--1: stack_top.alias_pos_rec.finalising_recursive_call (stack.first, stack_top, pre_add, pre_del)

		end


	locals_alias_object (a_routine: PROCEDURE_I): HASH_TABLE [TWO_WAY_LIST [ALIAS_OBJECT], ALIAS_KEY]
			-- returns alias object of local in routine `a_routine' if the routine was
			-- already visited. Void otherwise
		do
			create Result.make (16)
			if stack.count >= 1 then
				from
					stack.finish
				until
					stack.before or
					a_routine = stack.last.routine
				loop
					stack.back
				end
				if not stack.before then
					across
						stack.item.locals as l
					loop
						Result.force (l.item, l.key)
					end

--					Result := stack.item.locals
				end
			end
		end

feature -- Managing possible Dyn Bind

	init_feature_version
			-- initialises a branch for a conditional.
		do
			alias_dyn.init_feat_version
		end

feature {NONE} -- Access

	stack: TWO_WAY_LIST [ALIAS_ROUTINE]
			-- `stack' implements the ALIAS_GRAPH

	alias_dyn: ALIAS_DYN_BIND
			-- manages possible dynamic binding calls

feature -- Constants (static access)
	static_access: ALIAS_ROUTINE
		once
			create Result.make (stack.first.current_object,
							stack.first.routine, create {HASH_TABLE [TWO_WAY_LIST [ALIAS_OBJECT], ALIAS_KEY]}.make (16))
		end

	add_class_constant (c: STRING; class_id: INTEGER)
			-- adds class of name `c' (i.e. creates an ALIAS_OBJECT) to the map
			-- and adds the corresponding constants
		require
			not static_access.locals.has (create {ALIAS_KEY}.make (c))
		local
			obj: ALIAS_OBJECT
			l_obj: TWO_WAY_LIST [ALIAS_OBJECT]
			key: ALIAS_KEY
		do
			create key.make (c)
			create obj.make (create {CL_TYPE_A}.make (class_id))
			obj.add_predecessor (static_access, c)
			static_access.locals.force (create {TWO_WAY_LIST [ALIAS_OBJECT]}.make, key)
			static_access.locals.at (key).force (obj)
				-- add constants to obj	
			across
				obj.type.base_class.constant_features as const
			loop
				if not obj.attributes.has (create {ALIAS_KEY}.make (const.item.name_32)) then
						-- to retrieve their types and to add them to obj
					create l_obj.make
					l_obj.force (create {ALIAS_OBJECT}.make (const.item.type))
					l_obj.last.add_predecessor (obj, const.item.name_32)
					obj.attributes.force (l_obj, create {ALIAS_KEY}.make (const.item.name_32))
				end
			end
		ensure
			across static_access.locals as s_a all s_a.item.count = 1 end
		end

feature  -- For debugging purposes

	print_stack
		do
			from
				stack.finish
			until
				stack.before
			loop
				print ("> " + stack.item.routine.e_feature.name_32)
				io.new_line
				stack.back
			end
			print ("----------")
			io.new_line
		end

	print_stack_with_alias_changes
		do
			from
				stack.finish
			until
				stack.before
			loop
				print (">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>%N " + stack.item.routine.e_feature.name_32)
				io.new_line
				stack.item.print_graph_changes
				io.new_line
				stack.back
			end
			print ("----------")
			io.new_line
		end

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

	printing_atts
		do
			if tracing then
				print ("%N%NAtts%N%N")
				across
					stack_top.current_object.attributes as a
				loop
					print (a.key)
					print (": [")
					across
						a.item as v
					loop
						print (v.item.out2)
						if v.cursor_index /= a.item.count then
							print (", ")
						end
					end
					print ("]%N%N")
				end
			end
		end

	print_vals
		do
			if tracing then
				print ("%N============VALS==========%N")
				across
					stack as e
				loop
					print_alias_visitable (e.item, 1)
				end
				print ("%N============VALS END==========%N")
			end
		end

	print_alias_visitable (t: ALIAS_VISITABLE; i: INTEGER)
		local
			tab: STRING
		do
			if tracing then
				create tab.make_filled (' ', i)
				print (tab + "Variables:%N")
				if t.variables.is_empty then
					print ("  " + tab + "NONE%N")
				else
					across
						t.variables as var
					loop
						print ("  " + tab + var.key.name + "%N")
						across
							var.item as att
						loop
							print_alias_visitable (att.item, i * 3)
						end
					end
				end
				print (tab + "Visited: " + t.visited.out + "%N")
				print (tab + "visiting_data:%N")
				if t.visiting_data = Void or else t.visiting_data.is_empty then
					print ("  " + tab + "NONE%N")
				else
					across
						t.visiting_data as e
					loop
						print ("  " + tab + e.item + "%N")
					end
				end
				if attached {ALIAS_ROUTINE} t as ar then
					print (tab + "Routine: " + ar.routine.feature_name_32 + "%N")
					print (tab + "current_object:%N")
					print_alias_visitable (ar.current_object, i * 3)
				elseif attached {ALIAS_OBJECT} t as ao then
					print (tab + "type: " + ao.out + "%N")
				end
			end
		end

	all_true (a_cur_node: ALIAS_VISITABLE)
		do
			print (a_cur_node.visited)
			io.new_line
			if attached {ALIAS_ROUTINE} a_cur_node as l_ar then
				all_true (l_ar.current_object)
			end
			across
				a_cur_node.variables as c
			loop
				across
					c.item as vars
				loop
					all_true (vars.item)
				end
			end
		end

	not_visited (n: ALIAS_OBJECT)
		do
			if not n.visited then
				across
					n.attributes as att
				loop
					across
						att.item as o
					loop
						not_visited (o.item)
					end
				end
			end
			n.visited := False
		end

	check_consistency (n: ALIAS_OBJECT): BOOLEAN
		do
			if not n.visited then
				n.visited := True
				across
					n.attributes as att
				loop
					print ("> ")
					print (n.out2)
					print ("< compared in: " + att.key.name)
					io.new_line
					across
						att.item as o
					loop
						across
							o.item.predecessors.at (att.key) as p
						loop
							print (p.item.out2)
							io.new_line
						end

						Result :=
						across o.item.predecessors.at (att.key) as p some p.item ~ n end
						and then check_consistency (o.item)
					end
				end
			end
		end

	checking_consistency: BOOLEAN
		do
			not_visited (stack.first.current_object)
			Result := check_consistency (stack.first.current_object)
			not_visited (stack.first.current_object)
		end
invariant
	stack /= Void
	alias_dyn /= Void
	not stack.is_empty
	across stack as c all c.item /= Void end
	checking_consistency: checking_consistency

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
