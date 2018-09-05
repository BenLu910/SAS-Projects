# SAS Projects
Code written during my summer internship at SAS (2018)

Table of Contents
=================

   * [SAS Projects](#SAS-Projects)
       * [Problem Description](#problem-description)
       * [Project 1: Excel and Viya](#project-1)
       * [Project 2: Data Pipelines using SAS](#project-2)
       * [Project 3: Employee dashboards using JMP](#project-3)

## Problem Description

In the summer of 2018, I interned at SAS Headquarters in Cary, NC. I worked in the testing division within the main research building on the Cary campus. My team comprised of testers, specifically User Experience (UX) specialists. Their primary role is to ensure that user interfaces (UI) within SAS products follow UX guidelines. Creating and overseeing defects are a big part of upholding this role. As a data engineering intern, I worked to create reporting tools and dashboards for my team to use to explore their defects. The 3 projects I have included in this repository showcase my progression through the summer and show some images of the tools that I created.

## Project 1

At the beginning of the summer, I started by familiarizing myself with the database of defects stored on a SAS/SHARE server. I did this by importing data from an API called DARTS. I exported these datasets to Excel and cleaned them using Excel formulas. Lastly, I moved this data to SAS Viya and created reports.

### Data Aggregation and Cleaning Using DARTS and Excel
* Initially began data aggregation by downloading filtered data from DARTS.
* Imported the data to Excel and used functions and formulas to clean data.
* The options with Excel were limited, but improved understanding of Defects.

Here are some examples excel formulas that I used:
![Excel Formulas](https://i.imgur.com/nPBPKyg.png)

### Constructing Interactive Reports Using SAS Viya 3.4
* Transferred cleaned Excel spreadsheets into CAS Tables using Data Explorer.
* Transformed and formatted CAS table variables using Plans in Data Studio.
* Constructed interactive reports using Visual Analytics.
* Focused on defect completion time and virulence grouped by other variables
* Analyzed distributions of other important variables. (E.g. priority and status)

![SAS Viya](https://i.imgur.com/B1dMRKv.png)

## Project 2
Needless to say the process from project 1 was very tedious. My manager also asked me to create reports that could be refreshed daily. For my second, I setup the infrastructure for a data pipeline so I can get data that is consistently updated.

### Developing SAS Code to Access Defects the SAS/SHARE Server 
* Began learning and practicing SAS with Programming Essentials 1 and 2.
* After some practice, I began working with the Defects SAS/SHARE server.
* I developed a simple DATA step to aggregate defects data for my manager.
* Over time, I added a lengthy MERGE step to grab data from many tables.
* Used this code to replace the use of DARTS

This is the main code I used to grab the initial data set from the SAS/SHARE server:
![SAS Data Step](https://i.imgur.com/QCoFRwm.png)

This is a snippet of the code I ran next to grab supplementary data from related tables:
![SAS Merge Step](https://i.imgur.com/95CIy5d.png)

After I ran both of these data steps I had ALL the information on every defect that was included in the "WHERE" statement. I ran this code with batch files periodically on a Windows Virtual Machine to grab new defect data and update defect links every 15 minutes and then stored it on my own SAS/SHARE server. [Full SAS code found here](https://github.com/BenLu910/SAS-Projects/blob/master/DefectData.sas)
![Update Graphic](https://i.imgur.com/huoLhVm.png)

I now had access to a data set with ~1.2 million defects that spanned the past 9 years. It had records of all the data I would possibly need, such as the defects update history and it's links to other defects. 

## Project 3
Finally, once I had a reliable data source I began to build an application that my managers could use to explore their defects. I used my data pipeline along with JMP to create a dashboard. JMP is a tool created by SAS and has it's own language called JSL. This is a scripting language that allowed me to query the data pipeline and create an application all in one JMP file.

### Creating a Defects Application using JMP and JSL:
* Coded a JSL prompt that generates a SQL Query from selection.
* Accessed the Data Pipeline using generated Query and SAS Connect.
* Created an employee dashboard using JMP Application Builder to display this data.
* Coded a window embedded within the app to display data, filters, and a control panel.
* Embedded the prompt within the JMP App to fully combine the two.


The JSL prompt used the user's input to generate a SQL query as a string. After the query was generated, it was used to query the data pipeline and using this data the application could be launched. [JSL Prompt code found here](https://github.com/BenLu910/SAS-Projects/blob/master/QueryPrompt.jsl)


Here are a collection of screenshots showcasing the application:
[Full application code found here](https://github.com/BenLu910/SAS-Projects/blob/master/JMPApplication.jsl)

## Application Window 1 - Graphs
This application consisted of two windows. The first held all of the graphs for the data the query generated.

### Application Tab 1
The is tab showcases an overview of the defects, it has graphs that display the distributions of vital defect variables.
![JMP App Tab 1](https://i.imgur.com/54r59Xf.png)
### Application Tab 2

This tab explores the effect of priority on the completion time of a defect. 
![JMP App Tab 2](https://i.imgur.com/TAxJq9G.png)
### Application Tab 3

This tab explores the completion time of defects based on different product components.
![JMP App Tab 3](https://i.imgur.com/4rITTYN.png)

## Application Window 2 - Data
The second window of the application shows the data table resulting from the query.

### Defect Data Table
This is a standard data table, but has two special links in each row. One is used to open the defect's web page and the other opens an analysis of the defect's past.
![JMP App Data Table](https://i.imgur.com/yik7hdV.png)

### Defect History Analysis
When the historical analysis is launched a third window is created and an analysis of a defect's history is generated. 

Here is an example result: [Analysis code found here](https://github.com/BenLu910/SAS-Projects/blob/master/HistoryAnalysis.jsl)
![JMP App History Analysis](https://i.imgur.com/5dxjMUw.png)




