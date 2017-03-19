#
# This is the server logic of a Shiny web application. You can run the 
# application by clicking 'Run App' above.
#
# Find out more about building applications with Shiny here:
# 
#    http://shiny.rstudio.com/
#

library(shiny); library(NLP);library(tm);library(stringi);library(magrittr);library(RWeka);library(ggplot2);library(dplyr);library(DBI); library(RMySQL)

#profanity words
con <- dbConnect(drv = RMySQL::MySQL(), dbname = "XXXXX", host = "XXXXX", user = "XXXXX", password = "XXXXX")
query <- sprintf("SELECT profanity FROM profanity;")
rs <- dbGetQuery(con, query)
profanityWords <- as.vector(unlist(rs))
query <- sprintf("SELECT tweet FROM tweet ORDER BY ID asc;")
rs <- dbGetQuery(con, query)
sampleTweets <- as.vector(unlist(rs))
rm(rs)

cleanInput <- function(line) {
    line <- iconv(line, from = "latin1", to = "ASCII", sub = "")
    line <- tolower(line)
    line <- removePunctuation(line)
    line <- removeNumbers(line)
    line <- removeWords(line, profanityWords)
    line <- removeWords(line, stopwords("english"))
    line <- stripWhitespace(line)
    line <- trimws(line, "b")
}

predictWord <- function (input){
    #Clean input -> only relevant words
    cleanedInput <- cleanInput(input)
    
    #Tokenize
    spaces <- gregexpr(" ", cleanedInput)
    words <- sort(unlist(spaces), decreasing = TRUE)
    numWords <- ifelse(words != -1, length(words)+1, 1)
    numWords <- numWords[1]
    
    #Assign search words
    if(numWords >= 4){
        wordLast <- substr(cleanedInput, words[1]+1, 1000)
        word2ndLast <- substr(cleanedInput, words[2]+1, words[1]-1)
        word3rdLast <- substr(cleanedInput, words[3]+1, words[2]-1)
        word4thLast <- substr(cleanedInput, 1, words[3]-1)
        search4 <- paste(word4thLast, word3rdLast, word2ndLast, wordLast, sep = " ")
        search3 <- paste(word3rdLast, word2ndLast, wordLast, sep = " ")
        search2 <- paste(word2ndLast, wordLast, sep = " ")
        search1 <- wordLast
    } else if(numWords == 3){
        wordLast <- substr(cleanedInput, words[1]+1, 1000)
        word2ndLast <- substr(cleanedInput, words[2]+1, words[1]-1)
        word3rdLast <- substr(cleanedInput, 1, words[2]-1)
        search3 <- paste(word3rdLast, word2ndLast, wordLast, sep = " ")
        search2 <- paste(word2ndLast, wordLast, sep = " ")
        search1 <- wordLast
        search4 <- "#@|#@|"
    } else if(numWords == 2){
        wordLast <- substr(cleanedInput, words[1]+1, 1000)
        word2ndLast <- substr(cleanedInput, 1, words[1]-1)
        search2 <- paste(word2ndLast, wordLast, sep = " ")
        search1 <- wordLast
        search3 <- "#@|#@|"
        search4 <- "#@|#@|"
    } else{
        wordLast <- substr(cleanedInput, 1, 1000)
        search1 <- wordLast
        search2 <- "#@|#@|"
        search3 <- "#@|#@|"
        search4 <- "#@|#@|"
    }
    
    #Check weather search2 is in trigram
    query4 <- sprintf("SELECT * FROM pentagram WHERE search = '%s' ORDER BY frequency desc LIMIT 1", search4)
    query3 <- sprintf("SELECT * FROM tetragram WHERE search = '%s' ORDER BY frequency desc LIMIT 1", search3)
    query2 <- sprintf("SELECT * FROM trigram WHERE search = '%s' ORDER BY frequency desc LIMIT 1", search2)
    query1 <- sprintf("SELECT * FROM bigram WHERE search = '%s' ORDER BY frequency desc LIMIT 1", search1)
    
    prediction4 <- dbGetQuery(con, query4)
    prediction3 <- dbGetQuery(con, query3)
    prediction2 <- dbGetQuery(con, query2)
    prediction1 <- dbGetQuery(con, query1)
    
    #Evaluate results
    if(nrow(prediction4) > 0){
        predictedWord <- prediction4$prediction
        predictedFrequency <- prediction4$frequency
        matching <- "5-gram"
    } else if(nrow(prediction3) > 0){
        predictedWord <- prediction3$prediction
        predictedFrequency <- prediction3$frequency
        matching <- "4-gram"
    } else if(nrow(prediction2) > 0){
        predictedWord <- prediction2$prediction
        predictedFrequency <- prediction2$frequency
        matching <- "3-gram"
    } else if(nrow(prediction1) > 0){
        predictedWord <- prediction1$prediction
        predictedFrequency <- prediction1$frequency
        matching <- "2-gram"
    } else{
        predictedWord <- "im"
        predictedFrequency <- "158565"
        matching <- "No match at all -> most frequent word in unigram"
    }
    #Evaluate prediction process
    wordToFind <- wordLast
    success <- ifelse(wordLast == predictedWord && predictedFrequency > 0, "Success", "Fail")
    results <- list(input, cleanedInput, predictedWord, predictedFrequency, cleanedInput, "10-150ms", matching, wordLast, success)
    names(results) <- c("Input", "Cleaned input", "Prediction", "Frequency", "Relevant Words", "Processing time", "Matching", "Word to predict", "Success")
    isolate(saveRDS(results, "result.RDS"))
    
    return (predictedWord)
}

# Define server logic required to draw a histogram
shinyServer(function(input, output,session) {
    helperTextTweet <- "<b>Notice</b><br>For your convenience, 5 phrase samples without last word have been prepared.<br>All other Tweets remain unchanged.<br>Just select a Tweet and press button below...<br>Enjoy!"
    helperTextPhrase <- "<b>Notice</b><br>Enter your phrase in the textbox and press button below... <br>Have fun!"
    output$instructionTweet <- renderText(ifelse(input$inputButtons == "radioPhrase", helperTextPhrase, helperTextTweet))
    output$userInput <- renderUI({
        if (input$inputButtons == "radioTweet") {
            selectInput("userInput", "Select a Tweet", as.list(sampleTweets), width = "100%")
        }
        else {
            textInput("userInput", "Enter a phrase", "", width = "100%")
        }
    })

    
    predictedWord <- eventReactive(input$predictButton, {
        predictWord(input$userInput)
    })
    rawInput <- eventReactive(input$predictButton, {
        res <- readRDS("result.RDS")
        unlist(res)[1]
    })    
    predictedOutput <- eventReactive(input$predictButton, {
        res <- readRDS("result.RDS")
        unlist(res)[3]
    })    
    predictedFrequency <- eventReactive(input$predictButton, {
        res <- readRDS("result.RDS")
        unlist(res)[4]
    })    
    ngram <- eventReactive(input$predictButton, {
        res <- readRDS("result.RDS")
        unlist(res)[7]
    })    
    proTime <- eventReactive(input$predictButton, {
        res <- readRDS("result.RDS")
        rawInput <- unlist(res)[6]
    })    
    cleaned <- eventReactive(input$predictButton, {
        res <- readRDS("result.RDS")
        unlist(res)[2]
    })
    
    cancel.onSessionEnded <- session$onSessionEnded(function() {
        dbDisconnect(con)
    })
    
    
    output$predictedTitle <- renderText("<font color=\"#0000CC\"><b>Predicted Word:</b></font>")
    output$predictedWord <- renderText(ifelse(input$predictButton, predictedWord(), ""))
    output$rawTitle <- renderText(ifelse(input$detailsCheckbox && input$predictButton, "<font color=\"#0000CC\"><b>You entered or selected:</b></font>", ""))
    output$rawInput <- renderText(ifelse(input$detailsCheckbox && input$predictButton, rawInput(), ""))
    output$cleanedTitle <- renderText(ifelse(input$detailsCheckbox && input$predictButton, "<font color=\"#0000CC\"><b>Cleaned input:</b></font>", ""))
    output$cleanedInput <- renderText(ifelse(input$detailsCheckbox && input$predictButton, cleaned(), ""))
    output$matchingTitle <- renderText(ifelse(input$detailsCheckbox && input$predictButton, "<font color=\"#0000CC\"><b>Matched in:</b></font>", ""))
    output$matchingGram <- renderText(ifelse(input$detailsCheckbox && input$predictButton, ngram(), ""))
    output$frequencyTitle <- renderText(ifelse(input$detailsCheckbox && input$predictButton, "<font color=\"#0000CC\"><b>n-gram frequency:</b></font>", ""))
    output$frequencyFrequency <- renderText(ifelse(input$detailsCheckbox && input$predictButton, predictedFrequency(), ""))
    output$timeTitle <- renderText(ifelse(input$detailsCheckbox && input$predictButton, "<font color=\"#0000CC\"><b>Processing time:</b></font>", ""))
    output$timeTime <- renderText(ifelse(input$detailsCheckbox && input$predictButton, proTime(), ""))
    
    
})
