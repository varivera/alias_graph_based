class
	TRACING


create
	plot, default_create

feature

	tracing: BOOLEAN = false
			-- should it print?

	os_v: INTEGER = 1

	map_file: STRING
		do
			if os_v = 1 then
				Result := "C:\Users\v.rivera\Desktop\toDelete\resultAlias\map.csv"
			else
				Result := "/home/varivera/Desktop/toDelete/results/map.csv"
			end
		end

	ver1_file: STRING
		do
			if os_v = 1 then
				Result := "C:\Users\v.rivera\Desktop\toDelete\resultAlias\ver1-mq-inherited.csv"
			else
				Result := "/home/varivera/Desktop/toDelete/results/ver1.csv"
			end
		end

	ver1_a_file: STRING
		do
			if os_v = 1 then
				Result := "C:\Users\v.rivera\Desktop\toDelete\resultAlias\ver1-mq-not-inherited.csv"
			else
				Result := ""
			end
		end

	ver2_file: STRING
		do
			if os_v = 1 then
				Result := "C:\Users\v.rivera\Desktop\toDelete\resultAlias\ver2-mq-inherited.csv"
			else
				Result := "/home/varivera/Desktop/toDelete/results/ver2.csv"
			end
		end

	ver2_a_file: STRING
		do
			if os_v = 1 then
				Result := "C:\Users\v.rivera\Desktop\toDelete\resultAlias\ver2-mq-not-inherited.csv"
			else
				Result := "/home/varivera/Desktop/toDelete/results/ver2.csv"
			end
		end

	plot (graph: STRING)
		local
			output_file: PLAIN_TEXT_FILE
		do
			--if tracing then
				if os_v = 1 then
					create output_file.make_open_write ("c:\Users\v.rivera\Desktop\toDelete\testingGraphViz\dd.dot")
					output_file.put_string (graph)
					output_file.close;
				elseif os_v = 2 then
					(create {EXECUTION_ENVIRONMENT}).launch ("echo %"" + graph + "%" | dot -Tpdf | okular - 2>/dev/null");
				end
--			end
		end;

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
