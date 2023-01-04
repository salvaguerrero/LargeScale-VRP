function ReadData(excel_path)
#Function Description: 
#		Parse the data store in excel_path following the proprietary data structure
#Inputs:
#		path(string): excel path 
#Outputs:
#		data(dict): parsed data from excel_path
#excel_path = "data entry Aceite.xlsm"
	Str_df = DataFrame(XLSX.readtable(excel_path,"Data Struct"))
	Obj_df = DataFrame(XLSX.readtable(excel_path,"Objects"))
	Pro_df = DataFrame(XLSX.readtable(excel_path,"Properties"))
	data = Dict()
	#data["struct"]------------------------------------------------------->
	data["struct"] = Dict()
	for obj in unique(Str_df[!,"Object"])
		data["struct"][obj] = Dict()
		data["struct"][obj]["MultyPro"] = Str_df[ (Str_df.Object .== obj) , :][1,"MultiProperty"] 
		data["struct"][obj]["Parent"]   = size(dropmissing(Obj_df[ (Obj_df.Object .== obj) , :]))[1] != 0
		for pro in Str_df[ (Str_df.Object .== obj) , :][!,"PropertyName"]
			data["struct"][obj][pro] = Str_df[ (Str_df.PropertyName .== pro).&&(Str_df.Object .== obj),:] #ojoooo convert to array
		end
	end

	#data["data"]---------------------------------------------------->
	data["data"] = Dict()
	for obj_ty in unique(Obj_df[!,"Object"])
		data["data"][obj_ty] = Dict()

		if data["struct"][obj_ty]["MultyPro"] == false
			for obj in Obj_df[ (Obj_df.Object .== obj_ty),:][!,"Name"]
				data["data"][obj_ty][obj] = Dict()
				data["data"][obj_ty][obj]["Properties"] = Dict()
				data["data"][obj_ty][obj]["Properties"][ Str_df[ (Str_df.PropertyName .== "Name").&&(Str_df.Object .== obj_ty),:][1,"ModelName"] ] = obj
				data["data"][obj_ty][obj]["Parent"] = Obj_df[ (Obj_df.Name .== obj),:][1,"Parent"]

				for pro in 1:size(Pro_df[ (Pro_df.ObjectName .== obj),:])[1]
					key = Str_df[ (Str_df.PropertyName .== Pro_df[ (Pro_df.ObjectName .== obj),:][pro,"PropertyName"] ),:][1,"ModelName"]		
					data["data"][obj_ty][obj]["Properties"][ key ] = Pro_df[ (Pro_df.ObjectName .== obj),:][pro,"Value"]
				end
			end
		else
			Aux_df = DataFrame(XLSX.readtable(excel_path, obj_ty))
			for obj in 1:size(Aux_df)[1]
				data["data"][obj_ty][Aux_df[obj,"Name"]] = Dict()
				data["data"][obj_ty][Aux_df[obj,"Name"]]["Properties"] = Dict()
				data["data"][obj_ty][Aux_df[obj,"Name"]]["Properties"][ Str_df[ (Str_df.PropertyName .== "Name").&&(Str_df.Object .== obj_ty),:][1,"ModelName"] ] = Aux_df[obj,"Name"]
				data["data"][obj_ty][Aux_df[obj,"Name"]]["Parent"] = Obj_df[ (Obj_df.Name .== Aux_df[obj,"Name"]),:][1,"Parent"]
				for pro in setdiff(names(Aux_df),["Name"])
					key = Str_df[ (Str_df.PropertyName .== pro ),:][1,"ModelName"]
					data["data"][obj_ty][Aux_df[obj,"Name"]]["Properties"][key] = Aux_df[obj,pro]
				end
			end			
		end
	end

	#Save to Json---------------------------------------------------->

	#Build Data------------------------------------------------------>
	data2 = Dict()
	for obj_ty in keys(data["data"])
		for pro in keys(data["struct"][obj_ty])
			if typeof(data["struct"][obj_ty][pro]) == DataFrame

				# format = data["struct"][obj_ty][pro][1,"Format"]
				# if format == "Integer"
				# 	format = Int
				# elseif format == "Float"
				# 	format = Float64
				# elseif data["struct"][obj_ty][pro][1,"Type"] == "Link" 
				# 	format = String
				# elseif format == "Array"
				# 	format  = String
				# elseif format == "String"
				# 	format = String
				# else
				# 	format = String
				# end
				data2[data["struct"][obj_ty][pro][1,"ModelName"]] = Array{Any}(undef, length(data["data"][obj_ty]))
			end
		end
	end


	for obj_ty in keys(data["data"])
		i = 1
		for obj in keys(data["data"][obj_ty])
			for pro in keys(data["struct"][obj_ty])
				if typeof(data["struct"][obj_ty][pro]) == DataFrame
					if data["struct"][obj_ty][pro][1,"ModelName"] in keys(data["data"][obj_ty][obj]["Properties"])

						if data["struct"][obj_ty][pro][1,"Format"] == "Array"
							try 
								data2[data["struct"][obj_ty][pro][1,"ModelName"]][i] =  parse.(Float64, split(chop(  data["data"][obj_ty][obj]["Properties"][data["struct"][obj_ty][pro][1,"ModelName"]]   ; head=1, tail=1), ';'))  
							catch e 
								data2[data["struct"][obj_ty][pro][1,"ModelName"]][i] = Nothing
								println("Error parsing Array: ",pro)
							end
						
						else
							data2[data["struct"][obj_ty][pro][1,"ModelName"]][i] = data["data"][obj_ty][obj]["Properties"][ data["struct"][obj_ty][pro][1,"ModelName"] ]
						end
					elseif data["struct"][obj_ty]["Parent"] != false																#check parent
					
						parent = data["data"][obj_ty][obj]["Parent"]
						if parent !== missing && data["struct"][obj_ty][pro][1,"Inherit"] && data["struct"][obj_ty][pro][1,"ModelName"] in keys(data["data"][obj_ty][parent]["Properties"])
							if data["struct"][obj_ty][pro][1,"Format"] == "Array"
								data2[data["struct"][obj_ty][pro][1,"ModelName"]][i] = parse.(Float64, split(chop( data["data"][obj_ty][parent]["Properties"][data["struct"][obj_ty][pro][1,"ModelName"]]   ; head=1, tail=1), ';')) 
							else
								data2[data["struct"][obj_ty][pro][1,"ModelName"]][i] = data["data"][obj_ty][parent]["Properties"][data["struct"][obj_ty][pro][1,"ModelName"]]
							end
						else
							data2[data["struct"][obj_ty][pro][1,"ModelName"]][i] = Nothing
						end
						
					else																											#default
						
						data2[data["struct"][obj_ty][pro][1,"ModelName"]][i] = Nothing
					
					end
				end
			end
			i = i + 1
		end
	end

		#Links
	for obj_ty in keys(data["data"])
		for pro in keys(data["struct"][obj_ty]) 
			if typeof(data["struct"][obj_ty][pro]) == DataFrame
				if data["struct"][obj_ty][pro][1,"Type"] == "Link"
					for i in 1:length( data2[data["struct"][obj_ty]["Name"][1,"ModelName"]] )
					
						link_obj_ty = data["struct"][obj_ty][pro][1,"Format"]
						data2[data["struct"][obj_ty][pro][1,"ModelName"]][i] = findall(x -> x == data2[data["struct"][obj_ty][pro][1,"ModelName"]][i],    data2[data["struct"][link_obj_ty]["Name"][1,"ModelName"]]     )[1]
					
					end
				end
			end 
		end
	end

	return data2

end