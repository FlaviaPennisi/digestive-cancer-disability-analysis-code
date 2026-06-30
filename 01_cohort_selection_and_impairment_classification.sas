/**************************************************************************
 Program: 01_cohort_selection_and_impairment_classification.sas
 Purpose: Select incident digestive system cancer cases diagnosed in 2018-2021
          and derive pre-existing impairment categories.
 Software: SAS 9.4
**************************************************************************/

%include "00_setup.sas";

/* Remove duplicate cancer registry records, keeping the first diagnosis date */
data work_registry;
    set lib.casi_new;
    record_id = _n_;
run;

proc sort data=work_registry out=registry_sorted;
    by case_id incidenza;
run;

proc sort data=registry_sorted out=registry_nodup nodupkey;
    by case_id;
run;

/* Select digestive system cancers diagnosed from 2018 to 2021 */
data cancer_cohort;
    set registry_nodup;
    where year(incidenza) >= 2018
      and year(incidenza) <= 2021
      and upcase(sede) in ("COLONRETTO", "ESOFAGO", "PANCREAS", "FEGATO", "STOMACO");

    anno_incidenza = year(incidenza);
run;

/* Merge cancer cohort with impairment/disability data */
proc sort data=cancer_cohort;
    by case_id;
run;

proc sort data=lib.diabilita out=disability_sorted;
    by case_id;
run;

data cohort_disability;
    merge cancer_cohort(in=a)
          disability_sorted(in=b);
    by case_id;
    if a;
run;

/* Define pre-existing impairment:
   impairment present in or before the year of cancer diagnosis */
data cohort_disability;
    set cohort_disability;

    array disab[2018:2022] disabile_2018 - disabile_2022;

    disabileprimadeltumore = 0;

    do anno = 2018 to anno_incidenza;
        if anno >= 2018 and anno <= 2022 then do;
            if disab[anno] = 1 then do;
                disabileprimadeltumore = 1;
                leave;
            end;
        end;
    end;
run;

/* Derive ICF-based impairment categories */
data cohort_disability;
    set cohort_disability;

    funzioni_mentali = 0;
    funzioni_sensoriali_dolore = 0;
    funzioni_fonatorie_parlato = 0;
    funzioni_cardiovas_respiratorio = 0;
    funzioni_digerente_metabolico = 0;
    funzioni_genitourinarie = 0;
    funz_neuromuscol = 0;
    presidi_incontinenza = 0;
    presidio_protesica_maggiore = 0;
    invalidita_accompagnamento = 0;
    funzioni_pelle = 0;

    if disabileprimadeltumore = 1 then do;

        if index(upcase(stringa_chiaro1), "FUNZIONI MENTALI") > 0
            then funzioni_mentali = 1;

        if index(upcase(stringa_chiaro1), "FUNZIONI SENSORIALI E DOLORE") > 0
            then funzioni_sensoriali_dolore = 1;

        if index(upcase(stringa_chiaro1), "FUNZIONI FONATORIE E DI PRODUZIONE DEL PARLATO") > 0
            then funzioni_fonatorie_parlato = 1;

        if index(upcase(stringa_chiaro1), "FUNZIONI DEGLI APPARATI CARDIOVASCOLARE E RESPIRATORIO") > 0
            then funzioni_cardiovas_respiratorio = 1;

        if index(upcase(stringa_chiaro1), "FUNZIONI APPARATO DIGERENTE") > 0
            then funzioni_digerente_metabolico = 1;

        if index(upcase(stringa_chiaro1), "FUNZIONI GENITOURINARIE E RIPRODUTTIVE") > 0
            then funzioni_genitourinarie = 1;

        if index(upcase(stringa_chiaro1), "FUNZIONI NEUROMUSCOLOSCHELETRICHE E CORRELATE AL MOVIMENTO") > 0
            then funz_neuromuscol = 1;

        if index(upcase(stringa_chiaro1), "PRESIDI PER INCONTINENZA") > 0
            then presidi_incontinenza = 1;

        if index(upcase(stringa_chiaro1), "PRESIDIO DI PROTESICA MAGGIORE") > 0
            then presidio_protesica_maggiore = 1;

        if index(upcase(stringa_chiaro1), "INVALIDITÀ CON ACCOMPAGNAMENTO") > 0
            then invalidita_accompagnamento = 1;

        if index(upcase(stringa_chiaro1), "FUNZIONI DELLA PELLE E DELLE STRUTTURE CORRELATE") > 0
            then funzioni_pelle = 1;
    end;
run;

/* Count impairment categories used in the main analyses */
data cohort_impairment;
    set cohort_disability;

    any_impairment = max(
        funzioni_mentali,
        funzioni_sensoriali_dolore,
        funz_neuromuscol,
        presidi_incontinenza,
        presidio_protesica_maggiore
    );

    conta_disabilita = sum(
        funzioni_mentali,
        funzioni_sensoriali_dolore,
        funz_neuromuscol,
        presidi_incontinenza,
        presidio_protesica_maggiore
    );

    length numero_disabilita $10;

    if conta_disabilita = 0 then numero_disabilita = "0";
    else if conta_disabilita = 1 then numero_disabilita = "1";
    else if conta_disabilita = 2 then numero_disabilita = "2";
    else if conta_disabilita >= 3 then numero_disabilita = "3+";
run;

/* Tumour site grouping */
data cohort_impairment;
    set cohort_impairment;

    length sede_grouped $20;

    if upcase(sede) in ("COLON", "RETTO", "COLONRETTO") then sede_grouped = "COLONRETTO";
    else if upcase(sede) in ("STOMACO", "ESOFAGO") then sede_grouped = "UPPER GI";
    else if upcase(sede) in ("FEGATO", "PANCREAS") then sede_grouped = "HPB";
    else sede_grouped = "OTHER";
run;

/* Save clean cohort after impairment classification */
data out.cohort_impairment;
    set cohort_impairment;
run;
