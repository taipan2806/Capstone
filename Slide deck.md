Word Predictor
========================================================
author: taipan2806
date: March 18, 2017
autosize: true


The Problem
========================================================
This project aims to predict the next word in a Twitter message (Tweet). 

This kind of prediction is part of a discipline called Natural Language Processing (NLP) and it is an active research field.

The approach followed in this project is based on the fact that many words follow each other frequently, making consistent groups, so knowing the first words it is possible to predict next one.

These groups are called n-grams where n is the number of words in the group. A group of 4 words is called tetra-gram or 4-gram.

Approach
========================================================
The key task of the algorithm used in this project is to get the n-gram databases and transform them in a way that the next word can be predicted fast and accurately. The steps to obtain data are:

- Download and data selection as basis for all future steps.
- Cleansing (remove stop and profanity words, punctuation, numbers, etc.)
- Processing to get n-grams (groups of 2, 3, 4 and 5 words)
- Developing prediction algorithm
- Building a shiny app
- Performance and quality checks

Solution
========================================================
Early performance tests showed that queries in data frames are slowly and accuracy can't be improved much. Therefore data were uploaded in a relational database. This approach solves both problems. 

To predict the next word a simple back-off algorithm was implemented. This means that last 4 words of a Tweed are extracted and searched for them in pentagram data. In case of a match, the word with the highest occurrence is used as prediction. If there is no match, last 3 words of the Tweet is searched in tetra-gram. This procedure is repeated until a match is found. In case that there is no match in any n-grams, most frequent word in uni-gram is used as prediction.  

To get an idea of how the predicted word was achieved information about cleansing and matching is also provided. 


Characteristics
========================================================
**Word Predictor** is a shiny app which can be accessed from Internet. It predicts the next word of a phrase. The app is focused on Twitter messages in English. Other texts than Tweets can also be processed - but with some accuracy restrictions.  

Features of **Word Predictor** are:
- easy and convenient use
- fast (~100ms) and accurate predictions (73.2%¹)
- provides additional information about prediction procedure
- possibility to improve accuracy  

¹Based on 1000 randomly selected Tweets in English using 2-, 3-, 4- and 5-grams
Instructions
========================================================
**Word Predictor** is located at <https://taipan2806.shinyapps.io/WordPredictor>.  

To get the next word follow these steps:  

1. Enter a phrase in text field or select a Tweet in drop-down list
2. Press button "Predict next word"
3. Check result
4. Have fun!

Code and data can be found at <https://github.com/taipan2806/Capstone>.
