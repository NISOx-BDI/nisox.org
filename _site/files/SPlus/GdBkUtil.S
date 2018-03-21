#
# Functions to facilitate using data tables as grade books
#
# Based on CMU GdBkUtil.S,v 1.5 2000/02/02 21:31:53 nicholst Exp
#
# @(#)GdBkUtil.S	1.3 Tom Nichols 04/10/31

#
# These are utilities to support the GB gradebook for Splus
# 
# Documentation for GB can be found in
#
#        http://www.stat.cmu.edu/~nicholst/GB.html
#
#
# The main use of these utilities is for creating new grade books
# based on the registrar's course datafiles.
#
# To create the gradebook for 209, section "A", based on a comma-separated
# course datafile named "course.dat", you simply need to do the
# following
# 
#    ezGBcreate(209,"A","course.dat")
#




ezGBcreate <- function(Class, Sec, CourseDatFn) {
  #
  # Create a gradebook based on a course datafile.
  #
  # $Id: GdBkUtil.S,v 1.5 2000/02/02 21:31:53 nicholst Exp $
    
  # Read the course datafile into a data.frame
  Cdat <- ReadCourseDat(CourseDatFn)

  # Check for valid section
  if (sum(Cdat$Sect==Sec)==0) {
    cat("Error!  No students in section",Sec,"!\n")
    return(NULL)
  }

  # This extracts the parts you need for the gradebook: 
  # name, email, & soc sec num.  
  Info <- StudInfo(Cdat[Cdat$Sect==Sec,])

  # Display info
  cat("Creating gradebook for", Class,"section",Sec,
      "with following student information\n")
  print(data.frame(Info))

  # Create the gradebook
  GBcreate(Class,Sec,Studs=Info$Name,SS=Info$SS,Em=Info$Em)

}


ReadCourseDat <- function(File) {
  #
  # This function returns a data.frame containing the 
  # information in the comma separated course data file.
  #
  # $Id: GdBkUtil.S,v 1.5 2000/02/02 21:31:53 nicholst Exp $

  Tmp <- scan(File,sep=",",what=character())
  Dat <- data.frame(matrix(Tmp,byrow=T,ncol=14))
  names(Dat)<-c("Sem","compid","studid","LastNm","FirstNm",
		"Coll","Dept","Class","GdOpt","qSca","Course","Sect",
		"MidG","FinG")

  return(Dat)

}

StudInfo <- function(CourseDat) {
  #
  # Returns a list of text vectors suitable for use with 
  # GBcreate/GBaddstud
  # 
  # $Id: GdBkUtil.S,v 1.5 2000/02/02 21:31:53 nicholst Exp $


  Info_lapply(CourseDat,function(e){if(is.factor(e)) as.character(e)})

  Names_paste(Info$LastNm,Info$FirstNm,sep=",")

  return(list(Name=Names,SS=Info$studid,Em=Info$compid))
}


#
# Short cuts to avoid long option specifications...
#

GBfixstud <- function(...)
  GBaddstud(...,Type="fix")

GBdelstud <- function(...)
  GBaddstud(...,Type="del")

GBfixgrade <- function(...)
  GBaddgrade(...,Type="fix")

GBdelgrade <- function(...)
  GBaddgrade(...,Type="del")

GBincgrade <- function(...)
  GBaddgrade(...,Type="inc")





#
# Functions to support calculation of final grades
#

DropGd <- function(Tab,Drp)  {
  #
  # A gradebook is returned with all dropped grades set to NA.
  #
  # Tab  is a gradebook table as obtained from GBget
  #
  #
  # Drp  is a list coding which grade types can be dropped; the names
  #      of each element are taken from the gradebook column names
  #      with out any numbers.  For example
  #
  #             Drp=list(H=2,L=1)
  #
  #      would indicate that two homeworks and one lab can be
  #      dropped.
  #
  #      If you would like to prevent specific grades from being
  #      dropped you can supply a list consisting of an integer and a
  #      logical vector, as in 
  #
  #             Drp=list(H=list(2,c(T,T,T,T,T,T,T,F,F)))
  #
  #      This would used if you had 9 homeworks, you were going to let
  #      them drop two but they were not allowed to drop the last two.
  #      The logical list must have an element for each grade of that
  #      type. 
  #      
  # One caution:  If you use the feature which prevents certain grades
  #               from being dropped it will be possible that a
  #               dropped grade avereage is *lower* than a non-dropped
  #               grade average.  This function makes no account of
  #               this; you should work out grades both way and then
  #               take the max.
  #
  # $Id: GdBkUtil.S,v 1.5 2000/02/02 21:31:53 nicholst Exp $

  if(!ValidTab(Tab))
    stop("Bad Table.")
  if(!is.list(Drp))
    stop("Second argument (Drp) must be a list.")

  GBtyps <- attr(Tab, "GBtypes")
  GBtypC <- attr(Tab, "GBtypeC")

  Nms <- names(Drp)

  for (i in 1:length(Drp)) {
 
    GNm <- Nms[i]

    if (is.list(Drp[[i]])) {
      nD <- (Drp[[i]])[[1]]   # Number to drop
      wD <- (Drp[[i]])[[2]]   # Which can drop
    } else {
      nD <- Drp[[i]]
      wD <- numeric(0)
    }

    I <- (GNm==GBtyps[,"ColNm"])

    # Basic checks
    if (sum(I)==0)
      stop(paste("Unknown grade type letter '",GNm,"'",sep=""))
    if (length(nD)!=1)
      stop(paste("Number of grades to drop must be a scalar (grade type '",GNm,"')",sep=""))
    # Should never happen
    if (sum(I)>1)
      stop("Internal Error!  Nonunique grad column names!")
    # Convert I from logical vector to indici
    I <- (1:length(I))[I]

    GFulNm <- GBtyps[I,"Type"]

    # More checks
    if (GBtyps[I,"bMult"]=="F")
      stop(paste("Grade type '",GNm,"' (",GFulNm,") is not a multiple grade type",sep=""))
    if (GBtyps[I,"bGrade"]=="F")
      stop(paste("Grade type '",GNm,"' (",GFulNm,") is not a grade!",sep=""))
    
    # Get vector of columns containing this grade type
    IC <- GBtypC[[I]]

    if (length(IC)==0) {
      cat("Warning:  No grades of type ",GNm," (",GBtyps[I,"Type"],")",sep="")
      next
    }
    
    if ((length(wD)>0) & (length(wD)!=length(IC)))
      stop(paste("Drop T/F vector for grade type '",GNm,"' (",GFulNm,
		 ") is wrong length (should be ",length(IC),")",sep=""))

    Tab[,IC] <- t(apply(Tab[,IC],1,MinNA,nD,wD))
  }


  Tab
}


MkGrd <- function(Tab,Wts,GdWts=numeric(0),Rnd=T) {
  #
  # This function sums (optionally weighted) means of specified grade
  # types to form a grade.
  #
  # Tab   is a gradebook, such as returned from GBget
  #
  #
  # Wts   is a list identifying how to weight each different grade
  #       type; the weights must sum to one.  The names of each
  #       element are taken from the gradebook column names without
  #       any numbers.  An example is
  #
  #           Wts = list(H=0.2, L=0.2, E=.3, F=.3)
  #
  #       which specifies that homeworks are worth 20%, labs 20%,
  #       exams (average exam score) is work 30% and the final is worth
  #       30%.
  #
  #
  # GdWts is an optional list describing how to weight *individual* grades.
  #       Each element must either be a numeric scalar or vector.  If
  #       it is a scalar, then all grades of the specified type are
  #       scaled by that quantity.  If it is a vector, then there must
  #       be one element for each grade of that type.
  #
  #       For example, 
  #
  #            GdWts = list(L=100, E=100/c(100,150))
  #
  #       specifies that labs should be scaled up by a factor of 100
  #       (appropriate if the labs are entered as zero-one) and that
  #       the second exam score should be scaled down by a factor of
  #       0.66667 (appropriate if the second exam was out of 150
  #       points, but the two exams have equal value).
  #
  #
  # Rnd   If rnd is true, the grades are rounded to the nearest
  #       integer. 
  #
  # $Id: GdBkUtil.S,v 1.5 2000/02/02 21:31:53 nicholst Exp $

  if (!ValidTab(Tab))
    stop("Bad Table.")
  if (!is.list(Wts))
    stop("Second argument (Wts) must be a list.")
  if (abs(sum(unlist(Wts))-1)>1e-6)
    warning("Sum of weights in Wts doesn't sum to one")
  if ((length(GdWts)>0) & !is.list(Wts))
    stop("Third argument (GdWts) must be a list.")
    
  GBtyps <- attr(Tab, "GBtypes")
  GBtypC <- attr(Tab, "GBtypeC")

  Grd <- rep(0,dim(Tab)[1])

  Nms <- names(Wts)
  

  for (i in 1:length(Wts)) {

    GNm <- Nms[i]

    Wt <- Wts[[i]]

    if (length(GdWts)>0) {
      GdWt <- GdWts[[GNm]]
      if (length(GdWt)==0)
	GdWt <- 1
    } else {
      GdWt <- 1
    }

    I <- (GNm==GBtyps[,"ColNm"])
    if (sum(I)==0)
      stop(paste("Unknown grade type letter '",GNm,"'",sep=""))
    # Should never happen
    if (sum(I)>1)
      stop("Internal Error!  Nonunique grad column names!")

    # Convert I from logical vector to indici
    I <- (1:length(I))[I]

    GFulNm <- GBtyps[I,"Type"]

    # More checks
    if (GBtyps[I,"bGrade"]=="F")
      stop(paste("Grade type '",GNm,"' (",GFulNm,") is not a grade!",sep=""))
    
    # Get vector of columns containing this grade type
    IC <- GBtypC[[I]]

    if (length(IC)==0) {
      cat("Warning:  No grades of type ",GNm," (",GFulNm,")",sep="")
      next
    }

    if ((length(GdWt)>1) & (length(GdWt)!=length(IC)))
      stop(paste("Grade scaling  vector for grade type '",GNm,"' (",GFulNm,
		 ") is wrong length (should be ",length(IC),")",sep=""))

    if (length(IC)==1) {
      # For single grade types, if someone has a NA they'll get 
      # a NA final grade! 
      Grd <- Grd + Wt*GdWt*Tab[,IC]
    } else {
      if (length(GdWt)>1) {
	ScMtx <- matrix(rep(GdWt,dim(Tab)[1]),byrow=T,ncol=length(IC))
	Grd <- Grd + Wt*apply(Tab[,IC]*ScMtx,1,mean,na.rm=T)
      } else {
	Grd <- Grd + Wt*GdWt*apply(Tab[,IC],1,mean,na.rm=T)
      }
    }

  }

  if (Rnd==T)
    Grd <- round(Grd)

  Grd
}


MinNA <- function(Val,nNA,Wch=numeric(0)) {

  #
  # Set the nNA smallest values in numeric vector Val to NA
  #
  # Val is a numeric vector
  # nNA is a scalar integer
  # Whc is a logical vector either length zero or length equal to Val;
  #     Only elements tagged as "T" will be considered for setting to NA
  #
  # $Id: GdBkUtil.S,v 1.5 2000/02/02 21:31:53 nicholst Exp $

  if (is.list(Val))
    Val <- unlist(Val)
  
  if (length(Wch)>0) {
    if (length(Wch) != length(Val))
      stop("MinNA: Val and Wch length do not match")
    tVal <- Val
    tVal[!Wch] <- NA
  } else {
    tVal <- Val
  }
  
  if (sum(!is.na(tVal)) < nNA) {
    Val[!is.na(tVal)] <- NA
    return(Val)
  }

  Val[order(tVal)[1:nNA]] <- NA

  Val

}


LetrGd <- function(Grd,Lwl=c(90,80,70,60,0),LtGd=c("A","B","C","D","R")) {

  #
  # Convert numeric values into letter grades
  #
  # Grd is a numeric vector
  # Lwl is a numeric vector of lower levels, that is it 
  #     defines the inclusive lower limit of each grade.
  #     Lwl *must* be monotonically decreasing and it's length must
  #     match the length of LtGd (by default 5)
  #
  # $Id: GdBkUtil.S,v 1.5 2000/02/02 21:31:53 nicholst Exp $

  nLvl <- length(Lwl)
  nStud <- length(Grd)

  G <- matrix(rep(Grd,nLvl),nrow=nStud)
  L <- matrix(rep(Lwl,nStud),byrow=T,nrow=nStud)

  LtGd[1+nLvl-apply(G>=L,1,sum)]

}
