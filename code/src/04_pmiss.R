## ---------------------------
##
## Script name: 04_pmiss.R
##
## Purpose of script: identify the not attributed damage, casued by discrepencies in input data
##
## Author: Peter Pothmann
##
## Date Created: 03-04-2023
##
## Copyright (c) Peter Pothmann, 2022
## Email: peter.pothmann@idiv.de
##
## ---------------------------
##
## Notes:
##
##
## ---------------------------


# brauche dp -> das will ich auch aus dem submit script bekommen
# brauche sum of pcaoh und piaoh -> das will ich im submit script bekommen
# rechen dp - sum
# muss das fuer jede paraID, Art und periode machen
# write this



# submit script wird ziemlich gros sein - egal

# will iaoh und caoh fuer jeden Modeldurchlauf aggregieren und dann von dp abziehen

iaoh <- rast(submit$iaoh) # die extents werden nicht gleich sein

aoh <- rast(submit$caoh) # die extents werden nicht gleich sein


iaoh <- cumsum(iaoh)

aoh <- cumsum(aoh)


pmiss <- dp - abs()







#
#
