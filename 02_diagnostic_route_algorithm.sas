/**************************************************************************
 Program: 02_diagnostic_route_algorithm.sas
 Purpose: Derive route to diagnosis using outpatient, hospital discharge,
          emergency department and screening-related healthcare contacts
          before cancer diagnosis.
 Software: SAS 9.4
**************************************************************************/

%include "00_setup.sas";

/* Load cohort */
data cohort_impairment;
    set out.cohort_impairment;
run;

/**************************************************************************
 Outpatient records
**************************************************************************/

data outpatient_1;
    set lib.ambulatoriale;

    giorno = substr(DATA_CONTATTO, 1, 2);
    mese   = substr(DATA_CONTATTO, 3, 2);
    anno   = substr(DATA_CONTATTO, 5, 4);

    format data_contact ddmmyy10.;
    data_contact = mdy(input(mese, 2.), input(giorno, 2.), input(anno, 4.));

    giorno1 = substr(DATA_PRENOTAZIONE, 1, 2);
    mese1   = substr(DATA_PRENOTAZIONE, 3, 2);
    anno1   = substr(DATA_PRENOTAZIONE, 5, 4);

    format data_prenotaz ddmmyy10.;
    data_prenotaz = mdy(input(mese1, 2.), input(giorno1, 2.), input(anno1, 4.));

    drop giorno mese anno giorno1 mese1 anno1 DATA_CONTATTO DATA_PRENOTAZIONE;
run;

proc sql;
    create table outpatient_1 as
    select *
    from outpatient_1
    where data_prenotaz >= "01JAN2016"d;
quit;

data outpatient_2;
    set lib.ambu_extra;

    data_contact = DATA;
    format data_contact ddmmyy10.;

    rename CODICE_PRESTAZIONE = COD_PRESTAZIONE
           CODICE_DISCIPLINA  = DISCIPLINA;

    drop DATA;
run;

data outpatient_all;
    set outpatient_1 outpatient_2;

    drop CODICE_FISCALE REGIME_EROGAZIONE QUANTITA CLASSE_PRIORITA
         DISCIPLINA DIAGNOSI PROVENIENZA;
run;

/* Link outpatient records to cancer cohort */
proc sql;
    create table outpatient_registry as
    select a.*, b.incidenza, b.sede
    from outpatient_all as a
    left join cohort_impairment as b
    on a.case_id = b.case_id;
quit;

/* Identify screening-related outpatient contacts within 6 months */
data outpatient_registry;
    set outpatient_registry;

    where data_contact ne . and data_contact <= incidenza;

    intervallo = incidenza - data_contact;
    id_record = _n_;

    if intervallo <= 180
       and TIPO_PRESTAZIONE = "S"
       and upcase(sede) = "COLONRETTO"
       and COD_PRESTAZIONE in (4525, 4542, 4532, 4824, 90214, 91413, 91414, 91421, 91422)
       then ultimo_contatto = 1;
    else ultimo_contatto = 0;
run;

proc sql;
    create table outpatient_reduced_1 as
    select *
    from outpatient_registry
    group by case_id
    having ultimo_contatto = max(ultimo_contatto);
quit;

proc sql;
    create table outpatient_reduced_2 as
    select *
    from outpatient_reduced_1
    group by case_id
    having intervallo = min(intervallo);
quit;

proc sql;
    create table outpatient_reduced_3 as
    select *
    from outpatient_reduced_2
    group by case_id
    having id_record = min(id_record);
quit;

data outpatient_last_contact;
    set outpatient_reduced_3;

    if ultimo_contatto = 1 and intervallo < 30 then route = "S30";
    else if ultimo_contatto = 1 and intervallo >= 30 then route = "S06";
    else route = "";
run;

proc sql;
    create table cohort_with_outpatient as
    select a.*, b.*
    from outpatient_last_contact as a
    right join cohort_impairment as b
    on a.case_id = b.case_id;
quit;

/**************************************************************************
 Hospital discharge records
**************************************************************************/

data sdo_regional;
    set lib.sdo;

    giorno = substr(DADIM, 7, 2);
    mese   = substr(DADIM, 5, 2);
    anno   = substr(DADIM, 1, 4);

    format dimissione ddmmyy10.;
    dimissione = mdy(input(mese, 2.), input(giorno, 2.), input(anno, 4.));

    drop giorno mese anno DADIM;
run;

data sdo_regional;
    set sdo_regional;

    rename STACIV = statocivile
           POSPRO = professione
           PROVEN = PROVENIENZA
           TIPRIC = tipo
           DIAGN  = principale
           INTERV = INTERVENTO_PRINCIPALE;
run;

data sdo_extra;
    set lib.sdo_fr_new;

    ricovero = datepart(DATA_RICOVERO);
    dimissione = datepart(DATA_DIMISSIONE);

    format ricovero dimissione ddmmyy10.;

    rename tipo_ricovero = tipo
           modalita_dimissione = modim
           DIAGNOSI_PRINCIPALE = principale
           DIAGNOSI_CONCOMITANTE_1 = cond1
           DIAGNOSI_CONCOMITANTE_2 = cond2
           DIAGNOSI_CONCOMITANTE_3 = cond3
           DIAGNOSI_CONCOMITANTE_4 = cond4
           DIAGNOSI_CONCOMITANTE_5 = cond5
           ALTRO_INTERVENTO_1 = int1
           ALTRO_INTERVENTO_2 = int2
           ALTRO_INTERVENTO_3 = int3
           ALTRO_INTERVENTO_4 = int4
           ALTRO_INTERVENTO_5 = int5
           stato_civile = statocivile;

    drop DATA_RICOVERO DATA_DIMISSIONE;
run;

data sdo_all;
    set sdo_extra sdo_regional;
run;

proc sql;
    create table sdo_registry as
    select a.*, b.incidenza
    from sdo_all as a
    left join cohort_impairment as b
    on a.case_id = b.case_id;
quit;

/* Last hospital contact before diagnosis */
proc sql;
    create table sdo_last_contact as
    select distinct a.case_id, a.incidenza, b.ricovero as sdo_ultimocontatto format=ddmmyy10.
    from (
        select case_id, incidenza, ricovero, max(ricovero) as max_contact
        from sdo_registry
        where ricovero < incidenza
        group by case_id, incidenza
    ) as a
    inner join sdo_registry as b
    on a.case_id = b.case_id and a.max_contact = b.ricovero
    order by case_id, incidenza;
quit;

/**************************************************************************
 Emergency department records
**************************************************************************/

data ps;
    set lib.ps;

    data_entrata_num = input(data_entrata, yymmdd8.);
    format data_entrata_num ddmmyy10.;
run;

proc sql;
    create table ps_registry as
    select a.*, b.incidenza
    from ps as a
    left join cohort_impairment as b
    on a.case_id = b.case_id;
quit;

/* Last emergency department contact before diagnosis */
proc sql;
    create table ps_last_contact as
    select distinct a.case_id, a.incidenza, b.data_entrata_num as ps_ultimocontatto format=ddmmyy10.
    from (
        select case_id, incidenza, data_entrata_num, max(data_entrata_num) as max_contact
        from ps_registry
        where data_entrata_num < incidenza
        group by case_id, incidenza
    ) as a
    inner join ps_registry as b
    on a.case_id = b.case_id and a.max_contact = b.data_entrata_num
    order by case_id, incidenza;
quit;

/**************************************************************************
 Merge routes and define final route to diagnosis
**************************************************************************/

proc sql;
    create table route_data_1 as
    select a.*, b.sdo_ultimocontatto
    from cohort_with_outpatient as a
    left join sdo_last_contact as b
    on a.case_id = b.case_id;
quit;

proc sql;
    create table route_data_2 as
    select a.*, b.ps_ultimocontatto
    from route_data_1 as a
    left join ps_last_contact as b
    on a.case_id = b.case_id;
quit;

data route_data;
    set route_data_2;

    rename data_contact = ambu_ultimocontatto2;
run;

data route_data;
    set route_data;

    if route = "" and ps_ultimocontatto ne . and (incidenza - ps_ultimocontatto <= 30)
        then route = "e30";

    else if route = ""
        and (
            (ambu_ultimocontatto2 ne . and (incidenza - ambu_ultimocontatto2 <= 30))
            or
            (sdo_ultimocontatto ne . and (incidenza - sdo_ultimocontatto <= 30))
        )
        then route = "a30";

    else if route = "" and ps_ultimocontatto ne . and (incidenza - ps_ultimocontatto <= 180)
        then route = "e06";

    else if route = ""
        and (
            (ambu_ultimocontatto2 ne . and (incidenza - ambu_ultimocontatto2 <= 180))
            or
            (sdo_ultimocontatto ne . and (incidenza - sdo_ultimocontatto <= 180))
        )
        then route = "a06";
run;

/* Simplified route variables */
data route_data;
    set route_data;

    length percorso $1 percorso2 $4;
    durata = input(substr(route, 2, 2), 2.);

    percorso = substr(route, 1, 1);

    if percorso in ("S", "a") then percorso2 = "s/a";
    else if percorso = "e" then percorso2 = "e";

    if percorso2 = "e" then emergency_presentation = 1;
    else if percorso2 = "s/a" then emergency_presentation = 0;
    else emergency_presentation = .;
run;

data out.analysis_route;
    set route_data;
run;
