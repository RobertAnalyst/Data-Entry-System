# Data-Entry-System
# 📊 Data Entry Portal - Health Facility Reporting System

Welcome to the **Data Entry Portal**, a web-based application built using R and Shiny for collecting, managing, and visualizing health data at the Health Facility level.
![Map showing modern contraceptive use across Kenyan counties](ContraceptivePLOT.png)
Access the Live Portal 🌐 [HERE](https://omondirobert.shinyapps.io/DataEntrySystem/)

## 🌟 Overview

This application enables health professionals to securely log in and submit important metrics related to adolescent health programs — such as the number of adolescents who consumed tablets, any reported side effects, and facility-specific indicators. The app also provides a data visualization dashboard to support tracking and decision-making.

---

## 🚀 Features

- 🔐 **Login Authentication** to secure data access  
- 📝 **Dynamic Data Entry Form** tailored for health facility reports  
- 📈 **Interactive Data Visualization** (bar and scatter plots)  
- 📂 **Data Table View and CSV Export** functionality  
- 💾 **SQLite Database Integration** for backend storage  
- 🎨 **Custom UI Styling** for improved user experience  

---

## 📋 Technologies Used

- **R** and **Shiny** for web application development  
- **shinyjs** for dynamic UI components  
- **DBI** and **RSQLite** for database operations  
- **DT** for interactive tables  
- **ggplot2** for visualizations

---

## 🧰 Prerequisites

Make sure you have the following R packages installed:

```r
install.packages(c("shiny", "shinyjs", "DBI", "RSQLite", "DT", "ggplot2"))
```

---
## 🔧 How to Run the App
- Clone this repository or copy the app.R file.

- Ensure all required packages are installed.

- Run the app from your R console:
```r
shiny::runApp("path/to/app.R")
```
---
## 🛠️ App Structure
### 🔐 Login Page
Users must log in with a valid username and password to access the data entry form. (Default credentials: username = Robert, password = Robert001)

### 📝 Data Entry Form
The form collects the following information:

- Treating Month & Year

- Health Facility & District

- In-Charge Officer

- School and HSA coverage stats

- Adolescents reached and tablet consumption

- Side effects reported

### 📊 Visualization Dashboard
- Bar Plot showing the number of adolescents registered per health facility.

- Scatter Plot showing the relationship between Coverage Rate and Compliance Rate by district.

### 📁 Data Handling
- Data is stored in a local SQLite database (health_data.db)

- Data can be exported as a CSV file via the “Download CSV” button

### 📄 Database Table Schema
Table Name: _reports

| Column                     | Type     |
|---------------------------|----------|
| Treat_Month               | TEXT     |
| Treat_Year                | TEXT     |
| Health_Facility           | TEXT     |
| District                  | TEXT     |
| InCharge                  | TEXT     |
| Total_Schools             | INTEGER  |
| Total_HSAs                | INTEGER  |
| Schools_Reporting         | REAL     |
| HSAs_Reporting            | REAL     |
| Adolescents_Registered    | INTEGER  |
| Consumed_1Plus            | INTEGER  |
| Consumed_4Plus            | INTEGER  |
| Side_Effects_Reported     | INTEGER  |
| Adolescents_Side_Effects  | INTEGER  |
| Coverage_Rate             | REAL     |
| Compliance_Rate           | REAL     |

---

## 👨‍💻 Developed By
Omondi Robert

---



