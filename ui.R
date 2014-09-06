library(shiny)


# Define UI for plot digitizer
shinyUI(pageWithSidebar(
  # Application title
  headerPanel("Plot digitizer"),
  
  sidebarPanel(
    fileInput("fname",label=h4("Plot Input"),accept = c("image/bmp","image/jpeg","image/png")),
    #actionButton("processFile",label="Process File"),
    imageOutput("inplot",height="100%"),
    sliderInput("clusters","Number of Colors to classify",2,16,6),
    checkboxGroupInput("colors","color list",choices=c("blue","caffo","leek","peng","cyan"),inline=T),
    verbatimTextOutput("noise"),
    downloadButton("saveresults")
  ),
  
  mainPanel(
    
    plotOutput("outplot")
    
  )
))