-- PHYRISK EXAMPLE DATABASE STRUCTURE
-- Intended to help standardize glossary/metadata as well as field osc_names and constraints
-- to align with phys-risk/geo-indexer/other related initiatives
-- speed up application development, help internationalize and display the results of analyses, and more.

-- Last Updated: 2024-08-05. Add Asset Type table. Add osc_ prefix to most columns. Added Precalculated damage curve example. Added asset table inheritance examples, and some backend functionality such as user table and indexes for performance. Simplify table osc_names and consolosc_idate schemas.
-- The backend schema User and Tenant tables are derived from ASP.NET Boilerplate tables (https://aspnetboilerplate.com/). That code is available under the MIT license, here: https://github.com/aspnetboilerplate/aspnetboilerplate

-- SETUP EXTENSIONS
CREATE EXTENSION postgis; -- used for geolocation
CREATE EXTENSION h3; -- used for Uber H3 geolocation
CREATE EXTENSION pgcrypto; -- used for random UUID generation
CREATE EXTENSION hstore; -- used for metadata

-- SETUP SCHEMAS
CREATE SCHEMA IF NOT EXISTS osc_physrisk_backend;
CREATE SCHEMA IF NOT EXISTS osc_physrisk_scenarios;
CREATE SCHEMA IF NOT EXISTS osc_physrisk_hazards;
CREATE SCHEMA IF NOT EXISTS osc_physrisk_models;
CREATE SCHEMA IF NOT EXISTS osc_physrisk_assets;
CREATE SCHEMA IF NOT EXISTS osc_physrisk_analysis_results;

-- SETUP TABLES
-- SCHEMA osc_physrisk_backend

CREATE TABLE osc_physrisk_backend.user (
	osc_id bigint NOT NULL,
	osc_datetime_created       timestamptz  NOT NULL  ,
	osc_creator_user_id      bigint    ,
	osc_datetime_last_modified timestamptz    ,
	osc_last_modifier_user_id bigint    ,
	osc_is_deleted          boolean  NOT NULL  ,
	osc_deleter_user_id      bigint    ,
	osc_datetime_deleted       timestamptz    ,
	osc_user_name varchar(256) NOT NULL,
	osc_tenant_id INTEGER NOT NULL,
	email_address varchar(256) NOT NULL,
	osc_name        varchar(256)  NOT NULL  ,
	osc_surname        varchar(256)  NOT NULL  ,
	osc_is_active       boolean  NOT NULL  ,
	PRIMARY KEY (osc_id)
);

ALTER TABLE osc_physrisk_backend.user
	ADD FOREIGN KEY (osc_creator_user_id) 
	REFERENCES osc_physrisk_backend.user (osc_id);

ALTER TABLE osc_physrisk_backend.user
	ADD FOREIGN KEY (osc_deleter_user_id) 
	REFERENCES osc_physrisk_backend.user (osc_id);

ALTER TABLE osc_physrisk_backend.user
	ADD FOREIGN KEY (osc_last_modifier_user_id) 
	REFERENCES osc_physrisk_backend.user (osc_id);

CREATE INDEX "ix_osc_physrisk_backend_users_osc_creator_user_id" ON osc_physrisk_backend.user USING btree (osc_creator_user_id);
CREATE INDEX "ix_osc_physrisk_backend_users_osc_deleter_user_id" ON osc_physrisk_backend.user USING btree (osc_deleter_user_id);
CREATE INDEX "ix_osc_physrisk_backend_users_osc_last_modifier_user_id" ON osc_physrisk_backend.user USING btree (osc_last_modifier_user_id);
CREATE INDEX "ix_osc_physrisk_backend_users_email_address" ON osc_physrisk_backend.user USING btree (osc_tenant_id, email_address);
CREATE INDEX "ix_osc_physrisk_backend_users_osc_tenant_id_osc_user_name" ON osc_physrisk_backend.user USING btree (osc_tenant_id, osc_user_name);

COMMENT ON TABLE osc_physrisk_backend.user IS 'Stores user information.';

CREATE TABLE osc_physrisk_backend.tenant (
	osc_id bigint NOT NULL,
	osc_datetime_created       timestamptz  NOT NULL  ,
	osc_creator_user_id      bigint    ,
	osc_datetime_last_modified timestamptz    ,
	osc_last_modifier_user_id bigint    ,
	osc_is_deleted          boolean  NOT NULL  ,
	osc_deleter_user_id      bigint    ,
	osc_datetime_deleted       timestamptz    ,
	osc_name varchar(64) NOT NULL,
	osc_tenancy_name varchar(256) NOT NULL,
	osc_is_active       boolean  NOT NULL  ,
	PRIMARY KEY (osc_id),
	CONSTRAINT fk_tenants_osc_creator_user_id FOREIGN KEY ( osc_creator_user_id ) REFERENCES osc_physrisk_backend.user(osc_id),
	CONSTRAINT fk_tenants_osc_last_modifier_user_id FOREIGN KEY ( osc_last_modifier_user_id ) REFERENCES osc_physrisk_backend.user(osc_id),
	CONSTRAINT fk_tenants_osc_deleter_user_id FOREIGN KEY ( osc_deleter_user_id ) REFERENCES osc_physrisk_backend.user(osc_id)
);

CREATE INDEX "ix_osc_physrisk_backend_tenants_osc_datetime_created" ON osc_physrisk_backend.tenant USING btree (osc_datetime_created);
CREATE INDEX "ix_osc_physrisk_backend_tnants_osc_creator_user_id" ON osc_physrisk_backend.tenant USING btree (osc_creator_user_id);
CREATE INDEX "ix_osc_physrisk_backend_tenants_osc_deleter_user_id" ON osc_physrisk_backend.tenant USING btree (osc_deleter_user_id);
CREATE INDEX "ix_osc_physrisk_backend_tenants_osc_last_modifier_user_id" ON osc_physrisk_backend.tenant USING btree (osc_last_modifier_user_id);
CREATE INDEX "ix_osc_physrisk_backend_tenants_osc_tenancy_name" ON osc_physrisk_backend.tenant USING btree (osc_tenancy_name);

COMMENT ON TABLE osc_physrisk_backend.tenant IS 'Stores tenant information to support multi-tenancy data (where appropriate). A default tenant is always provosc_ided.';


-- SCHEMA osc_physrisk_scenarios
CREATE TABLE osc_physrisk_scenarios.scenario ( 
	osc_id BIGINT NOT NULL,
	osc_name VARCHAR(256) NOT NULL,
	osc_name_display VARCHAR(256),
	osc_abbreviation VARCHAR(8),
	osc_description_full  TEXT NOT NULL,
	osc_description_short  VARCHAR(256) NOT NULL,
    osc_tags hstore DEFAULT NULL,
	osc_datetime_created TIMESTAMPTZ NOT NULL,
	osc_creator_user_id BIGINT NOT NULL,
	osc_datetime_last_modified TIMESTAMPTZ NOT NULL,
	osc_last_modifier_user_id BIGINT NOT NULL,
	osc_is_deleted BOOLEAN NOT NULL DEFAULT 'n',
	osc_deleter_user_id BIGINT DEFAULT NULL,
	osc_datetime_deleted TIMESTAMPTZ DEFAULT NULL,
	osc_culture VARCHAR(5) NOT NULL DEFAULT 'en',
	osc_checksum VARCHAR(40) DEFAULT NULL,
	osc_seq_num SMALLINT  NOT NULL Default 1,
	osc_translated_from_id BIGINT DEFAULT NULL,
	osc_is_active BOOLEAN NOT NULL DEFAULT 'y',
	osc_is_published BOOLEAN DEFAULT 'n',
	osc_publisher_id BIGINT DEFAULT NULL,
	osc_datetime_published TIMESTAMPTZ DEFAULT NULL,
	osc_version TEXT DEFAULT '1.0',
	CONSTRAINT pk_scenario PRIMARY KEY ( osc_id ),
	CONSTRAINT fk_scenario_osc_creator_user_id FOREIGN KEY ( osc_creator_user_id ) REFERENCES osc_physrisk_backend.user(osc_id),
	CONSTRAINT fk_scenario_osc_last_modifier_user_id FOREIGN KEY ( osc_last_modifier_user_id ) REFERENCES osc_physrisk_backend.user(osc_id),
	CONSTRAINT fk_scenario_osc_deleter_user_id FOREIGN KEY ( osc_deleter_user_id ) REFERENCES osc_physrisk_backend.user(osc_id)
 ); 

 COMMENT ON TABLE osc_physrisk_scenarios.scenario IS 'Contains a list of the United Nations Intergovernmental Panel on Climate Change (IPCC)-defined climate scenarios (SSPs and RCPs).';


-- SCHEMA osc_physrisk_hazards
CREATE TABLE osc_physrisk_hazards.hazard ( 
	osc_id	UUID  DEFAULT gen_random_UUID ()  NOT NULL,
	osc_name VARCHAR(256) NOT NULL,
	osc_name_display VARCHAR(256),
	osc_abbreviation VARCHAR(8),
	osc_description_full  TEXT NOT NULL,
	osc_description_short  VARCHAR(256) NOT NULL,
    osc_tags hstore DEFAULT NULL,
	osc_datetime_created TIMESTAMPTZ NOT NULL,
	osc_creator_user_id BIGINT NOT NULL,
	osc_datetime_last_modified TIMESTAMPTZ NOT NULL,
	osc_last_modifier_user_id BIGINT NOT NULL,
	osc_is_deleted BOOLEAN NOT NULL DEFAULT 'n',
	osc_deleter_user_id BIGINT DEFAULT NULL,
	osc_datetime_deleted TIMESTAMPTZ DEFAULT NULL,
	osc_culture VARCHAR(5) NOT NULL DEFAULT 'en',
	osc_checksum VARCHAR(40) DEFAULT NULL,
	osc_seq_num SMALLINT  NOT NULL Default 1,
	osc_translated_from_id UUID DEFAULT NULL,
	osc_is_active BOOLEAN NOT NULL DEFAULT 'y',
	osc_is_published BOOLEAN DEFAULT 'n',
	osc_publisher_id BIGINT DEFAULT NULL,
	osc_datetime_published TIMESTAMPTZ DEFAULT NULL,
	osc_version TEXT DEFAULT '1.0',
	oed_peril_code integer,
	oed_input_abbreviation      varchar(5) ,
	oed_grouped_peril_code boolean,
	CONSTRAINT pk_hazard PRIMARY KEY ( osc_id ),
	CONSTRAINT fk_hazard_osc_creator_user_id FOREIGN KEY ( osc_creator_user_id ) REFERENCES osc_physrisk_backend.user(osc_id),
	CONSTRAINT fk_hazard_osc_last_modifier_user_id FOREIGN KEY ( osc_last_modifier_user_id ) REFERENCES osc_physrisk_backend.user(osc_id),
	CONSTRAINT fk_hazard_osc_deleter_user_id FOREIGN KEY ( osc_deleter_user_id ) REFERENCES osc_physrisk_backend.user(osc_id)
 );
COMMENT ON TABLE osc_physrisk_hazards.hazard IS 'Contains a list of the physical hazards supported by OS-Climate.';


CREATE TABLE osc_physrisk_hazards.hazard_indicator ( 
	osc_id	UUID  DEFAULT gen_random_UUID () NOT NULL,
	osc_name VARCHAR(256) NOT NULL,
	osc_name_display VARCHAR(256),
	osc_abbreviation VARCHAR(8),
	osc_description_full  TEXT NOT NULL,
	osc_description_short  VARCHAR(256) NOT NULL,
    osc_tags hstore DEFAULT NULL,
	osc_datetime_created TIMESTAMPTZ NOT NULL,
	osc_creator_user_id BIGINT NOT NULL,
	osc_datetime_last_modified TIMESTAMPTZ NOT NULL,
	osc_last_modifier_user_id BIGINT NOT NULL,
	osc_is_deleted BOOLEAN NOT NULL DEFAULT 'n',
	osc_deleter_user_id BIGINT DEFAULT NULL,
	osc_datetime_deleted TIMESTAMPTZ DEFAULT NULL,
	osc_culture VARCHAR(5) NOT NULL DEFAULT 'en',
	osc_checksum VARCHAR(40) DEFAULT NULL,
	osc_seq_num SMALLINT  NOT NULL Default 1,
	osc_translated_from_id UUID DEFAULT NULL,
	osc_is_active BOOLEAN NOT NULL DEFAULT 'y',
	osc_is_published BOOLEAN DEFAULT 'n',
	osc_publisher_id BIGINT DEFAULT NULL,
	osc_datetime_published TIMESTAMPTZ DEFAULT NULL,
	osc_version TEXT DEFAULT '1.0',
	osc_hazard_id	UUID  NOT NULL,
	CONSTRAINT pk_hazard_indicator PRIMARY KEY ( osc_id ),
	CONSTRAINT fk_hazard_indicator_osc_hazard_id FOREIGN KEY ( osc_hazard_id ) REFERENCES osc_physrisk_hazards.hazard(osc_id),
	CONSTRAINT fk_hazard_indicator_osc_creator_user_id FOREIGN KEY ( osc_creator_user_id ) REFERENCES osc_physrisk_backend.user(osc_id),
	CONSTRAINT fk_hazard_indicator_osc_last_modifier_user_id FOREIGN KEY ( osc_last_modifier_user_id ) REFERENCES osc_physrisk_backend.user(osc_id),
	CONSTRAINT fk_hazard_indicator_osc_deleter_user_id FOREIGN KEY ( osc_deleter_user_id ) REFERENCES osc_physrisk_backend.user(osc_id)	
 );
COMMENT ON TABLE osc_physrisk_hazards.hazard_indicator IS 'Contains a list of the physical hazard indicators that are supported by OS-Climate. An indicator must always relate to one particular hazard.';

 -- SCHEMA osc_physrisk_models
 CREATE TABLE osc_physrisk_models.exposure_function ( 
	osc_id	UUID  DEFAULT gen_random_UUID () NOT NULL,
	osc_name VARCHAR(256) NOT NULL,
	osc_name_display VARCHAR(256),
	osc_abbreviation VARCHAR(8),
	osc_description_full  TEXT NOT NULL,
	osc_description_short  VARCHAR(256) NOT NULL,
    osc_tags hstore DEFAULT NULL,
	osc_datetime_created TIMESTAMPTZ NOT NULL,
	osc_creator_user_id BIGINT NOT NULL,
	osc_datetime_last_modified TIMESTAMPTZ NOT NULL,
	osc_last_modifier_user_id BIGINT NOT NULL,
	osc_is_deleted BOOLEAN NOT NULL DEFAULT 'n',
	osc_deleter_user_id BIGINT DEFAULT NULL,
	osc_datetime_deleted TIMESTAMPTZ DEFAULT NULL,
	osc_tenant_id BIGINT NOT NULL DEFAULT 1,
	osc_culture VARCHAR(5) NOT NULL DEFAULT 'en',
	osc_checksum VARCHAR(40) DEFAULT NULL,
	osc_seq_num SMALLINT  NOT NULL Default 1,
	osc_translated_from_id UUID DEFAULT NULL,
	osc_is_active BOOLEAN NOT NULL DEFAULT 'y',
	osc_is_published BOOLEAN DEFAULT 'n',
	osc_publisher_id BIGINT DEFAULT NULL,
	osc_datetime_published TIMESTAMPTZ DEFAULT NULL,
	osc_version TEXT DEFAULT '1.0',
	CONSTRAINT pk_exposure_function PRIMARY KEY ( osc_id ),
	CONSTRAINT fk_exposure_function_osc_creator_user_id FOREIGN KEY ( osc_creator_user_id ) REFERENCES osc_physrisk_backend.user(osc_id),
	CONSTRAINT fk_exposure_function_osc_last_modifier_user_id FOREIGN KEY ( osc_last_modifier_user_id ) REFERENCES osc_physrisk_backend.user(osc_id),
	CONSTRAINT fk_exposure_function_osc_deleter_user_id FOREIGN KEY ( osc_deleter_user_id ) REFERENCES osc_physrisk_backend.user(osc_id),
	CONSTRAINT fk_exposure_function_osc_tenant_id FOREIGN KEY ( osc_tenant_id ) REFERENCES osc_physrisk_backend.tenant(osc_id)
 );
 COMMENT ON TABLE osc_physrisk_models.exposure_function IS 'The model used to determine whether a particular asset is exposed to a particular hazard indicator.';


-- SCHEMA osc_physrisk_models
CREATE TABLE osc_physrisk_models.vulnerability_function ( 
	osc_id	UUID  DEFAULT gen_random_UUID () NOT NULL,
	osc_name VARCHAR(256) NOT NULL,
	osc_name_display VARCHAR(256),
	osc_abbreviation VARCHAR(8),
	osc_description_full  TEXT NOT NULL,
	osc_description_short  VARCHAR(256) NOT NULL,
    osc_tags hstore DEFAULT NULL,
	osc_datetime_created TIMESTAMPTZ NOT NULL,
	osc_creator_user_id BIGINT NOT NULL,
	osc_datetime_last_modified TIMESTAMPTZ NOT NULL,
	osc_last_modifier_user_id BIGINT NOT NULL,
	osc_is_active BOOLEAN NOT NULL DEFAULT 'y',
	osc_is_deleted BOOLEAN NOT NULL DEFAULT 'n',
	osc_deleter_user_id BIGINT DEFAULT NULL,
	osc_datetime_deleted TIMESTAMPTZ DEFAULT NULL,
	osc_tenant_id BIGINT NOT NULL DEFAULT 1,
	osc_culture VARCHAR(5) NOT NULL DEFAULT 'en',
	osc_checksum VARCHAR(40) DEFAULT NULL,
	osc_seq_num SMALLINT  NOT NULL Default 1,
	osc_translated_from_id UUID DEFAULT NULL,
	osc_is_published BOOLEAN DEFAULT 'n',
	osc_publisher_id BIGINT DEFAULT NULL,
	osc_datetime_published TIMESTAMPTZ DEFAULT NULL,
	osc_version TEXT DEFAULT '1.0',
	CONSTRAINT pk_vulnerability_function PRIMARY KEY ( osc_id ),
	CONSTRAINT fk_vulnerability_osc_creator_user_id FOREIGN KEY ( osc_creator_user_id ) REFERENCES osc_physrisk_backend.user(osc_id),
	CONSTRAINT fk_vulnerability_osc_last_modifier_user_id FOREIGN KEY ( osc_last_modifier_user_id ) REFERENCES osc_physrisk_backend.user(osc_id),
	CONSTRAINT fk_vulnerability_osc_deleter_user_id FOREIGN KEY ( osc_deleter_user_id ) REFERENCES osc_physrisk_backend.user(osc_id),
	CONSTRAINT fk_vulnerability_osc_tenant_id FOREIGN KEY ( osc_tenant_id ) REFERENCES osc_physrisk_backend.tenant(osc_id)
 );
COMMENT ON TABLE osc_physrisk_models.vulnerability_function IS 'The model used to determine the degree by which a particular asset is vulnerable to a particular hazard indicator. If an asset is vulnerable to a peril, it must necessarily be exposed to it (see exposure_function).';

CREATE TABLE osc_physrisk_models.damage_function ( 
	osc_id	UUID  DEFAULT gen_random_UUID () NOT NULL,
	osc_name VARCHAR(256) NOT NULL,
	osc_name_display VARCHAR(256),
	osc_abbreviation VARCHAR(8),
	osc_description_full  TEXT NOT NULL,
	osc_description_short  VARCHAR(256) NOT NULL,
    osc_tags hstore DEFAULT NULL,
	osc_datetime_created TIMESTAMPTZ NOT NULL,
	osc_creator_user_id BIGINT NOT NULL,
	osc_datetime_last_modified TIMESTAMPTZ NOT NULL,
	osc_last_modifier_user_id BIGINT NOT NULL,
	osc_is_deleted BOOLEAN NOT NULL DEFAULT 'n',
	osc_deleter_user_id BIGINT DEFAULT NULL,
	osc_datetime_deleted TIMESTAMPTZ DEFAULT NULL,
	osc_tenant_id BIGINT NOT NULL DEFAULT 1,
	osc_culture VARCHAR(5) NOT NULL DEFAULT 'en',
	osc_checksum VARCHAR(40) DEFAULT NULL,
	osc_seq_num SMALLINT  NOT NULL Default 1,
	osc_translated_from_id UUID DEFAULT NULL,
	osc_is_active BOOLEAN NOT NULL DEFAULT 'y',
	osc_is_published BOOLEAN DEFAULT 'n',
	osc_publisher_id BIGINT DEFAULT NULL,
	osc_datetime_published TIMESTAMPTZ DEFAULT NULL,
	osc_version TEXT DEFAULT '1.0',
	CONSTRAINT pk_damage_function PRIMARY KEY ( osc_id ),
	CONSTRAINT fk_damage_function_osc_creator_user_id FOREIGN KEY ( osc_creator_user_id ) REFERENCES osc_physrisk_backend.user(osc_id),
	CONSTRAINT fk_damage_function_osc_last_modifier_user_id FOREIGN KEY ( osc_last_modifier_user_id ) REFERENCES osc_physrisk_backend.user(osc_id),
	CONSTRAINT fk_damage_function_osc_deleter_user_id FOREIGN KEY ( osc_deleter_user_id ) REFERENCES osc_physrisk_backend.user(osc_id),
	CONSTRAINT fk_damage_function_osc_tenant_id FOREIGN KEY ( osc_tenant_id ) REFERENCES osc_physrisk_backend.tenant(osc_id)
 );
COMMENT ON TABLE osc_physrisk_models.damage_function IS 'The model used to determine how to convert the vulnerability of an asset into a particular level of  damage and/or disruption. If an asset has damage or disruption from a peril, it must necessarily exposed to and vulnerable to it (see exposure_function and vulnerability_function).';

-- SCHEMA osc_physrisk_models;
CREATE TABLE osc_physrisk_models.financial_model ( 
	osc_id	UUID  DEFAULT gen_random_UUID () NOT NULL,
	osc_name VARCHAR(256) NOT NULL,
	osc_name_display VARCHAR(256),
	osc_abbreviation VARCHAR(8),
	osc_description_full  TEXT NOT NULL,
	osc_description_short  VARCHAR(256) NOT NULL,
    osc_tags hstore DEFAULT NULL,
	osc_datetime_created TIMESTAMPTZ NOT NULL,
	osc_creator_user_id BIGINT NOT NULL,
	osc_datetime_last_modified TIMESTAMPTZ NOT NULL,
	osc_last_modifier_user_id BIGINT NOT NULL,
	osc_is_deleted BOOLEAN NOT NULL DEFAULT 'n',
	osc_deleter_user_id BIGINT DEFAULT NULL,
	osc_datetime_deleted TIMESTAMPTZ DEFAULT NULL,
	osc_tenant_id BIGINT NOT NULL DEFAULT 1,
	osc_culture VARCHAR(5) NOT NULL DEFAULT 'en',
	osc_checksum VARCHAR(40) DEFAULT NULL,
	osc_seq_num SMALLINT  NOT NULL Default 1,
	osc_translated_from_id UUID DEFAULT NULL,
	osc_is_active BOOLEAN NOT NULL DEFAULT 'y',
	osc_is_published BOOLEAN DEFAULT 'n',
	osc_publisher_id BIGINT DEFAULT NULL,
	osc_datetime_published TIMESTAMPTZ DEFAULT NULL,
	osc_version TEXT DEFAULT '1.0',
	CONSTRAINT pk_financial_model PRIMARY KEY ( osc_id ),
	CONSTRAINT fk_financial_model_osc_creator_user_id FOREIGN KEY ( osc_creator_user_id ) REFERENCES osc_physrisk_backend.user(osc_id),
	CONSTRAINT fk_financial_model_osc_last_modifier_user_id FOREIGN KEY ( osc_last_modifier_user_id ) REFERENCES osc_physrisk_backend.user(osc_id),
	CONSTRAINT fk_financial_model_osc_deleter_user_id FOREIGN KEY ( osc_deleter_user_id ) REFERENCES osc_physrisk_backend.user(osc_id),
	CONSTRAINT fk_financial_model_osc_tenant_id FOREIGN KEY ( osc_tenant_id ) REFERENCES osc_physrisk_backend.tenant(osc_id)
 );
COMMENT ON TABLE osc_physrisk_models.financial_model IS 'Is this the same as damage_function, above?';



-- SCHEMA osc_physrisk_assets

CREATE TABLE osc_physrisk_assets.asset_class ( 
	osc_id UUID  DEFAULT gen_random_UUID () NOT NULL,
	osc_name VARCHAR(256) NOT NULL,
	osc_name_display VARCHAR(256),
	osc_abbreviation VARCHAR(8),
	osc_description_full  TEXT NOT NULL,
	osc_description_short  VARCHAR(256) NOT NULL,
    osc_tags hstore DEFAULT NULL,
	osc_datetime_created TIMESTAMPTZ NOT NULL,
	osc_creator_user_id BIGINT NOT NULL,
	osc_datetime_last_modified TIMESTAMPTZ NOT NULL,
	osc_last_modifier_user_id BIGINT NOT NULL,
	osc_is_deleted BOOLEAN NOT NULL DEFAULT 'n',
	osc_deleter_user_id BIGINT DEFAULT NULL,
	osc_datetime_deleted TIMESTAMPTZ DEFAULT NULL,
	osc_culture VARCHAR(5) NOT NULL DEFAULT 'en',
	osc_checksum VARCHAR(40) DEFAULT NULL,
	osc_seq_num SMALLINT  NOT NULL Default 1,
	osc_translated_from_id UUID DEFAULT NULL,
	osc_is_active BOOLEAN NOT NULL DEFAULT 'y',
	osc_is_published BOOLEAN DEFAULT 'n',
	osc_publisher_id BIGINT DEFAULT NULL,
	osc_datetime_published TIMESTAMPTZ DEFAULT NULL,
	osc_version TEXT DEFAULT '1.0',
	CONSTRAINT pk_asset_class PRIMARY KEY (osc_id ),
	CONSTRAINT fk_asset_class_osc_creator_user_id FOREIGN KEY ( osc_creator_user_id ) REFERENCES osc_physrisk_backend.user(osc_id),
	CONSTRAINT fk_asset_class_osc_last_modifier_user_id FOREIGN KEY ( osc_last_modifier_user_id ) REFERENCES osc_physrisk_backend.user(osc_id),
	CONSTRAINT fk_asset_class_osc_deleter_user_id FOREIGN KEY ( osc_deleter_user_id ) REFERENCES osc_physrisk_backend.user(osc_id)	
 );
COMMENT ON TABLE osc_physrisk_assets.asset_class IS 'A physical financial asset (infrastructure, utilities, property, buildings) category, that may impact the modeling (ex real estate vs power generating utilities).';


CREATE TABLE osc_physrisk_assets.asset_type ( 
	osc_id UUID  DEFAULT gen_random_UUID () NOT NULL,
	osc_name VARCHAR(256) NOT NULL,
	osc_name_display VARCHAR(256),
	osc_abbreviation VARCHAR(8),
	osc_description_full  TEXT NOT NULL,
	osc_description_short  VARCHAR(256) NOT NULL,
    osc_tags hstore DEFAULT NULL,
	osc_datetime_created TIMESTAMPTZ NOT NULL,
	osc_creator_user_id BIGINT NOT NULL,
	osc_datetime_last_modified TIMESTAMPTZ NOT NULL,
	osc_last_modifier_user_id BIGINT NOT NULL,
	osc_is_deleted BOOLEAN NOT NULL DEFAULT 'n',
	osc_deleter_user_id BIGINT DEFAULT NULL,
	osc_datetime_deleted TIMESTAMPTZ DEFAULT NULL,
	osc_culture VARCHAR(5) NOT NULL DEFAULT 'en',
	osc_checksum VARCHAR(40) DEFAULT NULL,
	osc_seq_num SMALLINT  NOT NULL Default 1,
	osc_translated_from_id UUID DEFAULT NULL,
	osc_is_active BOOLEAN NOT NULL DEFAULT 'y',
	osc_is_published BOOLEAN DEFAULT 'n',
	osc_publisher_id BIGINT DEFAULT NULL,
	osc_datetime_published TIMESTAMPTZ DEFAULT NULL,
	osc_version TEXT DEFAULT '1.0',
	osc_asset_class_id UUID,
	CONSTRAINT pk_asset_type PRIMARY KEY (osc_id ),
	CONSTRAINT fk_asset_type_osc_creator_user_id FOREIGN KEY ( osc_creator_user_id ) REFERENCES osc_physrisk_backend.user(osc_id),
	CONSTRAINT fk_asset_type_osc_last_modifier_user_id FOREIGN KEY ( osc_last_modifier_user_id ) REFERENCES osc_physrisk_backend.user(osc_id),
	CONSTRAINT fk_asset_type_osc_deleter_user_id FOREIGN KEY ( osc_deleter_user_id ) REFERENCES osc_physrisk_backend.user(osc_id),	
    CONSTRAINT fk_asset_type_osc_asset_class_id FOREIGN KEY ( osc_asset_class_id ) REFERENCES osc_physrisk_assets.asset_class(osc_id)
 );
COMMENT ON TABLE osc_physrisk_assets.asset_type IS 'A physical financial asset (infrastructure, utilities, property, buildings) specific classification within an overarching asset class, that may impact the modeling (ex commercial real estate vs residential real, both of which types belong to the same real estate class).';


CREATE TABLE osc_physrisk_assets.portfolio ( 
	osc_id UUID  DEFAULT gen_random_UUID () NOT NULL,
	osc_name VARCHAR(256) NOT NULL,
	osc_name_display VARCHAR(256),
	osc_abbreviation VARCHAR(8),
	osc_description_full  TEXT NOT NULL,
	osc_description_short  VARCHAR(256) NOT NULL,
    osc_tags hstore DEFAULT NULL,
	osc_datetime_created TIMESTAMPTZ NOT NULL,
	osc_creator_user_id BIGINT NOT NULL,
	osc_datetime_last_modified TIMESTAMPTZ NOT NULL,
	osc_last_modifier_user_id BIGINT NOT NULL,
	osc_is_deleted BOOLEAN NOT NULL DEFAULT 'n',
	osc_deleter_user_id BIGINT DEFAULT NULL,
	osc_datetime_deleted TIMESTAMPTZ DEFAULT NULL,
	osc_tenant_id BIGINT NOT NULL DEFAULT 1,
	osc_culture VARCHAR(5) NOT NULL DEFAULT 'en',
	osc_checksum VARCHAR(40) DEFAULT NULL,
	osc_seq_num SMALLINT  NOT NULL Default 1,
	osc_translated_from_id UUID DEFAULT NULL,
	osc_is_active BOOLEAN NOT NULL DEFAULT 'y',
	osc_is_published BOOLEAN DEFAULT 'n',
	osc_publisher_id BIGINT DEFAULT NULL,
	osc_datetime_published TIMESTAMPTZ DEFAULT NULL,
	osc_version TEXT DEFAULT '1.0',
    value_total numeric,
    value_currency_alphabetic_code char(3),
	CONSTRAINT pk_portfolio PRIMARY KEY (osc_id ),
	CONSTRAINT fk_portfolio_osc_creator_user_id FOREIGN KEY ( osc_creator_user_id ) REFERENCES osc_physrisk_backend.user(osc_id),
	CONSTRAINT fk_portfolio_osc_last_modifier_user_id FOREIGN KEY ( osc_last_modifier_user_id ) REFERENCES osc_physrisk_backend.user(osc_id),
	CONSTRAINT fk_portfolio_osc_deleter_user_id FOREIGN KEY ( osc_deleter_user_id ) REFERENCES osc_physrisk_backend.user(osc_id),
	CONSTRAINT fk_portfolio_osc_tenant_id FOREIGN KEY ( osc_tenant_id ) REFERENCES osc_physrisk_backend.tenant(osc_id)
 );
COMMENT ON TABLE osc_physrisk_assets.portfolio IS 'A financial portfolio that contains 1 or more physical financial assets (infrastructure, utilities, property, buildings).';

CREATE TABLE osc_physrisk_assets.asset ( 
	osc_id UUID  DEFAULT gen_random_UUID () NOT NULL,
	osc_name VARCHAR(256) NOT NULL,
	osc_name_display VARCHAR(256),
	osc_abbreviation VARCHAR(8),
	osc_description_full  TEXT NOT NULL,
	osc_description_short  VARCHAR(256) NOT NULL,
    osc_tags hstore DEFAULT NULL,
	osc_datetime_created TIMESTAMPTZ NOT NULL,
	osc_creator_user_id BIGINT NOT NULL,
	osc_datetime_last_modified TIMESTAMPTZ NOT NULL,
	osc_last_modifier_user_id BIGINT NOT NULL,
	osc_is_deleted BOOLEAN NOT NULL DEFAULT 'n',
	osc_deleter_user_id BIGINT DEFAULT NULL,
	osc_datetime_deleted TIMESTAMPTZ DEFAULT NULL,
	osc_tenant_id BIGINT NOT NULL DEFAULT 1,
	osc_culture VARCHAR(5) NOT NULL DEFAULT 'en',
	osc_checksum VARCHAR(40) DEFAULT NULL,
	osc_seq_num SMALLINT  NOT NULL Default 1,
	osc_translated_from_id UUID DEFAULT NULL,
	osc_is_active BOOLEAN NOT NULL DEFAULT 'y',
	osc_is_published BOOLEAN DEFAULT 'n',
	osc_publisher_id BIGINT DEFAULT NULL,
	osc_datetime_published TIMESTAMPTZ DEFAULT NULL,
	osc_version TEXT DEFAULT '1.0',
    osc_portfolio_id UUID NOT NULL,
	geo_location_name      	varchar(256),
    geo_location_address      	text,
    geo_location_coordinates      	GEOGRAPHY  NOT NULL  ,
	geo_altitude numeric DEFAULT NULL, 
	geo_altitude_confidence numeric DEFAULT NULL,
	geo_overture_features			jsonb[], -- This asset can be described in 0 or more Overture Map schemas to cover its land use, infrastructure, building extents, etc
	geo_h3_index H3INDEX NOT NULL,
    geo_h3_resolution INT2 NOT NULL,
	osc_asset_type_id UUID,
	owner_bloomberg_osc_id	varchar(12) DEFAULT NULL,
	owner_lei_osc_id varchar(20) DEFAULT NULL,
	value_cashflows numeric ARRAY,-- Sequence of the associated cash flows (for cash flow generating assets only).
    value_total numeric,
    value_dynamics jsonb, -- Asset Value Dynamics over time, example real estate appreciation
	value_currency_alphabetic_code char(3),
	CONSTRAINT pk_asset PRIMARY KEY ( osc_id ),
	CONSTRAINT fk_asset_osc_portfolio_id FOREIGN KEY ( osc_portfolio_id ) REFERENCES osc_physrisk_assets.portfolio(osc_id),
    CONSTRAINT ck_asset_h3_resolution CHECK (geo_h3_resolution >= 0 AND geo_h3_resolution <= 15),
	CONSTRAINT fk_asset_osc_creator_user_id FOREIGN KEY ( osc_creator_user_id ) REFERENCES osc_physrisk_backend.user(osc_id),
	CONSTRAINT fk_asset_osc_last_modifier_user_id FOREIGN KEY ( osc_last_modifier_user_id ) REFERENCES osc_physrisk_backend.user(osc_id),
	CONSTRAINT fk_asset_osc_deleter_user_id FOREIGN KEY ( osc_deleter_user_id ) REFERENCES osc_physrisk_backend.user(osc_id),
	CONSTRAINT fk_asset_osc_tenant_id FOREIGN KEY ( osc_tenant_id ) REFERENCES osc_physrisk_backend.tenant(osc_id),
    CONSTRAINT fk_asset_osc_asset_type_id FOREIGN KEY ( osc_asset_type_id ) REFERENCES osc_physrisk_assets.asset_type(osc_id)
 );
COMMENT ON TABLE osc_physrisk_assets.asset IS 'A physical financial asset (infrastructure, utilities, property, buildings) that is contained within a financial portfolio. The lowest unit of assessment for physical risk & resilience (currently).';

CREATE INDEX "ix_osc_physrisk_assets_asset_osc_portfolio_id" ON osc_physrisk_assets.asset USING btree (osc_portfolio_id);

CREATE TABLE osc_physrisk_assets.asset_realestate ( 
	value_ltv text ARRAY, -- Sequence of Loan-to-Value results by date, representing the ratio of the first mortgage line as a percentage of the total appraised value of real property.
	value_dynamics jsonb, -- Asset Value Dynamics over time, example real estate appreciation
	CONSTRAINT pk_asset_realestate PRIMARY KEY ( osc_id ),
	CONSTRAINT fk_asset_realestate_osc_portfolio_id FOREIGN KEY ( osc_portfolio_id ) REFERENCES osc_physrisk_assets.portfolio(osc_id),
    CONSTRAINT ck_asset_realestate_h3_resolution CHECK (geo_h3_resolution >= 0 AND geo_h3_resolution <= 15),
	CONSTRAINT fk_asset_realestate_osc_creator_user_id FOREIGN KEY ( osc_creator_user_id ) REFERENCES osc_physrisk_backend.user(osc_id),
	CONSTRAINT fk_asset_realestate_osc_last_modifier_user_id FOREIGN KEY ( osc_last_modifier_user_id ) REFERENCES osc_physrisk_backend.user(osc_id),
	CONSTRAINT fk_asset_realestate_osc_deleter_user_id FOREIGN KEY ( osc_deleter_user_id ) REFERENCES osc_physrisk_backend.user(osc_id),
	CONSTRAINT fk_asset_realestate_osc_tenant_id FOREIGN KEY ( osc_tenant_id ) REFERENCES osc_physrisk_backend.tenant(osc_id),	
    CONSTRAINT fk_asset_realestate_osc_asset_type_id FOREIGN KEY ( osc_asset_type_id ) REFERENCES osc_physrisk_assets.asset_type(osc_id)
 ) INHERITS (osc_physrisk_assets.asset);
COMMENT ON TABLE osc_physrisk_assets.asset_realestate IS 'A physical financial asset (infrastructure, utilities, property, buildings) that is contained within a financial portfolio. The lowest unit of assessment for physical risk & resilience (currently).';

CREATE TABLE osc_physrisk_assets.asset_powergeneratingutility ( 
	production numeric, -- Real annual production of a power plant in Wh.
	capacity numeric, -- Capacity of the power plant in W.
	availability_rate numeric, -- Availability factor of production.
	value_dynamics jsonb, -- Asset Value Dynamics over time, example real estate appreciation
	CONSTRAINT pk_asset_powergeneratingutility PRIMARY KEY ( osc_id ),
	CONSTRAINT fk_asset_powergeneratingutility_osc_portfolio_id FOREIGN KEY ( osc_portfolio_id ) REFERENCES osc_physrisk_assets.portfolio(osc_id),
    CONSTRAINT ck_asset_powergeneratingutility_h3_resolution CHECK (geo_h3_resolution >= 0 AND geo_h3_resolution <= 15),
	CONSTRAINT fk_asset_powergeneratingutility_osc_creator_user_id FOREIGN KEY ( osc_creator_user_id ) REFERENCES osc_physrisk_backend.user(osc_id),
	CONSTRAINT fk_asset_powergeneratingutility_osc_last_modifier_user_id FOREIGN KEY ( osc_last_modifier_user_id ) REFERENCES osc_physrisk_backend.user(osc_id),
	CONSTRAINT fk_asset_powergeneratingutilityosc_deleter_user_id FOREIGN KEY ( osc_deleter_user_id ) REFERENCES osc_physrisk_backend.user(osc_id),
	CONSTRAINT fk_asset_powergeneratingutility_osc_tenant_id FOREIGN KEY ( osc_tenant_id ) REFERENCES osc_physrisk_backend.tenant(osc_id),	
    CONSTRAINT fk_asset_powergeneratingutility_osc_asset_type_id FOREIGN KEY ( osc_asset_type_id ) REFERENCES osc_physrisk_assets.asset_type(osc_id)
 ) INHERITS (osc_physrisk_assets.asset);
COMMENT ON TABLE osc_physrisk_assets.asset_powergeneratingutility IS 'A physical financial asset (infrastructure, utilities, property, buildings) that is contained within a financial portfolio. The lowest unit of assessment for physical risk & resilience (currently).';

-- SCHEMA osc_physrisk_analysis_results
CREATE TABLE osc_physrisk_analysis_results.impact_type ( 
	osc_id INTEGER NOT NULL,
	osc_name VARCHAR(256) NOT NULL,
	osc_name_display VARCHAR(256),
	osc_abbreviation VARCHAR(8),
	osc_description_full  TEXT NOT NULL,
	osc_description_short  VARCHAR(256) NOT NULL,
    osc_tags hstore DEFAULT NULL,
	osc_datetime_created TIMESTAMPTZ NOT NULL,
	osc_creator_user_id BIGINT NOT NULL,
	osc_datetime_last_modified TIMESTAMPTZ NOT NULL,
	osc_last_modifier_user_id BIGINT NOT NULL,
	osc_is_deleted BOOLEAN NOT NULL DEFAULT 'n',
	osc_deleter_user_id BIGINT DEFAULT NULL,
	osc_datetime_deleted TIMESTAMPTZ DEFAULT NULL,
	osc_culture VARCHAR(5) NOT NULL DEFAULT 'en',
	osc_checksum VARCHAR(40) DEFAULT NULL,
	osc_seq_num SMALLINT  NOT NULL Default 1,
	osc_translated_from_id INTEGER DEFAULT NULL,
	osc_is_active BOOLEAN NOT NULL DEFAULT 'y',
	osc_is_published BOOLEAN DEFAULT 'n',
	osc_publisher_id BIGINT DEFAULT NULL,
	osc_datetime_published TIMESTAMPTZ DEFAULT NULL,
	osc_version TEXT DEFAULT '1.0',
    accounting_category varchar(256),
	CONSTRAINT pk_impact_type PRIMARY KEY ( osc_id ),
	CONSTRAINT fk_impact_type_osc_creator_user_id FOREIGN KEY ( osc_creator_user_id ) REFERENCES osc_physrisk_backend.user(osc_id),
	CONSTRAINT fk_impact_type_osc_last_modifier_user_id FOREIGN KEY ( osc_last_modifier_user_id ) REFERENCES osc_physrisk_backend.user(osc_id),
	CONSTRAINT fk_impact_type_osc_deleter_user_id FOREIGN KEY ( osc_deleter_user_id ) REFERENCES osc_physrisk_backend.user(osc_id)
 ); 
COMMENT ON TABLE osc_physrisk_analysis_results.impact_type IS 'A lookup table to classify and constrain types of damage/disruption that could occur to an asset due to its vulnerability to a hazard.';


CREATE TABLE osc_physrisk_analysis_results.portfolio_impact ( 
	osc_id UUID  DEFAULT gen_random_UUID () NOT NULL,
	osc_name VARCHAR(256) NOT NULL,
	osc_name_display VARCHAR(256),
	osc_abbreviation VARCHAR(8),
	osc_description_full  TEXT NOT NULL,
	osc_description_short  VARCHAR(256) NOT NULL,
    osc_tags hstore DEFAULT NULL,
	osc_datetime_created TIMESTAMPTZ NOT NULL,
	osc_creator_user_id BIGINT NOT NULL,
	osc_datetime_last_modified TIMESTAMPTZ NOT NULL,
	osc_last_modifier_user_id BIGINT NOT NULL,
	osc_is_deleted BOOLEAN NOT NULL DEFAULT 'n',
	osc_deleter_user_id BIGINT DEFAULT NULL,
	osc_datetime_deleted TIMESTAMPTZ DEFAULT NULL,
	osc_tenant_id BIGINT NOT NULL DEFAULT 1,
	osc_culture VARCHAR(5) NOT NULL DEFAULT 'en',
	osc_checksum VARCHAR(40) DEFAULT NULL,
	osc_seq_num SMALLINT  NOT NULL Default 1,
	osc_translated_from_id UUID DEFAULT NULL,
	osc_is_active BOOLEAN NOT NULL DEFAULT 'y',
	osc_is_published BOOLEAN DEFAULT 'n',
	osc_publisher_id BIGINT DEFAULT NULL,
	osc_datetime_published TIMESTAMPTZ DEFAULT NULL,
	osc_version TEXT DEFAULT '1.0',
	osc_portfolio_id            UUID  NOT NULL  ,
	osc_scenario_id integer NOT NULL,
    osc_scenario_year smallint,
	analysis_osc_hazard_id	UUID NOT NULL,
    osc_impact_type_id integer NOT NULL,
	annual_exceedence_probability numeric,
	average_annual_loss numeric,
    value_total numeric,
    value_at_risk numeric,
    value_currency_alphabetic_code char(3),
	CONSTRAINT pk_portfolio_analysis PRIMARY KEY ( osc_id ),
	CONSTRAINT fk_portfolio_analysis_osc_id FOREIGN KEY ( osc_portfolio_id ) REFERENCES osc_physrisk_assets.portfolio(osc_id),
	CONSTRAINT fk_portfolio_osc_scenario_id FOREIGN KEY ( osc_scenario_id ) REFERENCES osc_physrisk_scenarios.scenario(osc_id),
	CONSTRAINT fk_portfolio_analysis_osc_impact_type_id FOREIGN KEY ( osc_impact_type_id ) REFERENCES osc_physrisk_analysis_results.impact_type(osc_id),
	CONSTRAINT fk_portfolio_analysis_osc_hazard_id FOREIGN KEY ( analysis_osc_hazard_id ) REFERENCES osc_physrisk_hazards.hazard(osc_id)   ,
	CONSTRAINT fk_portfolio_analysis_osc_creator_user_id FOREIGN KEY ( osc_creator_user_id ) REFERENCES osc_physrisk_backend.user(osc_id),
	CONSTRAINT fk_portfolio_analysis_osc_last_modifier_user_id FOREIGN KEY ( osc_last_modifier_user_id ) REFERENCES osc_physrisk_backend.user(osc_id),
	CONSTRAINT fk_portfolio_analysis_osc_deleter_user_id FOREIGN KEY ( osc_deleter_user_id ) REFERENCES osc_physrisk_backend.user(osc_id)  ,
	CONSTRAINT fk_portfolio_analysis_osc_tenant_id FOREIGN KEY ( osc_tenant_id ) REFERENCES osc_physrisk_backend.tenant(osc_id)
 );
COMMENT ON TABLE osc_physrisk_analysis_results.portfolio_impact IS 'The result of a physical risk & resilience analysis. The result is determined by the chosen scenario, year, and hazard, aggregating the results for all of the assets in a given portfolio. If multiple scenarios/years/hazards were chosen, there will be multiple other rows containing the combined set of results.';

CREATE TABLE osc_physrisk_analysis_results.asset_impact ( 
	osc_id UUID  DEFAULT gen_random_UUID () NOT NULL,
	osc_name VARCHAR(256) NOT NULL,
	osc_name_display VARCHAR(256),
	osc_abbreviation VARCHAR(8),
	osc_description_full  TEXT NOT NULL,
	osc_description_short  VARCHAR(256) NOT NULL,
    osc_tags hstore DEFAULT NULL,
	osc_datetime_created TIMESTAMPTZ NOT NULL,
	osc_creator_user_id BIGINT NOT NULL,
	osc_datetime_last_modified TIMESTAMPTZ NOT NULL,
	osc_last_modifier_user_id BIGINT NOT NULL,
	osc_is_deleted BOOLEAN NOT NULL DEFAULT 'n',
	osc_deleter_user_id BIGINT DEFAULT NULL,
	osc_datetime_deleted TIMESTAMPTZ DEFAULT NULL,
	osc_tenant_id BIGINT NOT NULL DEFAULT 1,
	osc_culture VARCHAR(5) NOT NULL DEFAULT 'en',
	osc_checksum VARCHAR(40) DEFAULT NULL,
	osc_seq_num SMALLINT  NOT NULL Default 1,
	osc_translated_from_id UUID DEFAULT NULL,
	osc_is_active BOOLEAN NOT NULL DEFAULT 'y',
	osc_is_published BOOLEAN DEFAULT 'n',
	osc_publisher_id BIGINT DEFAULT NULL,
	osc_datetime_published TIMESTAMPTZ DEFAULT NULL,
	osc_version TEXT DEFAULT '1.0',
	osc_asset_id            UUID  NOT NULL  ,
	osc_hazard_id UUID NOT NULL,
    osc_hazard_intensity numeric[],
	osc_scenario_id integer NOT NULL,
    osc_scenario_year smallint,
	analysis_data_source text NOT NULL,
	geo_location_name      	varchar(256),
    geo_location_address      	text ,
    geo_location_coordinates      	GEOGRAPHY  NOT NULL  ,
	geo_altitude numeric DEFAULT NULL, 
	geo_altitude_confidence numeric DEFAULT NULL,
	geo_overture_features			jsonb[], -- This location can be described in 0 or more Overture Map schemas to cover its land use, infrastructure, building extents, etc
	geo_h3_index H3INDEX NOT NULL,
    geo_h3_resolution INT2 NOT NULL,
	is_impacted boolean NOT NULL,
	is_historic_impact boolean NOT NULL,
	historic_impact_started timestamptz,
	historic_impact_ended timestamptz,
	osc_impact_type_id integer NOT NULL, -- this design assumes one row per impact type. If there are multiple potential impact types, there would be multiple rows.
	impact_data_raw jsonb NOT NULL, -- we recommend that this json includes schema references so a consuming application can use json schema for parsing.	
    impact_mean    numeric[],
	impact_std    numeric[],
	impact_distr_bin_edges    numeric[],
    impact_distr_p    numeric[],
    impact_exc_exceed_p    numeric[],
    impact_exc_values    numeric[],
	impact_return_periods jsonb, 
	value_total numeric,
    value_at_risk numeric,
    value_currency_alphabetic_code char(3),
    --parameter    numeric,
    exposure_function_osc_ids text, -- simple way of including a delimited list of model osc_ids. A brosc_idge tble would be a normalized way to do this, but would require a lookup table. TBD.
	exposure_data_raw jsonb NOT NULL, -- STORE RAW JSON, MAYBE OVERLAP WITH SOME COLUMNS BELOW?
	exposure_probability numeric,
	exposure_is_exposed bool,
	vulnerability_function_osc_ids text, -- simple way of including a delimited list of model osc_ids. A brosc_idge tble would be a normalized way to do this, but would require a lookup table. TBD.
	vulnerability_data_raw jsonb NOT NULL, -- STORE RAW JSON, MAYBE OVERLAP WITH SOME COLUMNS BELOW?
    financial_model_osc_ids text, -- simple way of including a delimited list of model osc_ids. A brosc_idge tble would be a normalized way to do this, but would require a lookup table. TBD.	
    CONSTRAINT pk_asset_analysis PRIMARY KEY ( osc_id ),
    CONSTRAINT ck_asset_analysis_h3_resolution CHECK (geo_h3_resolution >= 0 AND geo_h3_resolution <= 15),
	CONSTRAINT fk_asset_analysis_osc_asset_id FOREIGN KEY ( osc_asset_id ) REFERENCES osc_physrisk_assets.asset(osc_id),
	CONSTRAINT fk_asset_osc_scenario_id FOREIGN KEY ( osc_scenario_id ) REFERENCES osc_physrisk_scenarios.scenario(osc_id),
	CONSTRAINT fk_asset_analysis_osc_impact_type_id FOREIGN KEY ( osc_impact_type_id ) REFERENCES osc_physrisk_analysis_results.impact_type(osc_id),
	CONSTRAINT fk_asset_analysis_osc_hazard_id FOREIGN KEY ( osc_hazard_id ) REFERENCES osc_physrisk_hazards.hazard(osc_id)    ,
	CONSTRAINT fk_asset_analysis_osc_creator_user_id FOREIGN KEY ( osc_creator_user_id ) REFERENCES osc_physrisk_backend.user(osc_id),
	CONSTRAINT fk_asset_analysis_osc_last_modifier_user_id FOREIGN KEY ( osc_last_modifier_user_id ) REFERENCES osc_physrisk_backend.user(osc_id),
	CONSTRAINT fk_asset_analysis_osc_deleter_user_id FOREIGN KEY ( osc_deleter_user_id ) REFERENCES osc_physrisk_backend.user(osc_id)   ,
	CONSTRAINT fk_asset_analysis_osc_tenant_id FOREIGN KEY ( osc_tenant_id ) REFERENCES osc_physrisk_backend.tenant(osc_id)
 );
COMMENT ON TABLE osc_physrisk_analysis_results.asset_impact IS 'The result of a physical risk & resilience analysis for a particular asset. The result is determined by the chosen scenario, year, and hazard. If multiple scenarios/years/hazards were chosen, there will be multiple other rows containing the combined set of results.';

CREATE TABLE osc_physrisk_analysis_results.geolocated_precalculated_impact ( 
	osc_id	UUID  DEFAULT gen_random_UUID () NOT NULL,
	osc_name VARCHAR(256) NOT NULL,
	osc_name_display VARCHAR(256),
	osc_abbreviation VARCHAR(8),
	osc_description_full  TEXT NOT NULL,
	osc_description_short  VARCHAR(256) NOT NULL,
    osc_tags hstore DEFAULT NULL,
	osc_datetime_created TIMESTAMPTZ NOT NULL,
	osc_creator_user_id BIGINT NOT NULL,
	osc_datetime_last_modified TIMESTAMPTZ NOT NULL,
	osc_last_modifier_user_id BIGINT NOT NULL,
	osc_is_deleted BOOLEAN NOT NULL DEFAULT 'n',
	osc_deleter_user_id BIGINT DEFAULT NULL,
	osc_datetime_deleted TIMESTAMPTZ DEFAULT NULL,
	osc_tenant_id BIGINT NOT NULL DEFAULT 1,
	osc_culture VARCHAR(5) NOT NULL DEFAULT 'en',
	osc_checksum VARCHAR(40) DEFAULT NULL,
	osc_seq_num SMALLINT  NOT NULL Default 1,
	osc_translated_from_id UUID DEFAULT NULL,
	osc_is_active BOOLEAN NOT NULL DEFAULT 'y',
	osc_is_published BOOLEAN DEFAULT 'n',
	osc_publisher_id BIGINT DEFAULT NULL,
	osc_datetime_published TIMESTAMPTZ DEFAULT NULL,
	osc_version TEXT DEFAULT '1.0',
    osc_hazard_id UUID NOT NULL,
    osc_hazard_intensity numeric[],
	osc_scenario_id integer NOT NULL,
    osc_scenario_year smallint,
	analysis_data_source text NOT NULL,
	geo_location_name      	varchar(256),
    geo_location_address      	text ,
    geo_location_coordinates      	GEOGRAPHY  NOT NULL  ,
	geo_altitude numeric DEFAULT NULL, 
	geo_altitude_confidence numeric DEFAULT NULL,
	geo_overture_features			jsonb[], -- This location can be described in 0 or more Overture Map schemas to cover its land use, infrastructure, building extents, etc
	geo_h3_index H3INDEX NOT NULL,
    geo_h3_resolution INT2 NOT NULL,
	is_impacted boolean NOT NULL,
	is_historic_impact boolean NOT NULL,
	historic_impact_started timestamptz,
	historic_impact_ended timestamptz,
	impact_data_raw jsonb NOT NULL, -- we recommend that this json includes schema references so a consuming application can use json schema for parsing.	
    impact_mean    numeric[],
	impact_std    numeric[],
	CONSTRAINT pk_geolocated_precalculated_impact_osc_id PRIMARY KEY ( osc_id ),
	CONSTRAINT fk_geolocated_precalculated_impact_osc_hazard_id FOREIGN KEY ( osc_hazard_id ) REFERENCES osc_physrisk_hazards.hazard(osc_id),	
	CONSTRAINT fk_geolocated_precalculated_impact_osc_scenario_id FOREIGN KEY ( osc_scenario_id ) REFERENCES osc_physrisk_scenarios.scenario(osc_id),
	CONSTRAINT ck_geolocated_precalculated_impact_h3_resolution CHECK (geo_h3_resolution >= 0 AND geo_h3_resolution <= 15),
	CONSTRAINT fk_geolocated_precalculated_impact_osc_creator_user_id FOREIGN KEY ( osc_creator_user_id ) REFERENCES osc_physrisk_backend.user(osc_id),
	CONSTRAINT fk_geolocated_precalculated_impact_osc_last_modifier_user_id FOREIGN KEY ( osc_last_modifier_user_id ) REFERENCES osc_physrisk_backend.user(osc_id),
	CONSTRAINT fk_geolocated_precalculated_impact_osc_deleter_user_id FOREIGN KEY ( osc_deleter_user_id ) REFERENCES osc_physrisk_backend.user(osc_id) ,
	CONSTRAINT fk_geolocated_precalculated_impact_osc_tenant_id FOREIGN KEY ( osc_tenant_id ) REFERENCES osc_physrisk_backend.tenant(osc_id)
 );
 COMMENT ON TABLE osc_physrisk_analysis_results.geolocated_precalculated_impact IS 'To help with indexing and searching, geographic locations may have precalculated information for hazard impacts. This can be historic (it actually happened) or projected (it is likely to happen). Note that this information is not aware of or concerned by whether or which physical assets may be present insosc_ide its borders.';


-- SETUP PERMISSIONS FOR A READER SQL SERVICE ACCOUNT (CREATE THAT USING A DATABASE TOOL)
--GRANT USAGE ON SCHEMA "osc_physrisk_backend" TO physrisk_reader_service;
--GRANT SELECT ON ALL TABLES IN SCHEMA "osc_physrisk_backend" TO physrisk_reader_service;
--GRANT USAGE ON SCHEMA "osc_physrisk_scenarios" TO physrisk_reader_service;
--GRANT SELECT ON ALL TABLES IN SCHEMA "osc_physrisk_scenarios" TO physrisk_reader_service;
--GRANT USAGE ON SCHEMA "osc_physrisk_hazards" TO physrisk_reader_service;
--GRANT SELECT ON ALL TABLES IN SCHEMA "osc_physrisk_hazards" TO physrisk_reader_service;
--GRANT USAGE ON SCHEMA "osc_physrisk_models" TO physrisk_reader_service;
--GRANT SELECT ON ALL TABLES IN SCHEMA "osc_physrisk_models" TO physrisk_reader_service;
--GRANT USAGE ON SCHEMA "osc_physrisk_assets" TO physrisk_reader_service;
--GRANT SELECT ON ALL TABLES IN SCHEMA "osc_physrisk_assets" TO physrisk_reader_service;
--GRANT USAGE ON SCHEMA "osc_physrisk_analysis_results" TO physrisk_reader_service;
--GRANT SELECT ON ALL TABLES IN SCHEMA "osc_physrisk_analysis_results" TO physrisk_reader_service;

-- SETUP PERMISSIONS FOR A READER/WRITER SQL SERVICE ACCOUNT (CREATE THAT USING A DATABASE TOOL)
--GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA "osc_physrisk_backend" TO physrisk_readerwriter_service;
--GRANT ALL ON ALL TABLES IN SCHEMA "osc_physrisk_backend" TO physrisk_readerwriter_service;
--GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA "osc_physrisk_scenarios" TO physrisk_readerwriter_service;
--GRANT ALL ON ALL TABLES IN SCHEMA "osc_physrisk_scenarios" TO physrisk_readerwriter_service;
--GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA "osc_physrisk_hazards" TO physrisk_readerwriter_service;
--GRANT ALL ON ALL TABLES IN SCHEMA "osc_physrisk_hazards" TO physrisk_readerwriter_service;
--GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA "osc_physrisk_models" TO physrisk_readerwriter_service;
--GRANT ALL ON ALL TABLES IN SCHEMA "osc_physrisk_models" TO physrisk_readerwriter_service;
--GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA "osc_physrisk_assets" TO physrisk_readerwriter_service;
--GRANT ALL ON ALL TABLES IN SCHEMA "osc_physrisk_assets" TO physrisk_readerwriter_service;
--GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA "osc_physrisk_analysis_results" TO physrisk_readerwriter_service;
--GRANT ALL ON ALL TABLES IN SCHEMA "osc_physrisk_analysis_results" TO physrisk_readerwriter_service;

-- DATA IN ENGLISH STARTS
INSERT INTO osc_physrisk.osc_physrisk_backend.user
	(osc_id, osc_datetime_created, osc_creator_user_id, osc_datetime_last_modified, osc_last_modifier_user_id, osc_is_deleted, osc_deleter_user_id, osc_datetime_deleted, osc_user_name, osc_tenant_id, email_address, osc_name, osc_surname, osc_is_active)
VALUES 
	(1,'2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'osc',1,'example@email','Open-Source','Climate','y')
;
INSERT INTO osc_physrisk.osc_physrisk_backend.tenant
	(osc_id, osc_datetime_created, osc_creator_user_id, osc_datetime_last_modified, osc_last_modifier_user_id, osc_is_deleted, osc_deleter_user_id, osc_datetime_deleted, osc_tenancy_name, osc_name, osc_is_active)
VALUES 
	(1,'2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL,'Default','Default','y');

INSERT INTO osc_physrisk.osc_physrisk_scenarios.scenario
	(osc_id, osc_description_full, osc_description_short, osc_name_display, osc_name, osc_tags, osc_datetime_created, osc_creator_user_id, osc_datetime_last_modified, osc_last_modifier_user_id, osc_is_deleted, osc_deleter_user_id, osc_datetime_deleted, osc_culture, osc_checksum, osc_seq_num, osc_translated_from_id, osc_is_active, osc_is_published, osc_publisher_id, osc_datetime_published)
VALUES 
	(-1, 'Unknown/Not Selected', 'Unknown/Not Selected', 'Unknown/Not Selected', 'Unknown/Not Selected','key1=>value1_en,key2=>value2_en', '2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'en', 'f098938cd8cc7c4f1c71c8e97db0f075',1,-1, 'y','y', 1,'2024-07-15T00:00:01Z')
;
INSERT INTO osc_physrisk.osc_physrisk_scenarios.scenario
	(osc_id, osc_description_full, osc_description_short, osc_name_display, osc_name,osc_tags,  osc_datetime_created, osc_creator_user_id, osc_datetime_last_modified, osc_last_modifier_user_id, osc_is_deleted, osc_deleter_user_id, osc_datetime_deleted, osc_culture, osc_checksum, osc_seq_num, osc_translated_from_id, osc_is_active, osc_is_published, osc_publisher_id, osc_datetime_published)
VALUES 
	(0, 'History (before 2014). See "Shared Socioeconomic Pathways in the IPCC Sixth Assessment Report" (https://www.ipcc.ch/report/sixth-assessment-report-working-group-i/).', 'History (before 2014)', 'History (- 2014)', 'History (- 2014)','key1=>value3_en,key2=>value4_en','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'en', 'osc_checksum',1,0, 'y','y', 1,'2024-07-15T00:00:01Z')
;
INSERT INTO osc_physrisk.osc_physrisk_scenarios.scenario
	(osc_id, osc_description_full, osc_description_short, osc_name_display, osc_name, osc_tags, osc_datetime_created, osc_creator_user_id, osc_datetime_last_modified, osc_last_modifier_user_id, osc_is_deleted, osc_deleter_user_id, osc_datetime_deleted, osc_culture, osc_checksum, osc_seq_num, osc_translated_from_id, osc_is_active, osc_is_published, osc_publisher_id, osc_datetime_published)
VALUES 
	(1, 'SSP1-1.9 -  very low GHG emissions: CO2 emissions cut to net zero around 2050. See "Shared Socioeconomic Pathways in the IPCC Sixth Assessment Report" (https://www.ipcc.ch/report/sixth-assessment-report-working-group-i/).', 'SSP1-1.9', 'SSP1-1.9', 'SSP1-1.9','key1=>value1_en,key2=>value2_en','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'en', 'osc_checksum',1,1, 'y','y', 1,'2024-07-15T00:00:01Z')
;
INSERT INTO osc_physrisk.osc_physrisk_scenarios.scenario
	(osc_id, osc_description_full, osc_description_short, osc_name_display, osc_name,osc_tags,  osc_datetime_created, osc_creator_user_id, osc_datetime_last_modified, osc_last_modifier_user_id, osc_is_deleted, osc_deleter_user_id, osc_datetime_deleted, osc_culture, osc_checksum, osc_seq_num, osc_translated_from_id, osc_is_active, osc_is_published, osc_publisher_id, osc_datetime_published)
VALUES 
	(2, 'SSP1-2.6 - low GHG emissions: CO2 emissions cut to net zero around 2075. See "Shared Socioeconomic Pathways in the IPCC Sixth Assessment Report" (https://www.ipcc.ch/report/sixth-assessment-report-working-group-i/).', 'SSP1-2.6', 'SSP1-2.6', 'SSP1-2.6','key1=>value3_en,key2=>value4_en','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'en', 'osc_checksum',1,2, 'y','y', 1,'2024-07-15T00:00:01Z')
;
INSERT INTO osc_physrisk.osc_physrisk_scenarios.scenario
	(osc_id, osc_description_full, osc_description_short, osc_name_display, osc_name, osc_tags, osc_datetime_created, osc_creator_user_id, osc_datetime_last_modified, osc_last_modifier_user_id, osc_is_deleted, osc_deleter_user_id, osc_datetime_deleted, osc_culture, osc_checksum, osc_seq_num, osc_translated_from_id, osc_is_active, osc_is_published, osc_publisher_id, osc_datetime_published)
VALUES 
	(3, 'SSP2-4.5 - intermediate GHG emissions: CO2 emissions around current levels until 2050, then falling but not reaching net zero by 2100. See "Shared Socioeconomic Pathways in the IPCC Sixth Assessment Report" (https://www.ipcc.ch/report/sixth-assessment-report-working-group-i/).', 'SSP2-4.5', 'SSP2-4.5', 'SSP2-4.5','key1=>value1_en,key2=>value2_en','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'en', 'osc_checksum',1,3, 'y','y', 1,'2024-07-15T00:00:01Z')
;
INSERT INTO osc_physrisk.osc_physrisk_scenarios.scenario
	(osc_id, osc_description_full, osc_description_short, osc_name_display, osc_name, osc_tags, osc_datetime_created, osc_creator_user_id, osc_datetime_last_modified, osc_last_modifier_user_id, osc_is_deleted, osc_deleter_user_id, osc_datetime_deleted, osc_culture, osc_checksum, osc_seq_num, osc_translated_from_id, osc_is_active, osc_is_published, osc_publisher_id, osc_datetime_published)
VALUES 
	(4, 'SSP3-7.0 - high GHG emissions: CO2 emissions double by 2100. See "Shared Socioeconomic Pathways in the IPCC Sixth Assessment Report" (https://www.ipcc.ch/report/sixth-assessment-report-working-group-i/).', 'SSP3-7.0', 'SSP3-7.0', 'SSP3-7.0','key1=>value1_en,key2=>value2_en','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'en', 'osc_checksum',1,4, 'y','y', 1,'2024-07-15T00:00:01Z')
;
INSERT INTO osc_physrisk.osc_physrisk_scenarios.scenario
	(osc_id, osc_description_full, osc_description_short, osc_name_display, osc_name, osc_tags, osc_datetime_created, osc_creator_user_id, osc_datetime_last_modified, osc_last_modifier_user_id, osc_is_deleted, osc_deleter_user_id, osc_datetime_deleted, osc_culture, osc_checksum, osc_seq_num, osc_translated_from_id, osc_is_active, osc_is_published, osc_publisher_id, osc_datetime_published)
VALUES 
	(5, 'SSP5-8.5 - very high GHG emissions: CO2 emissions triple by 2075. See "Shared Socioeconomic Pathways in the IPCC Sixth Assessment Report" (https://www.ipcc.ch/report/sixth-assessment-report-working-group-i/).', 'SSP5-8.5', 'SSP5-8.5', 'SSP5-8.5','key1=>value5_en,key2=>value6_en','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'en', 'osc_checksum',1,5, 'y','y', 1,'2024-07-15T00:00:01Z')
;
INSERT INTO osc_physrisk.osc_physrisk_scenarios.scenario
	(osc_id, osc_description_full, osc_description_short, osc_name_display, osc_name, osc_tags, osc_datetime_created, osc_creator_user_id, osc_datetime_last_modified, osc_last_modifier_user_id, osc_is_deleted, osc_deleter_user_id, osc_datetime_deleted, osc_culture, osc_checksum, osc_seq_num, osc_translated_from_id, osc_is_active, osc_is_published, osc_publisher_id, osc_datetime_published)
VALUES 
	(6, 'RCP2.6 - Peak in radiative forcing at ~ 3 W/m2 before 2100 and decline. See "REPRESENTATIVE CONCENTRATION PATHWAYS (RCPs)" (https://sedac.ciesin.columbia.edu/ddc/ar5_scenario_process/RCPs.html)', 'RCP2.6', 'RCP2.6', 'RCP2.6','key1=>value1_en,key2=>value2_en','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'en', 'osc_checksum',1,6, 'y','y', 1,'2024-07-15T00:00:01Z')
;
INSERT INTO osc_physrisk.osc_physrisk_scenarios.scenario
	(osc_id, osc_description_full, osc_description_short, osc_name_display, osc_name, osc_tags, osc_datetime_created, osc_creator_user_id, osc_datetime_last_modified, osc_last_modifier_user_id, osc_is_deleted, osc_deleter_user_id, osc_datetime_deleted, osc_culture, osc_checksum, osc_seq_num, osc_translated_from_id, osc_is_active, osc_is_published, osc_publisher_id, osc_datetime_published)
VALUES 
	(7, 'RCP4.5 - Stabilization without overshoot pathway to 4.5 W/m2 at stabilization after 2100. See "REPRESENTATIVE CONCENTRATION PATHWAYS (RCPs)" (https://sedac.ciesin.columbia.edu/ddc/ar5_scenario_process/RCPs.html)', 'RCP4.5', 'RCP4.5', 'RCP4.5','key1=>value1_en,key2=>value2_en','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'en', 'osc_checksum',1,7, 'y','y', 1,'2024-07-15T00:00:01Z')
;
INSERT INTO osc_physrisk.osc_physrisk_scenarios.scenario
	(osc_id, osc_description_full, osc_description_short, osc_name_display, osc_name, osc_tags, osc_datetime_created, osc_creator_user_id, osc_datetime_last_modified, osc_last_modifier_user_id, osc_is_deleted, osc_deleter_user_id, osc_datetime_deleted, osc_culture, osc_checksum, osc_seq_num, osc_translated_from_id, osc_is_active, osc_is_published, osc_publisher_id, osc_datetime_published)
VALUES 
	(8, 'RCP6 - Stabilization without overshoot pathway to 6 W/m2 at stabilization after 2100. See "REPRESENTATIVE CONCENTRATION PATHWAYS (RCPs)" (https://sedac.ciesin.columbia.edu/ddc/ar5_scenario_process/RCPs.html)', 'RCP6', 'RCP6', 'RCP6','key1=>value1_en,key2=>value2_en','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'en', 'osc_checksum',1,8, 'y','y', 1,'2024-07-15T00:00:01Z')
;
INSERT INTO osc_physrisk.osc_physrisk_scenarios.scenario
	(osc_id, osc_description_full, osc_description_short, osc_name_display, osc_name,osc_tags,  osc_datetime_created, osc_creator_user_id, osc_datetime_last_modified, osc_last_modifier_user_id, osc_is_deleted, osc_deleter_user_id, osc_datetime_deleted, osc_culture, osc_checksum, osc_seq_num, osc_translated_from_id, osc_is_active, osc_is_published, osc_publisher_id, osc_datetime_published)
VALUES 
	(9, 'RCP8.5 - Rising radiative forcing pathway leading to 8.5 W/m2 in 2100. See "REPRESENTATIVE CONCENTRATION PATHWAYS (RCPs)" (https://sedac.ciesin.columbia.edu/ddc/ar5_scenario_process/RCPs.html)', 'RCP8.5', 'RCP8.5', 'RCP8.5','key1=>value1_en,key2=>value2_en','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'en', 'osc_checksum',1,9, 'y','y', 1,'2024-07-15T00:00:01Z')
;

INSERT INTO osc_physrisk.osc_physrisk_analysis_results.impact_type
	(osc_id, osc_description_full, osc_description_short, osc_name_display, osc_name, osc_tags, osc_datetime_created, osc_creator_user_id, osc_datetime_last_modified, osc_last_modifier_user_id, osc_is_deleted, osc_deleter_user_id, osc_datetime_deleted, osc_culture, osc_checksum, osc_seq_num, osc_translated_from_id, osc_is_active, osc_is_published, osc_publisher_id, osc_datetime_published)
VALUES 
	(-1, 'Unknown Damage or Disruption', 'Unknown Damage or Disruption', 'Unknown Damage or Disruption', 'Unknown Damage or Disruption','key1=>value1_en,key2=>value2_en','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'f',NULL,NULL, 'en', 'osc_checksum',1,1, 't',  't',1 ,'2024-07-15T00:00:01Z')
;
INSERT INTO osc_physrisk.osc_physrisk_analysis_results.impact_type
	(osc_id, osc_name, osc_name_display, osc_description_full, osc_description_short, osc_tags, osc_datetime_created, osc_creator_user_id, osc_datetime_last_modified, osc_last_modifier_user_id, osc_is_deleted, osc_deleter_user_id, osc_datetime_deleted, osc_culture, osc_checksum, osc_seq_num, osc_translated_from_id, osc_is_active, osc_is_published, osc_publisher_id, osc_datetime_published, accounting_category)
VALUES 
	(1, 'Asset repairs and construction', 'Asset repairs and construction', 'Asset repairs and construction','Asset repairs and construction', 'key1=>value1_fr,key2=>value2_fr', '2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1, 'false',NULL,NULL, 'en', 'osc_checksum',1,1, 't',  't',1 ,'2024-07-15T00:00:01Z','Capex' );
INSERT INTO osc_physrisk.osc_physrisk_analysis_results.impact_type
	(osc_id, osc_name, osc_name_display, osc_description_full, osc_description_short, osc_tags, osc_datetime_created, osc_creator_user_id, osc_datetime_last_modified, osc_last_modifier_user_id, osc_is_deleted, osc_deleter_user_id, osc_datetime_deleted, osc_culture, osc_checksum, osc_seq_num, osc_translated_from_id, osc_is_active, osc_is_published, osc_publisher_id, osc_datetime_published, accounting_category)
VALUES 
	(2, 'Revenue loss due to asset restoration', 'Revenue loss due to asset restoration', 'Revenue loss due to asset restoration','Revenue loss due to asset restoration', 'key1=>value1_fr,key2=>value2_fr', '2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1, 'false',NULL,NULL, 'en', 'osc_checksum',1,1, 't',  't',1 ,'2024-07-15T00:00:01Z','Revenue' );
INSERT INTO osc_physrisk.osc_physrisk_analysis_results.impact_type
	(osc_id, osc_name, osc_name_display, osc_description_full, osc_description_short, osc_tags, osc_datetime_created, osc_creator_user_id, osc_datetime_last_modified, osc_last_modifier_user_id, osc_is_deleted, osc_deleter_user_id, osc_datetime_deleted, osc_culture, osc_checksum, osc_seq_num, osc_translated_from_id, osc_is_active, osc_is_published, osc_publisher_id, osc_datetime_published, accounting_category)
VALUES 
	(3, 'Revenue loss due to productivity impact', 'Revenue loss due to productivity impact', 'Revenue loss due to productivity impact','Revenue loss due to productivity impact', 'key1=>value1_fr,key2=>value2_fr', '2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1, 'false',NULL,NULL, 'en', 'osc_checksum',1,1, 't',  't',1 ,'2024-07-15T00:00:01Z','Revenue' );
INSERT INTO osc_physrisk.osc_physrisk_analysis_results.impact_type
	(osc_id, osc_name, osc_name_display, osc_description_full, osc_description_short, osc_tags, osc_datetime_created, osc_creator_user_id, osc_datetime_last_modified, osc_last_modifier_user_id, osc_is_deleted, osc_deleter_user_id, osc_datetime_deleted, osc_culture, osc_checksum, osc_seq_num, osc_translated_from_id, osc_is_active, osc_is_published, osc_publisher_id, osc_datetime_published, accounting_category)
VALUES 
	(4, 'Recurring cost increase (chronic)', 'Recurring cost increase (chronic)', 'Recurring cost increase (chronic)','Recurring cost increase (chronic)', 'key1=>value1_fr,key2=>value2_fr', '2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1, 'false',NULL,NULL, 'en', 'osc_checksum',1,1, 't',  't',1 ,'2024-07-15T00:00:01Z','OpEx' );
INSERT INTO osc_physrisk.osc_physrisk_analysis_results.impact_type
	(osc_id, osc_name, osc_name_display, osc_description_full, osc_description_short, osc_tags, osc_datetime_created, osc_creator_user_id, osc_datetime_last_modified, osc_last_modifier_user_id, osc_is_deleted, osc_deleter_user_id, osc_datetime_deleted, osc_culture, osc_checksum, osc_seq_num, osc_translated_from_id, osc_is_active, osc_is_published, osc_publisher_id, osc_datetime_published, accounting_category)
VALUES 
	(5, 'Recurring cost increase (acute)', 'Recurring cost increase (acute)', 'Recurring cost increase (acute)','Recurring cost increase (acute)', 'key1=>value1_fr,key2=>value2_fr', '2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1, 'false',NULL,NULL, 'en', 'osc_checksum',1,1, 't',  't',1 ,'2024-07-15T00:00:01Z','OpEx' );
INSERT INTO osc_physrisk.osc_physrisk_hazards.hazard
	(osc_id, osc_name, osc_name_display, osc_description_full, osc_description_short, osc_tags, osc_datetime_created, osc_creator_user_id, osc_datetime_last_modified, osc_last_modifier_user_id, osc_is_deleted, osc_deleter_user_id, osc_datetime_deleted, osc_culture, osc_checksum, osc_seq_num, osc_translated_from_id, osc_is_active, osc_is_published, osc_publisher_id, osc_datetime_published)
VALUES 
	('8159d927-e596-444d-8f1a-494494339fad', 'Unknown hazard/Not selected', 'Unknown hazard/Not selected', 'Unknown hazard/Not selected', 'Unknown hazard/Not selected', 'key1=>value1_es,key2=>value2_es','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'en', 'osc_checksum',1, NULL,'y','y',1,'2024-07-15T00:00:01Z')
;
INSERT INTO osc_physrisk.osc_physrisk_hazards.hazard
	(osc_id, osc_name, osc_name_display, osc_description_full, osc_description_short, osc_tags, osc_datetime_created, osc_creator_user_id, osc_datetime_last_modified, osc_last_modifier_user_id, osc_is_deleted, osc_deleter_user_id, osc_datetime_deleted, osc_culture, osc_checksum, osc_seq_num, osc_translated_from_id, osc_is_active, osc_is_published, osc_publisher_id, osc_datetime_published)
VALUES 
	('63ed7943-c4c4-43ea-abd2-86bb1997a094', 'Riverine Inundation', 'Riverine Inundation', 'Riverine Inundation', 'Riverine Inundation', 'key1=>value1_es,key2=>value2_es','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'en', 'osc_checksum',1, NULL,'y', 'y',1,'2024-07-15T00:00:01Z')
;
INSERT INTO osc_physrisk.osc_physrisk_hazards.hazard
	(osc_id, osc_name, osc_name_display, osc_description_full, osc_description_short, osc_tags, osc_datetime_created, osc_creator_user_id, osc_datetime_last_modified, osc_last_modifier_user_id, osc_is_deleted, osc_deleter_user_id, osc_datetime_deleted, osc_culture, osc_checksum, osc_seq_num, osc_translated_from_id, osc_is_active, osc_is_published, osc_publisher_id, osc_datetime_published)
VALUES 
	('28a095cd-4cde-40a1-90d9-cbb0ca673c06', 'Coastal Inundation', 'Coastal Inundation', 'Coastal Inundation', 'Coastal Inundation', 'key1=>value1_es,key2=>value2_es','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'en', 'osc_checksum',1, NULL,'y','y',1,'2024-07-15T00:00:01Z')
;
INSERT INTO osc_physrisk.osc_physrisk_hazards.hazard
	(osc_id, osc_name, osc_name_display, osc_description_full, osc_description_short, osc_tags, osc_datetime_created, osc_creator_user_id, osc_datetime_last_modified, osc_last_modifier_user_id, osc_is_deleted, osc_deleter_user_id, osc_datetime_deleted, osc_culture, osc_checksum, osc_seq_num, osc_translated_from_id, osc_is_active, osc_is_published, osc_publisher_id, osc_datetime_published)
VALUES 
	('d08db675-ee1e-48fe-b9e1-b0da27de8f2b', 'Chronic Heat', 'Chronic Heat', 'Chronic Heat', 'Chronic Heat', 'key1=>value1_es,key2=>value2_es','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'en', 'osc_checksum',1, NULL,'y','y',1,'2024-07-15T00:00:01Z')
;
INSERT INTO osc_physrisk.osc_physrisk_hazards.hazard
	(osc_id, osc_name, osc_name_display, osc_description_full, osc_description_short, osc_tags, osc_datetime_created, osc_creator_user_id, osc_datetime_last_modified, osc_last_modifier_user_id, osc_is_deleted, osc_deleter_user_id, osc_datetime_deleted, osc_culture, osc_checksum, osc_seq_num, osc_translated_from_id, osc_is_active, osc_is_published, osc_publisher_id, osc_datetime_published)
VALUES 
	('64fee0d3-b78b-49bf-911a-029695585d6a', 'Fire', 'Fire', 'Fire', 'Fire', 'key1=>value1_es,key2=>value2_es','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'en', 'osc_checksum',1, NULL,'y','y',1,'2024-07-15T00:00:01Z')
;
INSERT INTO osc_physrisk.osc_physrisk_hazards.hazard
	(osc_id, osc_name, osc_name_display, osc_description_full, osc_description_short, osc_tags, osc_datetime_created, osc_creator_user_id, osc_datetime_last_modified, osc_last_modifier_user_id, osc_is_deleted, osc_deleter_user_id, osc_datetime_deleted, osc_culture, osc_checksum, osc_seq_num, osc_translated_from_id, osc_is_active, osc_is_published, osc_publisher_id, osc_datetime_published)
VALUES 
	('35ace20f-86dc-4735-9536-129b51b6d25d', 'Drought', 'Drought', 'Drought', 'Drought', 'key1=>value1_es,key2=>value2_es','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'en', 'osc_checksum',1, NULL,'y','y',1,'2024-07-15T00:00:01Z')
;
INSERT INTO osc_physrisk.osc_physrisk_hazards.hazard
	(osc_id, osc_name, osc_name_display, osc_description_full, osc_description_short, osc_tags, osc_datetime_created, osc_creator_user_id, osc_datetime_last_modified, osc_last_modifier_user_id, osc_is_deleted, osc_deleter_user_id, osc_datetime_deleted, osc_culture, osc_checksum, osc_seq_num, osc_translated_from_id, osc_is_active, osc_is_published, osc_publisher_id, osc_datetime_published)
VALUES 
	('2faed491-2c5d-499e-9568-fad6e3b3c0ec', 'Precipitation', 'Precipitation', 'Precipitation', 'Precipitation', 'key1=>value1_es,key2=>value2_es','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'en', 'osc_checksum',1, NULL,'y','y',1,'2024-07-15T00:00:01Z')
;
INSERT INTO osc_physrisk.osc_physrisk_hazards.hazard
	(osc_id, osc_name, osc_name_display, osc_description_full, osc_description_short, osc_tags, osc_datetime_created, osc_creator_user_id, osc_datetime_last_modified, osc_last_modifier_user_id, osc_is_deleted, osc_deleter_user_id, osc_datetime_deleted, osc_culture, osc_checksum, osc_seq_num, osc_translated_from_id, osc_is_active, osc_is_published, osc_publisher_id, osc_datetime_published)
VALUES 
	('e4e4e199-367e-4568-824d-3f916e355567', 'Hail', 'Hail', 'Hail', 'Hail', 'key1=>value1_es,key2=>value2_es','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'en', 'osc_checksum',1, NULL,'y','y',1,'2024-07-15T00:00:01Z')
;
INSERT INTO osc_physrisk.osc_physrisk_hazards.hazard
	(osc_id, osc_name, osc_name_display, osc_description_full, osc_description_short, osc_tags, osc_datetime_created, osc_creator_user_id, osc_datetime_last_modified, osc_last_modifier_user_id, osc_is_deleted, osc_deleter_user_id, osc_datetime_deleted, osc_culture, osc_checksum, osc_seq_num, osc_translated_from_id, osc_is_active, osc_is_published, osc_publisher_id, osc_datetime_published)
VALUES 
	('0184b858-404d-4282-8f0d-2b4c42f7acd7', 'Wind', 'Wind', 'Wind', 'Wind', 'key1=>value1_es,key2=>value2_es','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'en', 'osc_checksum',1, NULL,'y','y',1,'2024-07-15T00:00:01Z')
;
INSERT INTO osc_physrisk.osc_physrisk_hazards.hazard
	(osc_id, osc_name, osc_name_display, osc_description_full, osc_description_short, osc_tags, osc_datetime_created, osc_creator_user_id, osc_datetime_last_modified, osc_last_modifier_user_id, osc_is_deleted, osc_deleter_user_id, osc_datetime_deleted, osc_culture, osc_checksum, osc_seq_num, osc_translated_from_id, osc_is_active, osc_is_published, osc_publisher_id, osc_datetime_published)
VALUES 
	('338ea109-828e-4aaf-b212-12d8eaf70a7e', 'Combined Inundation', 'Combined Inundation', 'Combined Inundation', 'Combined Inundation', 'key1=>value1_es,key2=>value2_es','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'en', 'osc_checksum',1, NULL,'y','y',1,'2024-07-15T00:00:01Z')
;
INSERT INTO osc_physrisk.osc_physrisk_hazards.hazard
	(osc_id, osc_name, osc_name_display, osc_description_full, osc_description_short, osc_tags, osc_datetime_created, osc_creator_user_id, osc_datetime_last_modified, osc_last_modifier_user_id, osc_is_deleted, osc_deleter_user_id, osc_datetime_deleted, osc_culture, osc_checksum, osc_seq_num, osc_translated_from_id, osc_is_active, osc_is_published, osc_publisher_id, osc_datetime_published)
VALUES 
	('29514258-18cb-4f2b-8798-203e0d513803', 'Water Risk', 'Water Risk', 'Water Risk', 'Water Risk', 'key1=>value1_es,key2=>value2_es','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'en', 'osc_checksum',1, NULL,'y','y',1,'2024-07-15T00:00:01Z')
;
INSERT INTO osc_physrisk.osc_physrisk_hazards.hazard_indicator
	(osc_id, osc_name, osc_name_display, osc_description_full, osc_description_short, osc_tags, osc_datetime_created, osc_creator_user_id, osc_datetime_last_modified, osc_last_modifier_user_id, osc_is_deleted, osc_deleter_user_id, osc_datetime_deleted, osc_culture, osc_checksum, osc_seq_num, osc_translated_from_id, osc_is_active, osc_is_published, osc_publisher_id, osc_datetime_published, osc_hazard_id)
VALUES 
	('57a7df66-420d-4730-9669-1547f8200272', 'Flood depth (TUDelft)', 'Flood depth (TUDelft)', 'Flood depth (TUDelft)', 'Flood depth (TUDelft)', 'key1=>value1_es,key2=>value2_es','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'en', 'osc_checksum',1, NULL,'y','y',1,'2024-07-15T00:00:01Z', '63ed7943-c4c4-43ea-abd2-86bb1997a094')
;
INSERT INTO osc_physrisk.osc_physrisk_hazards.hazard_indicator
	(osc_id, osc_name, osc_name_display, osc_description_full, osc_description_short, osc_tags, osc_datetime_created, osc_creator_user_id, osc_datetime_last_modified, osc_last_modifier_user_id, osc_is_deleted, osc_deleter_user_id, osc_datetime_deleted, osc_culture, osc_checksum, osc_seq_num, osc_translated_from_id, osc_is_active, osc_is_published, osc_publisher_id, osc_datetime_published, osc_hazard_id)
VALUES 
	('5fb27cc6-ee01-4133-b2e9-6c1f22ed5b40', 'Flood depth/GFDL-ESM2M (WRI)', 'Flood depth/GFDL-ESM2M (WRI)', 'Flood depth/GFDL-ESM2M (WRI)', 'Flood depth/GFDL-ESM2M (WRI)', 'key1=>value1_es,key2=>value2_es','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'en', 'osc_checksum',1, NULL,'y','y',1,'2024-07-15T00:00:01Z', '63ed7943-c4c4-43ea-abd2-86bb1997a094')
;
INSERT INTO osc_physrisk.osc_physrisk_hazards.hazard_indicator
	(osc_id, osc_name, osc_name_display, osc_description_full, osc_description_short, osc_tags, osc_datetime_created, osc_creator_user_id, osc_datetime_last_modified, osc_last_modifier_user_id, osc_is_deleted, osc_deleter_user_id, osc_datetime_deleted, osc_culture, osc_checksum, osc_seq_num, osc_translated_from_id, osc_is_active, osc_is_published, osc_publisher_id, osc_datetime_published, osc_hazard_id)
VALUES 
	('79555143-ba2a-47b0-bbe7-7aac3685dedb', 'Flood depth/HadGEM2-ES (WRI)', 'Flood depth/HadGEM2-ES (WRI)', 'Flood depth/HadGEM2-ES (WRI)', 'Flood depth/HadGEM2-ES (WRI)', 'key1=>value1_es,key2=>value2_es','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'en', 'osc_checksum',1, NULL,'y','y',1,'2024-07-15T00:00:01Z', '63ed7943-c4c4-43ea-abd2-86bb1997a094')
;
INSERT INTO osc_physrisk.osc_physrisk_hazards.hazard_indicator
	(osc_id, osc_name, osc_name_display, osc_description_full, osc_description_short, osc_tags, osc_datetime_created, osc_creator_user_id, osc_datetime_last_modified, osc_last_modifier_user_id, osc_is_deleted, osc_deleter_user_id, osc_datetime_deleted, osc_culture, osc_checksum, osc_seq_num, osc_translated_from_id, osc_is_active, osc_is_published, osc_publisher_id, osc_datetime_published, osc_hazard_id)
VALUES 
	('6fe5ccb1-5d38-4a3e-b0a5-d4cc70981035', 'Flood depth/IPSL-CM5A-LR (WRI)', 'Flood depth/IPSL-CM5A-LR (WRI)', 'Flood depth/IPSL-CM5A-LR (WRI)', 'Flood depth/IPSL-CM5A-LR (WRI)', 'key1=>value1_es,key2=>value2_es','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'en', 'osc_checksum',1, NULL,'y','y',1,'2024-07-15T00:00:01Z', '63ed7943-c4c4-43ea-abd2-86bb1997a094')
;
INSERT INTO osc_physrisk.osc_physrisk_hazards.hazard_indicator
	(osc_id, osc_name, osc_name_display, osc_description_full, osc_description_short, osc_tags, osc_datetime_created, osc_creator_user_id, osc_datetime_last_modified, osc_last_modifier_user_id, osc_is_deleted, osc_deleter_user_id, osc_datetime_deleted, osc_culture, osc_checksum, osc_seq_num, osc_translated_from_id, osc_is_active, osc_is_published, osc_publisher_id, osc_datetime_published, osc_hazard_id)
VALUES 
	('e4f10569-95be-4b5b-8d34-763eb95e730b', 'Flood depth/MIROC-ESM-CHEM (WRI)', 'Flood depth/MIROC-ESM-CHEM (WRI)', 'Flood depth/MIROC-ESM-CHEM (WRI)', 'Flood depth/MIROC-ESM-CHEM (WRI)', 'key1=>value1_es,key2=>value2_es','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'en', 'osc_checksum',1, NULL,'y','y',1,'2024-07-15T00:00:01Z', '63ed7943-c4c4-43ea-abd2-86bb1997a094')
;
INSERT INTO osc_physrisk.osc_physrisk_hazards.hazard_indicator
	(osc_id, osc_name, osc_name_display, osc_description_full, osc_description_short, osc_tags, osc_datetime_created, osc_creator_user_id, osc_datetime_last_modified, osc_last_modifier_user_id, osc_is_deleted, osc_deleter_user_id, osc_datetime_deleted, osc_culture, osc_checksum, osc_seq_num, osc_translated_from_id, osc_is_active, osc_is_published, osc_publisher_id, osc_datetime_published, osc_hazard_id)
VALUES 
	('690e01eb-f7e6-4fbf-84e4-f8195656abb3', 'Flood depth/NorESM1-M (WRI)', 'Flood depth/NorESM1-M (WRI)', 'Flood depth/NorESM1-M (WRI)', 'Flood depth/NorESM1-M (WRI)', 'key1=>value1_es,key2=>value2_es','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'en', 'osc_checksum',1, NULL,'y','y',1,'2024-07-15T00:00:01Z', '63ed7943-c4c4-43ea-abd2-86bb1997a094')
;
INSERT INTO osc_physrisk.osc_physrisk_hazards.hazard_indicator
	(osc_id, osc_name, osc_name_display, osc_description_full, osc_description_short, osc_tags, osc_datetime_created, osc_creator_user_id, osc_datetime_last_modified, osc_last_modifier_user_id, osc_is_deleted, osc_deleter_user_id, osc_datetime_deleted, osc_culture, osc_checksum, osc_seq_num, osc_translated_from_id, osc_is_active, osc_is_published, osc_publisher_id, osc_datetime_published, osc_hazard_id)
VALUES 
	('5f396b97-badc-40d2-b0b3-c8be8f3053ba', 'Flood depth/baseline (WRI)', 'Flood depth/baseline (WRI)', 'Flood depth/baseline (WRI)', 'Flood depth/baseline (WRI)', 'key1=>value1_es,key2=>value2_es','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'en', 'osc_checksum',1, NULL,'y','y',1,'2024-07-15T00:00:01Z', '63ed7943-c4c4-43ea-abd2-86bb1997a094')
;
INSERT INTO osc_physrisk.osc_physrisk_hazards.hazard_indicator
	(osc_id, osc_name, osc_name_display, osc_description_full, osc_description_short, osc_tags, osc_datetime_created, osc_creator_user_id, osc_datetime_last_modified, osc_last_modifier_user_id, osc_is_deleted, osc_deleter_user_id, osc_datetime_deleted, osc_culture, osc_checksum, osc_seq_num, osc_translated_from_id, osc_is_active, osc_is_published, osc_publisher_id, osc_datetime_published, osc_hazard_id)
VALUES 
	('901cbd14-9223-4d36-8ab4-658945d913a4', 'Standard of protection (TUDelft)', 'Standard of protection (TUDelft)', 'Standard of protection (TUDelft)', 'Standard of protection (TUDelft)', 'key1=>value1_es,key2=>value2_es','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'en', 'osc_checksum',1, NULL,'y','y',1,'2024-07-15T00:00:01Z', '63ed7943-c4c4-43ea-abd2-86bb1997a094')
;
INSERT INTO osc_physrisk.osc_physrisk_hazards.hazard_indicator
	(osc_id, osc_name, osc_name_display, osc_description_full, osc_description_short, osc_tags, osc_datetime_created, osc_creator_user_id, osc_datetime_last_modified, osc_last_modifier_user_id, osc_is_deleted, osc_deleter_user_id, osc_datetime_deleted, osc_culture, osc_checksum, osc_seq_num, osc_translated_from_id, osc_is_active, osc_is_published, osc_publisher_id, osc_datetime_published, osc_hazard_id)
VALUES 
	('be44d6fb-08cb-4f52-8ff2-bf1b7366a7a0', 'Flood depth/5%, no subsosc_idence (WRI)', 'Flood depth/5%, no subsosc_idence (WRI)', 'Flood depth/5%, no subsosc_idence (WRI)', 'Flood depth/5%, no subsosc_idence (WRI)', 'key1=>value1_es,key2=>value2_es','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'en', 'osc_checksum',1, NULL,'y','y',1,'2024-07-15T00:00:01Z', '28a095cd-4cde-40a1-90d9-cbb0ca673c06')
;
INSERT INTO osc_physrisk.osc_physrisk_hazards.hazard_indicator
	(osc_id, osc_name, osc_name_display, osc_description_full, osc_description_short, osc_tags, osc_datetime_created, osc_creator_user_id, osc_datetime_last_modified, osc_last_modifier_user_id, osc_is_deleted, osc_deleter_user_id, osc_datetime_deleted, osc_culture, osc_checksum, osc_seq_num, osc_translated_from_id, osc_is_active, osc_is_published, osc_publisher_id, osc_datetime_published, osc_hazard_id)
VALUES 
	('c87fc5c3-c2ae-4732-ba52-7d9156044d7b', 'Flood depth/5%, with subsosc_idence (WRI)', 'Flood depth/5%, with subsosc_idence (WRI)', 'Flood depth/5%, with subsosc_idence (WRI)', 'Flood depth/5%, with subsosc_idence (WRI)', 'key1=>value1_es,key2=>value2_es','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'en', 'osc_checksum',1, NULL,'y','y',1,'2024-07-15T00:00:01Z', '28a095cd-4cde-40a1-90d9-cbb0ca673c06')
;
INSERT INTO osc_physrisk.osc_physrisk_hazards.hazard_indicator
	(osc_id, osc_name, osc_name_display, osc_description_full, osc_description_short, osc_tags, osc_datetime_created, osc_creator_user_id, osc_datetime_last_modified, osc_last_modifier_user_id, osc_is_deleted, osc_deleter_user_id, osc_datetime_deleted, osc_culture, osc_checksum, osc_seq_num, osc_translated_from_id, osc_is_active, osc_is_published, osc_publisher_id, osc_datetime_published, osc_hazard_id)
VALUES 
	('60c90be9-5cfb-4f6a-b9eb-e84e7da5a456', 'Flood depth/50%, no subsosc_idence (WRI)', 'Flood depth/50%, no subsosc_idence (WRI)', 'Flood depth/50%, no subsosc_idence (WRI)', 'Flood depth/50%, no subsosc_idence (WRI)', 'key1=>value1_es,key2=>value2_es','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'en', 'osc_checksum',1, NULL,'y','y',1,'2024-07-15T00:00:01Z', '28a095cd-4cde-40a1-90d9-cbb0ca673c06')
;
INSERT INTO osc_physrisk.osc_physrisk_hazards.hazard_indicator
	(osc_id, osc_name, osc_name_display, osc_description_full, osc_description_short, osc_tags, osc_datetime_created, osc_creator_user_id, osc_datetime_last_modified, osc_last_modifier_user_id, osc_is_deleted, osc_deleter_user_id, osc_datetime_deleted, osc_culture, osc_checksum, osc_seq_num, osc_translated_from_id, osc_is_active, osc_is_published, osc_publisher_id, osc_datetime_published, osc_hazard_id)
VALUES 
	('e7623e9e-649e-460a-8b81-ae9d01711f75', 'Flood depth/50%, with subsosc_idence (WRI)', 'Flood depth/50%, with subsosc_idence (WRI)', 'Flood depth/50%, with subsosc_idence (WRI)', 'Flood depth/50%, with subsosc_idence (WRI)', 'key1=>value1_es,key2=>value2_es','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'en', 'osc_checksum',1, NULL,'y','y',1,'2024-07-15T00:00:01Z', '28a095cd-4cde-40a1-90d9-cbb0ca673c06')
;
INSERT INTO osc_physrisk.osc_physrisk_hazards.hazard_indicator
	(osc_id, osc_name, osc_name_display, osc_description_full, osc_description_short, osc_tags, osc_datetime_created, osc_creator_user_id, osc_datetime_last_modified, osc_last_modifier_user_id, osc_is_deleted, osc_deleter_user_id, osc_datetime_deleted, osc_culture, osc_checksum, osc_seq_num, osc_translated_from_id, osc_is_active, osc_is_published, osc_publisher_id, osc_datetime_published, osc_hazard_id)
VALUES 
	('28fbe059-a661-4fe6-8ba7-0fa626a9312b', 'Flood depth/95%, no subsosc_idence (WRI)', 'Flood depth/95%, no subsosc_idence (WRI)', 'Flood depth/95%, no subsosc_idence (WRI)', 'Flood depth/95%, no subsosc_idence (WRI)', 'key1=>value1_es,key2=>value2_es','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'en', 'osc_checksum',1, NULL,'y','y',1,'2024-07-15T00:00:01Z', '28a095cd-4cde-40a1-90d9-cbb0ca673c06')
;
INSERT INTO osc_physrisk.osc_physrisk_hazards.hazard_indicator
	(osc_id, osc_name, osc_name_display, osc_description_full, osc_description_short, osc_tags, osc_datetime_created, osc_creator_user_id, osc_datetime_last_modified, osc_last_modifier_user_id, osc_is_deleted, osc_deleter_user_id, osc_datetime_deleted, osc_culture, osc_checksum, osc_seq_num, osc_translated_from_id, osc_is_active, osc_is_published, osc_publisher_id, osc_datetime_published, osc_hazard_id)
VALUES 
	('ea005e03-f025-4aa4-a37e-981eea5bcfdb', 'Flood depth/95%, with subsosc_idence (WRI)', 'Flood depth/95%, with subsosc_idence (WRI)', 'Flood depth/95%, with subsosc_idence (WRI)', 'Flood depth/95%, with subsosc_idence (WRI)', 'key1=>value1_es,key2=>value2_es','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'en', 'osc_checksum',1, NULL,'y','y',1,'2024-07-15T00:00:01Z', '28a095cd-4cde-40a1-90d9-cbb0ca673c06')
;
INSERT INTO osc_physrisk.osc_physrisk_hazards.hazard_indicator
	(osc_id, osc_name, osc_name_display, osc_description_full, osc_description_short, osc_tags, osc_datetime_created, osc_creator_user_id, osc_datetime_last_modified, osc_last_modifier_user_id, osc_is_deleted, osc_deleter_user_id, osc_datetime_deleted, osc_culture, osc_checksum, osc_seq_num, osc_translated_from_id, osc_is_active, osc_is_published, osc_publisher_id, osc_datetime_published, osc_hazard_id)
VALUES 
	('12651bc5-04a2-4225-ba25-f1c0e09bdb90', 'Flood depth/baseline, no subsosc_idence (WRI)', 'Flood depth/baseline, no subsosc_idence (WRI)', 'Flood depth/baseline, no subsosc_idence (WRI)', 'Flood depth/baseline, no subsosc_idence (WRI)', 'key1=>value1_es,key2=>value2_es','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'en', 'osc_checksum',1, NULL,'y','y',1,'2024-07-15T00:00:01Z', '28a095cd-4cde-40a1-90d9-cbb0ca673c06')
;
INSERT INTO osc_physrisk.osc_physrisk_hazards.hazard_indicator
	(osc_id, osc_name, osc_name_display, osc_description_full, osc_description_short, osc_tags, osc_datetime_created, osc_creator_user_id, osc_datetime_last_modified, osc_last_modifier_user_id, osc_is_deleted, osc_deleter_user_id, osc_datetime_deleted, osc_culture, osc_checksum, osc_seq_num, osc_translated_from_id, osc_is_active, osc_is_published, osc_publisher_id, osc_datetime_published, osc_hazard_id)
VALUES 
	('6ba57474-6c7a-4ea3-aca8-25e30f27cec1', 'Flood depth/baseline, with subsosc_idence (WRI)', 'Flood depth/baseline, with subsosc_idence (WRI)', 'Flood depth/baseline, with subsosc_idence (WRI)', 'Flood depth/baseline, with subsosc_idence (WRI)', 'key1=>value1_es,key2=>value2_es','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'en', 'osc_checksum',1, NULL,'y','y',1,'2024-07-15T00:00:01Z', '28a095cd-4cde-40a1-90d9-cbb0ca673c06')
;
INSERT INTO osc_physrisk.osc_physrisk_hazards.hazard_indicator
	(osc_id, osc_name, osc_name_display, osc_description_full, osc_description_short, osc_tags, osc_datetime_created, osc_creator_user_id, osc_datetime_last_modified, osc_last_modifier_user_id, osc_is_deleted, osc_deleter_user_id, osc_datetime_deleted, osc_culture, osc_checksum, osc_seq_num, osc_translated_from_id, osc_is_active, osc_is_published, osc_publisher_id, osc_datetime_published, osc_hazard_id)
VALUES 
	('e0b5afc2-eed8-4760-9667-c14fdbf374db', 'Days with average temperature above 25°C/ACCESS-CM2', 'Days with average temperature above 25°C/ACCESS-CM2', 'Days with average temperature above 25°C/ACCESS-CM2', 'Days with average temperature above 25°C/ACCESS-CM2', 'key1=>value1_en,key2=>value2_en','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'en', 'osc_checksum',1, NULL,'y','y',1,'2024-07-15T00:00:01Z', 'd08db675-ee1e-48fe-b9e1-b0da27de8f2b')
;
INSERT INTO osc_physrisk.osc_physrisk_hazards.hazard_indicator
	(osc_id, osc_name, osc_name_display, osc_description_full, osc_description_short, osc_tags, osc_datetime_created, osc_creator_user_id, osc_datetime_last_modified, osc_last_modifier_user_id, osc_is_deleted, osc_deleter_user_id, osc_datetime_deleted, osc_culture, osc_checksum, osc_seq_num, osc_translated_from_id, osc_is_active, osc_is_published, osc_publisher_id, osc_datetime_published, osc_hazard_id)
VALUES 
	('b795a8af-12cc-4773-83ee-a50badd1fe74', 'Days with average temperature above 25°C/CMCC-ESM2', 'Days with average temperature above 25°C/CMCC-ESM2', 'Days with average temperature above 25°C/CMCC-ESM2', 'Days with average temperature above 25°C/CMCC-ESM2', 'key1=>value1_en,key2=>value2_en','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'en', 'osc_checksum',1, NULL,'y','y',1,'2024-07-15T00:00:01Z', 'd08db675-ee1e-48fe-b9e1-b0da27de8f2b')
;
INSERT INTO osc_physrisk.osc_physrisk_hazards.hazard_indicator
	(osc_id, osc_name, osc_name_display, osc_description_full, osc_description_short, osc_tags, osc_datetime_created, osc_creator_user_id, osc_datetime_last_modified, osc_last_modifier_user_id, osc_is_deleted, osc_deleter_user_id, osc_datetime_deleted, osc_culture, osc_checksum, osc_seq_num, osc_translated_from_id, osc_is_active, osc_is_published, osc_publisher_id, osc_datetime_published, osc_hazard_id)
VALUES 
	('81213608-0a01-42b0-a54f-a070fb104b95', 'Days with average temperature above 25°C/CNRM-CM6-1', 'Days with average temperature above 25°C/CNRM-CM6-1', 'Days with average temperature above 25°C/CNRM-CM6-1', 'Days with average temperature above 25°C/CNRM-CM6-1', 'key1=>value1_en,key2=>value2_en','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'en', 'osc_checksum',1, NULL,'y','y',1,'2024-07-15T00:00:01Z', 'd08db675-ee1e-48fe-b9e1-b0da27de8f2b')
;
INSERT INTO osc_physrisk.osc_physrisk_hazards.hazard_indicator
	(osc_id, osc_name, osc_name_display, osc_description_full, osc_description_short, osc_tags, osc_datetime_created, osc_creator_user_id, osc_datetime_last_modified, osc_last_modifier_user_id, osc_is_deleted, osc_deleter_user_id, osc_datetime_deleted, osc_culture, osc_checksum, osc_seq_num, osc_translated_from_id, osc_is_active, osc_is_published, osc_publisher_id, osc_datetime_published, osc_hazard_id)
VALUES 
	('98692238-6a8f-4e58-a779-9f96eeaf1abd', 'Days with average temperature above 25°C/MIROC6', 'Days with average temperature above 25°C/MIROC6', 'Days with average temperature above 25°C/MIROC6', 'Days with average temperature above 25°C/MIROC6', 'key1=>value1_en,key2=>value2_en','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'en', 'osc_checksum',1, NULL,'y','y',1,'2024-07-15T00:00:01Z', 'd08db675-ee1e-48fe-b9e1-b0da27de8f2b')
;
INSERT INTO osc_physrisk.osc_physrisk_hazards.hazard_indicator
	(osc_id, osc_name, osc_name_display, osc_description_full, osc_description_short, osc_tags, osc_datetime_created, osc_creator_user_id, osc_datetime_last_modified, osc_last_modifier_user_id, osc_is_deleted, osc_deleter_user_id, osc_datetime_deleted, osc_culture, osc_checksum, osc_seq_num, osc_translated_from_id, osc_is_active, osc_is_published, osc_publisher_id, osc_datetime_published, osc_hazard_id)
VALUES 
	('3dbf253a-d880-4440-baa5-3e4a9fcac355', 'Days with average temperature above 25°C/ESM1-2-LR', 'Days with average temperature above 25°C/ESM1-2-LR', 'Days with average temperature above 25°C/ESM1-2-LR', 'Days with average temperature above 25°C/ESM1-2-LR', 'key1=>value1_en,key2=>value2_en','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'en', 'osc_checksum',1, NULL,'y','y',1,'2024-07-15T00:00:01Z', 'd08db675-ee1e-48fe-b9e1-b0da27de8f2b')
;
INSERT INTO osc_physrisk.osc_physrisk_hazards.hazard_indicator
	(osc_id, osc_name, osc_name_display, osc_description_full, osc_description_short, osc_tags, osc_datetime_created, osc_creator_user_id, osc_datetime_last_modified, osc_last_modifier_user_id, osc_is_deleted, osc_deleter_user_id, osc_datetime_deleted, osc_culture, osc_checksum, osc_seq_num, osc_translated_from_id, osc_is_active, osc_is_published, osc_publisher_id, osc_datetime_published, osc_hazard_id)
VALUES 
	('5fcca03b-ffff-4632-b896-78ceb9777e4b', 'Days with average temperature above 25°C/NorESM2-MM', 'Days with average temperature above 25°C/NorESM2-MM', 'Days with average temperature above 25°C/NorESM2-MM', 'Days with average temperature above 25°C/NorESM2-MM', 'key1=>value1_en,key2=>value2_en','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'en', 'osc_checksum',1, NULL,'y','y',1,'2024-07-15T00:00:01Z', 'd08db675-ee1e-48fe-b9e1-b0da27de8f2b')
;
INSERT INTO osc_physrisk.osc_physrisk_hazards.hazard_indicator
	(osc_id, osc_name, osc_name_display, osc_description_full, osc_description_short, osc_tags, osc_datetime_created, osc_creator_user_id, osc_datetime_last_modified, osc_last_modifier_user_id, osc_is_deleted, osc_deleter_user_id, osc_datetime_deleted, osc_culture, osc_checksum, osc_seq_num, osc_translated_from_id, osc_is_active, osc_is_published, osc_publisher_id, osc_datetime_published, osc_hazard_id)
VALUES 
	('77f04d46-303f-40f2-a892-d0068d6ab64a', 'Days with average temperature above 30°C/ACCESS-CM2', 'Days with average temperature above 30°C/ACCESS-CM2', 'Days with average temperature above 30°C/ACCESS-CM2', 'Days with average temperature above 30°C/ACCESS-CM2', 'key1=>value1_en,key2=>value2_en','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'en', 'osc_checksum',1, NULL,'y','y',1,'2024-07-15T00:00:01Z', 'd08db675-ee1e-48fe-b9e1-b0da27de8f2b')
;
INSERT INTO osc_physrisk.osc_physrisk_hazards.hazard_indicator
	(osc_id, osc_name, osc_name_display, osc_description_full, osc_description_short, osc_tags, osc_datetime_created, osc_creator_user_id, osc_datetime_last_modified, osc_last_modifier_user_id, osc_is_deleted, osc_deleter_user_id, osc_datetime_deleted, osc_culture, osc_checksum, osc_seq_num, osc_translated_from_id, osc_is_active, osc_is_published, osc_publisher_id, osc_datetime_published, osc_hazard_id)
VALUES 
	('c47e4dfa-e850-4060-aed9-af9100c65986', 'Days with average temperature above 30°C/CMCC-ESM2', 'Days with average temperature above 30°C/CMCC-ESM2', 'Days with average temperature above 30°C/CMCC-ESM2', 'Days with average temperature above 30°C/CMCC-ESM2', 'key1=>value1_en,key2=>value2_en','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'en', 'osc_checksum',1, NULL,'y','y',1,'2024-07-15T00:00:01Z', 'd08db675-ee1e-48fe-b9e1-b0da27de8f2b')
;
INSERT INTO osc_physrisk.osc_physrisk_hazards.hazard_indicator
	(osc_id, osc_name, osc_name_display, osc_description_full, osc_description_short, osc_tags, osc_datetime_created, osc_creator_user_id, osc_datetime_last_modified, osc_last_modifier_user_id, osc_is_deleted, osc_deleter_user_id, osc_datetime_deleted, osc_culture, osc_checksum, osc_seq_num, osc_translated_from_id, osc_is_active, osc_is_published, osc_publisher_id, osc_datetime_published, osc_hazard_id)
VALUES 
	('ba1e06be-1cf5-4b5d-8f93-8f64e47af2b8', 'Days with average temperature above 30°C/CNRM-CM6-1', 'Days with average temperature above 30°C/CNRM-CM6-1', 'Days with average temperature above 30°C/CNRM-CM6-1', 'Days with average temperature above 30°C/CNRM-CM6-1', 'key1=>value1_en,key2=>value2_en','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'en', 'osc_checksum',1, NULL,'y','y',1,'2024-07-15T00:00:01Z', 'd08db675-ee1e-48fe-b9e1-b0da27de8f2b')
;
INSERT INTO osc_physrisk.osc_physrisk_hazards.hazard_indicator
	(osc_id, osc_name, osc_name_display, osc_description_full, osc_description_short, osc_tags, osc_datetime_created, osc_creator_user_id, osc_datetime_last_modified, osc_last_modifier_user_id, osc_is_deleted, osc_deleter_user_id, osc_datetime_deleted, osc_culture, osc_checksum, osc_seq_num, osc_translated_from_id, osc_is_active, osc_is_published, osc_publisher_id, osc_datetime_published, osc_hazard_id)
VALUES 
	('b882a67c-acea-4dbe-9939-1594775e6f78', 'Days with average temperature above 30°C/MIROC6', 'Days with average temperature above 30°C/MIROC6', 'Days with average temperature above 30°C/MIROC6', 'Days with average temperature above 30°C/MIROC6', 'key1=>value1_en,key2=>value2_en','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'en', 'osc_checksum',1, NULL,'y','y',1,'2024-07-15T00:00:01Z', 'd08db675-ee1e-48fe-b9e1-b0da27de8f2b')
;
INSERT INTO osc_physrisk.osc_physrisk_hazards.hazard_indicator
	(osc_id, osc_name, osc_name_display, osc_description_full, osc_description_short, osc_tags, osc_datetime_created, osc_creator_user_id, osc_datetime_last_modified, osc_last_modifier_user_id, osc_is_deleted, osc_deleter_user_id, osc_datetime_deleted, osc_culture, osc_checksum, osc_seq_num, osc_translated_from_id, osc_is_active, osc_is_published, osc_publisher_id, osc_datetime_published, osc_hazard_id)
VALUES 
	('0ae16260-45b7-48fe-924e-a2bd2bc25f39', 'Days with average temperature above 30°C/ESM1-2-LR', 'Days with average temperature above 30°C/ESM1-2-LR', 'Days with average temperature above 30°C/ESM1-2-LR', 'Days with average temperature above 30°C/ESM1-2-LR', 'key1=>value1_en,key2=>value2_en','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'en', 'osc_checksum',1, NULL,'y','y',1,'2024-07-15T00:00:01Z', 'd08db675-ee1e-48fe-b9e1-b0da27de8f2b')
;
INSERT INTO osc_physrisk.osc_physrisk_hazards.hazard_indicator
	(osc_id, osc_name, osc_name_display, osc_description_full, osc_description_short, osc_tags, osc_datetime_created, osc_creator_user_id, osc_datetime_last_modified, osc_last_modifier_user_id, osc_is_deleted, osc_deleter_user_id, osc_datetime_deleted, osc_culture, osc_checksum, osc_seq_num, osc_translated_from_id, osc_is_active, osc_is_published, osc_publisher_id, osc_datetime_published, osc_hazard_id)
VALUES 
	('151fe933-f1be-4fb1-bcaf-d534a5023c78', 'Days with average temperature above 30°C/NorESM2-MM', 'Days with average temperature above 30°C/NorESM2-MM', 'Days with average temperature above 30°C/NorESM2-MM', 'Days with average temperature above 30°C/NorESM2-MM', 'key1=>value1_en,key2=>value2_en','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'en', 'osc_checksum',1, NULL,'y','y',1,'2024-07-15T00:00:01Z', 'd08db675-ee1e-48fe-b9e1-b0da27de8f2b')
;
INSERT INTO osc_physrisk.osc_physrisk_hazards.hazard_indicator
	(osc_id, osc_name, osc_name_display, osc_description_full, osc_description_short, osc_tags, osc_datetime_created, osc_creator_user_id, osc_datetime_last_modified, osc_last_modifier_user_id, osc_is_deleted, osc_deleter_user_id, osc_datetime_deleted, osc_culture, osc_checksum, osc_seq_num, osc_translated_from_id, osc_is_active, osc_is_published, osc_publisher_id, osc_datetime_published, osc_hazard_id)
VALUES 
	('96e6fcc5-d843-4f59-9746-2d0d341b6bdc', 'Days with average temperature above 35°C/ACCESS-CM2', 'Days with average temperature above 35°C/ACCESS-CM2', 'Days with average temperature above 35°C/ACCESS-CM2', 'Days with average temperature above 35°C/ACCESS-CM2', 'key1=>value1_en,key2=>value2_en','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'en', 'osc_checksum',1, NULL,'y','y',1,'2024-07-15T00:00:01Z', 'd08db675-ee1e-48fe-b9e1-b0da27de8f2b')
;
INSERT INTO osc_physrisk.osc_physrisk_hazards.hazard_indicator
	(osc_id, osc_name, osc_name_display, osc_description_full, osc_description_short, osc_tags, osc_datetime_created, osc_creator_user_id, osc_datetime_last_modified, osc_last_modifier_user_id, osc_is_deleted, osc_deleter_user_id, osc_datetime_deleted, osc_culture, osc_checksum, osc_seq_num, osc_translated_from_id, osc_is_active, osc_is_published, osc_publisher_id, osc_datetime_published, osc_hazard_id)
VALUES 
	('2c485594-5220-4e5e-85f0-3e67a09bacd9', 'Days with average temperature above 35°C/CMCC-ESM2', 'Days with average temperature above 35°C/CMCC-ESM2', 'Days with average temperature above 35°C/CMCC-ESM2', 'Days with average temperature above 35°C/CMCC-ESM2', 'key1=>value1_en,key2=>value2_en','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'en', 'osc_checksum',1, NULL,'y','y',1,'2024-07-15T00:00:01Z', 'd08db675-ee1e-48fe-b9e1-b0da27de8f2b')
;
INSERT INTO osc_physrisk.osc_physrisk_hazards.hazard_indicator
	(osc_id, osc_name, osc_name_display, osc_description_full, osc_description_short, osc_tags, osc_datetime_created, osc_creator_user_id, osc_datetime_last_modified, osc_last_modifier_user_id, osc_is_deleted, osc_deleter_user_id, osc_datetime_deleted, osc_culture, osc_checksum, osc_seq_num, osc_translated_from_id, osc_is_active, osc_is_published, osc_publisher_id, osc_datetime_published, osc_hazard_id)
VALUES 
	('db9a09b3-3386-4081-bf0c-79b6c8ebd38e', 'Days with average temperature above 35°C/CNRM-CM6-1', 'Days with average temperature above 35°C/CNRM-CM6-1', 'Days with average temperature above 35°C/CNRM-CM6-1', 'Days with average temperature above 35°C/CNRM-CM6-1', 'key1=>value1_en,key2=>value2_en','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'en', 'osc_checksum',1, NULL,'y','y',1,'2024-07-15T00:00:01Z', 'd08db675-ee1e-48fe-b9e1-b0da27de8f2b')
;
INSERT INTO osc_physrisk.osc_physrisk_hazards.hazard_indicator
	(osc_id, osc_name, osc_name_display, osc_description_full, osc_description_short, osc_tags, osc_datetime_created, osc_creator_user_id, osc_datetime_last_modified, osc_last_modifier_user_id, osc_is_deleted, osc_deleter_user_id, osc_datetime_deleted, osc_culture, osc_checksum, osc_seq_num, osc_translated_from_id, osc_is_active, osc_is_published, osc_publisher_id, osc_datetime_published, osc_hazard_id)
VALUES 
	('3f77c47d-9a26-4a3f-a289-ecf56678ec69', 'Days with average temperature above 35°C/MIROC6', 'Days with average temperature above 35°C/MIROC6', 'Days with average temperature above 35°C/MIROC6', 'Days with average temperature above 35°C/MIROC6', 'key1=>value1_en,key2=>value2_en','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'en', 'osc_checksum',1, NULL,'y','y',1,'2024-07-15T00:00:01Z', 'd08db675-ee1e-48fe-b9e1-b0da27de8f2b')
;
INSERT INTO osc_physrisk.osc_physrisk_hazards.hazard_indicator
	(osc_id, osc_name, osc_name_display, osc_description_full, osc_description_short, osc_tags, osc_datetime_created, osc_creator_user_id, osc_datetime_last_modified, osc_last_modifier_user_id, osc_is_deleted, osc_deleter_user_id, osc_datetime_deleted, osc_culture, osc_checksum, osc_seq_num, osc_translated_from_id, osc_is_active, osc_is_published, osc_publisher_id, osc_datetime_published, osc_hazard_id)
VALUES 
	('f197975a-acea-4514-acbf-35cb070b0b5c', 'Days with average temperature above 35°C/ESM1-2-LR', 'Days with average temperature above 35°C/ESM1-2-LR', 'Days with average temperature above 35°C/ESM1-2-LR', 'Days with average temperature above 35°C/ESM1-2-LR', 'key1=>value1_en,key2=>value2_en','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'en', 'osc_checksum',1, NULL,'y','y',1,'2024-07-15T00:00:01Z', 'd08db675-ee1e-48fe-b9e1-b0da27de8f2b')
;
INSERT INTO osc_physrisk.osc_physrisk_hazards.hazard_indicator
	(osc_id, osc_name, osc_name_display, osc_description_full, osc_description_short, osc_tags, osc_datetime_created, osc_creator_user_id, osc_datetime_last_modified, osc_last_modifier_user_id, osc_is_deleted, osc_deleter_user_id, osc_datetime_deleted, osc_culture, osc_checksum, osc_seq_num, osc_translated_from_id, osc_is_active, osc_is_published, osc_publisher_id, osc_datetime_published, osc_hazard_id)
VALUES 
	('d4d610b4-060e-4212-9b0c-05fe551a0128', 'Days with average temperature above 35°C/NorESM2-MM', 'Days with average temperature above 35°C/NorESM2-MM', 'Days with average temperature above 35°C/NorESM2-MM', 'Days with average temperature above 35°C/NorESM2-MM', 'key1=>value1_en,key2=>value2_en','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'en', 'osc_checksum',1, NULL,'y','y',1,'2024-07-15T00:00:01Z', 'd08db675-ee1e-48fe-b9e1-b0da27de8f2b')
;
INSERT INTO osc_physrisk.osc_physrisk_hazards.hazard_indicator
	(osc_id, osc_name, osc_name_display, osc_description_full, osc_description_short, osc_tags, osc_datetime_created, osc_creator_user_id, osc_datetime_last_modified, osc_last_modifier_user_id, osc_is_deleted, osc_deleter_user_id, osc_datetime_deleted, osc_culture, osc_checksum, osc_seq_num, osc_translated_from_id, osc_is_active, osc_is_published, osc_publisher_id, osc_datetime_published, osc_hazard_id)
VALUES 
	('f38a4529-0b9e-4a31-9b16-f6e070a4f001', 'Days with average temperature above 40°C/ACCESS-CM2', 'Days with average temperature above 40°C/ACCESS-CM2', 'Days with average temperature above 40°C/ACCESS-CM2', 'Days with average temperature above 40°C/ACCESS-CM2', 'key1=>value1_en,key2=>value2_en','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'en', 'osc_checksum',1, NULL,'y','y',1,'2024-07-15T00:00:01Z', 'd08db675-ee1e-48fe-b9e1-b0da27de8f2b')
;
INSERT INTO osc_physrisk.osc_physrisk_hazards.hazard_indicator
	(osc_id, osc_name, osc_name_display, osc_description_full, osc_description_short, osc_tags, osc_datetime_created, osc_creator_user_id, osc_datetime_last_modified, osc_last_modifier_user_id, osc_is_deleted, osc_deleter_user_id, osc_datetime_deleted, osc_culture, osc_checksum, osc_seq_num, osc_translated_from_id, osc_is_active, osc_is_published, osc_publisher_id, osc_datetime_published, osc_hazard_id)
VALUES 
	('bae5ce0d-079c-44c8-87f2-705e13806371', 'Days with average temperature above 40°C/CMCC-ESM2', 'Days with average temperature above 40°C/CMCC-ESM2', 'Days with average temperature above 40°C/CMCC-ESM2', 'Days with average temperature above 40°C/CMCC-ESM2', 'key1=>value1_en,key2=>value2_en','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'en', 'osc_checksum',1, NULL,'y','y',1,'2024-07-15T00:00:01Z', 'd08db675-ee1e-48fe-b9e1-b0da27de8f2b')
;
INSERT INTO osc_physrisk.osc_physrisk_hazards.hazard_indicator
	(osc_id, osc_name, osc_name_display, osc_description_full, osc_description_short, osc_tags, osc_datetime_created, osc_creator_user_id, osc_datetime_last_modified, osc_last_modifier_user_id, osc_is_deleted, osc_deleter_user_id, osc_datetime_deleted, osc_culture, osc_checksum, osc_seq_num, osc_translated_from_id, osc_is_active, osc_is_published, osc_publisher_id, osc_datetime_published, osc_hazard_id)
VALUES 
	('19049eb2-9270-4b1b-9aea-8e2c610ea6b0', 'Days with average temperature above 40°C/CNRM-CM6-1', 'Days with average temperature above 40°C/CNRM-CM6-1', 'Days with average temperature above 40°C/CNRM-CM6-1', 'Days with average temperature above 40°C/CNRM-CM6-1', 'key1=>value1_en,key2=>value2_en','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'en', 'osc_checksum',1, NULL,'y','y',1,'2024-07-15T00:00:01Z', 'd08db675-ee1e-48fe-b9e1-b0da27de8f2b')
;
INSERT INTO osc_physrisk.osc_physrisk_hazards.hazard_indicator
	(osc_id, osc_name, osc_name_display, osc_description_full, osc_description_short, osc_tags, osc_datetime_created, osc_creator_user_id, osc_datetime_last_modified, osc_last_modifier_user_id, osc_is_deleted, osc_deleter_user_id, osc_datetime_deleted, osc_culture, osc_checksum, osc_seq_num, osc_translated_from_id, osc_is_active, osc_is_published, osc_publisher_id, osc_datetime_published, osc_hazard_id)
VALUES 
	('a35f8652-5736-4b83-b9ec-2bcd53dd2b75', 'Days with average temperature above 40°C/MIROC6', 'Days with average temperature above 40°C/MIROC6', 'Days with average temperature above 40°C/MIROC6', 'Days with average temperature above 40°C/MIROC6', 'key1=>value1_en,key2=>value2_en','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'en', 'osc_checksum',1, NULL,'y','y',1,'2024-07-15T00:00:01Z', 'd08db675-ee1e-48fe-b9e1-b0da27de8f2b')
;
INSERT INTO osc_physrisk.osc_physrisk_hazards.hazard_indicator
	(osc_id, osc_name, osc_name_display, osc_description_full, osc_description_short, osc_tags, osc_datetime_created, osc_creator_user_id, osc_datetime_last_modified, osc_last_modifier_user_id, osc_is_deleted, osc_deleter_user_id, osc_datetime_deleted, osc_culture, osc_checksum, osc_seq_num, osc_translated_from_id, osc_is_active, osc_is_published, osc_publisher_id, osc_datetime_published, osc_hazard_id)
VALUES 
	('6a23417d-27fc-49f5-9147-43f9a761e13d', 'Days with average temperature above 40°C/ESM1-2-LR', 'Days with average temperature above 40°C/ESM1-2-LR', 'Days with average temperature above 40°C/ESM1-2-LR', 'Days with average temperature above 40°C/ESM1-2-LR', 'key1=>value1_en,key2=>value2_en','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'en', 'osc_checksum',1, NULL,'y','y',1,'2024-07-15T00:00:01Z', 'd08db675-ee1e-48fe-b9e1-b0da27de8f2b')
;
INSERT INTO osc_physrisk.osc_physrisk_hazards.hazard_indicator
	(osc_id, osc_name, osc_name_display, osc_description_full, osc_description_short, osc_tags, osc_datetime_created, osc_creator_user_id, osc_datetime_last_modified, osc_last_modifier_user_id, osc_is_deleted, osc_deleter_user_id, osc_datetime_deleted, osc_culture, osc_checksum, osc_seq_num, osc_translated_from_id, osc_is_active, osc_is_published, osc_publisher_id, osc_datetime_published, osc_hazard_id)
VALUES 
	('9fd1aafe-d942-4dd7-8b5f-cc3983d12616', 'Days with average temperature above 40°C/NorESM2-MM', 'Days with average temperature above 40°C/NorESM2-MM', 'Days with average temperature above 40°C/NorESM2-MM', 'Days with average temperature above 40°C/NorESM2-MM', 'key1=>value1_en,key2=>value2_en','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'en', 'osc_checksum',1, NULL,'y','y',1,'2024-07-15T00:00:01Z', 'd08db675-ee1e-48fe-b9e1-b0da27de8f2b')
;
INSERT INTO osc_physrisk.osc_physrisk_hazards.hazard_indicator
	(osc_id, osc_name, osc_name_display, osc_description_full, osc_description_short, osc_tags, osc_datetime_created, osc_creator_user_id, osc_datetime_last_modified, osc_last_modifier_user_id, osc_is_deleted, osc_deleter_user_id, osc_datetime_deleted, osc_culture, osc_checksum, osc_seq_num, osc_translated_from_id, osc_is_active, osc_is_published, osc_publisher_id, osc_datetime_published, osc_hazard_id)
VALUES 
	('801009ff-7135-4252-a956-8f32cd9fb17d', 'Days with average temperature above 45°C/ACCESS-CM2', 'Days with average temperature above 45°C/ACCESS-CM2', 'Days with average temperature above 45°C/ACCESS-CM2', 'Days with average temperature above 45°C/ACCESS-CM2', 'key1=>value1_en,key2=>value2_en','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'en', 'osc_checksum',1, NULL,'y','y',1,'2024-07-15T00:00:01Z', 'd08db675-ee1e-48fe-b9e1-b0da27de8f2b')
;
INSERT INTO osc_physrisk.osc_physrisk_hazards.hazard_indicator
	(osc_id, osc_name, osc_name_display, osc_description_full, osc_description_short, osc_tags, osc_datetime_created, osc_creator_user_id, osc_datetime_last_modified, osc_last_modifier_user_id, osc_is_deleted, osc_deleter_user_id, osc_datetime_deleted, osc_culture, osc_checksum, osc_seq_num, osc_translated_from_id, osc_is_active, osc_is_published, osc_publisher_id, osc_datetime_published, osc_hazard_id)
VALUES 
	('ea8be4c4-a3f0-441f-b1cd-b4de8b9e885c', 'Days with average temperature above 45°C/CMCC-ESM2', 'Days with average temperature above 45°C/CMCC-ESM2', 'Days with average temperature above 45°C/CMCC-ESM2', 'Days with average temperature above 45°C/CMCC-ESM2', 'key1=>value1_en,key2=>value2_en','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'en', 'osc_checksum',1, NULL,'y','y',1,'2024-07-15T00:00:01Z', 'd08db675-ee1e-48fe-b9e1-b0da27de8f2b')
;
INSERT INTO osc_physrisk.osc_physrisk_hazards.hazard_indicator
	(osc_id, osc_name, osc_name_display, osc_description_full, osc_description_short, osc_tags, osc_datetime_created, osc_creator_user_id, osc_datetime_last_modified, osc_last_modifier_user_id, osc_is_deleted, osc_deleter_user_id, osc_datetime_deleted, osc_culture, osc_checksum, osc_seq_num, osc_translated_from_id, osc_is_active, osc_is_published, osc_publisher_id, osc_datetime_published, osc_hazard_id)
VALUES 
	('69053bee-35fd-45bd-9dd1-8fe485ae7715', 'Days with average temperature above 45°C/CNRM-CM6-1', 'Days with average temperature above 45°C/CNRM-CM6-1', 'Days with average temperature above 45°C/CNRM-CM6-1', 'Days with average temperature above 45°C/CNRM-CM6-1', 'key1=>value1_en,key2=>value2_en','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'en', 'osc_checksum',1, NULL,'y','y',1,'2024-07-15T00:00:01Z', 'd08db675-ee1e-48fe-b9e1-b0da27de8f2b')
;
INSERT INTO osc_physrisk.osc_physrisk_hazards.hazard_indicator
	(osc_id, osc_name, osc_name_display, osc_description_full, osc_description_short, osc_tags, osc_datetime_created, osc_creator_user_id, osc_datetime_last_modified, osc_last_modifier_user_id, osc_is_deleted, osc_deleter_user_id, osc_datetime_deleted, osc_culture, osc_checksum, osc_seq_num, osc_translated_from_id, osc_is_active, osc_is_published, osc_publisher_id, osc_datetime_published, osc_hazard_id)
VALUES 
	('1f48f1f2-03ab-43b8-9185-038fd656ebcd', 'Days with average temperature above 45°C/MIROC6', 'Days with average temperature above 45°C/MIROC6', 'Days with average temperature above 45°C/MIROC6', 'Days with average temperature above 45°C/MIROC6', 'key1=>value1_en,key2=>value2_en','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'en', 'osc_checksum',1, NULL,'y','y',1,'2024-07-15T00:00:01Z', 'd08db675-ee1e-48fe-b9e1-b0da27de8f2b')
;
INSERT INTO osc_physrisk.osc_physrisk_hazards.hazard_indicator
	(osc_id, osc_name, osc_name_display, osc_description_full, osc_description_short, osc_tags, osc_datetime_created, osc_creator_user_id, osc_datetime_last_modified, osc_last_modifier_user_id, osc_is_deleted, osc_deleter_user_id, osc_datetime_deleted, osc_culture, osc_checksum, osc_seq_num, osc_translated_from_id, osc_is_active, osc_is_published, osc_publisher_id, osc_datetime_published, osc_hazard_id)
VALUES 
	('8960452e-86b1-4134-b03d-5bea69079fcc', 'Days with average temperature above 45°C/ESM1-2-LR', 'Days with average temperature above 45°C/ESM1-2-LR', 'Days with average temperature above 45°C/ESM1-2-LR', 'Days with average temperature above 45°C/ESM1-2-LR', 'key1=>value1_en,key2=>value2_en','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'en', 'osc_checksum',1, NULL,'y','y',1,'2024-07-15T00:00:01Z', 'd08db675-ee1e-48fe-b9e1-b0da27de8f2b')
;
INSERT INTO osc_physrisk.osc_physrisk_hazards.hazard_indicator
	(osc_id, osc_name, osc_name_display, osc_description_full, osc_description_short, osc_tags, osc_datetime_created, osc_creator_user_id, osc_datetime_last_modified, osc_last_modifier_user_id, osc_is_deleted, osc_deleter_user_id, osc_datetime_deleted, osc_culture, osc_checksum, osc_seq_num, osc_translated_from_id, osc_is_active, osc_is_published, osc_publisher_id, osc_datetime_published, osc_hazard_id)
VALUES 
	('3676521f-16ee-4ce6-b8b4-d00aaba44281', 'Days with average temperature above 45°C/NorESM2-MM', 'Days with average temperature above 45°C/NorESM2-MM', 'Days with average temperature above 45°C/NorESM2-MM', 'Days with average temperature above 45°C/NorESM2-MM', 'key1=>value1_en,key2=>value2_en','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'en', 'osc_checksum',1, NULL,'y','y',1,'2024-07-15T00:00:01Z', 'd08db675-ee1e-48fe-b9e1-b0da27de8f2b')
;
INSERT INTO osc_physrisk.osc_physrisk_hazards.hazard_indicator
	(osc_id, osc_name, osc_name_display, osc_description_full, osc_description_short, osc_tags, osc_datetime_created, osc_creator_user_id, osc_datetime_last_modified, osc_last_modifier_user_id, osc_is_deleted, osc_deleter_user_id, osc_datetime_deleted, osc_culture, osc_checksum, osc_seq_num, osc_translated_from_id, osc_is_active, osc_is_published, osc_publisher_id, osc_datetime_published, osc_hazard_id)
VALUES 
	('8bfe29fb-85e3-4497-b340-ad3f4eadfc3f', 'Days with average temperature above 50°C/ACCESS-CM2', 'Days with average temperature above 50°C/ACCESS-CM2', 'Days with average temperature above 50°C/ACCESS-CM2', 'Days with average temperature above 50°C/ACCESS-CM2', 'key1=>value1_en,key2=>value2_en','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'en', 'osc_checksum',1, NULL,'y','y',1,'2024-07-15T00:00:01Z', 'd08db675-ee1e-48fe-b9e1-b0da27de8f2b')
;
INSERT INTO osc_physrisk.osc_physrisk_hazards.hazard_indicator
	(osc_id, osc_name, osc_name_display, osc_description_full, osc_description_short, osc_tags, osc_datetime_created, osc_creator_user_id, osc_datetime_last_modified, osc_last_modifier_user_id, osc_is_deleted, osc_deleter_user_id, osc_datetime_deleted, osc_culture, osc_checksum, osc_seq_num, osc_translated_from_id, osc_is_active, osc_is_published, osc_publisher_id, osc_datetime_published, osc_hazard_id)
VALUES 
	('fb684a2f-ce48-4d02-ba49-9c5cd49654df', 'Days with average temperature above 50°C/CMCC-ESM2', 'Days with average temperature above 50°C/CMCC-ESM2', 'Days with average temperature above 50°C/CMCC-ESM2', 'Days with average temperature above 50°C/CMCC-ESM2', 'key1=>value1_en,key2=>value2_en','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'en', 'osc_checksum',1, NULL,'y','y',1,'2024-07-15T00:00:01Z', 'd08db675-ee1e-48fe-b9e1-b0da27de8f2b')
;
INSERT INTO osc_physrisk.osc_physrisk_hazards.hazard_indicator
	(osc_id, osc_name, osc_name_display, osc_description_full, osc_description_short, osc_tags, osc_datetime_created, osc_creator_user_id, osc_datetime_last_modified, osc_last_modifier_user_id, osc_is_deleted, osc_deleter_user_id, osc_datetime_deleted, osc_culture, osc_checksum, osc_seq_num, osc_translated_from_id, osc_is_active, osc_is_published, osc_publisher_id, osc_datetime_published, osc_hazard_id)
VALUES 
	('56fb7c3a-7d9c-41d2-ab1d-37bab5544748', 'Days with average temperature above 50°C/CNRM-CM6-1', 'Days with average temperature above 50°C/CNRM-CM6-1', 'Days with average temperature above 50°C/CNRM-CM6-1', 'Days with average temperature above 50°C/CNRM-CM6-1', 'key1=>value1_en,key2=>value2_en','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'en', 'osc_checksum',1, NULL,'y','y',1,'2024-07-15T00:00:01Z', 'd08db675-ee1e-48fe-b9e1-b0da27de8f2b')
;
INSERT INTO osc_physrisk.osc_physrisk_hazards.hazard_indicator
	(osc_id, osc_name, osc_name_display, osc_description_full, osc_description_short, osc_tags, osc_datetime_created, osc_creator_user_id, osc_datetime_last_modified, osc_last_modifier_user_id, osc_is_deleted, osc_deleter_user_id, osc_datetime_deleted, osc_culture, osc_checksum, osc_seq_num, osc_translated_from_id, osc_is_active, osc_is_published, osc_publisher_id, osc_datetime_published, osc_hazard_id)
VALUES 
	('12a84609-f114-4975-a90a-aed809452897', 'Days with average temperature above 50°C/MIROC6', 'Days with average temperature above 50°C/MIROC6', 'Days with average temperature above 50°C/MIROC6', 'Days with average temperature above 50°C/MIROC6', 'key1=>value1_en,key2=>value2_en','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'en', 'osc_checksum',1, NULL,'y','y',1,'2024-07-15T00:00:01Z', 'd08db675-ee1e-48fe-b9e1-b0da27de8f2b')
;
INSERT INTO osc_physrisk.osc_physrisk_hazards.hazard_indicator
	(osc_id, osc_name, osc_name_display, osc_description_full, osc_description_short, osc_tags, osc_datetime_created, osc_creator_user_id, osc_datetime_last_modified, osc_last_modifier_user_id, osc_is_deleted, osc_deleter_user_id, osc_datetime_deleted, osc_culture, osc_checksum, osc_seq_num, osc_translated_from_id, osc_is_active, osc_is_published, osc_publisher_id, osc_datetime_published, osc_hazard_id)
VALUES 
	('22ce6754-f68b-4f96-b083-8bb2a5c4deb6', 'Days with average temperature above 50°C/ESM1-2-LR', 'Days with average temperature above 50°C/ESM1-2-LR', 'Days with average temperature above 50°C/ESM1-2-LR', 'Days with average temperature above 50°C/ESM1-2-LR', 'key1=>value1_en,key2=>value2_en','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'en', 'osc_checksum',1, NULL,'y','y',1,'2024-07-15T00:00:01Z', 'd08db675-ee1e-48fe-b9e1-b0da27de8f2b')
;
INSERT INTO osc_physrisk.osc_physrisk_hazards.hazard_indicator
	(osc_id, osc_name, osc_name_display, osc_description_full, osc_description_short, osc_tags, osc_datetime_created, osc_creator_user_id, osc_datetime_last_modified, osc_last_modifier_user_id, osc_is_deleted, osc_deleter_user_id, osc_datetime_deleted, osc_culture, osc_checksum, osc_seq_num, osc_translated_from_id, osc_is_active, osc_is_published, osc_publisher_id, osc_datetime_published, osc_hazard_id)
VALUES 
	('ec4c8b74-816a-4260-8321-fc03b6850c37', 'Days with average temperature above 50°C/NorESM2-MM', 'Days with average temperature above 50°C/NorESM2-MM', 'Days with average temperature above 50°C/NorESM2-MM', 'Days with average temperature above 50°C/NorESM2-MM', 'key1=>value1_en,key2=>value2_en','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'en', 'osc_checksum',1, NULL,'y','y',1,'2024-07-15T00:00:01Z', 'd08db675-ee1e-48fe-b9e1-b0da27de8f2b')
;
INSERT INTO osc_physrisk.osc_physrisk_hazards.hazard_indicator
	(osc_id, osc_name, osc_name_display, osc_description_full, osc_description_short, osc_tags, osc_datetime_created, osc_creator_user_id, osc_datetime_last_modified, osc_last_modifier_user_id, osc_is_deleted, osc_deleter_user_id, osc_datetime_deleted, osc_culture, osc_checksum, osc_seq_num, osc_translated_from_id, osc_is_active, osc_is_published, osc_publisher_id, osc_datetime_published, osc_hazard_id)
VALUES 
	('7f06ac9f-f6ac-467a-9a88-d14a91465141', 'Days with average temperature above 55°C/ACCESS-CM2', 'Days with average temperature above 55°C/ACCESS-CM2', 'Days with average temperature above 55°C/ACCESS-CM2', 'Days with average temperature above 55°C/ACCESS-CM2', 'key1=>value1_en,key2=>value2_en','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'en', 'osc_checksum',1, NULL,'y','y',1,'2024-07-15T00:00:01Z', 'd08db675-ee1e-48fe-b9e1-b0da27de8f2b')
;
INSERT INTO osc_physrisk.osc_physrisk_hazards.hazard_indicator
	(osc_id, osc_name, osc_name_display, osc_description_full, osc_description_short, osc_tags, osc_datetime_created, osc_creator_user_id, osc_datetime_last_modified, osc_last_modifier_user_id, osc_is_deleted, osc_deleter_user_id, osc_datetime_deleted, osc_culture, osc_checksum, osc_seq_num, osc_translated_from_id, osc_is_active, osc_is_published, osc_publisher_id, osc_datetime_published, osc_hazard_id)
VALUES 
	('c9edfa0d-5450-4de5-8680-4a26874cac2d', 'Days with average temperature above 55°C/CMCC-ESM2', 'Days with average temperature above 55°C/CMCC-ESM2', 'Days with average temperature above 55°C/CMCC-ESM2', 'Days with average temperature above 55°C/CMCC-ESM2', 'key1=>value1_en,key2=>value2_en','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'en', 'osc_checksum',1, NULL,'y','y',1,'2024-07-15T00:00:01Z', 'd08db675-ee1e-48fe-b9e1-b0da27de8f2b')
;
INSERT INTO osc_physrisk.osc_physrisk_hazards.hazard_indicator
	(osc_id, osc_name, osc_name_display, osc_description_full, osc_description_short, osc_tags, osc_datetime_created, osc_creator_user_id, osc_datetime_last_modified, osc_last_modifier_user_id, osc_is_deleted, osc_deleter_user_id, osc_datetime_deleted, osc_culture, osc_checksum, osc_seq_num, osc_translated_from_id, osc_is_active, osc_is_published, osc_publisher_id, osc_datetime_published, osc_hazard_id)
VALUES 
	('431a89ea-17bd-4dee-a2af-9ba18e737fe5', 'Days with average temperature above 55°C/CNRM-CM6-1', 'Days with average temperature above 55°C/CNRM-CM6-1', 'Days with average temperature above 55°C/CNRM-CM6-1', 'Days with average temperature above 55°C/CNRM-CM6-1', 'key1=>value1_en,key2=>value2_en','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'en', 'osc_checksum',1, NULL,'y','y',1,'2024-07-15T00:00:01Z', 'd08db675-ee1e-48fe-b9e1-b0da27de8f2b')
;
INSERT INTO osc_physrisk.osc_physrisk_hazards.hazard_indicator
	(osc_id, osc_name, osc_name_display, osc_description_full, osc_description_short, osc_tags, osc_datetime_created, osc_creator_user_id, osc_datetime_last_modified, osc_last_modifier_user_id, osc_is_deleted, osc_deleter_user_id, osc_datetime_deleted, osc_culture, osc_checksum, osc_seq_num, osc_translated_from_id, osc_is_active, osc_is_published, osc_publisher_id, osc_datetime_published, osc_hazard_id)
VALUES 
	('158038b5-1f09-471a-ac5b-85aae409148b', 'Days with average temperature above 55°C/MIROC6', 'Days with average temperature above 55°C/MIROC6', 'Days with average temperature above 55°C/MIROC6', 'Days with average temperature above 55°C/MIROC6', 'key1=>value1_en,key2=>value2_en','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'en', 'osc_checksum',1, NULL,'y','y',1,'2024-07-15T00:00:01Z', 'd08db675-ee1e-48fe-b9e1-b0da27de8f2b')
;
INSERT INTO osc_physrisk.osc_physrisk_hazards.hazard_indicator
	(osc_id, osc_name, osc_name_display, osc_description_full, osc_description_short, osc_tags, osc_datetime_created, osc_creator_user_id, osc_datetime_last_modified, osc_last_modifier_user_id, osc_is_deleted, osc_deleter_user_id, osc_datetime_deleted, osc_culture, osc_checksum, osc_seq_num, osc_translated_from_id, osc_is_active, osc_is_published, osc_publisher_id, osc_datetime_published, osc_hazard_id)
VALUES 
	('a5810ce7-eec7-4881-a182-33e0e3156a26', 'Days with average temperature above 55°C/ESM1-2-LR', 'Days with average temperature above 55°C/ESM1-2-LR', 'Days with average temperature above 55°C/ESM1-2-LR', 'Days with average temperature above 55°C/ESM1-2-LR', 'key1=>value1_en,key2=>value2_en','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'en', 'osc_checksum',1, NULL,'y','y',1,'2024-07-15T00:00:01Z', 'd08db675-ee1e-48fe-b9e1-b0da27de8f2b')
;
INSERT INTO osc_physrisk.osc_physrisk_hazards.hazard_indicator
	(osc_id, osc_name, osc_name_display, osc_description_full, osc_description_short, osc_tags, osc_datetime_created, osc_creator_user_id, osc_datetime_last_modified, osc_last_modifier_user_id, osc_is_deleted, osc_deleter_user_id, osc_datetime_deleted, osc_culture, osc_checksum, osc_seq_num, osc_translated_from_id, osc_is_active, osc_is_published, osc_publisher_id, osc_datetime_published, osc_hazard_id)
VALUES 
	('41705043-bdad-4d2d-ab2b-3d884375b52d', 'Days with average temperature above 55°C/NorESM2-MM', 'Days with average temperature above 55°C/NorESM2-MM', 'Days with average temperature above 55°C/NorESM2-MM', 'Days with average temperature above 55°C/NorESM2-MM', 'key1=>value1_en,key2=>value2_en','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'en', 'osc_checksum',1, NULL,'y','y',1,'2024-07-15T00:00:01Z', 'd08db675-ee1e-48fe-b9e1-b0da27de8f2b')
;

-- DATA IN ENGLISH ENDS
-- DATA IN FRENCH STARTS
INSERT INTO osc_physrisk.osc_physrisk_scenarios.scenario
	(osc_id, osc_description_full, osc_description_short, osc_name_display, osc_name, osc_tags, osc_datetime_created, osc_creator_user_id, osc_datetime_last_modified, osc_last_modifier_user_id, osc_is_deleted, osc_deleter_user_id, osc_datetime_deleted, osc_culture, osc_checksum, osc_seq_num, osc_translated_from_id, osc_is_active, osc_is_published, osc_publisher_id, osc_datetime_published)
VALUES 
	(10, 'Inconnu/Aucun selection', 'Inconnu/Aucun selection', 'Inconnu/Aucun selection', 'Inconnu/Aucun selection','key1=>value1_fr,key2=>value2_fr','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'fr', 'osc_checksum',1,-1, 'y','y', 1,'2024-07-15T00:00:01Z')
;
INSERT INTO osc_physrisk.osc_physrisk_scenarios.scenario
	(osc_id, osc_description_full, osc_description_short, osc_name_display, osc_name, osc_tags, osc_datetime_created, osc_creator_user_id, osc_datetime_last_modified, osc_last_modifier_user_id, osc_is_deleted, osc_deleter_user_id, osc_datetime_deleted, osc_culture, osc_checksum, osc_seq_num, osc_translated_from_id, osc_is_active, osc_is_published, osc_publisher_id, osc_datetime_published)
VALUES 
	(11, 'Historique (avant 2014). Voir "Scénarios d''émissions et de réchauffement futurs dans le sixième Rapport d''évaluation du GIEC" (https://www.ipcc.ch/report/ar6/wg1/downloads/report/IPCC_AR6_WG1_SPM_French.pdf).', 'Historique (avant 2014)', 'Historique (avant 2014)', 'Historique (avant 2014)','key1=>value1_fr,key2=>value2_fr','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'fr', 'osc_checksum',1,0, 'y','y', 1,'2024-07-15T00:00:01Z')
;
INSERT INTO osc_physrisk.osc_physrisk_scenarios.scenario
	(osc_id, osc_description_full, osc_description_short, osc_name_display, osc_name, osc_tags, osc_datetime_created, osc_creator_user_id, osc_datetime_last_modified, osc_last_modifier_user_id, osc_is_deleted, osc_deleter_user_id, osc_datetime_deleted, osc_culture, osc_checksum, osc_seq_num, osc_translated_from_id, osc_is_active, osc_is_published, osc_publisher_id, osc_datetime_published)
VALUES 
	(12, 'SSP1-1,9 — émissions de GES en baisse dès 2025, zéro émission nette de CO2 avant 2050, émissions négatives ensuite. Voir "Scénarios d''émissions et de réchauffement futurs dans le sixième Rapport d''évaluation du GIEC" (https://www.ipcc.ch/report/ar6/wg1/downloads/report/IPCC_AR6_WG1_SPM_French.pdf).', 'SSP1-1,9', 'SSP1-1,9', 'SSP1-1,9','key1=>value1_fr,key2=>value2_fr','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'fr', 'osc_checksum',1,1, 'y','y', 1,'2024-07-15T00:00:01Z')
;
INSERT INTO osc_physrisk.osc_physrisk_scenarios.scenario
	(osc_id, osc_description_full, osc_description_short, osc_name_display, osc_name, osc_tags, osc_datetime_created, osc_creator_user_id, osc_datetime_last_modified, osc_last_modifier_user_id, osc_is_deleted, osc_deleter_user_id, osc_datetime_deleted, osc_culture, osc_checksum, osc_seq_num, osc_translated_from_id, osc_is_active, osc_is_published, osc_publisher_id, osc_datetime_published)
VALUES 
	(13, 'SSP1-2,6 — similaire au précédent, mais le zéro émission nette de CO2 est atteint après 2050. Voir "Scénarios d''émissions et de réchauffement futurs dans le sixième Rapport d''évaluation du GIEC" (https://www.ipcc.ch/report/ar6/wg1/downloads/report/IPCC_AR6_WG1_SPM_French.pdf).', 'SSP1-2,6', 'SSP1-2,6', 'SSP1-2,6','key1=>value1_fr,key2=>value2_fr','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'fr', 'osc_checksum',1,2, 'y','y', 1,'2024-07-15T00:00:01Z')
;
INSERT INTO osc_physrisk.osc_physrisk_scenarios.scenario
	(osc_id, osc_description_full, osc_description_short, osc_name_display, osc_name, osc_tags, osc_datetime_created, osc_creator_user_id, osc_datetime_last_modified, osc_last_modifier_user_id, osc_is_deleted, osc_deleter_user_id, osc_datetime_deleted, osc_culture, osc_checksum, osc_seq_num, osc_translated_from_id, osc_is_active, osc_is_published, osc_publisher_id, osc_datetime_published)
VALUES 
	(14, 'SSP2-4,5 — maintien des émissions courantes jusqu''en 2050, division par quatre d''ici 2100. Voir "Scénarios d''émissions et de réchauffement futurs dans le sixième Rapport d''évaluation du GIEC" (https://www.ipcc.ch/report/ar6/wg1/downloads/report/IPCC_AR6_WG1_SPM_French.pdf).', 'SSP2-4,5', 'SSP2-4,5', 'SSP2-4,5','key1=>value1_fr,key2=>value2_fr','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'fr', 'osc_checksum',1,3, 'y','y', 1,'2024-07-15T00:00:01Z')
;
INSERT INTO osc_physrisk.osc_physrisk_scenarios.scenario
	(osc_id, osc_description_full, osc_description_short, osc_name_display, osc_name, osc_tags, osc_datetime_created, osc_creator_user_id, osc_datetime_last_modified, osc_last_modifier_user_id, osc_is_deleted, osc_deleter_user_id, osc_datetime_deleted, osc_culture, osc_checksum, osc_seq_num, osc_translated_from_id, osc_is_active, osc_is_published, osc_publisher_id, osc_datetime_published)
VALUES 
	(15, 'SSP3-7,0 — doublement des émissions de GES en 2100. Voir "Scénarios d''émissions et de réchauffement futurs dans le sixième Rapport d''évaluation du GIEC" (https://www.ipcc.ch/report/ar6/wg1/downloads/report/IPCC_AR6_WG1_SPM_French.pdf).', 'SSP3-7,0', 'SSP3-7,0', 'SSP3-7,0','key1=>value1_fr,key2=>value2_fr','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'fr', 'osc_checksum',1,4, 'y','y', 1,'2024-07-15T00:00:01Z')
;
INSERT INTO osc_physrisk.osc_physrisk_scenarios.scenario
	(osc_id, osc_description_full, osc_description_short, osc_name_display, osc_name, osc_tags, osc_datetime_created, osc_creator_user_id, osc_datetime_last_modified, osc_last_modifier_user_id, osc_is_deleted, osc_deleter_user_id, osc_datetime_deleted, osc_culture, osc_checksum, osc_seq_num, osc_translated_from_id, osc_is_active, osc_is_published, osc_publisher_id, osc_datetime_published)
VALUES 
	(16, 'SSP5-8,5 — émissions de GES en forte augmentation, doublement en 2050. Voir "Scénarios d''émissions et de réchauffement futurs dans le sixième Rapport d''évaluation du GIEC" (https://www.ipcc.ch/report/ar6/wg1/downloads/report/IPCC_AR6_WG1_SPM_French.pdf).', 'SSP5-8,5', 'SSP5-8,5', 'SSP5-8,5','key1=>value1_fr,key2=>value2_fr','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'fr', 'osc_checksum',1,5, 'y','y', 1,'2024-07-15T00:00:01Z')
;
INSERT INTO osc_physrisk.osc_physrisk_scenarios.scenario
	(osc_id, osc_description_full, osc_description_short, osc_name_display, osc_name, osc_tags, osc_datetime_created, osc_creator_user_id, osc_datetime_last_modified, osc_last_modifier_user_id, osc_is_deleted, osc_deleter_user_id, osc_datetime_deleted, osc_culture, osc_checksum, osc_seq_num, osc_translated_from_id, osc_is_active, osc_is_published, osc_publisher_id, osc_datetime_published)
VALUES 
	(17, 'RCP2.6 - le scénario d''émissions faibles, nous présente un futur où nous limitons les changements climatiques d''origine humaine. Le maximum des émissions de carbone est atteint raposc_idement, suivi d''une réduction qui mène vers une valeur presque nulle bien avant la fin du siècle. Voir « Scénarios d''émissions : les RCP » (https://donneesclimatiques.ca/interactive/scenarios-demissions-les-rcp/)', 'RCP2.6', 'RCP2.6', 'RCP2.6','key1=>value1_fr,key2=>value2_fr','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'fr', 'osc_checksum',1,6, 'y','y', 1,'2024-07-15T00:00:01Z')
;
INSERT INTO osc_physrisk.osc_physrisk_scenarios.scenario
	(osc_id, osc_description_full, osc_description_short, osc_name_display, osc_name, osc_tags, osc_datetime_created, osc_creator_user_id, osc_datetime_last_modified, osc_last_modifier_user_id, osc_is_deleted, osc_deleter_user_id, osc_datetime_deleted, osc_culture, osc_checksum, osc_seq_num, osc_translated_from_id, osc_is_active, osc_is_published, osc_publisher_id, osc_datetime_published)
VALUES 
	(18, 'RCP4.5 - un scénario d''émissions modérées, nous présente un futur où nous incluons des mesures pour limiter les changements climatiques d''origine humaine. Ce scénario exige que les émissions mondiales de carbone soient stabilisées d''ici la fin du siècle. Voir « Scénarios d''émissions : les RCP » (https://donneesclimatiques.ca/interactive/scenarios-demissions-les-rcp/)', 'RCP4.5', 'RCP4.5', 'RCP4.5','key1=>value1_fr,key2=>value2_fr','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'fr', 'osc_checksum',1,7, 'y','y', 1,'2024-07-15T00:00:01Z')
;
INSERT INTO osc_physrisk.osc_physrisk_scenarios.scenario
	(osc_id, osc_description_full, osc_description_short, osc_name_display, osc_name, osc_tags, osc_datetime_created, osc_creator_user_id, osc_datetime_last_modified, osc_last_modifier_user_id, osc_is_deleted, osc_deleter_user_id, osc_datetime_deleted, osc_culture, osc_checksum, osc_seq_num, osc_translated_from_id, osc_is_active, osc_is_published, osc_publisher_id, osc_datetime_published)
VALUES 
	(19, 'RCP6 -  Voir « Scénarios d''émissions : les RCP » (https://donneesclimatiques.ca/interactive/scenarios-demissions-les-rcp/)', 'RCP6', 'RCP6', 'RCP6','key1=>value1_fr,key2=>value2_fr','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'fr', 'osc_checksum',1,8, 'y','y', 1,'2024-07-15T00:00:01Z')
;
INSERT INTO osc_physrisk.osc_physrisk_scenarios.scenario
	(osc_id, osc_description_full, osc_description_short, osc_name_display, osc_name, osc_tags, osc_datetime_created, osc_creator_user_id, osc_datetime_last_modified, osc_last_modifier_user_id, osc_is_deleted, osc_deleter_user_id, osc_datetime_deleted, osc_culture, osc_checksum, osc_seq_num, osc_translated_from_id, osc_is_active, osc_is_published, osc_publisher_id, osc_datetime_published)
VALUES 
	(20, 'RCP8.5 - le scénario d''émissions élevées, nous présente un futur où peu de restrictions aux émissions ont été mises en place. Les émissions continuent d''augmenter raposc_idement au cours de ce siècle, et se stabilisent seulement après 2250. Voir « Scénarios d''émissions : les RCP » (https://donneesclimatiques.ca/interactive/scenarios-demissions-les-rcp/)', 'RCP8.5', 'RCP8.5', 'RCP8.5','key1=>value1_fr,key2=>value2_fr','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'fr', 'osc_checksum',1,9, 'y','y', 1,'2024-07-15T00:00:01Z')
;
-- DATA IN FRENCH ENDS
-- DATA IN SPANISH BEGINS
INSERT INTO osc_physrisk.osc_physrisk_scenarios.scenario
	(osc_id, osc_description_full, osc_description_short, osc_name_display, osc_name, osc_tags, osc_datetime_created, osc_creator_user_id, osc_datetime_last_modified, osc_last_modifier_user_id, osc_is_deleted, osc_deleter_user_id, osc_datetime_deleted, osc_culture, osc_checksum, osc_seq_num, osc_translated_from_id, osc_is_active, osc_is_published, osc_publisher_id, osc_datetime_published)
VALUES 
	(21, 'Desconocosc_ido/no seleccionado', 'Desconocosc_ido/no seleccionado', 'Desconocosc_ido/no seleccionado', 'Desconocosc_ido/no seleccionado','key1=>value1_es,key2=>value2_es','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'es', 'osc_checksum',1,-1, 'y','y', 1,'2024-07-15T00:00:01Z')
;
INSERT INTO osc_physrisk.osc_physrisk_scenarios.scenario
	(osc_id, osc_description_full, osc_description_short, osc_name_display, osc_name, osc_tags, osc_datetime_created, osc_creator_user_id, osc_datetime_last_modified, osc_last_modifier_user_id, osc_is_deleted, osc_deleter_user_id, osc_datetime_deleted, osc_culture, osc_checksum, osc_seq_num, osc_translated_from_id, osc_is_active, osc_is_published, osc_publisher_id, osc_datetime_published)
VALUES 
	(22, 'Histórico (antes 2014). Ver "El Grupo Interguberosc_namental de Expertos sobre el Cambio Climático (IPCC)" (https://www.ipcc.ch/languages-2/spanish/).', 'Histórico (antes 2014)', 'Histórico (antes 2014)', 'Histórico (antes 2014)','key1=>value1_es,key2=>value2_es','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'es', 'osc_checksum',1,0, 'y','y', 1,'2024-07-15T00:00:01Z')
;
INSERT INTO osc_physrisk.osc_physrisk_scenarios.scenario
	(osc_id, osc_description_full, osc_description_short, osc_name_display, osc_name, osc_tags, osc_datetime_created, osc_creator_user_id, osc_datetime_last_modified, osc_last_modifier_user_id, osc_is_deleted, osc_deleter_user_id, osc_datetime_deleted, osc_culture, osc_checksum, osc_seq_num, osc_translated_from_id, osc_is_active, osc_is_published, osc_publisher_id, osc_datetime_published)
VALUES 
	(23, 'SSP1-1.9 — Las trayectorias socioeconómicas compartosc_idas (SSP, por sus siglas en inglés) son escenarios de cambios socioeconómicos globales proyectados hasta 2100. Ver "El Grupo Interguberosc_namental de Expertos sobre el Cambio Climático (IPCC)" (https://www.ipcc.ch/languages-2/spanish/).', 'SSP1-1,9', 'SSP1-1,9', 'SSP1-1,9','key1=>value1_es,key2=>value2_es','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'es', 'osc_checksum',1,1, 'y','y', 1,'2024-07-15T00:00:01Z')
;
INSERT INTO osc_physrisk.osc_physrisk_scenarios.scenario
	(osc_id, osc_description_full, osc_description_short, osc_name_display, osc_name, osc_tags, osc_datetime_created, osc_creator_user_id, osc_datetime_last_modified, osc_last_modifier_user_id, osc_is_deleted, osc_deleter_user_id, osc_datetime_deleted, osc_culture, osc_checksum, osc_seq_num, osc_translated_from_id, osc_is_active, osc_is_published, osc_publisher_id, osc_datetime_published)
VALUES 
	(24, 'SSP1-2.6 - Las trayectorias socioeconómicas compartosc_idas (SSP, por sus siglas en inglés) son escenarios de cambios socioeconómicos globales proyectados hasta 2100. Ver "El Grupo Interguberosc_namental de Expertos sobre el Cambio Climático (IPCC)" (https://www.ipcc.ch/languages-2/spanish/).', 'SSP1-2.6', 'SSP1-2.6', 'SSP1-2.6','key1=>value1_es,key2=>value2_es','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'es', 'osc_checksum',1,2, 'y','y', 1,'2024-07-15T00:00:01Z')
;
INSERT INTO osc_physrisk.osc_physrisk_scenarios.scenario
	(osc_id, osc_description_full, osc_description_short, osc_name_display, osc_name,osc_tags,  osc_datetime_created, osc_creator_user_id, osc_datetime_last_modified, osc_last_modifier_user_id, osc_is_deleted, osc_deleter_user_id, osc_datetime_deleted, osc_culture, osc_checksum, osc_seq_num, osc_translated_from_id, osc_is_active, osc_is_published, osc_publisher_id, osc_datetime_published)
VALUES 
	(25, 'SSP2-4.5 Las trayectorias socioeconómicas compartosc_idas (SSP, por sus siglas en inglés) son escenarios de cambios socioeconómicos globales proyectados hasta 2100. Ver "El Grupo Interguberosc_namental de Expertos sobre el Cambio Climático (IPCC)" (https://www.ipcc.ch/languages-2/spanish/).', 'SSP2-4.5', 'SSP2-4.5', 'SSP2-4.5','key1=>value1_es,key2=>value2_es','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'es', 'osc_checksum',1,3, 'y','y', 1,'2024-07-15T00:00:01Z')
;
INSERT INTO osc_physrisk.osc_physrisk_scenarios.scenario
	(osc_id, osc_description_full, osc_description_short, osc_name_display, osc_name, osc_tags, osc_datetime_created, osc_creator_user_id, osc_datetime_last_modified, osc_last_modifier_user_id, osc_is_deleted, osc_deleter_user_id, osc_datetime_deleted, osc_culture, osc_checksum, osc_seq_num, osc_translated_from_id, osc_is_active, osc_is_published, osc_publisher_id, osc_datetime_published)
VALUES 
	(26, 'SSP3-7.0 - Las trayectorias socioeconómicas compartosc_idas (SSP, por sus siglas en inglés) son escenarios de cambios socioeconómicos globales proyectados hasta 2100. Ver "El Grupo Interguberosc_namental de Expertos sobre el Cambio Climático (IPCC)" (https://www.ipcc.ch/languages-2/spanish/).', 'SSP3-7.0', 'SSP3-7.0', 'SSP3-7.0','key1=>value1_es,key2=>value2_es','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'es', 'osc_checksum',1,4, 'y','y', 1,'2024-07-15T00:00:01Z')
;
INSERT INTO osc_physrisk.osc_physrisk_scenarios.scenario
	(osc_id, osc_description_full, osc_description_short, osc_name_display, osc_name, osc_tags, osc_datetime_created, osc_creator_user_id, osc_datetime_last_modified, osc_last_modifier_user_id, osc_is_deleted, osc_deleter_user_id, osc_datetime_deleted, osc_culture, osc_checksum, osc_seq_num, osc_translated_from_id, osc_is_active, osc_is_published, osc_publisher_id, osc_datetime_published)
VALUES 
	(27, 'SSP5-8.5 - Las trayectorias socioeconómicas compartosc_idas (SSP, por sus siglas en inglés) son escenarios de cambios socioeconómicos globales proyectados hasta 2100. Ver "El Grupo Interguberosc_namental de Expertos sobre el Cambio Climático (IPCC)" (https://www.ipcc.ch/languages-2/spanish/).', 'SSP5-8.5', 'SSP5-8.5', 'SSP5-8.5','key1=>value1_es,key2=>value2_es','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'es', 'osc_checksum',1,5, 'y','y', 1,'2024-07-15T00:00:01Z')
;
INSERT INTO osc_physrisk.osc_physrisk_scenarios.scenario
	(osc_id, osc_description_full, osc_description_short, osc_name_display, osc_name, osc_tags, osc_datetime_created, osc_creator_user_id, osc_datetime_last_modified, osc_last_modifier_user_id, osc_is_deleted, osc_deleter_user_id, osc_datetime_deleted, osc_culture, osc_checksum, osc_seq_num, osc_translated_from_id, osc_is_active, osc_is_published, osc_publisher_id, osc_datetime_published)
VALUES 
	(28, 'RCP2.6 Una trayectoria de concentración representativa (RCP, por sus siglas en inglés) es una proyección teórica de una trayectoria de concentración de gases de efecto invernadero (no emisiones) adoptada por el IPCC. Ver "El Grupo Interguberosc_namental de Expertos sobre el Cambio Climático (IPCC)" (https://www.ipcc.ch/languages-2/spanish/).', 'RCP2.6', 'RCP2.6', 'RCP2.6','key1=>value1_es,key2=>value2_es','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'es', 'osc_checksum',1,6, 'y','y', 1,'2024-07-15T00:00:01Z')
;
INSERT INTO osc_physrisk.osc_physrisk_scenarios.scenario
	(osc_id, osc_description_full, osc_description_short, osc_name_display, osc_name, osc_tags, osc_datetime_created, osc_creator_user_id, osc_datetime_last_modified, osc_last_modifier_user_id, osc_is_deleted, osc_deleter_user_id, osc_datetime_deleted, osc_culture, osc_checksum, osc_seq_num, osc_translated_from_id, osc_is_active, osc_is_published, osc_publisher_id, osc_datetime_published)
VALUES 
	(29, 'RCP4.5 - Una trayectoria de concentración representativa (RCP, por sus siglas en inglés) es una proyección teórica de una trayectoria de concentración de gases de efecto invernadero (no emisiones) adoptada por el IPCC. Ver "El Grupo Interguberosc_namental de Expertos sobre el Cambio Climático (IPCC)" (https://www.ipcc.ch/languages-2/spanish/).', 'RCP4.5', 'RCP4.5', 'RCP4.5','key1=>value1_es,key2=>value2_es','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'es', 'osc_checksum',1,7, 'y','y', 1,'2024-07-15T00:00:01Z')
;
INSERT INTO osc_physrisk.osc_physrisk_scenarios.scenario
	(osc_id, osc_description_full, osc_description_short, osc_name_display, osc_name,osc_tags,  osc_datetime_created, osc_creator_user_id, osc_datetime_last_modified, osc_last_modifier_user_id, osc_is_deleted, osc_deleter_user_id, osc_datetime_deleted, osc_culture, osc_checksum, osc_seq_num, osc_translated_from_id, osc_is_active, osc_is_published, osc_publisher_id, osc_datetime_published)
VALUES 
	(30, 'RCP6 - Una trayectoria de concentración representativa (RCP, por sus siglas en inglés) es una proyección teórica de una trayectoria de concentración de gases de efecto invernadero (no emisiones) adoptada por el IPCC. Ver "El Grupo Interguberosc_namental de Expertos sobre el Cambio Climático (IPCC)" (https://www.ipcc.ch/languages-2/spanish/).', 'RCP6', 'RCP6', 'RCP6','key1=>value1_es,key2=>value2_es','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'es', 'osc_checksum',1,8, 'y','y', 1,'2024-07-15T00:00:01Z')
;
INSERT INTO osc_physrisk.osc_physrisk_scenarios.scenario
	(osc_id, osc_description_full, osc_description_short, osc_name_display, osc_name, osc_tags, osc_datetime_created, osc_creator_user_id, osc_datetime_last_modified, osc_last_modifier_user_id, osc_is_deleted, osc_deleter_user_id, osc_datetime_deleted, osc_culture, osc_checksum, osc_seq_num, osc_translated_from_id, osc_is_active, osc_is_published, osc_publisher_id, osc_datetime_published)
VALUES 
	(31, 'RCP8.5 - Una trayectoria de concentración representativa (RCP, por sus siglas en inglés) es una proyección teórica de una trayectoria de concentración de gases de efecto invernadero (no emisiones) adoptada por el IPCC. Ver "El Grupo Interguberosc_namental de Expertos sobre el Cambio Climático (IPCC)" (https://www.ipcc.ch/languages-2/spanish/).', 'RCP8.5', 'RCP8.5', 'RCP8.5','key1=>value1_es,key2=>value2_es','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'es', 'osc_checksum',1,9, 'y','y', 1,'2024-07-15T00:00:01Z')
;

-- DATA IN SPANISH ENDS


-- INSERT ASSET PORTFOLIO EXAMPLE
-- INCLUDING EXAMPLE ASSET WITH OED AND NAICS osc_tags
INSERT INTO osc_physrisk.osc_physrisk_assets.asset_class
	(osc_id, osc_name, osc_name_display, osc_description_full, osc_description_short, osc_tags, osc_datetime_created, osc_creator_user_id, osc_datetime_last_modified, osc_last_modifier_user_id, osc_is_deleted, osc_deleter_user_id, osc_datetime_deleted, osc_culture, osc_checksum, osc_seq_num, osc_translated_from_id, osc_is_active, osc_is_published, osc_publisher_id, osc_datetime_published)
VALUES 
	('536e8cee-682f-4cd6-b23e-b32e885cc094', 'Real Estate', 'Real Estate', 'Real Estate', 'Real Estate', '','2024-07-25T00:00:01Z',1,'2024-07-25T00:00:01Z',1,'n',NULL,NULL, 'en', 'osc_checksum',1,NULL, 'y','y',1,'2024-07-25T00:00:01Z');
INSERT INTO osc_physrisk.osc_physrisk_assets.asset_class
	(osc_id, osc_name, osc_name_display, osc_description_full, osc_description_short, osc_tags, osc_datetime_created, osc_creator_user_id, osc_datetime_last_modified, osc_last_modifier_user_id, osc_is_deleted, osc_deleter_user_id, osc_datetime_deleted, osc_culture, osc_checksum, osc_seq_num, osc_translated_from_id, osc_is_active, osc_is_published, osc_publisher_id, osc_datetime_published)
VALUES 
	('f2baa602-44fe-49be-a5c9-d8b8208d9499', 'Power Generating Utility', 'Power Generating Utility', 'Power Generating Utility', 'Power Generating Utility', '','2024-07-25T00:00:01Z',1,'2024-07-25T00:00:01Z',1,'n',NULL,NULL, 'en', 'osc_checksum',1,NULL, 'y','y',1,'2024-07-25T00:00:01Z');

INSERT INTO osc_physrisk.osc_physrisk_assets.asset_type
	(osc_id, osc_name, osc_name_display, osc_description_full, osc_description_short, osc_tags, osc_datetime_created, osc_creator_user_id, osc_datetime_last_modified, osc_last_modifier_user_id, osc_is_deleted, osc_deleter_user_id, osc_datetime_deleted, osc_culture, osc_checksum, osc_seq_num, osc_translated_from_id, osc_is_active, osc_is_published, osc_publisher_id, osc_datetime_published,osc_asset_class_id)
VALUES 
	('85246f30-e622-4af9-af86-16b23e8671a7', 'Commercial Real Estate', 'Commercial Real Estate', 'Commercial Real Estate', 'Commercial Real Estate', '','2024-07-25T00:00:01Z',1,'2024-07-25T00:00:01Z',1,'n',NULL,NULL, 'en', 'osc_checksum',1,NULL, 'y','y',1,'2024-07-25T00:00:01Z','536e8cee-682f-4cd6-b23e-b32e885cc094');
INSERT INTO osc_physrisk.osc_physrisk_assets.asset_type
	(osc_id, osc_name, osc_name_display, osc_description_full, osc_description_short, osc_tags, osc_datetime_created, osc_creator_user_id, osc_datetime_last_modified, osc_last_modifier_user_id, osc_is_deleted, osc_deleter_user_id, osc_datetime_deleted, osc_culture, osc_checksum, osc_seq_num, osc_translated_from_id, osc_is_active, osc_is_published, osc_publisher_id, osc_datetime_published,osc_asset_class_id)
VALUES 
	('3a568df0-cf71-4598-9bc7-2fb5997fb30d', 'Power Generating Utility', 'Power Generating Utility', 'Power Generating Utility', 'Power Generating Utility', '','2024-07-25T00:00:01Z',1,'2024-07-25T00:00:01Z',1,'n',NULL,NULL, 'en', 'osc_checksum',1,NULL, 'y','y',1,'2024-07-25T00:00:01Z','f2baa602-44fe-49be-a5c9-d8b8208d9499');

INSERT INTO osc_physrisk.osc_physrisk_assets.portfolio
	(osc_id, osc_name, osc_name_display, osc_description_full, osc_description_short, osc_tags, osc_datetime_created, osc_creator_user_id, osc_datetime_last_modified, osc_last_modifier_user_id, osc_is_deleted, osc_deleter_user_id, osc_datetime_deleted, osc_culture, osc_checksum, osc_seq_num, osc_translated_from_id, osc_is_active, osc_tenant_id, osc_is_published, osc_publisher_id, osc_datetime_published, value_total, value_currency_alphabetic_code)
VALUES 
	('07c629be-42c6-4dbe-bd56-83e64253368d', 'Example Portfolio 1', 'Example Portfolio 1', 'Example Portfolio 1', 'Example Portfolio 1', '','2024-07-25T00:00:01Z',1,'2024-07-25T00:00:01Z',1,'n',NULL,NULL, 'en', 'osc_checksum',1,NULL, 'y', 1,'y',1,'2024-07-25T00:00:01Z', 12345678.90, 'USD');

INSERT INTO osc_physrisk.osc_physrisk_assets.asset_realestate
	(osc_id, osc_name, osc_name_display, osc_description_full, osc_description_short, osc_tags, osc_datetime_created, osc_creator_user_id, osc_datetime_last_modified, osc_last_modifier_user_id, osc_is_deleted, osc_deleter_user_id, osc_datetime_deleted, osc_culture, osc_checksum, osc_seq_num, osc_translated_from_id, osc_is_active,osc_tenant_id, osc_is_published, osc_publisher_id, osc_datetime_published, osc_portfolio_id, geo_location_name, geo_location_coordinates, geo_overture_features, geo_h3_index, geo_h3_resolution, osc_asset_type_id, owner_bloomberg_osc_id, owner_lei_osc_id, value_total, value_currency_alphabetic_code, value_ltv)
VALUES 
	('281d68cc-ffd3-4740-acd6-1ea23bce902f', 'Commercial Real Estate asset example', 'Commercial Real Estate asset example', 'Commercial Real Estate asset example', 'Commercial Real Estate asset example', 'naics=>531111,oed:occupancy:oed_code=>1050,oed:occupancy:air_code=>301','2024-07-25T00:00:01Z',1,'2024-07-25T00:00:01Z',1,'n',NULL,NULL, 'en', 'osc_checksum',1,NULL, 'y', 1,'y',1,'2024-07-25T00:00:01Z' , '07c629be-42c6-4dbe-bd56-83e64253368d', 'Fake location', ST_GeomFromText('POINT(-71.064544 42.28787)'), '{}', '1234', 12, '85246f30-e622-4af9-af86-16b23e8671a7', 'BBG000BLNQ16', '', 12345678.90, 'USD','{LTV value ratio}')
;
INSERT INTO osc_physrisk.osc_physrisk_assets.asset_powergeneratingutility
	(osc_id, osc_name, osc_name_display, osc_description_full, osc_description_short, osc_tags, osc_datetime_created, osc_creator_user_id, osc_datetime_last_modified, osc_last_modifier_user_id, osc_is_deleted, osc_deleter_user_id, osc_datetime_deleted, osc_culture, osc_checksum, osc_seq_num, osc_translated_from_id, osc_is_active, osc_tenant_id, osc_is_published, osc_publisher_id, osc_datetime_published, osc_portfolio_id, geo_location_name, geo_location_coordinates, geo_overture_features, geo_h3_index, geo_h3_resolution,osc_asset_type_id,  owner_bloomberg_osc_id, owner_lei_osc_id, value_total, value_currency_alphabetic_code, production, capacity, availability_rate)
VALUES 
	('78cb5382-5e4f-4762-b2e8-7cb33954f788', 'Electrical Power Generating Utility example', 'Electrical Power Generating Utility example', 'Electrical Power Generating Utility example', 'Electrical Power Generating Utility example', 'naics=>22111,oed:occupancy:oed_code=>1300,oed:occupancy:air_code=>361','2024-07-25T00:00:01Z',1,'2024-07-25T00:00:01Z',1,'n',NULL,NULL, 'en', 'osc_checksum',1,NULL, 'y', 1,'y',1,'2024-07-25T00:00:01Z' , '07c629be-42c6-4dbe-bd56-83e64253368d', 'Fake location', ST_GeomFromText('POINT(-71.064544 42.28787)'), '{}', '1234', 12, '3a568df0-cf71-4598-9bc7-2fb5997fb30d', 'BBG000BLNQ16', '', 12345678.90, 'USD', 12345.0,100.00,95.00)
;


-- INSERT PRECALCULATED IMPACT EXAMPLE
INSERT INTO osc_physrisk.osc_physrisk_analysis_results.geolocated_precalculated_impact
	(osc_id, osc_name, osc_name_display, osc_abbreviation, osc_description_full, osc_description_short, osc_tags, osc_datetime_created, osc_creator_user_id, osc_datetime_last_modified, osc_last_modifier_user_id, osc_is_deleted, osc_deleter_user_id, osc_datetime_deleted, osc_culture, osc_checksum, osc_seq_num, osc_translated_from_id, osc_is_active, osc_tenant_id,osc_is_published, osc_publisher_id, osc_datetime_published, osc_hazard_id, osc_scenario_id, osc_scenario_year, analysis_data_source, geo_location_name, geo_location_address, geo_location_coordinates, geo_overture_features, geo_h3_index, geo_h3_resolution, is_impacted, is_historic_impact, historic_impact_started, historic_impact_ended, impact_data_raw)
VALUES 
	('3bbb4a0e-f719-4e78-864b-3962e7f9e3a4', 'Example stored precalculated impact damage curve for Utility', 'Example stored precalculated impact damage curve for Utility', NULL, 'Example stored precalculated impact damage curve for Utility','Example stored precalculated impact damage curve for Utility', 'key1=>value1_en,key2=>value2_en','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'en', 'osc_checksum',1,NULL,'y', 1,'y',1,'2024-07-15T00:00:01Z','63ed7943-c4c4-43ea-abd2-86bb1997a094', 3, 2040, 'WRI Data', '07c629be-42c6-4dbe-bd56-83e64253368d', 'Fake location', ST_GeomFromText('POINT(-71.064544 42.28787)'), '{}', '1234', 12, 'y', 'n',NULL ,NULL , '{
    "items": [
        {
            "asset_type": "Steam/OnceThrough",
            "event_type": "Inundation",
            "impact_mean": [
                0.0,
                1.0,
                2.0,
                7.0,
                14.0,
                30.0,
                60.0,
                180.0,
                365.0
            ],
            "impact_std": [],
            "impact_type": "Disruption",
            "impact_units": "Days",
            "intensity": [
                0.0,
                0.1,
                0.2,
                0.3,
                0.4,
                0.5,
                0.6,
                0.7,
                1.0
            ],
            "intensity_units": "Metres",
            "location": "Global"
        },
        {
            "asset_type": "Steam/Dry",
            "event_type": "Inundation",
            "impact_mean": [
                0.0,
                1.0,
                2.0,
                7.0,
                14.0,
                30.0,
                60.0,
                180.0,
                365.0
            ],
            "impact_std": [],
            "impact_type": "Disruption",
            "impact_units": "Days",
            "intensity": [
                0.0,
                0.1,
                0.2,
                0.3,
                0.4,
                0.5,
                0.6,
                0.7,
                1.0
            ],
            "intensity_units": "Metres",
            "location": "Global"
        },
        {
            "asset_type": "Gas",
            "event_type": "Inundation",
            "impact_mean": [
                0.0,
                1.0,
                2.0,
                7.0,
                14.0,
                30.0,
                60.0,
                180.0,
                365.0
            ],
            "impact_std": [],
            "impact_type": "Disruption",
            "impact_units": "Days",
            "intensity": [
                0.0,
                0.1,
                0.2,
                0.3,
                0.4,
                0.5,
                0.6,
                0.7,
                1.0
            ],
            "intensity_units": "Metres",
            "location": "Global"
        },
        {
            "asset_type": "Steam/Recirculating",
            "event_type": "Inundation",
            "impact_mean": [
                0.0,
                1.0,
                2.0,
                7.0,
                14.0,
                30.0,
                60.0,
                180.0,
                365.0
            ],
            "impact_std": [],
            "impact_type": "Disruption",
            "impact_units": "Days",
            "intensity": [
                0.0,
                0.1,
                0.2,
                0.3,
                0.4,
                0.5,
                0.6,
                0.7,
                1.0
            ],
            "intensity_units": "Metres",
            "location": "Global"
        },
        {
            "asset_type": "Steam/Dry",
            "event_type": "AirTemperature",
            "impact_mean": [
                0.0,
                0.02,
                0.04,
                0.08,
                0.11,
                0.15,
                1.0
            ],
            "impact_std": [],
            "impact_type": "Disruption",
            "impact_units": "Days",
            "intensity": [
                0.0,
                6.0,
                12.0,
                18.0,
                24.0,
                30.0,
                198.0
            ],
            "intensity_units": "DegreesCelsius",
            "location": "Global"
        },
        {
            "asset_type": "Gas",
            "event_type": "AirTemperature",
            "impact_mean": [
                0.0,
                0.1,
                0.25,
                0.5,
                0.8,
                1.0
            ],
            "impact_std": [],
            "impact_type": "Disruption",
            "impact_units": "Days",
            "intensity": [
                0.0,
                10.0,
                20.0,
                30.0,
                40.0,
                50.0
            ],
            "intensity_units": "DegreesCelsius",
            "location": "Global"
        },
        {
            "asset_type": "Steam/OnceThrough",
            "event_type": "Drought",
            "impact_mean": [
                0.0,
                0.0,
                0.1,
                0.2,
                1.0
            ],
            "impact_std": [],
            "impact_type": "Disruption",
            "impact_units": "Days",
            "intensity": [
                0.0,
                -2.0,
                -2.5,
                -3.0,
                -3.6
            ],
            "intensity_units": "Unitless",
            "location": "Global"
        },
        {
            "asset_type": "Steam/Recirculating",
            "event_type": "Drought",
            "impact_mean": [
                0.0,
                0.0,
                0.1,
                0.2,
                1.0
            ],
            "impact_std": [],
            "impact_type": "Disruption",
            "impact_units": "Days",
            "intensity": [
                0.0,
                -2.0,
                -2.5,
                -3.0,
                -3.6
            ],
            "intensity_units": "Unitless",
            "location": "Global"
        },
        {
            "asset_type": "Steam/OnceThrough",
            "event_type": "WaterTemperature",
            "impact_mean": [
                0.0,
                0.003,
                0.009,
                0.017,
                0.027,
                0.041,
                0.061,
                0.089,
                0.118,
                0.157,
                0.205,
                0.257,
                0.327,
                0.411,
                0.508,
                0.629,
                0.775,
                1.0
            ],
            "impact_std": [],
            "impact_type": "Disruption",
            "impact_units": "Days",
            "intensity": [
                0.0,
                1.0,
                2.0,
                3.0,
                4.0,
                5.0,
                6.0,
                7.0,
                8.0,
                9.0,
                10.0,
                11.0,
                12.0,
                13.0,
                14.0,
                15.0,
                16.0,
                17.0
            ],
            "intensity_units": "DegreesCelsius",
            "location": "Global"
        },
        {
            "asset_type": "Steam/Recirculating",
            "event_type": "WaterTemperature",
            "impact_mean": [
                0.0,
                0.003,
                0.009,
                0.017,
                0.027,
                0.041,
                0.061,
                0.089,
                0.118,
                0.157,
                0.205,
                0.257,
                0.327,
                0.411,
                0.508,
                0.629,
                0.775,
                1.0
            ],
            "impact_std": [],
            "impact_type": "Disruption",
            "impact_units": "Days",
            "intensity": [
                0.0,
                1.0,
                2.0,
                3.0,
                4.0,
                5.0,
                6.0,
                7.0,
                8.0,
                9.0,
                10.0,
                11.0,
                12.0,
                13.0,
                14.0,
                15.0,
                16.0,
                17.0
            ],
            "intensity_units": "DegreesCelsius",
            "location": "Global"
        },
        {
            "asset_type": "Steam/OnceThrough",
            "event_type": "WaterStress",
            "impact_mean": [
                0.0,
                0.02,
                0.1,
                0.2,
                0.5,
                1.0
            ],
            "impact_std": [],
            "impact_type": "Disruption",
            "impact_units": "Days",
            "intensity": [
                0.0,
                0.1,
                0.25,
                0.5,
                0.75,
                1.0
            ],
            "intensity_units": "Unitless",
            "location": "Global"
        },
        {
            "asset_type": "Steam/Recirculating",
            "event_type": "WaterStress",
            "impact_mean": [
                0.0,
                0.02,
                0.1,
                0.2,
                0.5,
                1.0
            ],
            "impact_std": [],
            "impact_type": "Disruption",
            "impact_units": "Days",
            "intensity": [
                0.0,
                0.1,
                0.25,
                0.5,
                0.75,
                1.0
            ],
            "intensity_units": "Unitless",
            "location": "Global"
        },
        {
            "asset_type": "Steam/OnceThrough",
            "event_type": "RegulatoryDischargeWaterLimit",
            "impact_mean": [
                0.0,
                0.1,
                0.2,
                0.4,
                0.5,
                1.0
            ],
            "impact_std": [],
            "impact_type": "Disruption",
            "impact_units": "Days",
            "intensity": [
                27.0,
                28.0,
                29.0,
                30.0,
                31.0,
                32.0
            ],
            "intensity_units": "DegreesCelsius",
            "location": "Global"
        }
    ]
}
');

-- EXAMPLE QUERIES
-- VIEW SCENARIOS IN DIFFERENT LANGUAGES
SELECT * FROM osc_physrisk.osc_physrisk_scenarios.scenario WHERE osc_culture='en';
SELECT * FROM osc_physrisk.osc_physrisk_scenarios.scenario WHERE osc_culture='fr';
SELECT * FROM osc_physrisk.osc_physrisk_scenarios.scenario WHERE osc_culture='es';

SELECT a.osc_name as "English osc_name",  b.osc_culture as "Translated osc_culture",  b.osc_name as "Translated osc_name", b.osc_description_full as "Translated Description", b.osc_tags as "Translated osc_tags" FROM osc_physrisk.osc_physrisk_scenarios.scenario a 
INNER JOIN osc_physrisk.osc_physrisk_scenarios.scenario b ON a.osc_id = b.osc_translated_from_id
WHERE b.osc_culture='es'  ;

-- QUERY BY osc_tags EXAMPLE: FIND ASSETS WITH A CERTAIN NAICS OR OED OCCUPANCY VALUE (SHOWS HOW TO SUPPORT MULTIPLE STANDARDS)
SELECT a.osc_name,  a.osc_description_full, a.osc_tags, b.osc_name as asset_class FROM osc_physrisk.osc_physrisk_assets.asset a INNER JOIN osc_physrisk.osc_physrisk_assets.asset_class b ON a.osc_asset_class_id = b.osc_id
WHERE a.osc_tags -> 'naics'='22111' OR a.osc_tags -> 'oed:occupancy:oed_code'='1300' OR a.osc_tags -> 'oed:occupancy:air_code'='361' ;

SELECT a.osc_name,  a.osc_description_full, a.osc_tags, b.osc_name as asset_class FROM osc_physrisk.osc_physrisk_assets.asset a INNER JOIN osc_physrisk.osc_physrisk_assets.asset_class b ON a.osc_asset_class_id = b.osc_id
WHERE a.osc_tags -> 'naics' LIKE '53%'  ;

-- QUERY BY osc_tags EXAMPLE: FIND SCENARIOS WITH CERTAIN osc_tags
SELECT a.osc_name,  a.osc_description_full, a.osc_tags FROM osc_physrisk.osc_physrisk_scenarios.scenario a
WHERE a.osc_tags -> 'key1'='value1_en' OR a.osc_tags -> 'key2'='value4_en'  ;

-- SHOW IMPACT ANALYSIS EXAMPLE (CURRENTLY EMPTY - TODO MISSING TEST DATA)
SELECT	* FROM	osc_physrisk.osc_physrisk_analysis_results.portfolio_impact;
SELECT * FROM osc_physrisk.osc_physrisk_analysis_results.asset_impact;

-- VIEW RIVERINE INUNDATION HAZARD INDICATORS
SELECT	*
FROM
	osc_physrisk.osc_physrisk_hazards.hazard haz INNER JOIN osc_physrisk.osc_physrisk_hazards.hazard_indicator hi ON hi.osc_hazard_id = haz.osc_id
WHERE haz.osc_name = 'Riverine Inundation' -- more likely written as WHERE haz.osc_id = '63ed7943-c4c4-43ea-abd2-86bb1997a094'
;

-- VIEW COASTAL INUNDATION HAZARD INDICATORS
SELECT	*
FROM
	 osc_physrisk.osc_physrisk_hazards.hazard haz INNER JOIN osc_physrisk.osc_physrisk_hazards.hazard_indicator hi ON hi.osc_hazard_id = haz.osc_id
WHERE haz.osc_id = '28a095cd-4cde-40a1-90d9-cbb0ca673c06'
;

-- VIEW CHRONIC HEAT HAZARD INDICATORS
SELECT	*
FROM
	 osc_physrisk.osc_physrisk_hazards.hazard haz INNER JOIN osc_physrisk.osc_physrisk_hazards.hazard_indicator hi ON hi.osc_hazard_id = haz.osc_id
WHERE haz.osc_id = 'd08db675-ee1e-48fe-b9e1-b0da27de8f2b'
;

-- SAMPLE osc_checksum UPDATE
--UPDATE osc_physrisk.osc_physrisk_scenarios.scenario
--	SET osc_checksum = md5(concat('Unknown/Not Selected', 'Unknown/Not Selected', 'Unknown/Not Selected', 'Unknown/Not Selected')) WHERE scenario_osc_id = -1
--;

-- SELECT DIFFERENT ASSET TYPES
SELECT * from osc_physrisk_assets.asset; -- NOTICE THESE ARE THE GENERIC ASSET COLUMNS AND ALL ASSETS ARE RETURNED
SELECT osc_name, value_ltv from osc_physrisk_assets.asset_realestate; -- NOTICE THE COLUMNS INCLUDE RE-SPECIFIC FIELDS AND ONLY RE ASSETS ARE RETURNED
SELECT osc_name, production, capacity, availability_rate from osc_physrisk_assets.asset_powergeneratingutility; -- NOTICE THE COLUMNS INCLUDE UTILITY-SPECIFIC FIELDS AND ONLY UTILITY ASSETS ARE RETURNED

-- WE CAN ALSO DO A JOIN BY ASSET CLASS TO FILTER THE RESULTS
SELECT * from osc_physrisk_assets.asset a INNER JOIN osc_physrisk.osc_physrisk_assets.asset_class b ON a.osc_asset_class_id = b.osc_id
WHERE b.osc_name LIKE '%Utility%'
; -- NOTICE ONLY UTILITY ROW IS RETURNED

-- QUERY PRECALCULATED DAMAGE CURVES AT A CERTAIN LOCATION
SELECT
	geo_h3_index, geo_h3_resolution, ST_X(geo_location_coordinates::geometry) as Long, ST_Y(geo_location_coordinates::geometry) as Lat, geo_overture_features, is_impacted, is_historic_impact, impact_data_raw
FROM
	osc_physrisk.osc_physrisk_analysis_results.geolocated_precalculated_impact
WHERE geo_h3_index = '1234'
	;