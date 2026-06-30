/**************************************************************************
 Program: 03_covariates_and_descriptive_tables.sas
 Purpose: Derive covariates and generate descriptive tables.
 Software: SAS 9.4
**************************************************************************/

%include "00_setup.sas";

data analysis_data;
    set out.analysis_route;
run;

/* Age at diagnosis */
data analysis_data;
    set analysis_data;

    format dnascita incidenza ddmmyy10.;

    eta_diagnosi = intck("year", dnascita, incidenza);

    if month(incidenza) < month(dnascita)
       or (month(incidenza) = month(dnascita) and day(incidenza) < day(dnascita))
       then eta_diagnosi = eta_diagnosi - 1;

    length eta_diagnosicat $10 eta_diagnosicat2 $10;

    if eta_diagnosi < 50 then eta_diagnosicat = "<50";
    else if 50 <= eta_diagnosi <= 59 then eta_diagnosicat = "50-59";
    else if 60 <= eta_diagnosi <= 69 then eta_diagnosicat = "60-69";
    else if 70 <= eta_diagnosi <= 79 then eta_diagnosicat = "70-79";
    else if 80 <= eta_diagnosi <= 89 then eta_diagnosicat = "80-89";
    else if eta_diagnosi >= 90 then eta_diagnosicat = ">=90";

    if eta_diagnosi < 50 then eta_diagnosicat2 = "<50";
    else if 50 <= eta_diagnosi <= 59 then eta_diagnosicat2 = "50-59";
    else if 60 <= eta_diagnosi <= 69 then eta_diagnosicat2 = "60-69";
    else if 70 <= eta_diagnosi <= 79 then eta_diagnosicat2 = "70-79";
    else if eta_diagnosi >= 80 then eta_diagnosicat2 = ">=80";
run;

/* Pre-pandemic and pandemic periods */
data analysis_data;
    set analysis_data;

    if anno_incidenza in (2018, 2019) then periodo_covid = 0;
    else if anno_incidenza in (2020, 2021) then periodo_covid = 1;
    else periodo_covid = .;
run;

/* Merge sociodemographic data */
proc sql;
    create table analysis_data as
    select a.*, b.*
    from analysis_data as a
    left join lib.anag3 as b
    on a.case_id = b.case_id;
quit;

/* Merge deprivation index */
proc sql;
    create table analysis_data as
    select a.*, b.*
    from analysis_data as a
    left join lib.anag_dep as b
    on a.case_id = b.case_id;
quit;

/* Deprivation index grouped */
data analysis_data;
    set analysis_data;

    length indicedep2 $10;

    if ID_cat_reg in (1, 2) then indicedep2 = "1-2";
    else if ID_cat_reg in (3, 4, 5) then indicedep2 = "3-5";
run;

/* Merge chronic disease indicators */
proc sql;
    create table bda_without_dupkey as
    select distinct *
    from lib.bda
    group by case_id
    having DT_C08 = min(DT_C08);
quit;

proc sql;
    create table analysis_data as
    select a.*, b.*
    from analysis_data as a
    left join bda_without_dupkey as b
    on a.case_id = b.case_id;
quit;

/* Chronic disease categories before or at cancer diagnosis */
data analysis_data;
    set analysis_data;

    if (DT_C20 ne . or DT_C27 ne . or DT_C28 ne . or DT_C29 ne . or DT_C33 ne .)
       and min(DT_C20, DT_C27, DT_C28, DT_C29, DT_C33) <= incidenza
       then malattiecardiache = 1;
    else malattiecardiache = 0;

    if DT_C25 ne . and DT_C25 <= incidenza then malattiecerebrovasc = 1;
    else malattiecerebrovasc = 0;

    if (DT_C38 ne . or DT_C32 ne . or DT_C47 ne . or DT_C14 ne . or DT_C12 ne . or DT_C42 ne . or DT_C31 ne .)
       and min(DT_C38, DT_C32, DT_C47, DT_C14, DT_C12, DT_C42, DT_C31) <= incidenza
       then malattienervoso2 = 1;
    else malattienervoso2 = 0;

    if (DT_C43 ne . or DT_C10 ne . or DT_C52 ne . or DT_C30 ne . or DT_C18 ne .)
       and min(DT_C43, DT_C10, DT_C52, DT_C30, DT_C18) <= incidenza
       then diabete = 1;
    else diabete = 0;

    if (DT_C02 ne . or DT_C19 ne . or DT_C54 ne .)
       and min(DT_C02, DT_C19, DT_C54) <= incidenza
       then malattiegenitourinarie = 1;
    else malattiegenitourinarie = 0;
run;

/* Number of chronic conditions used in the manuscript */
data analysis_data;
    set analysis_data;

    conta_comorbidita = sum(
        malattiecardiache,
        malattiecerebrovasc,
        malattienervoso2,
        diabete,
        malattiegenitourinarie
    );

    length numero_patologiecroniche $10;

    if conta_comorbidita = 0 then numero_patologiecroniche = "0";
    else if conta_comorbidita = 1 then numero_patologiecroniche = "1";
    else if conta_comorbidita = 2 then numero_patologiecroniche = "2";
    else if conta_comorbidita >= 3 then numero_patologiecroniche = "3+";
run;

/* Remove duplicate records after merges */
proc sort data=analysis_data out=analysis_data_sorted;
    by case_id;
run;

data analysis_final;
    set analysis_data_sorted;
    by case_id;
    if first.case_id;
run;

/* Descriptive tables corresponding to Supplementary Dataset 1 */
ods output CrossTabFreqs=out.supp_dataset1_crosstabs
           ChiSq=out.supp_dataset1_chisq;

proc freq data=analysis_final;
    tables eta_diagnosicat * funzioni_mentali / chisq;
    tables gender * funzioni_mentali / chisq;
    tables indicedep2 * funzioni_mentali / chisq;
    tables numero_patologiecroniche * funzioni_mentali / chisq;
    tables emergency_presentation * funzioni_mentali / chisq;
    tables met_12_mese * funzioni_mentali / chisq;
    tables sede_grouped * funzioni_mentali / chisq;

    tables eta_diagnosicat * funzioni_sensoriali_dolore / chisq;
    tables gender * funzioni_sensoriali_dolore / chisq;
    tables indicedep2 * funzioni_sensoriali_dolore / chisq;
    tables numero_patologiecroniche * funzioni_sensoriali_dolore / chisq;
    tables emergency_presentation * funzioni_sensoriali_dolore / chisq;
    tables met_12_mese * funzioni_sensoriali_dolore / chisq;
    tables sede_grouped * funzioni_sensoriali_dolore / chisq;

    tables eta_diagnosicat * funz_neuromuscol / chisq;
    tables gender * funz_neuromuscol / chisq;
    tables indicedep2 * funz_neuromuscol / chisq;
    tables numero_patologiecroniche * funz_neuromuscol / chisq;
    tables emergency_presentation * funz_neuromuscol / chisq;
    tables met_12_mese * funz_neuromuscol / chisq;
    tables sede_grouped * funz_neuromuscol / chisq;

    tables eta_diagnosicat * presidi_incontinenza / chisq;
    tables gender * presidi_incontinenza / chisq;
    tables indicedep2 * presidi_incontinenza / chisq;
    tables numero_patologiecroniche * presidi_incontinenza / chisq;
    tables emergency_presentation * presidi_incontinenza / chisq;
    tables met_12_mese * presidi_incontinenza / chisq;
    tables sede_grouped * presidi_incontinenza / chisq;

    tables eta_diagnosicat * presidio_protesica_maggiore / chisq;
    tables gender * presidio_protesica_maggiore / chisq;
    tables indicedep2 * presidio_protesica_maggiore / chisq;
    tables numero_patologiecroniche * presidio_protesica_maggiore / chisq;
    tables emergency_presentation * presidio_protesica_maggiore / chisq;
    tables met_12_mese * presidio_protesica_maggiore / chisq;
    tables sede_grouped * presidio_protesica_maggiore / chisq;

    tables eta_diagnosicat * any_impairment / chisq;
    tables gender * any_impairment / chisq;
    tables indicedep2 * any_impairment / chisq;
    tables numero_patologiecroniche * any_impairment / chisq;
    tables emergency_presentation * any_impairment / chisq;
    tables met_12_mese * any_impairment / chisq;
    tables sede_grouped * any_impairment / chisq;
run;

data out.analysis_final;
    set analysis_final;
run;
