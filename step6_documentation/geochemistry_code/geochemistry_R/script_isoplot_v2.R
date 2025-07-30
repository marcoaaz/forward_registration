
rm(list=ls()) #clear

#install.packages('IsoplotR')
library(IsoplotR)

destDir <- system.file(package='IsoplotR')
setwd(destDir) # navigate to the built-in data files
#C:/Users/acevedoz/AppData/Local/Programs/R/R-4.4.3/library/IsoplotR


#User input

args <- commandArgs(TRUE)
sourceDir <- as.character(args[1]) #\\ also allowed
#sourceDir <- "E:\\Feb-March_2024_zircon imaging\\00_Paper 4_Forward image registration\\puck 1 and 2\\merge_grid_test\\project_20-May_1"

#Script

file1 = 'input_UPb.csv'
file2 = 'output_UPb_Wetherill.pdf'
file3 = 'output_UPb_KDE.pdf'
file4 = 'output_Age.csv'

filepath1 = file.path(sourceDir, file1) #input data
filepath2 = file.path(sourceDir, file2) #output figures
filepath3 = file.path(sourceDir, file3) 
filepath4 = file.path(sourceDir, file4) #output data

#Overwritting
fn <- filepath2
if (file.exists(fn)) {
  file.remove(fn)
}
fn <- filepath3
if (file.exists(fn)) {
  file.remove(fn)
}
fn <- filepath4
if (file.exists(fn)) {
  file.remove(fn)
}

#Input data
UPb <- read.data(
  filepath1,
  method='U-Pb',
  format= 3, #X=07/35, err[X], Y=06/38, err[Y], Z=07/06, err[Z] (, rho[X,Y]) (,rho[Y,Z])
  ierr= 2, #2σ absolute uncertainties.
  )

#Computations and plots

#Discordia cutoff disk
uncertainty <- 10
dscf <- discfilter(option='r',before=TRUE,cutoff=c(-uncertainty,uncertainty)) 
#empty means no filter

#Calculate isotopic age

tUPb <- age(
  UPb,
  type = 1, #separate for each analysis
  exterr = FALSE,
  i = NULL,
  oerr = 1,
  sigdig = NA,
  common.Pb = 0,
  discordance = dscf,
)

#Save
write.table(tUPb, file = filepath4, sep = ",", col.names=TRUE, row.names = FALSE)

#Concordia diagram

pdf(filepath2) #dev.new()

concordia(
  x = UPb,
  tlim = NULL, #NULL; c(0,2000); age limits of the concordia line
  type = 1, #Wetherill
  show.numbers = TRUE, #show grain numbers
  levels = NULL,
  clabel = "",
  ellipse.fill = c("#00FF0080", "#FF000080"), #c("#00FF0080", "#FF000080"); NULL
  ellipse.stroke = "black",
  concordia.col = "darksalmon",
  exterr = TRUE, #show decay constant uncertainties= TRUE
  show.age = 0, #with age fit= 1 ; time-consuming
  oerr = 3,
  sigdig = 2,
  common.Pb = 0, #use the isochron intercept as the initial Pb-composition=2
  ticks = 5,
  anchor = 0,
  cutoff.disc = discfilter(),
  hide = NULL,
  omit = NULL, #indices of aliquots that should be plotted but omitted
  omit.fill = NA,
  omit.stroke = "grey",
  )

dev.off()

#Kernel density estimate of Concordia ages

pdf(filepath3) #dev.new()

kde(
  UPb,
  from = NA,
  to = NA,
  bw = NA, #bandwidth of the KDE
  adaptive = TRUE,
  log = FALSE,
  n = 512, #horizontal resolution
  plot = TRUE,
  rug = TRUE,
  xlab = "age [Ma]",
  ylab = "",
  kde.col = rgb(1, 0, 1, 0.6),
  hist.col = rgb(0, 1, 0, 0.2),
  show.hist = TRUE,
  bty = "n",
  binwidth = 100, #Ma
  type = 4, #type of age = 4 (the 207Pb/206Pb-206Pb/238U age with cutoff)
  cutoff.76 = 900, #900 threshold valley away from events of geological interest
  cutoff.disc = discfilter(), #discfilter(); dscf
  common.Pb = 0,
  hide = NULL,
  nmodes = 'all', #most prominent modes
  sigdig = 2,
)

dev.off()

