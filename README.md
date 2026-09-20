## Functions for Image Processing
**Eu_register_x.m**: Register images using spm12.  
**Eu_segement.m**: Segment images using spm12.

## Scripts for Image Processing
**Eu_ds_preproc_CE_ASL_excel.m**: Preprocess (register and segment) GE scans.  
**Eu_ds_preproc_ASL_stroke.m**: Preprocess (register and segment) Philips scans.
**erode_mask.m**: Erode ROI masks.

## Scripts for Data Extraction 
**count_num_voxel.m**: Count the number of voxels using ROI masks.  
**extract_summed_signal.m**: Extract from ROI the mean, median, and standard deviation of the signal. Also extract the mean and median multiplied by uneroded mask volume.  
**extract_signal_excel_M0.m**: Extract the mean, median, and standard deviation of the signal across grey matter and white matter to estimate M0.  
**extract_roi_T1.m**: Extract the ROI mean, median, standard deviation from T1 maps.  
**normalise_summed_signal.m**: Normalise ASL signal using M0 extracted from grey matter and white matter.

## Functions for Modelling
**SCM_signal.m**: Single-Compartment Model ASL signal equation. Depending on the input arguments sblood, outflow, and outflow_csf, this function returns the ASL signal using the Single Blood Compartment Model (SBCM), Single Tissue Compartment Model (STCM) or STCM+outflow model.  
**TCM_signal.m**: Two-Compartment Model (TCM) ASL signal equation.  
**CP-LV_model.m**: Blood-CP-LV Model ASL signal equation.

## Functions for Data Fitting
**fit_SCM.m**: Fit Single-Compartment Model to data.  
**fit_TCM.m**: Fit Two-Compartment Model to data.  
**fit_CPLV_model.m**: Fit Blood-CP-LV Model to data.

## Scripts for Data Fitting and Model Selection
**fit_ASL_summed_signal_centralT1.m**: Fit models to individual data. 
**fit_averaged_curves.m**: Fit models to averaged data.
**cal_akaike_weights_centralT1.m**: Produce excel sheets containing fit parameters and normalised Akaike model weights (with small sample correction).  
**STCM_csf_model_identifiability.m**: Plot multi-start fitting solutions using the STCM, SBCM, TCM, STCM+outflow, blood-CP-LV models to assess parameter identifiability.

## Scripts for Plotting and Group Analysis
**plot_T1_vs_erosion_size.m**: Plot the mean T1 values against the erosion structuring element radii.  
**plot_model_weight_2.m**: Plot model weights.  
**plot_boxplot_averaged_curves.m**: Plot boxplots for fit parameters given by different models. Perform group analysis using Mann-Whitney tests. Plot group-averaged ASL signals.

## Output – Excel Spreadsheets
**calc_akaike_weights_centralT1**: Fit parameters and model weights.
- *gm_0_9*: Grey matter (GM) mask produced from the tissue probability map using a threshold of 0.9
- *wm_0_9*: White matter (WM) mask produced from the tissue probability map using a threshold of 0.9
- *choroid_plexus_mask*: Choroid plexus (CP) segmented using FreeSurfer
- *choroid_plexuserode_size1_corrected_mask*: CP mask eroded using MATLAB strel of 1mm radius (pixel)
- *lateral ventricleserode_size3_corrected_mask*: Lateral ventricles (LV) segmented using FreeSurfer and eroded using MATLAB strel of 3mm radius (pixel)
- *inferior lateral ventricles_mask*: Inferior lateral ventricles (ILV) segmented using FreeSurfer
- *inferior lateral ventricleserode_size1_corrected_mask*: ILV mask eroded using MATLAB strel of 1mm radius (pixel)  
**Note**: Fit parameters and model weights can be found in *xxx*_model_results.xlsx and the fitted ASL signal in *xxx*_delta_M.xlsx.  

**fit_ASL_summed_signal_centralT1**: Output files in .mat that contain fitting results (roi_*xxx*.m)
**count_num_voxel**: Number of voxels given by uneroded masks.  
**extract_roi_T1**: ROI T1 values.  
**extract_summed_signal/newnew**: ASL signal.  
***xxx*_roi_outlier.xlsx**: Outlier parameters (values > 1.5*IQR)  
**Note**: *STCM_LV* represents the STCM+outflow model, *CP_LV* represents the blood-CP-LV model.
  *xxx* can be *median_normalised* (normalised median ASL signal) or *mean_times_vol_normalised* (normalised mean ASL signal multiplied by uneroded ROI volume)
