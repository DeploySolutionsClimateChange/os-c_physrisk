-- SETUP EXTENSIONS
CREATE EXTENSION postgis;
CREATE EXTENSION h3;
CREATE EXTENSION pgcrypto;

-- SETUP SCHEMAS
CREATE SCHEMA IF NOT EXISTS osc_physrisk_scenarios;
CREATE SCHEMA IF NOT EXISTS osc_physrisk_hazards;
CREATE SCHEMA IF NOT EXISTS osc_physrisk_assets;
CREATE SCHEMA IF NOT EXISTS osc_physrisk_risk_analysis;

-- SETUP TABLES
CREATE TABLE osc_physrisk_hazards.hazard ( 
	hazard_id	UUID  DEFAULT gen_random_uuid () NOT NULL,
	description_full   varchar(8096)    ,
	description_short  varchar(256)  NOT NULL  ,
	name_fullyqualified varchar(256)    ,
	name        varchar(100)  NOT NULL  ,
	creation_time     timestamptz  NOT NULL  ,
	creator_user_id      bigint    ,
	last_modification_time timestamptz    ,
	last_modifier_user_id bigint    ,
	is_deleted      boolean  NOT NULL  ,
	deleter_user_id      bigint    ,
	deletion_time       timestamptz    ,
	culture            varchar(5)  NOT NULL  ,
	checksum           text    ,
	external_id         varchar(36)    ,
	seq_num             integer  NOT NULL  ,
	translated_from_id   bigint  NOT NULL  ,
	is_active       boolean  NOT NULL  ,
	creator_user_name   varchar(256)    ,
	last_modifier_user_name varchar(256)    ,
	deleter_user_name   varchar(256)    ,
	tenant_id        integer  NOT NULL  ,
	tenant_name        text  NOT NULL  ,
	is_published       boolean  NOT NULL  ,
	publisher_id        bigint    ,
	published_date      timestamptz    ,
	oed_input_abbreviation      varchar(5)  NOT NULL,
	oed_grouped_peril_code boolean NOT NULL,
	CONSTRAINT pk_hazard PRIMARY KEY ( hazard_id )
 );

CREATE TABLE osc_physrisk_assets.fact_portfolio ( 
	portfolio_id                UUID  DEFAULT gen_random_uuid () NOT NULL,
	description_full  varchar(8096)    ,
	description_short  varchar(256)  NOT NULL  ,
	name_fullyqualified varchar(256)    ,
	name          varchar(100)  NOT NULL  ,
	creation_time       timestamptz  NOT NULL  ,
	creator_user_id      bigint    ,
	last_modification_time timestamptz    ,
	last_modifier_user_id bigint    ,
	is_deleted          boolean  NOT NULL  ,
	deleter_user_id     bigint    ,
	deletion_time      timestamptz    ,
	culture        varchar(5)  NOT NULL  ,
	checksum        text    ,
	external_id         varchar(36)    ,
	seq_num         integer  NOT NULL  ,
	translated_from_id   UUID  ,
	is_active       boolean  NOT NULL  ,
	creator_user_name   varchar(256)    ,
	last_modifier_user_name varchar(256)    ,
	deleter_user_name    varchar(256)    ,
	tenant_id           integer  NOT NULL  ,
	tenant_name         text  NOT NULL  ,
	is_published        boolean  NOT NULL  ,
	publisher_id        bigint    ,
	published_date      timestamptz    ,
	CONSTRAINT pk_fact_portfolio PRIMARY KEY (portfolio_id )
 );

CREATE TABLE osc_physrisk_assets.fact_asset ( 
	asset_id                UUID  DEFAULT gen_random_uuid () NOT NULL,
	description_full  varchar(8096)    ,
	description_short  varchar(256)  NOT NULL  ,
	name_fullyqualified varchar(256)    ,
	name          varchar(100)  NOT NULL  ,
	creation_time       timestamptz  NOT NULL  ,
	creator_user_id      bigint    ,
	last_modification_time timestamptz    ,
	last_modifier_user_id bigint    ,
	is_deleted          boolean  NOT NULL  ,
	deleter_user_id     bigint    ,
	deletion_time      timestamptz    ,
	culture        varchar(5)  NOT NULL  ,
	checksum        text    ,
	external_id         varchar(36)    ,
	seq_num         integer  NOT NULL  ,
	translated_from_id   UUID  ,
	is_active       boolean  NOT NULL  ,
	creator_user_name   varchar(256)    ,
	last_modifier_user_name varchar(256)    ,
	deleter_user_name    varchar(256)    ,
	tenant_id           integer  NOT NULL  ,
	tenant_name         text  NOT NULL  ,
	is_published        boolean  NOT NULL  ,
	publisher_id        bigint    ,
	published_date      timestamptz    ,
    portfolio_id UUID NOT NULL,
	location      	GEOGRAPHY  NOT NULL  ,
	gers_id			UUID,
	h3_index H3INDEX NOT NULL,
    h3_resolution INT2 NOT NULL,
	asset_type	varchar(256),
	asset_class varchar(256),
	owner_bloomberg_id	varchar(12) DEFAULT NULL,
	owner_lei_id varchar(20) DEFAULT NULL,
	CONSTRAINT pk_fact_asset PRIMARY KEY ( asset_id ),
	CONSTRAINT fk_fact_asset_portfolio_id FOREIGN KEY ( portfolio_id ) REFERENCES osc_physrisk_assets.fact_portfolio(portfolio_id),
    CONSTRAINT ck_fact_asset_h3_resolution CHECK (h3_resolution >= 0 AND h3_resolution <= 15)
 );


CREATE TABLE osc_physrisk_scenarios.dim_scenario_type ( 
	scenario_type_id integer  NOT NULL,
	description_full   varchar(8096)    ,
	description_short  varchar(256)  NOT NULL  ,
	name_fullyqualified varchar(256)    ,
	name          varchar(100)  NOT NULL  ,
	creation_time       timestamptz  NOT NULL  ,
	creator_user_id      bigint    ,
	last_modification_time timestamptz    ,
	last_modifier_user_id bigint    ,
	is_deleted          boolean  NOT NULL  ,
	deleter_user_id      bigint    ,
	deletion_time       timestamptz    ,
	culture            varchar(5)  NOT NULL  ,
	checksum           text    ,
	seq_num             integer  NOT NULL  ,
	translated_from_id   integer  ,
	is_active           boolean  NOT NULL  ,
	creator_user_name    varchar(256)    ,
	last_modifier_user_name varchar(256)    ,
	deleter_user_name    varchar(256)    ,
	is_published        boolean  NOT NULL  ,
	publisher_id        bigint    ,
	published_date      timestamptz,
	CONSTRAINT pk_dim_scenario_type PRIMARY KEY ( scenario_type_id )
 ); 

CREATE TABLE osc_physrisk_risk_analysis.dim_impact_type ( 
	impact_type_id integer NOT NULL,
	description_full   varchar(8096)    ,
	description_short  varchar(256)  NOT NULL  ,
	name_fullyqualified varchar(256)    ,
	name          varchar(100)  NOT NULL  ,
	creation_time       timestamptz  NOT NULL  ,
	creator_user_id      bigint    ,
	last_modification_time timestamptz    ,
	last_modifier_user_id bigint    ,
	is_deleted          boolean  NOT NULL  ,
	deleter_user_id      bigint    ,
	deletion_time       timestamptz    ,
	culture            varchar(5)  NOT NULL  ,
	checksum           text    ,
	seq_num             integer  NOT NULL  ,
	translated_from_id   UUID,
	is_active           boolean  NOT NULL  ,
	creator_user_name    varchar(256)    ,
	last_modifier_user_name varchar(256)    ,
	deleter_user_name    varchar(256)    ,
	is_published        boolean  NOT NULL  ,
	publisher_id        bigint    ,
	published_date      timestamptz  ,
	CONSTRAINT pk_dim_impact_type PRIMARY KEY ( impact_type_id )
 ); 

CREATE TABLE osc_physrisk_risk_analysis.fact_portfolio_analysis ( 
	portfolio_analysis_id UUID  DEFAULT gen_random_uuid () NOT NULL,
	description_full   varchar(8096)    ,
	description_short  varchar(256)  NOT NULL  ,
	name_fullyqualified varchar(256)    ,
	name          varchar(100)  NOT NULL  ,
	creation_time       timestamptz  NOT NULL  ,
	creator_user_id      bigint    ,
	last_modification_time timestamptz    ,
	last_modifier_user_id bigint    ,
	is_deleted          boolean  NOT NULL  ,
	deleter_user_id      bigint    ,
	deletion_time       timestamptz    ,
	culture            varchar(5)  NOT NULL  ,
	checksum           text    ,
	external_id         varchar(36)    ,
	seq_num             integer  NOT NULL  ,
	translated_from_id   UUID,
	is_active           boolean  NOT NULL  ,
	creator_user_name    varchar(256)    ,
	last_modifier_user_name varchar(256)    ,
	deleter_user_name    varchar(256)    ,
	tenant_id           integer  NOT NULL  ,
	tenant_name         text  NOT NULL  ,
	is_published        boolean  NOT NULL  ,
	publisher_id        bigint    ,
	published_date      timestamptz    ,
	portfolio_id            UUID  NOT NULL  ,
	scenario_type_id integer NOT NULL,
    scenario_year smallint,
	hazard_id UUID NOT NULL,
    impact_type_id integer NOT NULL,
    value_at_risk float,
	annual_exceedence_probability float,
	average_annual_loss float,
    currency_alphabetic_code char(3),
	CONSTRAINT pk_fact_portfolio_analysis PRIMARY KEY ( portfolio_analysis_id ),
	CONSTRAINT fk_fact_portfolio_analysis_portfolio_id FOREIGN KEY ( portfolio_id ) REFERENCES osc_physrisk_assets.fact_portfolio(portfolio_id),
	CONSTRAINT fk_fact_portfolio_analysis_scenario_type_id FOREIGN KEY ( scenario_type_id ) REFERENCES osc_physrisk_scenarios.dim_scenario_type(scenario_type_id),
	CONSTRAINT fk_fact_portfolio_analysis_impact_type_id FOREIGN KEY ( impact_type_id ) REFERENCES osc_physrisk_risk_analysis.dim_impact_type(impact_type_id),
	CONSTRAINT fk_fact_portfolio_analysis_hazard_id FOREIGN KEY ( hazard_id ) REFERENCES osc_physrisk_hazards.hazard(hazard_id)     
 );

CREATE TABLE osc_physrisk_risk_analysis.fact_asset_analysis ( 
	asset_analysis_id UUID  DEFAULT gen_random_uuid () NOT NULL,
	description_full   varchar(8096)    ,
	description_short  varchar(256)  NOT NULL  ,
	name_fullyqualified varchar(256)    ,
	name          varchar(100)  NOT NULL  ,
	creation_time       timestamptz  NOT NULL  ,
	creator_user_id      bigint    ,
	last_modification_time timestamptz    ,
	last_modifier_user_id bigint    ,
	is_deleted          boolean  NOT NULL  ,
	deleter_user_id      bigint    ,
	deletion_time       timestamptz    ,
	culture            varchar(5)  NOT NULL  ,
	checksum           text    ,
	external_id         varchar(36)    ,
	seq_num             integer  NOT NULL  ,
	translated_from_id   UUID,
	is_active           boolean  NOT NULL  ,
	creator_user_name    varchar(256)    ,
	last_modifier_user_name varchar(256)    ,
	deleter_user_name    varchar(256)    ,
	tenant_id           integer  NOT NULL  ,
	tenant_name         text  NOT NULL  ,
	is_published        boolean  NOT NULL  ,
	publisher_id        bigint    ,
	published_date      timestamptz    ,
	asset_id            UUID  NOT NULL  ,
	location varchar(256),  
    coordinates      	GEOGRAPHY  NOT NULL  ,
	gers_id			UUID,
	h3_index H3INDEX NOT NULL,
    h3_resolution INT2 NOT NULL,
	scenario_type_id integer NOT NULL,
    scenario_year smallint,
	hazard_id UUID NOT NULL,
    impact_type_id integer NOT NULL,
    value_at_risk float,
    currency_alphabetic_code char(3),
	probability float,
	CONSTRAINT pk_fact_asset_analysis PRIMARY KEY ( asset_analysis_id ),
    CONSTRAINT ck_fact_asset_analysis_h3_resolution CHECK (h3_resolution >= 0 AND h3_resolution <= 15),
	CONSTRAINT fk_fact_asset_analysis_asset_id FOREIGN KEY ( asset_id ) REFERENCES osc_physrisk_assets.fact_asset(asset_id),
	CONSTRAINT fk_fact_asset_analysis_scenario_type_id FOREIGN KEY ( scenario_type_id ) REFERENCES osc_physrisk_scenarios.dim_scenario_type(scenario_type_id),
	CONSTRAINT fk_fact_asset_analysis_impact_type_id FOREIGN KEY ( impact_type_id ) REFERENCES osc_physrisk_risk_analysis.dim_impact_type(impact_type_id),
	CONSTRAINT fk_fact_asset_analysis_hazard_id FOREIGN KEY ( hazard_id ) REFERENCES osc_physrisk_hazards.hazard(hazard_id)     
 );

-- SETUP PERMISSIONS
--GRANT USAGE ON SCHEMA "osc.physrisk.data_example.comp_domain" TO physrisk_service;
--GRANT SELECT ON ALL TABLES IN SCHEMA "osc.physrisk.data_example.comp_domain" TO physrisk_service;
--GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA "osc.physrisk.data_example.comp_domain" TO physrisk_service;
--GRANT ALL ON ALL TABLES IN SCHEMA "osc.physrisk.data_example.comp_domain" TO physrisk_service;


-- DATA IN ENGLISH STARTS
INSERT INTO osc_physrisk.osc_physrisk_scenarios.dim_scenario_type
	(scenario_type_id, description_full, description_short, name_fullyqualified, "name", creation_time, creator_user_id, last_modification_time, last_modifier_user_id, is_deleted, deleter_user_id, deletion_time, culture, checksum, seq_num, translated_from_id, is_active, creator_user_name, last_modifier_user_name, deleter_user_name, is_published, publisher_id, published_date)
VALUES 
	(-1, 'Unknown/Not Selected', 'Unknown/Not Selected', 'Unknown/Not Selected', 'Unknown/Not Selected','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'en', 'f098938cd8cc7c4f1c71c8e97db0f075',1,NULL, 'y', 'OS-C', 'OS-C', 'OS-C','y', 1,'2024-07-15T00:00:01Z')
;
INSERT INTO osc_physrisk.osc_physrisk_scenarios.dim_scenario_type
	(scenario_type_id, description_full, description_short, name_fullyqualified, "name", creation_time, creator_user_id, last_modification_time, last_modifier_user_id, is_deleted, deleter_user_id, deletion_time, culture, checksum, seq_num, translated_from_id, is_active, creator_user_name, last_modifier_user_name, deleter_user_name, is_published, publisher_id, published_date)
VALUES 
	(0, 'History (before 2014). See "Shared Socioeconomic Pathways in the IPCC Sixth Assessment Report" (https://www.ipcc.ch/report/sixth-assessment-report-working-group-i/).', 'History (before 2014)', 'History (- 2014)', 'History (- 2014)','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'en', 'checksum',1,NULL, 'y', 'OS-C', 'OS-C', 'OS-C','y', 1,'2024-07-15T00:00:01Z')
;
INSERT INTO osc_physrisk.osc_physrisk_scenarios.dim_scenario_type
	(scenario_type_id, description_full, description_short, name_fullyqualified, "name", creation_time, creator_user_id, last_modification_time, last_modifier_user_id, is_deleted, deleter_user_id, deletion_time, culture, checksum, seq_num, translated_from_id, is_active, creator_user_name, last_modifier_user_name, deleter_user_name, is_published, publisher_id, published_date)
VALUES 
	(1, 'SSP1-1.9 -  very low GHG emissions: CO2 emissions cut to net zero around 2050. See "Shared Socioeconomic Pathways in the IPCC Sixth Assessment Report" (https://www.ipcc.ch/report/sixth-assessment-report-working-group-i/).', 'SSP1-1.9', 'SSP1-1.9', 'SSP1-1.9','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'en', 'checksum',1,NULL, 'y', 'OS-C', 'OS-C', 'OS-C','y', 1,'2024-07-15T00:00:01Z')
;
INSERT INTO osc_physrisk.osc_physrisk_scenarios.dim_scenario_type
	(scenario_type_id, description_full, description_short, name_fullyqualified, "name", creation_time, creator_user_id, last_modification_time, last_modifier_user_id, is_deleted, deleter_user_id, deletion_time, culture, checksum, seq_num, translated_from_id, is_active, creator_user_name, last_modifier_user_name, deleter_user_name, is_published, publisher_id, published_date)
VALUES 
	(2, 'SSP1-2.6 - low GHG emissions: CO2 emissions cut to net zero around 2075. See "Shared Socioeconomic Pathways in the IPCC Sixth Assessment Report" (https://www.ipcc.ch/report/sixth-assessment-report-working-group-i/).', 'SSP1-2.6', 'SSP1-2.6', 'SSP1-2.6','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'en', 'checksum',1,NULL, 'y', 'OS-C', 'OS-C', 'OS-C','y', 1,'2024-07-15T00:00:01Z')
;
INSERT INTO osc_physrisk.osc_physrisk_scenarios.dim_scenario_type
	(scenario_type_id, description_full, description_short, name_fullyqualified, "name", creation_time, creator_user_id, last_modification_time, last_modifier_user_id, is_deleted, deleter_user_id, deletion_time, culture, checksum, seq_num, translated_from_id, is_active, creator_user_name, last_modifier_user_name, deleter_user_name, is_published, publisher_id, published_date)
VALUES 
	(3, 'SSP2-4.5 - intermediate GHG emissions: CO2 emissions around current levels until 2050, then falling but not reaching net zero by 2100. See "Shared Socioeconomic Pathways in the IPCC Sixth Assessment Report" (https://www.ipcc.ch/report/sixth-assessment-report-working-group-i/).', 'SSP2-4.5', 'SSP2-4.5', 'SSP2-4.5','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'en', 'checksum',1,NULL, 'y', 'OS-C', 'OS-C', 'OS-C','y', 1,'2024-07-15T00:00:01Z')
;
INSERT INTO osc_physrisk.osc_physrisk_scenarios.dim_scenario_type
	(scenario_type_id, description_full, description_short, name_fullyqualified, "name", creation_time, creator_user_id, last_modification_time, last_modifier_user_id, is_deleted, deleter_user_id, deletion_time, culture, checksum, seq_num, translated_from_id, is_active, creator_user_name, last_modifier_user_name, deleter_user_name, is_published, publisher_id, published_date)
VALUES 
	(4, 'SSP3-7.0 - high GHG emissions: CO2 emissions double by 2100. See "Shared Socioeconomic Pathways in the IPCC Sixth Assessment Report" (https://www.ipcc.ch/report/sixth-assessment-report-working-group-i/).', 'SSP3-7.0', 'SSP3-7.0', 'SSP3-7.0','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'en', 'checksum',1,NULL, 'y', 'OS-C', 'OS-C', 'OS-C','y', 1,'2024-07-15T00:00:01Z')
;
INSERT INTO osc_physrisk.osc_physrisk_scenarios.dim_scenario_type
	(scenario_type_id, description_full, description_short, name_fullyqualified, "name", creation_time, creator_user_id, last_modification_time, last_modifier_user_id, is_deleted, deleter_user_id, deletion_time, culture, checksum, seq_num, translated_from_id, is_active, creator_user_name, last_modifier_user_name, deleter_user_name, is_published, publisher_id, published_date)
VALUES 
	(5, 'SSP5-8.5 - very high GHG emissions: CO2 emissions triple by 2075. See "Shared Socioeconomic Pathways in the IPCC Sixth Assessment Report" (https://www.ipcc.ch/report/sixth-assessment-report-working-group-i/).', 'SSP5-8.5', 'SSP5-8.5', 'SSP5-8.5','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'en', 'checksum',1,NULL, 'y', 'OS-C', 'OS-C', 'OS-C','y', 1,'2024-07-15T00:00:01Z')
;
INSERT INTO osc_physrisk.osc_physrisk_scenarios.dim_scenario_type
	(scenario_type_id, description_full, description_short, name_fullyqualified, "name", creation_time, creator_user_id, last_modification_time, last_modifier_user_id, is_deleted, deleter_user_id, deletion_time, culture, checksum, seq_num, translated_from_id, is_active, creator_user_name, last_modifier_user_name, deleter_user_name, is_published, publisher_id, published_date)
VALUES 
	(6, 'RCP2.6 - Peak in radiative forcing at ~ 3 W/m2 before 2100 and decline. See "REPRESENTATIVE CONCENTRATION PATHWAYS (RCPs)" (https://sedac.ciesin.columbia.edu/ddc/ar5_scenario_process/RCPs.html)', 'RCP2.6', 'RCP2.6', 'RCP2.6','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'en', 'checksum',1,NULL, 'y', 'OS-C', 'OS-C', 'OS-C','y', 1,'2024-07-15T00:00:01Z')
;
INSERT INTO osc_physrisk.osc_physrisk_scenarios.dim_scenario_type
	(scenario_type_id, description_full, description_short, name_fullyqualified, "name", creation_time, creator_user_id, last_modification_time, last_modifier_user_id, is_deleted, deleter_user_id, deletion_time, culture, checksum, seq_num, translated_from_id, is_active, creator_user_name, last_modifier_user_name, deleter_user_name, is_published, publisher_id, published_date)
VALUES 
	(7, 'RCP4.5 - Stabilization without overshoot pathway to 4.5 W/m2 at stabilization after 2100. See "REPRESENTATIVE CONCENTRATION PATHWAYS (RCPs)" (https://sedac.ciesin.columbia.edu/ddc/ar5_scenario_process/RCPs.html)', 'RCP4.5', 'RCP4.5', 'RCP4.5','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'en', 'checksum',1,NULL, 'y', 'OS-C', 'OS-C', 'OS-C','y', 1,'2024-07-15T00:00:01Z')
;
INSERT INTO osc_physrisk.osc_physrisk_scenarios.dim_scenario_type
	(scenario_type_id, description_full, description_short, name_fullyqualified, "name", creation_time, creator_user_id, last_modification_time, last_modifier_user_id, is_deleted, deleter_user_id, deletion_time, culture, checksum, seq_num, translated_from_id, is_active, creator_user_name, last_modifier_user_name, deleter_user_name, is_published, publisher_id, published_date)
VALUES 
	(8, 'RCP6 - Stabilization without overshoot pathway to 6 W/m2 at stabilization after 2100. See "REPRESENTATIVE CONCENTRATION PATHWAYS (RCPs)" (https://sedac.ciesin.columbia.edu/ddc/ar5_scenario_process/RCPs.html)', 'RCP6', 'RCP6', 'RCP6','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'en', 'checksum',1,NULL, 'y', 'OS-C', 'OS-C', 'OS-C','y', 1,'2024-07-15T00:00:01Z')
;
INSERT INTO osc_physrisk.osc_physrisk_scenarios.dim_scenario_type
	(scenario_type_id, description_full, description_short, name_fullyqualified, "name", creation_time, creator_user_id, last_modification_time, last_modifier_user_id, is_deleted, deleter_user_id, deletion_time, culture, checksum, seq_num, translated_from_id, is_active, creator_user_name, last_modifier_user_name, deleter_user_name, is_published, publisher_id, published_date)
VALUES 
	(9, 'RCP8.5 - Rising radiative forcing pathway leading to 8.5 W/m2 in 2100. See "REPRESENTATIVE CONCENTRATION PATHWAYS (RCPs)" (https://sedac.ciesin.columbia.edu/ddc/ar5_scenario_process/RCPs.html)', 'RCP8.5', 'RCP8.5', 'RCP8.5','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'en', 'checksum',1,NULL, 'y', 'OS-C', 'OS-C', 'OS-C','y', 1,'2024-07-15T00:00:01Z')
;

INSERT INTO osc_physrisk.osc_physrisk_risk_analysis.dim_impact_type
	(impact_type_id, description_full, description_short, name_fullyqualified, "name", creation_time, creator_user_id, last_modification_time, last_modifier_user_id, is_deleted, deleter_user_id, deletion_time, culture, checksum, seq_num, translated_from_id, is_active, creator_user_name, last_modifier_user_name, deleter_user_name, is_published, publisher_id, published_date)
VALUES 
	(1, 'Damage', 'Damage', 'Damage', 'Damage','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'f',NULL,NULL, 'en', 'checksum',1,NULL, 't', 'OS-C', 'OS-C',NULL, 't',1 ,'2024-07-15T00:00:01Z')
;
INSERT INTO osc_physrisk.osc_physrisk_risk_analysis.dim_impact_type
	(impact_type_id, description_full, description_short, name_fullyqualified, "name", creation_time, creator_user_id, last_modification_time, last_modifier_user_id, is_deleted, deleter_user_id, deletion_time, culture, checksum, seq_num, translated_from_id, is_active, creator_user_name, last_modifier_user_name, deleter_user_name, is_published, publisher_id, published_date)
VALUES 
	(2, 'Disruption', 'Disruption', 'Disruption', 'Disruption','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'f',NULL,NULL, 'en', 'checksum',1,NULL, 't', 'OS-C', 'OS-C',NULL, 't',1 ,'2024-07-15T00:00:01Z')
;

-- DATA IN ENGLISH ENDS
-- DATA IN FRENCH STARTS
INSERT INTO osc_physrisk.osc_physrisk_scenarios.dim_scenario_type
	(scenario_type_id, description_full, description_short, name_fullyqualified, "name", creation_time, creator_user_id, last_modification_time, last_modifier_user_id, is_deleted, deleter_user_id, deletion_time, culture, checksum, seq_num, translated_from_id, is_active, creator_user_name, last_modifier_user_name, deleter_user_name, is_published, publisher_id, published_date)
VALUES 
	(10, 'Inconnu/Aucun selection', 'Inconnu/Aucun selection', 'Inconnu/Aucun selection', 'Inconnu/Aucun selection','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'fr', 'checksum',1,-1, 'y', 'OS-C', 'OS-C', 'OS-C','y', 1,'2024-07-15T00:00:01Z')
;
INSERT INTO osc_physrisk.osc_physrisk_scenarios.dim_scenario_type
	(scenario_type_id, description_full, description_short, name_fullyqualified, "name", creation_time, creator_user_id, last_modification_time, last_modifier_user_id, is_deleted, deleter_user_id, deletion_time, culture, checksum, seq_num, translated_from_id, is_active, creator_user_name, last_modifier_user_name, deleter_user_name, is_published, publisher_id, published_date)
VALUES 
	(11, 'Historique (avant 2014). Voir "Scénarios d''émissions et de réchauffement futurs dans le sixième Rapport d''évaluation du GIEC" (https://www.ipcc.ch/report/ar6/wg1/downloads/report/IPCC_AR6_WG1_SPM_French.pdf).', 'Historique (avant 2014)', 'Historique (avant 2014)', 'Historique (avant 2014)','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'fr', 'checksum',1,0, 'y', 'OS-C', 'OS-C', 'OS-C','y', 1,'2024-07-15T00:00:01Z')
;
INSERT INTO osc_physrisk.osc_physrisk_scenarios.dim_scenario_type
	(scenario_type_id, description_full, description_short, name_fullyqualified, "name", creation_time, creator_user_id, last_modification_time, last_modifier_user_id, is_deleted, deleter_user_id, deletion_time, culture, checksum, seq_num, translated_from_id, is_active, creator_user_name, last_modifier_user_name, deleter_user_name, is_published, publisher_id, published_date)
VALUES 
	(12, 'SSP1-1,9 — émissions de GES en baisse dès 2025, zéro émission nette de CO2 avant 2050, émissions négatives ensuite. Voir "Scénarios d''émissions et de réchauffement futurs dans le sixième Rapport d''évaluation du GIEC" (https://www.ipcc.ch/report/ar6/wg1/downloads/report/IPCC_AR6_WG1_SPM_French.pdf).', 'SSP1-1,9', 'SSP1-1,9', 'SSP1-1,9','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'fr', 'checksum',1,1, 'y', 'OS-C', 'OS-C', 'OS-C','y', 1,'2024-07-15T00:00:01Z')
;
INSERT INTO osc_physrisk.osc_physrisk_scenarios.dim_scenario_type
	(scenario_type_id, description_full, description_short, name_fullyqualified, "name", creation_time, creator_user_id, last_modification_time, last_modifier_user_id, is_deleted, deleter_user_id, deletion_time, culture, checksum, seq_num, translated_from_id, is_active, creator_user_name, last_modifier_user_name, deleter_user_name, is_published, publisher_id, published_date)
VALUES 
	(13, 'SSP1-2,6 — similaire au précédent, mais le zéro émission nette de CO2 est atteint après 2050. Voir "Scénarios d''émissions et de réchauffement futurs dans le sixième Rapport d''évaluation du GIEC" (https://www.ipcc.ch/report/ar6/wg1/downloads/report/IPCC_AR6_WG1_SPM_French.pdf).', 'SSP1-2,6', 'SSP1-2,6', 'SSP1-2,6','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'fr', 'checksum',1,2, 'y', 'OS-C', 'OS-C', 'OS-C','y', 1,'2024-07-15T00:00:01Z')
;
INSERT INTO osc_physrisk.osc_physrisk_scenarios.dim_scenario_type
	(scenario_type_id, description_full, description_short, name_fullyqualified, "name", creation_time, creator_user_id, last_modification_time, last_modifier_user_id, is_deleted, deleter_user_id, deletion_time, culture, checksum, seq_num, translated_from_id, is_active, creator_user_name, last_modifier_user_name, deleter_user_name, is_published, publisher_id, published_date)
VALUES 
	(14, 'SSP2-4,5 — maintien des émissions courantes jusqu''en 2050, division par quatre d''ici 2100. Voir "Scénarios d''émissions et de réchauffement futurs dans le sixième Rapport d''évaluation du GIEC" (https://www.ipcc.ch/report/ar6/wg1/downloads/report/IPCC_AR6_WG1_SPM_French.pdf).', 'SSP2-4,5', 'SSP2-4,5', 'SSP2-4,5','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'fr', 'checksum',1,3, 'y', 'OS-C', 'OS-C', 'OS-C','y', 1,'2024-07-15T00:00:01Z')
;
INSERT INTO osc_physrisk.osc_physrisk_scenarios.dim_scenario_type
	(scenario_type_id, description_full, description_short, name_fullyqualified, "name", creation_time, creator_user_id, last_modification_time, last_modifier_user_id, is_deleted, deleter_user_id, deletion_time, culture, checksum, seq_num, translated_from_id, is_active, creator_user_name, last_modifier_user_name, deleter_user_name, is_published, publisher_id, published_date)
VALUES 
	(15, 'SSP3-7,0 — doublement des émissions de GES en 2100. Voir "Scénarios d''émissions et de réchauffement futurs dans le sixième Rapport d''évaluation du GIEC" (https://www.ipcc.ch/report/ar6/wg1/downloads/report/IPCC_AR6_WG1_SPM_French.pdf).', 'SSP3-7,0', 'SSP3-7,0', 'SSP3-7,0','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'fr', 'checksum',1,4, 'y', 'OS-C', 'OS-C', 'OS-C','y', 1,'2024-07-15T00:00:01Z')
;
INSERT INTO osc_physrisk.osc_physrisk_scenarios.dim_scenario_type
	(scenario_type_id, description_full, description_short, name_fullyqualified, "name", creation_time, creator_user_id, last_modification_time, last_modifier_user_id, is_deleted, deleter_user_id, deletion_time, culture, checksum, seq_num, translated_from_id, is_active, creator_user_name, last_modifier_user_name, deleter_user_name, is_published, publisher_id, published_date)
VALUES 
	(16, 'SSP5-8,5 — émissions de GES en forte augmentation, doublement en 2050. Voir "Scénarios d''émissions et de réchauffement futurs dans le sixième Rapport d''évaluation du GIEC" (https://www.ipcc.ch/report/ar6/wg1/downloads/report/IPCC_AR6_WG1_SPM_French.pdf).', 'SSP5-8,5', 'SSP5-8,5', 'SSP5-8,5','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'fr', 'checksum',1,5, 'y', 'OS-C', 'OS-C', 'OS-C','y', 1,'2024-07-15T00:00:01Z')
;
INSERT INTO osc_physrisk.osc_physrisk_scenarios.dim_scenario_type
	(scenario_type_id, description_full, description_short, name_fullyqualified, "name", creation_time, creator_user_id, last_modification_time, last_modifier_user_id, is_deleted, deleter_user_id, deletion_time, culture, checksum, seq_num, translated_from_id, is_active, creator_user_name, last_modifier_user_name, deleter_user_name, is_published, publisher_id, published_date)
VALUES 
	(17, 'RCP2.6 - le scénario d''émissions faibles, nous présente un futur où nous limitons les changements climatiques d''origine humaine. Le maximum des émissions de carbone est atteint rapidement, suivi d''une réduction qui mène vers une valeur presque nulle bien avant la fin du siècle. Voir « Scénarios d''émissions : les RCP » (https://donneesclimatiques.ca/interactive/scenarios-demissions-les-rcp/)', 'RCP2.6', 'RCP2.6', 'RCP2.6','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'fr', 'checksum',1,6, 'y', 'OS-C', 'OS-C', 'OS-C','y', 1,'2024-07-15T00:00:01Z')
;
INSERT INTO osc_physrisk.osc_physrisk_scenarios.dim_scenario_type
	(scenario_type_id, description_full, description_short, name_fullyqualified, "name", creation_time, creator_user_id, last_modification_time, last_modifier_user_id, is_deleted, deleter_user_id, deletion_time, culture, checksum, seq_num, translated_from_id, is_active, creator_user_name, last_modifier_user_name, deleter_user_name, is_published, publisher_id, published_date)
VALUES 
	(18, 'RCP4.5 - un scénario d''émissions modérées, nous présente un futur où nous incluons des mesures pour limiter les changements climatiques d''origine humaine. Ce scénario exige que les émissions mondiales de carbone soient stabilisées d''ici la fin du siècle. Voir « Scénarios d''émissions : les RCP » (https://donneesclimatiques.ca/interactive/scenarios-demissions-les-rcp/)', 'RCP4.5', 'RCP4.5', 'RCP4.5','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'fr', 'checksum',1,7, 'y', 'OS-C', 'OS-C', 'OS-C','y', 1,'2024-07-15T00:00:01Z')
;
INSERT INTO osc_physrisk.osc_physrisk_scenarios.dim_scenario_type
	(scenario_type_id, description_full, description_short, name_fullyqualified, "name", creation_time, creator_user_id, last_modification_time, last_modifier_user_id, is_deleted, deleter_user_id, deletion_time, culture, checksum, seq_num, translated_from_id, is_active, creator_user_name, last_modifier_user_name, deleter_user_name, is_published, publisher_id, published_date)
VALUES 
	(19, 'RCP6 -  Voir « Scénarios d''émissions : les RCP » (https://donneesclimatiques.ca/interactive/scenarios-demissions-les-rcp/)', 'RCP6', 'RCP6', 'RCP6','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'fr', 'checksum',1,8, 'y', 'OS-C', 'OS-C', 'OS-C','y', 1,'2024-07-15T00:00:01Z')
;
INSERT INTO osc_physrisk.osc_physrisk_scenarios.dim_scenario_type
	(scenario_type_id, description_full, description_short, name_fullyqualified, "name", creation_time, creator_user_id, last_modification_time, last_modifier_user_id, is_deleted, deleter_user_id, deletion_time, culture, checksum, seq_num, translated_from_id, is_active, creator_user_name, last_modifier_user_name, deleter_user_name, is_published, publisher_id, published_date)
VALUES 
	(20, 'RCP8.5 - le scénario d''émissions élevées, nous présente un futur où peu de restrictions aux émissions ont été mises en place. Les émissions continuent d''augmenter rapidement au cours de ce siècle, et se stabilisent seulement après 2250. Voir « Scénarios d''émissions : les RCP » (https://donneesclimatiques.ca/interactive/scenarios-demissions-les-rcp/)', 'RCP8.5', 'RCP8.5', 'RCP8.5','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'fr', 'checksum',1,9, 'y', 'OS-C', 'OS-C', 'OS-C','y', 1,'2024-07-15T00:00:01Z')
;
-- DATA IN FRENCH ENDS
-- DATA IN SPANISH BEGINS
INSERT INTO osc_physrisk.osc_physrisk_scenarios.dim_scenario_type
	(scenario_type_id, description_full, description_short, name_fullyqualified, "name", creation_time, creator_user_id, last_modification_time, last_modifier_user_id, is_deleted, deleter_user_id, deletion_time, culture, checksum, seq_num, translated_from_id, is_active, creator_user_name, last_modifier_user_name, deleter_user_name, is_published, publisher_id, published_date)
VALUES 
	(21, 'Desconocido/no seleccionado', 'Desconocido/no seleccionado', 'Desconocido/no seleccionado', 'Desconocido/no seleccionado','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'es', 'checksum',1,-1, 'y', 'OS-C', 'OS-C', 'OS-C','y', 1,'2024-07-15T00:00:01Z')
;
INSERT INTO osc_physrisk.osc_physrisk_scenarios.dim_scenario_type
	(scenario_type_id, description_full, description_short, name_fullyqualified, "name", creation_time, creator_user_id, last_modification_time, last_modifier_user_id, is_deleted, deleter_user_id, deletion_time, culture, checksum, seq_num, translated_from_id, is_active, creator_user_name, last_modifier_user_name, deleter_user_name, is_published, publisher_id, published_date)
VALUES 
	(22, 'Histórico (antes 2014). Ver "El Grupo Intergubernamental de Expertos sobre el Cambio Climático (IPCC)" (https://www.ipcc.ch/languages-2/spanish/).', 'Histórico (antes 2014)', 'Histórico (antes 2014)', 'Histórico (antes 2014)','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'es', 'checksum',1,0, 'y', 'OS-C', 'OS-C', 'OS-C','y', 1,'2024-07-15T00:00:01Z')
;
INSERT INTO osc_physrisk.osc_physrisk_scenarios.dim_scenario_type
	(scenario_type_id, description_full, description_short, name_fullyqualified, "name", creation_time, creator_user_id, last_modification_time, last_modifier_user_id, is_deleted, deleter_user_id, deletion_time, culture, checksum, seq_num, translated_from_id, is_active, creator_user_name, last_modifier_user_name, deleter_user_name, is_published, publisher_id, published_date)
VALUES 
	(23, 'SSP1-1.9 — Las trayectorias socioeconómicas compartidas (SSP, por sus siglas en inglés) son escenarios de cambios socioeconómicos globales proyectados hasta 2100. Ver "El Grupo Intergubernamental de Expertos sobre el Cambio Climático (IPCC)" (https://www.ipcc.ch/languages-2/spanish/).', 'SSP1-1,9', 'SSP1-1,9', 'SSP1-1,9','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'es', 'checksum',1,1, 'y', 'OS-C', 'OS-C', 'OS-C','y', 1,'2024-07-15T00:00:01Z')
;
INSERT INTO osc_physrisk.osc_physrisk_scenarios.dim_scenario_type
	(scenario_type_id, description_full, description_short, name_fullyqualified, "name", creation_time, creator_user_id, last_modification_time, last_modifier_user_id, is_deleted, deleter_user_id, deletion_time, culture, checksum, seq_num, translated_from_id, is_active, creator_user_name, last_modifier_user_name, deleter_user_name, is_published, publisher_id, published_date)
VALUES 
	(24, 'SSP1-2.6 - Las trayectorias socioeconómicas compartidas (SSP, por sus siglas en inglés) son escenarios de cambios socioeconómicos globales proyectados hasta 2100. Ver "El Grupo Intergubernamental de Expertos sobre el Cambio Climático (IPCC)" (https://www.ipcc.ch/languages-2/spanish/).', 'SSP1-2.6', 'SSP1-2.6', 'SSP1-2.6','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'es', 'checksum',1,2, 'y', 'OS-C', 'OS-C', 'OS-C','y', 1,'2024-07-15T00:00:01Z')
;
INSERT INTO osc_physrisk.osc_physrisk_scenarios.dim_scenario_type
	(scenario_type_id, description_full, description_short, name_fullyqualified, "name", creation_time, creator_user_id, last_modification_time, last_modifier_user_id, is_deleted, deleter_user_id, deletion_time, culture, checksum, seq_num, translated_from_id, is_active, creator_user_name, last_modifier_user_name, deleter_user_name, is_published, publisher_id, published_date)
VALUES 
	(25, 'SSP2-4.5 Las trayectorias socioeconómicas compartidas (SSP, por sus siglas en inglés) son escenarios de cambios socioeconómicos globales proyectados hasta 2100. Ver "El Grupo Intergubernamental de Expertos sobre el Cambio Climático (IPCC)" (https://www.ipcc.ch/languages-2/spanish/).', 'SSP2-4.5', 'SSP2-4.5', 'SSP2-4.5','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'es', 'checksum',1,3, 'y', 'OS-C', 'OS-C', 'OS-C','y', 1,'2024-07-15T00:00:01Z')
;
INSERT INTO osc_physrisk.osc_physrisk_scenarios.dim_scenario_type
	(scenario_type_id, description_full, description_short, name_fullyqualified, "name", creation_time, creator_user_id, last_modification_time, last_modifier_user_id, is_deleted, deleter_user_id, deletion_time, culture, checksum, seq_num, translated_from_id, is_active, creator_user_name, last_modifier_user_name, deleter_user_name, is_published, publisher_id, published_date)
VALUES 
	(26, 'SSP3-7.0 - Las trayectorias socioeconómicas compartidas (SSP, por sus siglas en inglés) son escenarios de cambios socioeconómicos globales proyectados hasta 2100. Ver "El Grupo Intergubernamental de Expertos sobre el Cambio Climático (IPCC)" (https://www.ipcc.ch/languages-2/spanish/).', 'SSP3-7.0', 'SSP3-7.0', 'SSP3-7.0','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'es', 'checksum',1,4, 'y', 'OS-C', 'OS-C', 'OS-C','y', 1,'2024-07-15T00:00:01Z')
;
INSERT INTO osc_physrisk.osc_physrisk_scenarios.dim_scenario_type
	(scenario_type_id, description_full, description_short, name_fullyqualified, "name", creation_time, creator_user_id, last_modification_time, last_modifier_user_id, is_deleted, deleter_user_id, deletion_time, culture, checksum, seq_num, translated_from_id, is_active, creator_user_name, last_modifier_user_name, deleter_user_name, is_published, publisher_id, published_date)
VALUES 
	(27, 'SSP5-8.5 - Las trayectorias socioeconómicas compartidas (SSP, por sus siglas en inglés) son escenarios de cambios socioeconómicos globales proyectados hasta 2100. Ver "El Grupo Intergubernamental de Expertos sobre el Cambio Climático (IPCC)" (https://www.ipcc.ch/languages-2/spanish/).', 'SSP5-8.5', 'SSP5-8.5', 'SSP5-8.5','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'es', 'checksum',1,5, 'y', 'OS-C', 'OS-C', 'OS-C','y', 1,'2024-07-15T00:00:01Z')
;
INSERT INTO osc_physrisk.osc_physrisk_scenarios.dim_scenario_type
	(scenario_type_id, description_full, description_short, name_fullyqualified, "name", creation_time, creator_user_id, last_modification_time, last_modifier_user_id, is_deleted, deleter_user_id, deletion_time, culture, checksum, seq_num, translated_from_id, is_active, creator_user_name, last_modifier_user_name, deleter_user_name, is_published, publisher_id, published_date)
VALUES 
	(28, 'RCP2.6 Una trayectoria de concentración representativa (RCP, por sus siglas en inglés) es una proyección teórica de una trayectoria de concentración de gases de efecto invernadero (no emisiones) adoptada por el IPCC. Ver "El Grupo Intergubernamental de Expertos sobre el Cambio Climático (IPCC)" (https://www.ipcc.ch/languages-2/spanish/).', 'RCP2.6', 'RCP2.6', 'RCP2.6','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'es', 'checksum',1,6, 'y', 'OS-C', 'OS-C', 'OS-C','y', 1,'2024-07-15T00:00:01Z')
;
INSERT INTO osc_physrisk.osc_physrisk_scenarios.dim_scenario_type
	(scenario_type_id, description_full, description_short, name_fullyqualified, "name", creation_time, creator_user_id, last_modification_time, last_modifier_user_id, is_deleted, deleter_user_id, deletion_time, culture, checksum, seq_num, translated_from_id, is_active, creator_user_name, last_modifier_user_name, deleter_user_name, is_published, publisher_id, published_date)
VALUES 
	(29, 'RCP4.5 - Una trayectoria de concentración representativa (RCP, por sus siglas en inglés) es una proyección teórica de una trayectoria de concentración de gases de efecto invernadero (no emisiones) adoptada por el IPCC. Ver "El Grupo Intergubernamental de Expertos sobre el Cambio Climático (IPCC)" (https://www.ipcc.ch/languages-2/spanish/).', 'RCP4.5', 'RCP4.5', 'RCP4.5','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'es', 'checksum',1,7, 'y', 'OS-C', 'OS-C', 'OS-C','y', 1,'2024-07-15T00:00:01Z')
;
INSERT INTO osc_physrisk.osc_physrisk_scenarios.dim_scenario_type
	(scenario_type_id, description_full, description_short, name_fullyqualified, "name", creation_time, creator_user_id, last_modification_time, last_modifier_user_id, is_deleted, deleter_user_id, deletion_time, culture, checksum, seq_num, translated_from_id, is_active, creator_user_name, last_modifier_user_name, deleter_user_name, is_published, publisher_id, published_date)
VALUES 
	(30, 'RCP6 - Una trayectoria de concentración representativa (RCP, por sus siglas en inglés) es una proyección teórica de una trayectoria de concentración de gases de efecto invernadero (no emisiones) adoptada por el IPCC. Ver "El Grupo Intergubernamental de Expertos sobre el Cambio Climático (IPCC)" (https://www.ipcc.ch/languages-2/spanish/).', 'RCP6', 'RCP6', 'RCP6','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'es', 'checksum',1,8, 'y', 'OS-C', 'OS-C', 'OS-C','y', 1,'2024-07-15T00:00:01Z')
;
INSERT INTO osc_physrisk.osc_physrisk_scenarios.dim_scenario_type
	(scenario_type_id, description_full, description_short, name_fullyqualified, "name", creation_time, creator_user_id, last_modification_time, last_modifier_user_id, is_deleted, deleter_user_id, deletion_time, culture, checksum, seq_num, translated_from_id, is_active, creator_user_name, last_modifier_user_name, deleter_user_name, is_published, publisher_id, published_date)
VALUES 
	(31, 'RCP8.5 - Una trayectoria de concentración representativa (RCP, por sus siglas en inglés) es una proyección teórica de una trayectoria de concentración de gases de efecto invernadero (no emisiones) adoptada por el IPCC. Ver "El Grupo Intergubernamental de Expertos sobre el Cambio Climático (IPCC)" (https://www.ipcc.ch/languages-2/spanish/).', 'RCP8.5', 'RCP8.5', 'RCP8.5','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'es', 'checksum',1,9, 'y', 'OS-C', 'OS-C', 'OS-C','y', 1,'2024-07-15T00:00:01Z')
;



-- DATA IN SPANISH ENDS


-- EXAMPLE QUERIES
-- VIEW SCENARIOS IN DIFFERENT LANGUAGES
SELECT * FROM osc_physrisk.osc_physrisk_scenarios.dim_scenario_type WHERE culture='en';
SELECT * FROM osc_physrisk.osc_physrisk_scenarios.dim_scenario_type WHERE culture='fr';
SELECT * FROM osc_physrisk.osc_physrisk_scenarios.dim_scenario_type WHERE culture='es';

SELECT a."name" as "English Name",  b.culture as "Translated Culture",  b."name" as "Translated Name", b.description_full as "Translated Description" FROM osc_physrisk.osc_physrisk_scenarios.dim_scenario_type a 
INNER JOIN osc_physrisk.osc_physrisk_scenarios.dim_scenario_type b ON a.scenario_type_id = b.translated_from_id
WHERE b.culture='es'  ;

-- SAMPLE CHECKSUM UPDATE
--UPDATE osc_physrisk.osc_physrisk_scenarios.dim_scenario_type
--	SET checksum = md5(concat('Unknown/Not Selected', 'Unknown/Not Selected', 'Unknown/Not Selected', 'Unknown/Not Selected')) WHERE scenario_type_id = -1
--;