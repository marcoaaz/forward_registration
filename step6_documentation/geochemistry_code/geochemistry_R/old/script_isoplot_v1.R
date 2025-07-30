
rm(list=ls()) #clear

#install.packages('IsoplotR')
library(IsoplotR)

destDir <- system.file(package='IsoplotR')
setwd(destDir) # navigate to the built-in data files
#C:/Users/acevedoz/AppData/Local/Programs/R/R-4.4.3/library/IsoplotR

file = 'C:\\Users\\acevedoz\\OneDrive - Queensland University of Technology\\Desktop\\img_concordia7.pdf'
pdf(file) #dev.new()

UPb <- read.data('UPb6.csv',method='U-Pb',format=6)

#concordia(UPb, common.Pb=2, show.age=1, exterr=TRUE)
concordia(
  x = UPb,
  tlim = NULL, #age limits of the concordia line
  type = 1, #Wetherill
  show.numbers = FALSE,
  levels = NULL,
  clabel = "",
  ellipse.fill = c("#00FF0080", "#FF000080"),
  ellipse.stroke = "black",
  concordia.col = "darksalmon",
  exterr = TRUE, #show decay constant uncertainties
  show.age = 1, #with age fit
  oerr = 3,
  sigdig = 2,
  common.Pb = 2, #use the isochron intercept as the initial Pb-composition
  ticks = 5,
  anchor = 0,
  cutoff.disc = discfilter(),
  hide = NULL,
  omit = NULL,
  omit.fill = NA,
  omit.stroke = "grey",
  )


dev.off()

