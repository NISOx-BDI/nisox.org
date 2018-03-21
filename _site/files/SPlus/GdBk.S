#
# Functions to facilitate using data tables as grade books
#
# Based on GdBk.S,v 1.20 2000/02/03 03:29:11 nicholst Exp
#
# @(#)GdBk.S	1.6 Tom Nichols 04/10/31

if (!exists("GRADE.HOME"))
  GRADE.HOME <- cat(getenv("HOME"),"/Sgrades",sep="")

#
# Sample Session and documentation:
#
#        http://www.sph.umich.edu/~nichols/GB/GB.html
#

#
# GB uses Splus data.frames to store grades.  There are 6 types of
# grades, Homework, Lab, Special, Exam, Final, Overall, but more can
# be added by editing DefaultGBtypes below.
#
# Each section must have it's own gradebook, but multiple sections can
# be combined for viewing via GBget.  
#
# Gradebook data.fames can only contain numeric grades!!!  This is due
# to problems with the way Splus handles nonnumeric values in
# data.frames (it converts them to factors, so they can be treated like
# numbers).  Hence, non-numeric information such email address and
# social security number (which, b/c of nontrivial leading zeros, must
# be of type character) are stored in an associated list of string 
# vectors... but I'm getting ahead of myself.
# 
# The key to GB is in the attributes; the attributes hold the
# definitions of the different grade types, and keeps track of which
# columns are what type of grades.  Another attribute is the
# aforementioned list string vectors; currently only email and soc sec
# are stored there, but there's no reason that all of the fields of
# the registrar's database couldn't be put there.
#

#
# Slightly anal distiction:
#
#  "GB*" functions specify gradebooks by class number and a section.
#  "Tab" and other functions specify gradebooks in data.table form.
# 
# A Valid Gradebook is a data.frame with attributes called "GBsec" and
# "GBtypes", but "GBtypC" is also needed, and until a gradebook has grades
# student names are stored in "StudNms".
#
# If more attributes are added code should be checked (in particular,
# GBaddgrade,"fix") to ensure new attribute is always propagated.
#
#
#
#  UM Modifications
#
#  Now has limited ability work with numeric sections.  If a integer
#  value is supplied for a section letter it is converted to the
#  corresponding letter (1->"A", 2->"B", etc.)  The names of the
#  variables are written to disk, however, still using letters for
#  section ids.
#
#  To turn off this option, find the definition of the "GBget" function
#  below and change "SecNum=T" to "SecNum=F".
#
#


# 
# History
#
# GB-like functions were created to manage final grades for 36-201 in
# the Fall of 1996.  Christmas 1996 I spent too much time playing with
# Splus trying to get it do what I wanted. It was made available to
# other stats classes for spring 1997 semester. Unfortunately, it
# hasn't changed much since then.
#
# Thanks to Joel Greenhouse for supporting this initially, and all the
# students and faculty who've given feedback to improve it.
#
# TEN
#


"GBcreate" <- function(Class, Sec, addstud=T,...)
# Additional args are passed on to addstud, like Studs
{
    TabNm <- MkTabNm(Class, Sec)
    if (TabExist(TabNm)) {
	cat("Gradebook '",TabNm,"' already exists.\n",sep="")
	return(NULL)
    }
    Sec <- MkSecNm(Sec)
    Tab <- data.frame()
    attr(Tab, "GBsec") <- Sec
    attr(Tab, "GBtypes") <- DefaultGBtypes()
    attr(Tab, "GBtypeC") <- vector("list",dim(attr(Tab, "GBtypes"))[1])
    attr(Tab, "GBver") <- "$Id: GdBk.S,v 1.20 2000/02/03 03:29:11 nicholst Exp $"
    attr(Tab, "GBtxt") <- list()
    if (addstud)
      GBaddstud(Class, Sec, GBdf=Tab, ...)
    else
      PutTab(Tab, TabNm, Talk = T)
}


"GBdelete" <- function(Class, Sec)
{
    TabNm <- MkTabNm(Class, Sec)
    Sec <- MkSecNm(Sec)
    if (is.null(GB <- GetTab(TabNm))) return(NULL)
    StdNms <- row.names(GB)
    if(length(StdNms) == 0) {
      StdNms <- attr(GB, "StudNms")
      attr(GB, "StudNms") <- NULL
    }
    nStd <- length(StdNms)
    nGrd <- length(names(GB))

    cat("\nGrade book for",Class,"section",Sec,"has",
	nStd,"students and",nGrd,"grades in it\n")
    cat("\n    Are you sure you want to delete it?  ")
    Tmp <- readline();
    if (Tmp == "y" || Tmp == "Y") {
      RmTab(TabNm,Talk=T)
    } else {
      cat("\nAborted\n")
    }

    invisible()
}


"GBrecover" <- function(Class, Sec)
{

    # Get current GB if exists
    Sec <- MkSecNm(Sec)
    TabNm <- MkTabNm(Class, Sec)
    if (TabExist(TabNm)) {
      GB <- GetTab(TabNm)
      if ((nStd <- length(row.names(GB))) == 0) {
	nStd <- length(attr(GB, "StudNms"))
      }
      nGrd <- length(names(GB))
    } else {
      GB <- NULL
    }
     
    # Get backup GB
    TabNmBak <- paste(TabNm, ".bak", sep = "")
    if (!TabExist(TabNmBak)) {
      cat("No backup found for",Class,"section",Sec,"\n")
      return(NULL)
    }
    GBbak <- GetTab(TabNmBak)
    if ((nStdBak <- length(row.names(GBbak))) == 0) {
      nStdBak <- length(attr(GBbak, "StudNms"))
    }
    nGrdBak <- length(names(GBbak))


    if (is.null(GB)) {
      cat("\nCurrent grade book for",Class,"section",Sec,"does not exist\n")
    } else {
      cat("\nCurrent grade book for",Class,"section",Sec,"has",
	  nStd,"students and",nGrd,"grades in it.\n")
    }
    cat("Backup grade book for",Class,"section",Sec,"has",
	nStdBak,"students and",nGrdBak,"grades in it.\n")
    cat("\n    Are you sure you want recover backup?  ")
    Tmp <- readline();
    if (Tmp == "y" || Tmp == "Y") {
      if (!is.null(GB))
	RmTab(TabNm,Talk=F)
      PutTab(GBbak,TabNm,Talk=F);
      cat("\nBackup recovered (previous grade book now backup)\n")
    } else {
      cat("\nAborted\n")
    }

    invisible()
}


"GBaddgrade"<- function(Class, Sec, Type="new",Gds=numeric(0))
{
					# Setup & Basic error checking
  BkNm <- MkTabNm(Class, Sec)
  Sec <- MkSecNm(Sec)
  if (is.null(GB <- GetTab(BkNm))) return(NULL)
  StdNms <- row.names(GB)
  if(length(StdNms) == 0) {
    StdNms <- attr(GB, "StudNms")
    attr(GB, "StudNms") <- NULL
  }
  if (length(StdNms)==0) {
    cat("No students!\n")
    return(NULL)
  }
  if (!missing(Type)) {
    Tmp <- charmatch(Type,c("new","delete","fix","inc"))
    if (is.na(Tmp)) {
      cat("Type keyword is not matched; must be one of 'new', 'delete', 'fix' or 'inc'\n")
      return(NULL)
    }
    if (Tmp==0) {
      cat("Type keyword is not uniquely matched; must match one of 'new', 'delete' 'fix' or 'inc'\n")
      return(NULL)
    }
  }
  GdNms <- names(GB)
  NewGdCol <- dim(GB)[2]+1
  nStd <- length(StdNms)
  NewGd <- rep(0, nStd)
  GdTyp <- attr(GB, "GBtypes")
  GdTypC <- attr(GB, "GBtypeC")
  GdTyp <- GdTyp[GdTyp[, "bGrade"] == "T",  ]	# Kill non grade types
  nGdTyp <- dim(GdTyp)[1]

  if (is.logical(Gds))
    Gds <- as.numeric(Gds)
  if (!is.numeric(Gds)) {
    cat("Grade vector Gds must be numeric\n")
    return(NULL)
  } 
  if (length(Gds)>0) {
    if (length(Gds)!=nStd) {
      cat("Grade vector Gds is wrong length (should be length",nStd,")\n")
      return(NULL)
    }
    cat("\n          >>> Getting grades from Gds option <<<\n")
  }
    
  if (charmatch(Type,c("new","delete","fix","inc"))==1) {
    
    cat("\nEnter New Grade Type (0 to exit)...")
    Tmp <- menu(GdTyp[,"Type"])
    if(Tmp == 0) {
      cat("Gradebook unchanged\n")
      return(NULL)
    }
    iGdTypC <- as.numeric((dimnames(GdTyp)[[1]])[Tmp])
    GdTypC <- GdTypC[[iGdTypC]]
    GdTyp <- GdTyp[Tmp, ]
    if ((length(GdTypC) > 0) && (GdTyp["bMult"] == "F")) {
      cat("\007\n'", GdTyp["Type"], 
	  "' already exists!\n", 
	  "Use GBaddgrade,Type=\"fix\" to change or Type=\"delete\" ",
	  "to delete it.\n\n",
	  "Gradebook unchanged.\n", sep = "")
      return(NULL)
    }
    GdTypC <- c(GdTypC, NewGdCol)

    if (GdTyp["bMult"] == "T")
      NewGdNm <- paste(GdTyp["ColNm"], length(GdTypC), sep = "")
    else
      NewGdNm <- GdTyp["ColNm"]
    attr(GB, "GBtypeC")[[iGdTypC]] <- GdTypC
    
    cat("\n    ", rep(" ", 42), NewGdNm,"\n",sep="")
    for(i in 1:nStd) {
      Len <- nchar(StdNms[i])
      BadInput <- T
      while(BadInput) {
	cat("    ", StdNms[i], rep(".", max(0,40 - Len)), " ", sep = "")
	if (length(Gds)>0) {
	  BadInput <- F
	  Tmp <- Gds[i]
	  cat(Tmp,"\n")
	} else {
	  Tmp <- readline()	
	  if (!ValidNum(Tmp))
	    cat("\007Please re-enter\n")
	  else 
	    BadInput <- F
	}
      }
      NewGd[i] <- as.numeric(Tmp)
    }
    cat("\n")
    
    # Very carefully add the new column (keeping attrs)
    if (all(dim(GB)==c(0,0))) {
      Tmp <- data.frame(NewGd)
      attributes(Tmp) <- attributes(GB)
      GB <- Tmp
      attr(GB,"row.names") <- StdNms
    } else {
      GB[,NewGdCol] <- NewGd
    }
    names(GB) <- c(GdNms, NewGdNm)

  } else {

    if (charmatch(Type,c("new","delete","fix","inc"))==2) {
      rm.grade <- T
      cat("\nEnter Grade to Delete (0 to exit)...")

    } else if (charmatch(Type,c("new","delete","fix","inc"))==3) {
      rm.grade <- F
      cat("\nEnter Grade to Fix (0 to exit)...")

    } else if (charmatch(Type,c("new","delete","fix","inc"))==4) {
      rm.grade <- F
      cat("\nEnter Grade to Increment (0 to exit)...")
    }
    
    Gd <- menu(GdNms)
    if(Gd == 0) {
      cat("Gradebook unchanged\n")
      return(NULL)
    }
    GdNm <- GdNms[Gd]
    
    if (rm.grade==T) {
      
      GBtypC<-attr(GB,"GBtypeC")
      GdInfo<-NA
      for (i in 1:length(GBtypC)) {
	if (length(GBtypC[[i]]) && any(GBtypC[[i]]==Gd)) {
	  GdInfoN <- i
	  GdInfo<-attr(GB,"GBtypes")[i,]
	  break
	}
      }
      if (is.na(GdInfo[1]))
	stop("\nYou seem to have a corrupt gradebook: get help\n(Grade to delete not found in GBtypeC)\n")
      if (GdInfo["bMult"]=="T")
	Tmp <- as.character((1:length(GBtypC[[GdInfoN]]))[GBtypC[[GdInfoN]]==Gd])
      else
	Tmp <- ""
      cat("\nIf you sure you want to delete ",GdInfo[1]," ",
	  Tmp,
	  " (",GdNm,")",	    
	  " enter 'YES': ",sep="")
      Tmp <- readline()
      if (Tmp!="YES") {
	cat("Gradebook unchanged\n")
	return(NULL)
      }
      GB[[Gd]] <- NULL
      if (dim(GB)[2]==0) {
	attr(GB,"StudNms") <- attr(GB,"row.names")
	attr(GB,"row.names") <- NULL
      }
      # Update GBtypeC
      for (i in 1:length(GBtypC)) {
	if (i==GdInfoN) {
	  # Nuke the entry
	  GBtypC[[i]] <- GBtypC[[i]][GBtypC[[i]]!=Gd]
	}
	if (length(GBtypC[[i]]) && any(GBtypC[[i]]>Gd)) {
	  # deincriment any entries greater than Gd
	  GBtypC[[i]][GBtypC[[i]]>Gd] <- GBtypC[[i]][GBtypC[[i]]>Gd]-1
	}
      }
      attr(GB,"GBtypeC") <- GBtypC

    } else {   # Fix or Inc

      UniGrade <- numeric(0)
      if (charmatch(Type,c("new","delete","fix","inc"))==3)
	cat("\nEnter Student Number to Fix (0 for all students)...")
      else
	cat("\nEnter Student Number to Increment (0 for all students)...")
      Tmp <- menu(row.names(GB))
      if(Tmp == 0) {
	Stud <- 1:dim(GB)[1]
	cat("\nSame grade (fix or inc) for all students? (y|n) ");
	Tmp <- readline();
	if (Tmp == "y" || Tmp == "Y") {
	  while (!ValidNum(Tmp)) {
	    cat("\nEnter single grade ");
	    Tmp <- readline()
	  }
	  UniGrade <- as.numeric(Tmp)
	}
      } else {
	Stud <- Tmp
      }

      if (length(UniGrade)==0)
	cat("\n    ", rep(" ", 37), "(old) ",GdNm,"\n",sep="")
      for (i in Stud) {
	Len <- nchar(StdNms[i]) + nchar(as.character(GB[i,Gd]))
	if (length(UniGrade)) {
	  Tmp <- UniGrade
	} else {
	  BadInput <- T
	  while(BadInput) {
	    cat("    ", StdNms[i], 
		rep(".", max(0,40 - Len)), 
		"(", as.character(GB[i,Gd]),") ",
		sep = "")
	    Tmp <- readline()	
	    if(!ValidNum(Tmp))
	      cat("\007Please re-enter\n")
	    else 
	      BadInput <- F
	  }
	}
	if (charmatch(Type,c("new","delete","fix","inc"))==3) {
	  GB[i,Gd] <- as.numeric(Tmp)
	} else {
	  # If is.na(GB[i,Gd]) && is.na(as.numeric(Tmp))
	  #  Then GB[i,Gd] stays NA
	  # If !is.na(GB[i,Gd]) && is.na(as.numeric(Tmp))
	  #  Then GB[i,Gd] is unchanged
	  if (is.na(GB[i,Gd]) && !is.na(as.numeric(Tmp)))
	    GB[i,Gd] <- as.numeric(Tmp)
	  else if (!is.na(GB[i,Gd]) && !is.na(as.numeric(Tmp)))
	    GB[i,Gd] <- GB[i,Gd] + as.numeric(Tmp)
	}
	
      }
      cat("\n")
    } 
  }
  # Save table
  return(PutTab(GB, BkNm, Talk=T))
}

#
#  Adding students to an existing gradebook still needs work!
#
#




"GBaddstud" <- function(Class, Sec, Type="new", GBdf=NA, 
			Studs=NULL,SS=NULL,Em=NULL)
{
# GBdf is only intended to be used by other functions.
# Student names in string vectors can be given via Studs; if this is done,
# then you can also specify SS (soc sec) and/or Em (email)

    TabNm <- MkTabNm(Class, Sec)
    Sec <- MkSecNm(Sec)
    if (missing(GBdf)) {
      if (is.null(GB <- GetTab(TabNm))) return(NULL)
    } else
      GB <- GBdf
    StudNm <- row.names(GB)
    if (length(StudNm)==0)
      StudNm <- attr(GB,"StudNms")
    if (is.null(GBtxt<-attr(GB,"GBtxt")))
      GBtxt <- list() # give old GB's an empty list
    Email <- GBtxt$Email
    SocSec <- GBtxt$SocSec
    nStud <- length(StudNm)
    nCol <- dim(GB)[2]	
    #
    # Too much error checking...
    #
    if (!missing(Type)) {
      Tmp <- charmatch(Type,c("new","delete","fix"))
      if (is.na(Tmp)) {
	cat("Type keyword is not matched; must be one of 'new', 'delete' or 'fix'\n")
	return(NULL)
      }
      if (Tmp==0) {
	cat("Type keyword is not uniquely matched; must match one of 'new', 'delete' or 'fix'\n")
	return(NULL)
      }
    }
    if ( (!missing(SS) && missing(Studs)) ||
	 (!missing(Em) && missing(Studs))  ) {
             cat("SS or Em can only be specified if Studs is.\n")
      return(NULL)
    }
    if (!missing(Studs) &&!(is.vector(Studs) && is.character(Studs))) {
      cat("Studs must be a chacter vector\n")
      return(NULL)
    }
    if (!missing(SS)) {
      if (!(is.vector(SS) && is.character(SS))) {
	cat("Studs must be a chacter vector\n");return(NULL)
      }
      if (length(SS) != length(Studs))  {
	cat("SS must have same length as Studs\n");return(NULL)
      }
    }
    if (!missing(Em)) {
      if(!(is.vector(Em) && is.character(Em))) {
	cat("Em must be a chacter vector\n");return(NULL)
      }
      if (length(Em) != length(Studs))  {
	cat("Em must have same length as Studs\n");return(NULL)
      }
    }

    #
    # Add names until blank
    #
    if (charmatch(Type,c("new","delete","fix"))==1) {
      if (missing(Studs)) {
	cat("Enter new student info (blank name to end)\n")
	NewStudNm <- as.character(c())
	NewSocSec <- switch(1+(!nStud || !is.null(SocSec)),
			    c(),as.character(c()))
	NewEmail <-  switch(1+(!nStud || !is.null(Email)),
			    c(),as.character(c()))
	Cnt <- 0
	while(T) {
	  cat(" Lastname,Firstname  : ")
	  Tmp <- readline()
	  if(Tmp != "") {
	    Cnt <- Cnt + 1
	    NewStudNm[Cnt] <- Tmp
	  } else {
	    break
	  }
	  if (is.character(NewSocSec)) {
	    cat(" Soc Sec (no dashes) : ")
	    NewSocSec[Cnt] <- readline()
	  }
	  if (is.character(NewEmail)) {
	    cat(" Email id            : ")
	    NewEmail[Cnt] <- readline()
	  }
	}
      } else {
	NewStudNm <- Studs
	Cnt <-length(Studs)
	NewSocSec <- switch(1+missing(SS),SS,NULL)
	NewEmail <- switch(1+missing(Em),Em,NULL)
      }
      StudNm <- c(StudNm,NewStudNm)
      SocSec <- c(SocSec,NewSocSec)
      Email <- c(Email,NewEmail)

      GBtxt <- lapply(GBtxt,function(l,a)c(l,a),rep("",Cnt))
      GBtxt$SocSec <- SocSec
      GBtxt$Email <- Email

    } else { # "delete" or "fix"

      NewStudNm <- NULL
      if (charmatch(Type,c("new","delete","fix"))==2) {
	rm.stud <- T
	cat("\nEnter Student to Delete (0 to exit)...")
      } else {
	rm.stud <- F
	cat("\nEnter Student to Fix (0 to exit)...")
      }
      
      Stud <- menu(StudNm)
      if (Stud==0)
	return(NULL)
      
      if (rm.stud==T) {
	TmpNm<-StudNm[Stud]
	StudNm<-StudNm[-Stud]
	# if nCol==0 then we take care of it below
	if (nCol==1) {
	# Stupid!!! Hack needed b/c S sees GB[-Stud,] as vector
	  attr(GB,"class") <- NULL  # Close your eyes
	  GB[[1]] <- GB[[1]][-Stud]
	  attr(GB,"row.names") <- StudNm
	  attr(GB,"class")<-"data.frame" # Now open them
	} else if (dim(GB)[2]>1) {
	  GB <- GB[-Stud,]
	}
	GBtxt <- lapply(GBtxt, function(l,s){l[-s]},Stud)
	cat("Student \"",TmpNm,"\" deleted.\n",sep="")
      } else {
	cat(" Enter student info\n")
	cat(" Lastname,Firstname (old: ",StudNm[Stud],"): ",sep="")
	StudNm[Stud] <- readline()
	if (!is.null(GBtxt$SocSec)) {
	  cat(" Soc Sec (no dashes) (old: ",GBtxt$SocSec[Stud],"): ",sep="")
	  GBtxt$SocSec[Stud] <- readline()
	}
	if (!is.null(GBtxt$Email)) {
	  cat(" Email id (old: ",GBtxt$Email[Stud],"): ",sep="")
	  GBtxt$Email[Stud] <- readline()
	}
      }
    }	    

    # Pack the new/changed data
    attr(GB,"GBtxt") <- GBtxt
    if (all(dim(GB) == c(0, 0))) {
      attr(GB, "StudNms") <- StudNm
    } else if (charmatch(Type,c("new","delete","fix"))!=2) {
      if (length(NewStudNm)>0) {
	Tmp <- cbind(matrix(rep(NA, Cnt * nCol), ncol = nCol))
	dimnames(Tmp) <- list(NewStudNm,NULL)
	GB <- rbind(GB, Tmp)
      } else {
	row.names(GB) <- StudNm
      }
    }
    GB <- SortTabSt(GB)

    PutTab(GB, TabNm, Talk = T)
}




"GBget" <- function(Class,Sec=NA,file=NA,Print=F,
		    SS=F,Em=T,SecNum=T) 
{
    TabNms <- GBexist(Class,Sec)
    if (length(TabNms)==0) {
	cat("No matching gradebooks\n")
	return(NULL)
    }

    nTabs <- length(TabNms)
    Tabs <- list()
    iTabs <- c()
    GdTypC <- list()
    Sec <- c()
    SecNms <- ""
    StudNms <- c()
    SocSecs <- c()
    Emails <- c()
    for (i in 1:nTabs) {
	if (is.null(Tabs[[i]] <- GetTab(TabNms[i]))) return(NULL)
	iTabs <- c(iTabs,rep(i,dim(Tabs[[i]])[1]))
	GdTypC[[i]] <- attr(Tabs[[i]],"GBtypeC")
	Sec <- c(Sec,rep(attr(Tabs[[i]],"GBsec"),dim(Tabs[[i]])[1]))
	SecNms <- paste(SecNms,attr(Tabs[[i]],"GBsec"),sep="")
	StudNms <- c(StudNms,row.names(Tabs[[i]]))
	Tmp <- attr(Tabs[[i]],"GBtxt")$SocSec
	SocSecs <- c(SocSecs,switch(1+is.null(Tmp),Tmp,
				    rep("",dim(Tabs[[i]])[1])))
	Tmp <- attr(Tabs[[i]],"GBtxt")$Email
	Emails <- c(Emails,switch(1+is.null(Tmp),Tmp,
				    rep("",dim(Tabs[[i]])[1])))
    }
    PreCols <- list(Sec=Sec)
    if (length(SocSecs))
      if (SS && any(SocSecs!=""))
	PreCols <- c(PreCols,list(SocSec=SocSecs))
    if (length(Emails))
      if (Em && any(Emails!=""))
      PreCols <- c(PreCols,list(Email=Emails))
    nPreCol <- length(PreCols)
    nStud <- length(StudNms)
    GBTyp <- attr(Tabs[[1]], "GBtypes") # should be same for all
    
    GB <- NULL
    GBtypC <- list()
    NAv <- rep(NA,nStud)
    for (i in 2:dim(GBTyp)[1]) {
	Gd <- NULL
	GdTypCLen <- list()
	for (j in 1:nTabs) {
	    GdC <- GdTypC[[j]][[i]]
	    if (length(GdC)==0)
	      next
	    if (is.null(Gd)) Gd <- matrix(NAv)
	    if (dim(Gd)[2]<length(GdC)) {
		Gd <- cbind(Gd,matrix(rep(NAv,
					  length(GdC)-dim(Gd)[2]),
				      nrow=nStud))
	    }
	    Gd[iTabs==j,1:length(GdC)] <- as.matrix(Tabs[[j]][,GdC])
	}
	if (is.null(Gd)) {
	    GBtypC[[i]] <- numeric(0)
	} else {
	    if (GBTyp[i,"bMult"]=="T")
	      Tmp <- 1:dim(Gd)[2]
	    else {
		if (dim(Gd)[2] != 1)
		  stop(paste("Grade type",GBTyp[i,"Type"],"should only have one grade... it has many???"))
		Tmp <- NULL
	    }
	    dimnames(Gd) <- list(NULL,
				 paste(GBTyp[i,"ColNm"],Tmp,sep=""))
	    GB <- cbind(GB,Gd)
	    # Plus one is for Sec to be added below
	    GBtypC[[i]] <- (dim(GB)[2]-(dim(Gd)[2]-1):0)+nPreCol
	}
    }

    if (is.null(GB)) 
      GB <- data.frame(NULL)
    else {
	GB <- data.frame(PreCols,GB)
	GBtypC[[1]] <- 1
	row.names(GB) <- make.names(StudNms,unique=T)
    }
    attr(GB,"GBtypes") <- GBTyp
    attr(GB,"GBtypeC") <- GBtypC

    #
    #  SPH/Biostat modification
    #
    #  Optionally, at the last minute, change sections to numbers
    #
    if (SecNum) {
      GB$Sec <- AsciiToInt(as.character(GB$Sec))-AsciiToInt("A")+1
    }

    row.names(GB) <- format(row.names(GB))

    if (!missing(file) || (Print==T)) {
	if (missing(file)) {
	  file <- paste("/tmp/",Class,SecNms,".txt",sep="")
          Remove <- T
        } else {
          Remove <- F
        }
	Tmp <- options()
	options(length = dim(GB)[1]+5, width = 40+10*dim(GB)[2])
	sink(file=file)
	print(GB)
	sink()
	options(Tmp)
	if (Print==T) {
	    if ((PRNT<-getenv("PRINTER"))=="")
	      PRNT <- "student_lp"
	    unix.shell(paste("enscript -r -fCourier7 -P",PRNT,
		       " ",file,sep=""),
		 shell="/bin/sh")
	}
        if (Remove)
          unix.shell(paste("/bin/rm -f",file),shell="/bin/sh")
    }

    GB
}


"GBsummary" <- function(Class,Gd,Sec=NA,rm.z=F,...) {
    
    GB <- GBget(Class,Sec,...)
    if (is.null(GB))
      return(NULL)

    Tmp <- charmatch(Gd,names(GB))
    if (is.na(Tmp) || Tmp==0) {
	cat("No (uniquely) matching grade found; must be one of:",names(GB),"\n")
	return(NULL)
    }

    if (rm.z==T) {
	GB <- GB[GB[,Gd]!=0,]
	cat("NOTE: Zeros removed\n")
    }

    Tmp<-match(Gd,names(GB))
    GBtypeC <- attr(GB,"GBtypeC")
    iGd <- NA
    for (i in 1:length(GBtypeC)) {
	if (!is.na(nGd<-match(Tmp,GBtypeC[[i]]))) {
	    iGd<-i
	    break
	}
    }
    if (is.na(iGd))
      stop("Weird problem; bug Tom")

    GdNm <- attr(GB,"GBtypes")[iGd,"Type"]

    GB.S_split(GB[,Gd],GB[,"Sec"])

    if (length(GB.S)>1) {
	cat("--------------------- ",GdNm," ",nGd,": All Sections ",
	    "---------------------\n",sep="")
	stem(GB[,Gd])
    }

    for (i in 1:length(GB.S)) {
	cat("----------------------- ",GdNm," ",nGd,": Section ", 
	    names(GB.S)[i],
	    " -----------------------\n",sep="")
	stem(GB.S[[i]])
    }

}


#
#  End of functions that user should directly call
#
#




"DefaultGBtypes"<- function()
{
    #
    # "Section" ***must*** be in the first row
    #

    #                   Type      Column    Grade    Mult
    #                   Name    Name/Prefix  T/F      T/F
    Types <- matrix(c("Section",  "Sec",     "F",     "F", 
		      "Homework", "H",       "T",     "T",
		      "Lab",      "L",       "T",     "T", 
		      "Special",  "S",       "T",     "T", 
		      "Exam",     "E",       "T",     "T", 
		      "Final",    "F",       "T",     "F", 
		      "Overall",  "OVL",     "T",     "F"), 
		    byrow = T, ncol = 4)  
    # row names are used to index into GBtypeC list
    dimnames(Types) <- list(1:dim(Types)[1], 
	c("Type", "ColNm", "bGrade", "bMult"))
    Types
}

"MkTabNm" <- function(Class, Sec)
{
    Sec <- MkSecNm(Sec)
    paste("GB.", Class, ".", Sec, sep = "")
}

"MkSecNm" <- function(Sec)
{
    if (is.numeric(Sec))
      Sec <- LETTERS[Sec]
    if(!is.character(Sec) || nchar(Sec) != 1)
      stop(paste("Bad section letter: '", Sec, "'\n", sep = ""))
    Sec <- casefold(Sec,upper=T)
    Sec
}

"GBexist" <- function(Class, Sec=NA)
{
    RegExp <- "A-Z"
    if (!is.na(Sec)) {
        if (is.numeric(Sec) || (nchar(Sec)==1)) {
	    Tmp <- MkTabNm(Class, Sec)
	    if (TabExist(Tmp))
	      return(Tmp)
	    else
	      return(NULL)
	} else {
	    RegExp <- Sec
	}
    }

    # Choose database
    GH <- getenv("GRADE.HOME")	# is "" if not env var
    if(exists("GRADE.HOME"))
      GH <- GRADE.HOME

    # Setup database
    if(GH != "") {
	Pos <- 2
	attach(GH, pos = Pos)
        Detch <- T
    } else {
	Pos <- 1
    }
    
    Tmp <- objects(pattern=paste("GB\\.",Class,"\\.[",RegExp,"]$",sep=""),
		   where = Pos) 

    if(GH != "")
      detach(GH)
      
    if (length(Tmp)==0)
      return(NULL)
    else
      return(Tmp)
}    

"TabExist" <- function(GBnm)
{
    # Choose database
    GH <- getenv("GRADE.HOME")	# is "" if not env var
    if(exists("GRADE.HOME"))
      GH <- GRADE.HOME

    # Setup database
    if(GH != "") {
	Pos <- 2
	attach(GH, pos = Pos)
    } else {
	Pos <- 1
    }

    # Does valid gradebook exist?
    Exist<-F
    if (exists(GBnm,where = Pos))
      if (ValidTab(get(GBnm, where = Pos)))
	Exist<-T

    if (GH != "")
      detach(GH)

    Exist
}    

"GetTab" <- function(GBnm, Talk = F)
{
    # Choose database
    GH <- getenv("GRADE.HOME")	# is "" if not env var
    if(exists("GRADE.HOME"))
      GH <- GRADE.HOME

    # Setup database
    if(GH != "") {
	Pos <- GH
	DBnm <- GH
    } else {
	Pos <- 1
	DBnm <- search()[Pos]
    }
    # Does gradebook exist?
    if (!exists(GBnm,where = Pos)) {
	cat("\007Gradebook '",GBnm,"' not found in '",DBnm,"'\n",sep="")
	return(NULL)
    }
    # Get it and check it
    GB <- get(GBnm, where = Pos)
    if(!ValidTab(GB))
      stop(paste("Bad Table: '", GBnm, "'\n", sep = ""))

    if(Talk)
      cat("Read '", GBnm, "' from '", DBnm, "'.\n", sep = "")

    GB
}

"PutTab" <- function(Tab, GBnm, Talk = F)
{
    # Choose database
    GH <- getenv("GRADE.HOME")	# is "" if not env var
    if(exists("GRADE.HOME"))
      GH <- GRADE.HOME

    # Set up database
    if (GH != "") {
	Pos <- GH
	DBnm <- GH
    } else {
	Pos <- 1
	DBnm <- search()[Pos]
    }

    # Check that we have priveledges
    if (unix.shell(paste("touch ",DBnm,"/...dummy",sep=""),
		   shell="/bin/sh",output=F)==0) {
	unix.shell(paste("/bin/rm ",DBnm,"/...dummy",sep=""),
		   shell="/bin/sh",output=F)
    } else {
	cat("\007No write permissions for '",DBnm,"'\nTable not saved.")
	return(NULL)
    }

    # Save backup if there's an existing GB
    if (exists(GBnm,where = Pos)) {
	Tmp <- get(GBnm, where = Pos)
	assign(paste(GBnm, ".bak", sep = ""), Tmp, where = Pos)
    }

    # Save it!
    assign(GBnm, Tab, where = Pos)

    if(Talk)
      cat("Wrote '", GBnm, "' to '", DBnm, "'.\n", sep = "")

    return()
}

"RmTab" <- function(GBnm, Talk = F)
{
    # Choose database
    GH <- getenv("GRADE.HOME")	# is "" if not env var
    if(exists("GRADE.HOME"))
      GH <- GRADE.HOME

    # Set up database
    if (GH != "") {
	Pos <- GH
	DBnm <- GH
    } else {
	Pos <- 1
	DBnm <- search()[Pos]
    }

    # Check that we have priveledges
    if (unix.shell(paste("touch ",DBnm,"/...dummy",sep=""),
		   shell="/bin/sh",output=F)==0) {
	unix.shell(paste("/bin/rm ",DBnm,"/...dummy",sep=""),
		   shell="/bin/sh",output=F)
    } else {
	cat("\007No write permissions for '",DBnm,"'\nTable not deleted.")
	return(NULL)
    }

    # Make a backup just in case
    if (exists(GBnm,where = Pos)) {
	Tmp <- get(GBnm, where = Pos)
	assign(paste(GBnm, ".bak", sep = ""), Tmp, where = Pos)
    }

    # Kill it
    remove(GBnm, where = Pos)

    if(Talk)
      cat("Deleted '", GBnm, "' from '", DBnm, "'.\n", sep = "")

    return()
}

"SortTabSt" <- function(Tab)
{
    if(!ValidTab(Tab))
      stop("Bad Table")
    if (dim(Tab)[2]==0) {
      Ord <- order(attr(Tab,"StudNms"))
      attr(Tab,"StudNms") <- attr(Tab,"StudNms")[Ord]
    } else {
      Ord <- order(row.names(Tab))
      if (dim(Tab)[2]==1) {
	Tab[[1]] <- Tab[[1]][Ord]
	row.names(Tab)<-row.names(Tab)[Ord]
      } else {
	Tab <- Tab[Ord,]
      }
    }

    attr(Tab,"GBtxt") <- lapply(attr(Tab,"GBtxt"),
				  function(v,o)v[o],Ord)

    Tab
}

"ValidNum" <- function(Str)
{
    # Seems like there should be an easier way to 
    # test for a valid number...

  OptSv <- options(warn=-1)

  VN <- !is.na(as.numeric(Str))

  options(OptSv)

  VN

}

"ValidTab" <- function(Tab)
{
  if(is.data.frame(Tab)) {
    TabAtt <- names(attributes(Tab))
    if(!is.na(charmatch("GBtypes", TabAtt)) &&
       !is.na(charmatch("GBtypeC", TabAtt))) {
      Szs <- sapply(attr(Tab,"GBtxt"),function(e)length(e))
      if (length(Szs)>0) {
	nStud <- ifelse(dim(Tab)[2],
			dim(Tab)[1],
			length(attr(Tab,"StudNms")))
	if (all(Szs==nStud)) {
	  return(T)
	} else {
	  cat("GBtxt length mismatch!",Szs,"\n")
	}
      } else {
	return(T)
      }
    }
  }
  F
}

