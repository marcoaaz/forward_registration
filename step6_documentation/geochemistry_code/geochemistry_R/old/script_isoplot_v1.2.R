
rm(list=ls()) #clear

#install.packages('IsoplotR')
library(IsoplotR)

#User input
args <- commandArgs(TRUE)

#Script
sourceDir <- as.character(args[1]) #\\ also allowed

file1 = 'input_UPb.csv'
file2 = 'output_UPb_Concordia.pdf'
file3 = 'output_UPb_KDE.pdf'
filepath1 = file.path(sourceDir, file1) #
filepath2 = file.path(sourceDir, file2) #output figures
filepath3 = file.path(sourceDir, file3) #output figures

destDir <- system.file(package='IsoplotR')
setwd(destDir) # navigate to the built-in data files
#C:/Users/acevedoz/AppData/Local/Programs/R/R-4.4.3/library/IsoplotR

#Input data
UPb <- read.data(
  filepath1,
  method='U-Pb',
  format= 1, #X=07/35, err[X], Y=06/38, err[Y], rho[X,Y]
  ierr= 2, #2σ absolute uncertainties.
  )

#Computations and plots

#Concordia diagram

pdf(filepath2) #dev.new()

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
  exterr = TRUE, #show decay constant uncertainties= TRUE
  show.age = 0, #with age fit= 1 ; time-consuming
  oerr = 3,
  sigdig = 2,
  common.Pb = 0, #use the isochron intercept as the initial Pb-composition=2
  ticks = 5,
  anchor = 0,
  cutoff.disc = discfilter(),
  hide = NULL,
  omit = NULL,
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
  type = 5, #type of age = 5 (Concordia age)
  cutoff.76 = 1100, #only for type=4 (Charlotte 900 Ma split)
  cutoff.disc = discfilter(),
  common.Pb = 0,
  hide = NULL,
  nmodes = 'all', #most prominent modes
  sigdig = 2,
)

dev.off()

