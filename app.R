library(shiny)
library(shinyjs)
library(DBI)
library(RSQLite)
library(DT)
library(ggplot2)

# UI
ui <- fluidPage(
  useShinyjs(),
  titlePanel("Data Entry Portal"),
  
  # Introduction Section
  div(style = "padding: 10px; background-color: #e0f7fa; border-radius: 8px; margin-bottom: 20px;",
      h4("Introduction"),
      p("Welcome to the Data Entry Portal! This platform is designed to collect and manage health data at Health Facility Level. Health professionals can use this portal to submit data and track progress over time."),
      p("Please log in to start entering the data for various health facilities, including reports on adolescents consuming tablets, reported side effects, and other relevant information.")
  ),
  
  # Style customization
  tags$style(HTML("
    #login_page {
      width: 400px;
      margin: 0 auto;
      padding: 20px;
      background-color: #f7f7f7;
      border-radius: 8px;
      box-shadow: 0px 0px 10px rgba(0, 0, 0, 0.1);
    }
    #main_content {
      margin-left: 10px;
      margin-right: 10px;
      width: calc(100% - 20px);
    }
    .container-fluid {
      padding: 0 !important;
      margin: 0 !important;
    }
    .well {
      margin: 0 !important;
    }
    .shiny-input-container {
      margin-bottom: 10px;
    }
  ")),
  
  # Login Page
  div(id = "login_page", class = "well",
      textInput("username", "Username:"),
      passwordInput("password", "Password:"),
      actionButton("login", "Login", class = "btn-primary"),
      textOutput("login_status")
  ),
  
  # Main Form - Hidden until login
  hidden(div(id = "main_content", class = "container-fluid",
             fluidRow(
               column(3,
                      selectInput("treat_month", "Treating Month:", month.name),
                      selectInput("treat_year", "Treating Year:", as.character(2020:2030)),
                      textInput("health_facility", "Health Facility Name:"),
                      textInput("district", "District:"),
                      textInput("health_incharge", "Health Facility In-Charge:")
               ),
               column(3,
                      numericInput("total_schools", "Total Schools in Catchment Area:", 0, min = 0),
                      numericInput("total_CHVs", "Total CHVs in Catchment Area:", 0, min = 0),
                      numericInput("schools_reporting", "% of Schools Submitting Reports:", 0, min = 0, max = 100),
                      numericInput("CHVs_reporting", "% of CHVs Submitting Reports:", 0, min = 0, max = 100)
               ),
               column(3,
                      numericInput("total_adolescents", "Total Adolescents Registered:", 0, min = 0),
                      numericInput("consumed__1plus", "Adolescents Consuming 1+ Tablets:", 0, min = 0),
                      numericInput("consumed__4plus", "Adolescents Consuming 4-5 Tablets:", 0, min = 0)
               ),
               column(3,
                      numericInput("side_effects_reported", "Total Side Effects Reported:", 0, min = 0),
                      numericInput("adolescents_with_side_effects", "Adolescents With Side Effects:", 0, min = 0),
                      br(),
                      actionButton("submit", "Submit Data", class = "btn-primary"),
                      actionButton("view_data", "View Data", class = "btn-secondary"),
                      downloadButton("download_data", "Download CSV", class = "btn-success"),
                      actionButton("logout", "Logout", class = "btn-danger")
               )
             ),
             hr(),
             DTOutput("data_table"),
             
             # Data Visualizations
             div(id = "visual_section",
                 h4("📊 Data Visualization"),
                 p("Below are some visual insights from the submitted data. CLICK View Data to access"),
                 fluidRow(
                   column(6, plotOutput("bar_plot")),
                   column(6, plotOutput("scatter_plot"))
                 )
             )
  )),
  
  # Developed By Section
  div(style = "text-align: center; padding: 10px; background-color: #e0f7fa; border-radius: 8px; margin-top: 20px;",
      h4("Developed By:"),
      p("This portal was developed by Omondi Robert.")
  )
)

# Server
server <- function(input, output, session) {
  #conn <- dbConnect(RSQLite::SQLite(), "health_data.db")
  db_path <- file.path(getwd(), "health_data.db")
  conn <- dbConnect(RSQLite::SQLite(), db_path)
  if (!dbExistsTable(conn, "_reports")) {
    dbExecute(conn, "
      CREATE TABLE _reports (
        Treat_Month TEXT,
        Treat_Year TEXT,
        Health_Facility TEXT,
        District TEXT,
        InCharge TEXT,
        Total_Schools INTEGER,
        Total_CHVs INTEGER,
        Schools_Reporting REAL,
        CHVs_Reporting REAL,
        Adolescents_Registered INTEGER,
        Consumed_1Plus INTEGER,
        Consumed_4Plus INTEGER,
        Side_Effects_Reported INTEGER,
        Adolescents_Side_Effects INTEGER,
        Coverage_Rate REAL,
        Compliance_Rate REAL
      )
    ")
  }
  
  users <- data.frame(username = "Robert", password = "Robert001")
  user_logged_in <- reactiveVal(FALSE)
  submitted_data <- reactiveVal(data.frame())
  
  # Login
  observeEvent(input$login, {
    if (input$username == users$username && input$password == users$password) {
      user_logged_in(TRUE)
      hide("login_page")
      shinyjs::show("main_content")
      output$login_status <- renderText("")
    } else {
      output$login_status <- renderText("❌ Invalid Username or Password")
    }
  })
  
  # Logout
  observeEvent(input$logout, {
    user_logged_in(FALSE)
    shinyjs::show("login_page")
    shinyjs::hide("main_content")
  })
  
  # Submit Data
  observeEvent(input$submit, {
    if (any(sapply(list(input$treat_month, input$treat_year, input$health_facility, input$district, input$health_incharge,
                        input$total_schools, input$total_CHVs, input$schools_reporting, input$CHVs_reporting,
                        input$total_adolescents, input$consumed__1plus, input$consumed__4plus,
                        input$side_effects_reported, input$adolescents_with_side_effects),
                   function(x) is.null(x) || x == ""))) {
      showNotification("❌ All fields are required", type = "error")
      return()
    }
    
    coverage_rate <- round((input$consumed__1plus / input$total_adolescents) * 100)
    compliance_rate <- round((input$consumed__4plus / input$total_adolescents) * 100)
    
    new_entry <- data.frame(
      Treat_Month = input$treat_month,
      Treat_Year = input$treat_year,
      Health_Facility = input$health_facility,
      District = input$district,
      InCharge = input$health_incharge,
      Total_Schools = input$total_schools,
      Total_CHVs = input$total_CHVs,
      Schools_Reporting = input$schools_reporting,
      CHVs_Reporting = input$CHVs_reporting,
      Adolescents_Registered = input$total_adolescents,
      Consumed_1Plus = input$consumed__1plus,
      Consumed_4Plus = input$consumed__4plus,
      Side_Effects_Reported = input$side_effects_reported,
      Adolescents_Side_Effects = input$adolescents_with_side_effects,
      Coverage_Rate = coverage_rate,
      Compliance_Rate = compliance_rate
    )
    
    dbWriteTable(conn, "_reports", new_entry, append = TRUE, row.names = FALSE)
    showNotification("✅ Data submitted successfully!", type = "message")
    
    updateTextInput(session, "health_facility", value = "")
    updateTextInput(session, "district", value = "")
    updateTextInput(session, "health_incharge", value = "")
    updateNumericInput(session, "total_schools", value = 0)
    updateNumericInput(session, "total_CHVs", value = 0)
    updateNumericInput(session, "schools_reporting", value = 0)
    updateNumericInput(session, "CHVs_reporting", value = 0)
    updateNumericInput(session, "total_adolescents", value = 0)
    updateNumericInput(session, "consumed__1plus", value = 0)
    updateNumericInput(session, "consumed__4plus", value = 0)
    updateNumericInput(session, "side_effects_reported", value = 0)
    updateNumericInput(session, "adolescents_with_side_effects", value = 0)
  })
  
  observeEvent(input$view_data, {
    data <- dbReadTable(conn, "_reports")
    submitted_data(data)
  })
  
  output$data_table <- renderDT({
    datatable(submitted_data(), options = list(
      autoWidth = TRUE,
      scrollX = TRUE,
      paging = TRUE
    ))
  })
  
  output$download_data <- downloadHandler(
    filename = function() {
      paste("health_Data", Sys.Date(), ".csv", sep = "")
    },
    content = function(file) {
      write.csv(submitted_data(), file, row.names = FALSE)
    }
  )
  
  # Visuals
  output$bar_plot <- renderPlot({
    data <- submitted_data()
    if (nrow(data) == 0) return(NULL)
    ggplot(data, aes(x = reorder(Health_Facility, -Adolescents_Registered), y = Adolescents_Registered)) +
      geom_bar(stat = "identity", fill = "#4db6ac") +
      coord_flip() +
      labs(title = "Adolescents Registered by Health Facility", x = "Health Facility", y = "Registered Adolescents") +
      theme_minimal()
  })
  
  output$scatter_plot <- renderPlot({
    data <- submitted_data()
    if (nrow(data) == 0) return(NULL)
    ggplot(data, aes(x = Coverage_Rate, y = Compliance_Rate, color = District)) +
      geom_point(size = 3) +
      labs(title = "Coverage vs Compliance Rate", x = "Coverage Rate", y = "Compliance Rate") +
      theme_minimal()
  })
  
  onStop(function() {
    dbDisconnect(conn)
  })
}

# Run App
shinyApp(ui, server)
