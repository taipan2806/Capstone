#
# This is the user-interface definition of a Shiny web application. You can
# run the application by clicking 'Run App' above.
#
# Find out more about building applications with Shiny here:
# 
#    http://shiny.rstudio.com/
#

library(shiny)

shinyUI(
    pageWithSidebar(
        headerPanel('Word Predictor'),
        sidebarPanel(
            radioButtons('inputButtons', 'Select Input Type',
                         c("Sample Tweets"='radioTweet',
                           "Own Phrase"='radioPhrase'), selected = "radioTweet"),
            checkboxInput("detailsCheckbox", label = "Show Details", value = TRUE)
        ),
        mainPanel(
            htmlOutput("instructionTweet"),
            br(),
            uiOutput("userInput"),
            actionButton('predictButton', "Predict next word"),
            br(),
            br(),
            h4(htmlOutput("predictedTitle")),
            h4(htmlOutput("predictedWord")),
            br(),
            br(),
            htmlOutput("rawTitle"),
            htmlOutput("rawInput"),
            htmlOutput("cleanedTitle"),
            htmlOutput("cleanedInput"),
            htmlOutput("matchingTitle"),
            htmlOutput("matchingGram"),
            htmlOutput("frequencyTitle"),
            htmlOutput("frequencyFrequency"),
            htmlOutput("timeTitle"),
            htmlOutput("timeTime")
        )
    )
)  
    

