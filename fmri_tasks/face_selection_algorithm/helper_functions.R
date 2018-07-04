library(ggplot2)
library(igraph)
library(corrplot)
library(lme4)
library(reshape)
library(Matching) # for ks.boot (bootstrapped Kolmogorov-Smirnov)

my_default_theme = theme_bw() + theme(strip.background = element_rect(fill="#FFFFFF"), 
        strip.text = element_text(size=12), 
        axis.text = element_text(size=12),
        axis.title.x = element_text(size=14, vjust=-0.2),
        axis.title.y = element_text(size=14, vjust=0.35),
        legend.text = element_text(size=12),
        title = element_text(size=18, vjust=1),
        panel.grid = element_blank())


trim <- function (x) gsub("^\\s+|\\s+$", "", x)

## make nomination matrix from data and list
makeNominationMatrixFromList <- function(dataFile, listOfIDs, listOfQuestions=c(1:9)) {
  thisLength = length(listOfIDs)
  nominationMatrix=matrix(rep(0,thisLength*thisLength), nrow=thisLength, ncol=thisLength) 
  rownames(nominationMatrix)<-listOfIDs
  colnames(nominationMatrix)<-listOfIDs
  
  listOfColumns = c()
  if(1 %in% listOfQuestions) { listOfColumns = c(listOfColumns, 3:10)}
  if(2 %in% listOfQuestions) { listOfColumns = c(listOfColumns, 11:18)}
  if(3 %in% listOfQuestions) { listOfColumns = c(listOfColumns, 19:26)}
  if(4 %in% listOfQuestions) { listOfColumns = c(listOfColumns, 27:34)}
  if(5 %in% listOfQuestions) { listOfColumns = c(listOfColumns, 35:42)}
  if(6 %in% listOfQuestions) { listOfColumns = c(listOfColumns, 43:50)}
  if(7 %in% listOfQuestions) { listOfColumns = c(listOfColumns, 51:58)}
  if(8 %in% listOfQuestions) { listOfColumns = c(listOfColumns, 59:66)}
  if(9 %in% listOfQuestions) { listOfColumns = c(listOfColumns, 67:74)}
  
  #new changes: remove self nominations, and double nominations.
  for(row in 1:nrow(dataFile)){
    #if(dataFile$Gender[row]==1) {
    if(dataFile[row,2] %in% listOfIDs) {
      nominationMatrix[ which(dataFile[row,2] == listOfIDs), which(dataFile[row,2] == listOfIDs) ] = -1
      added = c()
      count = 0
      for(col in listOfColumns) {
        count = count + 1
        if(count %% 8 ==0) { added = c() } #reset the "added" variable list after every question
        if(!is.na(dataFile[row,col])) {
          if(dataFile[row,col] %in% listOfIDs) {
            if(!dataFile[row,col] %in% added) {
              if(dataFile[row,col] != dataFile[row,2]) { # EXCLUDE self nominations
                nominationMatrix[ which(dataFile[row,2] == listOfIDs), which(dataFile[row,col] == listOfIDs) ] = nominationMatrix[ which(dataFile[row,2] == listOfIDs), which(dataFile[row,col] == listOfIDs) ] + 1;    
                added = c(added, dataFile[row,col])
              }
            }
          }
        }
      }
    }
  }
  return(nominationMatrix)
}

## making edge list from nomination matrix

makeEdgeListFromNominationMatrix <- function(nominationMatrix) {
  numEdges = sum(nominationMatrix > 0)
  edgeList = data.frame(source = rep(0,numEdges), target = rep(0, numEdges), weight = rep(0, numEdges))
  myArrInd = which(nominationMatrix>0, arr.ind = TRUE)
  for (j in 1: numEdges) {
    edgeList[j,] = c(myArrInd[j,1], myArrInd[j,2], nominationMatrix[myArrInd[j,1], myArrInd[j,2]])
  }
  return(edgeList)
}


replaceNamesWithIDUsingRoster <- function(dataFile, roster, listOfColumns=0) {
	# data file = input data. Expect each row to be a participant
	# roster: first column is 
	if(length(listOfColumns==0)) {
		listOfColumns = c(2:ncol(dataFile))
	}
	notFound = 0
	for(col in listOfColumns) {
  		dataFile[,col] = as.character(dataFile[,col])
  		for(row in 1:nrow(dataFile)) {
  			if(is.na(dataFile[row,col])) {
  				dataFile[row,col]=NA
  			}
  			else if(dataFile[row,col]=="") {
  				dataFile[row,col]=NA
  				} else {
  					id = roster[match(tolower(trim(dataFile[row,col])),
  						tolower(roster[,2])), 1]
  					if(!is.na(id)) {dataFile[row,col]=id}
  					else { 
  						cat("NAME NOT FOUND: ", as.character(dataFile[row,col]), ", row:", row, " col:", col, "\n"); 
  						notFound=notFound+1;
  					}
  				}
  			}
  			dataFile[,col] = as.numeric(dataFile[,col])
  		}
	#notFound
	dataFile[dataFile==-1]=NA
	return(dataFile)
}


calculateCorrelations <- function(nominationMatrix1, nominationMatrix2) {
  vec1 = c(nominationMatrix1)[c(nominationMatrix1)!=-1]
  vec2 = c(nominationMatrix2)[c(nominationMatrix2)!=-1]
  return(cor(vec1, vec2))
}

calculateChangeFrom <- function(nominationMatrixBase, nominationMatrix1) {
  # returns fraction of edges in nomMatrixBase that's also in nomMatrix1
  vecBase = c(nominationMatrixBase)[c(nominationMatrixBase)!=-1]
  vec1 = c(nominationMatrix1)[c(nominationMatrix1)!=-1]
  return(sum(vec1 & vecBase)/sum(vecBase))
}


replace_minus999s_with_NAs <- function(dataFile, listOfColumns) {
	dataFile[,listOfColumns][dataFile[,listOfColumns]==-999] = NA
	return(dataFile)
}


calculateInDegree <- function(nominationMatrix, subjID) { return(sum(nominationMatrix[,as.character(subjID)]) + 1) }
calculateOutDegree <- function(nominationMatrix, subjID) { return(sum(nominationMatrix[as.character(subjID),]) + 1) }

calculateReciprocalDegree <- function(nominationMatrix, subjID) { return(sum(
  nominationMatrix[as.character(subjID),] & nominationMatrix[,as.character(subjID)]) - 1) } # - 1 because self-nomination will count as a reciprocal.

# including people not in the study
calculateFullOutDegree <- function(dataFile, subjID, listOfQuestions = c(1:9)) { 
  listOfColumns = c()
  if(1 %in% listOfQuestions) { listOfColumns = c(listOfColumns, 3:10)}
  if(2 %in% listOfQuestions) { listOfColumns = c(listOfColumns, 11:18)}
  if(3 %in% listOfQuestions) { listOfColumns = c(listOfColumns, 19:26)}
  if(4 %in% listOfQuestions) { listOfColumns = c(listOfColumns, 27:34)}
  if(5 %in% listOfQuestions) { listOfColumns = c(listOfColumns, 35:42)}
  if(6 %in% listOfQuestions) { listOfColumns = c(listOfColumns, 43:50)}
  if(7 %in% listOfQuestions) { listOfColumns = c(listOfColumns, 51:58)}
  if(8 %in% listOfQuestions) { listOfColumns = c(listOfColumns, 59:66)}
  if(9 %in% listOfQuestions) { listOfColumns = c(listOfColumns, 67:74)}
  
  rowIndex = which(dataFile[,2]==subjID)
  #return (sum(dataFile[rowIndex, listOfColumns]<54, na.rm=T))
  return( sum(!is.na(dataFile[rowIndex, listOfColumns])) ) 
}


generatePairsDataframeFromNominationMatrix <- function(nominationMatrix) {
  vectorOfIDs = as.numeric(colnames(nominationMatrix))
  dPairs = data.frame(fromID = rep(vectorOfIDs, each=length(vectorOfIDs)),
    toID = rep(vectorOfIDs,length(vectorOfIDs)))
    # remove self edges:
    dPairs = dPairs[dPairs$fromID!=dPairs$toID,]

    # Change this for the desired edge (e.g. which time point, which question)
    for(row in 1:nrow(dPairs)) {
      #nodeFromIndex = which(dNodes$ID == dPairs$fromID[row])
      #nodeToIndex = which(dNodes$ID == dPairs$toID[row])
      dPairs$edge[row] = nominationMatrix[as.character(dPairs$fromID[row]), as.character(dPairs$toID[row])]
      dPairs$reverseDirectionEdge[row] = nominationMatrix[as.character(dPairs$toID[row]), as.character(dPairs$fromID[row])]
    }
  dPairs$reciprocal = (dPairs$edge & dPairs$reverseDirectionEdge)*1
  print("Finished Processing")
  return(dPairs)
}

calculatePairVariable_homophily <- function(dNodes, dPairs, variableInputName = NULL, variableOutputName = NULL) {
  if( is.null(variableInputName) ) {print("Error. Input name not given"); return;}
  if(! (variableInputName %in% colnames(dNodes) )) {print("Error. Input name not found in dNodes"); return;}
  if( is.null(variableOutputName) ) {print("Error. Output name not given"); return;}
  for(row in 1:nrow(dPairs)) {
    nodeFromIndex = which(dNodes$ID == dPairs$fromID[row])  
    nodeToIndex = which(dNodes$ID == dPairs$toID[row])

    eval(parse(text=paste(
      "dPairs$", variableOutputName, "[row] = ", 
      "(dNodes$", variableInputName, "[nodeFromIndex]", "==", 
      "dNodes$", variableInputName,"[nodeToIndex])", 
      sep="")))
  }
  return(dPairs)
}

calculateListOfPairVariables_homophily <- function(dNodes, dPairs, variableList) {
  for(variable in variableList) {
    variableOutputName = paste(variable, "_homophily", sep="")
    dPairs = calculatePairVariable_homophily(dNodes, dPairs, 
      variableInputName = variable, variableOutputName = variableOutputName)
  }
  cat("Finished Processing\n")
  return(dPairs)
}

calculatePairVariable_fromAndTo <- function(dNodes, dPairs, 
  direction='from', variableInputName = NULL, variableOutputName = NULL) {
  if( is.null(variableInputName) ) {print("Error. Input name not given"); return;}
  if(! (variableInputName %in% colnames(dNodes) )) {print("Error. Input name not found in dNodes"); return;}
  if( is.null(variableOutputName) ) {print("Error. Output name not given"); return;}

  if( ! (direction %in% c("from", "to"))) {print("Error. Direction not recognized"); return;}

  for(row in 1:nrow(dPairs)) {
    if(direction=='from') {
      nodeIndex = which(dNodes$ID == dPairs$fromID[row])  
    } else {
      nodeIndex = which(dNodes$ID == dPairs$toID[row])
    }
    eval(parse(text= paste(
      "dPairs$", variableOutputName, "[row] = ", 
      "dNodes$", variableInputName, "[nodeIndex]", sep="")
      ))
  }
  return(dPairs)
}

calculateListOfPairVariables_toFrom <- function(dNodes, dPairs, variableList) {
  # removing _avg and _trnsf suffixes
  variableList = gsub("_avg", "", gsub("_trnsf", "", variableList))

  for(variable in variableList) {
    variableOutputName_to = paste("to", variable, sep="")
    dPairs = calculatePairVariable_fromAndTo(dNodes, dPairs, 
      direction='to', variableInputName = variable, variableOutputName = variableOutputName_to)
    
    variableOutputName_from = paste("from", variable, sep="")
    dPairs = calculatePairVariable_fromAndTo(dNodes, dPairs, 
      direction='from', variableInputName = variable, variableOutputName = variableOutputName_from)
    
    variableOutputName_diff = paste("diff", variable, sep="")
    eval(parse(text=paste("dPairs$", variableOutputName_diff, "= dPairs$", variableOutputName_to, " - dPairs$", variableOutputName_from, sep="")))
  }
  cat("Finished Processing\n")
  return(dPairs)
}


addQuestionAndTimeVariablesToMeltedNomination<- function(totalNominations_melt) {
  for(row in 1:nrow(totalNominations_melt)) {
    totalNominations_melt$time[row] = grepl("t1", as.character(totalNominations_melt$variable[row]))*1 + grepl("t2", as.character(totalNominations_melt$variable[row]))*2
    totalNominations_melt$question[row] = grepl("q1", as.character(totalNominations_melt$variable[row]))*1 + 
      grepl("q2", as.character(totalNominations_melt$variable[row]))*2 + 
      grepl("q3", as.character(totalNominations_melt$variable[row]))*3 + 
      grepl("q4", as.character(totalNominations_melt$variable[row]))*4 + 
      grepl("q5", as.character(totalNominations_melt$variable[row]))*5 + 
      grepl("q6", as.character(totalNominations_melt$variable[row]))*6 + 
      grepl("q7", as.character(totalNominations_melt$variable[row]))*7 + 
      grepl("q8", as.character(totalNominations_melt$variable[row]))*8 +
      grepl("q9", as.character(totalNominations_melt$variable[row]))*9
  }
  return(totalNominations_melt)
}


addIncomingOutgoingVariablesToMeltedNomination <- function(totalNominations_melt) {
  for(row in 1:nrow(totalNominations_melt)) {
    totalNominations_melt$incoming[row] = grepl("Incoming", as.character(totalNominations_melt$variable[row]))*1
  }
  return(totalNominations_melt)
}


calculateAllOutgoingNominations <- function(totalNominationsDataFrame, questions, times) {
  for(question in questions) {
    for(time in times) {
      for(row in 1:nrow(totalNominationsDataFrame)) {
        eval(parse(text=
                     paste(
                       paste("totalNominationsDataFrame$numOutgoingNominations_q",
                             paste( as.character(question), as.character(time), sep="_t"), 
                             sep=""),
                       paste( 
                         paste("calculateFullOutDegree(d_t",as.character(time), sep=""),
                         paste(as.character(question), ")", sep=""),
                         sep=", totalNominationsDataFrame$ID[row], "),
                       sep="[row] = ") 
        ))
      }
    }
  }
  return(totalNominationsDataFrame)
}


calculateIncomingNominations <- function(totalNominationsDataFrame, questions, times) {
  # totalNominationsDataFrame$numNominations_q1_t0 = colSums(nominationMatrix_q1_t0) + 1 
  ### +1 is because I coded the diagonal as having -1
  for(question in questions) {
    for(time in times) {
      eval(parse(text=paste(
        "totalNominationsDataFrame$numIncomingNominations_q", 
        as.character(question), "_t", as.character(time), 
        " = colSums(nominationMatrix_q",
        as.character(question), "_t", as.character(time), 
        ") + 1", 
        sep="")
      ))
    }
  }
  return(totalNominationsDataFrame)
}


calculateKStest <- function(totalNominationsDataFrame, questionList, timeList, alpha=0.05) {
  question = questionList[1]; time = timeList[1]
  dist1String = paste("numOutgoingNominations_q", paste(as.character(question), as.character(time), sep="_t"), sep="")
  question = questionList[2]; time = timeList[2]
  dist2String = paste("numOutgoingNominations_q", paste(as.character(question), as.character(time), sep="_t"), sep="")
  
  eval(parse(text=paste('dist1 = totalNominationsDataFrame$', dist1String, sep="")))
  eval(parse(text=paste('dist2 = totalNominationsDataFrame$', dist2String, sep="")))
  #ks.test(dist1, dist2)
  
  thisBoot = ks.boot(dist1, dist2, nboots=1000, print.level=0)
  if(thisBoot$ks.boot.pvalue < alpha) {
    
    comparisonString = paste(paste("q", as.character(questionList[1]), " t", as.character(timeList[1]), sep=""),
                             paste("q", as.character(questionList[2]), " t", as.character(timeList[2]), sep=""),
                             sep = " vs. ")
    
    cat(paste("Comparison: ", comparisonString, ", p-value: ", format(thisBoot$ks.boot.pvalue, digits=3), sep=""), '\n\n') 
  }
}



calculateKStestVsBinom <- function(totalNominationsDataFrame, question, time, altDist, alpha=0.05) {
  dist1String = paste("numOutgoingNominations_q", paste(as.character(question), as.character(time), sep="_t"), sep="")
  
  eval(parse(text=paste('dist1 = totalNominationsDataFrame$', dist1String, sep="")))
  
  thisBoot = ks.boot(dist1, altDist, nboots=1000, print.level=0)
  if(thisBoot$ks.boot.pvalue < alpha) {
    
    comparisonString = paste("q", paste(as.character(question), as.character(time), sep=" t"), sep="")
                             
    cat(paste( "Comparison: ", comparisonString, " vs binomial: p-value: ", format(thisBoot$ks.boot.pvalue, digits=3), sep=""), "\n\n") 
  }
}



runModels <- function(dataFile, DVList, IVList, categoricalOutcome = FALSE) {
  for(n in 1:length(DVList)) {
    DV = DVList[n]
    IVs = IVList[n]
    IVstring = paste(unlist(IVs), collapse=' + ')
    
    cat(paste("Running Formula: ", DV, " ~ ", IVstring, sep=""), "\n")
    if(categoricalOutcome) {
      eval(parse(text = paste('thisModel = glm(', DV, ' ~ ', IVstring, ', family=binomial(), dataFile)', sep="")))
    } else {
      eval(parse(text = paste('thisModel = lm(', DV, ' ~ ', IVstring, ', dataFile)', sep="")))
    }
    thisTable = summary(thisModel)$coeff
    for(j in 2:(dim(thisTable)[1])) { # ignore intercept
      if(thisTable[j,4]<.05) {
        cat(paste("Significant Predictor: ", rownames(thisTable)[j], ", b: ", format(thisTable[j,1], digit=3), ", t: ", format(thisTable[j,3], digits=3), ", p: ", format(thisTable[j,4], digits=3), sep=""), "\n")
      }
    }
    #print(summary(thisModel))
    cat("\n")
  }
  cat("--- Finished running models ---\n")
}
