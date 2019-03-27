# Util

 A set of tools that have helped me process whole-slide images, extract features from object segmentations, and build and evaluate machine learning models.
 
 # ROIextraction
 
 Matlab code for extracting annotated regions of interest from whole-slide images. You need either BioFormats or Openslide for getROIfromTif to work at all and need both of them to get full functionality. Annotations can be read directly from .czi files or from .xml files in the Aperio ImageScope format for all other image types.
 
 # QuPathScripts
 
 Some handy scripts I've put together for importing and exporting annotations to and from QuPath. Annotations exported using qupath_to_xml.groovy should be readable by getRegionsOfAnnotation.m in ROIextraction.
 
 # featureExtraction
 
 Matlab code for extracting 216 morphology features from object segmentations and 26 Haralick texture features. CGT and sub-graph features are tuned for 1.25X (8MPP) segmentations.
 
 # lumenSegHelpers
 
 Matlab functions for extracting regions of interest at a certain MPP and processing binary masks to get bounds structs which can be used in extract_all_features.m in featureExtraction.
 
 # bfmatlab
 
 A fork of the bioformats matlab commands. Does not have the actual bioformats.jar. Included because I have modified bfopenSpecificLayer.m to work in getROIfromTif.
 
 # Visualization
 
 Tools for visualizing segmentation results and model performance. 
