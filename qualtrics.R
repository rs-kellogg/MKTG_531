###########################
# Retrieving Qualtrics Results
############################

# Clear Workspace
rm(list=ls()) 

# set working directory
setwd("~/MKTG_531")

# Install and load necessary libraries
if(!require("qualtRics")) install.packages("qualtRics")
if(!require("dplyr")) install.packages("dplyr")
if(!require("stringr")) install.packages("stringr")
if(!require("rmarkdown")) install.packages("rmarkdown")
if(!require("vtable")) install.packages("vtable")
if(!require("stargazer")) install.packages("stargazer")
if(!require("data.table")) install.packages("data.table")
if(!require("formattable")) install.packages("formattable")
if(!require("vcd")) install.packages("vcd")

library(qualtRics)
library(dplyr)
library(stringr)
library(rmarkdown)
library(vtable)
library(stargazer)
library(data.table)
library(formattable)
library(vcd)

# RUN THIS STEP FIRST TIME ONLY, TO GENERATE ".Renviron" FILE
qualtrics_api_credentials(api_key = "INSERT YOUR API KEY HERE",
                          base_url = "ca1.qualtrics.com",
                          install = TRUE, 
                          overwrite = TRUE)

readRenviron("~/.Renviron")
outpath = "~/MKTG_531"

# Show all surveys 
surveys   <- all_surveys()
surveys

# Select one project by name
myproject <- filter(surveys, name=="Demographics Survey - eLab - 2022 pool refresh")
myproject
myproject$id[1]

#Fetch the survey for that project as .RDS file
mysurvey <- fetch_survey(surveyID = myproject$id[1],
                         save_dir = outpath,
                         force_request = TRUE,
                         verbose = TRUE)
nrow(mysurvey)

# save the approximate day/time of when you downloaded the survey
Sys.time()
download_time <- format(Sys.time(), "%a %b %d %X %Y")
download_message <- paste("I downloaded the", myproject$name, "survey data on:", download_time, sep=" ")
download_message

# save download time to log file
logfile_path <- paste(outpath, "/logfile.text", sep="")
writeLines(download_message, logfile_path)

# Read RDS file into dataframe "mysurvey", and save copy as CSV
rdspath <- paste(outpath, "/", myproject$id[1], ".rds", sep="")
mysurvey <- readRDS(file = rdspath)
csvpath <- paste(outpath, "/", myproject$id[1], ".csv", sep="")
ret <- write.csv(x=mysurvey, file=csvpath)


# Fix problem of spaces in column names!
names(mysurvey) <- str_replace_all(names(mysurvey),c(" "=".", ","=""))
colnames(mysurvey)

### FILTERING
# Eliminate test responses
mysample <- filter(mysurvey, Status=="IP Address")
nrow(mysample)

# Eliminate outliers for response time
quant_duration <- quantile(mysample$`Duration.(in.seconds)`, probs=seq(0,1,.05), na.rm=FALSE, names=FALSE)
quant_duration
mysample <- filter(mysample, `Duration.(in.seconds)` > quant_duration[2])
mysample <- filter(mysample, `Duration.(in.seconds)` < quant_duration[20])
nrow(mysample)

# Proportion of respondents who are female
females <- filter(mysample, Q1.Gender == "Female")
pct_female <- nrow(females) / nrow(mysample)
pct_female


# Create a simple summary table
partyXgender <- table(mysample$Q19.Pol.party, mysample$Q1.Gender, exclude = c(NA,"I do not identify with either of these.", 
                                                                              "I do not identify with any of these"))
partyXgender


# To write results to an external file with rmarkdown & knitr
# you will need to reformat this Rscript as an Rmarkdown file. 
