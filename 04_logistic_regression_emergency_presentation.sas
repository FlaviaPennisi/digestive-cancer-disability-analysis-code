/**************************************************************************
 Program: 04_logistic_regression_emergency_presentation.sas
 Purpose: Estimate odds ratios for emergency presentation according to
          impairment categories and covariates.
 Software: SAS 9.4
**************************************************************************/

%include "00_setup.sas";

data analysis_final;
    set out.analysis_final;
run;

/* Ensure outcome is coded as 1=emergency presentation, 0=non-emergency */
data analysis_final;
    set analysis_final;

    if emergency_presentation in (0, 1);
run;

/**************************************************************************
 Model with any impairment
**************************************************************************/

ods output OddsRatios=out.logistic_any_impairment_or
           ParameterEstimates=out.logistic_any_impairment_params;

proc logistic data=analysis_final descending;
    class any_impairment(ref="0")
          eta_diagnosicat2(ref="60-69")
          gender(ref="Male")
          indicedep2(ref="1-2")
          numero_patologiecroniche(ref="0")
          sede_grouped(ref="COLONRETTO")
          met_12_mese(ref="0")
          periodo_covid(ref="0")
          / param=ref;

    model emergency_presentation =
          any_impairment
          eta_diagnosicat2
          gender
          indicedep2
          numero_patologiecroniche
          sede_grouped
          met_12_mese
          periodo_covid;
run;

/**************************************************************************
 Sequential models for impairment categories
 Model 1: age and sex
 Model 2: additionally deprivation and chronic conditions
 Model 3: additionally tumour site, metastatic status and period
**************************************************************************/

ods output OddsRatios=out.logistic_model1_or
           ParameterEstimates=out.logistic_model1_params;

proc logistic data=analysis_final descending;
    class funzioni_mentali(ref="0")
          funzioni_sensoriali_dolore(ref="0")
          funz_neuromuscol(ref="0")
          presidi_incontinenza(ref="0")
          presidio_protesica_maggiore(ref="0")
          eta_diagnosicat2(ref="60-69")
          gender(ref="Male")
          / param=ref;

    model emergency_presentation =
          funzioni_mentali
          funzioni_sensoriali_dolore
          funz_neuromuscol
          presidi_incontinenza
          presidio_protesica_maggiore
          eta_diagnosicat2
          gender;
run;

ods output OddsRatios=out.logistic_model2_or
           ParameterEstimates=out.logistic_model2_params;

proc logistic data=analysis_final descending;
    class funzioni_mentali(ref="0")
          funzioni_sensoriali_dolore(ref="0")
          funz_neuromuscol(ref="0")
          presidi_incontinenza(ref="0")
          presidio_protesica_maggiore(ref="0")
          eta_diagnosicat2(ref="60-69")
          gender(ref="Male")
          indicedep2(ref="1-2")
          numero_patologiecroniche(ref="0")
          / param=ref;

    model emergency_presentation =
          funzioni_mentali
          funzioni_sensoriali_dolore
          funz_neuromuscol
          presidi_incontinenza
          presidio_protesica_maggiore
          eta_diagnosicat2
          gender
          indicedep2
          numero_patologiecroniche;
run;

ods output OddsRatios=out.logistic_model3_or
           ParameterEstimates=out.logistic_model3_params;

proc logistic data=analysis_final descending;
    class funzioni_mentali(ref="0")
          funzioni_sensoriali_dolore(ref="0")
          funz_neuromuscol(ref="0")
          presidi_incontinenza(ref="0")
          presidio_protesica_maggiore(ref="0")
          eta_diagnosicat2(ref="60-69")
          gender(ref="Male")
          indicedep2(ref="1-2")
          numero_patologiecroniche(ref="0")
          sede_grouped(ref="COLONRETTO")
          met_12_mese(ref="0")
          periodo_covid(ref="0")
          / param=ref;

    model emergency_presentation =
          funzioni_mentali
          funzioni_sensoriali_dolore
          funz_neuromuscol
          presidi_incontinenza
          presidio_protesica_maggiore
          eta_diagnosicat2
          gender
          indicedep2
          numero_patologiecroniche
          sede_grouped
          met_12_mese
          periodo_covid;
run;

/**************************************************************************
 Period-stratified models
**************************************************************************/

ods output OddsRatios=out.logistic_prepandemic_or
           ParameterEstimates=out.logistic_prepandemic_params;

proc logistic data=analysis_final(where=(periodo_covid=0)) descending;
    class funzioni_mentali(ref="0")
          funzioni_sensoriali_dolore(ref="0")
          funz_neuromuscol(ref="0")
          presidi_incontinenza(ref="0")
          presidio_protesica_maggiore(ref="0")
          eta_diagnosicat2(ref="60-69")
          gender(ref="Male")
          indicedep2(ref="1-2")
          numero_patologiecroniche(ref="0")
          sede_grouped(ref="COLONRETTO")
          met_12_mese(ref="0")
          / param=ref;

    model emergency_presentation =
          funzioni_mentali
          funzioni_sensoriali_dolore
          funz_neuromuscol
          presidi_incontinenza
          presidio_protesica_maggiore
          eta_diagnosicat2
          gender
          indicedep2
          numero_patologiecroniche
          sede_grouped
          met_12_mese;
run;

ods output OddsRatios=out.logistic_pandemic_or
           ParameterEstimates=out.logistic_pandemic_params;

proc logistic data=analysis_final(where=(periodo_covid=1)) descending;
    class funzioni_mentali(ref="0")
          funzioni_sensoriali_dolore(ref="0")
          funz_neuromuscol(ref="0")
          presidi_incontinenza(ref="0")
          presidio_protesica_maggiore(ref="0")
          eta_diagnosicat2(ref="60-69")
          gender(ref="Male")
          indicedep2(ref="1-2")
          numero_patologiecroniche(ref="0")
          sede_grouped(ref="COLONRETTO")
          met_12_mese(ref="0")
          / param=ref;

    model emergency_presentation =
          funzioni_mentali
          funzioni_sensoriali_dolore
          funz_neuromuscol
          presidi_incontinenza
          presidio_protesica_maggiore
          eta_diagnosicat2
          gender
          indicedep2
          numero_patologiecroniche
          sede_grouped
          met_12_mese;
run;

/**************************************************************************
 Interaction tests
**************************************************************************/

ods output ModelFit=out.interaction_period_fit;

proc logistic data=analysis_final descending;
    class funzioni_mentali(ref="0")
          funzioni_sensoriali_dolore(ref="0")
          funz_neuromuscol(ref="0")
          presidi_incontinenza(ref="0")
          presidio_protesica_maggiore(ref="0")
          eta_diagnosicat2(ref="60-69")
          gender(ref="Male")
          indicedep2(ref="1-2")
          numero_patologiecroniche(ref="0")
          sede_grouped(ref="COLONRETTO")
          met_12_mese(ref="0")
          periodo_covid(ref="0")
          / param=ref;

    model emergency_presentation =
          funzioni_mentali
          funzioni_sensoriali_dolore
          funz_neuromuscol
          presidi_incontinenza
          presidio_protesica_maggiore
          eta_diagnosicat2
          gender
          indicedep2
          numero_patologiecroniche
          sede_grouped
          met_12_mese
          periodo_covid
          funzioni_mentali*periodo_covid
          funzioni_sensoriali_dolore*periodo_covid
          funz_neuromuscol*periodo_covid
          presidi_incontinenza*periodo_covid
          presidio_protesica_maggiore*periodo_covid;
run;
