# Base.jl
This is the core of the mathematical optimization backend. It has 3 main parts:
	+ Data Parsing
		Read the excel file with the data and parse it to the proprietary data structure.
	+ Model Execution
		Execute the mathematical model
	+ Data Output
		Parse the data solution data to a jsson format for the Front End to interprete and display.

Each part is composed by a core function that is located in external files. 
include("julia_libs/data_parsing.jl")
include("julia_libs/data_output.jl")
include("julia_libs/models.jl")

# Data types:
As a general rule of thump the core functions will have as input the variable "data" and dataframes. As Output the will have dataframes or JSON files if they are intentded to be used in the front end.
+ Data Input:
The way to interact with "base-jl" is via the Excel input where all the data is stored.
The Excel data is structured in the following way:
Objects with different properties wich can:
	+Be inherit from a pharent object.
	+Be different types: floats, strings etc
	+Refers to a different Object
Each property is associated to a "label": Object abrebiation + Property abrebiation. (i.e. NodNam, TruNod ) The output object whill be a dictionay with the labels as the keys. Each key will store an array with the data (i.e. data["NodNam"] = ["Node1","Node2"]).The data is store with the same index (i.e. data["NodNam"][1] = "Node1" ,data["NodLng"][1] = "47.931066" Both of them are indexed by a 1 meaning that both properties belong to the same Node object)
For example:
```bash
Object "Tuck"
   ├── Prperty: "Name": "Green tuck 1"
   ├── Prperty: "Vehicle capacity": "10"
   └── Prperty: "Node": "Depo"
Object "Node"
   ├── Prperty: "Name": "Depo"
   ├── Prperty: "Lat": "-99.114677"
   └── Prperty: "Lng": "47.931066"
 ```
 Excel Sheet:

 Important:
	+ The property "Name" is esential.

# models.jl
This files contains the mathematical optimization models:
## greedy_routing
Input: data
Output:
		arcs_df(dataframe): arcs information  DataFrame(Time = [],Vehicle = [],FromLat = [],FromLng = [],ToLat = [],ToLng = [], ColorF=[], ColorT=[]) 	
		nodes_df(dataframe): nodes information (Node_Name=[],Lat=[],Lng=[],Color=[])
