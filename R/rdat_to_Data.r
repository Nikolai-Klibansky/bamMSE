#' Build MSEtool Data object from bam rdat object
#'
#' @param rdat BAM output rdat (list) object read in with dget()
#' @param Data MSEtool Data object to start with
#' @param herm Is the species hermaphroditic? If "gonochoristic", use female maturity. If "protogynous", use a function of male and female maturity.
#' @param nsim see \code{\link[MSEtool]{OM-class}}
#' @param genus_species Genus and species names separated by a space (e.g. "Centropristis striata").
#' @param Region see \code{\link[MSEtool]{Data-class}}
#' @param Fref_name Name of F reference as named in rdat$parms list (e.g. Fmsy, F30)
#' @param Rec see \code{\link[MSEtool]{Data-class}}. Set to "bam_recruits" to set this value to the vector of recruits estimated by bam for years where rec devs were estimated. Set to NULL to leave it empty.
#' @param CAA_abb Abbreviation for identifying the observed age comp matrix for the catch-at-age (CAA) slot. Names of age compositions in the BAM rdat comp.mats list are expected to follow the naming convention "acomp.abb.ob". Examples from SEDAR 53 Red Grouper: "CVT", "HB", "cH". Set to "all" or "none" to use all or none of the age comps, respectively.
#' @param CAL_abb Abbreviation for identifying the observed index for the catch-at-length (CAL) slot. Analogous to CAA_abb. Names of length compositions in the BAM rdat comp.mats list are expected to follow the naming convention "lcomp.abb.ob". Set to "all" or "none" to use all or none of the length comps, respectively.
#' @param Ind_abb Abbreviation for identifying the observed index of abundance for the Ind slot. Names of indices in the BAM rdat t.series matrix are expected to follow the naming convention "U.abb.ob". Examples from SEDAR 53 Red Grouper: "CVT", "HB", "cH". If multiple (valid) abb values are provided, the corresponding indices will be averaged (geomean) and restandardized to a mean of 1. Abbreviations that don't match any indices will be ignored. Set to "all" or "none" to use all or none of the indices, respectively.
#' @param Mat_age1_max Limit maximum value of proportion mature of first age class (usually age-0 or age-1). Models sometimes fail when maturity of first age class is too high (e.g. >0.5)
#' @param length_sc  Scalar (multiplier) to convert length units including wla parameter. For example if L in wla*L^wlb is in mm then length_sc should be 0.1 to convert to cm. (MSEtool examples tend to use cm whereas BAM uses mm.)
#' @param wla_sc Scalar (multiplier) to convert wla parameter to kilograms (kg). Setting a value for wla_sc will override settings for wla_unit and wla_unit_mult. If null, the function will try to figure out if the weight unit of wla was g, kg, or mt based on the range of the exponent to convert to kg. The wla parameter will also be scaled by 1/length_sc^wlb.
#' @param wla_unit Character. Basic unit that you want weight to be in, which is applied to the wla parameter. Accepted units are those used by measurements::conv_unit function (\code{\link[measurements]{conv_unit})}.
#' @param wla_unit_mult Numeric. Multiplier to apply to wla_unit (e.g. 10, 100, 1000)
#' @param catch_sc  Scalar (multiplier) for catch. BAM catch is usually in thousand pounds (klb). The default 1 maintains that scale.
#' @param CV_vbK see \code{\link[MSEtool]{Data-class}}
#' @param CV_vbLinf see \code{\link[MSEtool]{Data-class}}
#' @param CV_vbt0 see \code{\link[MSEtool]{Data-class}}
#' @param CV_Cat see \code{\link[MSEtool]{Data-class}}
#' @param combine_indices Indicate whether indices should be combined or remain separate. logical.
#' @param fleet_sel_abb_key Data frame with two columns "U" and "sel" for indicating the abbreviations for individual indices and the
#' selectivity that should be used with it if the abbreviation for that index cannot be matched to a selectivity. This is used to build
#' the AddIndV slot to correspond to the AddInd and CV_AddInd slots
#' @param AddInd_order A character vector of abbreviations used in AddInd slot, to attempt to sort the indices. The function will then
#' attempt to sort AddInd, CV_AddInd, and AddIndV in this order. The order of indices doesn't matter in most cases, but when using
#' interim management procedures built with \code{\link[SAMtool]{make_interimMP}} the interim procedure will use the first index.
#' \code{AddInd_order} does not need to include the abbreviations for all indices. Simply indicating the abbreviation of a single index
#' will result in that index being first in the order followed by the remaining indices in the order they were provided. A value of "" will not modify the order of the indices.
#' @param AddIndFleetType_key Named numeric vector indicating the units of each fleet type (s=survey, r=recreational, c=commercial) used
#' to determine AddIunits (see \code{\link[MSEtool]{Data-class}}). The names of the values in the key are matched to the first letter of the
#' abbreviations of the indices.
#' @details
#'
#' @keywords bam stock assessment fisheries MSEtool
#' @author Nikolai Klibansky
#' @export
#' @examples
#' \dontrun{
#' # Convert Black Sea Bass rdat to Data object
#' Data_BlackSeaBass <- rdat_to_Data(rdat_BlackSeaBass)
#' # Run statistical catch-at-age model
#' SCA(1,Data_BlackSeaBass)
#'
#' }

rdat_to_Data <- function(
  rdat,
  Data = NULL,
  herm = NULL,
  nsim=1,
  genus_species=NULL,
  Region="Southeast US Atlantic",
  Fref_name = "Fmsy",
  Rec="bam_recruits",
  CAA_abb="all",
  CAL_abb="all",
  Ind_abb="all",
  CV_vbK=0.001, CV_vbLinf=0.001, CV_vbt0=0.001,
  CV_Cat=NULL,
  Mat_age1_max = 0.49,
  length_sc=0.1,
  wla_sc=NULL,
  wla_unit="lbs",
  wla_unit_mult=1000,
  catch_sc=1,
  combine_indices=FALSE,
  fleet_sel_abb_key=data.frame("U"=c("sTV","rHB","rGN"),"sel"=c("sCT","rGN","rHB")),
  AddInd_order = c("sTV","sCT","sVD","sBL","sVL","sBT","sFT","rHB","rHB.D","cDV","cHL","cLL","cOT","cPT","cGN","rGN"),
  AddIndFleetType_key = c("s"=0,"r"=0,"c"=1)
)
{
if(is.null(Data)){
  Data <- new('Data')
  # Empty all slots to create completely blank Data object
  # sn <- slotNames(Data)
  # for(sn_i in sn){
  #   slot_i <- slot(Data,sn_i)
  #   cls_i <- class(slot_i)
  #   if(cls_i=="character"){
  #     slot_i <- ""
  #   }else{
  #     slot_i <- slot_i*NA
  #   }
  #   slot(Data,sn_i) <- slot_i
  # }
}


  rdat <- standardize_rdat(rdat)

  info <- rdat$info
  parms <- rdat$parms
  parm.cons <- rdat$parm.cons
  parm.tvec <- rdat$parm.tvec
  a.series <- rdat$a.series
  t.series <- rdat$t.series
  comp.mats <- rdat$comp.mats
  sel.age <- rdat$sel.age
  B.age <- rdat$B.age

  styr <- parms$styr
  endyr <- parms$endyr

  Name <- gsub(" ","",stringr::str_to_title(info$species))

  # MSEtool expects age-based data to begin with age 0
  if(min(a.series$age)>0){
    message(paste(Name,": Minimum age > 0. Age-based data (a.series) linearly extrapolated to age-0"))
    a.series <- data_polate(a.series,xout=0:max(a.series$age))
    a.series <- data_lim(a.series,xlim=c(0,Inf))
    a.series <- data_lim(a.series,xname=c("prop.female","prop.male","mat.female","mat.male"),xlim=c(0,1))
    a.series <- as.data.frame(a.series)
    rownames(a.series) <- a.series$age
  }
  age <- a.series$age

  t.series <- t.series[paste(styr:endyr),]

  for(i in names(sel.age)){
    sel.i <- sel.age[[i]]
    if(grepl("^sel.v",i)){
    if(min(as.numeric(names(sel.i)))>0){
      message(paste0(Name,": Minimum age of ",i," > 0. ", i, " linearly extrapolated to age-0"))
        sel.i <- cbind("age"=as.numeric(names(sel.i)),"sel"=sel.i)
        sel.i <- data_polate(sel.i,xout=0:max(sel.i[,"age"]))
        sel.i <- data_lim(sel.i,xname="sel",xlim=c(0,1))
        # sel.i <- as.data.frame(sel.i)
        sel.age[[i]] <- setNames(sel.i[,"sel"],sel.i[,"age"])
      }
    }
    if(grepl("^sel.m",i)){
      if(min(as.numeric(colnames(sel.i)))>0){
        message(paste0(Name,": Minimum age of ",i," > 0. ", i, " linearly extrapolated to age-0"))
        sel.i <- cbind("age"=as.numeric(colnames(sel.i)),t(sel.i))
        sel.i <- data_polate(sel.i,xout=0:max(sel.i[,"age"]))
        sel.i <- data_lim(sel.i,xname=colnames(sel.i)[colnames(sel.i)!="age"],xlim=c(0,1))
        sel.i <- t(sel.i)
        colnames(sel.i) <- sel.i["age",]
        sel.i <- sel.i[rownames(sel.i)!="age",]
        sel.age[[i]] <- sel.i
      }
    }
  }

Common_Name <-stringr::str_replace_all(Name,"(?<=[a-z])(?=[A-Z])"," ")
if(is.null(genus_species)){genus_species <- bamStockMisc[Name,"Species"]}
if(is.null(herm)){herm <- bamStockMisc[Name,"herm"]}

B.to.klb <- local({
  if(info$units.biomass%in%c("mt","metric tons")){
    out <- 2.204624}else{
      warning("units.biomass not equal to metric tons")
    }
  return(out)
})

catch.raw <- t.series$total.L.klb*catch_sc
cc.yrCat <- complete.cases(t.series$year,catch.raw) # Complete cases for catch data series
year <- t.series$year[cc.yrCat]
nyear <- length(year)
catch <- catch.raw[cc.yrCat]
recruits <- setNames(t.series$recruits,t.series$year)

# Scale BAM recruits to approximate age-0 recruits (most BAM models use age-1 for recruitment)
Nage_F0 <- exp_decay(age=age,Z=a.series$M,N0=1)
bam_age_R <- min(rdat$a.series$age)
R_sc <- Nage_F0["0"]/Nage_F0[paste(bam_age_R)] # Scaling factor for recruitment
recruits_sc <- recruits*R_sc # Scaled value of BAM R0 to approximate unfished numbers at age-0

Linf <- parm.cons$Linf[8]
K <- parm.cons$K[8]
t0 <- parm.cons$t0[8]

LenCV <- parm.cons$len.cv.val[8]

M.constant <- ifelse(!is.null(parms$M.constant),
                     parms$M.constant,
                     tail(a.series$M,1))

if(Fref_name=="Fmsy"){
  Cref <- parms$msy.klb*catch_sc
  Bref <- parms$Bmsy
  Fref <- parms$Fmsy
}
if(Fref_name=="F30"){
  Cref <- parms$L.F30.klb*catch_sc
  Bref <- parms$B.F30
  Fref <- parms$F30
}

Bcurrent <- t.series[paste(endyr),"B"]
B0 <- parms$B0

SSBcurrent <- t.series[paste(endyr),"SSB"]
SSB0 <- parms$SSB0

#An estimate of absolute current vulnerable abundance, converted to klb (needs to be in same units as catch)
if(min(as.numeric(colnames(B.age)))>0){
  message(paste0(Name,": Minimum age of B.age > 0. B.age linearly extrapolated to age-0"))

  tB.age <- t(B.age)
  tB.age <- cbind("age"=as.numeric(rownames(tB.age)),tB.age)
  tB.age <- data_polate(tB.age,xout=age)
  tB.age <- tB.age[,colnames(tB.age)!="age"]
  tB.age <- data_lim(tB.age,xlim=c(0,Inf))
  rownames(tB.age) <- age
  B.age <- t(tB.age)
}


Abun <- sum(B.age[paste(endyr),]*B.to.klb*sel.age$sel.v.wgted.tot)*catch_sc

FMSY_M <- Fref/M.constant
BMSY_B0 <- Bref/B0
Dep <- SSBcurrent/SSB0
LHYear <- endyr

# Recruitment for years where recruitment deviations were estimated
if(!is.null(Rec)){
  if(identical(Rec,"bam_recruits")){
    Rec <- local({
      year_nodev <- parm.tvec$year[is.na(parm.tvec$log.rec.dev)]
      recruits[paste(year_nodev)] <- NA
      matrix(data=recruits_sc,nrow=nsim,ncol=length(recruits_sc),dimnames=list("sim"=1:nsim,"year"=year))
    })
  }
}else{
  Rec <- Data@Rec
}

# Catch (Cat): Total annual catches (NOTE: MSEtool wants Cat to be a matrix)
Cat <- matrix(data=catch,nrow=nsim,ncol=length(catch),dimnames=list("sim"=1:nsim,"year"=year))

# Catch CV
if(is.null(CV_Cat)){
CV_Cat <- matrix(0.05,nrow=nsim,ncol=nyear,dimnames=list("sim"=1:nsim,"year"=year))
}

# Abundance Index (Ind): Relative abundance index (NOTE: MSEtool wants Ind to be a matrix)
if(!Ind_abb[1]=="none"){
IndCalc <- local({
  D <- t.series[cc.yrCat,]
  x <- names(D)
  Ind_names_all <- x[grepl(pattern="U.",x=x)&grepl(pattern=".ob",x=x)]
  if(Ind_abb[1]=="all"){
  Ind_names <- Ind_names_all
  }else{
    Ind_names <- paste("U",Ind_abb,"ob",sep=".")
  }
  Ind_names <- Ind_names[Ind_names%in%names(D)] # Identify valid names
  if(length(Ind_names)==0){
    message(paste("Ind_abb does not match any index names in the rdat t.series. Ind will be the geometric mean of all available indices:",paste(Ind_names_all,collapse=", ")))
    Ind_names <- Ind_names_all
  }
  CV_Ind_names <- paste0("cv.U.",gsub("U.|.ob","",Ind_names))
  CV_Ind_names <- CV_Ind_names[CV_Ind_names%in%names(D)] # Identify valid names

  D[D==-99999] <- NA
  D_Ind <- D[,Ind_names,drop=FALSE]
  D_CV_Ind <- D[,CV_Ind_names,drop=FALSE]

  names(D_Ind) <- gsub("^U.|.ob$","",names(D_Ind))
  names(D_Ind) <- gsub("^cv.U.","",names(D_CV_Ind))

  A_Ind <- local({
    a <- abind::abind(replicate(n=nsim,D_Ind,simplify = FALSE),along=3)
    aperm(a,perm=c(3,2,1))
  })

  dimnames(A_Ind)[[1]] <- 1:nsim

  A_CV_Ind <- local({
    a <- abind::abind(replicate(n=nsim,D_CV_Ind,simplify = FALSE),along=3)
    aperm(a,perm=c(3,2,1))
  })

  dimnames(A_CV_Ind)[[1]] <- 1:nsim
  dimnames(A_CV_Ind)[[2]] <- gsub("^cv.U.","",dimnames(A_CV_Ind)[[2]])

  Ind <- apply(D_Ind,1, geomean) # Calculate geometric mean of all indices
  Ind <- Ind/mean(Ind, na.rm=TRUE) # Restandardize to mean of 1
  Ind <- matrix(data=Ind,nrow=1,ncol=length(Ind))
  Ind[is.nan(Ind)] <- NA

  CV_Ind <- apply(D_CV_Ind,1, geomean) # Calculate geometric mean of all index CVs
  CV_Ind <- matrix(data=CV_Ind,nrow=1,ncol=length(CV_Ind))
  CV_Ind[is.nan(CV_Ind)] <- NA

  return(list("A_Ind"=A_Ind,"A_CV_Ind"=A_CV_Ind,"Ind_Combined"=Ind,"CV_Ind_Combined"=CV_Ind))
})

if(combine_indices){
  slot(Data,"Ind") <- IndCalc$Ind_Combined
  slot(Data,"CV_Ind") <- IndCalc$CV_Ind_Combined
}else{
  AddInd <- IndCalc$A_Ind
  CV_AddInd <- IndCalc$A_CV_Ind

  # Reorder AddInd and CV_AddInd according the AddInd_order
  AddInd_names <- AddInd_names_init <- dimnames(AddInd)[[2]]
  AddInd_names_new <- AddInd_names[!AddInd_names%in%AddInd_order]
  # If there are index names not included in AddInd_order then just add them to the end of AddInd_order, in the order they were provided
  if(length(AddInd_names_new)>0){
    AddInd_order <- c(AddInd_order,AddInd_names_new)
  }
  AddInd_names <- factor(AddInd_names,levels=AddInd_order)
  AddInd_names_o <- order(AddInd_names)

  AddInd <- AddInd[,AddInd_names_o,,drop=FALSE]
  CV_AddInd <- CV_AddInd[,AddInd_names_o,,drop=FALSE]
  AddIndFleetType <- str_extract(AddInd_names_o,"^{1}.") # Get first letter of AddInd_names_o

  slot(Data,"AddInd") <- AddInd
  slot(Data,"CV_AddInd") <- CV_AddInd
  slot(Data,"AddIndType") <- rep(1,dim(AddInd)[2]) # Indices are calculated from the total stock (AddIndType=1), with respect to selectivity
  slot(Data,"AddIunits") <- AddIndFleetType_key[AddIndFleetType] # Indices are calculated from the total stock (AddIndType=1), with respect to selectivity
  }

}

## Identify selectivities associated with indices, landings, and discards
# Combined selectivities
sel_tot <- sel.age$sel.v.wgted.tot
sel_L <- sel.age$sel.v.wgted.L
sel_D <- sel.age$sel.v.wgted.D

if(!combine_indices){
# Fleet-specific selectivities
selNames <- names(sel.age)[!grepl("sel.v.wgted",names(sel.age))]
selNames_D <- selNames[grepl("[A-Za-z]+(\\.D)$",selNames)]  # Selectivities of discards
selNames_LU <- selNames[!grepl("[A-Za-z]+(\\.D)$",selNames)] # Selectivities of landings and/or indices

# Define matrix of selectivity-at-age in the final year available (should be endyr)
M_sel <- matrix(NA,nrow=length(age),ncol=length(selNames),dimnames=list(age,selNames))
for(i in selNames){
  sel_i <- setNames(rep(0,length(age)),age) # Initialize with zeros
  if(grepl("^sel.v",i)){ # For vectors
    sel_i[names(sel.age[[i]])] <- sel.age[[i]][names(sel.age[[i]])]
  }
  if(grepl("^sel.m",i)){ # For matrices (get most recent selectivity-at-age)
    sel_i[colnames(sel.age[[i]])] <- sel.age[[i]][dim(sel.age[[i]])[1],colnames(sel.age[[i]])]
  }
  M_sel[,i] <- sel_i
}

# Match indices to selectivities by abbreviation
AddInd_abb <- dimnames(AddInd)[[2]]
sel_fleet_abb <- unlist(stringr::str_extract_all(colnames(M_sel),"[A-Za-z]+$"))
M_sel_abb <- gsub("^sel.[mv].","",colnames(M_sel)) # Fleet abbreviations used in M_sel colnames

AddIndV <- matrix(NA,nrow=length(age),ncol=length(AddInd_abb),dimnames=list(paste(age),AddInd_abb))
for(abb_i in AddInd_abb){
  if(abb_i%in%M_sel_abb){
    AddIndV[,abb_i] <- M_sel[,match(abb_i,M_sel_abb)]
  }else{
    ma1_i <- match(abb_i,fleet_sel_abb_key$U)
    ma2_i <- match(fleet_sel_abb_key[ma1_i,"sel"],M_sel_abb)
    # Try to match abb_i in fleet_sel_abb_key and then match the selectivity abbreviation among the available selectivities
    if(!is.na(ma1_i)&!is.na(ma2_i)){
      AddIndV[,abb_i] <- M_sel[,ma2_i]
    }else{
      AddIndV[,abb_i] <- sel_tot
      message(paste0("The ",abb_i, " index does not match any of the abbreviations in the available selectivities (", paste(M_sel_abb,collapse=", "),
                     "). Total selectivity will be used. If this is undesirable, please indicate the abbreviation for the selectivity you want to use for the ",
                     abb_i ," index with fleet_sel_abb_key.")
      )
    }

  }
}

# Convert AddIndV to array of correct dimensions
AddIndV <- aperm(replicate(nsim,AddIndV),c(3,2,1))
dimnames(AddIndV)[[1]] <- 1:nsim


slot(Data,"AddIndV") <- AddIndV
}

Dt <- t.series[paste(tail(year,1)),"SSB"]/t.series[paste(year[1]),"SSB"]

# Compute proportion mature at age
pmat <- pmatage(a.series=a.series,Mat_age1_max=Mat_age1_max,herm=herm,age=age)$pmat

# Compute maturity-at-length L50 and L50_95
mat_at_len <- local({
  # Predict proportion mature at from linear interpolation
  age_pr <- seq(min(age),max(age),length=1000)
  pmat_pr <- approx(age,pmat,xout = age_pr)$y

  age50 <- age_pr[which.min(abs(pmat_pr-0.50))] # age at 50% maturity
  age95 <- age_pr[which.min(abs(pmat_pr-0.95))] # age at 95% maturity

  len50 <- vb_len(Linf=Linf, K=K, t0=t0, a=age50)*length_sc # length at 50% maturity
  len95 <- vb_len(Linf=Linf, K=K, t0=t0, a=age95)*length_sc # length at 95% maturity
  return(list("L50"=len50,"L50_95"=len95-len50))
})
L50 <- mat_at_len$L50
L95 <- mat_at_len$L50+mat_at_len$L50_95

# Estimate length at 5% and full (100%) vulnerability (total selectivity) and retention (landings selectivity)
vuln_out <- vulnerability(Vdata = sel_tot, retdata = sel_L, Linf = parm.cons$Linf[8], K = parm.cons$K[8], t0 = parm.cons$t0[8], length_sc=length_sc)

L5 <- vuln_out$L5*length_sc
LFS <- vuln_out$LFS*length_sc

## Age comps
if(!CAA_abb[1]=="none"){
is_acomp <- grepl(x=names(comp.mats),pattern="acomp.",fixed=TRUE)&grepl(x=names(comp.mats),pattern=".ob",fixed=TRUE)
if(any(is_acomp)){
  acomp_names_all <- names(comp.mats)[is_acomp]
if(CAA_abb[1]=="all"){
  acomp_names <- acomp_names_all
}else{
  acomp_names <- paste("acomp",CAA_abb,"ob",sep=".")
}
acomp_names <- acomp_names[acomp_names%in%names(comp.mats)] # Identify valid names
if(length(acomp_names)==0){
  message(paste(Name,": CAA_abb does not match any names in the rdat comp.mats. CAA will be computed as a cellwise average of all available age compositions:",paste(acomp_names_all,collapse=", ")))
  acomp_names <- acomp_names_all
}
acomp_mats <- comp.mats[acomp_names] # Comps by year

names(acomp_mats) <- gsub(x=names(acomp_mats),pattern=".ob",replacement = "",fixed=TRUE)
acomp_data_n <- t.series[,grepl(x=names(t.series),pattern="acomp.",fixed=TRUE)&grepl(x=names(t.series),pattern=".n",fixed=TRUE)&!grepl(x=names(t.series),pattern=".neff",fixed=TRUE)]  # N by year
acomp_data_n[acomp_data_n==-99999] <- 0
acomp_mats_nfish <- comp_complete(acomp_mats,acomp_data_n,output_type = "nfish", val_rownames=year, val_colnames = age)

acomp_nfish <- comp_combine(acomp_mats_nfish,scale_rows = FALSE)
# Convert CAA to array to appease MSEtool

CAA <- aperm(replicate(nsim,acomp_nfish),c(3,1,2))
# CAA <- array(data=acomp_nfish, dim=c(nsim,nrow(acomp_nfish),ncol(acomp_nfish)),
#              dimnames = list("sim"=1:nsim,"year"=rownames(acomp_nfish),"age"=colnames(acomp_nfish)))
slot(Data,"CAA") <- CAA
}
}

## Length comps
if(!CAL_abb=="none"){
is_lcomp <- grepl(x=names(comp.mats),pattern="lcomp.",fixed=TRUE)&grepl(x=names(comp.mats),pattern=".ob",fixed=TRUE)
if(any(is_lcomp)){
  lcomp_names_all <- names(comp.mats)[is_lcomp]
  if(CAL_abb=="all"){
    lcomp_names <- lcomp_names_all
  }else{
    lcomp_names <- paste("lcomp",CAL_abb,"ob",sep=".")
  }
  lcomp_names <- lcomp_names[lcomp_names%in%names(comp.mats)] # Identify valid names
  if(length(lcomp_names)==0){
    message(paste(Name,": CAL_abb does not match any names in the rdat comp.mats. CAL will be computed as a cellwise average of all available length compositions:",paste(lcomp_names_all,collapse=", ")))
              lcomp_names <- lcomp_names_all
  }
  lcomp_mats <- comp.mats[lcomp_names] # Comps by year

names(lcomp_mats) <- gsub(x=names(lcomp_mats),pattern=".ob",replacement = "",fixed=TRUE)
lcomp_data_n <- t.series[,grepl(x=names(t.series),pattern="lcomp.",fixed=TRUE)&grepl(x=names(t.series),pattern=".n",fixed=TRUE)]  # N by year
lcomp_data_n[lcomp_data_n==-99999] <- 0
lcomp_mats_nfish <- comp_complete(lcomp_mats,lcomp_data_n,output_type = "nfish", val_rownames=year)

lcomp_nfish <- comp_combine(lcomp_mats_nfish,scale_rows = FALSE)
colnames(lcomp_nfish) <- paste(as.numeric(colnames(lcomp_nfish))*length_sc)

# Mean
ML_LFS_out <- ML_LFS(lcomp_nfish,minL=LFS)
ML <- setNames(ML_LFS_out$mlen,ML_LFS_out$year)
slot(Data,"ML") <-  matrix(ML,nrow=nsim,ncol=nyear,byrow=TRUE,dimnames=list("sim"=1:nsim,"year"=year))

# Convert CAL to array to appease MSEtool
# CAL <- array(data=lcomp_nfish, dim=c(nsim,nrow(lcomp_nfish),ncol(lcomp_nfish)),
#              dimnames = list("sim"=1:nsim,"year"=rownames(lcomp_nfish),"len"=colnames(lcomp_nfish)))
CAL <- aperm(replicate(nsim,lcomp_nfish),c(3,1,2))
dimnames(CAL) <-  list("sim"=1:nsim,"year"=rownames(lcomp_nfish),"len"=colnames(lcomp_nfish))
# CAL <- array(data=lcomp_nfish, dim=c(nsim,nrow(lcomp_nfish),ncol(lcomp_nfish)),
#              dimnames = list("sim"=1:nsim,"year"=rownames(lcomp_nfish),"length"=colnames(lcomp_nfish)))

CAL_mids <- as.numeric(dimnames(CAL)$len)
CAL_bin_width <- median(diff(CAL_mids))
CAL_bins <- c(CAL_mids[1]-CAL_bin_width/2,CAL_mids+CAL_bin_width/2)

slot(Data,"CAL") <- CAL
slot(Data,"CAL_bins") <- CAL_bins
slot(Data,"CAL_mids") <- CAL_mids
}
}

slot(Data,"Name") <- Name
slot(Data,"Common_Name") <- Common_Name
slot(Data,"Species") <- genus_species
slot(Data,"Region") <- Region
slot(Data,"Year") <- year
slot(Data,"Cat") <- Cat
slot(Data,"CV_Cat") <- CV_Cat
slot(Data,"Rec") <- Rec
slot(Data,"t") <- nyear
slot(Data,"AvC") <- mean(Cat)
slot(Data,"Dt") <- Dt
slot(Data,"Mort") <- M.constant
slot(Data,"FMSY_M") <- FMSY_M
slot(Data,"BMSY_B0") <- BMSY_B0
slot(Data,"L50") <- L50
slot(Data,"L95") <- L95
slot(Data,"LFC") <- L5
slot(Data,"LFS") <- LFS

# von Bertalanffy K parameter (vbK): growth coefficient
slot(Data,"vbK") <- K
slot(Data,"CV_vbK") <- CV_vbK

# von Bertalanffy Linf parameter (vbLinf): Maximum length
slot(Data,"vbLinf") <- Linf*length_sc
slot(Data,"CV_vbLinf") <- CV_vbLinf

# von Bertalanffy t0 parameter (vbt0): Theoretical age at length zero
slot(Data,"vbt0") <- t0
slot(Data,"CV_vbt0") <- CV_vbt0

# Coefficient of variation of length-at-age (assumed constant for all age classes)
slot(Data,"LenCV") <- LenCV

# Length-weight parameter a (wla)
# Identify weight unit used in weight~length equation and scale parameter to compute weight in kg
wla <- parms$wgt.a
wlb <- parms$wgt.b

if(is.null(wla_sc)){
wla_sc <- local({
  if(wla>=1E-6&wla<=1E-4){
    wla_sc <- 0.001
    message(paste0("For ",Name," weight~length appears to be in grams. Scaling wla parameter by ",wla_sc))
  }
  if(wla>=1E-9&wla<=1E-7){wla_sc <- 1}      # Weight appears to already be in kilograms
  if(wla>=1E-13&wla<=1E-11){
    wla_sc <- 1000
    message(paste0("For ",Name," weight~length appears to be in metric tonnes. Scaling wla parameter by ",wla_sc))
  }
  wla_sc
})
}
wla_kg <- wla*wla_sc
wla_userunit <- measurements::conv_unit(wla_kg,from="kg",to=wla_unit)

# Length-weight parameter b (wlb)
if(wlb<=2|wlb>=4){
  message(paste0("For ",Name," the wlb parameter is outside of the expected range (2-4)"))
}

slot(Data,"wla") <- wla_unit_mult*wla_userunit*1/length_sc^wlb # Adjust a parameter for length units
slot(Data,"wlb") <- wlb


slot(Data,"steep") <- parm.cons$steep[8]
slot(Data,"sigmaR") <- parm.cons$rec.sigma[8]

slot(Data,"MaxAge") <- max(age)

slot(Data,"Dep") <- Dep
slot(Data,"Abun") <- Abun
slot(Data,"SpAbun") <- SSBcurrent

slot(Data,"LHYear") <- LHYear

slot(Data,"Cref") <- Cref

# slot(Data,"Units") <- Units

return(Data)
}
