library(shiny)


# Define UI for plot digitizer
shinyUI(pageWithSidebar(
  # Application title
  headerPanel("Plot digitizer"),
  
  sidebarPanel(
    fileInput("fname",label=h4("Choose Plot File"),accept = c("image/bmp","image/jpeg","image/png")),
    hr(),
    h4("Source Plot"),
    imageOutput("inplot",height="100%"),
    hr(),
    sliderInput("clusters",label=h4("Number of Colors to classify"),2,16,6),
    hr(),
    checkboxGroupInput("colors",h4("Colors to Display"),choices=c("blue","caffo","leek","peng","cyan"),inline=T),
    hr(),
    h4("Save displayed plots as R data file"),
    downloadButton("saveresults")
  ),
  
  mainPanel(
    plotOutput("outplot"),
    hr(),
    h2("Instructions"),
    HTML("This app aids in reproducing collected data from plots which have been saved as images.<br>
    1) Upload a file using the  'choose file' button. The image will show up in the left column. 
        The image can be uploaded from the local file system or from a URL.
        For an example, try the following file from the Python sympy documentation, found via a Google search for 'plot':<br>"),

    h5("http://docs.sympy.org/dev/_images/plot.png"),
    HTML("
    2) The right column will show the results of breaking the input image into its constituent colors
        as identified by the hclust function for hierarchical cluster analysis.<br>
    3) The level at which the cluster map is cut can be adjusted using the slider. Adjust the slider until
         the displayed plots include isolated versions of the data of interest.<br>
    4) The colors displayed can be turned on and off with the checkboxes under 'Colors to Display'.
         By default the most common color in the image (assumed to be the background color) is not displayed.
    4) Clicking the 'Download' button will save the data represented by the displayed plots as an R .rda file.
        Depending on the OS and browser used, this file will most likely end up in a 'Downloads' folder.
         ")
    
  )
))