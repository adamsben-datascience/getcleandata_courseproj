## Course Project for Getting & Cleaning Data
## jhu data scient course

##welcome to my code for this assignment!  Since you're going to be reading
## it, I might as well provide you with the most accurate and complete 
## comments possible.

##step one: cleanup.  Check to make sure all the variables in the code
##          are removed.  Want to make sure if running this code a second
##          time, nothing is left over to mess up the code.
if (exists("activities"))        rm(activities)
if (exists("completeData"))      rm(completeData)
if (exists("fullAct"))           rm(fullAct)
if (exists("fullData"))          rm(fullData)
if (exists("fullSubj"))          rm(fullSubj)
if (exists("interestingData"))   rm(interestingData)
if (exists("measurements"))      rm(measurements)
if (exists("testAct"))           rm(testAct)
if (exists("testSubj"))          rm(testSubj)
if (exists("testData"))          rm(testData)
if (exists("trainAct"))          rm(trainAct)
if (exists("trainSubj"))         rm(trainSubj)
if (exists("trainData"))         rm(trainData)
if (exists("columnsOfInterest")) rm(columnsOfInterest)
if (exists("dataPath"))          rm(dataPath)
if (exists("testPath"))          rm(testPath)
if (exists("trainPath"))         rm(trainPath)
if (exists("i"))                 rm(i)
if (exists("loop_df"))           rm(loop_df)
if (exists("tidyData"))          rm(tidyData)

#step 2: require!!  whew! now that cleanup is done, make sure we have
##       the needed packages.  I'ma assume you have the packages installed.
require('plyr')
require('dplyr')
require('data.table')

##step 3: read in the data.  Another assumption here.
##        I'm assuming the data files are downloaded from here:
##        https://d396qusza40orc.cloudfront.net/getdata%2Fprojectfiles%2FUCI%20HAR%20Dataset.zip
##        they are unzipped, and they are in a subdirectory called "data"
##        just off the current working directory.
##        if they aren't, you only need to edit the dataPath variable.

dataPath <- file.path("./data","UCI_HAR_Dataset")
testPath <- file.path(dataPath,'test')
trainPath <- file.path(dataPath,'train')

## so here, there are 3 files per set: data, subjects, and activities.
##          there are 2 sets: train and test
##          let's get the data!!
trainData <- read.table(file.path(trainPath,'X_train.txt'),header=F)
trainSubj <- read.table(file.path(trainPath,'subject_train.txt'),header=F)
trainAct  <- read.table(file.path(trainPath,'y_train.txt'),header=F)

testData <- read.table(file.path(testPath,'X_test.txt'),header=F)
testSubj <- read.table(file.path(testPath,'subject_test.txt'),header=F)
testAct  <- read.table(file.path(testPath,'y_test.txt'),header=F)

## in addition to the two datasets, there are labels for the activities
##             and the headings/column labels
activities <- read.table(file.path(dataPath,'activity_labels.txt'),header=F)
measurements <- read.table(file.path(dataPath,'features.txt'),header=F)

## step 4: unite!!  Now that we have the data, let's mush it together.
##         first, put each of the 3 bits of data for the 2 sets
##         together.  rBind will put the rows of train on top of the 
##         rows of test, in each of the 3 bits below.
fullData <- rbind(trainData,testData)
fullSubj <- rbind(trainSubj,testSubj)
fullAct  <- rbind(trainAct ,testAct)

## let's name things correctly.  Measurements have 2 columns, so set the 
##   full data to the 2nd column.  The others I picked names for.  Meh.
##   They are hard-coded strings, so could be really anything.
names(fullData) <- measurements$V2
names(fullSubj) <- c('subject_of_experiment')
names(fullAct)  <- c('activity_performed')

## ok... here's a tricky bit.  activities[] has the NAMES of the activities
##   that each person did.  fullAct[] has the CODES.  I want to replace a 1
##   with WALKING, and a 2 with STANDING (or whatever the NAME/CODE pairs
##   are).  So this code does exactly that.  first column of fullAct matches
##   with activities row, and then replaces the string found.
fullAct[,1] = activities[fullAct[,1], 2]

## so finally, use cBind to put the columns together of the full data set.
##   I decided to to put subject id & activity performed up front.  I
##   figure they are the most important variables.
completeData <- cbind(fullSubj,fullAct,fullData)

## step 5: subset!  The assignment calls for using only a few of the columns.
##         there are 561 friggin' variables!  We should only use the ones
##         with MEAN or STD in the variable name.  I use GREP to find
##         the ones we want, and make a logical array of the ones that match.
columnsOfInterest <- grep(".*Mean.*|.*Std.*", names(completeData), ignore.case=TRUE)
## and include the first two!!
columnsOfInterest <- c(1,2,columnsOfInterest)

## now use that subset to make sure we have only those we want.
interestingData <- subset(completeData,select=columnsOfInterest)

##step 6: cleanup.  The colummn names have some weird codes, including
##        t, f, Acc, & similar.  we're using gsub, with REGEXes to match 
##        and replace.
names(interestingData)<-gsub("^t", "time", names(interestingData))
names(interestingData)<-gsub("^f", "frequency", names(interestingData))
names(interestingData)<-gsub("Acc", "Accelerometer", names(interestingData))
names(interestingData)<-gsub("Gyro", "Gyroscope", names(interestingData))
names(interestingData)<-gsub("Mag", "Magnitude", names(interestingData))
names(interestingData)<-gsub("BodyBody", "Body", names(interestingData))
##        above, we look for a T at the beginning of the line.  Needed
##        so we don't replace a random T with TIME.. we'd end up with
##        magniTIMEude.  However, there are a few columns that have 
##        a name like "mean(t"  that needs to be replaced.
names(interestingData)<-gsub("\\(t", "\\(time", names(interestingData))

##step 7: TIDY!!  so, now it gets fun.

## change subject to factor.
interestingData$subject_of_experiment <- as.factor(interestingData$subject_of_experiment)
## make sure interestedingData is a data table.
interestingData <- data.table(interestingData)

## use aggregate to summarize by subject & activity, and then average it all up.
tidyData <- aggregate(. ~subject_of_experiment + activity_performed, interestingData, mean)
tidyData <- tidyData[order(tidyData$subject_of_experiment,tidyData$activity_performed),]

## the end result looks like this:
##   Subject  Activity  timeBodyAccelerometer-mean()-x
##   1        LAYING    0.2215982
##   1        Sitting   0.2612376
##  and so on, for 85 columns that way >>>>>>
##             and 178 rows down -------v

## last step: write it out.
write.table(tidyData,
            file.path('./data','second_independent_tidy_data_set.txt'),
            sep='\t',
            row.names=F
            )
## that's it!  all done.