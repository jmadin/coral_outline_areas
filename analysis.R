# Image overlay and area and perimeter calculations with two examples

library(jpeg)
library(sp)

# Get list of outlined colony filenames
files <- dir("data/outlines")
cols <- files[grep(".lm", files)]
cols <- unlist(strsplit(cols, "\\."))[seq(1, length(cols) * 2, 2)]

areas <- c()

for (i in cols) {
  sq <- read.delim(paste0("data/outlines/", i, ".sq"), header = F)
  # The .sq file set the number of scale plate squares used in .lm (landmark) file
  if (sq == 16) {scal = 10}     # Set square edge dimension
  if (sq == 9) {scal = 7.5}
  if (sq == 4) {scal = 5}
  if (sq == 1) {scal = 2.5}
  if (sq == "circle") {scal = 9.8}

  lm <- read.delim(paste0("data/outlines/", i, ".lm"), header = F)
  # The .lm (landmark) file contains the coordinates form the scale plate
  pix_T <- scal / sqrt(sum((lm[1,] - lm[2,])^2)) # The length of an image pixel

  ol <- read.delim(paste0("data/outlines/", i, ".ol"), header = F)
  # The .ol (outline) file contains the coordinates for the outlines from ImageJ

  # Below adds the landmarks and outline to the image file
  img <- readJPEG(paste0("data/images/", i, ".JPG"))
  jpeg(filename = paste0("output/", i, ".jpeg"), width = dim(img)[2], height = dim(img)[1], units = "px")
  par(mar = c(0, 0, 0, 0))
  plot(1, 1, xlim=c(1,dim(img)[2]), ylim=c(1,dim(img)[1]),type="n",xaxs="i",yaxs="i")
  rasterImage(img, 1, 1, dim(img)[2], dim(img)[1])
  points(lm[,1], dim(img)[1] - lm[,2], col = "blue", cex = 5*(dim(img)[1]/2000), pch = 20)
  ol[,2] <- dim(img)[1] - ol[,2]
  lines(ol[,1], ol[,2], col = "red", lwd = 5*(dim(img)[1]/2000))
  dev.off()

  # Area calculation
  ol2 <- ol
  ol2[,2] <- max(ol[,2]) - ol[,2] + 1
  ol2[,1] <- max(ol[,1]) - ol[,1] + 1

  x_vec <- rep(c(min(ol2[,1]):max(ol2[,1])), times = length(min(ol2[,2]):max(ol2[,2])))
  y_vec <- rep(c(min(ol2[,2]):max(ol2[,2])), each = length(min(ol2[,1]):max(ol2[,1])))
  pip_T <- point.in.polygon(x_vec, y_vec, ol2[,1], ol2[,2])
  # Change the below to suit your outlining style (e.g., if outlines include the edge or not)
  pip_T[pip_T == 3] <- 0            # remove points on outside edge of vertices
  pip_T[pip_T == 2] <- 1            # keep points on inside edge of vertices
  pip_mat_T <- matrix(pip_T, length(min(ol2[,1]):max(ol2[,1])), length(min(ol2[,2]):max(ol2[,2])))

  area_T <- sum(pip_T * pix_T ^ 2)     # conduct scale correction
  peri_T <- dim(ol)[1] * pix_T         # conduct scale correction

  areas <- rbind(areas, cbind(id = i, area_cm2 = area_T, perimeter_cm = peri_T))
  write.csv(areas, file = "output/area_output.csv", row.names = F)

  print(area_T)
}

