debugg <- function(){
  rm(list=ls())
  out.path <- "outputs/Test01"
  library(tictoc);  library(sp); library(raster); library(RANN); library(tidyverse)
  setwd("C:/work/qbcmod/QbcLDM")
  source("mdl/define.scenario.r");  source("mdl/landscape.dyn.r")
  source("mdl/wildfires.r");   source("mdl/disturbance.cc.r");   source("mdl/sbw.outbreak.r") 
  source("mdl/disturbance.pc.r");   source("mdl/buffer.mig.r"); source("mdl/forest.transitions.r")  
  source("mdl/suitability.r"); source("mdl/fuel.type.r")  
  scn.name <- "Test01"
  define.scenario(scn.name)
  ## From landscape.dyn()
  source(paste0("outputs/", scn.name, "/scn.def.r"))
  load(file="inputlyrs/rdata/mask.rdata")
  km2.pixel <- res(MASK)[1] * res(MASK)[2] / 10^6
  time.seq <- seq(time.step, max(time.horizon, time.step), time.step)
  clim.scn <- "rcp85"
  load(file="inputlyrs/rdata/land.rdata")
  baseline.fuel <- group_by(fuel.type(land,fuel.types.modif), zone) %>% summarize(x=mean(baseline))
  track.spp.frzone <- data.frame(run=NA, year=NA, FRZone=NA, SppGrp=NA, Area=NA)
  track.spp.age.class <- data.frame(run=NA, year=NA, BCDomain=NA, SppGrp=NA, 
                                    C20=NA, C40=NA, C60=NA, C80=NA, C100=NA, Cold=NA)
  track.suit.class <- data.frame(run=NA, year=NA, BCDomain=NA, PotSpp=NA, poor=NA, med=NA, good=NA)
  fire.schedule <- seq(0, time.horizon, fire.step)
  cc.schedule <- seq(0, time.horizon, cc.step)
  pc.schedule <- seq(0, time.horizon, pc.step)
  sbw.schedule <- seq(sbw.step, time.horizon, sbw.step)
  load(file=paste0("inputlyrs/rdata/temp_", clim.scn, "_ModCan.rdata")) 
  load(file=paste0("inputlyrs/rdata/precip_", clim.scn, "_ModCan.rdata"))  
  irun=1  
  t=0
  processes <- c(T, F, F, F)
  
  
  ## FROM DISTURBANCE.FIRE
  `%notin%` <- Negate(`%in%`)
  load("inputlyrs/rdata/pigni.rdata")
  dist.num.fires <- read.table(file.num.fires, header = T)
  dist.fire.size <- read.table(file.fire.sizes, header = T)
  track.fire <- data.frame(year=NA, fire.id=NA, wind=NA, atarget=NA, aburnt=NA)
  default.neigh <- data.frame(x=c(-1,1,2900,-2900,2899,-2901,2901,-2899,-2,2,5800,-5800),
                              windir=c(270,90,180,0,225,315,135,45,270,90,180,0),
                              dist=c(100,100,100,100,141.421,141.421,141.421,141.421,200,200,200,200))
  default.nneigh <- nrow(default.neigh)
  modif.fuels <- group_by(fuel.type(land,fuel.types.modif), FRZone) %>% summarize(x=mean(baseline))
  modif.fuels$x <- 1+(modif.fuels$x-baseline.fuel$x)/baseline.fuel$x
  burnt.cells <- numeric(0)
  fire.id <- 0
  
  
}

play.landscape.dyn <- function(){
  rm(list=ls())
  # setwd("C:/Users/boumav/Desktop/LandscapeDynamics3_nu/rscripts")
  setwd("C:/work/qbcmod/QbcLDM")
  source("mdl/define.scenario.r")
  source("mdl/landscape.dyn.r")  
  scn.name <- "Test01"
  define.scenario(scn.name)
  fuel.types.modif <- data.frame(type=1:3, baseline=c(0.1, 0.4, 0.95)) 
  write.sp.outputs <- T
  dump(c("fuel.types.modif", "write.sp.outputs"), 
       paste0("outputs/", scn.name, "/scn.custom.def.r"))
  landscape.dyn(scn.name)
  
}


play.read.state.vars <- function(){
  rm(list=ls())
  # work.path <- "C:/Users/boumav/Desktop/QLandscapeDynamics1"
  work.path <- "C:/work/qbcmod/QbcLDM"
  source("mdl/read.state.vars.r")
  read.state.vars(work.path)
}


play.change.spinput.resol <- function(){
  rm(list=ls())
  library(RColorBrewer)
  setwd("C:/Users/boumav/Desktop/LandscapeDynamics2")
  source("mdl/change.spinput.resol.r")
  # load original data
  load(file="inputlyrs/rdata/mask.rdata") 
  load(file="inputlyrs/rdata/sp.input.rdata") 
  load(file="inputlyrs/rdata/land.rdata") 
  change.spinput.resol(MASK, sp.input, land, factor=4, is.climate.change=T)
  # look at what commes up
  load("inputlyrs/rdata/mask.factor4.rdata")
  res(MASK)
  load("inputlyrs/rdata/sp.input.factor4.rdata")
  plot(sp.input$FRZone, col=brewer.pal(4, "Set1"))
  load("inputlyrs/rdata/land.factor4.rdata")
  head(land)
  load("inputlyrs/rdata/cc.temp.factor4.rdata")
  head(land.factor)
}


write.plot.sp.input <- function(){
  rm(list=ls())
  setwd("C:/work/qbcmod/QbcLDM")
  load(file="inputlyrs/rdata/sp.input.rdata")
  writeRaster(sp.input$FRZone, "inputlyrs/asc/FRZone.tif", format="GTiff", overwrite=T)
  writeRaster(sp.input$FRZone, "inputlyrs/asc/FRZone.asc", format="ascii", overwrite=T)
  writeRaster(sp.input$BCDomain, "inputlyrs/asc/BCDomain.asc", format="ascii", overwrite=T)
  writeRaster(sp.input$MgmtUnit, "inputlyrs/asc/MgmtUnit.asc", format="ascii", overwrite=T)    
  writeRaster(sp.input$SppGrp, "inputlyrs/asc/SppGrp_t0.asc", format="ascii", overwrite=T)    
  writeRaster(sp.input$TSD, "inputlyrs/asc/TSD_t0.asc", format="ascii", overwrite=T)    
  plot(sp.input$FRZone)
  plot(sp.input$BCDomain)
  plot(sp.input$MgmtUnit)
  plot(sp.input$SppGrp)
  plot(sp.input$Temp)
  plot(sp.input$Precip)
  plot(sp.input$SoilType)
  plot(sp.input$Exclus)
}



