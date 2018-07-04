face_selection_algorithm <- function() {
  setwd("~/face_selection_algorithm")
  source("helper_functions.R")
  library(ggplot2)
  
  if(require("xlsx")){ } else {
    print("trying to install package 'xlsx' (to write to .xls file)")
    install.packages("xlsx")
    if(require("xlsx")){
      print("xlsx installed and loaded")
    } else {
      stop("could not install xlsx")
    }
  }
  
  dormA_roster = read.csv('dormA_fall_roster.csv', header=T)
  dormB_roster = read.csv('dormB_fall_roster.csv', header=T)
  full_roster = rbind(dormA_roster, dormB_roster)
  

  prescanFilename = 'PreScan_Ratings_anon.csv'
  headers = read.csv(prescanFilename, header=T, nrows=1)
  surveyFileRaw = read.csv(prescanFilename, header=F, skip=2, col.names=colnames(headers))[,c(13:986)]
  
  participantName <- readline("Which participant do you want to process? \n (Type in the first and last name, or PID): \n")  
  if(!participantName %in% surveyFileRaw$Name & !participantName %in% full_roster$ID) { # not found
    print("Name or ID not found. Script is exiting.\n")
  } else {
    surveyFile = replaceNamesWithIDUsingRoster(surveyFileRaw, full_roster, listOfColumns=c(2))
    if(participantName %in% surveyFileRaw$Name) {
      rowNumber = which(participantName == surveyFileRaw$Name) 
    } else { # inputted ID number
      rowNumber = which(participantName == surveyFile$Name)
    }
    participantID = surveyFile$Name[rowNumber]
    cat(paste(participantName, " is ID number: ", participantID, "\n", sep=""))
    
    # XXX_1 : picture
    # XXX_2 : have you ever talked or interacted. 1 = yes, 2 = no, 3 = photo of me
    # _____ : picture again
    # XXX_3 : how close
    # XXX_4 : how much time
    # XXX_5 : how happy
    # XXX_6 : how much do you like
    # XXX_7 : how empathetic
    # XXX_8 : how attractive
    # XXX_9 : how much does this person like you?
    
    # 2 questions: just close and liking (XXX_3; XXX_6)
    # 4 questions: close and liking (XXX_3; XXX_6) + happy, empathetic (XXX_5; XXX_7)
    
    # #for(rowNumber in 1:nrow(surveyFile)) {
    # #rowNumber = 2 # Use this line if you want to do individual participants. Replace with which participant you want to see
    
    if(surveyFile$Dorm[rowNumber]==1) { # dormA
      numMales = 24
      numFemales = 22
      startingNumber = 5
      friendList_4questions = data.frame(friendID = c(201:246), closeness = rep(0, 46))
    } else { # dormB
      numMales = 28
      numFemales = 23
      startingNumber = 5 + 460
      friendList_4questions = data.frame(friendID = c(301:351), closeness = rep(0, 51)) 
    }
    noInteractionList = c()
    numPeople = numMales + numFemales
    count = 0
    for(friend in c(1:numPeople)) {
      currentColumnNumber = (startingNumber + (friend-1)*10)
      friendID = strtoi(substr(colnames(surveyFile)[currentColumnNumber], start=2, stop=4))
      friendRow = which(friendList_4questions$friendID==friendID)
      if(surveyFile[rowNumber, currentColumnNumber]==1) {
        #friendList_2questions$closeness[friendRow] = surveyFile[rowNumber, currentColumnNumber+1] + 
        #  surveyFile[rowNumber, currentColumnNumber+4]
        
        friendList_4questions$closeness[friendRow] = surveyFile[rowNumber, currentColumnNumber+1] + 
          surveyFile[rowNumber, currentColumnNumber+4] + surveyFile[rowNumber, currentColumnNumber+3] + 
          surveyFile[rowNumber, currentColumnNumber+5]
        #friendList_4questions$closeness[friendRow] = surveyFile[rowNumber, currentColumnNumber+1] + surveyFile[rowNumber, currentColumnNumber+5]
        count = count + 1;
      } else if (surveyFile[rowNumber, currentColumnNumber]==2) {
        # add to a "no-interaction list". in case less than 30 friends, sample from this no-interaction list.
        noInteractionList = c(noInteractionList, friendList_4questions[c(friendRow), 1])
        
        # remove row:
        friendList_4questions = friendList_4questions[-c(friendRow), ]
      } else { # this person's ID
        if( friendID != participantID ) { # double check that its them
          cat("*** Warning: Participant ID: ", as.character(participantID), " doesn't match the ID of the picture they indicated was them: ", as.character(friendID), "\n")
        }
        
        # remove self row:
        friendList_4questions = friendList_4questions[-c(friendRow), ]
      } # end else clause
    }  
    
    # sort by order
    #friendList_4questions<-friendList_4questions[with(friendList_4questions, order(-closeness)), ]
    
    # plot and save distribution
    ggplot(friendList_4questions, aes(x=closeness)) + 
      geom_histogram(binwidth=1, origin=-0.5, colour="black", fill="white") +
      coord_cartesian(xlim=c(-1,30)) + ggtitle(paste("Participant ID: ", participantID, ", full set of closeness scores. N=", count, sep="") )
    
    ggsave(file=paste("output/", participantID, "_fullSetOfCloseness.png", sep=""), width=8, height=4)
    
    cat(paste("Participant ID: ", participantID, " has ", count, " friends that they talked with/interacted \n", sep=""))
    
    # making a set of 30
    if(count < 30) {
      cat("Warning: Participant ID: ", as.character(participantID), "has less than 30 positively close friends \n")
      
      # sample randomly from the noInteraction list to make up N=30
      numToAdd = 30 - count
      sampledOthers = data.frame(
        friendID = noInteractionList[sample(length(noInteractionList), numToAdd)],
        closeness = rep(0, numToAdd))
      
      friendList_4questionsShort = rbind(friendList_4questions, sampledOthers)
      
      ggplot(friendList_4questionsShort, aes(x=closeness)) + 
        geom_histogram(binwidth=1, origin=-0.5, colour="black", fill="white") +
        coord_cartesian(xlim=c(-1,30)) + ggtitle(paste("Participant ID: ", participantID, ", subset of closeness scores, with noInt others. N=", nrow(friendList_4questionsShort), ", orig N=", count, sep="") )
    } else if (count == 30) {
      # don't do anything!
      friendList_4questionsShort = friendList_4questions
      ggplot(friendList_4questionsShort, aes(x=closeness)) + 
        geom_histogram(binwidth=1, origin=-0.5, colour="black", fill="white") +
        coord_cartesian(xlim=c(-1,30)) + ggtitle(paste("Participant ID: ", participantID, ", subset of closeness scores. N=", nrow(friendList_4questionsShort), ", orig N=", count, sep="") )
    } else {
      # This was to evenly sample 30. We don't want this.
      ##friendList_4questionsShort = friendList_4questions[sample(nrow(friendList_4questions), 30), ]
      
      # subtract participants to get 30
      numToSubtract = nrow(friendList_4questions) - 30
      friendList_4questionsShort = friendList_4questions
      for(j in c(1:numToSubtract)) {
        # Table of values in histogram -> Sort it in increasing order -> 
        #    Reverse it (to find the mode) -> sample one bin value from the modes
        modeValue = rev(sort(table(friendList_4questionsShort$closeness)))[1]
        bins = names(which(table(friendList_4questionsShort$closeness)==modeValue))
        binValue = bins[sample(length(bins),1)]
        
        # find all friends in bin; randomly choose one
        targets = which(friendList_4questionsShort$closeness == binValue)
        friendToEliminate = targets[sample(length(targets),1)]
        friendList_4questionsShort = friendList_4questionsShort[-c(friendToEliminate), ]
      }  
      #order
      friendList_4questionsShort <-friendList_4questionsShort[with(friendList_4questionsShort, order(-closeness)), ]
      
      ggplot(friendList_4questionsShort, aes(x=closeness)) + 
        geom_histogram(binwidth=1, origin=-0.5, colour="black", fill="white") +
        coord_cartesian(xlim=c(-1,30)) + ggtitle(paste("Participant ID: ", participantID, ", subset of closeness scores. N=", nrow(friendList_4questionsShort), ", orig N=", count, sep="") )
    }
    
    ggsave(file=paste("output/", participantID, "_subsetOfCloseness.png", sep=""), width=8, height=4)
    
    #write.table(friendList_4questionsShort$friendID, paste("output/", participantID,".csv", sep=""), row.names=FALSE, col.names=FALSE, sep=",")
    write.table(friendList_4questionsShort, paste("output/", participantID,"_closeness_subset.csv", sep=""), row.names=FALSE, sep=",")
    write.table(friendList_4questions, paste("output/", participantID,"_closeness_full.csv", sep=""), row.names=FALSE, sep=",")
    
    write.xlsx(friendList_4questionsShort$friendID, paste("output/", participantID,".xls", sep=""), row.names=FALSE, col.names=FALSE)
    
    
  } #end of if loop

} # end of function
