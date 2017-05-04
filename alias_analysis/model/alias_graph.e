class
	ALIAS_GRAPH

inherit

	TRACING

create
	make

feature {NONE}

	make (a_routine: PROCEDURE_I)
			-- Initialises an ALIAS_GRAPH with `a_routine' as root. it will contain (initially) all references to class fields.
		require
			a_routine /= Void
		do
			create alias_cond.make
			create alias_loop.make
			create alias_dyn.make
			create stack.make
			stack_push (create {ALIAS_OBJECT}.make (a_routine.written_class.actual_type), a_routine,
						Void, Void, False)
			if tracing then
				print_atts_depth (stack_top.current_object.attributes)
				print_atts_depth (stack_top.locals)
			end
		ensure
			stack /= Void
			stack.count = 1
		end

feature

	stack_top: ALIAS_ROUTINE
			-- Returns the current object's context
		do
			Result := stack.last
		end

	stack_push (a_current_object: ALIAS_OBJECT; a_routine: PROCEDURE_I;
				ent: TWO_WAY_LIST [TWO_WAY_LIST [STRING]];
				ent_local: TWO_WAY_LIST [HASH_TABLE [TWO_WAY_LIST [ALIAS_OBJECT], ALIAS_KEY]]; qualified_call: BOOLEAN)
			-- adds a context `a_routine' to the ALIAS_GRAPH having a ref to `a_current_object'
			--  routine `a_routine' was called from entity `ent' in `qualified_call'
		local
			l_ent: TWO_WAY_LIST [TWO_WAY_LIST [STRING]]
			l_local_ent: TWO_WAY_LIST [TWO_WAY_LIST [HASH_TABLE [TWO_WAY_LIST [ALIAS_OBJECT], ALIAS_KEY]]]
		do
			if stack.count > 1 then
				l_ent := stack.last.caller_path.twin
				l_local_ent := stack.last.caller_locals.twin
			else
				create l_ent.make
				create l_local_ent.make
			end
			if qualified_call then
				from
					--ent.finish
					ent.start
				until
					--ent.before
					ent.after
				loop
					l_ent.extend (ent.item)
					--ent.back
					ent.forth
					--if ent.before then
					if not ent.after then
						l_local_ent.extend (create {TWO_WAY_LIST [HASH_TABLE [TWO_WAY_LIST [ALIAS_OBJECT], ALIAS_KEY]]}.make)
					end
				end

				if tracing then
					io.new_line
					print (l_ent.count)
					io.new_line
					print (l_local_ent.count)
				end

				--l_ent.extend (ent)
				l_local_ent.extend (ent_local)
			end
			stack.extend (create {ALIAS_ROUTINE}.make (
						a_current_object, a_routine, create {HASH_TABLE [TWO_WAY_LIST [ALIAS_OBJECT], ALIAS_KEY]}.make (16),
						l_ent, l_local_ent))

				-- to retrieve the class in which a_routine is
			if qualified_call or stack.count = 1 then
				update_class_atts_routine (a_routine)
			end
			update_feat_signature (a_routine)
		end

	update_class_atts_routine (a_routine: PROCEDURE_I)
			-- updates, in the graph, the class attributes in which `a_routine' is
			-- it adds a Void reference to those detachable references.
		do
			update_class_atts (a_routine.access_class, stack_top.current_object.attributes)
		end

	update_class_atts_routine_in_obj (a_routine: PROCEDURE_I; obj: HASH_TABLE [TWO_WAY_LIST [ALIAS_OBJECT], ALIAS_KEY])
			-- updates, in `obj', the class attributes in which `a_routine' is
			-- it adds a Void reference to those detachable references.
		do
			update_class_atts (a_routine.access_class, obj)
		end

	update_class_atts (a_class: CLASS_C; obj_vars: HASH_TABLE [TWO_WAY_LIST [ALIAS_OBJECT], ALIAS_KEY])
			-- updates, in the graph, the class attributes of class `a_class'
		local
			l_obj: TWO_WAY_LIST [ALIAS_OBJECT]
		do
			across
				a_class.constant_features as const
			loop
				if not obj_vars.has (create {ALIAS_KEY}.make (const.item.name_32)) then
						-- to retrieve their types and to add them to the stack
					create l_obj.make
					l_obj.force (create {ALIAS_OBJECT}.make (const.item.type))
					obj_vars.force (l_obj, create {ALIAS_KEY}.make (const.item.name_32))
				end
			end
			across
				a_class.skeleton as att
			loop
				if tracing then
					print (att.item.attribute_name)
					io.new_line
				end
				if not obj_vars.has (create {ALIAS_KEY}.make (att.item.attribute_name)) then
					if att.item.type_i.has_detachable_mark then
							-- to retrieve their types and to add them to the stack
						create l_obj.make
						l_obj.force (create {ALIAS_OBJECT}.make_void)
						obj_vars.force (l_obj, create {ALIAS_KEY}.make (att.item.attribute_name))
					else
							-- to retrieve their types and to add them to the stack
						create l_obj.make
						l_obj.force (create {ALIAS_OBJECT}.make (att.item.type_i))
						obj_vars.force (l_obj, create {ALIAS_KEY}.make (att.item.attribute_name))
					end

				end
			end
		end

	update_feat_signature (a_routine: PROCEDURE_I)
			-- updates, in the graph, the `a_routine's signature
			-- it adds a Void reference to those detachable references.
		local
			l_obj: TWO_WAY_LIST [ALIAS_OBJECT]
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
						l_obj.force (create {ALIAS_OBJECT}.make (type))
						stack_top.locals.force (l_obj, create {ALIAS_KEY}.make (args_names.at (i)))
					end
					i := i + 1
				end
			end

				-- Return value
			if a_routine.e_feature.has_return_value then
				if attached a_routine.e_feature.type as type then
					create l_obj.make
					l_obj.force (create {ALIAS_OBJECT}.make (type))
					stack_top.locals.force (l_obj, create {ALIAS_KEY}.make ("Result"))
				else
						-- TODO
				end
			end
		end

	stack_pop
			-- removes the last context
		do
			stack.finish
			stack.remove
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
			print_nodes (stack.last, create {CELL [NATURAL_32]}.put (0), Result)
			print_edges (stack.last, Result, cur_change)
			Result.append ("}%N")
		end

feature -- Updating

	update_call
			-- updates the name of the caller if the current call is a function
			-- e.g. in x.feat, where 'x:T do Result := a end', the caller of 'feat' is not Result but 'a': a.set
		local
			atts_mapped: TWO_WAY_LIST [STRING]
		do
			if tracing then
				print (stack_top.routine.e_feature.name_32)
				io.new_line
				print (stack.count > 1)
				io.new_line
				print (not stack_top.routine.is_attribute)
				io.new_line
				print (stack_top.routine.is_function)
				io.new_line
			end

			if stack.count > 1 and not stack_top.routine.is_attribute then
				if stack_top.routine.is_function then
					create atts_mapped.make
					across
						stack_top.locals.at (create {ALIAS_KEY}.make ("Result")) as objs
					loop
						across
							stack_top.current_object.attributes as attributes
						loop
							if attributes.item.has (objs.item) then
								atts_mapped.force (attributes.key.name)
									-- TODO: move cursor to the end
							end
						end
					end
					stack.at (stack.count - 1).map_funct.force (atts_mapped, create {ALIAS_KEY}.make (stack_top.routine.e_feature.name_32))
				end
				deleting_local_vars (stack_top.routine.e_feature.name_32, stack_top.locals.current_keys)
			end
			if tracing then
				io.new_line
				print (stack_top.routine.e_feature.name_32)
				if attached atts_mapped as a and then a.count > 0 then
					across
						a as v
					loop
						io.new_line
						print (v.item)
					end
				end
			end
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

	print_nodes (a_cur_node: ALIAS_VISITABLE; a_id: CELL [NATURAL_32]; a_output: STRING_8)
		require
			a_cur_node /= Void
			a_id /= Void
			a_output /= Void
		do
			if not a_cur_node.visited then
				a_cur_node.visited := True
				a_id.put (a_id.item + 1)
				a_cur_node.add_visiting_data ("b" + a_id.item.out)
				a_output.append ("%T" + a_cur_node.visiting_data.last + "[label=<" + a_cur_node.out + ">]%N")
				if attached {ALIAS_ROUTINE} a_cur_node as l_ar then
					print_nodes (l_ar.current_object, a_id, a_output)
				end
				across
					a_cur_node.variables as c
				loop
					across
						c.item as vars
					loop
						print_nodes (vars.item, a_id, a_output)
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

feature -- Managing Conditionals

	is_conditional_branch: BOOLEAN
			-- is the alias graph currently analysing a condition?
		do
			Result := alias_cond.is_conditional_branch
		end

	init_cond
			-- initialises the counter for branches in a conditional and
			-- stores the initial state of the graph
		do
			alias_cond.init_cond
		end

	init_cond_branch
			-- initialises a branch for a conditional.
		do
			alias_cond.init_branch
		end

	restore_graph
			-- restores the alias graph as it was before the current conditional branch
		do
			if tracing then
				print_atts_depth (stack_top.current_object.attributes)
				print_atts_depth (stack_top.locals)
			end
			alias_cond.restoring_state (stack.first, stack_top)
		end

	finalising_cond
			-- finalises the operations of conditionals
		do
			alias_cond.finalising_cond (stack.first, stack_top)
		end

	updating_graph (target, source: ALIAS_OBJECT_INFO)
			-- updates the sets `additions' and `deletions' accordingly.
		do
			if tracing then
				alias_cond.printing_vars (1)
				if stack.count > 1 then
					print (stack_top.routine.e_feature.name_32)
				end
				across
					stack_top.caller_path as aa
				loop
					across
						aa.item as a
					loop
						print (a.item)
						io.new_line
					end
				end
			end

			if is_conditional_branch then
				alias_cond.updating_A_D (target.variable_name, source.variable_name, target.alias_object, source.alias_object,
					if stack.count > 1 then stack_top.caller_path else create {TWO_WAY_LIST [TWO_WAY_LIST [STRING]]}.make end,
					if stack.count > 1 then stack_top.caller_locals else create {TWO_WAY_LIST [TWO_WAY_LIST [HASH_TABLE [TWO_WAY_LIST [ALIAS_OBJECT], ALIAS_KEY]]]}.make end,
					stack_top.routine.e_feature.name_32 + "_",
					stack_top.locals.has (create {ALIAS_KEY}.make (target.variable_name)),
					stack_top.locals.has (create {ALIAS_KEY}.make (source.variable_name))
					)
			end
			if is_loop_iter then
				alias_loop.updating_A_D (target.variable_name, source.variable_name, target.alias_object, source.alias_object,
					if stack.count > 1 then stack_top.caller_path else create {TWO_WAY_LIST [TWO_WAY_LIST [STRING]]}.make end,
					if stack.count > 1 then stack_top.caller_locals else create {TWO_WAY_LIST [TWO_WAY_LIST [HASH_TABLE [TWO_WAY_LIST [ALIAS_OBJECT], ALIAS_KEY]]]}.make end,
					stack_top.routine.e_feature.name_32 + "_",
					stack_top.locals.has (create {ALIAS_KEY}.make (target.variable_name)),
					stack_top.locals.has (create {ALIAS_KEY}.make (source.variable_name))
					)
			end

			if is_dyn_bin then
				alias_dyn.updating_A_D (target.variable_name, source.variable_name, target.alias_object, source.alias_object,
					if stack.count > 1 then stack_top.caller_path else create {TWO_WAY_LIST [TWO_WAY_LIST [STRING]]}.make end,
					if stack.count > 1 then stack_top.caller_locals else create {TWO_WAY_LIST [TWO_WAY_LIST [HASH_TABLE [TWO_WAY_LIST [ALIAS_OBJECT], ALIAS_KEY]]]}.make end,
					stack_top.routine.e_feature.name_32 + "_",
					stack_top.locals.has (create {ALIAS_KEY}.make (target.variable_name)),
					stack_top.locals.has (create {ALIAS_KEY}.make (source.variable_name))
					)
			end

				-- in case of recursion
			stack_top.alias_pos_rec.updating_a_d (target.variable_name, source.variable_name, target.alias_object, source.alias_object,
					if stack.count > 1 then stack_top.caller_path else create {TWO_WAY_LIST [TWO_WAY_LIST [STRING]]}.make end,
					if stack.count > 1 then stack_top.caller_locals else create {TWO_WAY_LIST [TWO_WAY_LIST [HASH_TABLE [TWO_WAY_LIST [ALIAS_OBJECT], ALIAS_KEY]]]}.make end,
					stack_top.routine.e_feature.name_32 + "_",
					stack_top.locals.has (create {ALIAS_KEY}.make (target.variable_name)),
					stack_top.locals.has (create {ALIAS_KEY}.make (source.variable_name))
					)
		end

		--forget_att (target: ALIAS_OBJECT_INFO)

	forget_att (target, source: ALIAS_OBJECT_INFO)
			-- used whenever a class attribute is created. It forgets (deletes) the `variable_name'
			-- from the additions edges on the graph
		do
				--alias_cond.forget_att (target.variable_name, target.alias_object,
				--						(not (target.variable_name ~ "Result")) and (not stack_top.locals.has (target.variable_name)))

			alias_cond.forget_att (target.variable_name, target.variable_name, target.alias_object, source.alias_object, (not (target.variable_name ~ "Result")) and (not stack_top.locals.has (create {ALIAS_KEY}.make (target.variable_name))))
		end

	deleting_local_vars (function_name: STRING; locals: ARRAY [ALIAS_KEY])
			-- updates the sets `additions and `deletions' deleting local variables that will no be of any used outside a feature
		local
			current_atts: ARRAYED_LIST [STRING]
		do
			create current_atts.make (stack.at (stack.count-1).current_object.attributes.count)
			if tracing then
				print ("%NCount: ")
				print (stack.count)
				io.new_line
			end
			if locals.count > 0 then
				across
					stack.at (stack.count-1).current_object.attributes.current_keys as keys
				loop
					current_atts.force (keys.item.name)
				end
			end

			if is_conditional_branch then
				alias_cond.deleting_local_vars (function_name, stack.count, locals, current_atts)
			end

			if is_loop_iter then
				alias_loop.deleting_local_vars (function_name, stack.count, locals, current_atts)
			end
			if is_dyn_bin then
				alias_dyn.deleting_local_vars (function_name, stack.count, locals, current_atts)
			end
		end

feature -- Managing Loops

	is_loop_iter: BOOLEAN
			-- is the alias graph currently analysing a loop iteration?
		do
			Result := alias_loop.is_loop_iter
		end

	init_loop
			-- initialises the counter for loops iterations
		do
			alias_loop.init_loop
		end

	iter
			-- initialises another iteraction in the loop
		do
			alias_loop.iter
		end

	finalising_loop
			-- adds the deleted nodes to the graph
		do
			if is_conditional_branch then
				alias_loop.set_cond_add (alias_cond.additions)
			end

			alias_loop.finalising_loop (stack.first, stack_top)
			alias_loop.set_cond_add (Void)
		end

	fixpoint_reached: INTEGER
			-- `fixpoint_reached' stores the type of reachpoint reached:
			--		0: no fixpoint
			--		1: the body of the loop does not change the graph
			-- 		2: the graph did not change from last iteraction
			-- 		3: fixpoint associated to N
		do
			Result := alias_loop.fixpoint_reached
		end

	checking_fixpoint
			-- checks (and updates accordingly) if the loop analysis has reached a checkpoint
		do
			alias_loop.checking_fixpoint
		end

feature -- Managing Recursion

	check_recursive_fix_point (routine_name: STRING)
			-- checks for fix point reached in a recursive call. It set variables
			--	is_recursive_fix_point to True in case of fix point reached and
			--  rec_last_locals to the locals variables of the last routine
		local
			i: INTEGER
			times: INTEGER
		do
			create rec_last_locals.make (0)
			create pre_add.make
			create pre_del.make
			from
				i := stack.count
			until
				i < 1 or times > fix_point
			loop
				if stack.at (i).routine.feature_name_32 ~ routine_name then
					times := times + 1
					if rec_last_locals.is_empty then
							-- points to the previous call
						rec_last_locals := stack.at (i).locals
					end
						-- pre_add and pre_del will be needed to restore the graph
					pre_add.put_front (stack.at (i).alias_pos_rec.additions.at (1))
					pre_del.put_front (stack.at (i).alias_pos_rec.deletions.at (1))
				end
				i := i - 1
			end
			is_recursive_fix_point := times > fix_point
		end

	is_recursive_fix_point: BOOLEAN
			-- is the analysis in a recursion and it already reached a fix point?

	rec_last_locals: HASH_TABLE [TWO_WAY_LIST [ALIAS_OBJECT], ALIAS_KEY]
			-- points to the last locals in a previous recursive call

	pre_add, pre_del: TWO_WAY_LIST [HASH_TABLE [TUPLE [name, abs_name, feat_name: STRING;
				obj: TWO_WAY_LIST [ALIAS_OBJECT]; path: TWO_WAY_LIST [TWO_WAY_LIST [STRING]];
				path_locals: TWO_WAY_LIST [TWO_WAY_LIST [HASH_TABLE [TWO_WAY_LIST [ALIAS_OBJECT], ALIAS_KEY]]]
				], ALIAS_KEY]]
			-- additions and deletions of the previous recursive calls.
			-- TODO: To improve

	fix_point: INTEGER = 2
			-- `n_fixpoint' is a fix number: upper bound for rec

	finalising_recursion
			-- finalises the operations of recursion in case of fix pont
		require
			is_recursive_fix_point;
			(pre_add.count = pre_del.count) and (pre_add.count = 3)
		do
				-- retrieve additions and deletions
				-- TODO: should I delete them as well? (additions and deletions of previous calls)
			stack_top.alias_pos_rec.finalising_recursive_call (stack.first, stack_top, pre_add, pre_del)
		end

	inter_deletion_cond: HASH_TABLE [TUPLE [name, abs_name, feat_name: STRING;
			obj: TWO_WAY_LIST [ALIAS_OBJECT]; path: TWO_WAY_LIST [TWO_WAY_LIST [STRING]];
			path_locals: TWO_WAY_LIST [TWO_WAY_LIST [HASH_TABLE [TWO_WAY_LIST [ALIAS_OBJECT], ALIAS_KEY]]]
			], ALIAS_KEY]
			-- returns the entities to be added to deletion after a conditional
		do
			Result := alias_cond.inter_deletion
		end

feature -- Managing possible Dyn Bind

	is_dyn_bin: BOOLEAN
			-- is the alias graph currently analysing a feature version?
		do
			Result := alias_dyn.is_dyn_bind
		end

	init_dyn_bin
			-- initialises the counter for feature versions and
			-- stores the initial state of the graph
		do
			alias_dyn.init_dyn_bind
		end

	init_feature_version
			-- initialises a branch for a conditional.
		do
			alias_dyn.init_feat_version
		end

	restore_graph_dyn
			-- restores the alias graph as it was before the current feature version
		do
			if tracing then
				print_atts_depth (stack_top.current_object.attributes)
				print_atts_depth (stack_top.locals)
				alias_dyn.printing_vars (1)
			end
			alias_dyn.restoring_state (stack.first, stack_top)
			if tracing then
				alias_dyn.printing_vars (1)
				print_atts_depth (stack_top.current_object.attributes)
				print_atts_depth (stack_top.locals)
			end
		end

	finalising_dyn_bind
			-- finalises the operations of feature versions
		do
			if tracing then
				alias_dyn.printing_vars(1)
			end
			alias_dyn.finalising_dyn_bind (stack.first, stack_top)
		end

feature {NONE} -- Access

	stack: TWO_WAY_LIST [ALIAS_ROUTINE]
			-- `stack' implements the ALIAS_GRAPH

	alias_cond: ALIAS_COND
			-- manages conditional branches

	alias_loop: ALIAS_LOOP
			-- manages loop interations

	alias_dyn: ALIAS_DYN_BIND
			-- manages possible dynamic binding calls

feature --{ALIAS_GRAPH} -- TO DELETE

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

		--	reset (in: HASH_TABLE [TWO_WAY_LIST [ALIAS_OBJECT], STRING_8])
		--		do
		--			across
		--				in as links
		--			loop
		--				across
		--					links.item as vals
		--				loop
		--					if vals.item.visited then
		--						vals.item.visited := false
		--						reset (vals.item.attributes)
		--					end
		--				end
		--			end
		--		end

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
					--print ("%N ====================TO GRAPH ====================%N")
					--				print (to_graph)
					--				print ("%N ====================TO GRAPH ====================%N")
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

invariant
	stack /= Void
	alias_cond /= Void
	alias_loop /= Void
	alias_dyn /= Void
	not stack.is_empty
	across stack as c all c.item /= Void end

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
