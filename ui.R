library(shiny)


# Define UI for plot digitizer
shinyUI(pageWithSidebar(
  # Application title
  headerPanel("Plot digitizer"),
  
  sidebarPanel(
    textInput("fname",label=h4("Plot Input"),value="c:/temp/images.jpg"),
    #actionButton("processFile",label="Process File"),
    imageOutput("inplot",height="100%"),
    sliderInput("clusters","Number of Colors to classify",2,16,6),
    checkboxGroupInput("colors","color list",choices=c("blue","caffo","leek","peng","cyan"),inline=T),
    verbatimTextOutput("noise"),
    actionButton("save","save")
    ),
  
  mainPanel(
    
    plotOutput("outplot")
    
    )
))