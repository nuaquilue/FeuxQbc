######################################################################################
###  forest.trans()
###
###  Description >  Assigns a new tree species according to the post-disturbance 
###                 regeneration or forest succession hypotheses. The function is
###                 called in the regen/succession sections of landscape.dyn
###
###  Arguments >  
###   subland : data frame of the state variables       
###   prob.reg : probability of regeneration of pre-species to post-species
###   buffer = presence of a sufficient number of source populations of a given 
###            tree species in the neighborhood
###   suitability: cell suitability for each species in terms of climate and soil
###   dtype: disturbance type B=burn, C=clearcut, S=succession
###   persist: is it a simulation scenario where species persistence in the face of unsuitable 
###            conditions is allowed
###
######################################################################################

          # subland  <- filter(land, cell.id %in% burnt.cells)
          # prob.reg <- post.fire.reg
#          subland  <- filter(land, cell.id %in% cc.cells)
#          prob.reg <- post.harvest.reg
#  dtype = "C"
#   target.cells <- cc.cells

forest.trans <- function(land, target.cells, prob.reg, buffer, suitab, potential.spp, 
                         dtype, p.failure, age.seed, suboptimal, enfeuil){
  
  ## If target data.frame is empty
  if(length(target.cells)==0)
    return(numeric())
    
  ## Tracking
  cat(ifelse(dtype=="B", "Forest transition post-fire", 
        ifelse(dtype=="O", "Forest transition post-outbreak", 
          ifelse(dtype=="C", "Forest transition post-cut", 
            ifelse(dtype=="S", "Natural succession", "xxx")))), "\n")

  
  ## Keep the current species in case any potential species can colonize the site.
  ## In that case, the current species, persist.
  subland <- filter(land, cell.id %in% target.cells)
  subland$SppGrp <- as.character(subland$SppGrp)
  current.spp <- subland$SppGrp

  subland[is.na(subland$PotSpp),]
  
  ## Join to the subland data frame the probability of transition to PotSpp (according to initial SppGrp)
  ## Then join buffer results indicating whether the potential species is present in the surrounding neighborhood
  ## Finally join the climatic-soil suitability index (i.e. modifier) of the potential spp
  #subland$SppGrp[subland$SppGrp %in% c("OthCB", "OthCT", "OthDB", "OthDT")] <- "OTH"
  subland <- left_join(subland, prob.reg, by="SppGrp") %>%
             left_join(buffer, by=c("cell.id", "PotSpp")) %>%
             left_join(suitab, by=c("cell.id", "PotSpp")) 
  
  ## Reset suitability for 'other species' because the group includes many species and 
  ## it's assumed that the climate would be suitable for at least one of those species. 
  subland$SuitClim[subland$PotSpp=="OTH"] <- 1
  subland$SuitClim[subland$PotSpp=="NonFor"] <- 1
  subland$SuitSoil[subland$PotSpp=="NonFor"] <- 1
  
  ## Eufeuillement volontaire suite aux coupes, that is, after clear-cut for a % of EPN and SAB
  ## to transform to PET
  if(dtype=="C" & enfeuil>0){  
    vec.enfeuil <- filter(subland, SppGrp %in% c("EPN", "SAB") & PotSpp=="PET") %>% select(ptrans)
    vec.enfeuil <- vec.enfeuil + (runif(length(vec.enfeuil))<enfeuil)*1000
    subland$ptrans[subland$SppGrp %in% c("EPN", "SAB") & subland$PotSpp=="PET"] <- unlist(vec.enfeuil)
  }
  
  ## Reburning case: If burnt stands are too young, probability of successful natural regeneration is lower
  if(dtype=="B"){ 
    subland$ptrans[subland$SppGrp=="EPN" & subland$PotSpp=="EPN" & subland$Age<age.seed] <- 
      subland$ptrans[subland$SppGrp=="EPN" & subland$PotSpp=="EPN" & subland$Age<age.seed] * (1-p.failure)
  }
  
  ## Stability criteria: if the species is present in the target location, then
  ## soil conditions are assumed to be optimal (not limiting)
      # levels(subland$SppGrp) <- levels(subland$PotSpp)
  subland$PressBuffer <- (subland$SppGrp == subland$PotSpp) | (subland$PressBuffer)
  subland$SuitSoil[subland$SppGrp == subland$PotSpp] <- 1
  
  ## Species persistence when climatic conditions become unfavorable: when persistence is allowed (1), 
  ## there is a floor probability of self-replacement corresponding to sub-optimal conditions 
  ## (under the assumption that competition is more limiting than  physiological response to climate)
  ## First, find which spp are allowed to persist then, upgrade climatic suitability to suboptimal
  ## in case this is lower than suboptimal.
  spp.persist <- potential.spp$spp[potential.spp$persist==1]
  subland$SuitClim[subland$SppGrp %in% spp.persist & 
                     subland$SppGrp == subland$PotSpp & subland$SuitClim<suboptimal] <- suboptimal
  
  ## Determine the final succession / regeneration probability 
  subland$p <- subland$ptrans * subland$PressBuffer * pmin(subland$SuitClim, subland$SuitSoil)
  
  ## Reshape the data frame, so we have a column for each potential species with 
  ## the corresponding transition probability (one row per target cell)
  ## Substitute dcast by "gather" or "spread" from tidyverse
  aux <- reshape2::dcast(subland, formula = cell.id ~ PotSpp, value.var = "p")
  #subland[subland$PotSpp ==NA,]$p
  
  ## Now select a new spp according to these probabilities and assign the corresponing species name
  ## If after all filters, p for all PotSpp is 0, the current species remains
  spp.names <- names(aux)[2:ncol(aux)]
  id.spp <- apply(aux[,2:ncol(aux)], 1, select.spp)
  new.spp <- numeric(length=length(id.spp))
  new.spp[id.spp!=0] <- spp.names[id.spp[id.spp!=0]]
  new.spp[id.spp==0] <- as.character(current.spp[id.spp==0])
  # pour les cellules deja dominées par other, revenir à la même chose
  new.spp[new.spp %in% c("OTH") & current.spp %in% c("OthCB","OthCT","OthDB","OthDT")] <- 
   current.spp[new.spp %in% c("OTH") & current.spp %in% c("OthCB","OthCT","OthDB","OthDT")]   
  
  new.spp[new.spp=="OTH"] <- select.others(land, unique(subland$cell.id)[new.spp=="OTH"])
  

  #cbind(new.spp,current.spp)
  
  ## Return the vector with the name of the new spp
  return(new.spp)

}

## Function that returns spp id according to probability x
select.spp <- function(x){
  if(sum(x)==0)
    return(0)
  id.spp <- sample(1:length(x), 1, replace=FALSE, prob=x)
  return(id.spp)
}
