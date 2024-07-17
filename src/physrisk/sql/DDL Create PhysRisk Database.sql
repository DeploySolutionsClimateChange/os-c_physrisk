-- SETUP EXTENSIONS
CREATE EXTENSION postgis; -- used for geolocation
CREATE EXTENSION h3; -- used for Uber H3 geolocation
CREATE EXTENSION pgcrypto; -- used for random UUID generation
CREATE EXTENSION hstore; -- used for metadata

-- SETUP SCHEMAS
CREATE SCHEMA IF NOT EXISTS osc_physrisk_scenario;
CREATE SCHEMA IF NOT EXISTS osc_physrisk_hazard;
CREATE SCHEMA IF NOT EXISTS osc_physrisk_vulnerability;
CREATE SCHEMA IF NOT EXISTS osc_physrisk_exposure;
CREATE SCHEMA IF NOT EXISTS osc_physrisk_asset;
CREATE SCHEMA IF NOT EXISTS osc_physrisk_risk_analysis;

-- SETUP TABLES
-- SCHEMA osc_physrisk_hazard
CREATE TABLE osc_physrisk_hazard.hazard ( 
	hazard_id	UUID  DEFAULT gen_random_uuid ()  NOT NULL,
	name        varchar(100)  NOT NULL  ,
	name_fullyqualified varchar(256)    ,
	description_full   varchar(8096)    ,
	description_short  varchar(256)  NOT NULL  ,
    tags hstore,
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
	translated_from_id   UUID ,
	is_active       boolean  NOT NULL  ,
	creator_user_name   varchar(256)    ,
	last_modifier_user_name varchar(256)    ,
	deleter_user_name   varchar(256)    ,
	tenant_id        integer  NOT NULL  ,
	tenant_name        text  NOT NULL  ,
	is_published       boolean  NOT NULL  ,
	publisher_id        bigint    ,
	published_date      timestamptz    ,
	oed_peril_code integer,
	oed_input_abbreviation      varchar(5) ,
	oed_grouped_peril_code boolean,
	CONSTRAINT pk_hazard PRIMARY KEY ( hazard_id )
 );

CREATE TABLE osc_physrisk_hazard.hazard_indicator ( 
	hazard_indicator_id	UUID  DEFAULT gen_random_uuid () NOT NULL,
	name        varchar(100)  NOT NULL  ,
	name_fullyqualified varchar(256)    ,
	description_full   varchar(8096)    ,
	description_short  varchar(256)  NOT NULL  ,
    tags hstore,
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
	translated_from_id   UUID ,
	is_active       boolean  NOT NULL  ,
	creator_user_name   varchar(256)    ,
	last_modifier_user_name varchar(256)    ,
	deleter_user_name   varchar(256)    ,
	tenant_id        integer  NOT NULL  ,
	tenant_name        text  NOT NULL  ,
	is_published       boolean  NOT NULL  ,
	publisher_id        bigint    ,
	published_date      timestamptz    ,
	hazard_id	UUID  NOT NULL,
	CONSTRAINT pk_hazard_indicator PRIMARY KEY ( hazard_indicator_id ),
	CONSTRAINT fk_hazard_indicator_hazard_id FOREIGN KEY ( hazard_id ) REFERENCES osc_physrisk_hazard.hazard(hazard_id)
 );

-- SCHEMA osc_physrisk_vulnerability
CREATE TABLE osc_physrisk_vulnerability.vulnerability_function ( 
	vulnerability_function_id	UUID  DEFAULT gen_random_uuid () NOT NULL,
	name        varchar(100)  NOT NULL  ,
	name_fullyqualified varchar(256)    ,
	description_full   varchar(8096)    ,
	description_short  varchar(256)  NOT NULL  ,
    tags hstore,
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
	translated_from_id   UUID,
	is_active       boolean  NOT NULL  ,
	creator_user_name   varchar(256)    ,
	last_modifier_user_name varchar(256)    ,
	deleter_user_name   varchar(256)    ,
	tenant_id        integer  NOT NULL  ,
	tenant_name        text  NOT NULL  ,
	is_published       boolean  NOT NULL  ,
	publisher_id        bigint    ,
	published_date      timestamptz    ,
	CONSTRAINT pk_vulnerability_function PRIMARY KEY ( vulnerability_function_id )
 );

CREATE TABLE osc_physrisk_vulnerability.damage_function ( 
	damage_function_id	UUID  DEFAULT gen_random_uuid () NOT NULL,
	name        varchar(100)  NOT NULL  ,
	name_fullyqualified varchar(256)    ,
	description_full   varchar(8096)    ,
	description_short  varchar(256)  NOT NULL  ,
    tags hstore,
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
	translated_from_id   UUID,
	is_active       boolean  NOT NULL  ,
	creator_user_name   varchar(256)    ,
	last_modifier_user_name varchar(256)    ,
	deleter_user_name   varchar(256)    ,
	tenant_id        integer  NOT NULL  ,
	tenant_name        text  NOT NULL  ,
	is_published       boolean  NOT NULL  ,
	publisher_id        bigint    ,
	published_date      timestamptz    ,
	CONSTRAINT pk_damage_function PRIMARY KEY ( damage_function_id )
 );

-- SCHEMA osc_physrisk_scenario
CREATE TABLE osc_physrisk_scenario.dim_scenario_type ( 
	scenario_type_id integer  NOT NULL,
	name        varchar(100)  NOT NULL  ,
	name_fullyqualified varchar(256)    ,
	description_full   varchar(8096)    ,
	description_short  varchar(256)  NOT NULL  ,
    tags hstore,
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
	translated_from_id   integer,
	is_active           boolean  NOT NULL  ,
	creator_user_name    varchar(256)    ,
	last_modifier_user_name varchar(256)    ,
	deleter_user_name    varchar(256)    ,
	is_published        boolean  NOT NULL  ,
	publisher_id        bigint    ,
	published_date      timestamptz,
	CONSTRAINT pk_dim_scenario_type PRIMARY KEY ( scenario_type_id )
 ); 

-- SCHEMA osc_physrisk_asset
CREATE TABLE osc_physrisk_asset.fact_portfolio ( 
	portfolio_id                UUID  DEFAULT gen_random_uuid () NOT NULL,
	name        varchar(100)  NOT NULL  ,
	name_fullyqualified varchar(256)    ,
	description_full   varchar(8096)    ,
	description_short  varchar(256)  NOT NULL  ,
    tags hstore,
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
	translated_from_id   UUID,
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

CREATE TABLE osc_physrisk_asset.fact_asset ( 
	asset_id                UUID  DEFAULT gen_random_uuid () NOT NULL,
	name        varchar(100)  NOT NULL  ,
	name_fullyqualified varchar(256)    ,
	description_full   varchar(8096)    ,
	description_short  varchar(256)  NOT NULL  ,
    tags hstore,
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
	CONSTRAINT fk_fact_asset_portfolio_id FOREIGN KEY ( portfolio_id ) REFERENCES osc_physrisk_asset.fact_portfolio(portfolio_id),
    CONSTRAINT ck_fact_asset_h3_resolution CHECK (h3_resolution >= 0 AND h3_resolution <= 15)
 );

-- SCHEMA osc_physrisk_risk_analysis
CREATE TABLE osc_physrisk_risk_analysis.dim_impact_type ( 
	impact_type_id integer NOT NULL,
	name        varchar(100)  NOT NULL  ,
	name_fullyqualified varchar(256)    ,
	description_full   varchar(8096)    ,
	description_short  varchar(256)  NOT NULL  ,
    tags hstore,
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
	translated_from_id   integer,
	is_active           boolean  NOT NULL  ,
	creator_user_name    varchar(256)    ,
	last_modifier_user_name varchar(256)    ,
	deleter_user_name    varchar(256)    ,
	is_published        boolean  NOT NULL  ,
	publisher_id        bigint    ,
	published_date      timestamptz  ,
    accounting_category varchar(256),
	CONSTRAINT pk_dim_impact_type PRIMARY KEY ( impact_type_id )
 ); 

CREATE TABLE osc_physrisk_risk_analysis.fact_portfolio_impact ( 
	portfolio_analysis_id UUID  DEFAULT gen_random_uuid () NOT NULL,
	name        varchar(100)  NOT NULL  ,
	name_fullyqualified varchar(256)    ,
	description_full   varchar(8096)    ,
	description_short  varchar(256)  NOT NULL  ,
    tags hstore,
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
	hazard_id	UUID NOT NULL,
    impact_type_id integer NOT NULL,
    value_at_risk decimal,
	annual_exceedence_probability decimal,
	average_annual_loss decimal,
    currency_alphabetic_code char(3),
	CONSTRAINT pk_fact_portfolio_analysis PRIMARY KEY ( portfolio_analysis_id ),
	CONSTRAINT fk_fact_portfolio_analysis_portfolio_id FOREIGN KEY ( portfolio_id ) REFERENCES osc_physrisk_asset.fact_portfolio(portfolio_id),
	CONSTRAINT fk_fact_portfolio_analysis_scenario_type_id FOREIGN KEY ( scenario_type_id ) REFERENCES osc_physrisk_scenario.dim_scenario_type(scenario_type_id),
	CONSTRAINT fk_fact_portfolio_analysis_impact_type_id FOREIGN KEY ( impact_type_id ) REFERENCES osc_physrisk_risk_analysis.dim_impact_type(impact_type_id),
	CONSTRAINT fk_fact_portfolio_analysis_hazard_id FOREIGN KEY ( hazard_id ) REFERENCES osc_physrisk_hazard.hazard(hazard_id)     
 );

CREATE TABLE osc_physrisk_risk_analysis.fact_asset_impact ( 
	asset_analysis_id UUID  DEFAULT gen_random_uuid () NOT NULL,
	name        varchar(100)  NOT NULL  ,
	name_fullyqualified varchar(256)    ,
	description_full   varchar(8096)    ,
	description_short  varchar(256)  NOT NULL  ,
    tags hstore,
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
	hazard_id	UUID NOT NULL,
    hazard_intensity decimal,
    impact_type_id integer NOT NULL,
    value_at_risk decimal,
    currency_alphabetic_code char(3),
    return_periods jsonb,
    parameter    decimal,
    impact_mean    decimal,
    impact_distr_bin_edges    decimal[],
    impact_distr_p    decimal[],
    impact_exc_exceed_p    decimal[],
    impact_exc_values    decimal[],
	probability decimal,
	CONSTRAINT pk_fact_asset_analysis PRIMARY KEY ( asset_analysis_id ),
    CONSTRAINT ck_fact_asset_analysis_h3_resolution CHECK (h3_resolution >= 0 AND h3_resolution <= 15),
	CONSTRAINT fk_fact_asset_analysis_asset_id FOREIGN KEY ( asset_id ) REFERENCES osc_physrisk_asset.fact_asset(asset_id),
	CONSTRAINT fk_fact_asset_analysis_scenario_type_id FOREIGN KEY ( scenario_type_id ) REFERENCES osc_physrisk_scenario.dim_scenario_type(scenario_type_id),
	CONSTRAINT fk_fact_asset_analysis_impact_type_id FOREIGN KEY ( impact_type_id ) REFERENCES osc_physrisk_risk_analysis.dim_impact_type(impact_type_id),
	CONSTRAINT fk_fact_asset_analysis_hazard_id FOREIGN KEY ( hazard_id ) REFERENCES osc_physrisk_hazard.hazard(hazard_id)     
 );

-- SETUP PERMISSIONS
--GRANT USAGE ON SCHEMA "osc.physrisk.data_example.comp_domain" TO physrisk_service;
--GRANT SELECT ON ALL TABLES IN SCHEMA "osc.physrisk.data_example.comp_domain" TO physrisk_service;
--GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA "osc.physrisk.data_example.comp_domain" TO physrisk_service;
--GRANT ALL ON ALL TABLES IN SCHEMA "osc.physrisk.data_example.comp_domain" TO physrisk_service;

-- DATA IN ENGLISH STARTS
INSERT INTO osc_physrisk.osc_physrisk_scenario.dim_scenario_type
	(scenario_type_id, description_full, description_short, name_fullyqualified, "name", tags, creation_time, creator_user_id, last_modification_time, last_modifier_user_id, is_deleted, deleter_user_id, deletion_time, culture, checksum, seq_num, translated_from_id, is_active, creator_user_name, last_modifier_user_name, deleter_user_name, is_published, publisher_id, published_date)
VALUES 
	(-1, 'Unknown/Not Selected', 'Unknown/Not Selected', 'Unknown/Not Selected', 'Unknown/Not Selected','key1=>value1_en,key2=>value2_en', '2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'en', 'f098938cd8cc7c4f1c71c8e97db0f075',1,-1, 'y', 'OS-C', 'OS-C', 'OS-C','y', 1,'2024-07-15T00:00:01Z')
;
INSERT INTO osc_physrisk.osc_physrisk_scenario.dim_scenario_type
	(scenario_type_id, description_full, description_short, name_fullyqualified, "name",tags,  creation_time, creator_user_id, last_modification_time, last_modifier_user_id, is_deleted, deleter_user_id, deletion_time, culture, checksum, seq_num, translated_from_id, is_active, creator_user_name, last_modifier_user_name, deleter_user_name, is_published, publisher_id, published_date)
VALUES 
	(0, 'History (before 2014). See "Shared Socioeconomic Pathways in the IPCC Sixth Assessment Report" (https://www.ipcc.ch/report/sixth-assessment-report-working-group-i/).', 'History (before 2014)', 'History (- 2014)', 'History (- 2014)','key1=>value3_en,key2=>value4_en','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'en', 'checksum',1,0, 'y', 'OS-C', 'OS-C', 'OS-C','y', 1,'2024-07-15T00:00:01Z')
;
INSERT INTO osc_physrisk.osc_physrisk_scenario.dim_scenario_type
	(scenario_type_id, description_full, description_short, name_fullyqualified, "name", tags, creation_time, creator_user_id, last_modification_time, last_modifier_user_id, is_deleted, deleter_user_id, deletion_time, culture, checksum, seq_num, translated_from_id, is_active, creator_user_name, last_modifier_user_name, deleter_user_name, is_published, publisher_id, published_date)
VALUES 
	(1, 'SSP1-1.9 -  very low GHG emissions: CO2 emissions cut to net zero around 2050. See "Shared Socioeconomic Pathways in the IPCC Sixth Assessment Report" (https://www.ipcc.ch/report/sixth-assessment-report-working-group-i/).', 'SSP1-1.9', 'SSP1-1.9', 'SSP1-1.9','key1=>value1_en,key2=>value2_en','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'en', 'checksum',1,1, 'y', 'OS-C', 'OS-C', 'OS-C','y', 1,'2024-07-15T00:00:01Z')
;
INSERT INTO osc_physrisk.osc_physrisk_scenario.dim_scenario_type
	(scenario_type_id, description_full, description_short, name_fullyqualified, "name",tags,  creation_time, creator_user_id, last_modification_time, last_modifier_user_id, is_deleted, deleter_user_id, deletion_time, culture, checksum, seq_num, translated_from_id, is_active, creator_user_name, last_modifier_user_name, deleter_user_name, is_published, publisher_id, published_date)
VALUES 
	(2, 'SSP1-2.6 - low GHG emissions: CO2 emissions cut to net zero around 2075. See "Shared Socioeconomic Pathways in the IPCC Sixth Assessment Report" (https://www.ipcc.ch/report/sixth-assessment-report-working-group-i/).', 'SSP1-2.6', 'SSP1-2.6', 'SSP1-2.6','key1=>value3_en,key2=>value4_en','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'en', 'checksum',1,2, 'y', 'OS-C', 'OS-C', 'OS-C','y', 1,'2024-07-15T00:00:01Z')
;
INSERT INTO osc_physrisk.osc_physrisk_scenario.dim_scenario_type
	(scenario_type_id, description_full, description_short, name_fullyqualified, "name", tags, creation_time, creator_user_id, last_modification_time, last_modifier_user_id, is_deleted, deleter_user_id, deletion_time, culture, checksum, seq_num, translated_from_id, is_active, creator_user_name, last_modifier_user_name, deleter_user_name, is_published, publisher_id, published_date)
VALUES 
	(3, 'SSP2-4.5 - intermediate GHG emissions: CO2 emissions around current levels until 2050, then falling but not reaching net zero by 2100. See "Shared Socioeconomic Pathways in the IPCC Sixth Assessment Report" (https://www.ipcc.ch/report/sixth-assessment-report-working-group-i/).', 'SSP2-4.5', 'SSP2-4.5', 'SSP2-4.5','key1=>value1_en,key2=>value2_en','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'en', 'checksum',1,3, 'y', 'OS-C', 'OS-C', 'OS-C','y', 1,'2024-07-15T00:00:01Z')
;
INSERT INTO osc_physrisk.osc_physrisk_scenario.dim_scenario_type
	(scenario_type_id, description_full, description_short, name_fullyqualified, "name", tags, creation_time, creator_user_id, last_modification_time, last_modifier_user_id, is_deleted, deleter_user_id, deletion_time, culture, checksum, seq_num, translated_from_id, is_active, creator_user_name, last_modifier_user_name, deleter_user_name, is_published, publisher_id, published_date)
VALUES 
	(4, 'SSP3-7.0 - high GHG emissions: CO2 emissions double by 2100. See "Shared Socioeconomic Pathways in the IPCC Sixth Assessment Report" (https://www.ipcc.ch/report/sixth-assessment-report-working-group-i/).', 'SSP3-7.0', 'SSP3-7.0', 'SSP3-7.0','key1=>value1_en,key2=>value2_en','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'en', 'checksum',1,4, 'y', 'OS-C', 'OS-C', 'OS-C','y', 1,'2024-07-15T00:00:01Z')
;
INSERT INTO osc_physrisk.osc_physrisk_scenario.dim_scenario_type
	(scenario_type_id, description_full, description_short, name_fullyqualified, "name", tags, creation_time, creator_user_id, last_modification_time, last_modifier_user_id, is_deleted, deleter_user_id, deletion_time, culture, checksum, seq_num, translated_from_id, is_active, creator_user_name, last_modifier_user_name, deleter_user_name, is_published, publisher_id, published_date)
VALUES 
	(5, 'SSP5-8.5 - very high GHG emissions: CO2 emissions triple by 2075. See "Shared Socioeconomic Pathways in the IPCC Sixth Assessment Report" (https://www.ipcc.ch/report/sixth-assessment-report-working-group-i/).', 'SSP5-8.5', 'SSP5-8.5', 'SSP5-8.5','key1=>value5_en,key2=>value6_en','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'en', 'checksum',1,5, 'y', 'OS-C', 'OS-C', 'OS-C','y', 1,'2024-07-15T00:00:01Z')
;
INSERT INTO osc_physrisk.osc_physrisk_scenario.dim_scenario_type
	(scenario_type_id, description_full, description_short, name_fullyqualified, "name", tags, creation_time, creator_user_id, last_modification_time, last_modifier_user_id, is_deleted, deleter_user_id, deletion_time, culture, checksum, seq_num, translated_from_id, is_active, creator_user_name, last_modifier_user_name, deleter_user_name, is_published, publisher_id, published_date)
VALUES 
	(6, 'RCP2.6 - Peak in radiative forcing at ~ 3 W/m2 before 2100 and decline. See "REPRESENTATIVE CONCENTRATION PATHWAYS (RCPs)" (https://sedac.ciesin.columbia.edu/ddc/ar5_scenario_process/RCPs.html)', 'RCP2.6', 'RCP2.6', 'RCP2.6','key1=>value1_en,key2=>value2_en','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'en', 'checksum',1,6, 'y', 'OS-C', 'OS-C', 'OS-C','y', 1,'2024-07-15T00:00:01Z')
;
INSERT INTO osc_physrisk.osc_physrisk_scenario.dim_scenario_type
	(scenario_type_id, description_full, description_short, name_fullyqualified, "name", tags, creation_time, creator_user_id, last_modification_time, last_modifier_user_id, is_deleted, deleter_user_id, deletion_time, culture, checksum, seq_num, translated_from_id, is_active, creator_user_name, last_modifier_user_name, deleter_user_name, is_published, publisher_id, published_date)
VALUES 
	(7, 'RCP4.5 - Stabilization without overshoot pathway to 4.5 W/m2 at stabilization after 2100. See "REPRESENTATIVE CONCENTRATION PATHWAYS (RCPs)" (https://sedac.ciesin.columbia.edu/ddc/ar5_scenario_process/RCPs.html)', 'RCP4.5', 'RCP4.5', 'RCP4.5','key1=>value1_en,key2=>value2_en','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'en', 'checksum',1,7, 'y', 'OS-C', 'OS-C', 'OS-C','y', 1,'2024-07-15T00:00:01Z')
;
INSERT INTO osc_physrisk.osc_physrisk_scenario.dim_scenario_type
	(scenario_type_id, description_full, description_short, name_fullyqualified, "name", tags, creation_time, creator_user_id, last_modification_time, last_modifier_user_id, is_deleted, deleter_user_id, deletion_time, culture, checksum, seq_num, translated_from_id, is_active, creator_user_name, last_modifier_user_name, deleter_user_name, is_published, publisher_id, published_date)
VALUES 
	(8, 'RCP6 - Stabilization without overshoot pathway to 6 W/m2 at stabilization after 2100. See "REPRESENTATIVE CONCENTRATION PATHWAYS (RCPs)" (https://sedac.ciesin.columbia.edu/ddc/ar5_scenario_process/RCPs.html)', 'RCP6', 'RCP6', 'RCP6','key1=>value1_en,key2=>value2_en','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'en', 'checksum',1,8, 'y', 'OS-C', 'OS-C', 'OS-C','y', 1,'2024-07-15T00:00:01Z')
;
INSERT INTO osc_physrisk.osc_physrisk_scenario.dim_scenario_type
	(scenario_type_id, description_full, description_short, name_fullyqualified, "name",tags,  creation_time, creator_user_id, last_modification_time, last_modifier_user_id, is_deleted, deleter_user_id, deletion_time, culture, checksum, seq_num, translated_from_id, is_active, creator_user_name, last_modifier_user_name, deleter_user_name, is_published, publisher_id, published_date)
VALUES 
	(9, 'RCP8.5 - Rising radiative forcing pathway leading to 8.5 W/m2 in 2100. See "REPRESENTATIVE CONCENTRATION PATHWAYS (RCPs)" (https://sedac.ciesin.columbia.edu/ddc/ar5_scenario_process/RCPs.html)', 'RCP8.5', 'RCP8.5', 'RCP8.5','key1=>value1_en,key2=>value2_en','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'en', 'checksum',1,9, 'y', 'OS-C', 'OS-C', 'OS-C','y', 1,'2024-07-15T00:00:01Z')
;

INSERT INTO osc_physrisk.osc_physrisk_risk_analysis.dim_impact_type
	(impact_type_id, description_full, description_short, name_fullyqualified, "name", tags, creation_time, creator_user_id, last_modification_time, last_modifier_user_id, is_deleted, deleter_user_id, deletion_time, culture, checksum, seq_num, translated_from_id, is_active, creator_user_name, last_modifier_user_name, deleter_user_name, is_published, publisher_id, published_date)
VALUES 
	(1, 'Unknown Damage or Disruption', 'Unknown Damage or Disruption', 'Unknown Damage or Disruption', 'Unknown Damage or Disruption','key1=>value1_en,key2=>value2_en','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'f',NULL,NULL, 'en', 'checksum',1,1, 't', 'OS-C', 'OS-C',NULL, 't',1 ,'2024-07-15T00:00:01Z')
;
INSERT INTO osc_physrisk.osc_physrisk_risk_analysis.dim_impact_type
	(impact_type_id, "name", name_fullyqualified, description_full, description_short, tags, creation_time, creator_user_id, last_modification_time, last_modifier_user_id, is_deleted, deleter_user_id, deletion_time, culture, checksum, seq_num, translated_from_id, is_active, creator_user_name, last_modifier_user_name, deleter_user_name, is_published, publisher_id, published_date, accounting_category)
VALUES 
	(2, 'Asset repairs and construction', 'Asset repairs and construction', 'Asset repairs and construction','Asset repairs and construction', 'key1=>value1_fr,key2=>value2_fr', '2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1, 'false',NULL,NULL, 'en', 'checksum',1,1, 't', 'OS-C', 'OS-C',NULL, 't',1 ,'2024-07-15T00:00:01Z','Capex' );
INSERT INTO osc_physrisk.osc_physrisk_risk_analysis.dim_impact_type
	(impact_type_id, "name", name_fullyqualified, description_full, description_short, tags, creation_time, creator_user_id, last_modification_time, last_modifier_user_id, is_deleted, deleter_user_id, deletion_time, culture, checksum, seq_num, translated_from_id, is_active, creator_user_name, last_modifier_user_name, deleter_user_name, is_published, publisher_id, published_date, accounting_category)
VALUES 
	(3, 'Revenue loss due to asset restoration', 'Revenue loss due to asset restoration', 'Revenue loss due to asset restoration','Revenue loss due to asset restoration', 'key1=>value1_fr,key2=>value2_fr', '2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1, 'false',NULL,NULL, 'en', 'checksum',1,1, 't', 'OS-C', 'OS-C',NULL, 't',1 ,'2024-07-15T00:00:01Z','Revenue' );
INSERT INTO osc_physrisk.osc_physrisk_risk_analysis.dim_impact_type
	(impact_type_id, "name", name_fullyqualified, description_full, description_short, tags, creation_time, creator_user_id, last_modification_time, last_modifier_user_id, is_deleted, deleter_user_id, deletion_time, culture, checksum, seq_num, translated_from_id, is_active, creator_user_name, last_modifier_user_name, deleter_user_name, is_published, publisher_id, published_date, accounting_category)
VALUES 
	(4, 'Revenue loss due to productivity impact', 'Revenue loss due to productivity impact', 'Revenue loss due to productivity impact','Revenue loss due to productivity impact', 'key1=>value1_fr,key2=>value2_fr', '2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1, 'false',NULL,NULL, 'en', 'checksum',1,1, 't', 'OS-C', 'OS-C',NULL, 't',1 ,'2024-07-15T00:00:01Z','Revenue' );
INSERT INTO osc_physrisk.osc_physrisk_risk_analysis.dim_impact_type
	(impact_type_id, "name", name_fullyqualified, description_full, description_short, tags, creation_time, creator_user_id, last_modification_time, last_modifier_user_id, is_deleted, deleter_user_id, deletion_time, culture, checksum, seq_num, translated_from_id, is_active, creator_user_name, last_modifier_user_name, deleter_user_name, is_published, publisher_id, published_date, accounting_category)
VALUES 
	(5, 'Recurring cost increase (chronic)', 'Recurring cost increase (chronic)', 'Recurring cost increase (chronic)','Recurring cost increase (chronic)', 'key1=>value1_fr,key2=>value2_fr', '2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1, 'false',NULL,NULL, 'en', 'checksum',1,1, 't', 'OS-C', 'OS-C',NULL, 't',1 ,'2024-07-15T00:00:01Z','OpEx' );
INSERT INTO osc_physrisk.osc_physrisk_risk_analysis.dim_impact_type
	(impact_type_id, "name", name_fullyqualified, description_full, description_short, tags, creation_time, creator_user_id, last_modification_time, last_modifier_user_id, is_deleted, deleter_user_id, deletion_time, culture, checksum, seq_num, translated_from_id, is_active, creator_user_name, last_modifier_user_name, deleter_user_name, is_published, publisher_id, published_date, accounting_category)
VALUES 
	(6, 'Recurring cost increase (acute)', 'Recurring cost increase (acute)', 'Recurring cost increase (acute)','Recurring cost increase (acute)', 'key1=>value1_fr,key2=>value2_fr', '2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1, 'false',NULL,NULL, 'en', 'checksum',1,1, 't', 'OS-C', 'OS-C',NULL, 't',1 ,'2024-07-15T00:00:01Z','OpEx' );
INSERT INTO osc_physrisk.osc_physrisk_hazard.hazard
	(hazard_id, "name", name_fullyqualified, description_full, description_short, tags, creation_time, creator_user_id, last_modification_time, last_modifier_user_id, is_deleted, deleter_user_id, deletion_time, culture, checksum, external_id, seq_num, translated_from_id, is_active, creator_user_name, last_modifier_user_name, deleter_user_name, tenant_id, tenant_name, is_published, publisher_id, published_date)
VALUES 
	('8159d927-e596-444d-8f1a-494494339fad', 'Unknown hazard/Not selected', 'Unknown hazard/Not selected', 'Unknown hazard/Not selected', 'Unknown hazard/Not selected', 'key1=>value1_es,key2=>value2_es','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'en', 'checksum',NULL,1, NULL,'y', 'OS-C', 'OS-C', NULL, 1,'OS-C','y',1,'2024-07-15T00:00:01Z')
;
INSERT INTO osc_physrisk.osc_physrisk_hazard.hazard
	(hazard_id, "name", name_fullyqualified, description_full, description_short, tags, creation_time, creator_user_id, last_modification_time, last_modifier_user_id, is_deleted, deleter_user_id, deletion_time, culture, checksum, external_id, seq_num, translated_from_id, is_active, creator_user_name, last_modifier_user_name, deleter_user_name, tenant_id, tenant_name, is_published, publisher_id, published_date)
VALUES 
	('63ed7943-c4c4-43ea-abd2-86bb1997a094', 'Riverine Inundation', 'Riverine Inundation', 'Riverine Inundation', 'Riverine Inundation', 'key1=>value1_es,key2=>value2_es','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'en', 'checksum',NULL,1, NULL,'y', 'OS-C', 'OS-C', NULL, 1,'OS-C','y',1,'2024-07-15T00:00:01Z')
;
INSERT INTO osc_physrisk.osc_physrisk_hazard.hazard
	(hazard_id, "name", name_fullyqualified, description_full, description_short, tags, creation_time, creator_user_id, last_modification_time, last_modifier_user_id, is_deleted, deleter_user_id, deletion_time, culture, checksum, external_id, seq_num, translated_from_id, is_active, creator_user_name, last_modifier_user_name, deleter_user_name, tenant_id, tenant_name, is_published, publisher_id, published_date)
VALUES 
	('28a095cd-4cde-40a1-90d9-cbb0ca673c06', 'Coastal Inundation', 'Coastal Inundation', 'Coastal Inundation', 'Coastal Inundation', 'key1=>value1_es,key2=>value2_es','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'en', 'checksum',NULL,1, NULL,'y', 'OS-C', 'OS-C', NULL, 1,'OS-C','y',1,'2024-07-15T00:00:01Z')
;
INSERT INTO osc_physrisk.osc_physrisk_hazard.hazard
	(hazard_id, "name", name_fullyqualified, description_full, description_short, tags, creation_time, creator_user_id, last_modification_time, last_modifier_user_id, is_deleted, deleter_user_id, deletion_time, culture, checksum, external_id, seq_num, translated_from_id, is_active, creator_user_name, last_modifier_user_name, deleter_user_name, tenant_id, tenant_name, is_published, publisher_id, published_date)
VALUES 
	('d08db675-ee1e-48fe-b9e1-b0da27de8f2b', 'Chronic Heat', 'Chronic Heat', 'Chronic Heat', 'Chronic Heat', 'key1=>value1_es,key2=>value2_es','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'en', 'checksum',NULL,1, NULL,'y', 'OS-C', 'OS-C', NULL, 1,'OS-C','y',1,'2024-07-15T00:00:01Z')
;
INSERT INTO osc_physrisk.osc_physrisk_hazard.hazard
	(hazard_id, "name", name_fullyqualified, description_full, description_short, tags, creation_time, creator_user_id, last_modification_time, last_modifier_user_id, is_deleted, deleter_user_id, deletion_time, culture, checksum, external_id, seq_num, translated_from_id, is_active, creator_user_name, last_modifier_user_name, deleter_user_name, tenant_id, tenant_name, is_published, publisher_id, published_date)
VALUES 
	('64fee0d3-b78b-49bf-911a-029695585d6a', 'Fire', 'Fire', 'Fire', 'Fire', 'key1=>value1_es,key2=>value2_es','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'en', 'checksum',NULL,1, NULL,'y', 'OS-C', 'OS-C', NULL, 1,'OS-C','y',1,'2024-07-15T00:00:01Z')
;
INSERT INTO osc_physrisk.osc_physrisk_hazard.hazard
	(hazard_id, "name", name_fullyqualified, description_full, description_short, tags, creation_time, creator_user_id, last_modification_time, last_modifier_user_id, is_deleted, deleter_user_id, deletion_time, culture, checksum, external_id, seq_num, translated_from_id, is_active, creator_user_name, last_modifier_user_name, deleter_user_name, tenant_id, tenant_name, is_published, publisher_id, published_date)
VALUES 
	('35ace20f-86dc-4735-9536-129b51b6d25d', 'Drought', 'Drought', 'Drought', 'Drought', 'key1=>value1_es,key2=>value2_es','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'en', 'checksum',NULL,1, NULL,'y', 'OS-C', 'OS-C', NULL, 1,'OS-C','y',1,'2024-07-15T00:00:01Z')
;
INSERT INTO osc_physrisk.osc_physrisk_hazard.hazard
	(hazard_id, "name", name_fullyqualified, description_full, description_short, tags, creation_time, creator_user_id, last_modification_time, last_modifier_user_id, is_deleted, deleter_user_id, deletion_time, culture, checksum, external_id, seq_num, translated_from_id, is_active, creator_user_name, last_modifier_user_name, deleter_user_name, tenant_id, tenant_name, is_published, publisher_id, published_date)
VALUES 
	('2faed491-2c5d-499e-9568-fad6e3b3c0ec', 'Precipitation', 'Precipitation', 'Precipitation', 'Precipitation', 'key1=>value1_es,key2=>value2_es','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'en', 'checksum',NULL,1, NULL,'y', 'OS-C', 'OS-C', NULL, 1,'OS-C','y',1,'2024-07-15T00:00:01Z')
;
INSERT INTO osc_physrisk.osc_physrisk_hazard.hazard
	(hazard_id, "name", name_fullyqualified, description_full, description_short, tags, creation_time, creator_user_id, last_modification_time, last_modifier_user_id, is_deleted, deleter_user_id, deletion_time, culture, checksum, external_id, seq_num, translated_from_id, is_active, creator_user_name, last_modifier_user_name, deleter_user_name, tenant_id, tenant_name, is_published, publisher_id, published_date)
VALUES 
	('e4e4e199-367e-4568-824d-3f916e355567', 'Hail', 'Hail', 'Hail', 'Hail', 'key1=>value1_es,key2=>value2_es','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'en', 'checksum',NULL,1, NULL,'y', 'OS-C', 'OS-C', NULL, 1,'OS-C','y',1,'2024-07-15T00:00:01Z')
;
INSERT INTO osc_physrisk.osc_physrisk_hazard.hazard
	(hazard_id, "name", name_fullyqualified, description_full, description_short, tags, creation_time, creator_user_id, last_modification_time, last_modifier_user_id, is_deleted, deleter_user_id, deletion_time, culture, checksum, external_id, seq_num, translated_from_id, is_active, creator_user_name, last_modifier_user_name, deleter_user_name, tenant_id, tenant_name, is_published, publisher_id, published_date)
VALUES 
	('0184b858-404d-4282-8f0d-2b4c42f7acd7', 'Wind', 'Wind', 'Wind', 'Wind', 'key1=>value1_es,key2=>value2_es','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'en', 'checksum',NULL,1, NULL,'y', 'OS-C', 'OS-C', NULL, 1,'OS-C','y',1,'2024-07-15T00:00:01Z')
;
INSERT INTO osc_physrisk.osc_physrisk_hazard.hazard
	(hazard_id, "name", name_fullyqualified, description_full, description_short, tags, creation_time, creator_user_id, last_modification_time, last_modifier_user_id, is_deleted, deleter_user_id, deletion_time, culture, checksum, external_id, seq_num, translated_from_id, is_active, creator_user_name, last_modifier_user_name, deleter_user_name, tenant_id, tenant_name, is_published, publisher_id, published_date)
VALUES 
	('338ea109-828e-4aaf-b212-12d8eaf70a7e', 'Combined Inundation', 'Combined Inundation', 'Combined Inundation', 'Combined Inundation', 'key1=>value1_es,key2=>value2_es','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'en', 'checksum',NULL,1, NULL,'y', 'OS-C', 'OS-C', NULL, 1,'OS-C','y',1,'2024-07-15T00:00:01Z')
;
INSERT INTO osc_physrisk.osc_physrisk_hazard.hazard
	(hazard_id, "name", name_fullyqualified, description_full, description_short, tags, creation_time, creator_user_id, last_modification_time, last_modifier_user_id, is_deleted, deleter_user_id, deletion_time, culture, checksum, external_id, seq_num, translated_from_id, is_active, creator_user_name, last_modifier_user_name, deleter_user_name, tenant_id, tenant_name, is_published, publisher_id, published_date)
VALUES 
	('29514258-18cb-4f2b-8798-203e0d513803', 'Water Risk', 'Water Risk', 'Water Risk', 'Water Risk', 'key1=>value1_es,key2=>value2_es','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'en', 'checksum',NULL,1, NULL,'y', 'OS-C', 'OS-C', NULL, 1,'OS-C','y',1,'2024-07-15T00:00:01Z')
;
INSERT INTO osc_physrisk.osc_physrisk_hazard.hazard_indicator
	(hazard_indicator_id, "name", name_fullyqualified, description_full, description_short, tags, creation_time, creator_user_id, last_modification_time, last_modifier_user_id, is_deleted, deleter_user_id, deletion_time, culture, checksum, external_id, seq_num, translated_from_id, is_active, creator_user_name, last_modifier_user_name, deleter_user_name, tenant_id, tenant_name, is_published, publisher_id, published_date, hazard_id)
VALUES 
	('57a7df66-420d-4730-9669-1547f8200272', 'Flood depth (TUDelft)', 'Flood depth (TUDelft)', 'Flood depth (TUDelft)', 'Flood depth (TUDelft)', 'key1=>value1_es,key2=>value2_es','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'en', 'checksum',NULL,1, NULL,'y', 'OS-C', 'OS-C', NULL, 1,'OS-C','y',1,'2024-07-15T00:00:01Z', '63ed7943-c4c4-43ea-abd2-86bb1997a094')
;
INSERT INTO osc_physrisk.osc_physrisk_hazard.hazard_indicator
	(hazard_indicator_id, "name", name_fullyqualified, description_full, description_short, tags, creation_time, creator_user_id, last_modification_time, last_modifier_user_id, is_deleted, deleter_user_id, deletion_time, culture, checksum, external_id, seq_num, translated_from_id, is_active, creator_user_name, last_modifier_user_name, deleter_user_name, tenant_id, tenant_name, is_published, publisher_id, published_date, hazard_id)
VALUES 
	('5fb27cc6-ee01-4133-b2e9-6c1f22ed5b40', 'Flood depth/GFDL-ESM2M (WRI)', 'Flood depth/GFDL-ESM2M (WRI)', 'Flood depth/GFDL-ESM2M (WRI)', 'Flood depth/GFDL-ESM2M (WRI)', 'key1=>value1_es,key2=>value2_es','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'en', 'checksum',NULL,1, NULL,'y', 'OS-C', 'OS-C', NULL, 1,'OS-C','y',1,'2024-07-15T00:00:01Z', '63ed7943-c4c4-43ea-abd2-86bb1997a094')
;
INSERT INTO osc_physrisk.osc_physrisk_hazard.hazard_indicator
	(hazard_indicator_id, "name", name_fullyqualified, description_full, description_short, tags, creation_time, creator_user_id, last_modification_time, last_modifier_user_id, is_deleted, deleter_user_id, deletion_time, culture, checksum, external_id, seq_num, translated_from_id, is_active, creator_user_name, last_modifier_user_name, deleter_user_name, tenant_id, tenant_name, is_published, publisher_id, published_date, hazard_id)
VALUES 
	('79555143-ba2a-47b0-bbe7-7aac3685dedb', 'Flood depth/HadGEM2-ES (WRI)', 'Flood depth/HadGEM2-ES (WRI)', 'Flood depth/HadGEM2-ES (WRI)', 'Flood depth/HadGEM2-ES (WRI)', 'key1=>value1_es,key2=>value2_es','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'en', 'checksum',NULL,1, NULL,'y', 'OS-C', 'OS-C', NULL, 1,'OS-C','y',1,'2024-07-15T00:00:01Z', '63ed7943-c4c4-43ea-abd2-86bb1997a094')
;
INSERT INTO osc_physrisk.osc_physrisk_hazard.hazard_indicator
	(hazard_indicator_id, "name", name_fullyqualified, description_full, description_short, tags, creation_time, creator_user_id, last_modification_time, last_modifier_user_id, is_deleted, deleter_user_id, deletion_time, culture, checksum, external_id, seq_num, translated_from_id, is_active, creator_user_name, last_modifier_user_name, deleter_user_name, tenant_id, tenant_name, is_published, publisher_id, published_date, hazard_id)
VALUES 
	('6fe5ccb1-5d38-4a3e-b0a5-d4cc70981035', 'Flood depth/IPSL-CM5A-LR (WRI)', 'Flood depth/IPSL-CM5A-LR (WRI)', 'Flood depth/IPSL-CM5A-LR (WRI)', 'Flood depth/IPSL-CM5A-LR (WRI)', 'key1=>value1_es,key2=>value2_es','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'en', 'checksum',NULL,1, NULL,'y', 'OS-C', 'OS-C', NULL, 1,'OS-C','y',1,'2024-07-15T00:00:01Z', '63ed7943-c4c4-43ea-abd2-86bb1997a094')
;
INSERT INTO osc_physrisk.osc_physrisk_hazard.hazard_indicator
	(hazard_indicator_id, "name", name_fullyqualified, description_full, description_short, tags, creation_time, creator_user_id, last_modification_time, last_modifier_user_id, is_deleted, deleter_user_id, deletion_time, culture, checksum, external_id, seq_num, translated_from_id, is_active, creator_user_name, last_modifier_user_name, deleter_user_name, tenant_id, tenant_name, is_published, publisher_id, published_date, hazard_id)
VALUES 
	('e4f10569-95be-4b5b-8d34-763eb95e730b', 'Flood depth/MIROC-ESM-CHEM (WRI)', 'Flood depth/MIROC-ESM-CHEM (WRI)', 'Flood depth/MIROC-ESM-CHEM (WRI)', 'Flood depth/MIROC-ESM-CHEM (WRI)', 'key1=>value1_es,key2=>value2_es','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'en', 'checksum',NULL,1, NULL,'y', 'OS-C', 'OS-C', NULL, 1,'OS-C','y',1,'2024-07-15T00:00:01Z', '63ed7943-c4c4-43ea-abd2-86bb1997a094')
;
INSERT INTO osc_physrisk.osc_physrisk_hazard.hazard_indicator
	(hazard_indicator_id, "name", name_fullyqualified, description_full, description_short, tags, creation_time, creator_user_id, last_modification_time, last_modifier_user_id, is_deleted, deleter_user_id, deletion_time, culture, checksum, external_id, seq_num, translated_from_id, is_active, creator_user_name, last_modifier_user_name, deleter_user_name, tenant_id, tenant_name, is_published, publisher_id, published_date, hazard_id)
VALUES 
	('690e01eb-f7e6-4fbf-84e4-f8195656abb3', 'Flood depth/NorESM1-M (WRI)', 'Flood depth/NorESM1-M (WRI)', 'Flood depth/NorESM1-M (WRI)', 'Flood depth/NorESM1-M (WRI)', 'key1=>value1_es,key2=>value2_es','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'en', 'checksum',NULL,1, NULL,'y', 'OS-C', 'OS-C', NULL, 1,'OS-C','y',1,'2024-07-15T00:00:01Z', '63ed7943-c4c4-43ea-abd2-86bb1997a094')
;
INSERT INTO osc_physrisk.osc_physrisk_hazard.hazard_indicator
	(hazard_indicator_id, "name", name_fullyqualified, description_full, description_short, tags, creation_time, creator_user_id, last_modification_time, last_modifier_user_id, is_deleted, deleter_user_id, deletion_time, culture, checksum, external_id, seq_num, translated_from_id, is_active, creator_user_name, last_modifier_user_name, deleter_user_name, tenant_id, tenant_name, is_published, publisher_id, published_date, hazard_id)
VALUES 
	('5f396b97-badc-40d2-b0b3-c8be8f3053ba', 'Flood depth/baseline (WRI)', 'Flood depth/baseline (WRI)', 'Flood depth/baseline (WRI)', 'Flood depth/baseline (WRI)', 'key1=>value1_es,key2=>value2_es','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'en', 'checksum',NULL,1, NULL,'y', 'OS-C', 'OS-C', NULL, 1,'OS-C','y',1,'2024-07-15T00:00:01Z', '63ed7943-c4c4-43ea-abd2-86bb1997a094')
;
INSERT INTO osc_physrisk.osc_physrisk_hazard.hazard_indicator
	(hazard_indicator_id, "name", name_fullyqualified, description_full, description_short, tags, creation_time, creator_user_id, last_modification_time, last_modifier_user_id, is_deleted, deleter_user_id, deletion_time, culture, checksum, external_id, seq_num, translated_from_id, is_active, creator_user_name, last_modifier_user_name, deleter_user_name, tenant_id, tenant_name, is_published, publisher_id, published_date, hazard_id)
VALUES 
	('901cbd14-9223-4d36-8ab4-658945d913a4', 'Standard of protection (TUDelft)', 'Standard of protection (TUDelft)', 'Standard of protection (TUDelft)', 'Standard of protection (TUDelft)', 'key1=>value1_es,key2=>value2_es','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'en', 'checksum',NULL,1, NULL,'y', 'OS-C', 'OS-C', NULL, 1,'OS-C','y',1,'2024-07-15T00:00:01Z', '63ed7943-c4c4-43ea-abd2-86bb1997a094')
;
INSERT INTO osc_physrisk.osc_physrisk_hazard.hazard_indicator
	(hazard_indicator_id, "name", name_fullyqualified, description_full, description_short, tags, creation_time, creator_user_id, last_modification_time, last_modifier_user_id, is_deleted, deleter_user_id, deletion_time, culture, checksum, external_id, seq_num, translated_from_id, is_active, creator_user_name, last_modifier_user_name, deleter_user_name, tenant_id, tenant_name, is_published, publisher_id, published_date, hazard_id)
VALUES 
	('be44d6fb-08cb-4f52-8ff2-bf1b7366a7a0', 'Flood depth/5%, no subsidence (WRI)', 'Flood depth/5%, no subsidence (WRI)', 'Flood depth/5%, no subsidence (WRI)', 'Flood depth/5%, no subsidence (WRI)', 'key1=>value1_es,key2=>value2_es','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'en', 'checksum',NULL,1, NULL,'y', 'OS-C', 'OS-C', NULL, 1,'OS-C','y',1,'2024-07-15T00:00:01Z', '28a095cd-4cde-40a1-90d9-cbb0ca673c06')
;
INSERT INTO osc_physrisk.osc_physrisk_hazard.hazard_indicator
	(hazard_indicator_id, "name", name_fullyqualified, description_full, description_short, tags, creation_time, creator_user_id, last_modification_time, last_modifier_user_id, is_deleted, deleter_user_id, deletion_time, culture, checksum, external_id, seq_num, translated_from_id, is_active, creator_user_name, last_modifier_user_name, deleter_user_name, tenant_id, tenant_name, is_published, publisher_id, published_date, hazard_id)
VALUES 
	('c87fc5c3-c2ae-4732-ba52-7d9156044d7b', 'Flood depth/5%, with subsidence (WRI)', 'Flood depth/5%, with subsidence (WRI)', 'Flood depth/5%, with subsidence (WRI)', 'Flood depth/5%, with subsidence (WRI)', 'key1=>value1_es,key2=>value2_es','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'en', 'checksum',NULL,1, NULL,'y', 'OS-C', 'OS-C', NULL, 1,'OS-C','y',1,'2024-07-15T00:00:01Z', '28a095cd-4cde-40a1-90d9-cbb0ca673c06')
;
INSERT INTO osc_physrisk.osc_physrisk_hazard.hazard_indicator
	(hazard_indicator_id, "name", name_fullyqualified, description_full, description_short, tags, creation_time, creator_user_id, last_modification_time, last_modifier_user_id, is_deleted, deleter_user_id, deletion_time, culture, checksum, external_id, seq_num, translated_from_id, is_active, creator_user_name, last_modifier_user_name, deleter_user_name, tenant_id, tenant_name, is_published, publisher_id, published_date, hazard_id)
VALUES 
	('60c90be9-5cfb-4f6a-b9eb-e84e7da5a456', 'Flood depth/50%, no subsidence (WRI)', 'Flood depth/50%, no subsidence (WRI)', 'Flood depth/50%, no subsidence (WRI)', 'Flood depth/50%, no subsidence (WRI)', 'key1=>value1_es,key2=>value2_es','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'en', 'checksum',NULL,1, NULL,'y', 'OS-C', 'OS-C', NULL, 1,'OS-C','y',1,'2024-07-15T00:00:01Z', '28a095cd-4cde-40a1-90d9-cbb0ca673c06')
;
INSERT INTO osc_physrisk.osc_physrisk_hazard.hazard_indicator
	(hazard_indicator_id, "name", name_fullyqualified, description_full, description_short, tags, creation_time, creator_user_id, last_modification_time, last_modifier_user_id, is_deleted, deleter_user_id, deletion_time, culture, checksum, external_id, seq_num, translated_from_id, is_active, creator_user_name, last_modifier_user_name, deleter_user_name, tenant_id, tenant_name, is_published, publisher_id, published_date, hazard_id)
VALUES 
	('e7623e9e-649e-460a-8b81-ae9d01711f75', 'Flood depth/50%, with subsidence (WRI)', 'Flood depth/50%, with subsidence (WRI)', 'Flood depth/50%, with subsidence (WRI)', 'Flood depth/50%, with subsidence (WRI)', 'key1=>value1_es,key2=>value2_es','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'en', 'checksum',NULL,1, NULL,'y', 'OS-C', 'OS-C', NULL, 1,'OS-C','y',1,'2024-07-15T00:00:01Z', '28a095cd-4cde-40a1-90d9-cbb0ca673c06')
;
INSERT INTO osc_physrisk.osc_physrisk_hazard.hazard_indicator
	(hazard_indicator_id, "name", name_fullyqualified, description_full, description_short, tags, creation_time, creator_user_id, last_modification_time, last_modifier_user_id, is_deleted, deleter_user_id, deletion_time, culture, checksum, external_id, seq_num, translated_from_id, is_active, creator_user_name, last_modifier_user_name, deleter_user_name, tenant_id, tenant_name, is_published, publisher_id, published_date, hazard_id)
VALUES 
	('28fbe059-a661-4fe6-8ba7-0fa626a9312b', 'Flood depth/95%, no subsidence (WRI)', 'Flood depth/95%, no subsidence (WRI)', 'Flood depth/95%, no subsidence (WRI)', 'Flood depth/95%, no subsidence (WRI)', 'key1=>value1_es,key2=>value2_es','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'en', 'checksum',NULL,1, NULL,'y', 'OS-C', 'OS-C', NULL, 1,'OS-C','y',1,'2024-07-15T00:00:01Z', '28a095cd-4cde-40a1-90d9-cbb0ca673c06')
;
INSERT INTO osc_physrisk.osc_physrisk_hazard.hazard_indicator
	(hazard_indicator_id, "name", name_fullyqualified, description_full, description_short, tags, creation_time, creator_user_id, last_modification_time, last_modifier_user_id, is_deleted, deleter_user_id, deletion_time, culture, checksum, external_id, seq_num, translated_from_id, is_active, creator_user_name, last_modifier_user_name, deleter_user_name, tenant_id, tenant_name, is_published, publisher_id, published_date, hazard_id)
VALUES 
	('ea005e03-f025-4aa4-a37e-981eea5bcfdb', 'Flood depth/95%, with subsidence (WRI)', 'Flood depth/95%, with subsidence (WRI)', 'Flood depth/95%, with subsidence (WRI)', 'Flood depth/95%, with subsidence (WRI)', 'key1=>value1_es,key2=>value2_es','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'en', 'checksum',NULL,1, NULL,'y', 'OS-C', 'OS-C', NULL, 1,'OS-C','y',1,'2024-07-15T00:00:01Z', '28a095cd-4cde-40a1-90d9-cbb0ca673c06')
;
INSERT INTO osc_physrisk.osc_physrisk_hazard.hazard_indicator
	(hazard_indicator_id, "name", name_fullyqualified, description_full, description_short, tags, creation_time, creator_user_id, last_modification_time, last_modifier_user_id, is_deleted, deleter_user_id, deletion_time, culture, checksum, external_id, seq_num, translated_from_id, is_active, creator_user_name, last_modifier_user_name, deleter_user_name, tenant_id, tenant_name, is_published, publisher_id, published_date, hazard_id)
VALUES 
	('12651bc5-04a2-4225-ba25-f1c0e09bdb90', 'Flood depth/baseline, no subsidence (WRI)', 'Flood depth/baseline, no subsidence (WRI)', 'Flood depth/baseline, no subsidence (WRI)', 'Flood depth/baseline, no subsidence (WRI)', 'key1=>value1_es,key2=>value2_es','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'en', 'checksum',NULL,1, NULL,'y', 'OS-C', 'OS-C', NULL, 1,'OS-C','y',1,'2024-07-15T00:00:01Z', '28a095cd-4cde-40a1-90d9-cbb0ca673c06')
;
INSERT INTO osc_physrisk.osc_physrisk_hazard.hazard_indicator
	(hazard_indicator_id, "name", name_fullyqualified, description_full, description_short, tags, creation_time, creator_user_id, last_modification_time, last_modifier_user_id, is_deleted, deleter_user_id, deletion_time, culture, checksum, external_id, seq_num, translated_from_id, is_active, creator_user_name, last_modifier_user_name, deleter_user_name, tenant_id, tenant_name, is_published, publisher_id, published_date, hazard_id)
VALUES 
	('6ba57474-6c7a-4ea3-aca8-25e30f27cec1', 'Flood depth/baseline, with subsidence (WRI)', 'Flood depth/baseline, with subsidence (WRI)', 'Flood depth/baseline, with subsidence (WRI)', 'Flood depth/baseline, with subsidence (WRI)', 'key1=>value1_es,key2=>value2_es','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'en', 'checksum',NULL,1, NULL,'y', 'OS-C', 'OS-C', NULL, 1,'OS-C','y',1,'2024-07-15T00:00:01Z', '28a095cd-4cde-40a1-90d9-cbb0ca673c06')
;
INSERT INTO osc_physrisk.osc_physrisk_hazard.hazard_indicator
	(hazard_indicator_id, "name", name_fullyqualified, description_full, description_short, tags, creation_time, creator_user_id, last_modification_time, last_modifier_user_id, is_deleted, deleter_user_id, deletion_time, culture, checksum, external_id, seq_num, translated_from_id, is_active, creator_user_name, last_modifier_user_name, deleter_user_name, tenant_id, tenant_name, is_published, publisher_id, published_date, hazard_id)
VALUES 
	('e0b5afc2-eed8-4760-9667-c14fdbf374db', 'Days with average temperature above 25°C/ACCESS-CM2', 'Days with average temperature above 25°C/ACCESS-CM2', 'Days with average temperature above 25°C/ACCESS-CM2', 'Days with average temperature above 25°C/ACCESS-CM2', 'key1=>value1_en,key2=>value2_en','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'en', 'checksum',NULL,1, NULL,'y', 'OS-C', 'OS-C', NULL, 1,'OS-C','y',1,'2024-07-15T00:00:01Z', 'd08db675-ee1e-48fe-b9e1-b0da27de8f2b')
;
INSERT INTO osc_physrisk.osc_physrisk_hazard.hazard_indicator
	(hazard_indicator_id, "name", name_fullyqualified, description_full, description_short, tags, creation_time, creator_user_id, last_modification_time, last_modifier_user_id, is_deleted, deleter_user_id, deletion_time, culture, checksum, external_id, seq_num, translated_from_id, is_active, creator_user_name, last_modifier_user_name, deleter_user_name, tenant_id, tenant_name, is_published, publisher_id, published_date, hazard_id)
VALUES 
	('b795a8af-12cc-4773-83ee-a50badd1fe74', 'Days with average temperature above 25°C/CMCC-ESM2', 'Days with average temperature above 25°C/CMCC-ESM2', 'Days with average temperature above 25°C/CMCC-ESM2', 'Days with average temperature above 25°C/CMCC-ESM2', 'key1=>value1_en,key2=>value2_en','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'en', 'checksum',NULL,1, NULL,'y', 'OS-C', 'OS-C', NULL, 1,'OS-C','y',1,'2024-07-15T00:00:01Z', 'd08db675-ee1e-48fe-b9e1-b0da27de8f2b')
;
INSERT INTO osc_physrisk.osc_physrisk_hazard.hazard_indicator
	(hazard_indicator_id, "name", name_fullyqualified, description_full, description_short, tags, creation_time, creator_user_id, last_modification_time, last_modifier_user_id, is_deleted, deleter_user_id, deletion_time, culture, checksum, external_id, seq_num, translated_from_id, is_active, creator_user_name, last_modifier_user_name, deleter_user_name, tenant_id, tenant_name, is_published, publisher_id, published_date, hazard_id)
VALUES 
	('81213608-0a01-42b0-a54f-a070fb104b95', 'Days with average temperature above 25°C/CNRM-CM6-1', 'Days with average temperature above 25°C/CNRM-CM6-1', 'Days with average temperature above 25°C/CNRM-CM6-1', 'Days with average temperature above 25°C/CNRM-CM6-1', 'key1=>value1_en,key2=>value2_en','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'en', 'checksum',NULL,1, NULL,'y', 'OS-C', 'OS-C', NULL, 1,'OS-C','y',1,'2024-07-15T00:00:01Z', 'd08db675-ee1e-48fe-b9e1-b0da27de8f2b')
;
INSERT INTO osc_physrisk.osc_physrisk_hazard.hazard_indicator
	(hazard_indicator_id, "name", name_fullyqualified, description_full, description_short, tags, creation_time, creator_user_id, last_modification_time, last_modifier_user_id, is_deleted, deleter_user_id, deletion_time, culture, checksum, external_id, seq_num, translated_from_id, is_active, creator_user_name, last_modifier_user_name, deleter_user_name, tenant_id, tenant_name, is_published, publisher_id, published_date, hazard_id)
VALUES 
	('98692238-6a8f-4e58-a779-9f96eeaf1abd', 'Days with average temperature above 25°C/MIROC6', 'Days with average temperature above 25°C/MIROC6', 'Days with average temperature above 25°C/MIROC6', 'Days with average temperature above 25°C/MIROC6', 'key1=>value1_en,key2=>value2_en','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'en', 'checksum',NULL,1, NULL,'y', 'OS-C', 'OS-C', NULL, 1,'OS-C','y',1,'2024-07-15T00:00:01Z', 'd08db675-ee1e-48fe-b9e1-b0da27de8f2b')
;
INSERT INTO osc_physrisk.osc_physrisk_hazard.hazard_indicator
	(hazard_indicator_id, "name", name_fullyqualified, description_full, description_short, tags, creation_time, creator_user_id, last_modification_time, last_modifier_user_id, is_deleted, deleter_user_id, deletion_time, culture, checksum, external_id, seq_num, translated_from_id, is_active, creator_user_name, last_modifier_user_name, deleter_user_name, tenant_id, tenant_name, is_published, publisher_id, published_date, hazard_id)
VALUES 
	('3dbf253a-d880-4440-baa5-3e4a9fcac355', 'Days with average temperature above 25°C/ESM1-2-LR', 'Days with average temperature above 25°C/ESM1-2-LR', 'Days with average temperature above 25°C/ESM1-2-LR', 'Days with average temperature above 25°C/ESM1-2-LR', 'key1=>value1_en,key2=>value2_en','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'en', 'checksum',NULL,1, NULL,'y', 'OS-C', 'OS-C', NULL, 1,'OS-C','y',1,'2024-07-15T00:00:01Z', 'd08db675-ee1e-48fe-b9e1-b0da27de8f2b')
;
INSERT INTO osc_physrisk.osc_physrisk_hazard.hazard_indicator
	(hazard_indicator_id, "name", name_fullyqualified, description_full, description_short, tags, creation_time, creator_user_id, last_modification_time, last_modifier_user_id, is_deleted, deleter_user_id, deletion_time, culture, checksum, external_id, seq_num, translated_from_id, is_active, creator_user_name, last_modifier_user_name, deleter_user_name, tenant_id, tenant_name, is_published, publisher_id, published_date, hazard_id)
VALUES 
	('5fcca03b-ffff-4632-b896-78ceb9777e4b', 'Days with average temperature above 25°C/NorESM2-MM', 'Days with average temperature above 25°C/NorESM2-MM', 'Days with average temperature above 25°C/NorESM2-MM', 'Days with average temperature above 25°C/NorESM2-MM', 'key1=>value1_en,key2=>value2_en','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'en', 'checksum',NULL,1, NULL,'y', 'OS-C', 'OS-C', NULL, 1,'OS-C','y',1,'2024-07-15T00:00:01Z', 'd08db675-ee1e-48fe-b9e1-b0da27de8f2b')
;
INSERT INTO osc_physrisk.osc_physrisk_hazard.hazard_indicator
	(hazard_indicator_id, "name", name_fullyqualified, description_full, description_short, tags, creation_time, creator_user_id, last_modification_time, last_modifier_user_id, is_deleted, deleter_user_id, deletion_time, culture, checksum, external_id, seq_num, translated_from_id, is_active, creator_user_name, last_modifier_user_name, deleter_user_name, tenant_id, tenant_name, is_published, publisher_id, published_date, hazard_id)
VALUES 
	('77f04d46-303f-40f2-a892-d0068d6ab64a', 'Days with average temperature above 30°C/ACCESS-CM2', 'Days with average temperature above 30°C/ACCESS-CM2', 'Days with average temperature above 30°C/ACCESS-CM2', 'Days with average temperature above 30°C/ACCESS-CM2', 'key1=>value1_en,key2=>value2_en','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'en', 'checksum',NULL,1, NULL,'y', 'OS-C', 'OS-C', NULL, 1,'OS-C','y',1,'2024-07-15T00:00:01Z', 'd08db675-ee1e-48fe-b9e1-b0da27de8f2b')
;
INSERT INTO osc_physrisk.osc_physrisk_hazard.hazard_indicator
	(hazard_indicator_id, "name", name_fullyqualified, description_full, description_short, tags, creation_time, creator_user_id, last_modification_time, last_modifier_user_id, is_deleted, deleter_user_id, deletion_time, culture, checksum, external_id, seq_num, translated_from_id, is_active, creator_user_name, last_modifier_user_name, deleter_user_name, tenant_id, tenant_name, is_published, publisher_id, published_date, hazard_id)
VALUES 
	('c47e4dfa-e850-4060-aed9-af9100c65986', 'Days with average temperature above 30°C/CMCC-ESM2', 'Days with average temperature above 30°C/CMCC-ESM2', 'Days with average temperature above 30°C/CMCC-ESM2', 'Days with average temperature above 30°C/CMCC-ESM2', 'key1=>value1_en,key2=>value2_en','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'en', 'checksum',NULL,1, NULL,'y', 'OS-C', 'OS-C', NULL, 1,'OS-C','y',1,'2024-07-15T00:00:01Z', 'd08db675-ee1e-48fe-b9e1-b0da27de8f2b')
;
INSERT INTO osc_physrisk.osc_physrisk_hazard.hazard_indicator
	(hazard_indicator_id, "name", name_fullyqualified, description_full, description_short, tags, creation_time, creator_user_id, last_modification_time, last_modifier_user_id, is_deleted, deleter_user_id, deletion_time, culture, checksum, external_id, seq_num, translated_from_id, is_active, creator_user_name, last_modifier_user_name, deleter_user_name, tenant_id, tenant_name, is_published, publisher_id, published_date, hazard_id)
VALUES 
	('ba1e06be-1cf5-4b5d-8f93-8f64e47af2b8', 'Days with average temperature above 30°C/CNRM-CM6-1', 'Days with average temperature above 30°C/CNRM-CM6-1', 'Days with average temperature above 30°C/CNRM-CM6-1', 'Days with average temperature above 30°C/CNRM-CM6-1', 'key1=>value1_en,key2=>value2_en','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'en', 'checksum',NULL,1, NULL,'y', 'OS-C', 'OS-C', NULL, 1,'OS-C','y',1,'2024-07-15T00:00:01Z', 'd08db675-ee1e-48fe-b9e1-b0da27de8f2b')
;
INSERT INTO osc_physrisk.osc_physrisk_hazard.hazard_indicator
	(hazard_indicator_id, "name", name_fullyqualified, description_full, description_short, tags, creation_time, creator_user_id, last_modification_time, last_modifier_user_id, is_deleted, deleter_user_id, deletion_time, culture, checksum, external_id, seq_num, translated_from_id, is_active, creator_user_name, last_modifier_user_name, deleter_user_name, tenant_id, tenant_name, is_published, publisher_id, published_date, hazard_id)
VALUES 
	('b882a67c-acea-4dbe-9939-1594775e6f78', 'Days with average temperature above 30°C/MIROC6', 'Days with average temperature above 30°C/MIROC6', 'Days with average temperature above 30°C/MIROC6', 'Days with average temperature above 30°C/MIROC6', 'key1=>value1_en,key2=>value2_en','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'en', 'checksum',NULL,1, NULL,'y', 'OS-C', 'OS-C', NULL, 1,'OS-C','y',1,'2024-07-15T00:00:01Z', 'd08db675-ee1e-48fe-b9e1-b0da27de8f2b')
;
INSERT INTO osc_physrisk.osc_physrisk_hazard.hazard_indicator
	(hazard_indicator_id, "name", name_fullyqualified, description_full, description_short, tags, creation_time, creator_user_id, last_modification_time, last_modifier_user_id, is_deleted, deleter_user_id, deletion_time, culture, checksum, external_id, seq_num, translated_from_id, is_active, creator_user_name, last_modifier_user_name, deleter_user_name, tenant_id, tenant_name, is_published, publisher_id, published_date, hazard_id)
VALUES 
	('0ae16260-45b7-48fe-924e-a2bd2bc25f39', 'Days with average temperature above 30°C/ESM1-2-LR', 'Days with average temperature above 30°C/ESM1-2-LR', 'Days with average temperature above 30°C/ESM1-2-LR', 'Days with average temperature above 30°C/ESM1-2-LR', 'key1=>value1_en,key2=>value2_en','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'en', 'checksum',NULL,1, NULL,'y', 'OS-C', 'OS-C', NULL, 1,'OS-C','y',1,'2024-07-15T00:00:01Z', 'd08db675-ee1e-48fe-b9e1-b0da27de8f2b')
;
INSERT INTO osc_physrisk.osc_physrisk_hazard.hazard_indicator
	(hazard_indicator_id, "name", name_fullyqualified, description_full, description_short, tags, creation_time, creator_user_id, last_modification_time, last_modifier_user_id, is_deleted, deleter_user_id, deletion_time, culture, checksum, external_id, seq_num, translated_from_id, is_active, creator_user_name, last_modifier_user_name, deleter_user_name, tenant_id, tenant_name, is_published, publisher_id, published_date, hazard_id)
VALUES 
	('151fe933-f1be-4fb1-bcaf-d534a5023c78', 'Days with average temperature above 30°C/NorESM2-MM', 'Days with average temperature above 30°C/NorESM2-MM', 'Days with average temperature above 30°C/NorESM2-MM', 'Days with average temperature above 30°C/NorESM2-MM', 'key1=>value1_en,key2=>value2_en','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'en', 'checksum',NULL,1, NULL,'y', 'OS-C', 'OS-C', NULL, 1,'OS-C','y',1,'2024-07-15T00:00:01Z', 'd08db675-ee1e-48fe-b9e1-b0da27de8f2b')
;
INSERT INTO osc_physrisk.osc_physrisk_hazard.hazard_indicator
	(hazard_indicator_id, "name", name_fullyqualified, description_full, description_short, tags, creation_time, creator_user_id, last_modification_time, last_modifier_user_id, is_deleted, deleter_user_id, deletion_time, culture, checksum, external_id, seq_num, translated_from_id, is_active, creator_user_name, last_modifier_user_name, deleter_user_name, tenant_id, tenant_name, is_published, publisher_id, published_date, hazard_id)
VALUES 
	('96e6fcc5-d843-4f59-9746-2d0d341b6bdc', 'Days with average temperature above 35°C/ACCESS-CM2', 'Days with average temperature above 35°C/ACCESS-CM2', 'Days with average temperature above 35°C/ACCESS-CM2', 'Days with average temperature above 35°C/ACCESS-CM2', 'key1=>value1_en,key2=>value2_en','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'en', 'checksum',NULL,1, NULL,'y', 'OS-C', 'OS-C', NULL, 1,'OS-C','y',1,'2024-07-15T00:00:01Z', 'd08db675-ee1e-48fe-b9e1-b0da27de8f2b')
;
INSERT INTO osc_physrisk.osc_physrisk_hazard.hazard_indicator
	(hazard_indicator_id, "name", name_fullyqualified, description_full, description_short, tags, creation_time, creator_user_id, last_modification_time, last_modifier_user_id, is_deleted, deleter_user_id, deletion_time, culture, checksum, external_id, seq_num, translated_from_id, is_active, creator_user_name, last_modifier_user_name, deleter_user_name, tenant_id, tenant_name, is_published, publisher_id, published_date, hazard_id)
VALUES 
	('2c485594-5220-4e5e-85f0-3e67a09bacd9', 'Days with average temperature above 35°C/CMCC-ESM2', 'Days with average temperature above 35°C/CMCC-ESM2', 'Days with average temperature above 35°C/CMCC-ESM2', 'Days with average temperature above 35°C/CMCC-ESM2', 'key1=>value1_en,key2=>value2_en','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'en', 'checksum',NULL,1, NULL,'y', 'OS-C', 'OS-C', NULL, 1,'OS-C','y',1,'2024-07-15T00:00:01Z', 'd08db675-ee1e-48fe-b9e1-b0da27de8f2b')
;
INSERT INTO osc_physrisk.osc_physrisk_hazard.hazard_indicator
	(hazard_indicator_id, "name", name_fullyqualified, description_full, description_short, tags, creation_time, creator_user_id, last_modification_time, last_modifier_user_id, is_deleted, deleter_user_id, deletion_time, culture, checksum, external_id, seq_num, translated_from_id, is_active, creator_user_name, last_modifier_user_name, deleter_user_name, tenant_id, tenant_name, is_published, publisher_id, published_date, hazard_id)
VALUES 
	('db9a09b3-3386-4081-bf0c-79b6c8ebd38e', 'Days with average temperature above 35°C/CNRM-CM6-1', 'Days with average temperature above 35°C/CNRM-CM6-1', 'Days with average temperature above 35°C/CNRM-CM6-1', 'Days with average temperature above 35°C/CNRM-CM6-1', 'key1=>value1_en,key2=>value2_en','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'en', 'checksum',NULL,1, NULL,'y', 'OS-C', 'OS-C', NULL, 1,'OS-C','y',1,'2024-07-15T00:00:01Z', 'd08db675-ee1e-48fe-b9e1-b0da27de8f2b')
;
INSERT INTO osc_physrisk.osc_physrisk_hazard.hazard_indicator
	(hazard_indicator_id, "name", name_fullyqualified, description_full, description_short, tags, creation_time, creator_user_id, last_modification_time, last_modifier_user_id, is_deleted, deleter_user_id, deletion_time, culture, checksum, external_id, seq_num, translated_from_id, is_active, creator_user_name, last_modifier_user_name, deleter_user_name, tenant_id, tenant_name, is_published, publisher_id, published_date, hazard_id)
VALUES 
	('3f77c47d-9a26-4a3f-a289-ecf56678ec69', 'Days with average temperature above 35°C/MIROC6', 'Days with average temperature above 35°C/MIROC6', 'Days with average temperature above 35°C/MIROC6', 'Days with average temperature above 35°C/MIROC6', 'key1=>value1_en,key2=>value2_en','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'en', 'checksum',NULL,1, NULL,'y', 'OS-C', 'OS-C', NULL, 1,'OS-C','y',1,'2024-07-15T00:00:01Z', 'd08db675-ee1e-48fe-b9e1-b0da27de8f2b')
;
INSERT INTO osc_physrisk.osc_physrisk_hazard.hazard_indicator
	(hazard_indicator_id, "name", name_fullyqualified, description_full, description_short, tags, creation_time, creator_user_id, last_modification_time, last_modifier_user_id, is_deleted, deleter_user_id, deletion_time, culture, checksum, external_id, seq_num, translated_from_id, is_active, creator_user_name, last_modifier_user_name, deleter_user_name, tenant_id, tenant_name, is_published, publisher_id, published_date, hazard_id)
VALUES 
	('f197975a-acea-4514-acbf-35cb070b0b5c', 'Days with average temperature above 35°C/ESM1-2-LR', 'Days with average temperature above 35°C/ESM1-2-LR', 'Days with average temperature above 35°C/ESM1-2-LR', 'Days with average temperature above 35°C/ESM1-2-LR', 'key1=>value1_en,key2=>value2_en','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'en', 'checksum',NULL,1, NULL,'y', 'OS-C', 'OS-C', NULL, 1,'OS-C','y',1,'2024-07-15T00:00:01Z', 'd08db675-ee1e-48fe-b9e1-b0da27de8f2b')
;
INSERT INTO osc_physrisk.osc_physrisk_hazard.hazard_indicator
	(hazard_indicator_id, "name", name_fullyqualified, description_full, description_short, tags, creation_time, creator_user_id, last_modification_time, last_modifier_user_id, is_deleted, deleter_user_id, deletion_time, culture, checksum, external_id, seq_num, translated_from_id, is_active, creator_user_name, last_modifier_user_name, deleter_user_name, tenant_id, tenant_name, is_published, publisher_id, published_date, hazard_id)
VALUES 
	('d4d610b4-060e-4212-9b0c-05fe551a0128', 'Days with average temperature above 35°C/NorESM2-MM', 'Days with average temperature above 35°C/NorESM2-MM', 'Days with average temperature above 35°C/NorESM2-MM', 'Days with average temperature above 35°C/NorESM2-MM', 'key1=>value1_en,key2=>value2_en','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'en', 'checksum',NULL,1, NULL,'y', 'OS-C', 'OS-C', NULL, 1,'OS-C','y',1,'2024-07-15T00:00:01Z', 'd08db675-ee1e-48fe-b9e1-b0da27de8f2b')
;
INSERT INTO osc_physrisk.osc_physrisk_hazard.hazard_indicator
	(hazard_indicator_id, "name", name_fullyqualified, description_full, description_short, tags, creation_time, creator_user_id, last_modification_time, last_modifier_user_id, is_deleted, deleter_user_id, deletion_time, culture, checksum, external_id, seq_num, translated_from_id, is_active, creator_user_name, last_modifier_user_name, deleter_user_name, tenant_id, tenant_name, is_published, publisher_id, published_date, hazard_id)
VALUES 
	('f38a4529-0b9e-4a31-9b16-f6e070a4f001', 'Days with average temperature above 40°C/ACCESS-CM2', 'Days with average temperature above 40°C/ACCESS-CM2', 'Days with average temperature above 40°C/ACCESS-CM2', 'Days with average temperature above 40°C/ACCESS-CM2', 'key1=>value1_en,key2=>value2_en','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'en', 'checksum',NULL,1, NULL,'y', 'OS-C', 'OS-C', NULL, 1,'OS-C','y',1,'2024-07-15T00:00:01Z', 'd08db675-ee1e-48fe-b9e1-b0da27de8f2b')
;
INSERT INTO osc_physrisk.osc_physrisk_hazard.hazard_indicator
	(hazard_indicator_id, "name", name_fullyqualified, description_full, description_short, tags, creation_time, creator_user_id, last_modification_time, last_modifier_user_id, is_deleted, deleter_user_id, deletion_time, culture, checksum, external_id, seq_num, translated_from_id, is_active, creator_user_name, last_modifier_user_name, deleter_user_name, tenant_id, tenant_name, is_published, publisher_id, published_date, hazard_id)
VALUES 
	('bae5ce0d-079c-44c8-87f2-705e13806371', 'Days with average temperature above 40°C/CMCC-ESM2', 'Days with average temperature above 40°C/CMCC-ESM2', 'Days with average temperature above 40°C/CMCC-ESM2', 'Days with average temperature above 40°C/CMCC-ESM2', 'key1=>value1_en,key2=>value2_en','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'en', 'checksum',NULL,1, NULL,'y', 'OS-C', 'OS-C', NULL, 1,'OS-C','y',1,'2024-07-15T00:00:01Z', 'd08db675-ee1e-48fe-b9e1-b0da27de8f2b')
;
INSERT INTO osc_physrisk.osc_physrisk_hazard.hazard_indicator
	(hazard_indicator_id, "name", name_fullyqualified, description_full, description_short, tags, creation_time, creator_user_id, last_modification_time, last_modifier_user_id, is_deleted, deleter_user_id, deletion_time, culture, checksum, external_id, seq_num, translated_from_id, is_active, creator_user_name, last_modifier_user_name, deleter_user_name, tenant_id, tenant_name, is_published, publisher_id, published_date, hazard_id)
VALUES 
	('19049eb2-9270-4b1b-9aea-8e2c610ea6b0', 'Days with average temperature above 40°C/CNRM-CM6-1', 'Days with average temperature above 40°C/CNRM-CM6-1', 'Days with average temperature above 40°C/CNRM-CM6-1', 'Days with average temperature above 40°C/CNRM-CM6-1', 'key1=>value1_en,key2=>value2_en','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'en', 'checksum',NULL,1, NULL,'y', 'OS-C', 'OS-C', NULL, 1,'OS-C','y',1,'2024-07-15T00:00:01Z', 'd08db675-ee1e-48fe-b9e1-b0da27de8f2b')
;
INSERT INTO osc_physrisk.osc_physrisk_hazard.hazard_indicator
	(hazard_indicator_id, "name", name_fullyqualified, description_full, description_short, tags, creation_time, creator_user_id, last_modification_time, last_modifier_user_id, is_deleted, deleter_user_id, deletion_time, culture, checksum, external_id, seq_num, translated_from_id, is_active, creator_user_name, last_modifier_user_name, deleter_user_name, tenant_id, tenant_name, is_published, publisher_id, published_date, hazard_id)
VALUES 
	('a35f8652-5736-4b83-b9ec-2bcd53dd2b75', 'Days with average temperature above 40°C/MIROC6', 'Days with average temperature above 40°C/MIROC6', 'Days with average temperature above 40°C/MIROC6', 'Days with average temperature above 40°C/MIROC6', 'key1=>value1_en,key2=>value2_en','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'en', 'checksum',NULL,1, NULL,'y', 'OS-C', 'OS-C', NULL, 1,'OS-C','y',1,'2024-07-15T00:00:01Z', 'd08db675-ee1e-48fe-b9e1-b0da27de8f2b')
;
INSERT INTO osc_physrisk.osc_physrisk_hazard.hazard_indicator
	(hazard_indicator_id, "name", name_fullyqualified, description_full, description_short, tags, creation_time, creator_user_id, last_modification_time, last_modifier_user_id, is_deleted, deleter_user_id, deletion_time, culture, checksum, external_id, seq_num, translated_from_id, is_active, creator_user_name, last_modifier_user_name, deleter_user_name, tenant_id, tenant_name, is_published, publisher_id, published_date, hazard_id)
VALUES 
	('6a23417d-27fc-49f5-9147-43f9a761e13d', 'Days with average temperature above 40°C/ESM1-2-LR', 'Days with average temperature above 40°C/ESM1-2-LR', 'Days with average temperature above 40°C/ESM1-2-LR', 'Days with average temperature above 40°C/ESM1-2-LR', 'key1=>value1_en,key2=>value2_en','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'en', 'checksum',NULL,1, NULL,'y', 'OS-C', 'OS-C', NULL, 1,'OS-C','y',1,'2024-07-15T00:00:01Z', 'd08db675-ee1e-48fe-b9e1-b0da27de8f2b')
;
INSERT INTO osc_physrisk.osc_physrisk_hazard.hazard_indicator
	(hazard_indicator_id, "name", name_fullyqualified, description_full, description_short, tags, creation_time, creator_user_id, last_modification_time, last_modifier_user_id, is_deleted, deleter_user_id, deletion_time, culture, checksum, external_id, seq_num, translated_from_id, is_active, creator_user_name, last_modifier_user_name, deleter_user_name, tenant_id, tenant_name, is_published, publisher_id, published_date, hazard_id)
VALUES 
	('9fd1aafe-d942-4dd7-8b5f-cc3983d12616', 'Days with average temperature above 40°C/NorESM2-MM', 'Days with average temperature above 40°C/NorESM2-MM', 'Days with average temperature above 40°C/NorESM2-MM', 'Days with average temperature above 40°C/NorESM2-MM', 'key1=>value1_en,key2=>value2_en','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'en', 'checksum',NULL,1, NULL,'y', 'OS-C', 'OS-C', NULL, 1,'OS-C','y',1,'2024-07-15T00:00:01Z', 'd08db675-ee1e-48fe-b9e1-b0da27de8f2b')
;
INSERT INTO osc_physrisk.osc_physrisk_hazard.hazard_indicator
	(hazard_indicator_id, "name", name_fullyqualified, description_full, description_short, tags, creation_time, creator_user_id, last_modification_time, last_modifier_user_id, is_deleted, deleter_user_id, deletion_time, culture, checksum, external_id, seq_num, translated_from_id, is_active, creator_user_name, last_modifier_user_name, deleter_user_name, tenant_id, tenant_name, is_published, publisher_id, published_date, hazard_id)
VALUES 
	('801009ff-7135-4252-a956-8f32cd9fb17d', 'Days with average temperature above 45°C/ACCESS-CM2', 'Days with average temperature above 45°C/ACCESS-CM2', 'Days with average temperature above 45°C/ACCESS-CM2', 'Days with average temperature above 45°C/ACCESS-CM2', 'key1=>value1_en,key2=>value2_en','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'en', 'checksum',NULL,1, NULL,'y', 'OS-C', 'OS-C', NULL, 1,'OS-C','y',1,'2024-07-15T00:00:01Z', 'd08db675-ee1e-48fe-b9e1-b0da27de8f2b')
;
INSERT INTO osc_physrisk.osc_physrisk_hazard.hazard_indicator
	(hazard_indicator_id, "name", name_fullyqualified, description_full, description_short, tags, creation_time, creator_user_id, last_modification_time, last_modifier_user_id, is_deleted, deleter_user_id, deletion_time, culture, checksum, external_id, seq_num, translated_from_id, is_active, creator_user_name, last_modifier_user_name, deleter_user_name, tenant_id, tenant_name, is_published, publisher_id, published_date, hazard_id)
VALUES 
	('ea8be4c4-a3f0-441f-b1cd-b4de8b9e885c', 'Days with average temperature above 45°C/CMCC-ESM2', 'Days with average temperature above 45°C/CMCC-ESM2', 'Days with average temperature above 45°C/CMCC-ESM2', 'Days with average temperature above 45°C/CMCC-ESM2', 'key1=>value1_en,key2=>value2_en','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'en', 'checksum',NULL,1, NULL,'y', 'OS-C', 'OS-C', NULL, 1,'OS-C','y',1,'2024-07-15T00:00:01Z', 'd08db675-ee1e-48fe-b9e1-b0da27de8f2b')
;
INSERT INTO osc_physrisk.osc_physrisk_hazard.hazard_indicator
	(hazard_indicator_id, "name", name_fullyqualified, description_full, description_short, tags, creation_time, creator_user_id, last_modification_time, last_modifier_user_id, is_deleted, deleter_user_id, deletion_time, culture, checksum, external_id, seq_num, translated_from_id, is_active, creator_user_name, last_modifier_user_name, deleter_user_name, tenant_id, tenant_name, is_published, publisher_id, published_date, hazard_id)
VALUES 
	('69053bee-35fd-45bd-9dd1-8fe485ae7715', 'Days with average temperature above 45°C/CNRM-CM6-1', 'Days with average temperature above 45°C/CNRM-CM6-1', 'Days with average temperature above 45°C/CNRM-CM6-1', 'Days with average temperature above 45°C/CNRM-CM6-1', 'key1=>value1_en,key2=>value2_en','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'en', 'checksum',NULL,1, NULL,'y', 'OS-C', 'OS-C', NULL, 1,'OS-C','y',1,'2024-07-15T00:00:01Z', 'd08db675-ee1e-48fe-b9e1-b0da27de8f2b')
;
INSERT INTO osc_physrisk.osc_physrisk_hazard.hazard_indicator
	(hazard_indicator_id, "name", name_fullyqualified, description_full, description_short, tags, creation_time, creator_user_id, last_modification_time, last_modifier_user_id, is_deleted, deleter_user_id, deletion_time, culture, checksum, external_id, seq_num, translated_from_id, is_active, creator_user_name, last_modifier_user_name, deleter_user_name, tenant_id, tenant_name, is_published, publisher_id, published_date, hazard_id)
VALUES 
	('1f48f1f2-03ab-43b8-9185-038fd656ebcd', 'Days with average temperature above 45°C/MIROC6', 'Days with average temperature above 45°C/MIROC6', 'Days with average temperature above 45°C/MIROC6', 'Days with average temperature above 45°C/MIROC6', 'key1=>value1_en,key2=>value2_en','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'en', 'checksum',NULL,1, NULL,'y', 'OS-C', 'OS-C', NULL, 1,'OS-C','y',1,'2024-07-15T00:00:01Z', 'd08db675-ee1e-48fe-b9e1-b0da27de8f2b')
;
INSERT INTO osc_physrisk.osc_physrisk_hazard.hazard_indicator
	(hazard_indicator_id, "name", name_fullyqualified, description_full, description_short, tags, creation_time, creator_user_id, last_modification_time, last_modifier_user_id, is_deleted, deleter_user_id, deletion_time, culture, checksum, external_id, seq_num, translated_from_id, is_active, creator_user_name, last_modifier_user_name, deleter_user_name, tenant_id, tenant_name, is_published, publisher_id, published_date, hazard_id)
VALUES 
	('8960452e-86b1-4134-b03d-5bea69079fcc', 'Days with average temperature above 45°C/ESM1-2-LR', 'Days with average temperature above 45°C/ESM1-2-LR', 'Days with average temperature above 45°C/ESM1-2-LR', 'Days with average temperature above 45°C/ESM1-2-LR', 'key1=>value1_en,key2=>value2_en','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'en', 'checksum',NULL,1, NULL,'y', 'OS-C', 'OS-C', NULL, 1,'OS-C','y',1,'2024-07-15T00:00:01Z', 'd08db675-ee1e-48fe-b9e1-b0da27de8f2b')
;
INSERT INTO osc_physrisk.osc_physrisk_hazard.hazard_indicator
	(hazard_indicator_id, "name", name_fullyqualified, description_full, description_short, tags, creation_time, creator_user_id, last_modification_time, last_modifier_user_id, is_deleted, deleter_user_id, deletion_time, culture, checksum, external_id, seq_num, translated_from_id, is_active, creator_user_name, last_modifier_user_name, deleter_user_name, tenant_id, tenant_name, is_published, publisher_id, published_date, hazard_id)
VALUES 
	('3676521f-16ee-4ce6-b8b4-d00aaba44281', 'Days with average temperature above 45°C/NorESM2-MM', 'Days with average temperature above 45°C/NorESM2-MM', 'Days with average temperature above 45°C/NorESM2-MM', 'Days with average temperature above 45°C/NorESM2-MM', 'key1=>value1_en,key2=>value2_en','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'en', 'checksum',NULL,1, NULL,'y', 'OS-C', 'OS-C', NULL, 1,'OS-C','y',1,'2024-07-15T00:00:01Z', 'd08db675-ee1e-48fe-b9e1-b0da27de8f2b')
;
INSERT INTO osc_physrisk.osc_physrisk_hazard.hazard_indicator
	(hazard_indicator_id, "name", name_fullyqualified, description_full, description_short, tags, creation_time, creator_user_id, last_modification_time, last_modifier_user_id, is_deleted, deleter_user_id, deletion_time, culture, checksum, external_id, seq_num, translated_from_id, is_active, creator_user_name, last_modifier_user_name, deleter_user_name, tenant_id, tenant_name, is_published, publisher_id, published_date, hazard_id)
VALUES 
	('8bfe29fb-85e3-4497-b340-ad3f4eadfc3f', 'Days with average temperature above 50°C/ACCESS-CM2', 'Days with average temperature above 50°C/ACCESS-CM2', 'Days with average temperature above 50°C/ACCESS-CM2', 'Days with average temperature above 50°C/ACCESS-CM2', 'key1=>value1_en,key2=>value2_en','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'en', 'checksum',NULL,1, NULL,'y', 'OS-C', 'OS-C', NULL, 1,'OS-C','y',1,'2024-07-15T00:00:01Z', 'd08db675-ee1e-48fe-b9e1-b0da27de8f2b')
;
INSERT INTO osc_physrisk.osc_physrisk_hazard.hazard_indicator
	(hazard_indicator_id, "name", name_fullyqualified, description_full, description_short, tags, creation_time, creator_user_id, last_modification_time, last_modifier_user_id, is_deleted, deleter_user_id, deletion_time, culture, checksum, external_id, seq_num, translated_from_id, is_active, creator_user_name, last_modifier_user_name, deleter_user_name, tenant_id, tenant_name, is_published, publisher_id, published_date, hazard_id)
VALUES 
	('fb684a2f-ce48-4d02-ba49-9c5cd49654df', 'Days with average temperature above 50°C/CMCC-ESM2', 'Days with average temperature above 50°C/CMCC-ESM2', 'Days with average temperature above 50°C/CMCC-ESM2', 'Days with average temperature above 50°C/CMCC-ESM2', 'key1=>value1_en,key2=>value2_en','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'en', 'checksum',NULL,1, NULL,'y', 'OS-C', 'OS-C', NULL, 1,'OS-C','y',1,'2024-07-15T00:00:01Z', 'd08db675-ee1e-48fe-b9e1-b0da27de8f2b')
;
INSERT INTO osc_physrisk.osc_physrisk_hazard.hazard_indicator
	(hazard_indicator_id, "name", name_fullyqualified, description_full, description_short, tags, creation_time, creator_user_id, last_modification_time, last_modifier_user_id, is_deleted, deleter_user_id, deletion_time, culture, checksum, external_id, seq_num, translated_from_id, is_active, creator_user_name, last_modifier_user_name, deleter_user_name, tenant_id, tenant_name, is_published, publisher_id, published_date, hazard_id)
VALUES 
	('56fb7c3a-7d9c-41d2-ab1d-37bab5544748', 'Days with average temperature above 50°C/CNRM-CM6-1', 'Days with average temperature above 50°C/CNRM-CM6-1', 'Days with average temperature above 50°C/CNRM-CM6-1', 'Days with average temperature above 50°C/CNRM-CM6-1', 'key1=>value1_en,key2=>value2_en','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'en', 'checksum',NULL,1, NULL,'y', 'OS-C', 'OS-C', NULL, 1,'OS-C','y',1,'2024-07-15T00:00:01Z', 'd08db675-ee1e-48fe-b9e1-b0da27de8f2b')
;
INSERT INTO osc_physrisk.osc_physrisk_hazard.hazard_indicator
	(hazard_indicator_id, "name", name_fullyqualified, description_full, description_short, tags, creation_time, creator_user_id, last_modification_time, last_modifier_user_id, is_deleted, deleter_user_id, deletion_time, culture, checksum, external_id, seq_num, translated_from_id, is_active, creator_user_name, last_modifier_user_name, deleter_user_name, tenant_id, tenant_name, is_published, publisher_id, published_date, hazard_id)
VALUES 
	('12a84609-f114-4975-a90a-aed809452897', 'Days with average temperature above 50°C/MIROC6', 'Days with average temperature above 50°C/MIROC6', 'Days with average temperature above 50°C/MIROC6', 'Days with average temperature above 50°C/MIROC6', 'key1=>value1_en,key2=>value2_en','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'en', 'checksum',NULL,1, NULL,'y', 'OS-C', 'OS-C', NULL, 1,'OS-C','y',1,'2024-07-15T00:00:01Z', 'd08db675-ee1e-48fe-b9e1-b0da27de8f2b')
;
INSERT INTO osc_physrisk.osc_physrisk_hazard.hazard_indicator
	(hazard_indicator_id, "name", name_fullyqualified, description_full, description_short, tags, creation_time, creator_user_id, last_modification_time, last_modifier_user_id, is_deleted, deleter_user_id, deletion_time, culture, checksum, external_id, seq_num, translated_from_id, is_active, creator_user_name, last_modifier_user_name, deleter_user_name, tenant_id, tenant_name, is_published, publisher_id, published_date, hazard_id)
VALUES 
	('22ce6754-f68b-4f96-b083-8bb2a5c4deb6', 'Days with average temperature above 50°C/ESM1-2-LR', 'Days with average temperature above 50°C/ESM1-2-LR', 'Days with average temperature above 50°C/ESM1-2-LR', 'Days with average temperature above 50°C/ESM1-2-LR', 'key1=>value1_en,key2=>value2_en','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'en', 'checksum',NULL,1, NULL,'y', 'OS-C', 'OS-C', NULL, 1,'OS-C','y',1,'2024-07-15T00:00:01Z', 'd08db675-ee1e-48fe-b9e1-b0da27de8f2b')
;
INSERT INTO osc_physrisk.osc_physrisk_hazard.hazard_indicator
	(hazard_indicator_id, "name", name_fullyqualified, description_full, description_short, tags, creation_time, creator_user_id, last_modification_time, last_modifier_user_id, is_deleted, deleter_user_id, deletion_time, culture, checksum, external_id, seq_num, translated_from_id, is_active, creator_user_name, last_modifier_user_name, deleter_user_name, tenant_id, tenant_name, is_published, publisher_id, published_date, hazard_id)
VALUES 
	('ec4c8b74-816a-4260-8321-fc03b6850c37', 'Days with average temperature above 50°C/NorESM2-MM', 'Days with average temperature above 50°C/NorESM2-MM', 'Days with average temperature above 50°C/NorESM2-MM', 'Days with average temperature above 50°C/NorESM2-MM', 'key1=>value1_en,key2=>value2_en','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'en', 'checksum',NULL,1, NULL,'y', 'OS-C', 'OS-C', NULL, 1,'OS-C','y',1,'2024-07-15T00:00:01Z', 'd08db675-ee1e-48fe-b9e1-b0da27de8f2b')
;
INSERT INTO osc_physrisk.osc_physrisk_hazard.hazard_indicator
	(hazard_indicator_id, "name", name_fullyqualified, description_full, description_short, tags, creation_time, creator_user_id, last_modification_time, last_modifier_user_id, is_deleted, deleter_user_id, deletion_time, culture, checksum, external_id, seq_num, translated_from_id, is_active, creator_user_name, last_modifier_user_name, deleter_user_name, tenant_id, tenant_name, is_published, publisher_id, published_date, hazard_id)
VALUES 
	('7f06ac9f-f6ac-467a-9a88-d14a91465141', 'Days with average temperature above 55°C/ACCESS-CM2', 'Days with average temperature above 55°C/ACCESS-CM2', 'Days with average temperature above 55°C/ACCESS-CM2', 'Days with average temperature above 55°C/ACCESS-CM2', 'key1=>value1_en,key2=>value2_en','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'en', 'checksum',NULL,1, NULL,'y', 'OS-C', 'OS-C', NULL, 1,'OS-C','y',1,'2024-07-15T00:00:01Z', 'd08db675-ee1e-48fe-b9e1-b0da27de8f2b')
;
INSERT INTO osc_physrisk.osc_physrisk_hazard.hazard_indicator
	(hazard_indicator_id, "name", name_fullyqualified, description_full, description_short, tags, creation_time, creator_user_id, last_modification_time, last_modifier_user_id, is_deleted, deleter_user_id, deletion_time, culture, checksum, external_id, seq_num, translated_from_id, is_active, creator_user_name, last_modifier_user_name, deleter_user_name, tenant_id, tenant_name, is_published, publisher_id, published_date, hazard_id)
VALUES 
	('c9edfa0d-5450-4de5-8680-4a26874cac2d', 'Days with average temperature above 55°C/CMCC-ESM2', 'Days with average temperature above 55°C/CMCC-ESM2', 'Days with average temperature above 55°C/CMCC-ESM2', 'Days with average temperature above 55°C/CMCC-ESM2', 'key1=>value1_en,key2=>value2_en','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'en', 'checksum',NULL,1, NULL,'y', 'OS-C', 'OS-C', NULL, 1,'OS-C','y',1,'2024-07-15T00:00:01Z', 'd08db675-ee1e-48fe-b9e1-b0da27de8f2b')
;
INSERT INTO osc_physrisk.osc_physrisk_hazard.hazard_indicator
	(hazard_indicator_id, "name", name_fullyqualified, description_full, description_short, tags, creation_time, creator_user_id, last_modification_time, last_modifier_user_id, is_deleted, deleter_user_id, deletion_time, culture, checksum, external_id, seq_num, translated_from_id, is_active, creator_user_name, last_modifier_user_name, deleter_user_name, tenant_id, tenant_name, is_published, publisher_id, published_date, hazard_id)
VALUES 
	('431a89ea-17bd-4dee-a2af-9ba18e737fe5', 'Days with average temperature above 55°C/CNRM-CM6-1', 'Days with average temperature above 55°C/CNRM-CM6-1', 'Days with average temperature above 55°C/CNRM-CM6-1', 'Days with average temperature above 55°C/CNRM-CM6-1', 'key1=>value1_en,key2=>value2_en','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'en', 'checksum',NULL,1, NULL,'y', 'OS-C', 'OS-C', NULL, 1,'OS-C','y',1,'2024-07-15T00:00:01Z', 'd08db675-ee1e-48fe-b9e1-b0da27de8f2b')
;
INSERT INTO osc_physrisk.osc_physrisk_hazard.hazard_indicator
	(hazard_indicator_id, "name", name_fullyqualified, description_full, description_short, tags, creation_time, creator_user_id, last_modification_time, last_modifier_user_id, is_deleted, deleter_user_id, deletion_time, culture, checksum, external_id, seq_num, translated_from_id, is_active, creator_user_name, last_modifier_user_name, deleter_user_name, tenant_id, tenant_name, is_published, publisher_id, published_date, hazard_id)
VALUES 
	('158038b5-1f09-471a-ac5b-85aae409148b', 'Days with average temperature above 55°C/MIROC6', 'Days with average temperature above 55°C/MIROC6', 'Days with average temperature above 55°C/MIROC6', 'Days with average temperature above 55°C/MIROC6', 'key1=>value1_en,key2=>value2_en','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'en', 'checksum',NULL,1, NULL,'y', 'OS-C', 'OS-C', NULL, 1,'OS-C','y',1,'2024-07-15T00:00:01Z', 'd08db675-ee1e-48fe-b9e1-b0da27de8f2b')
;
INSERT INTO osc_physrisk.osc_physrisk_hazard.hazard_indicator
	(hazard_indicator_id, "name", name_fullyqualified, description_full, description_short, tags, creation_time, creator_user_id, last_modification_time, last_modifier_user_id, is_deleted, deleter_user_id, deletion_time, culture, checksum, external_id, seq_num, translated_from_id, is_active, creator_user_name, last_modifier_user_name, deleter_user_name, tenant_id, tenant_name, is_published, publisher_id, published_date, hazard_id)
VALUES 
	('a5810ce7-eec7-4881-a182-33e0e3156a26', 'Days with average temperature above 55°C/ESM1-2-LR', 'Days with average temperature above 55°C/ESM1-2-LR', 'Days with average temperature above 55°C/ESM1-2-LR', 'Days with average temperature above 55°C/ESM1-2-LR', 'key1=>value1_en,key2=>value2_en','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'en', 'checksum',NULL,1, NULL,'y', 'OS-C', 'OS-C', NULL, 1,'OS-C','y',1,'2024-07-15T00:00:01Z', 'd08db675-ee1e-48fe-b9e1-b0da27de8f2b')
;
INSERT INTO osc_physrisk.osc_physrisk_hazard.hazard_indicator
	(hazard_indicator_id, "name", name_fullyqualified, description_full, description_short, tags, creation_time, creator_user_id, last_modification_time, last_modifier_user_id, is_deleted, deleter_user_id, deletion_time, culture, checksum, external_id, seq_num, translated_from_id, is_active, creator_user_name, last_modifier_user_name, deleter_user_name, tenant_id, tenant_name, is_published, publisher_id, published_date, hazard_id)
VALUES 
	('41705043-bdad-4d2d-ab2b-3d884375b52d', 'Days with average temperature above 55°C/NorESM2-MM', 'Days with average temperature above 55°C/NorESM2-MM', 'Days with average temperature above 55°C/NorESM2-MM', 'Days with average temperature above 55°C/NorESM2-MM', 'key1=>value1_en,key2=>value2_en','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'en', 'checksum',NULL,1, NULL,'y', 'OS-C', 'OS-C', NULL, 1,'OS-C','y',1,'2024-07-15T00:00:01Z', 'd08db675-ee1e-48fe-b9e1-b0da27de8f2b')
;

-- DATA IN ENGLISH ENDS
-- DATA IN FRENCH STARTS
INSERT INTO osc_physrisk.osc_physrisk_scenario.dim_scenario_type
	(scenario_type_id, description_full, description_short, name_fullyqualified, "name", tags, creation_time, creator_user_id, last_modification_time, last_modifier_user_id, is_deleted, deleter_user_id, deletion_time, culture, checksum, seq_num, translated_from_id, is_active, creator_user_name, last_modifier_user_name, deleter_user_name, is_published, publisher_id, published_date)
VALUES 
	(10, 'Inconnu/Aucun selection', 'Inconnu/Aucun selection', 'Inconnu/Aucun selection', 'Inconnu/Aucun selection','key1=>value1_fr,key2=>value2_fr','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'fr', 'checksum',1,-1, 'y', 'OS-C', 'OS-C', 'OS-C','y', 1,'2024-07-15T00:00:01Z')
;
INSERT INTO osc_physrisk.osc_physrisk_scenario.dim_scenario_type
	(scenario_type_id, description_full, description_short, name_fullyqualified, "name", tags, creation_time, creator_user_id, last_modification_time, last_modifier_user_id, is_deleted, deleter_user_id, deletion_time, culture, checksum, seq_num, translated_from_id, is_active, creator_user_name, last_modifier_user_name, deleter_user_name, is_published, publisher_id, published_date)
VALUES 
	(11, 'Historique (avant 2014). Voir "Scénarios d''émissions et de réchauffement futurs dans le sixième Rapport d''évaluation du GIEC" (https://www.ipcc.ch/report/ar6/wg1/downloads/report/IPCC_AR6_WG1_SPM_French.pdf).', 'Historique (avant 2014)', 'Historique (avant 2014)', 'Historique (avant 2014)','key1=>value1_fr,key2=>value2_fr','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'fr', 'checksum',1,0, 'y', 'OS-C', 'OS-C', 'OS-C','y', 1,'2024-07-15T00:00:01Z')
;
INSERT INTO osc_physrisk.osc_physrisk_scenario.dim_scenario_type
	(scenario_type_id, description_full, description_short, name_fullyqualified, "name", tags, creation_time, creator_user_id, last_modification_time, last_modifier_user_id, is_deleted, deleter_user_id, deletion_time, culture, checksum, seq_num, translated_from_id, is_active, creator_user_name, last_modifier_user_name, deleter_user_name, is_published, publisher_id, published_date)
VALUES 
	(12, 'SSP1-1,9 — émissions de GES en baisse dès 2025, zéro émission nette de CO2 avant 2050, émissions négatives ensuite. Voir "Scénarios d''émissions et de réchauffement futurs dans le sixième Rapport d''évaluation du GIEC" (https://www.ipcc.ch/report/ar6/wg1/downloads/report/IPCC_AR6_WG1_SPM_French.pdf).', 'SSP1-1,9', 'SSP1-1,9', 'SSP1-1,9','key1=>value1_fr,key2=>value2_fr','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'fr', 'checksum',1,1, 'y', 'OS-C', 'OS-C', 'OS-C','y', 1,'2024-07-15T00:00:01Z')
;
INSERT INTO osc_physrisk.osc_physrisk_scenario.dim_scenario_type
	(scenario_type_id, description_full, description_short, name_fullyqualified, "name", tags, creation_time, creator_user_id, last_modification_time, last_modifier_user_id, is_deleted, deleter_user_id, deletion_time, culture, checksum, seq_num, translated_from_id, is_active, creator_user_name, last_modifier_user_name, deleter_user_name, is_published, publisher_id, published_date)
VALUES 
	(13, 'SSP1-2,6 — similaire au précédent, mais le zéro émission nette de CO2 est atteint après 2050. Voir "Scénarios d''émissions et de réchauffement futurs dans le sixième Rapport d''évaluation du GIEC" (https://www.ipcc.ch/report/ar6/wg1/downloads/report/IPCC_AR6_WG1_SPM_French.pdf).', 'SSP1-2,6', 'SSP1-2,6', 'SSP1-2,6','key1=>value1_fr,key2=>value2_fr','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'fr', 'checksum',1,2, 'y', 'OS-C', 'OS-C', 'OS-C','y', 1,'2024-07-15T00:00:01Z')
;
INSERT INTO osc_physrisk.osc_physrisk_scenario.dim_scenario_type
	(scenario_type_id, description_full, description_short, name_fullyqualified, "name", tags, creation_time, creator_user_id, last_modification_time, last_modifier_user_id, is_deleted, deleter_user_id, deletion_time, culture, checksum, seq_num, translated_from_id, is_active, creator_user_name, last_modifier_user_name, deleter_user_name, is_published, publisher_id, published_date)
VALUES 
	(14, 'SSP2-4,5 — maintien des émissions courantes jusqu''en 2050, division par quatre d''ici 2100. Voir "Scénarios d''émissions et de réchauffement futurs dans le sixième Rapport d''évaluation du GIEC" (https://www.ipcc.ch/report/ar6/wg1/downloads/report/IPCC_AR6_WG1_SPM_French.pdf).', 'SSP2-4,5', 'SSP2-4,5', 'SSP2-4,5','key1=>value1_fr,key2=>value2_fr','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'fr', 'checksum',1,3, 'y', 'OS-C', 'OS-C', 'OS-C','y', 1,'2024-07-15T00:00:01Z')
;
INSERT INTO osc_physrisk.osc_physrisk_scenario.dim_scenario_type
	(scenario_type_id, description_full, description_short, name_fullyqualified, "name", tags, creation_time, creator_user_id, last_modification_time, last_modifier_user_id, is_deleted, deleter_user_id, deletion_time, culture, checksum, seq_num, translated_from_id, is_active, creator_user_name, last_modifier_user_name, deleter_user_name, is_published, publisher_id, published_date)
VALUES 
	(15, 'SSP3-7,0 — doublement des émissions de GES en 2100. Voir "Scénarios d''émissions et de réchauffement futurs dans le sixième Rapport d''évaluation du GIEC" (https://www.ipcc.ch/report/ar6/wg1/downloads/report/IPCC_AR6_WG1_SPM_French.pdf).', 'SSP3-7,0', 'SSP3-7,0', 'SSP3-7,0','key1=>value1_fr,key2=>value2_fr','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'fr', 'checksum',1,4, 'y', 'OS-C', 'OS-C', 'OS-C','y', 1,'2024-07-15T00:00:01Z')
;
INSERT INTO osc_physrisk.osc_physrisk_scenario.dim_scenario_type
	(scenario_type_id, description_full, description_short, name_fullyqualified, "name", tags, creation_time, creator_user_id, last_modification_time, last_modifier_user_id, is_deleted, deleter_user_id, deletion_time, culture, checksum, seq_num, translated_from_id, is_active, creator_user_name, last_modifier_user_name, deleter_user_name, is_published, publisher_id, published_date)
VALUES 
	(16, 'SSP5-8,5 — émissions de GES en forte augmentation, doublement en 2050. Voir "Scénarios d''émissions et de réchauffement futurs dans le sixième Rapport d''évaluation du GIEC" (https://www.ipcc.ch/report/ar6/wg1/downloads/report/IPCC_AR6_WG1_SPM_French.pdf).', 'SSP5-8,5', 'SSP5-8,5', 'SSP5-8,5','key1=>value1_fr,key2=>value2_fr','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'fr', 'checksum',1,5, 'y', 'OS-C', 'OS-C', 'OS-C','y', 1,'2024-07-15T00:00:01Z')
;
INSERT INTO osc_physrisk.osc_physrisk_scenario.dim_scenario_type
	(scenario_type_id, description_full, description_short, name_fullyqualified, "name", tags, creation_time, creator_user_id, last_modification_time, last_modifier_user_id, is_deleted, deleter_user_id, deletion_time, culture, checksum, seq_num, translated_from_id, is_active, creator_user_name, last_modifier_user_name, deleter_user_name, is_published, publisher_id, published_date)
VALUES 
	(17, 'RCP2.6 - le scénario d''émissions faibles, nous présente un futur où nous limitons les changements climatiques d''origine humaine. Le maximum des émissions de carbone est atteint rapidement, suivi d''une réduction qui mène vers une valeur presque nulle bien avant la fin du siècle. Voir « Scénarios d''émissions : les RCP » (https://donneesclimatiques.ca/interactive/scenarios-demissions-les-rcp/)', 'RCP2.6', 'RCP2.6', 'RCP2.6','key1=>value1_fr,key2=>value2_fr','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'fr', 'checksum',1,6, 'y', 'OS-C', 'OS-C', 'OS-C','y', 1,'2024-07-15T00:00:01Z')
;
INSERT INTO osc_physrisk.osc_physrisk_scenario.dim_scenario_type
	(scenario_type_id, description_full, description_short, name_fullyqualified, "name", tags, creation_time, creator_user_id, last_modification_time, last_modifier_user_id, is_deleted, deleter_user_id, deletion_time, culture, checksum, seq_num, translated_from_id, is_active, creator_user_name, last_modifier_user_name, deleter_user_name, is_published, publisher_id, published_date)
VALUES 
	(18, 'RCP4.5 - un scénario d''émissions modérées, nous présente un futur où nous incluons des mesures pour limiter les changements climatiques d''origine humaine. Ce scénario exige que les émissions mondiales de carbone soient stabilisées d''ici la fin du siècle. Voir « Scénarios d''émissions : les RCP » (https://donneesclimatiques.ca/interactive/scenarios-demissions-les-rcp/)', 'RCP4.5', 'RCP4.5', 'RCP4.5','key1=>value1_fr,key2=>value2_fr','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'fr', 'checksum',1,7, 'y', 'OS-C', 'OS-C', 'OS-C','y', 1,'2024-07-15T00:00:01Z')
;
INSERT INTO osc_physrisk.osc_physrisk_scenario.dim_scenario_type
	(scenario_type_id, description_full, description_short, name_fullyqualified, "name", tags, creation_time, creator_user_id, last_modification_time, last_modifier_user_id, is_deleted, deleter_user_id, deletion_time, culture, checksum, seq_num, translated_from_id, is_active, creator_user_name, last_modifier_user_name, deleter_user_name, is_published, publisher_id, published_date)
VALUES 
	(19, 'RCP6 -  Voir « Scénarios d''émissions : les RCP » (https://donneesclimatiques.ca/interactive/scenarios-demissions-les-rcp/)', 'RCP6', 'RCP6', 'RCP6','key1=>value1_fr,key2=>value2_fr','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'fr', 'checksum',1,8, 'y', 'OS-C', 'OS-C', 'OS-C','y', 1,'2024-07-15T00:00:01Z')
;
INSERT INTO osc_physrisk.osc_physrisk_scenario.dim_scenario_type
	(scenario_type_id, description_full, description_short, name_fullyqualified, "name", tags, creation_time, creator_user_id, last_modification_time, last_modifier_user_id, is_deleted, deleter_user_id, deletion_time, culture, checksum, seq_num, translated_from_id, is_active, creator_user_name, last_modifier_user_name, deleter_user_name, is_published, publisher_id, published_date)
VALUES 
	(20, 'RCP8.5 - le scénario d''émissions élevées, nous présente un futur où peu de restrictions aux émissions ont été mises en place. Les émissions continuent d''augmenter rapidement au cours de ce siècle, et se stabilisent seulement après 2250. Voir « Scénarios d''émissions : les RCP » (https://donneesclimatiques.ca/interactive/scenarios-demissions-les-rcp/)', 'RCP8.5', 'RCP8.5', 'RCP8.5','key1=>value1_fr,key2=>value2_fr','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'fr', 'checksum',1,9, 'y', 'OS-C', 'OS-C', 'OS-C','y', 1,'2024-07-15T00:00:01Z')
;
-- DATA IN FRENCH ENDS
-- DATA IN SPANISH BEGINS
INSERT INTO osc_physrisk.osc_physrisk_scenario.dim_scenario_type
	(scenario_type_id, description_full, description_short, name_fullyqualified, "name", tags, creation_time, creator_user_id, last_modification_time, last_modifier_user_id, is_deleted, deleter_user_id, deletion_time, culture, checksum, seq_num, translated_from_id, is_active, creator_user_name, last_modifier_user_name, deleter_user_name, is_published, publisher_id, published_date)
VALUES 
	(21, 'Desconocido/no seleccionado', 'Desconocido/no seleccionado', 'Desconocido/no seleccionado', 'Desconocido/no seleccionado','key1=>value1_es,key2=>value2_es','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'es', 'checksum',1,-1, 'y', 'OS-C', 'OS-C', 'OS-C','y', 1,'2024-07-15T00:00:01Z')
;
INSERT INTO osc_physrisk.osc_physrisk_scenario.dim_scenario_type
	(scenario_type_id, description_full, description_short, name_fullyqualified, "name", tags, creation_time, creator_user_id, last_modification_time, last_modifier_user_id, is_deleted, deleter_user_id, deletion_time, culture, checksum, seq_num, translated_from_id, is_active, creator_user_name, last_modifier_user_name, deleter_user_name, is_published, publisher_id, published_date)
VALUES 
	(22, 'Histórico (antes 2014). Ver "El Grupo Intergubernamental de Expertos sobre el Cambio Climático (IPCC)" (https://www.ipcc.ch/languages-2/spanish/).', 'Histórico (antes 2014)', 'Histórico (antes 2014)', 'Histórico (antes 2014)','key1=>value1_es,key2=>value2_es','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'es', 'checksum',1,0, 'y', 'OS-C', 'OS-C', 'OS-C','y', 1,'2024-07-15T00:00:01Z')
;
INSERT INTO osc_physrisk.osc_physrisk_scenario.dim_scenario_type
	(scenario_type_id, description_full, description_short, name_fullyqualified, "name", tags, creation_time, creator_user_id, last_modification_time, last_modifier_user_id, is_deleted, deleter_user_id, deletion_time, culture, checksum, seq_num, translated_from_id, is_active, creator_user_name, last_modifier_user_name, deleter_user_name, is_published, publisher_id, published_date)
VALUES 
	(23, 'SSP1-1.9 — Las trayectorias socioeconómicas compartidas (SSP, por sus siglas en inglés) son escenarios de cambios socioeconómicos globales proyectados hasta 2100. Ver "El Grupo Intergubernamental de Expertos sobre el Cambio Climático (IPCC)" (https://www.ipcc.ch/languages-2/spanish/).', 'SSP1-1,9', 'SSP1-1,9', 'SSP1-1,9','key1=>value1_es,key2=>value2_es','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'es', 'checksum',1,1, 'y', 'OS-C', 'OS-C', 'OS-C','y', 1,'2024-07-15T00:00:01Z')
;
INSERT INTO osc_physrisk.osc_physrisk_scenario.dim_scenario_type
	(scenario_type_id, description_full, description_short, name_fullyqualified, "name", tags, creation_time, creator_user_id, last_modification_time, last_modifier_user_id, is_deleted, deleter_user_id, deletion_time, culture, checksum, seq_num, translated_from_id, is_active, creator_user_name, last_modifier_user_name, deleter_user_name, is_published, publisher_id, published_date)
VALUES 
	(24, 'SSP1-2.6 - Las trayectorias socioeconómicas compartidas (SSP, por sus siglas en inglés) son escenarios de cambios socioeconómicos globales proyectados hasta 2100. Ver "El Grupo Intergubernamental de Expertos sobre el Cambio Climático (IPCC)" (https://www.ipcc.ch/languages-2/spanish/).', 'SSP1-2.6', 'SSP1-2.6', 'SSP1-2.6','key1=>value1_es,key2=>value2_es','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'es', 'checksum',1,2, 'y', 'OS-C', 'OS-C', 'OS-C','y', 1,'2024-07-15T00:00:01Z')
;
INSERT INTO osc_physrisk.osc_physrisk_scenario.dim_scenario_type
	(scenario_type_id, description_full, description_short, name_fullyqualified, "name",tags,  creation_time, creator_user_id, last_modification_time, last_modifier_user_id, is_deleted, deleter_user_id, deletion_time, culture, checksum, seq_num, translated_from_id, is_active, creator_user_name, last_modifier_user_name, deleter_user_name, is_published, publisher_id, published_date)
VALUES 
	(25, 'SSP2-4.5 Las trayectorias socioeconómicas compartidas (SSP, por sus siglas en inglés) son escenarios de cambios socioeconómicos globales proyectados hasta 2100. Ver "El Grupo Intergubernamental de Expertos sobre el Cambio Climático (IPCC)" (https://www.ipcc.ch/languages-2/spanish/).', 'SSP2-4.5', 'SSP2-4.5', 'SSP2-4.5','key1=>value1_es,key2=>value2_es','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'es', 'checksum',1,3, 'y', 'OS-C', 'OS-C', 'OS-C','y', 1,'2024-07-15T00:00:01Z')
;
INSERT INTO osc_physrisk.osc_physrisk_scenario.dim_scenario_type
	(scenario_type_id, description_full, description_short, name_fullyqualified, "name", tags, creation_time, creator_user_id, last_modification_time, last_modifier_user_id, is_deleted, deleter_user_id, deletion_time, culture, checksum, seq_num, translated_from_id, is_active, creator_user_name, last_modifier_user_name, deleter_user_name, is_published, publisher_id, published_date)
VALUES 
	(26, 'SSP3-7.0 - Las trayectorias socioeconómicas compartidas (SSP, por sus siglas en inglés) son escenarios de cambios socioeconómicos globales proyectados hasta 2100. Ver "El Grupo Intergubernamental de Expertos sobre el Cambio Climático (IPCC)" (https://www.ipcc.ch/languages-2/spanish/).', 'SSP3-7.0', 'SSP3-7.0', 'SSP3-7.0','key1=>value1_es,key2=>value2_es','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'es', 'checksum',1,4, 'y', 'OS-C', 'OS-C', 'OS-C','y', 1,'2024-07-15T00:00:01Z')
;
INSERT INTO osc_physrisk.osc_physrisk_scenario.dim_scenario_type
	(scenario_type_id, description_full, description_short, name_fullyqualified, "name", tags, creation_time, creator_user_id, last_modification_time, last_modifier_user_id, is_deleted, deleter_user_id, deletion_time, culture, checksum, seq_num, translated_from_id, is_active, creator_user_name, last_modifier_user_name, deleter_user_name, is_published, publisher_id, published_date)
VALUES 
	(27, 'SSP5-8.5 - Las trayectorias socioeconómicas compartidas (SSP, por sus siglas en inglés) son escenarios de cambios socioeconómicos globales proyectados hasta 2100. Ver "El Grupo Intergubernamental de Expertos sobre el Cambio Climático (IPCC)" (https://www.ipcc.ch/languages-2/spanish/).', 'SSP5-8.5', 'SSP5-8.5', 'SSP5-8.5','key1=>value1_es,key2=>value2_es','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'es', 'checksum',1,5, 'y', 'OS-C', 'OS-C', 'OS-C','y', 1,'2024-07-15T00:00:01Z')
;
INSERT INTO osc_physrisk.osc_physrisk_scenario.dim_scenario_type
	(scenario_type_id, description_full, description_short, name_fullyqualified, "name", tags, creation_time, creator_user_id, last_modification_time, last_modifier_user_id, is_deleted, deleter_user_id, deletion_time, culture, checksum, seq_num, translated_from_id, is_active, creator_user_name, last_modifier_user_name, deleter_user_name, is_published, publisher_id, published_date)
VALUES 
	(28, 'RCP2.6 Una trayectoria de concentración representativa (RCP, por sus siglas en inglés) es una proyección teórica de una trayectoria de concentración de gases de efecto invernadero (no emisiones) adoptada por el IPCC. Ver "El Grupo Intergubernamental de Expertos sobre el Cambio Climático (IPCC)" (https://www.ipcc.ch/languages-2/spanish/).', 'RCP2.6', 'RCP2.6', 'RCP2.6','key1=>value1_es,key2=>value2_es','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'es', 'checksum',1,6, 'y', 'OS-C', 'OS-C', 'OS-C','y', 1,'2024-07-15T00:00:01Z')
;
INSERT INTO osc_physrisk.osc_physrisk_scenario.dim_scenario_type
	(scenario_type_id, description_full, description_short, name_fullyqualified, "name", tags, creation_time, creator_user_id, last_modification_time, last_modifier_user_id, is_deleted, deleter_user_id, deletion_time, culture, checksum, seq_num, translated_from_id, is_active, creator_user_name, last_modifier_user_name, deleter_user_name, is_published, publisher_id, published_date)
VALUES 
	(29, 'RCP4.5 - Una trayectoria de concentración representativa (RCP, por sus siglas en inglés) es una proyección teórica de una trayectoria de concentración de gases de efecto invernadero (no emisiones) adoptada por el IPCC. Ver "El Grupo Intergubernamental de Expertos sobre el Cambio Climático (IPCC)" (https://www.ipcc.ch/languages-2/spanish/).', 'RCP4.5', 'RCP4.5', 'RCP4.5','key1=>value1_es,key2=>value2_es','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'es', 'checksum',1,7, 'y', 'OS-C', 'OS-C', 'OS-C','y', 1,'2024-07-15T00:00:01Z')
;
INSERT INTO osc_physrisk.osc_physrisk_scenario.dim_scenario_type
	(scenario_type_id, description_full, description_short, name_fullyqualified, "name",tags,  creation_time, creator_user_id, last_modification_time, last_modifier_user_id, is_deleted, deleter_user_id, deletion_time, culture, checksum, seq_num, translated_from_id, is_active, creator_user_name, last_modifier_user_name, deleter_user_name, is_published, publisher_id, published_date)
VALUES 
	(30, 'RCP6 - Una trayectoria de concentración representativa (RCP, por sus siglas en inglés) es una proyección teórica de una trayectoria de concentración de gases de efecto invernadero (no emisiones) adoptada por el IPCC. Ver "El Grupo Intergubernamental de Expertos sobre el Cambio Climático (IPCC)" (https://www.ipcc.ch/languages-2/spanish/).', 'RCP6', 'RCP6', 'RCP6','key1=>value1_es,key2=>value2_es','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'es', 'checksum',1,8, 'y', 'OS-C', 'OS-C', 'OS-C','y', 1,'2024-07-15T00:00:01Z')
;
INSERT INTO osc_physrisk.osc_physrisk_scenario.dim_scenario_type
	(scenario_type_id, description_full, description_short, name_fullyqualified, "name", tags, creation_time, creator_user_id, last_modification_time, last_modifier_user_id, is_deleted, deleter_user_id, deletion_time, culture, checksum, seq_num, translated_from_id, is_active, creator_user_name, last_modifier_user_name, deleter_user_name, is_published, publisher_id, published_date)
VALUES 
	(31, 'RCP8.5 - Una trayectoria de concentración representativa (RCP, por sus siglas en inglés) es una proyección teórica de una trayectoria de concentración de gases de efecto invernadero (no emisiones) adoptada por el IPCC. Ver "El Grupo Intergubernamental de Expertos sobre el Cambio Climático (IPCC)" (https://www.ipcc.ch/languages-2/spanish/).', 'RCP8.5', 'RCP8.5', 'RCP8.5','key1=>value1_es,key2=>value2_es','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'es', 'checksum',1,9, 'y', 'OS-C', 'OS-C', 'OS-C','y', 1,'2024-07-15T00:00:01Z')
;



-- DATA IN SPANISH ENDS


-- EXAMPLE QUERIES
-- VIEW SCENARIOS IN DIFFERENT LANGUAGES
SELECT * FROM osc_physrisk.osc_physrisk_scenario.dim_scenario_type WHERE culture='en';
SELECT * FROM osc_physrisk.osc_physrisk_scenario.dim_scenario_type WHERE culture='fr';
SELECT * FROM osc_physrisk.osc_physrisk_scenario.dim_scenario_type WHERE culture='es';

SELECT a."name" as "English Name",  b.culture as "Translated Culture",  b."name" as "Translated Name", b.description_full as "Translated Description", b.tags as "Translated Tags" FROM osc_physrisk.osc_physrisk_scenario.dim_scenario_type a 
INNER JOIN osc_physrisk.osc_physrisk_scenario.dim_scenario_type b ON a.scenario_type_id = b.translated_from_id
WHERE b.culture='es'  ;

-- QUERY BY TAGS
SELECT a."name",  a.description_full, a.tags FROM osc_physrisk.osc_physrisk_scenario.dim_scenario_type a
WHERE a.tags -> 'key1'='value1_en' OR a.tags -> 'key2'='value4_en'  ;

-- SHOW IMPACT ANALYSIS RESULTS
SELECT
	portfolio_analysis_id,
	"name",
	name_fullyqualified,
	description_full,
	description_short,
	tags,
	portfolio_id,
	scenario_type_id,
	scenario_year,
	hazard_id,
	impact_type_id,
	value_at_risk,
	annual_exceedence_probability,
	average_annual_loss,
	currency_alphabetic_code
FROM
	osc_physrisk.osc_physrisk_risk_analysis.fact_portfolio_impact
;

SELECT
	asset_analysis_id,
	"name",
	name_fullyqualified,
	description_full,
	description_short,
	tags,
	culture,
	asset_id,
	"location",
	coordinates,
	gers_id,
	h3_index,
	h3_resolution,
	scenario_type_id,
	scenario_year,
	hazard_id,
	hazard_intensity,
	impact_type_id,
	value_at_risk,
	currency_alphabetic_code,
	return_periods,
	"parameter",
	impact_mean,
	impact_distr_bin_edges,
	impact_distr_p,
	impact_exc_exceed_p,
	impact_exc_values,
	probability
FROM
	osc_physrisk.osc_physrisk_risk_analysis.fact_asset_impact
;

-- VIEW RIVERINE INUNDATION HAZARD INDICATORS
SELECT	*
FROM
	osc_physrisk.osc_physrisk_hazard.hazard haz INNER JOIN osc_physrisk.osc_physrisk_hazard.hazard_indicator hi ON hi.hazard_id = haz.hazard_id
WHERE haz."name" = 'Riverine Inundation' -- more likely written as WHERE haz.hazard_id = '63ed7943-c4c4-43ea-abd2-86bb1997a094'
;

-- VIEW COASTAL INUNDATION HAZARD INDICATORS
SELECT	*
FROM
	 osc_physrisk.osc_physrisk_hazard.hazard haz INNER JOIN osc_physrisk.osc_physrisk_hazard.hazard_indicator hi ON hi.hazard_id = haz.hazard_id
WHERE haz.hazard_id = '28a095cd-4cde-40a1-90d9-cbb0ca673c06'
;

-- VIEW CHRONIC HEAT HAZARD INDICATORS
SELECT	*
FROM
	 osc_physrisk.osc_physrisk_hazard.hazard haz INNER JOIN osc_physrisk.osc_physrisk_hazard.hazard_indicator hi ON hi.hazard_id = haz.hazard_id
WHERE haz.hazard_id = 'd08db675-ee1e-48fe-b9e1-b0da27de8f2b'
;

-- SAMPLE CHECKSUM UPDATE
--UPDATE osc_physrisk.osc_physrisk_scenario.dim_scenario_type
--	SET checksum = md5(concat('Unknown/Not Selected', 'Unknown/Not Selected', 'Unknown/Not Selected', 'Unknown/Not Selected')) WHERE scenario_type_id = -1
--;






