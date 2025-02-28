# bamMSE
 This package contains a set of functions used to convert data and assessment outputs from the Beaufort Assessment Model (BAM) to inputs used by the openMSE packages (DLMtool, MSEtool, and SAMtool).

# Example usage

## Load the package

First, install and load the package. 

```{r, echo=TRUE, message=FALSE}
# Install and load package
devtools::install_github("Nikolai-Klibansky/bamMSE", build_vignettes = TRUE)
library(bamMSE)
```


The `intro` vignette shows you how to use BAM data and output to condition operating models for running management strategy evaluations with the [openMSE](https://openmse.com/) package.
```R
vignette("intro","bamMSE")
```

# Disclaimer
“This repository is a scientific product and is not official communication of the National Oceanic and
Atmospheric Administration, or the United States Department of Commerce. All NOAA GitHub project code is
provided on an ‘as is’ basis and the user assumes responsibility for its use. Any claims against the Department of
Commerce or Department of Commerce bureaus stemming from the use of this GitHub project will be governed
by all applicable Federal law. Any reference to specific commercial products, processes, or services by service
mark, trademark, manufacturer, or otherwise, does not constitute or imply their endorsement, recommendation or
favoring by the Department of Commerce. The Department of Commerce seal and logo, or the seal and logo of a
DOC bureau, shall not be used in any manner to imply endorsement of any commercial product or activity by
DOC or the United States Government.”
