stepwiseqtl.summary.simple<-function(cross, model.in, phe, covar=NULL, ci.method="drop", drop=1.5, plot=FALSE){
  #set up the environment
  if(class(cross)[1]=="riself" | class(cross)[1]=="bc"){
    stats_out<-data.frame(phenotype=character(),chromosome=numeric(),position=numeric(),
                          df=numeric(),type3SS=numeric(),LOD=numeric(),perc.var=numeric(),Fstat=numeric(),P.chi2=numeric(),P.F=numeric(),
                          effect.estimate=numeric(),effect.SE=numeric(),effect.t=numeric(),
                          lowCImarker=character(), hiCImarker=character(),
                          lowCIpos=character(), hiCIpos=character())
  }else{
    if(class(cross)[1]=="f2"){
      stats_out<-data.frame(phenotype=character(),chromosome=numeric(),position=numeric(),
                            df=numeric(),type3SS=numeric(),LOD=numeric(),perc.var=numeric(),Fstat=numeric(),P.chi2=numeric(),P.F=numeric(),
                            lowCImarker=character(), hiCImarker=character(),
                            lowCIpos=character(), hiCIpos=character())
    }else{
      print("stepwiseqtl.summary is only implemented for f2, bc and ril experimental designs")
      next
    }
  }
  statcols<-names(stats_out)
  if(class(model.in)=="list")
  {
    stepout<-model.in[[phe]]
  }else{stepout<-model.in}
  
  if(nqtl(stepout)==0){
    if(printout){cat(paste(" ******* phenotype",phe,"has a null qtl model","\n"))}
    next
  }
  #plot the lod profile to the window
  if(plot){
    plotLodProfile(stepout,main=paste(phe,"formula: ", formula(stepout)))
  }
  #fit the qtl model
  fit<-fitqtl(cross,
              pheno.col=phe,
              qtl=stepout,
              formula=formula(stepout),
              get.ests=T,dropone=T,covar=covar,
              method="hk")
  #determine the number of terms/qtl in the model
  nqtls<-nqtl(stepout)
  nterms<-sum(countqtlterms(formula(stepout), ignore.covar=F)[c(1,4)])
  ncovar<-length(covar)
  #extract information if the qtl model has multiple qtls/covariates
  if(nterms>1){
    ests_out<-summary(fit)$ests[2:(nterms+1),1:3]
    cis<-data.frame()
    #calculate confidence intervals for each qtl
    for (j in 1:nqtls){
      attr(stepout, "lodprofile")
      if(ci.method=="drop"){ciout<-lodint(stepout,qtl.index=j, expandtomarkers=F, drop=drop)
      }else{
        if(ci.method=="bayes"){ciout<-bayesint(stepout,qtl.index=j, expandtomarkers=F, prob=prob)}
      }
      lowmarker<-rownames(ciout)[1]
      highmarker<-rownames(ciout)[3]
      lowposition<-ciout[1,2]
      highposition<-ciout[3,2]
      cis<-rbind(cis,cbind(lowmarker,highmarker,lowposition,highposition))
    }
    chrs<-stepout$chr
    pos<-stepout$pos
    #if covariates, add in NAs into the dataframe
    if(ncovar>0) {
      covar.ci<-(rep(NA,4))
      cis<-rbind(covar.ci, cis)
      chrs<-c(names(covar), stepout$chr)
      pos<- c(names(covar), stepout$pos)
    }
    #if epistasis, add NAs into the dataframe
    if(as.numeric(countqtlterms(formula(stepout))[4])>0) {
      epi.ci<-data.frame()
      for (j in 1:countqtlterms(formula(stepout))[4]){
        epi.ci.out<-(rep(NA,4))
        cis<-rbind(cis,epi.ci.out)
      }
      chrs<-c(chrs,rep(NA,countqtlterms(formula(stepout))[4]))
      pos<- c(pos,rep(NA,countqtlterms(formula(stepout))[4]))
    }
    
    if(class(cross)[1]=="riself"){
      ests_out<-summary(fit)$ests[2:(nterms+1),1:3]
      stats<-data.frame(rep(phe,nterms),chrs,pos,fit$result.drop[1:nterms,],ests_out,cis)
      colnames(stats)<-statcols
    }else{
      stats<-data.frame(rep(phe,nterms),chrs,pos,fit$result.drop[1:nterms,],cis)
      colnames(stats)<-statcols
    }
  }else{
    cis<-data.frame()
    for (j in 1:nqtls){
      if(ci.method=="drop"){ciout<-lodint(stepout,qtl.index=j, expandtomarkers=F, drop=drop)
      }else{
        if(ci.method=="bayes"){ciout<-bayesint(stepout,qtl.index=j, expandtomarkers=F, prob=prob)}
      }
      lowmarker<-rownames(ciout)[1]
      highmarker<-rownames(ciout)[3]
      lowposition<-ciout[1,2]
      highposition<-ciout[3,2]
      cis<-rbind(cis,cbind(lowmarker,highmarker,lowposition,highposition))
    }
    if(class(cross)[1]=="riself" | class(cross)[1]=="bc"){
      ests_out<-summary(fit)$ests[2:(nqtls+1),1:3]
      stats<-data.frame(c(phe,stepout$chr[1],stepout$pos[1],
                          as.numeric(fit$result.full[1,c(1,2,4,5,3,6,7)]),as.numeric(ests_out),cis[1,]))
    }else{
      stats<-data.frame(c(phe,stepout$chr[1],stepout$pos[1],
                          as.numeric(fit$result.full[1,c(1,2,4,5,3,6,7)]),cis[1,]))
    }
    ests_out<-summary(fit)$ests[2:(nqtls+1),1:3]
    colnames(stats)<-statcols; rownames(stats)<-stepout$name
  }
  stats_out<-rbind(stats_out,stats)
  return(stats_out)
}