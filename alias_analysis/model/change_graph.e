class
	CHANGE_GRAPH

inherit

	ALIAS_GRAPH
		redefine
			make,
			to_string,
			collect_aliasing_info
		end

create
	make

feature -- Initialisation (Redefinition)

	make (a_routine: PROCEDURE_I)
		do
			Precursor (a_routine)
			create change_field.make (0)
			last_added := ""
			create change_getting_alias.make (0)
		end

feature -- Redefinition

	to_string: STRING_8
		do
			print ("%N")
			across
				change_field as k
			loop

				-- print ("("+k.key  + "," + "{" + k.item.base_class.name + "}" + "), ")
			end
			print ("%N")
			Result := Precursor + "%N%NChange Calculus%N%N"
			across
				change_field as change
			loop
				if attached change.item as type then
					Result := Result + "{" + type.base_class.name + "}." + change.key
				else
					Result := Result + "{NONE}." + change.key
				end
				Result := Result + "%N"
			end
		end

	collect_aliasing_info (a_cur_node: ALIAS_VISITABLE; a_info: STRING_8)
		local
			sub: STRING
		do
			print_vals
			print ("Info collect_aliasing_info:%N")
			print ("type a_cur_node: " + (if attached {ALIAS_ROUTINE} a_cur_node as a then "ALIAS_ROUTINE%N"
			elseif attached {ALIAS_OBJECT} a_cur_node as a then "ALIAS_OBJECT%N"
			else
				"ALIAS_VISITABLE%N"
			end))

			print ("a_info: " + a_info + "%N%N")
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
						if change_getting_alias.count >= 1 then
							print ("%N c.item: " + c.item)
							io.new_line
							sub := c.item.twin
							print ("type: " + change_getting_alias.item.type.base_class.name)
							io.new_line
							--sub.replace_substring_all (change_getting_alias.item.type.base_class.name, "")
							if sub.has_substring (change_getting_alias.item.type.base_class.name) then
								sub.replace_substring_all ("{"+change_getting_alias.item.type.base_class.name+"}.", "")
							else
								sub.replace_substring_all ("{}.", "")
							end

							print ("sub: " + sub)
							io.new_line
							print ("c.item: " + c.item)
							io.new_line

							if change_field.has (sub) then
								change_getting_alias.item.need := True
							else
								change_getting_alias.item.fields.force (sub)
							end
						end
						--if change_getting_alias.count >= 1 and then not change_field.has (c.item) then
							--change_field.put (new: G, key: K)
						--end
						a_info.append (c.item)
					end
				end
				if attached {ALIAS_ROUTINE} a_cur_node as l_ar then
					collect_aliasing_info (l_ar.current_object, a_info)
				end
				across
					a_cur_node.variables as c
				loop

					print ("%Nactual var: " + c.key + "%N")
							-- there might need checking for aliases
					if attached {ALIAS_OBJECT} a_cur_node as node then
						change_getting_alias.put ([False, node.type, create {ARRAYED_LIST [STRING]}.make (0)])
					else
						change_getting_alias.put ([False, Void, create {ARRAYED_LIST [STRING]}.make (0)])
					end
					collect_aliasing_info (c.item, a_info)
						-- update change_field
					if change_getting_alias.item.need then
							-- there is alias information
						across
							change_getting_alias.item.fields as fields
						loop
							--change_field.force (change_getting_alias.item.type, fields.item)
						end
					end
					change_getting_alias.remove
				end
			end
		end

feature -- Storing

	add_field (name: STRING)
		do
			if not change_field.has (name) then
				change_field.put (Void, name)
				last_added := name
			end
		end

	update_type_field (name: STRING; type: CL_TYPE_A)
		require
			has_field (name)
			void_type_field (name)
		do
			change_field.replace (type, name)
		end

feature --Query

	has_field (name: STRING): BOOLEAN
		do
			Result := change_field.has (name)
		end

	void_type_field (name: STRING): BOOLEAN
		do

			Result := attached change_field.at (name)
		end

	last_added : STRING
			-- last change field added (needed to check which fields are aliased to it)

feature {NONE} -- Storing Change Fields

	change_field: HASH_TABLE [detachable CL_TYPE_A, STRING]
			-- 'change_fields' stores the fields that are being changed by the routine.
			-- key: variable name
			-- value: Type

	change_getting_alias: ARRAYED_STACK [TUPLE [need: BOOLEAN; type:CL_TYPE_A; fields: ARRAYED_LIST[STRING]]]
			-- 'change_getting_alias' is used to check a class field needs to be checked for aliases in order to
			--	be put in change_field

	alias_to (a_cur_node: ALIAS_VISITABLE; a_cur_path: TWO_WAY_LIST [TUPLE [av: ALIAS_VISITABLE; name: STRING]]; a_info: STRING_8)
		require
			a_cur_node /= Void
			a_cur_path /= Void
			a_info /= Void
		local
			l_cycle_head: like a_cur_path
		do
			print_vals
			print ("Info compute_aliasing_info:%N")
			print ("type a_cur_node: " + (if attached {ALIAS_ROUTINE} a_cur_node as a then "ALIAS_ROUTINE%N"
			elseif attached {ALIAS_OBJECT} a_cur_node as a then "ALIAS_OBJECT%N"
			else
				"ALIAS_VISITABLE%N"
			end))
			print ("a_cur_path: %N")
			across
				a_cur_path as e
			loop
				print (">> " + e.item.name + "%N")
			end
			print ("a_info: " + a_info + "%N%N")
			a_cur_node.add_visiting_data (path_to_string (a_cur_path))
			if not a_cur_node.visited then
				a_cur_node.visited := True
				if attached {ALIAS_ROUTINE} a_cur_node as l_ar then
					compute_aliasing_info (l_ar.current_object, a_cur_path, a_info)
				end
				across
					a_cur_node.variables as c
				loop
					a_cur_path.extend ([a_cur_node, c.key])
					compute_aliasing_info (c.item, a_cur_path, a_info)
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

;

note
	copyright: "Copyright (c) 1984-2016, Eiffel Software"
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
