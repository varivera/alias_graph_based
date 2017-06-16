note
	description: "[
		This class managing sub-alias-graph when need it: the main the functionality to add/delete/restore the Alias graph when the
		analysis enters in structures such as conditionals, loops, recursions or handling 'dynamic binding'
		This class provides mechanisms to manipulate the graph and to restore it. Also mechanismos to subsume nodes.
	]"
	legal: "See notice at end of class."
	status: "See notice at end of class."
	date: "$Date: (Fri, 07 Oct 2016) $"
	revision: "$Revision: 98127 $"

deferred class
	ALIAS_SUB_GRAPH

inherit

	TRACING

feature {NONE} -- Initialiasation

	make
			-- Initialises an {ALIAS_SUB_GRAPH} and descendants
		do
			create indexes.make
			create additions.make
			create deletions.make
		end

feature -- Updating

	stop2 (n: INTEGER)
		do
			if tracing then
				print (n)
				io.new_line
			end
		end

	updating_A_D (target_name, source_name: STRING; target_object, source_object: TWO_WAY_LIST [ALIAS_OBJECT];
				target_path: TWO_WAY_LIST [TWO_WAY_LIST [STRING]];
				target_path_locals: TWO_WAY_LIST [HASH_TABLE [TWO_WAY_LIST [ALIAS_OBJECT], ALIAS_KEY]];
				routine_name: STRING; local_var_target, local_var_source: BOOLEAN)
			-- updates the sets `additions' and `deletions' accordingly:
			--	additions -> [`target_name': (`source_name', `source_object', `target_path', `path_locals')]
			--  deletions -> [`target_name': (`source_name', `source_object', `target_path', `path_locals')]
			-- `routine_name' is needed to identified local variables (e.g. `local_var') from different features inside the same the class
		require
			is_in_structure
		local
			tup: TUPLE [
				name, abs_name, feat_name: STRING;
				obj: TWO_WAY_LIST [ALIAS_OBJECT];
				path: TWO_WAY_LIST [TWO_WAY_LIST [STRING]];
				path_locals: TWO_WAY_LIST [HASH_TABLE [TWO_WAY_LIST [ALIAS_OBJECT], ALIAS_KEY]]
				]
			obj: TWO_WAY_LIST [ALIAS_OBJECT]
		do
			if tracing then
				io.new_line
				print ("target_path: ")
				print (target_path.count)
				print ("[")
				across
					target_path as tp
				loop
					print ("[")
					across
						tp.item as p
					loop
						print (p.item)
						print (",")
					end
					print ("]")
				end
				print ("]")
				io.new_line
				io.new_line
				print ("target_path_locals: ")
				print (target_path_locals.count)
				print ("[")
				across
					target_path_locals as p
				loop
					print ("keys (")
--					across
--						tpl.item as p
--					loop
						across
							p.item.current_keys as k
						loop
							print (k.item)
							print (",")
						end
--					end
					print ("), ")
				end
				print ("]")
				io.new_line
				io.new_line
			end
			stop2 (0)
			create tup
			tup.feat_name := routine_name
			tup.abs_name := ""
			stop2 (8)
			across
				target_path as abs
			loop
				stop2 (1)
				if abs.item.count = 0 then
					tup.abs_name := tup.abs_name + "Current."
				elseif abs.item.count = 1 then
					tup.abs_name := tup.abs_name + abs.item.first + "."
				else
					tup.abs_name := tup.abs_name + "["
					across
						abs.item as sub
					loop
						tup.abs_name := tup.abs_name + sub.item + ","
					end
					tup.abs_name := tup.abs_name + "]."
				end
			end
			stop2 (9)
			--if target_name ~ "Result" then
			if local_var_target then
				stop2 (10)
				tup.abs_name := tup.abs_name + routine_name + target_name
			else
				stop2 (11)
				tup.abs_name := tup.abs_name + target_name
			end
			if attached source_name as sn then
				if local_var_source then
					tup.name := routine_name + sn
				else
					tup.name := sn
				end
			else
				tup.name := "Void"
			end
			tup.path := target_path.deep_twin
			tup.path_locals := target_path_locals.deep_twin
			create obj.make
			stop2 (12)
			if attached source_object as so then
				across
					so as s
				loop
					obj.force (s.item)
				end
			else
				obj.force (create {ALIAS_OBJECT}.make_void)
			end
			stop2 (2)
			tup.obj := obj
			--if target_name ~ "Result" then
			if local_var_target then
				additions.last.force (tup, create {ALIAS_KEY}.make (routine_name + target_name))
			else
				additions.last.force (tup, create {ALIAS_KEY}.make (target_name))
			end

				--if attached target_object as target then
				-- An example of Void target: Result
			create tup
			tup.feat_name := routine_name
			tup.abs_name := ""
			across
				target_path as abs
			loop
				stop2 (3)
				if abs.item.count = 0 then
					tup.abs_name := tup.abs_name + "Current."
				elseif abs.item.count = 1 then
					tup.abs_name := tup.abs_name + abs.item.first + "."
				else
					tup.abs_name := tup.abs_name + "["
					across
						abs.item as sub
					loop
						tup.abs_name := tup.abs_name + sub.item + ","
					end
					tup.abs_name := tup.abs_name + "]."
				end
			end
			--if target_name ~ "Result" then
			if local_var_target then
				tup.abs_name := tup.abs_name + routine_name + target_name
			else
				tup.abs_name := tup.abs_name + target_name
			end
			if local_var_target then
				tup.name := routine_name + target_name
			else
				tup.name := target_name
			end
			tup.path := target_path.deep_twin
			tup.path_locals := target_path_locals.deep_twin
			create obj.make
			stop2 (4)
			if attached target_object as target then
				across
					target as t
				loop
					obj.force (t.item)
				end
			end
			tup.obj := obj
			--if target_name ~ "Result" then
			if local_var_target then
				deletions.last.force (tup, create {ALIAS_KEY}.make (routine_name + target_name))
			else
				deletions.last.force (tup, create {ALIAS_KEY}.make (target_name))
			end
			stop2 (5)
			if tracing then
				printing_vars (1)
			end
		end

	deleting_local_vars (function_name: STRING; func_n: INTEGER; locals: ARRAY [ALIAS_KEY]; current_atts: ARRAYED_LIST [STRING])
			-- updates the sets `additions and `deletions' deleting local variables that will no be of
			-- any used outside a feature
			-- `func_n' is used to determined whether a variable is a local variable of the corresponding feature
		require
			is_in_structure
		local
			keys_to_delete: ARRAYED_LIST [ALIAS_KEY]

			local_map: HASH_TABLE [STRING, STRING]
		do
			if tracing then
				print ("%N========%N")
				printing_vars (1)
			end

			create local_map.make (0)
			if locals.count >= 1 then
					-- local var Result
				if additions.count > 0 then
					additions.last.remove (create {ALIAS_KEY}.make (function_name + "_Result"))
				end
				if deletions.count > 0 then
					deletions.last.remove (create {ALIAS_KEY}.make (function_name + "_Result"))
				end

					-- other local variables
				if tracing then
					print ("%N========%N")
					printing_vars (1)
				end
						-- collect the mapping between local variables and class attributes
				if additions.count >= 1 then
					across
						locals as l
					loop
						create keys_to_delete.make (0)
						across
							additions.last as vals
						loop
							if tracing then
								print ("0: " + (vals.item.name))
								io.new_line
								print ("1: " + (function_name+"_"+l.item.name))
								io.new_line
								print ("2: " + vals.key.name)
								io.new_line
								print ("3: ")
								print ((function_name+"_"+l.item.name) ~ vals.key.name)

							end
							if (function_name+"_"+l.item.name) ~ vals.key.name then
								if tracing then
									io.new_line
									print (">"+vals.item.name+"<")
									io.new_line
									print ("atts: [")
									across
										current_atts as att
									loop
										print (att.item)
										print (", ")
									end
									print ("]%N")
								end
								if current_atts.has (vals.item.name) then
									if tracing then
										io.new_line
										print ("key: " +  vals.key.name + " value: " + vals.item.name)
										io.new_line
									end
									local_map.force (vals.item.name, vals.key.name)
								end
								keys_to_delete.force (create {ALIAS_KEY}.make (vals.key.name))
							end
						end
						across
							keys_to_delete as keys
						loop
							additions.last.remove (keys.item)
							deletions.last.remove (keys.item)
						end
					end
				end
				if tracing then
					print ("%N========%N")
					printing_vars (1)
				end
				create keys_to_delete.make (0)
					-- deleting/mapping from `name'
				if additions.count >= 1 then
					across
						locals as l
					loop
						create keys_to_delete.make (0)
						across
							additions.last as vals
						loop
							if tracing then
								io.new_line
								print (function_name+"_"+l.item.name)
								io.new_line
								print (vals.item.name.out)
								io.new_line
								print ((function_name+"_"+l.item.name) ~ vals.item.name.out)
								io.new_line
								print (" and ")
								print (vals.item.path.count)
								print (" = ")
								print (func_n - 1)
								io.new_line
							end
							if (function_name+"_"+l.item.name) ~ vals.item.name.out then
								if local_map.has (vals.item.name.out) then
										-- change
									vals.item.name.replace_substring_all (vals.item.name.out, local_map.at (vals.item.name.out))
								else
										-- remove
									keys_to_delete.force (create {ALIAS_KEY}.make (vals.item.name.out))
								end
							end
						end
						across
							keys_to_delete as keys
						loop
							additions.last.remove (keys.item)
							deletions.last.remove (keys.item)
						end
					end
				end
				if tracing then
					print ("%N========%N")
					printing_vars (1)
				end
				create keys_to_delete.make (0)
					-- deleting/mapping from `path'
				if additions.count >= 1 then
					create keys_to_delete.make (0)
					across
						locals as l
					loop
						across
							additions.last as vals
						loop

							across
								vals.item.path as path
							loop
								across
									path.item as vals2
								loop
									if tracing then
										io.new_line
										print (not keys_to_delete.has (create {ALIAS_KEY}.make (vals.key.name)))
										io.new_line
										print (l.item.name)
										print (" ~ ")
										print (vals2.item)
										print (" and ")
										print (vals.item.path.count)
										print (" = ")
										print (func_n - 1)
										io.new_line
									end
									if not keys_to_delete.has (create {ALIAS_KEY}.make (vals.key.name)) and
									 	l.item.name ~ vals2.item and vals.item.path.count = (func_n - 1)
									 then
									 	if local_map.has (function_name+"_"+vals2.item) then
												-- change
											if vals.item.abs_name.has_substring (l.item.name) then
												vals.item.abs_name.replace_substring_all (l.item.name, local_map.at (function_name+"_"+vals2.item))
											end
											vals2.item.replace_substring_all (l.item.name, local_map.at (function_name+"_"+vals2.item))
										else
												-- remove
											keys_to_delete.force (create {ALIAS_KEY}.make (vals.key.name.out))
										end
									 end
								end
							end
						end
					end
					across
						keys_to_delete as keys
					loop
						additions.last.remove (keys.item)
						deletions.last.remove (keys.item)
					end
				end

				if deletions.count >= 1 then
					create keys_to_delete.make (0)
					across
						locals as l
					loop
						across
							deletions.last as vals
						loop

							across
								vals.item.path as path
							loop
								across
									path.item as vals2
								loop
									if tracing then
										io.new_line
										print (not keys_to_delete.has (create {ALIAS_KEY}.make (vals.key.name)))
										io.new_line
										print (l.item.name)
										print (" ~ ")
										print (vals2.item)
										print (" and ")
										print (vals.item.path.count)
										print (" = ")
										print (func_n - 1)
										io.new_line
									end
									if not keys_to_delete.has (create {ALIAS_KEY}.make (vals.key.name)) and
									 	l.item.name ~ vals2.item and vals.item.path.count = (func_n - 1)
									 then
									 	if local_map.has (function_name+"_"+vals2.item) then
												-- change
											if vals.item.abs_name.has_substring (l.item.name) then
												vals.item.abs_name.replace_substring_all (l.item.name, local_map.at (function_name+"_"+vals2.item))
											end
											vals2.item.replace_substring_all (l.item.name, local_map.at (function_name+"_"+vals2.item))
										else
												-- remove
											keys_to_delete.force (create {ALIAS_KEY}.make (vals.key.name.out))
										end
									 end
								end
							end
						end
					end
					across
						keys_to_delete as keys
					loop
						additions.last.remove (keys.item)
						deletions.last.remove (keys.item)
					end
				end

			end

			if tracing then
				print ("%N========%N")
				printing_vars (1)
			end
		end

	deleting_local_vars2 (function_name: STRING; func_n: INTEGER; locals: ARRAY [ALIAS_KEY])
			-- updates the sets `additions and `deletions' deleting local variables that will no be of
			-- any used outside a feature
			-- `func_n' is used to determined whether a variable is a local variable of the corresponding feature
		require
			is_in_structure
		local
			stop: BOOLEAN
			key: STRING
			keys_to_delete: ARRAYED_LIST [ALIAS_KEY]
		do
			if tracing then
				printing_vars (1)
			end
			if locals.count >= 1 then
					-- local var Result
				if additions.count > 0 then
					additions.last.remove (create {ALIAS_KEY}.make (function_name + "_Result"))
				end
				if deletions.count > 0 then
					deletions.last.remove (create {ALIAS_KEY}.make (function_name + "_Result"))
				end

					-- other local variables
				if additions.count >= 1 then
					across
						locals as l
					loop
						if tracing then
							print ("checking: ")
							print (l.item)
							io.new_line
							io.new_line
						end
						create keys_to_delete.make (0)
						across
							additions.last as vals
						loop
							key := vals.key.name
							if tracing then
								io.new_line
								print (">")
								print (l.item)
								print ("<")
								print (" =? ")
								print (">")
								print (vals.item.name)
								print ("<")
								io.new_line
								print (vals.item.name.out ~ l.item.out)
								io.new_line
								print (func_n - 1)
								io.new_line
								print (vals.item.path.count)
								print (l.item ~ vals.item.name and vals.item.path.count = (func_n - 1))
							end
							if (function_name+"_"+l.item.name) ~ vals.item.name.out and vals.item.path.count = (func_n - 1) then
								keys_to_delete.force (create {ALIAS_KEY}.make (key))
							end
						end
						across
							keys_to_delete as keys
						loop
							additions.last.remove (keys.item)
							deletions.last.remove (keys.item)
						end
					end
				end

				if additions.count >= 1 then
					create keys_to_delete.make (0)
					across
						locals as l
					loop
						across
							additions.last as vals
						loop
							key := vals.key.name
							if not keys_to_delete.has (create {ALIAS_KEY}.make (key)) then
								across
									vals.item.path as path
								loop
									if across path.item as p some p.item ~ (function_name+"_"+l.item.name) end then
										keys_to_delete.force (create {ALIAS_KEY}.make (key))
									end
								end
							end
						end
					end
					across
						keys_to_delete as keys
					loop
						additions.last.remove (keys.item)
						deletions.last.remove (keys.item)
					end
				end
			end
		end

feature -- Managing Branches

	is_in_structure: BOOLEAN
			-- is the alias graph currently analysing a structure: eg. conditional branch, loop iteration, recursion?
		deferred
		end

	initialising
			-- initialises the counter of steps
		do
			indexes.force (create {TUPLE [index_add, index_del: INTEGER]})
			indexes.last.index_add := additions.count + 1
			indexes.last.index_del := deletions.count + 1
		ensure
			is_in_structure
		end

	step
			-- initialises a step of a structure: e.g. a conditional branch
		require
			is_in_structure
		do



			additions.force (create {
				HASH_TABLE [TUPLE [
						name, abs_name, feat_name: STRING;
						obj: TWO_WAY_LIST [ALIAS_OBJECT];
						path: TWO_WAY_LIST [TWO_WAY_LIST [STRING]];
						path_locals: TWO_WAY_LIST [HASH_TABLE [TWO_WAY_LIST [ALIAS_OBJECT], ALIAS_KEY]]
						], ALIAS_KEY]}.make (0))
			deletions.force (create {
				HASH_TABLE [TUPLE [
						name, abs_name, feat_name: STRING;
						obj: TWO_WAY_LIST [ALIAS_OBJECT];
						path: TWO_WAY_LIST [TWO_WAY_LIST [STRING]];
						path_locals: TWO_WAY_LIST [HASH_TABLE [TWO_WAY_LIST [ALIAS_OBJECT], ALIAS_KEY]]
						], ALIAS_KEY]}.make (0))
		end

	finalising (root, current_routine: ALIAS_ROUTINE)
			-- it consists of two actions:
			--	i) inserts the union of elements in `additions'
			--	ii) deletes the intersection of elements in `deletions'
			--to `current_alias_routine'
		require
			is_in_structure
		deferred
		end

feature -- Managing merging nodes (for loops and recursion)

	subsume (root: ALIAS_ROUTINE)
			-- subsumes nodes if needed
		do
			if tracing then
				print ("%N===================================================%N")
				printing_vars (1)
			end
			across
				additions.last as added
					--additions.at (additions.count) as added
			loop
				if tracing then
					io.new_line
					print (added.key)
					io.new_line
				end

				if
					additions.at (additions.count - 1).has (added.key) and
					added.item.obj.count = additions.at (additions.count - 1).at (added.key).obj.count and
					not across added.item.obj as obj all additions.at (additions.count - 1).at (added.key).obj.has (obj.item) end then
						--TODO mark1 go through all elements in additions.at (add.index) .. addition.last adding thing to cond
					across
						added.item.obj as n2
					loop
							-- n1 subsumed by n2
						across
							additions.at (additions.count - 1).at (added.key).obj as n1
						loop
							subsume_nodes (n2.item, n1.item, root)
						end
					end
				else
					print ("No Subsume%N")
						-- nodes did not reach N fixed point
				end
			end
		end

	subsume_nodes (n2, n1: ALIAS_OBJECT; root: ALIAS_ROUTINE)
			-- subsumes node `n2' by `n1' in the graph
			-- it comprises 3 steps
			-- i. for_all i | i \in Nodes and i /= 2 and n_2 -->_t n_i then n_1 -->_t n_i
			-- ii. for_all i | i \in Nodes and i /= 2 and n_i -->_t n_2 then n_i -->_t n_1
			-- iii. for_all n_2 -->_t n_2 then n_1 -->_t n_1
		do
			subsume_from_n2 (n2, n1)
				-- including from n2 to itself

			reset (root.current_object.attributes)
			n2.visited := True
			subsume_to_n2 (root.current_object.attributes, n1, n2)
			reset (root.current_object.attributes)
		end

	subsume_from_n2 (n2, n1: ALIAS_OBJECT)
			-- subsumes node `n2' by `n1' in the graph
			-- it comprises 2 steps (steps (i) and (iii))
			-- i. for_all i | i \in Nodes and i /= 2 and n_2 -->_t n_i then n_1 -->_t n_i
			-- (NO) ii. for_all i | i \in Nodes and i /= 2 and n_i -->_t n_2 then n_i -->_t n_1
			-- iii. for_all n_2 -->_t n_2 then n_1 -->_t n_1
		local
			item_to_be_added: ALIAS_OBJECT
		do
			across
				n2.attributes as v2
			loop
				if not n1.attributes.has (v2.key) then
					n1.attributes.force (create {TWO_WAY_LIST [ALIAS_OBJECT]}.make, v2.key)
				end
				across
					v2.item as objs
				loop
					if objs.item = n2 then
						item_to_be_added := n1
					else
						item_to_be_added := objs.item
					end
					if not n1.attributes.at (v2.key).has (item_to_be_added) then
						n1.attributes.at (v2.key).force (item_to_be_added)
					end
				end
			end
		end

	subsume_to_n2 (v: HASH_TABLE [TWO_WAY_LIST [ALIAS_OBJECT], ALIAS_KEY]; n1, n2: ALIAS_OBJECT)
			-- subsumes node `n2' by `n1' in the graph
			-- it comprises 1 step (step (ii))
			-- (NO) i. for_all i | i \in Nodes and i /= 2 and n_2 -->_t n_i then n_1 -->_t n_i
			-- ii. for_all i | i \in Nodes and i /= 2 and n_i -->_t n_2 then n_i -->_t n_1
			-- (NO) iii. for_all n_2 -->_t n_2 then n_1 -->_t n_1
		require
			v /= Void
			n2.visited
		do
			if not v.is_empty then
				across
					v as values
				loop
					from
						values.item.start
					until
						values.item.after
					loop
						if values.item.item = n2 then
							if not values.item.has (n1) then
								values.item.put_right (n1)
							end
							values.item.remove
						end
						if not values.item.after and not values.item.item.visited then
							values.item.item.visited := True
							subsume_to_n2 (values.item.item.attributes, n1, n2)
						end
						if not values.item.after then
							values.item.forth
						end
					end
				end
			end
		end

	add_deleted_links (root, current_routine: ALIAS_ROUTINE)
			-- restore the graph by given back the deleted links
		do
			if tracing then
				printing_vars (1)
			end
			if indexes.last.index_del <= deletions.count then
					-- Inserting deleted links
				from
					deletions.go_i_th (indexes.last.index_del)
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
							1,
							values.item.obj)
					end
					deletions.forth
				end
				indexes.finish
				indexes.remove
			end
		end

	restore_deleted (
			current_object: ALIAS_OBJECT;
			current_routine: ALIAS_ROUTINE;
			name_entity, feat_name: STRING;
			path: TWO_WAY_LIST [TWO_WAY_LIST [STRING]];
			path_locals: TWO_WAY_LIST [HASH_TABLE [TWO_WAY_LIST [ALIAS_OBJECT], ALIAS_KEY]];
			index: INTEGER;
			old_object: TWO_WAY_LIST [ALIAS_OBJECT])
			-- adds in `current_object'.`path' the deleted object: `old_object'
			-- This command is used to restore the state of the graph on exit of the structure
		require
			path.count = path_locals.count
		local
			c_objs: TWO_WAY_LIST [ALIAS_OBJECT]
			real_name: STRING
		do
			create real_name.make_from_string (name_entity)
			real_name.replace_substring_all (feat_name, "")
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
				if tracing then
					print_atts_depth (current_object.attributes)
					io.new_line
					print_atts_depth (current_routine.locals)
					io.new_line
					print (name_entity)
					io.new_line
					print (current_object.attributes.count)
					io.new_line
					if current_object.attributes.at (create {ALIAS_KEY}.make (name_entity)) = Void then
						io.new_line
						print ("Void")
						io.new_line
						print (current_object.attributes.count)
					end
				end
--				if current_object.attributes.at (create {ALIAS_KEY}.make (name_entity)) = Void then
--					io.new_line
--					print ("Void")
--				end

					-- the variable should exist (no need to check)
				if name_entity.ends_with ("_Result") then
					c_objs := current_routine.locals.at (create {ALIAS_KEY}.make ("Result"))
				elseif current_routine.locals.has (create {ALIAS_KEY}.make (real_name)) then
					c_objs := current_routine.locals.at (create {ALIAS_KEY}.make (real_name))
				elseif current_object.attributes.has (create {ALIAS_KEY}.make (name_entity)) then
					c_objs := current_object.attributes.at (create {ALIAS_KEY}.make (name_entity))
				else
						--				elseif current_routine.current_object.attributes.has (name_entity) then
						--					c_objs := current_routine.current_object.attributes.at (name_entity)
						--				else

				end
				across
					old_object as o_o
				loop
					if not c_objs.has (o_o.item) then
						c_objs.force (o_o.item)
					end
				end
			else
				across
					path.at (index) as paths
				loop
					if tracing then
						print_atts_depth (current_object.attributes)
						io.new_line
						print_atts_depth (current_routine.locals)
						io.new_line
						print (name_entity)
						io.new_line
						print (paths.item)
						io.new_line
					end
						-- either a class attribute or a local
					if current_object.attributes.has (create {ALIAS_KEY}.make (paths.item)) then
						c_objs := current_object.attributes.at (create {ALIAS_KEY}.make (paths.item))
					elseif index >= 1 and index <= path_locals.count then
						--c_objs := obj_locals (path_locals, index, create {ALIAS_KEY}.make (paths.item))
						c_objs := path_locals [index].at (create {ALIAS_KEY}.make (paths.item))
					end

					across
						c_objs as objs
					loop
						restore_deleted (
								objs.item,
								current_routine,
								name_entity,
								feat_name,
								path,
								path_locals,
								index + 1, old_object)
					end
				end
			end
		end

--	obj_locals (path_locals: TWO_WAY_LIST [HASH_TABLE [TWO_WAY_LIST [ALIAS_OBJECT], ALIAS_KEY]];
--			index: INTEGER;
--			key: ALIAS_KEY
--			): TWO_WAY_LIST [ALIAS_OBJECT]
--			-- make `objs' point to the right table
--		require
--			index >= 1 and index <= path_locals.count
--		do
--			across
--				path_locals.at (index) as vals
--			loop
--				if not attached Result and then vals.item.has_key (key) then
--					Result := vals.item.at (key)
--				end
--			end
--		end

feature -- Access
	--TODO: to create a class with this structure

	additions: TWO_WAY_LIST [HASH_TABLE [TUPLE [
						name, abs_name, feat_name: STRING;
						obj: TWO_WAY_LIST [ALIAS_OBJECT];
						path: TWO_WAY_LIST [TWO_WAY_LIST [STRING]];
						path_locals: TWO_WAY_LIST [HASH_TABLE [TWO_WAY_LIST [ALIAS_OBJECT], ALIAS_KEY]]
						], ALIAS_KEY]];

		-- stores the edges added by a step (A_i in the def): the key is the name of the entity to be added (it contains all path)
		-- `name': name of the entity to point at
		-- `obj': object that `name' is pointing at
		-- `path': path of the entity e.g. Current.v.[w,x]...
		-- `path_locals': contains the local variables of the callers (in case of need)
		-- `feat_name': the name of the feature where the addition took place

	deletions: like additions
			-- stores the edges deleted by a step (D_i in the def): the key is the name of the entity to be deleted (it contains all path)
			-- `name': name of the entity it was pointing at
			-- `obj': object that `name' it was pointing at
			-- `path': path of the entity e.g. Current.v.[w,x]...
			-- `path_locals': contains the local variables of the callers (in case of need)
			-- `feat_name': the name of the feature where the deletion took place

	indexes: TWO_WAY_LIST [TUPLE [index_add, index_del: INTEGER]]
			-- stores for each step index: the number of additions and deletions

feature --{NONE} -- To Delete

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
			ttt: TWO_WAY_LIST [HASH_TABLE [TUPLE [name, abs_name, feat_name: STRING;
			obj: TWO_WAY_LIST [ALIAS_OBJECT];
			path: TWO_WAY_LIST [TWO_WAY_LIST [STRING]];
			path_locals: TWO_WAY_LIST [HASH_TABLE [TWO_WAY_LIST [ALIAS_OBJECT], ALIAS_KEY]]
			], ALIAS_KEY]]
		do
			if tracing then
				if va = 4 then
				else
					if va = 1 or va = 3 then
						print ("%N%NAditions%N%N")
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
							added.item as pair_add
						loop
							print (pair_add.key)
							print (": ")
							print (pair_add.item.name)
							print (" -[")
							across
								pair_add.item.obj as obj_add
							loop
								if attached obj_add.item as oo then
									print (oo.out2)
								else
									print ("Void")
								end
								if obj_add.after then
									print (", ")
								end
							end
							print ("] path: [")
							across
								pair_add.item.path as path_add
							loop
								print ("[")
								across
									path_add.item as p
								loop
									print (p.item)
									if p.after then
										print (",")
									end
								end
								print ("]")
								if path_add.after then
									print (", ")
								end
							end
							print ("] path_locals: [")
							across
								pair_add.item.path_locals as p
							loop
								print ("keys (")
--								across
--									tpl.item as p
--								loop
									across
										p.item.current_keys as k
									loop
										print (k.item)
										print (",")
									end
--								end
								print ("), ")
							end
							print ("] abs_name: ")
							print (pair_add.item.abs_name)
							print (" feature_name: ")
							print (pair_add.item.feat_name)
							print ("%N")
						end
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
			ttt: TWO_WAY_LIST [HASH_TABLE [TUPLE [name, abs_name, feat_name: STRING;
			obj: TWO_WAY_LIST [ALIAS_OBJECT];
			path: TWO_WAY_LIST [TWO_WAY_LIST [STRING]];
			path_locals: TWO_WAY_LIST [HASH_TABLE [TWO_WAY_LIST [ALIAS_OBJECT], ALIAS_KEY]]
			], ALIAS_KEY]]
			va: INTEGER
		do
			va := 1
			if tracing then
				if va = 4 then
				else
					if va = 1 or va = 3 then
						print ("%N%NAditions%N%N")
						ttt := v
					end
					across
						ttt as added
					loop
						print ("--%N")
						across
							added.item as pair_add
						loop
							print (pair_add.key)
							print (": ")
							print (pair_add.item.name)
							print (" -[")
							across
								pair_add.item.obj as obj_add
							loop
								if attached obj_add.item as oo then
									print (oo.out2)
								else
									print ("Void")
								end
								if obj_add.after then
									print (", ")
								end
							end
							print ("] path: [")
							across
								pair_add.item.path as path_add
							loop
								print ("[")
								across
									path_add.item as p
								loop
									print (p.item)
									if p.after then
										print (",")
									end
								end
								print ("]")
								if path_add.after then
									print (", ")
								end
							end
							print ("] path_locals: [")
							across
								pair_add.item.path_locals as p
							loop
								print ("keys (")
--								across
--									tpl.item as p
--								loop
									across
										p.item.current_keys as k
									loop
										print (k.item)
										print (",")
									end
--								end
								print ("), ")
							end
							print ("] abs_name: ")
							print (pair_add.item.abs_name)
							print (" feature_name: ")
							print (pair_add.item.feat_name)
							print ("%N")
						end
					end
				end
			end
		end

feature {NONE}

	n_fixpoint: INTEGER = 2
			-- `n_fixpoint' is a fix number: upper bound for loops and rec

invariant
	additions /= Void
	deletions /= Void
	indexes /= void
	indexes.count = 0 implies (additions.count + deletions.count = 0)

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
