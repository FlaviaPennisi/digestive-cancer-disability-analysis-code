/**************************************************************************
 Program: 05_cox_survival_models_and_adjusted_curves.sas
 Purpose: Estimate one-year overall survival using Cox proportional hazards
          models and generate adjusted survival estimates.
 Software: SAS 9.4
**************************************************************************/

%include "00_setup.sas";

data survival_data;
    set out.analysis_final;

    /* Expected variables:
       incidenza: cancer diagnosis date
       data_decesso: date of death, if applicable
       fine_followup: administrative end of follow-up
    */

    format end_followup censor_date ddmmyy10.;

    one_year_after_diagnosis = intnx("day", incidenza, 365, "same");

    if data_decesso ne . and data_decesso <= one_year_after_diagnosis then do;
        time_os = data_decesso - incidenza;
        death_1y = 1;
    end;
    else do;
        time_os = min(one_year_after_diagnosis, fine_followup) - incidenza;
        death_1y = 0;
    end;

    if time_os < 0 then delete;
run;

/**************************************************************************
 Overall Cox model
**************************************************************************/

ods output HazardRatios=out.cox_overall_hr
           ParameterEstimates=out.cox_overall_params;

proc phreg data=survival_data;
    class funzioni_mentali(ref="0")
          funzioni_sensoriali_dolore(ref="0")
          funz_neuromuscol(ref="0")
          presidi_incontinenza(ref="0")
          presidio_protesica_maggiore(ref="0")
          sede_grouped(ref="COLONRETTO")
          gender(ref="Male")
          eta_diagnosicat2(ref="60-69")
          numero_patologiecroniche(ref="0")
          emergency_presentation(ref="0")
          periodo_covid(ref="0")
          met_12_mese(ref="0")
          / param=ref;

    model time_os*death_1y(0) =
          funzioni_mentali
          funzioni_sensoriali_dolore
          funz_neuromuscol
          presidi_incontinenza
          presidio_protesica_maggiore
          sede_grouped
          gender
          eta_diagnosicat2
          numero_patologiecroniche
          emergency_presentation
          periodo_covid
          met_12_mese;

    hazardratio funzioni_mentali;
    hazardratio funzioni_sensoriali_dolore;
    hazardratio funz_neuromuscol;
    hazardratio presidi_incontinenza;
    hazardratio presidio_protesica_maggiore;
run;

/**************************************************************************
 Cox models stratified by metastatic status
 Corresponds to Figure 1 and Supplementary Table 3
**************************************************************************/

ods output HazardRatios=out.cox_nonmetastatic_hr
           ParameterEstimates=out.cox_nonmetastatic_params;

proc phreg data=survival_data(where=(met_12_mese=0));
    class funzioni_mentali(ref="0")
          funzioni_sensoriali_dolore(ref="0")
          funz_neuromuscol(ref="0")
          presidi_incontinenza(ref="0")
          presidio_protesica_maggiore(ref="0")
          sede_grouped(ref="COLONRETTO")
          gender(ref="Male")
          eta_diagnosicat2(ref="60-69")
          numero_patologiecroniche(ref="0")
          emergency_presentation(ref="0")
          periodo_covid(ref="0")
          / param=ref;

    model time_os*death_1y(0) =
          funzioni_mentali
          funzioni_sensoriali_dolore
          funz_neuromuscol
          presidi_incontinenza
          presidio_protesica_maggiore
          sede_grouped
          gender
          eta_diagnosicat2
          numero_patologiecroniche
          emergency_presentation
          periodo_covid;

    hazardratio funzioni_mentali;
    hazardratio funzioni_sensoriali_dolore;
    hazardratio funz_neuromuscol;
    hazardratio presidi_incontinenza;
    hazardratio presidio_protesica_maggiore;
run;

ods output HazardRatios=out.cox_metastatic_hr
           ParameterEstimates=out.cox_metastatic_params;

proc phreg data=survival_data(where=(met_12_mese=1));
    class funzioni_mentali(ref="0")
          funzioni_sensoriali_dolore(ref="0")
          funz_neuromuscol(ref="0")
          presidi_incontinenza(ref="0")
          presidio_protesica_maggiore(ref="0")
          sede_grouped(ref="COLONRETTO")
          gender(ref="Male")
          eta_diagnosicat2(ref="60-69")
          numero_patologiecroniche(ref="0")
          emergency_presentation(ref="0")
          periodo_covid(ref="0")
          / param=ref;

    model time_os*death_1y(0) =
          funzioni_mentali
          funzioni_sensoriali_dolore
          funz_neuromuscol
          presidi_incontinenza
          presidio_protesica_maggiore
          sede_grouped
          gender
          eta_diagnosicat2
          numero_patologiecroniche
          emergency_presentation
          periodo_covid;

    hazardratio funzioni_mentali;
    hazardratio funzioni_sensoriali_dolore;
    hazardratio funz_neuromuscol;
    hazardratio presidi_incontinenza;
    hazardratio presidio_protesica_maggiore;
run;

/**************************************************************************
 Cox models stratified by diagnostic route
 Corresponds to Figure 2 and Supplementary Table 4
**************************************************************************/

ods output HazardRatios=out.cox_non_ep_hr
           ParameterEstimates=out.cox_non_ep_params;

proc phreg data=survival_data(where=(emergency_presentation=0));
    class funzioni_mentali(ref="0")
          funzioni_sensoriali_dolore(ref="0")
          funz_neuromuscol(ref="0")
          presidi_incontinenza(ref="0")
          presidio_protesica_maggiore(ref="0")
          sede_grouped(ref="COLONRETTO")
          gender(ref="Male")
          eta_diagnosicat2(ref="60-69")
          numero_patologiecroniche(ref="0")
          periodo_covid(ref="0")
          met_12_mese(ref="0")
          / param=ref;

    model time_os*death_1y(0) =
          funzioni_mentali
          funzioni_sensoriali_dolore
          funz_neuromuscol
          presidi_incontinenza
          presidio_protesica_maggiore
          sede_grouped
          gender
          eta_diagnosicat2
          numero_patologiecroniche
          periodo_covid
          met_12_mese;

    hazardratio funzioni_mentali;
    hazardratio funzioni_sensoriali_dolore;
    hazardratio funz_neuromuscol;
    hazardratio presidi_incontinenza;
    hazardratio presidio_protesica_maggiore;
run;

ods output HazardRatios=out.cox_ep_hr
           ParameterEstimates=out.cox_ep_params;

proc phreg data=survival_data(where=(emergency_presentation=1));
    class funzioni_mentali(ref="0")
          funzioni_sensoriali_dolore(ref="0")
          funz_neuromuscol(ref="0")
          presidi_incontinenza(ref="0")
          presidio_protesica_maggiore(ref="0")
          sede_grouped(ref="COLONRETTO")
          gender(ref="Male")
          eta_diagnosicat2(ref="60-69")
          numero_patologiecroniche(ref="0")
          periodo_covid(ref="0")
          met_12_mese(ref="0")
          / param=ref;

    model time_os*death_1y(0) =
          funzioni_mentali
          funzioni_sensoriali_dolore
          funz_neuromuscol
          presidi_incontinenza
          presidio_protesica_maggiore
          sede_grouped
          gender
          eta_diagnosicat2
          numero_patologiecroniche
          periodo_covid
          met_12_mese;

    hazardratio funzioni_mentali;
    hazardratio funzioni_sensoriali_dolore;
    hazardratio funz_neuromuscol;
    hazardratio presidi_incontinenza;
    hazardratio presidio_protesica_maggiore;
run;

/**************************************************************************
 Tumour-site stratified Cox models
 Corresponds to Supplementary Tables 5 and 6
**************************************************************************/

%macro cox_by_site(site=, outprefix=);

    ods output HazardRatios=out.&outprefix._hr
               ParameterEstimates=out.&outprefix._params;

    proc phreg data=survival_data(where=(sede_grouped="&site."));
        class funzioni_mentali(ref="0")
              funzioni_sensoriali_dolore(ref="0")
              funz_neuromuscol(ref="0")
              presidi_incontinenza(ref="0")
              presidio_protesica_maggiore(ref="0")
              gender(ref="Male")
              eta_diagnosicat2(ref="60-69")
              numero_patologiecroniche(ref="0")
              emergency_presentation(ref="0")
              periodo_covid(ref="0")
              met_12_mese(ref="0")
              / param=ref;

        model time_os*death_1y(0) =
              funzioni_mentali
              funzioni_sensoriali_dolore
              funz_neuromuscol
              presidi_incontinenza
              presidio_protesica_maggiore
              gender
              eta_diagnosicat2
              numero_patologiecroniche
              emergency_presentation
              periodo_covid
              met_12_mese;

        hazardratio funzioni_mentali;
        hazardratio funzioni_sensoriali_dolore;
        hazardratio funz_neuromuscol;
        hazardratio presidi_incontinenza;
        hazardratio presidio_protesica_maggiore;
    run;

%mend;

%cox_by_site(site=COLONRETTO, outprefix=cox_colorectal);
%cox_by_site(site=HPB,        outprefix=cox_hpb);
%cox_by_site(site=UPPER GI,   outprefix=cox_uppergi);

/* Save survival analysis dataset */
data out.survival_data;
    set survival_data;
run;
