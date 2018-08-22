note
	description: "[
		Represents the possible objects in OO computations.
		ALIAS_OBJECTS are the nodes in the Alias graphs.
	]"
	date: "August, 2018"
	author: "Victor Rivera"


class
	ALIAS_OBJECT

inherit

	ALIAS_VISITABLE
		rename
			variables as attributes,
			is_equal as is_equal_alias_visitable
		select out, is_equal_alias_visitable
		end

	HASHABLE
		rename out as out_hash
		redefine is_equal
		--select is_equal
		end

create
	make,
	make_void

feature {NONE}

	make (a_type: TYPE_A)
		require
			a_type /= Void
		local
			l_obj: TWO_WAY_LIST [ALIAS_OBJECT]
		do
			if attached {LIKE_FEATURE} a_type as like_type then
					-- there's a need to retrieve the right type
				type := like_type.actual_type
			else
				type := a_type
			end

			create predecessors.make (0)
			create predecessors_param.make (0)

			create attributes.make (16)
				-- SPECIAL is a special class to implement Arrays. It does not contain
				-- all implementation as it is implemented in C.
			if type.name.starts_with ("detachable SPECIAL [") or type.name.starts_with ("SPECIAL [") or type.name.starts_with ("V_SPECIAL [")
				or type.conformance_type.name.has_substring ("SPECIAL")
				-- TODO to find a better way to express that
				--if attached {detachable SPECIAL [ANY]} type as special_type then
			then
					-- 'items' is an (non-existing) attribute of class (V_)SPECIAL to represent
					-- all fields of the Array
				create l_obj.make

				if attached type.generics as tg and then tg.count > 0 then -- TODO HW
					l_obj.force (create {ALIAS_OBJECT}.make (type.generics.first.actual_type))
				else
					l_obj.force (create {ALIAS_OBJECT}.make (create {CL_TYPE_A}.make (a_type.system.any_class.compiled_class.class_id)))
				end

				l_obj.last.predecessors.force (create {TWO_WAY_LIST [ALIAS_OBJECT]}.make, create {ALIAS_KEY}.make ("items"))
				l_obj.last.predecessors.at (create {ALIAS_KEY}.make ("items")).force (Current)
				attributes.force (l_obj, create {ALIAS_KEY}.make ("items"))

			end


		ensure
			not attached {LIKE_FEATURE} a_type implies type = a_type
			attributes /= Void
		--	attributes.is_empty
		end

	make_void
		do
			create {VOID_A} type
			create attributes.make (16)
			create predecessors.make (0)
			create predecessors_param.make (0)
		ensure
			--type = Void
			attributes /= Void
			attributes.is_empty
		end

feature {ANY}

	type: TYPE_A
			-- type of the object


	predecessors: HASH_TABLE [TWO_WAY_LIST [ALIAS_VISITABLE], ALIAS_KEY]
			-- list of predecessors

	predecessors_param: HASH_TABLE [TWO_WAY_LIST [ALIAS_VISITABLE], ALIAS_KEY]
			-- list of predecessors that are parameters

feature {ANY}

	add_predecessor (o: ALIAS_VISITABLE; tag: STRING)
			-- adds 'o' as a predecessor of Current (if it is not already a predecessor)
		local
			k: ALIAS_KEY
		do
			create k.make (tag)
			if not predecessors.has (k) then
				predecessors.force (create {TWO_WAY_LIST [ALIAS_VISITABLE]}.make, k)
				predecessors.at (k).force (o)
			else
				if
					across
						predecessors.at (k) as p
					all
						p.item /~ o
					end
				then
					predecessors.at (k).force (o)
				end
			end
		end

	add_local_predecessor (o: ALIAS_OBJECT; tag: STRING)
			-- adds 'o' as a local predecessor of Current (if it is not already a predecessor)
		local
			k: ALIAS_KEY
		do
			create k.make (tag)
			if not predecessors_param.has (k) then
				predecessors_param.force (create {TWO_WAY_LIST [ALIAS_OBJECT]}.make, k)
				predecessors_param.at (k).force (o)
			else
				if
					across
						predecessors_param.at (k) as p
					all
						p.item /~ o
					end
				then
					predecessors_param.at (k).force (o)
				end
			end
		end

	out: STRING_8
		do
			if attached {CL_TYPE_A} type then
				Result := "{" + type.base_class.name + "}"
			else
				Result := "{" + type.name + "}"
			end
		end

	is_string: BOOLEAN
			-- is the ALIAS_OBJECT a STRING?
			--TODO: to find out a better way
		do
			if attached {CL_TYPE_A} type then
				Result := type.base_class.name.starts_with ("STRING")
			end
		end

	set_type (new_type: TYPE_A)
		do
			type := new_type
		end

feature -- From HASHABLE
	hash_code: INTEGER
		do
			Result := tagged_out.hash_code
		end

	is_equal (other: like Current): BOOLEAN
		do
			Result := other.hash_code = hash_code
--			if tracing then
--				print ("other: ")
--				print (other.out2)
--				io.new_line
--				print ("Current: ")
--				print (Current.out2)
--				io.new_line
--			end
		end

feature -- For Debugging purposes

	out2: STRING_8
		do
			if tagged_out.split ('%N').count > 0 then
				Result := tagged_out.split ('%N').at (1)
			else
				Result := tagged_out
			end
		end

invariant
--	type /= Void

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
