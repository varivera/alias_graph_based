note
	description: "[
				The visitor that computes the MQ list.
					Given a Model Query, this class returns the list of class attributtes related to it
				This is an initial implementation. It needs to be improved
	]"
	legal: "See notice at end of class."
	status: "See notice at end of class."
	date: "$Date: 2015-11-20 18:49:14 +0300 (Fri, 20 Nov 2015) $"
	revision: "$Revision: 98127 $"

class
	MQ_ANALYSIS_VISITOR

inherit

	AST_ITERATOR
		redefine
			process_eiffel_list,
			process_assign_as,
			process_assigner_call_as,
			process_create_creation_as,
			process_instr_call_as,
			process_if_as,
			process_elseif_as,
			process_object_test_as,
			process_loop_as,
			process_routine_as,
			process_access_feat_as,
			process_nested_as,
			process_current_as,
			process_id_as
		end

	SHARED_SERVER

	TRACING

create
	make

feature {NONE}

	make (class_id: INTEGER)
		do
			create mq_list.make
			class_base_id := class_id
			create calls.make
			create iv.make
		end

feature {ANY}

	mq_list: TWO_WAY_LIST [STRING]
			-- stores the class attributes needed to build a Model Query

	class_base_id: INTEGER
			-- class id

	calls: TWO_WAY_LIST [STRING]
			-- call feature to handle recursion: this needs to be improved

feature {NONE} -- Iteration Variable
	iv: TWO_WAY_LIST [STRING]
		-- in case of nested loops

feature {NONE}

	process_eiffel_list (a_node: EIFFEL_LIST [AST_EIFFEL])
		local
			l_cursor: INTEGER
		do
			from
				l_cursor := a_node.index
				a_node.start
			until
				a_node.after
			loop
				if attached a_node.item as l_item then
					l_item.process (Current)
				else
					check
						False
					end
				end
				a_node.forth
			end
			a_node.go_i_th (l_cursor)
		end

	process_routine_as (a_node: ROUTINE_AS)
		do
				-- Note: no need for MQ Analysis safe_process (l_as.precondition)
			safe_process (a_node.internal_locals)
			a_node.routine_body.process (Current)
				-- Note: no need for MQ Analysis safe_process (l_as.postcondition)
				-- Note: no need for MQ Analysis safe_process (l_as.rescue_clause)
		end

	process_access_feat_as (a_node: ACCESS_FEAT_AS)
		do
			store_info (a_node, false)
		end

	process_assign_as (a_node: ASSIGN_AS)
		do
			store_info (a_node.target, false)
			store_info (a_node.source, false)
		end

	process_assigner_call_as (a_node: ASSIGNER_CALL_AS)
		do
				-- foo.bar := baz  ->  handle as: foo.set_bar(baz)
			if attached {EXPR_CALL_AS} a_node.target as l_target1 and then -- foo.bar
				attached {NESTED_AS} l_target1.call as l_target2 -- foo.bar
			then
				if iv.count > 0 and then iv.last /= Void then
						-- inside a loop with iterator as Current
					store_info (a_node.source, false)
				else
					store_info (l_target2.target, false)
					store_info (a_node.source, true)
				end
			elseif -- foo [bar] := baz
				attached {BRACKET_AS} a_node.target as l_target2
			then
				Io.put_string ("Not yet supported (2): %N")
			else
				Io.put_string ("Not yet supported (2): %N")
			end
		end

	process_create_creation_as (a_node: CREATE_CREATION_AS)
		do
			store_info (a_node.target, false)
			if attached a_node.call then
				store_info (a_node.call, true)
			end
		end

	process_instr_call_as (a_node: INSTR_CALL_AS)
		do
			store_info (a_node.call, false)
		end

	process_elseif_as (a_node: ELSIF_AS)
		do
			a_node.expr.process (Current)
			safe_process (a_node.compound)
		end

	process_if_as (a_node: IF_AS)
		do
			a_node.condition.process (Current)
			safe_process (a_node.compound)
			safe_process (a_node.elsif_list)
			safe_process (a_node.else_part)
		end

	process_loop_as (a_node: LOOP_AS)
		do
			iv.force (Void)
			safe_process (a_node.iteration)
			safe_process (a_node.from_part)
			safe_process (a_node.stop)
			safe_process (a_node.compound)
			iv.finish
			iv.remove
		end

	process_object_test_as (a_node: OBJECT_TEST_AS)
		do
				-- TODO only keep it in its scope
			if a_node.name /= Void then
				store_info (a_node.expression, false)
			end
		end

	process_nested_as (a_node: NESTED_AS)
		do
			store_info (a_node, false)
		end

	process_current_as (a_node: CURRENT_AS)
		do
--			if across mq_list as mq all mq.item /~ "Current" end then
--				mq_list.force ("Current")
--			end
				-- inside a loop
			iv.finish
			if iv.count > 0 and then iv.item = Void then
				iv.replace ("Current")
			end
		end


	process_id_as (l_node: ID_AS)
		do
			iv.finish
			if iv.count > 0 and then attached iv.item as id and then id ~ "Current" then
				iv.replace (l_node.name_32)
			end
		end

feature {NONE} -- utilities

	store_info (a_node: AST_EIFFEL; is_qualified_call: BOOLEAN)
			-- analyses `a_node' and stores the corresponding information
		require
			a_node /= Void
		do
			if attached {ACCESS_FEAT_AS} a_node as l_node then
				if l_node.is_local or l_node.is_argument or l_node.is_object_test_local or l_node.is_tuple_access then
						-- we do not care about them
					do_nothing
				elseif attached find_routine (l_node, is_qualified_call) as l_routine then
					if attached l_node.parameters as params then
							-- check only the arguments
						across
							params as c
						loop
							store_info (c.item, false)
						end
					end
						-- routine
					if not is_qualified_call then
						if across calls as c all c.item /~ l_routine.e_feature.name_32 end then
							calls.force (l_routine.e_feature.name_32)
							if l_routine.is_deferred then
								mq_list.force (l_node.access_name_8 + "*")
							else
								l_routine.body.process (Current)
							end
						end
					end
				else
						-- attribute
					if not is_qualified_call and then across mq_list as mq all mq.item /~ l_node.access_name_8 end then
						mq_list.force (l_node.access_name_8)
					end
				end
			elseif attached {PRECURSOR_AS} a_node as l_node then
				if attached l_node.parameters as params then
					across
						params as c
					loop
						store_info (c.item, false)
					end
				end
			elseif attached {NESTED_AS} a_node as l_node then
				if iv.count > 0 and then iv.last /= Void and then
					attached {ACCESS_FEAT_AS} l_node.target as feat and then
						feat.access_name_32 ~ iv.last
				then
						-- inside a loop with iterator as Current
					--store_info (l_node.message, false)

					if System.class_of_id (class_base_id).name ~ "V_BINARY_TREE" then
						System.class_of_id (class_base_id).feature_named_32 ("inorder").body.process (Current)
					else
						System.class_of_id (class_base_id).feature_named_32 ("new_cursor").body.process (Current)
					end
				else
					store_info (l_node.target, is_qualified_call)
					store_info (l_node.message, true)
				end
			elseif attached {BINARY_AS} a_node as l_node then
				store_info (l_node.left, is_qualified_call)
				store_info (l_node.right, false)
			elseif attached {BRACKET_AS} a_node as l_node then
				store_info (l_node.target, is_qualified_call)
				if attached l_node.operands as params then
					across
						params as c
					loop
						store_info (c.item, false)
					end
				end
			elseif attached {EXPR_CALL_AS} a_node as l_node then
				store_info (l_node.call, is_qualified_call)
			elseif attached {NESTED_EXPR_AS} a_node as l_node then
				store_info (l_node.message, is_qualified_call)
			elseif attached {PARAN_AS} a_node as l_node then
				store_info (l_node.expr, is_qualified_call)
			elseif attached {CONVERTED_EXPR_AS} a_node as l_node then
				store_info (l_node.expr, is_qualified_call)
			end
		end

	find_routine (a_node: ID_SET_ACCESSOR; is_qualified_call: BOOLEAN): PROCEDURE_I
			-- finds routine in a_node in class_base_id
		require
			a_node /= Void
		do
			inspect a_node.routine_ids.count
			when 0 then
					-- local variable -> return Void
			else
				if attached {PROCEDURE_I} System.class_of_id (if is_qualified_call then a_node.class_id else class_base_id end).feature_of_rout_id (a_node.routine_ids.first) as l_r then
						-- routine
					Result := l_r
				else
						-- attribute -> return Void
				end
			end
		end

invariant

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
