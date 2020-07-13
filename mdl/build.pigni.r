build.pigni <- function(work.path, lambda=0){
  
  library(rgdal)
  
  ## Load land df
  load(file="inputlyrs/rdata/land.rdata")
  
  ## Build a spatial points layer with coordinates of the forest data
  points <- SpatialPoints(land[,2:3],  CRS("+proj=lcc +lat_1=46 +lat_2=60 +lat_0=44 +lon_0=-68.5 +x_0=0 +y_0=0 
                    +ellps=GRS80 +towgs84=0,0,0,0,0,0,0 +units=m +no_defs"))
    
  ## Read buffers around the observed ignitions (of fires of size > 200 ha) and 
  buff <- data.frame(points)
  for(i in c("05", 10, 20, 30)){   
    BUFF <- readOGR(paste0(work.path, "DataIn/Buffers/Buff",i,"Kall.shp"))
    # Change cartographic projection
    BUFFp <- spTransform(BUFF, CRS("+proj=lcc +lat_1=46 +lat_2=60 +lat_0=44 +lon_0=-68.5 +x_0=0 +y_0=0 
                                +ellps=GRS80 +towgs84=0,0,0,0,0,0,0 +units=m +no_defs"))
    # Overlap point and polygons
    aux <- over(points, BUFFp)
    save(aux, file=paste0("C:/WORK/QBCMOD/DataIn/Buffers/OverlappLandBuff_", i, "K.rdata"))
    buff$z <- !is.na(aux$BUFF_DIST)
    if(i=="05")
      buff$z <- buff$z*5
    if(i!="05")
      buff$z <- buff$z*i
    names(buff)[ncol(buff)] <- paste0("r", i)
  }
  buff$r40 <- 40
  ## Replace 0 by NA
  for(i in 3:6)
    buff[,i] <- ifelse(buff[,i]==0, NA, buff[,i])
  
  ## Compute the minimum distance to a focal, and then assign prob igni
  pigni <- data.frame(cell.id=land$cell.id, frz=land$FRZone,
                      d=pmin(buff$r05, buff$r10, buff$r20, buff$r30, buff$r40, na.rm=T))
  pigni$p <- exp(-lambda*pigni$d)
  
  
  ## Save the prob igni dataframe
  save(pigni, file="inputlyrs/rdata/pigni_static.rdata")
}
