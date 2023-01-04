# Logistic Optimization Solution (prototype)

The goal of this project is to built a mathematical optimization platform for assiting decition makers in logistic companies with the porblems of:
    + Vehicle Routing
    + Workforce Scheduling
    + Future investmenrs 

![alt text](https://raw.githubusercontent.com/salvaguerrero/BBS/master/images/screenshoot1.png)

# Solution structure
This prototipe is designed to run locally. The user uploads an excel with the problem dato to a Web Based django front end. The front end then store the excel in a known path and execute de optimization module. The optimization model then find and optimal solution, after processing the data it store the files in a known path location. Lastly the front end read the output data and display the maps/graphs.

```bash
Main Solution
├── FrontEnd 
│   ├── Data Input: Excel
│   └── Data Output: Django based Web interface with MapBox integration
│ 
└── BackEnd (Julia based)
    ├── Data Parsing module
    ├── Optimization module
    └── Data Exporting module
 ```
 # Technology Stack
 - BackEnd: + Julia
            + Gurobi (optimization solver)
 - FrontEnd:
 	+ Web app: Python (Django) + html + css + js
	+ Maps visualization: Matbox + Deckgl 
 # Flow Chart

 ## 1. Data Input
An excel template is use to populate the different data sets and the solution configuration parameters.
	 
## 2. Model Execution

The file "base.jl" is executed. It reads the data input excel. Firstly the excel data is parsed with the function "ReadData". Secondly the selected optimization module is executed. Lastly the solution of the problem is exporting as a JSON or CSV file in the path: "visualization/model_data"

## 3. Data visualization
A Django based Web application can be executed to visualized the output of the optimization model. The Web app read the data from the path "visualization/model_data" and paint it in a MapBox + DeckGl map.

# Case Study
To test the solution the [**Boston Public Schools Transportation Challenge**](https://www.bostonpublicschools.org/transportationchallenge) will be solved. 
## Problem description
The routing and the scheduling of the fleet of buses serving the Boston Public Schools should be optimized. 20K kids should be assigned to a bus and to a route optimizing for cost 
