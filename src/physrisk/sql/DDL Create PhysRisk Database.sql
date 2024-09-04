-- PHYRISK EXAMPLE DATABASE STRUCTURE
-- Intended to help standardize glossary/metadata as well as field std_names and constraints
-- to align with phys-risk/geo-indexer/other related initiatives and 
-- speed up application development, help internationalize and display the results of analyses, and more.
-- The backend schema User and Tenant tables are derived from ASP.NET Boilerplate tables (https://aspnetboilerplate.com/). That code is available under the MIT license, here: https://github.com/aspnetboilerplate/aspnetboilerplate

-- Last Updated: 2024-09-04. 
-- Add reporting standards and country lookup tables. Make VARCHAR(256) => VARCHAR(255). Specify in column names that times are in UTC. Split impact assessment into two stages: "1. vulnerability analysis" then "2. financial_impact"
-- Fix duplicate value_dynamics column

-- SETUP EXTENSIONS
CREATE EXTENSION IF NOT EXISTS postgis; -- used for geolocation
CREATE EXTENSION IF NOT EXISTS h3; -- used for Uber H3 geolocation
CREATE EXTENSION IF NOT EXISTS pgcrypto; -- used for random UUID generation

-- SETUP SCHEMAS
CREATE SCHEMA IF NOT EXISTS osc_physrisk_backend;
CREATE SCHEMA IF NOT EXISTS osc_physrisk_scenarios;
CREATE SCHEMA IF NOT EXISTS osc_physrisk_assets;
CREATE SCHEMA IF NOT EXISTS osc_physrisk_vulnerability_analysis;
CREATE SCHEMA IF NOT EXISTS osc_physrisk_financial_analysis;

-- SETUP TABLES
-- SCHEMA osc_physrisk_backend

CREATE TABLE osc_physrisk_backend.user (
	std_id bigint NOT NULL,
	std_datetime_utc_created       timestamptz  NOT NULL  ,
	std_creator_user_id      bigint    ,
	std_datetime_utc_last_modified timestamptz    ,
	std_last_modifier_user_id bigint    ,
	std_is_deleted          boolean  NOT NULL  ,
	std_deleter_user_id      bigint    ,
	std_datetime_utc_deleted       timestamptz    ,
	std_user_name VARCHAR(255) NOT NULL,
	std_tenant_id INTEGER NOT NULL,
	email_address VARCHAR(255) NOT NULL,
	std_name        VARCHAR(255)  NOT NULL  ,
	std_surname        VARCHAR(255)  NOT NULL  ,
	std_is_active       boolean  NOT NULL  ,
	PRIMARY KEY (std_id)
);

ALTER TABLE osc_physrisk_backend.user
	ADD FOREIGN KEY (std_creator_user_id) 
	REFERENCES osc_physrisk_backend.user (std_id);

ALTER TABLE osc_physrisk_backend.user
	ADD FOREIGN KEY (std_deleter_user_id) 
	REFERENCES osc_physrisk_backend.user (std_id);

ALTER TABLE osc_physrisk_backend.user
	ADD FOREIGN KEY (std_last_modifier_user_id) 
	REFERENCES osc_physrisk_backend.user (std_id);

CREATE INDEX "ix_osc_physrisk_backend_users_std_creator_user_id" ON osc_physrisk_backend.user USING btree (std_creator_user_id);
CREATE INDEX "ix_osc_physrisk_backend_users_std_deleter_user_id" ON osc_physrisk_backend.user USING btree (std_deleter_user_id);
CREATE INDEX "ix_osc_physrisk_backend_users_std_last_modifier_user_id" ON osc_physrisk_backend.user USING btree (std_last_modifier_user_id);
CREATE INDEX "ix_osc_physrisk_backend_users_email_address" ON osc_physrisk_backend.user USING btree (std_tenant_id, email_address);
CREATE INDEX "ix_osc_physrisk_backend_users_std_tenant_id_std_user_name" ON osc_physrisk_backend.user USING btree (std_tenant_id, std_user_name);

COMMENT ON TABLE osc_physrisk_backend.user IS 'Stores user information.';

CREATE TABLE osc_physrisk_backend.tenant (
	std_id bigint NOT NULL,
	std_datetime_utc_created       timestamptz  NOT NULL  ,
	std_creator_user_id      bigint    ,
	std_datetime_utc_last_modified timestamptz    ,
	std_last_modifier_user_id bigint    ,
	std_is_deleted          boolean  NOT NULL  ,
	std_deleter_user_id      bigint    ,
	std_datetime_utc_deleted       timestamptz    ,
	std_name varchar(64) NOT NULL,
	std_tenancy_name VARCHAR(255) NOT NULL,
	std_is_active       boolean  NOT NULL  ,
	PRIMARY KEY (std_id),
	CONSTRAINT fk_tenants_std_creator_user_id FOREIGN KEY ( std_creator_user_id ) REFERENCES osc_physrisk_backend.user(std_id),
	CONSTRAINT fk_tenants_std_last_modifier_user_id FOREIGN KEY ( std_last_modifier_user_id ) REFERENCES osc_physrisk_backend.user(std_id),
	CONSTRAINT fk_tenants_std_deleter_user_id FOREIGN KEY ( std_deleter_user_id ) REFERENCES osc_physrisk_backend.user(std_id)
);

CREATE INDEX "ix_osc_physrisk_backend_tenants_std_datetime_utc_created" ON osc_physrisk_backend.tenant USING btree (std_datetime_utc_created);
CREATE INDEX "ix_osc_physrisk_backend_tnants_std_creator_user_id" ON osc_physrisk_backend.tenant USING btree (std_creator_user_id);
CREATE INDEX "ix_osc_physrisk_backend_tenants_std_deleter_user_id" ON osc_physrisk_backend.tenant USING btree (std_deleter_user_id);
CREATE INDEX "ix_osc_physrisk_backend_tenants_std_last_modifier_user_id" ON osc_physrisk_backend.tenant USING btree (std_last_modifier_user_id);
CREATE INDEX "ix_osc_physrisk_backend_tenants_std_tenancy_name" ON osc_physrisk_backend.tenant USING btree (std_tenancy_name);

COMMENT ON TABLE osc_physrisk_backend.tenant IS 'Stores tenant information to support multi-tenancy data (where appropriate). A default tenant is always provstd_ided.';

CREATE TABLE osc_physrisk_backend.dataset ( 
	std_id UUID  DEFAULT gen_random_UUID ()  NOT NULL,
	std_name VARCHAR(255) NOT NULL,
	std_name_display VARCHAR(255),
	std_slug VARCHAR(255),
	std_abbreviation VARCHAR(12),
	std_description_full  TEXT NOT NULL,
	std_description_short  VARCHAR(255) NOT NULL,
    std_tags jsonb DEFAULT NULL,
	std_datetime_utc_created TIMESTAMPTZ NOT NULL,
	std_creator_user_id BIGINT NOT NULL,
	std_datetime_utc_last_modified TIMESTAMPTZ NOT NULL,
	std_last_modifier_user_id BIGINT NOT NULL,
	std_is_deleted BOOLEAN NOT NULL DEFAULT 'n',
	std_deleter_user_id BIGINT DEFAULT NULL,
	std_datetime_utc_deleted TIMESTAMPTZ DEFAULT NULL,
	std_culture VARCHAR(5) NOT NULL DEFAULT 'en',
	std_checksum VARCHAR(40) DEFAULT NULL,
	std_seq_num SMALLINT  NOT NULL Default 0,
	std_translated_from_id UUID DEFAULT NULL,
	std_is_active BOOLEAN NOT NULL DEFAULT 'y',
	std_is_published BOOLEAN DEFAULT 'n',
	std_publisher_id BIGINT DEFAULT NULL,
	std_datetime_utc_published TIMESTAMPTZ DEFAULT NULL,
	std_version TEXT DEFAULT '1.0',
	data_contact TEXT NOT NULL, -- Contact information for inquiries about the dataset.
	data_quality TEXT NOT NULL, -- Information on the accuracy, completeness, and source of the data.
	data_format TEXT NOT NULL, -- Formats in which the data is available.
	data_schema TEXT NOT NULL, -- Describe the data schema, or reference the Json Schema or Frictionless CSV schema. Can be a hyperlink to a relevant schema file.
	data_access_rights TEXT NOT NULL, -- Information on who can access the dataset.
	data_license TEXT NOT NULL, -- The licensing terms under which the dataset is released. License(s) of the data as SPDX License identifier, SPDX License expression, or other. Link to the license text. 
	data_usage_notes TEXT NOT NULL, -- Notes on how the dataset can be used.
	data_related TEXT NOT NULL, -- Links to related datasets for further information or analysis. Could be a list of UUIDs or a textual description, or hyperlinks
	CONSTRAINT pk_scenario PRIMARY KEY ( std_id ),
	CONSTRAINT fk_scenario_std_creator_user_id FOREIGN KEY ( std_creator_user_id ) REFERENCES osc_physrisk_backend.user(std_id),
	CONSTRAINT fk_scenario_std_last_modifier_user_id FOREIGN KEY ( std_last_modifier_user_id ) REFERENCES osc_physrisk_backend.user(std_id),
	CONSTRAINT fk_scenario_std_deleter_user_id FOREIGN KEY ( std_deleter_user_id ) REFERENCES osc_physrisk_backend.user(std_id)
 ); 

 COMMENT ON TABLE osc_physrisk_backend.dataset IS 'Contains a list of the data sets that are in use in this database, facilitating rigourous data hygeine, governance, and reporting tasks.';


CREATE TABLE osc_physrisk_backend.geo_country ( 
	std_id UUID  DEFAULT gen_random_UUID ()  NOT NULL,
	std_name VARCHAR(255) NOT NULL,
	std_name_display VARCHAR(255),
	std_slug VARCHAR(255),
	std_abbreviation VARCHAR(12),
	std_description_full  TEXT NOT NULL,
	std_description_short  VARCHAR(255) NOT NULL,
    std_tags jsonb DEFAULT NULL,
	std_datetime_utc_created TIMESTAMPTZ NOT NULL,
	std_creator_user_id BIGINT NOT NULL,
	std_datetime_utc_last_modified TIMESTAMPTZ NOT NULL,
	std_last_modifier_user_id BIGINT NOT NULL,
	std_is_deleted BOOLEAN NOT NULL DEFAULT 'n',
	std_deleter_user_id BIGINT DEFAULT NULL,
	std_datetime_utc_deleted TIMESTAMPTZ DEFAULT NULL,
	std_culture VARCHAR(5) NOT NULL DEFAULT 'en',
	std_checksum VARCHAR(40) DEFAULT NULL,
	std_seq_num SMALLINT  NOT NULL Default 0,
	std_translated_from_id UUID DEFAULT NULL,
	std_is_active BOOLEAN NOT NULL DEFAULT 'y',
	std_is_published BOOLEAN DEFAULT 'n',
	std_publisher_id BIGINT DEFAULT NULL,
	std_datetime_utc_published TIMESTAMPTZ DEFAULT NULL,
	std_version TEXT DEFAULT '1.0',
	un_global_code NUMERIC NOT NULL, -- Numeric but zero padded
	un_global_name VARCHAR(255) NOT NULL,
	un_region_code NUMERIC NOT NULL, -- Numeric but zero padded
	un_region_name VARCHAR(255) NOT NULL,
	un_subregion_code NUMERIC NOT NULL, -- Numeric but zero padded
	un_subregion_name VARCHAR(255) NOT NULL,
	un_intermediateregion_code NUMERIC, -- Numeric but zero padded
	un_intermediateregion_name VARCHAR(255),
	un_code_m49 NUMERIC NOT NULL, -- Numeric but zero padded
	un_is_ldc BOOLEAN, -- True if listed on UN Least Developed Countries (LDC)
	un_is_lldc BOOLEAN, -- True if listed on Land Locked Developing Countries (LLDC)
	un_is_sids BOOLEAN, -- True if listed on Small Island Developing States (SIDS)
	iso_code_alpha2 CHAR(2) NOT NULL, -- Alpha-2
	iso_code_alpha3 CHAR(3) NOT NULL, -- Alpha-3
	CONSTRAINT pk_geo_country PRIMARY KEY ( std_id ),
	CONSTRAINT fk_geo_country_std_creator_user_id FOREIGN KEY ( std_creator_user_id ) REFERENCES osc_physrisk_backend.user(std_id),
	CONSTRAINT fk_geo_country_std_last_modifier_user_id FOREIGN KEY ( std_last_modifier_user_id ) REFERENCES osc_physrisk_backend.user(std_id),
	CONSTRAINT fk_geo_country_std_deleter_user_id FOREIGN KEY ( std_deleter_user_id ) REFERENCES osc_physrisk_backend.user(std_id)
 ); 

 COMMENT ON TABLE osc_physrisk_backend.geo_country IS 'Contains a list of country ISO codes as described in ISO 3166 standard.';

-- SCHEMA osc_physrisk_scenarios
CREATE TABLE osc_physrisk_scenarios.scenario ( 
	std_id UUID  DEFAULT gen_random_UUID ()  NOT NULL,
	std_name VARCHAR(255) NOT NULL,
	std_name_display VARCHAR(255),
	std_slug VARCHAR(255),
	std_abbreviation VARCHAR(12),
	std_description_full  TEXT NOT NULL,
	std_description_short  VARCHAR(255) NOT NULL,
    std_tags jsonb DEFAULT NULL,
	std_datetime_utc_created TIMESTAMPTZ NOT NULL,
	std_creator_user_id BIGINT NOT NULL,
	std_datetime_utc_last_modified TIMESTAMPTZ NOT NULL,
	std_last_modifier_user_id BIGINT NOT NULL,
	std_is_deleted BOOLEAN NOT NULL DEFAULT 'n',
	std_deleter_user_id BIGINT DEFAULT NULL,
	std_datetime_utc_deleted TIMESTAMPTZ DEFAULT NULL,
	std_culture VARCHAR(5) NOT NULL DEFAULT 'en',
	std_checksum VARCHAR(40) DEFAULT NULL,
	std_seq_num SMALLINT  NOT NULL Default 0,
	std_translated_from_id UUID DEFAULT NULL,
	std_is_active BOOLEAN NOT NULL DEFAULT 'y',
	std_is_published BOOLEAN DEFAULT 'n',
	std_publisher_id BIGINT DEFAULT NULL,
	std_datetime_utc_published TIMESTAMPTZ DEFAULT NULL,
	std_version TEXT DEFAULT '1.0',
	std_dataset_id UUID,
	CONSTRAINT pk_scenario PRIMARY KEY ( std_id ),
	CONSTRAINT fk_scenario_std_dataset_id FOREIGN KEY ( std_dataset_id ) REFERENCES osc_physrisk_backend.dataset(std_id),
	CONSTRAINT fk_scenario_std_creator_user_id FOREIGN KEY ( std_creator_user_id ) REFERENCES osc_physrisk_backend.user(std_id),
	CONSTRAINT fk_scenario_std_last_modifier_user_id FOREIGN KEY ( std_last_modifier_user_id ) REFERENCES osc_physrisk_backend.user(std_id),
	CONSTRAINT fk_scenario_std_deleter_user_id FOREIGN KEY ( std_deleter_user_id ) REFERENCES osc_physrisk_backend.user(std_id)
 ); 

 COMMENT ON TABLE osc_physrisk_scenarios.scenario IS 'Contains a list of the United Nations Intergovernmental Panel on Climate Change (IPCC)-defined climate scenarios (SSPs and RCPs).';

CREATE TABLE osc_physrisk_scenarios.hazard ( 
	std_id	UUID  DEFAULT gen_random_UUID ()  NOT NULL,
	std_name VARCHAR(255) NOT NULL,
	std_name_display VARCHAR(255),
	std_slug VARCHAR(255),
	std_abbreviation VARCHAR(12),
	std_description_full  TEXT NOT NULL,
	std_description_short  VARCHAR(255) NOT NULL,
    std_tags jsonb DEFAULT NULL,
	std_datetime_utc_created TIMESTAMPTZ NOT NULL,
	std_creator_user_id BIGINT NOT NULL,
	std_datetime_utc_last_modified TIMESTAMPTZ NOT NULL,
	std_last_modifier_user_id BIGINT NOT NULL,
	std_is_deleted BOOLEAN NOT NULL DEFAULT 'n',
	std_deleter_user_id BIGINT DEFAULT NULL,
	std_datetime_utc_deleted TIMESTAMPTZ DEFAULT NULL,
	std_culture VARCHAR(5) NOT NULL DEFAULT 'en',
	std_checksum VARCHAR(40) DEFAULT NULL,
	std_seq_num SMALLINT  NOT NULL Default 0,
	std_translated_from_id UUID DEFAULT NULL,
	std_is_active BOOLEAN NOT NULL DEFAULT 'y',
	std_is_published BOOLEAN DEFAULT 'n',
	std_publisher_id BIGINT DEFAULT NULL,
	std_datetime_utc_published TIMESTAMPTZ DEFAULT NULL,
	std_version TEXT DEFAULT '1.0',
	std_dataset_id UUID,
	-- is_chronic BOOLEAN NOT NULL,
	-- is_acute BOOLEAN NOT NULL,
	oed_peril_code integer,
	oed_input_abbreviation      varchar(5) ,
	oed_grouped_peril_code boolean,
	CONSTRAINT pk_hazard PRIMARY KEY ( std_id ),	
	CONSTRAINT fk_hazard_std_dataset_id FOREIGN KEY ( std_dataset_id ) REFERENCES osc_physrisk_backend.dataset(std_id),
	CONSTRAINT fk_hazard_std_creator_user_id FOREIGN KEY ( std_creator_user_id ) REFERENCES osc_physrisk_backend.user(std_id),
	CONSTRAINT fk_hazard_std_last_modifier_user_id FOREIGN KEY ( std_last_modifier_user_id ) REFERENCES osc_physrisk_backend.user(std_id),
	CONSTRAINT fk_hazard_std_deleter_user_id FOREIGN KEY ( std_deleter_user_id ) REFERENCES osc_physrisk_backend.user(std_id)
 );
COMMENT ON TABLE osc_physrisk_scenarios.hazard IS 'Contains a list of the physical hazards supported by OS-Climate.';

CREATE TABLE osc_physrisk_scenarios.hazard_indicator ( 
	std_id	UUID  DEFAULT gen_random_UUID () NOT NULL,
	std_name VARCHAR(255) NOT NULL,
	std_name_display VARCHAR(255),
	std_slug VARCHAR(255),
	std_abbreviation VARCHAR(12),
	std_description_full  TEXT NOT NULL,
	std_description_short  VARCHAR(255) NOT NULL,
    std_tags jsonb DEFAULT NULL,
	std_datetime_utc_created TIMESTAMPTZ NOT NULL,
	std_creator_user_id BIGINT NOT NULL,
	std_datetime_utc_last_modified TIMESTAMPTZ NOT NULL,
	std_last_modifier_user_id BIGINT NOT NULL,
	std_is_deleted BOOLEAN NOT NULL DEFAULT 'n',
	std_deleter_user_id BIGINT DEFAULT NULL,
	std_datetime_utc_deleted TIMESTAMPTZ DEFAULT NULL,
	std_culture VARCHAR(5) NOT NULL DEFAULT 'en',
	std_checksum VARCHAR(40) DEFAULT NULL,
	std_seq_num SMALLINT  NOT NULL Default 0,
	std_translated_from_id UUID DEFAULT NULL,
	std_is_active BOOLEAN NOT NULL DEFAULT 'y',
	std_is_published BOOLEAN DEFAULT 'n',
	std_publisher_id BIGINT DEFAULT NULL,
	std_datetime_utc_published TIMESTAMPTZ DEFAULT NULL,
	std_version TEXT DEFAULT '1.0',
	std_dataset_id UUID,
	hazard_id	UUID  NOT NULL,
	CONSTRAINT pk_hazard_indicator PRIMARY KEY ( std_id ),
	CONSTRAINT fk_hazard_indicator_std_dataset_id FOREIGN KEY ( std_dataset_id ) REFERENCES osc_physrisk_backend.dataset(std_id),
	CONSTRAINT fk_hazard_indicator_hazard_id FOREIGN KEY ( hazard_id ) REFERENCES osc_physrisk_scenarios.hazard(std_id),
	CONSTRAINT fk_hazard_indicator_std_creator_user_id FOREIGN KEY ( std_creator_user_id ) REFERENCES osc_physrisk_backend.user(std_id),
	CONSTRAINT fk_hazard_indicator_std_last_modifier_user_id FOREIGN KEY ( std_last_modifier_user_id ) REFERENCES osc_physrisk_backend.user(std_id),
	CONSTRAINT fk_hazard_indicator_std_deleter_user_id FOREIGN KEY ( std_deleter_user_id ) REFERENCES osc_physrisk_backend.user(std_id)	
 );
COMMENT ON TABLE osc_physrisk_scenarios.hazard_indicator IS 'Contains a list of the physical hazard indicators that are supported by OS-Climate. An indicator must always relate to one particular hazard.';


-- SCHEMA osc_physrisk_assets
CREATE TABLE osc_physrisk_assets.asset_class ( 
	std_id UUID  DEFAULT gen_random_UUID () NOT NULL,
	std_name VARCHAR(255) NOT NULL,
	std_name_display VARCHAR(255),
	std_slug VARCHAR(255),
	std_abbreviation VARCHAR(12),
	std_description_full  TEXT NOT NULL,
	std_description_short  VARCHAR(255) NOT NULL,
    std_tags jsonb DEFAULT NULL,
	std_datetime_utc_created TIMESTAMPTZ NOT NULL,
	std_creator_user_id BIGINT NOT NULL,
	std_datetime_utc_last_modified TIMESTAMPTZ NOT NULL,
	std_last_modifier_user_id BIGINT NOT NULL,
	std_is_deleted BOOLEAN NOT NULL DEFAULT 'n',
	std_deleter_user_id BIGINT DEFAULT NULL,
	std_datetime_utc_deleted TIMESTAMPTZ DEFAULT NULL,
	std_culture VARCHAR(5) NOT NULL DEFAULT 'en',
	std_checksum VARCHAR(40) DEFAULT NULL,
	std_seq_num SMALLINT  NOT NULL Default 0,
	std_translated_from_id UUID DEFAULT NULL,
	std_is_active BOOLEAN NOT NULL DEFAULT 'y',
	std_is_published BOOLEAN DEFAULT 'n',
	std_publisher_id BIGINT DEFAULT NULL,
	std_datetime_utc_published TIMESTAMPTZ DEFAULT NULL,
	std_version TEXT DEFAULT '1.0',
	std_dataset_id UUID,
	CONSTRAINT pk_asset_class PRIMARY KEY (std_id ),
	CONSTRAINT fk_asset_class_std_dataset_id FOREIGN KEY ( std_dataset_id ) REFERENCES osc_physrisk_backend.dataset(std_id),
	CONSTRAINT fk_asset_class_std_creator_user_id FOREIGN KEY ( std_creator_user_id ) REFERENCES osc_physrisk_backend.user(std_id),
	CONSTRAINT fk_asset_class_std_last_modifier_user_id FOREIGN KEY ( std_last_modifier_user_id ) REFERENCES osc_physrisk_backend.user(std_id),
	CONSTRAINT fk_asset_class_std_deleter_user_id FOREIGN KEY ( std_deleter_user_id ) REFERENCES osc_physrisk_backend.user(std_id)	
 );
COMMENT ON TABLE osc_physrisk_assets.asset_class IS 'A physical financial asset (infrastructure, utilities, property, buildings) category, that may impact the modeling (ex real estate vs power generating utilities).';


CREATE TABLE osc_physrisk_assets.asset_type ( 
	std_id UUID  DEFAULT gen_random_UUID () NOT NULL,
	std_name VARCHAR(255) NOT NULL,
	std_name_display VARCHAR(255),
	std_slug VARCHAR(255),
	std_abbreviation VARCHAR(12),
	std_description_full  TEXT NOT NULL,
	std_description_short  VARCHAR(255) NOT NULL,
    std_tags jsonb DEFAULT NULL,
	std_datetime_utc_created TIMESTAMPTZ NOT NULL,
	std_creator_user_id BIGINT NOT NULL,
	std_datetime_utc_last_modified TIMESTAMPTZ NOT NULL,
	std_last_modifier_user_id BIGINT NOT NULL,
	std_is_deleted BOOLEAN NOT NULL DEFAULT 'n',
	std_deleter_user_id BIGINT DEFAULT NULL,
	std_datetime_utc_deleted TIMESTAMPTZ DEFAULT NULL,
	std_culture VARCHAR(5) NOT NULL DEFAULT 'en',
	std_checksum VARCHAR(40) DEFAULT NULL,
	std_seq_num SMALLINT  NOT NULL Default 0,
	std_translated_from_id UUID DEFAULT NULL,
	std_is_active BOOLEAN NOT NULL DEFAULT 'y',
	std_is_published BOOLEAN DEFAULT 'n',
	std_publisher_id BIGINT DEFAULT NULL,
	std_datetime_utc_published TIMESTAMPTZ DEFAULT NULL,
	std_version TEXT DEFAULT '1.0',
	std_dataset_id UUID,
	asset_class_id UUID,
	CONSTRAINT pk_asset_type PRIMARY KEY (std_id ),
	CONSTRAINT fk_asset_type_std_dataset_id FOREIGN KEY ( std_dataset_id ) REFERENCES osc_physrisk_backend.dataset(std_id),
	CONSTRAINT fk_asset_type_std_creator_user_id FOREIGN KEY ( std_creator_user_id ) REFERENCES osc_physrisk_backend.user(std_id),
	CONSTRAINT fk_asset_type_std_last_modifier_user_id FOREIGN KEY ( std_last_modifier_user_id ) REFERENCES osc_physrisk_backend.user(std_id),
	CONSTRAINT fk_asset_type_std_deleter_user_id FOREIGN KEY ( std_deleter_user_id ) REFERENCES osc_physrisk_backend.user(std_id),	
    CONSTRAINT fk_asset_type_asset_class_id FOREIGN KEY ( asset_class_id ) REFERENCES osc_physrisk_assets.asset_class(std_id)
 );
COMMENT ON TABLE osc_physrisk_assets.asset_type IS 'A physical financial asset (infrastructure, utilities, property, buildings) specific classification within an overarching asset class, that may impact the modeling (ex commercial real estate vs residential real, both of which types belong to the same real estate class).';


CREATE TABLE osc_physrisk_assets.portfolio ( 
	std_id UUID  DEFAULT gen_random_UUID () NOT NULL,
	std_name VARCHAR(255) NOT NULL,
	std_name_display VARCHAR(255),
	std_slug VARCHAR(255),
	std_abbreviation VARCHAR(12),
	std_description_full  TEXT NOT NULL,
	std_description_short  VARCHAR(255) NOT NULL,
    std_tags jsonb DEFAULT NULL,
	std_datetime_utc_created TIMESTAMPTZ NOT NULL,
	std_creator_user_id BIGINT NOT NULL,
	std_datetime_utc_last_modified TIMESTAMPTZ NOT NULL,
	std_last_modifier_user_id BIGINT NOT NULL,
	std_is_deleted BOOLEAN NOT NULL DEFAULT 'n',
	std_deleter_user_id BIGINT DEFAULT NULL,
	std_datetime_utc_deleted TIMESTAMPTZ DEFAULT NULL,
	std_tenant_id BIGINT NOT NULL DEFAULT 1,
	std_culture VARCHAR(5) NOT NULL DEFAULT 'en',
	std_checksum VARCHAR(40) DEFAULT NULL,
	std_seq_num SMALLINT  NOT NULL Default 0,
	std_translated_from_id UUID DEFAULT NULL,
	std_is_active BOOLEAN NOT NULL DEFAULT 'y',
	std_is_published BOOLEAN DEFAULT 'n',
	std_publisher_id BIGINT DEFAULT NULL,
	std_datetime_utc_published TIMESTAMPTZ DEFAULT NULL,
	std_version TEXT DEFAULT '1.0',
	std_dataset_id UUID,
    value_total numeric,
    value_currency_alphabetic_code char(3),
	CONSTRAINT pk_portfolio PRIMARY KEY (std_id ),
	CONSTRAINT fk_portfolio_std_dataset_id FOREIGN KEY ( std_dataset_id ) REFERENCES osc_physrisk_backend.dataset(std_id),
	CONSTRAINT fk_portfolio_std_creator_user_id FOREIGN KEY ( std_creator_user_id ) REFERENCES osc_physrisk_backend.user(std_id),
	CONSTRAINT fk_portfolio_std_last_modifier_user_id FOREIGN KEY ( std_last_modifier_user_id ) REFERENCES osc_physrisk_backend.user(std_id),
	CONSTRAINT fk_portfolio_std_deleter_user_id FOREIGN KEY ( std_deleter_user_id ) REFERENCES osc_physrisk_backend.user(std_id),
	CONSTRAINT fk_portfolio_std_tenant_id FOREIGN KEY ( std_tenant_id ) REFERENCES osc_physrisk_backend.tenant(std_id)
 );
COMMENT ON TABLE osc_physrisk_assets.portfolio IS 'A financial portfolio that contains 1 or more physical financial assets (infrastructure, utilities, property, buildings).';

CREATE TABLE osc_physrisk_assets.generic_asset ( 
	std_id UUID  DEFAULT gen_random_UUID () NOT NULL,
	std_name VARCHAR(255) NOT NULL,
	std_name_display VARCHAR(255),
	std_slug VARCHAR(255),
	std_abbreviation VARCHAR(12),
	std_description_full  TEXT NOT NULL,
	std_description_short  VARCHAR(255) NOT NULL,
    std_tags jsonb DEFAULT NULL,
	std_datetime_utc_created TIMESTAMPTZ NOT NULL,
	std_creator_user_id BIGINT NOT NULL,
	std_datetime_utc_last_modified TIMESTAMPTZ NOT NULL,
	std_last_modifier_user_id BIGINT NOT NULL,
	std_is_deleted BOOLEAN NOT NULL DEFAULT 'n',
	std_deleter_user_id BIGINT DEFAULT NULL,
	std_datetime_utc_deleted TIMESTAMPTZ DEFAULT NULL,
	std_tenant_id BIGINT NOT NULL DEFAULT 1,
	std_culture VARCHAR(5) NOT NULL DEFAULT 'en',
	std_checksum VARCHAR(40) DEFAULT NULL,
	std_seq_num SMALLINT  NOT NULL Default 0,
	std_translated_from_id UUID DEFAULT NULL,
	std_is_active BOOLEAN NOT NULL DEFAULT 'y',
	std_is_published BOOLEAN DEFAULT 'n',
	std_publisher_id BIGINT DEFAULT NULL,
	std_datetime_utc_published TIMESTAMPTZ DEFAULT NULL,
	std_version TEXT DEFAULT '1.0',
	std_dataset_id UUID,
	std_geo_country_id UUID,
    std_geo_location_name      	VARCHAR(255),
    std_geo_location_address      	text,
    std_geo_location_coordinates      	GEOGRAPHY  NOT NULL  ,
	std_geo_altitude numeric DEFAULT NULL, 
	std_geo_altitude_confidence numeric DEFAULT NULL,
	std_geo_overture_features			jsonb[], -- This asset can be described in 0 or more Overture Map schemas to cover its land use, infrastructure, building extents, etc
	std_geo_h3_index H3INDEX NOT NULL,
    std_geo_h3_resolution INT2 NOT NULL,
	asset_type_id UUID,
    portfolio_id UUID NOT NULL,
	owner_bloomberg_id	varchar(12) DEFAULT NULL,
	owner_lei_id varchar(20) DEFAULT NULL,
	value_total numeric,
    value_dynamics jsonb, -- Asset Value Dynamics over time, example real estate appreciation
	value_currency_alphabetic_code char(3),
	CONSTRAINT pk_generic_asset PRIMARY KEY ( std_id ),
	CONSTRAINT fk_generic_asset_std_dataset_id FOREIGN KEY ( std_dataset_id ) REFERENCES osc_physrisk_backend.dataset(std_id),
	CONSTRAINT fk_generic_asset_portfolio_id FOREIGN KEY ( portfolio_id ) REFERENCES osc_physrisk_assets.portfolio(std_id),
	CONSTRAINT fk_generic_asset_geo_country_id FOREIGN KEY ( std_geo_country_id ) REFERENCES osc_physrisk_backend.geo_country(std_id),
	CONSTRAINT ck_generic_asset_geo_h3_resolution CHECK (std_geo_h3_resolution >= 0 AND std_geo_h3_resolution <= 15),
	CONSTRAINT fk_generic_asset_std_creator_user_id FOREIGN KEY ( std_creator_user_id ) REFERENCES osc_physrisk_backend.user(std_id),
	CONSTRAINT fk_generic_asset_std_last_modifier_user_id FOREIGN KEY ( std_last_modifier_user_id ) REFERENCES osc_physrisk_backend.user(std_id),
	CONSTRAINT fk_generic_asset_std_deleter_user_id FOREIGN KEY ( std_deleter_user_id ) REFERENCES osc_physrisk_backend.user(std_id),
	CONSTRAINT fk_generic_asset_std_tenant_id FOREIGN KEY ( std_tenant_id ) REFERENCES osc_physrisk_backend.tenant(std_id),
    CONSTRAINT fk_generic_asset_asset_type_id FOREIGN KEY ( asset_type_id ) REFERENCES osc_physrisk_assets.asset_type(std_id)
 );
COMMENT ON TABLE osc_physrisk_assets.generic_asset IS 'A physical financial asset (infrastructure, utilities, property, buildings) that is contained within a financial portfolio and not further classified by its Asset Type (otherwise use a more specific, relevant table). The lowest unit of assessment for physical risk & resilience (currently).';

CREATE INDEX "ix_osc_physrisk_assets_asset_portfolio_id" ON osc_physrisk_assets.generic_asset USING btree (portfolio_id);

CREATE TABLE osc_physrisk_assets.asset_realestate ( 
	value_cashflows numeric ARRAY,-- Sequence of the associated cash flows (for cash flow generating assets only).
    value_loan text ARRAY, -- Sequence of Loans by date, representing the mortgage lines
	value_ltv text ARRAY, -- Sequence of Loan-to-Value results by date, representing the ratio of the first mortgage line as a percentage of the total appraised value of real property.
	CONSTRAINT pk_asset_realestate PRIMARY KEY ( std_id ),
	CONSTRAINT fk_asset_realestate_std_dataset_id FOREIGN KEY ( std_dataset_id ) REFERENCES osc_physrisk_backend.dataset(std_id),
	CONSTRAINT fk_asset_realestate_portfolio_id FOREIGN KEY ( portfolio_id ) REFERENCES osc_physrisk_assets.portfolio(std_id),
    CONSTRAINT ck_asset_realestate_h3_resolution CHECK (std_geo_h3_resolution >= 0 AND std_geo_h3_resolution <= 15),
	CONSTRAINT fk_asset_realestate_std_creator_user_id FOREIGN KEY ( std_creator_user_id ) REFERENCES osc_physrisk_backend.user(std_id),
	CONSTRAINT fk_asset_realestate_std_last_modifier_user_id FOREIGN KEY ( std_last_modifier_user_id ) REFERENCES osc_physrisk_backend.user(std_id),
	CONSTRAINT fk_asset_realestate_std_deleter_user_id FOREIGN KEY ( std_deleter_user_id ) REFERENCES osc_physrisk_backend.user(std_id),
	CONSTRAINT fk_asset_realestate_std_tenant_id FOREIGN KEY ( std_tenant_id ) REFERENCES osc_physrisk_backend.tenant(std_id),	
    CONSTRAINT fk_asset_realestate_asset_type_id FOREIGN KEY ( asset_type_id ) REFERENCES osc_physrisk_assets.asset_type(std_id)
 ) INHERITS (osc_physrisk_assets.generic_asset);
COMMENT ON TABLE osc_physrisk_assets.asset_realestate IS 'A physical financial asset (infrastructure, utilities, property, buildings) that is of the Real Estate asset type and contained within a financial portfolio. The lowest unit of assessment for physical risk & resilience (currently).';

CREATE TABLE osc_physrisk_assets.asset_powergeneratingutility ( 
	production numeric NOT NULL, -- Real annual production of a power plant in Wh.
	capacity numeric NOT NULL, -- Capacity of the power plant in W.
	availability_rate numeric NOT NULL, -- Availability factor of production.
	CONSTRAINT pk_asset_powergeneratingutility PRIMARY KEY ( std_id ),
	CONSTRAINT fk_asset_powergeneratingutility_std_dataset_id FOREIGN KEY ( std_dataset_id ) REFERENCES osc_physrisk_backend.dataset(std_id),
	CONSTRAINT fk_asset_powergeneratingutility_portfolio_id FOREIGN KEY ( portfolio_id ) REFERENCES osc_physrisk_assets.portfolio(std_id),
    CONSTRAINT ck_asset_powergeneratingutility_h3_resolution CHECK (std_geo_h3_resolution >= 0 AND std_geo_h3_resolution <= 15),
	CONSTRAINT fk_asset_powergeneratingutility_std_creator_user_id FOREIGN KEY ( std_creator_user_id ) REFERENCES osc_physrisk_backend.user(std_id),
	CONSTRAINT fk_asset_powergeneratingutility_std_last_modifier_user_id FOREIGN KEY ( std_last_modifier_user_id ) REFERENCES osc_physrisk_backend.user(std_id),
	CONSTRAINT fk_asset_powergeneratingutilitystd_deleter_user_id FOREIGN KEY ( std_deleter_user_id ) REFERENCES osc_physrisk_backend.user(std_id),
	CONSTRAINT fk_asset_powergeneratingutility_std_tenant_id FOREIGN KEY ( std_tenant_id ) REFERENCES osc_physrisk_backend.tenant(std_id),	
    CONSTRAINT fk_asset_powergeneratingutility_asset_type_id FOREIGN KEY ( asset_type_id ) REFERENCES osc_physrisk_assets.asset_type(std_id)
 ) INHERITS (osc_physrisk_assets.generic_asset);
COMMENT ON TABLE osc_physrisk_assets.asset_powergeneratingutility IS 'A physical financial asset (infrastructure, utilities, property, buildings) that is of the Power Generating Utility asset type and contained within a financial portfolio. The lowest unit of assessment for physical risk & resilience (currently).';

-- SCHEMA osc_physrisk_vulnerability_analysis
CREATE TABLE osc_physrisk_vulnerability_analysis.exposure_function ( 
	std_id	UUID  DEFAULT gen_random_UUID () NOT NULL,
	std_name VARCHAR(255) NOT NULL,
	std_name_display VARCHAR(255),
	std_slug VARCHAR(255),
	std_abbreviation VARCHAR(12),
	std_description_full  TEXT NOT NULL,
	std_description_short  VARCHAR(255) NOT NULL,
    std_tags jsonb DEFAULT NULL,
	std_datetime_utc_created TIMESTAMPTZ NOT NULL,
	std_creator_user_id BIGINT NOT NULL,
	std_datetime_utc_last_modified TIMESTAMPTZ NOT NULL,
	std_last_modifier_user_id BIGINT NOT NULL,
	std_is_deleted BOOLEAN NOT NULL DEFAULT 'n',
	std_deleter_user_id BIGINT DEFAULT NULL,
	std_datetime_utc_deleted TIMESTAMPTZ DEFAULT NULL,
	std_tenant_id BIGINT NOT NULL DEFAULT 1,
	std_culture VARCHAR(5) NOT NULL DEFAULT 'en',
	std_checksum VARCHAR(40) DEFAULT NULL,
	std_seq_num SMALLINT  NOT NULL Default 0,
	std_translated_from_id UUID DEFAULT NULL,
	std_is_active BOOLEAN NOT NULL DEFAULT 'y',
	std_is_published BOOLEAN DEFAULT 'n',
	std_publisher_id BIGINT DEFAULT NULL,
	std_datetime_utc_published TIMESTAMPTZ DEFAULT NULL,
	std_version TEXT DEFAULT '1.0',
	std_dataset_id UUID,
	CONSTRAINT pk_exposure_function PRIMARY KEY ( std_id ),
	CONSTRAINT fk_exposure_function_std_dataset_id FOREIGN KEY ( std_dataset_id ) REFERENCES osc_physrisk_backend.dataset(std_id),
	CONSTRAINT fk_exposure_function_std_creator_user_id FOREIGN KEY ( std_creator_user_id ) REFERENCES osc_physrisk_backend.user(std_id),
	CONSTRAINT fk_exposure_function_std_last_modifier_user_id FOREIGN KEY ( std_last_modifier_user_id ) REFERENCES osc_physrisk_backend.user(std_id),
	CONSTRAINT fk_exposure_function_std_deleter_user_id FOREIGN KEY ( std_deleter_user_id ) REFERENCES osc_physrisk_backend.user(std_id),
	CONSTRAINT fk_exposure_function_std_tenant_id FOREIGN KEY ( std_tenant_id ) REFERENCES osc_physrisk_backend.tenant(std_id)
 );
 COMMENT ON TABLE osc_physrisk_vulnerability_analysis.exposure_function IS 'The model used to determine whether a particular asset is exposed to a particular hazard indicator.';

CREATE TABLE osc_physrisk_vulnerability_analysis.vulnerability_function ( 
	std_id	UUID  DEFAULT gen_random_UUID () NOT NULL,
	std_name VARCHAR(255) NOT NULL,
	std_name_display VARCHAR(255),
	std_slug VARCHAR(255),
	std_abbreviation VARCHAR(12),
	std_description_full  TEXT NOT NULL,
	std_description_short  VARCHAR(255) NOT NULL,
    std_tags jsonb DEFAULT NULL,
	std_datetime_utc_created TIMESTAMPTZ NOT NULL,
	std_creator_user_id BIGINT NOT NULL,
	std_datetime_utc_last_modified TIMESTAMPTZ NOT NULL,
	std_last_modifier_user_id BIGINT NOT NULL,
	std_is_active BOOLEAN NOT NULL DEFAULT 'y',
	std_is_deleted BOOLEAN NOT NULL DEFAULT 'n',
	std_deleter_user_id BIGINT DEFAULT NULL,
	std_datetime_utc_deleted TIMESTAMPTZ DEFAULT NULL,
	std_tenant_id BIGINT NOT NULL DEFAULT 1,
	std_culture VARCHAR(5) NOT NULL DEFAULT 'en',
	std_checksum VARCHAR(40) DEFAULT NULL,
	std_seq_num SMALLINT  NOT NULL Default 0,
	std_translated_from_id UUID DEFAULT NULL,
	std_is_published BOOLEAN DEFAULT 'n',
	std_publisher_id BIGINT DEFAULT NULL,
	std_datetime_utc_published TIMESTAMPTZ DEFAULT NULL,
	std_version TEXT DEFAULT '1.0',
	std_dataset_id UUID,
	CONSTRAINT pk_vulnerability_function PRIMARY KEY ( std_id ),
	CONSTRAINT fk_vulnerability_function_std_dataset_id FOREIGN KEY ( std_dataset_id ) REFERENCES osc_physrisk_backend.dataset(std_id),
	CONSTRAINT fk_vulnerability_std_creator_user_id FOREIGN KEY ( std_creator_user_id ) REFERENCES osc_physrisk_backend.user(std_id),
	CONSTRAINT fk_vulnerability_std_last_modifier_user_id FOREIGN KEY ( std_last_modifier_user_id ) REFERENCES osc_physrisk_backend.user(std_id),
	CONSTRAINT fk_vulnerability_std_deleter_user_id FOREIGN KEY ( std_deleter_user_id ) REFERENCES osc_physrisk_backend.user(std_id),
	CONSTRAINT fk_vulnerability_std_tenant_id FOREIGN KEY ( std_tenant_id ) REFERENCES osc_physrisk_backend.tenant(std_id)
 );
COMMENT ON TABLE osc_physrisk_vulnerability_analysis.vulnerability_function IS 'The model used to determine the degree by which a particular asset is vulnerable to a particular hazard indicator. If an asset is vulnerable to a peril, it must necessarily be exposed to it (see exposure_function).';

CREATE TABLE osc_physrisk_vulnerability_analysis.vulnerability_type ( 
	std_id INTEGER NOT NULL,
	std_name VARCHAR(255) NOT NULL,
	std_name_display VARCHAR(255),
	std_slug VARCHAR(255),
	std_abbreviation VARCHAR(12),
	std_description_full  TEXT NOT NULL,
	std_description_short  VARCHAR(255) NOT NULL,
    std_tags jsonb DEFAULT NULL,
	std_datetime_utc_created TIMESTAMPTZ NOT NULL,
	std_creator_user_id BIGINT NOT NULL,
	std_datetime_utc_last_modified TIMESTAMPTZ NOT NULL,
	std_last_modifier_user_id BIGINT NOT NULL,
	std_is_deleted BOOLEAN NOT NULL DEFAULT 'n',
	std_deleter_user_id BIGINT DEFAULT NULL,
	std_datetime_utc_deleted TIMESTAMPTZ DEFAULT NULL,
	std_culture VARCHAR(5) NOT NULL DEFAULT 'en',
	std_checksum VARCHAR(40) DEFAULT NULL,
	std_seq_num SMALLINT  NOT NULL Default 0,
	std_translated_from_id UUID DEFAULT NULL,
	std_is_active BOOLEAN NOT NULL DEFAULT 'y',
	std_is_published BOOLEAN DEFAULT 'n',
	std_publisher_id BIGINT DEFAULT NULL,
	std_datetime_utc_published TIMESTAMPTZ DEFAULT NULL,
	std_version TEXT DEFAULT '1.0',
	std_dataset_id UUID,
    accounting_category VARCHAR(255),
	CONSTRAINT pk_vulnerability_type PRIMARY KEY ( std_id ),
	CONSTRAINT fk_vulnerability_type_std_dataset_id FOREIGN KEY ( std_dataset_id ) REFERENCES osc_physrisk_backend.dataset(std_id),
	CONSTRAINT fk_vulnerability_type_std_creator_user_id FOREIGN KEY ( std_creator_user_id ) REFERENCES osc_physrisk_backend.user(std_id),
	CONSTRAINT fk_vulnerability_type_std_last_modifier_user_id FOREIGN KEY ( std_last_modifier_user_id ) REFERENCES osc_physrisk_backend.user(std_id),
	CONSTRAINT fk_vulnerability_type_std_deleter_user_id FOREIGN KEY ( std_deleter_user_id ) REFERENCES osc_physrisk_backend.user(std_id)
 ); 
COMMENT ON TABLE osc_physrisk_vulnerability_analysis.vulnerability_type IS 'A lookup table to classify and constrain types of damage/disruption that could occur to an asset due to its vulnerability to a hazard.';


CREATE TABLE osc_physrisk_vulnerability_analysis.hazard_data_request ( 
	std_id	UUID  DEFAULT gen_random_UUID ()  NOT NULL,
	std_name VARCHAR(255) NOT NULL,
	std_name_display VARCHAR(255),
	std_slug VARCHAR(255),
	std_abbreviation VARCHAR(12),
	std_description_full  TEXT NOT NULL,
	std_description_short  VARCHAR(255) NOT NULL,
    std_tags jsonb DEFAULT NULL,
	std_datetime_utc_created TIMESTAMPTZ NOT NULL,
	std_creator_user_id BIGINT NOT NULL,
	std_datetime_utc_last_modified TIMESTAMPTZ NOT NULL,
	std_last_modifier_user_id BIGINT NOT NULL,
	std_is_deleted BOOLEAN NOT NULL DEFAULT 'n',
	std_deleter_user_id BIGINT DEFAULT NULL,
	std_datetime_utc_deleted TIMESTAMPTZ DEFAULT NULL,
	std_culture VARCHAR(5) NOT NULL DEFAULT 'en',
	std_checksum VARCHAR(40) DEFAULT NULL,
	std_seq_num SMALLINT  NOT NULL Default 0,
	std_translated_from_id UUID DEFAULT NULL,
	std_is_active BOOLEAN NOT NULL DEFAULT 'y',
	std_is_published BOOLEAN DEFAULT 'n',
	std_publisher_id BIGINT DEFAULT NULL,
	std_datetime_utc_published TIMESTAMPTZ DEFAULT NULL,
	std_version TEXT DEFAULT '1.0',
	std_dataset_id UUID,
    std_geo_location_coordinates      	GEOGRAPHY  NOT NULL  ,
	scenario_id UUID NOT NULL,
    scenario_year smallint,
	hazard_id	UUID NOT NULL,
	hazard_indicator_id UUID NOT NULL,
	CONSTRAINT pk_hazard_data_request PRIMARY KEY ( std_id ),	
	CONSTRAINT fk_hazard_data_request_std_dataset_id FOREIGN KEY ( std_dataset_id ) REFERENCES osc_physrisk_backend.dataset(std_id),
	CONSTRAINT fk_hazard_data_request_std_creator_user_id FOREIGN KEY ( std_creator_user_id ) REFERENCES osc_physrisk_backend.user(std_id),
	CONSTRAINT fk_hazard_data_request_std_last_modifier_user_id FOREIGN KEY ( std_last_modifier_user_id ) REFERENCES osc_physrisk_backend.user(std_id),
	CONSTRAINT fk_hazard_data_request_std_deleter_user_id FOREIGN KEY ( std_deleter_user_id ) REFERENCES osc_physrisk_backend.user(std_id),
 	CONSTRAINT fk_hazard_data_request_scenario_id FOREIGN KEY ( scenario_id ) REFERENCES osc_physrisk_scenarios.scenario(std_id),
	CONSTRAINT fk_hazard_data_request_hazard_id FOREIGN KEY ( hazard_id ) REFERENCES osc_physrisk_scenarios.hazard(std_id),
 	CONSTRAINT fk_hazard_data_request_hazard_indicator_id FOREIGN KEY ( hazard_indicator_id ) REFERENCES osc_physrisk_scenarios.hazard_indicator(std_id)
	
 );
COMMENT ON TABLE osc_physrisk_vulnerability_analysis.hazard_data_request IS 'Contains a request to evaluate the physical hazard of a particular location.';


CREATE TABLE osc_physrisk_vulnerability_analysis.portfolio_vulnerability ( 
	std_id UUID  DEFAULT gen_random_UUID () NOT NULL,
	std_name VARCHAR(255) NOT NULL,
	std_name_display VARCHAR(255),
	std_slug VARCHAR(255),
	std_abbreviation VARCHAR(12),
	std_description_full  TEXT NOT NULL,
	std_description_short  VARCHAR(255) NOT NULL,
    std_tags jsonb DEFAULT NULL,
	std_datetime_utc_created TIMESTAMPTZ NOT NULL,
	std_creator_user_id BIGINT NOT NULL,
	std_datetime_utc_last_modified TIMESTAMPTZ NOT NULL,
	std_last_modifier_user_id BIGINT NOT NULL,
	std_is_deleted BOOLEAN NOT NULL DEFAULT 'n',
	std_deleter_user_id BIGINT DEFAULT NULL,
	std_datetime_utc_deleted TIMESTAMPTZ DEFAULT NULL,
	std_tenant_id BIGINT NOT NULL DEFAULT 1,
	std_culture VARCHAR(5) NOT NULL DEFAULT 'en',
	std_checksum VARCHAR(40) DEFAULT NULL,
	std_seq_num SMALLINT  NOT NULL Default 1,
	std_translated_from_id UUID DEFAULT NULL,
	std_is_active BOOLEAN NOT NULL DEFAULT 'y',
	std_is_published BOOLEAN DEFAULT 'n',
	std_publisher_id BIGINT DEFAULT NULL,
	std_datetime_utc_published TIMESTAMPTZ DEFAULT NULL,
	std_version TEXT DEFAULT '1.0',
	std_dataset_id UUID,
	portfolio_id            UUID  NOT NULL  ,
	scenario_id UUID NOT NULL,
    scenario_year smallint,
	CONSTRAINT pk_portfolio_vulnerability PRIMARY KEY ( std_id ),
	CONSTRAINT fk_portfolio_vulnerability_std_dataset_id FOREIGN KEY ( std_dataset_id ) REFERENCES osc_physrisk_backend.dataset(std_id),
	CONSTRAINT fk_portfolio_vulnerability_std_id FOREIGN KEY ( portfolio_id ) REFERENCES osc_physrisk_assets.portfolio(std_id),
	CONSTRAINT fk_portfolio_vulnerability_scenario_id FOREIGN KEY ( scenario_id ) REFERENCES osc_physrisk_scenarios.scenario(std_id),
	CONSTRAINT fk_portfolio_vulnerability_std_creator_user_id FOREIGN KEY ( std_creator_user_id ) REFERENCES osc_physrisk_backend.user(std_id),
	CONSTRAINT fk_portfolio_vulnerability_std_last_modifier_user_id FOREIGN KEY ( std_last_modifier_user_id ) REFERENCES osc_physrisk_backend.user(std_id),
	CONSTRAINT fk_portfolio_vulnerability_std_deleter_user_id FOREIGN KEY ( std_deleter_user_id ) REFERENCES osc_physrisk_backend.user(std_id)  ,
	CONSTRAINT fk_portfolio_vulnerability_std_tenant_id FOREIGN KEY ( std_tenant_id ) REFERENCES osc_physrisk_backend.tenant(std_id)
 );
COMMENT ON TABLE osc_physrisk_vulnerability_analysis.portfolio_vulnerability IS 'The result of a physical risk & resilience vulnerability analysis. The result is determined by the chosen scenario, year, and hazard, aggregating the results for all of the assets in a given portfolio. If multiple scenarios/years/hazards were chosen, there will be multiple other rows containing the combined set of results. For financial impact, see portfolio_financial_impact table.';

CREATE TABLE osc_physrisk_vulnerability_analysis.asset_vulnerability ( 
	std_id UUID  DEFAULT gen_random_UUID () NOT NULL,
	std_name VARCHAR(255) NOT NULL,
	std_name_display VARCHAR(255),
	std_slug VARCHAR(255),
	std_abbreviation VARCHAR(12),
	std_description_full  TEXT NOT NULL,
	std_description_short  VARCHAR(255) NOT NULL,
    std_tags jsonb DEFAULT NULL,
	std_datetime_utc_created TIMESTAMPTZ NOT NULL,
	std_creator_user_id BIGINT NOT NULL,
	std_datetime_utc_last_modified TIMESTAMPTZ NOT NULL,
	std_last_modifier_user_id BIGINT NOT NULL,
	std_is_deleted BOOLEAN NOT NULL DEFAULT 'n',
	std_deleter_user_id BIGINT DEFAULT NULL,
	std_datetime_utc_deleted TIMESTAMPTZ DEFAULT NULL,
	std_tenant_id BIGINT NOT NULL DEFAULT 1,
	std_culture VARCHAR(5) NOT NULL DEFAULT 'en',
	std_checksum VARCHAR(40) DEFAULT NULL,
	std_seq_num SMALLINT  NOT NULL Default 1,
	std_translated_from_id UUID DEFAULT NULL,
	std_is_active BOOLEAN NOT NULL DEFAULT 'y',
	std_is_published BOOLEAN DEFAULT 'n',
	std_publisher_id BIGINT DEFAULT NULL,
	std_datetime_utc_published TIMESTAMPTZ DEFAULT NULL,
	std_version TEXT DEFAULT '1.0',
	std_dataset_id UUID,
	std_geo_country_id UUID,
	std_geo_location_name      	VARCHAR(255),
    std_geo_location_address      	text ,
    std_geo_location_coordinates      	GEOGRAPHY  NOT NULL  ,
	std_geo_altitude numeric DEFAULT NULL, 
	std_geo_altitude_confidence numeric DEFAULT NULL,
	std_geo_overture_features			jsonb[], -- This location can be described in 0 or more Overture Map schemas to cover its land use, infrastructure, building extents, etc
	std_geo_h3_index H3INDEX NOT NULL,
    std_geo_h3_resolution INT2 NOT NULL,
	std_datetime_utc_start timestamptz,
	std_datetime_utc_end timestamptz,	
	asset_id            UUID  NOT NULL  ,
	hazard_indicator_id UUID NOT NULL,
    hazard_intensity numeric[], -- Assume this includes intensity units
	scenario_id UUID NOT NULL,
    scenario_year smallint,
    vulnerability_type_id integer NOT NULL,
	exposure_function_id text NOT NULL,
	exposure_data_raw jsonb NOT NULL, -- STORE RAW JSON, MAYBE OVERLAP WITH SOME COLUMNS BELOW?
	exposure_probability numeric,
	exposure_level numeric, -- 0.0 = not exposed at all 1.0 = fully exposed across whole area. In  between = some level of exposure, finer geographic granularity is required	
	vulnerability_function_id UUID NOT NULL,	
	vulnerability_historically boolean,
	vulnerability_data_raw jsonb NOT NULL, -- we recommend that this json includes schema references so a consuming application can use json schema for parsing.	
    vulnerability_level numeric NOT NULL, -- 0.0 = not vulnerable at all 1.0 = highly vulnerable across whole area. In  between = some level of vulnerability, finer geographic granularity is required	
	vulnerability_mean    numeric[],
	vulnerability_std    numeric[],
	vulnerability_distribution_bin_edges    numeric[],
    vulnerability_distribution_probabilities    numeric[],
	vulnerability_exceedance_probabilities    numeric[], -- X axis info, redundant but useful
	vulnerability_return_periods jsonb, -- useful?	
    --parameter    numeric,
    CONSTRAINT pk_asset_vulnerability PRIMARY KEY ( std_id ),
	CONSTRAINT fk_asset_vulnerability_std_dataset_id FOREIGN KEY ( std_dataset_id ) REFERENCES osc_physrisk_backend.dataset(std_id),
    CONSTRAINT fk_asset_vulnerability_geo_country_id FOREIGN KEY ( std_geo_country_id ) REFERENCES osc_physrisk_backend.geo_country(std_id),
	CONSTRAINT ck_asset_vulnerability_geo_h3_resolution CHECK (std_geo_h3_resolution >= 0 AND std_geo_h3_resolution <= 15),
	CONSTRAINT fk_asset_vulnerability_asset_id FOREIGN KEY ( asset_id ) REFERENCES osc_physrisk_assets.generic_asset(std_id),
	CONSTRAINT fk_asset_vulnerability_scenario_id FOREIGN KEY ( scenario_id ) REFERENCES osc_physrisk_scenarios.scenario(std_id),
	CONSTRAINT fk_asset_vulnerability_vulnerability_type_id FOREIGN KEY ( vulnerability_type_id ) REFERENCES osc_physrisk_vulnerability_analysis.vulnerability_type(std_id),
	CONSTRAINT fk_asset_vulnerability_hazard_indicator_id FOREIGN KEY ( hazard_indicator_id ) REFERENCES osc_physrisk_scenarios.hazard_indicator(std_id)    ,
	CONSTRAINT fk_asset_vulnerability_std_vulnerability_function_id FOREIGN KEY ( vulnerability_function_id ) REFERENCES osc_physrisk_vulnerability_analysis.vulnerability_function(std_id),	
	CONSTRAINT fk_asset_vulnerability_std_creator_user_id FOREIGN KEY ( std_creator_user_id ) REFERENCES osc_physrisk_backend.user(std_id),
	CONSTRAINT fk_asset_vulnerability_std_last_modifier_user_id FOREIGN KEY ( std_last_modifier_user_id ) REFERENCES osc_physrisk_backend.user(std_id),
	CONSTRAINT fk_asset_vulnerability_std_deleter_user_id FOREIGN KEY ( std_deleter_user_id ) REFERENCES osc_physrisk_backend.user(std_id)   ,
	CONSTRAINT fk_asset_vulnerability_std_tenant_id FOREIGN KEY ( std_tenant_id ) REFERENCES osc_physrisk_backend.tenant(std_id)
 );
COMMENT ON TABLE osc_physrisk_vulnerability_analysis.asset_vulnerability IS 'The result of a physical risk & resilience analysis for a particular asset. The result is determined by the chosen scenario, year, and hazard. If multiple scenarios/years/hazards were chosen, there will be multiple other rows containing the combined set of results.';

CREATE TABLE osc_physrisk_vulnerability_analysis.geolocated_precalculated_vulnerability ( 
	std_id	UUID  DEFAULT gen_random_UUID () NOT NULL,
	std_name VARCHAR(255) NOT NULL,
	std_name_display VARCHAR(255),
	std_slug VARCHAR(255),
	std_abbreviation VARCHAR(12),
	std_description_full  TEXT NOT NULL,
	std_description_short  VARCHAR(255) NOT NULL,
    std_tags jsonb DEFAULT NULL,
	std_datetime_utc_created TIMESTAMPTZ NOT NULL,
	std_creator_user_id BIGINT NOT NULL,
	std_datetime_utc_last_modified TIMESTAMPTZ NOT NULL,
	std_last_modifier_user_id BIGINT NOT NULL,
	std_is_deleted BOOLEAN NOT NULL DEFAULT 'n',
	std_deleter_user_id BIGINT DEFAULT NULL,
	std_datetime_utc_deleted TIMESTAMPTZ DEFAULT NULL,
	std_tenant_id BIGINT NOT NULL DEFAULT 1,
	std_culture VARCHAR(5) NOT NULL DEFAULT 'en',
	std_checksum VARCHAR(40) DEFAULT NULL,
	std_seq_num SMALLINT  NOT NULL Default 0,
	std_translated_from_id UUID DEFAULT NULL,
	std_is_active BOOLEAN NOT NULL DEFAULT 'y',
	std_is_published BOOLEAN DEFAULT 'n',
	std_publisher_id BIGINT DEFAULT NULL,
	std_datetime_utc_published TIMESTAMPTZ DEFAULT NULL,
	std_version TEXT DEFAULT '1.0',
	std_dataset_id UUID,
	std_geo_country_id UUID,
	std_geo_location_name      	VARCHAR(255),
    std_geo_location_address      	text ,
    std_geo_location_coordinates      	GEOGRAPHY  NOT NULL  ,
	std_geo_altitude numeric DEFAULT NULL, 
	std_geo_altitude_confidence numeric DEFAULT NULL,
	std_geo_overture_features			jsonb[], -- This location can be described in 0 or more Overture Map schemas to cover its land use, infrastructure, building extents, etc
	std_geo_h3_index H3INDEX NOT NULL,
    std_geo_h3_resolution INT2 NOT NULL,
    hazard_indicator_id UUID NOT NULL,
    hazard_intensity numeric[], -- Assume this includes intensity units
	scenario_id UUID NOT NULL,
    scenario_year smallint,
    vulnerability_type_id integer NOT NULL,
	exposure_function_id text NOT NULL,
	exposure_data_raw jsonb NOT NULL, -- STORE RAW JSON, MAYBE OVERLAP WITH SOME COLUMNS BELOW?
	exposure_probability numeric,
	exposure_level numeric, -- 0.0 = not exposed at all 1.0 = fully exposed across whole area. In  between = some level of exposure, finer geographic granularity is required	
	vulnerability_function_id UUID NOT NULL,
	vulnerability_data_raw jsonb NOT NULL, -- we recommend that this json includes schema references so a consuming application can use json schema for parsing.	
    vulnerability_level numeric NOT NULL, -- 0.0 = not vulnerable at all 1.0 = highly vulnerable across whole area. In  between = some level of vulnerability, finer geographic granularity is required	
	vulnerability_mean    numeric[],
	vulnerability_std    numeric[],
	vulnerability_distribution_bin_edges    numeric[],
    vulnerability_distribution_probabilities    numeric[],
	vulnerability_exceedance_probabilities    numeric[], -- X axis info, redundant but useful
	vulnerability_return_periods jsonb, -- useful?	
	vulnerability_historically boolean,
	std_datetime_utc_start timestamptz,
	std_datetime_utc_end timestamptz,
	CONSTRAINT pk_geolocated_precalculated_vulnerability_std_id PRIMARY KEY ( std_id ),
	CONSTRAINT fk_geolocated_precalculated_vulnerability_std_dataset_id FOREIGN KEY ( std_dataset_id ) REFERENCES osc_physrisk_backend.dataset(std_id),
	CONSTRAINT fk_geolocated_precalculated_vulnerability_scenario_id FOREIGN KEY ( scenario_id ) REFERENCES osc_physrisk_scenarios.scenario(std_id),
	CONSTRAINT fk_geolocated_precalculated_vulnerability_vulnerability_type_id FOREIGN KEY ( vulnerability_type_id ) REFERENCES osc_physrisk_vulnerability_analysis.vulnerability_type(std_id),
	CONSTRAINT fk_geolocated_precalculated_vulnerability_hazard_indicator_id FOREIGN KEY ( hazard_indicator_id ) REFERENCES osc_physrisk_scenarios.hazard_indicator(std_id)    ,
	CONSTRAINT fk_geolocated_precalculated_vulnerability_std_vulnerability_function_id FOREIGN KEY ( vulnerability_function_id ) REFERENCES osc_physrisk_vulnerability_analysis.vulnerability_function(std_id),	
	CONSTRAINT fk_geolocated_precalculated_vulnerability_geo_country_id FOREIGN KEY ( std_geo_country_id ) REFERENCES osc_physrisk_backend.geo_country(std_id),
	CONSTRAINT ck_geolocated_precalculated_vulnerability_geo_h3_resolution CHECK (std_geo_h3_resolution >= 0 AND std_geo_h3_resolution <= 15),
	CONSTRAINT fk_geolocated_precalculated_vulnerability_std_creator_user_id FOREIGN KEY ( std_creator_user_id ) REFERENCES osc_physrisk_backend.user(std_id),
	CONSTRAINT fk_geolocated_precalculated_vulnerability_std_last_modifier_user_id FOREIGN KEY ( std_last_modifier_user_id ) REFERENCES osc_physrisk_backend.user(std_id),
	CONSTRAINT fk_geolocated_precalculated_vulnerability_std_deleter_user_id FOREIGN KEY ( std_deleter_user_id ) REFERENCES osc_physrisk_backend.user(std_id) ,
	CONSTRAINT fk_geolocated_precalculated_vulnerability_std_tenant_id FOREIGN KEY ( std_tenant_id ) REFERENCES osc_physrisk_backend.tenant(std_id)
 );
COMMENT ON TABLE osc_physrisk_vulnerability_analysis.geolocated_precalculated_vulnerability IS 'To help with indexing and searching, geographic locations may have precalculated information for hazard impacts. This can be historic (it actually happened) or projected (it is likely to happen). Note that this information is not aware of or concerned by whether or which physical assets may be present insstd_ide its borders.';


-- SCHEMA osc_physrisk_financial_analysis;
CREATE TABLE osc_physrisk_financial_analysis.financial_function ( 
	std_id	UUID  DEFAULT gen_random_UUID () NOT NULL,
	std_name VARCHAR(255) NOT NULL,
	std_name_display VARCHAR(255),
	std_slug VARCHAR(255),
	std_abbreviation VARCHAR(12),
	std_description_full  TEXT NOT NULL,
	std_description_short  VARCHAR(255) NOT NULL,
    std_tags jsonb DEFAULT NULL,
	std_datetime_utc_created TIMESTAMPTZ NOT NULL,
	std_creator_user_id BIGINT NOT NULL,
	std_datetime_utc_last_modified TIMESTAMPTZ NOT NULL,
	std_last_modifier_user_id BIGINT NOT NULL,
	std_is_deleted BOOLEAN NOT NULL DEFAULT 'n',
	std_deleter_user_id BIGINT DEFAULT NULL,
	std_datetime_utc_deleted TIMESTAMPTZ DEFAULT NULL,
	std_tenant_id BIGINT NOT NULL DEFAULT 1,
	std_culture VARCHAR(5) NOT NULL DEFAULT 'en',
	std_checksum VARCHAR(40) DEFAULT NULL,
	std_seq_num SMALLINT  NOT NULL Default 0,
	std_translated_from_id UUID DEFAULT NULL,
	std_is_active BOOLEAN NOT NULL DEFAULT 'y',
	std_is_published BOOLEAN DEFAULT 'n',
	std_publisher_id BIGINT DEFAULT NULL,
	std_datetime_utc_published TIMESTAMPTZ DEFAULT NULL,
	std_version TEXT DEFAULT '1.0',
	std_dataset_id UUID,
	CONSTRAINT pk_financial_function PRIMARY KEY ( std_id ),
	CONSTRAINT fk_financial_function_std_dataset_id FOREIGN KEY ( std_dataset_id ) REFERENCES osc_physrisk_backend.dataset(std_id),
	CONSTRAINT fk_financial_function_std_creator_user_id FOREIGN KEY ( std_creator_user_id ) REFERENCES osc_physrisk_backend.user(std_id),
	CONSTRAINT fk_financial_function_std_last_modifier_user_id FOREIGN KEY ( std_last_modifier_user_id ) REFERENCES osc_physrisk_backend.user(std_id),
	CONSTRAINT fk_financial_function_std_deleter_user_id FOREIGN KEY ( std_deleter_user_id ) REFERENCES osc_physrisk_backend.user(std_id),
	CONSTRAINT fk_financial_function_std_tenant_id FOREIGN KEY ( std_tenant_id ) REFERENCES osc_physrisk_backend.tenant(std_id)
 );
COMMENT ON TABLE osc_physrisk_financial_analysis.financial_function IS 'Related to osc_physrisk_financial_analysis';

CREATE TABLE osc_physrisk_financial_analysis.financial_impact_type ( 
	std_id INTEGER NOT NULL,
	std_name VARCHAR(255) NOT NULL,
	std_name_display VARCHAR(255),
	std_slug VARCHAR(255),
	std_abbreviation VARCHAR(12),
	std_description_full  TEXT NOT NULL,
	std_description_short  VARCHAR(255) NOT NULL,
    std_tags jsonb DEFAULT NULL,
	std_datetime_utc_created TIMESTAMPTZ NOT NULL,
	std_creator_user_id BIGINT NOT NULL,
	std_datetime_utc_last_modified TIMESTAMPTZ NOT NULL,
	std_last_modifier_user_id BIGINT NOT NULL,
	std_is_deleted BOOLEAN NOT NULL DEFAULT 'n',
	std_deleter_user_id BIGINT DEFAULT NULL,
	std_datetime_utc_deleted TIMESTAMPTZ DEFAULT NULL,
	std_culture VARCHAR(5) NOT NULL DEFAULT 'en',
	std_checksum VARCHAR(40) DEFAULT NULL,
	std_seq_num SMALLINT  NOT NULL Default 0,
	std_translated_from_id UUID DEFAULT NULL,
	std_is_active BOOLEAN NOT NULL DEFAULT 'y',
	std_is_published BOOLEAN DEFAULT 'n',
	std_publisher_id BIGINT DEFAULT NULL,
	std_datetime_utc_published TIMESTAMPTZ DEFAULT NULL,
	std_version TEXT DEFAULT '1.0',
	std_dataset_id UUID,
    accounting_category VARCHAR(255),
	CONSTRAINT pk_financial_impact_type PRIMARY KEY ( std_id ),
	CONSTRAINT fk_financial_impact_type_std_dataset_id FOREIGN KEY ( std_dataset_id ) REFERENCES osc_physrisk_backend.dataset(std_id),
	CONSTRAINT fk_financial_impact_type_std_creator_user_id FOREIGN KEY ( std_creator_user_id ) REFERENCES osc_physrisk_backend.user(std_id),
	CONSTRAINT fk_financial_impact_type_std_last_modifier_user_id FOREIGN KEY ( std_last_modifier_user_id ) REFERENCES osc_physrisk_backend.user(std_id),
	CONSTRAINT fk_financial_impact_type_std_deleter_user_id FOREIGN KEY ( std_deleter_user_id ) REFERENCES osc_physrisk_backend.user(std_id)
 ); 
COMMENT ON TABLE osc_physrisk_financial_analysis.financial_impact_type IS 'A lookup table to classify and constrain types of damage/disruption that could occur to an asset due to its vulnerability to a hazard.';

CREATE TABLE osc_physrisk_financial_analysis.portfolio_financial_impact ( 
	std_id UUID  DEFAULT gen_random_UUID () NOT NULL,
	std_name VARCHAR(255) NOT NULL,
	std_name_display VARCHAR(255),
	std_slug VARCHAR(255),
	std_abbreviation VARCHAR(12),
	std_description_full  TEXT NOT NULL,
	std_description_short  VARCHAR(255) NOT NULL,
    std_tags jsonb DEFAULT NULL,
	std_datetime_utc_created TIMESTAMPTZ NOT NULL,
	std_creator_user_id BIGINT NOT NULL,
	std_datetime_utc_last_modified TIMESTAMPTZ NOT NULL,
	std_last_modifier_user_id BIGINT NOT NULL,
	std_is_deleted BOOLEAN NOT NULL DEFAULT 'n',
	std_deleter_user_id BIGINT DEFAULT NULL,
	std_datetime_utc_deleted TIMESTAMPTZ DEFAULT NULL,
	std_tenant_id BIGINT NOT NULL DEFAULT 1,
	std_culture VARCHAR(5) NOT NULL DEFAULT 'en',
	std_checksum VARCHAR(40) DEFAULT NULL,
	std_seq_num SMALLINT  NOT NULL Default 0,
	std_translated_from_id UUID DEFAULT NULL,
	std_is_active BOOLEAN NOT NULL DEFAULT 'y',
	std_is_published BOOLEAN DEFAULT 'n',
	std_publisher_id BIGINT DEFAULT NULL,
	std_datetime_utc_published TIMESTAMPTZ DEFAULT NULL,
	std_version TEXT DEFAULT '1.0',
	std_dataset_id UUID,
	portfolio_id            UUID  NOT NULL  ,
	scenario_id UUID NOT NULL,
    scenario_year smallint,
	hazard_id	UUID NOT NULL,
	annual_exceedence_probability numeric,
	average_annual_loss numeric,
    value_total numeric,
    value_at_risk numeric,
    value_currency_alphabetic_code char(3),
	CONSTRAINT pk_portfolio_financial_impact PRIMARY KEY ( std_id ),
	CONSTRAINT fk_portfolio_financial_impact_std_dataset_id FOREIGN KEY ( std_dataset_id ) REFERENCES osc_physrisk_backend.dataset(std_id),
	CONSTRAINT fk_portfolio_financial_impact_analysis_std_id FOREIGN KEY ( portfolio_id ) REFERENCES osc_physrisk_assets.portfolio(std_id),
	CONSTRAINT fk_portfolio_financial_impact_analysis_scenario_id FOREIGN KEY ( scenario_id ) REFERENCES osc_physrisk_scenarios.scenario(std_id),
	CONSTRAINT fk_portfolio_financial_impact_analysis_hazard_id FOREIGN KEY ( hazard_id ) REFERENCES osc_physrisk_scenarios.hazard(std_id)   ,
	CONSTRAINT fk_portfolio_financial_impact_analysis_std_creator_user_id FOREIGN KEY ( std_creator_user_id ) REFERENCES osc_physrisk_backend.user(std_id),
	CONSTRAINT fk_portfolio_financial_impact_analysis_std_last_modifier_user_id FOREIGN KEY ( std_last_modifier_user_id ) REFERENCES osc_physrisk_backend.user(std_id),
	CONSTRAINT fk_portfolio_financial_impact_analysis_std_deleter_user_id FOREIGN KEY ( std_deleter_user_id ) REFERENCES osc_physrisk_backend.user(std_id)  ,
	CONSTRAINT fk_portfolio_financial_impact_analysis_std_tenant_id FOREIGN KEY ( std_tenant_id ) REFERENCES osc_physrisk_backend.tenant(std_id)
 );
COMMENT ON TABLE osc_physrisk_financial_analysis.portfolio_financial_impact IS 'The result of a physical risk & resilience analysis. The result is determined by the chosen scenario, year, and hazard, aggregating the results for all of the assets in a given portfolio. If multiple scenarios/years/hazards were chosen, there will be multiple other rows containing the combined set of results.';

CREATE TABLE osc_physrisk_financial_analysis.asset_financial_impact ( 
	std_id UUID  DEFAULT gen_random_UUID () NOT NULL,
	std_name VARCHAR(255) NOT NULL,
	std_name_display VARCHAR(255),
	std_slug VARCHAR(255),
	std_abbreviation VARCHAR(12),
	std_description_full  TEXT NOT NULL,
	std_description_short  VARCHAR(255) NOT NULL,
    std_tags jsonb DEFAULT NULL,
	std_datetime_utc_created TIMESTAMPTZ NOT NULL,
	std_creator_user_id BIGINT NOT NULL,
	std_datetime_utc_last_modified TIMESTAMPTZ NOT NULL,
	std_last_modifier_user_id BIGINT NOT NULL,
	std_is_deleted BOOLEAN NOT NULL DEFAULT 'n',
	std_deleter_user_id BIGINT DEFAULT NULL,
	std_datetime_utc_deleted TIMESTAMPTZ DEFAULT NULL,
	std_tenant_id BIGINT NOT NULL DEFAULT 1,
	std_culture VARCHAR(5) NOT NULL DEFAULT 'en',
	std_checksum VARCHAR(40) DEFAULT NULL,
	std_seq_num SMALLINT  NOT NULL Default 0,
	std_translated_from_id UUID DEFAULT NULL,
	std_is_active BOOLEAN NOT NULL DEFAULT 'y',
	std_is_published BOOLEAN DEFAULT 'n',
	std_publisher_id BIGINT DEFAULT NULL,
	std_datetime_utc_published TIMESTAMPTZ DEFAULT NULL,
	std_version TEXT DEFAULT '1.0',
	std_dataset_id UUID,
	std_geo_country_id UUID,
	std_geo_location_name      	VARCHAR(255),
    std_geo_location_address      	text ,
    std_geo_location_coordinates      	GEOGRAPHY  NOT NULL  ,
	std_geo_altitude numeric DEFAULT NULL, 
	std_geo_altitude_confidence numeric DEFAULT NULL,
	std_geo_overture_features			jsonb[], -- This location can be described in 0 or more Overture Map schemas to cover its land use, infrastructure, building extents, etc
	std_geo_h3_index H3INDEX NOT NULL,
    std_geo_h3_resolution INT2 NOT NULL,
	std_datetime_utc_start timestamptz,
	std_datetime_utc_end timestamptz,	
	asset_id            UUID  NOT NULL  ,
	hazard_indicator_id UUID NOT NULL,
    hazard_intensity numeric[], -- Assume this includes intensity units
	scenario_id UUID NOT NULL,
    scenario_year smallint,
    vulnerability_type_id integer NOT NULL,
	financial_impact_type_id integer NOT NULL, -- this design assumes one row per impact type. If there are multiple potential impact types, there would be multiple rows.
	impact_data_raw jsonb NOT NULL, -- we recommend that this json includes schema references so a consuming application can use json schema for parsing.	
    impact_level numeric NOT NULL, -- 0.0 = not vulnerable at all 1.0 = highly vulnerable across whole area. In  between = some level of vulnerability, finer geographic granularity is required	
	impact_mean    numeric[],
	impact_std    numeric[],
	impact_distribution_bin_edges    numeric[],
    impact_distribution_probabilities    numeric[],
	impact_exceedance_probabilities    numeric[], -- X axis info, redundant but useful
	impact_return_periods jsonb, -- useful?	
	value_total numeric,
    value_at_risk numeric,
    value_currency_alphabetic_code char(3),
    --parameter    numeric,
    exposure_function_id text NOT NULL,
	exposure_result_raw jsonb NOT NULL, -- STORE RAW JSON, MAYBE OVERLAP WITH SOME COLUMNS BELOW?
	exposure_probability numeric,
	exposure_level bool,	
	vulnerability_function_id UUID NOT NULL,
	CONSTRAINT pk_asset_financial_impact PRIMARY KEY ( std_id ),
	CONSTRAINT fk_asset_financial_impact_std_dataset_id FOREIGN KEY ( std_dataset_id ) REFERENCES osc_physrisk_backend.dataset(std_id),
    CONSTRAINT fk_asset_financial_impact_geo_country_id FOREIGN KEY ( std_geo_country_id ) REFERENCES osc_physrisk_backend.geo_country(std_id),
	CONSTRAINT ck_asset_financial_impact_geo_h3_resolution CHECK (std_geo_h3_resolution >= 0 AND std_geo_h3_resolution <= 15),
	CONSTRAINT fk_asset_financial_impact_asset_id FOREIGN KEY ( asset_id ) REFERENCES osc_physrisk_assets.generic_asset(std_id),
	CONSTRAINT fk_asset_financial_impact_scenario_id FOREIGN KEY ( scenario_id ) REFERENCES osc_physrisk_scenarios.scenario(std_id),
	CONSTRAINT fk_asset_financial_impact_vulnerability_type_id FOREIGN KEY ( vulnerability_type_id ) REFERENCES osc_physrisk_vulnerability_analysis.vulnerability_type(std_id),
	CONSTRAINT fk_asset_financial_impact_financial_impact_type_id FOREIGN KEY ( financial_impact_type_id ) REFERENCES osc_physrisk_financial_analysis.financial_impact_type(std_id),
	CONSTRAINT fk_asset_financial_impact_hazard_indicator_id FOREIGN KEY ( hazard_indicator_id ) REFERENCES osc_physrisk_scenarios.hazard_indicator(std_id)    ,
	CONSTRAINT fk_asset_financial_impact_std_vulnerability_function_id FOREIGN KEY ( vulnerability_function_id ) REFERENCES osc_physrisk_vulnerability_analysis.vulnerability_function(std_id),	
	CONSTRAINT fk_asset_financial_impact_std_creator_user_id FOREIGN KEY ( std_creator_user_id ) REFERENCES osc_physrisk_backend.user(std_id),
	CONSTRAINT fk_asset_financial_impact_std_last_modifier_user_id FOREIGN KEY ( std_last_modifier_user_id ) REFERENCES osc_physrisk_backend.user(std_id),
	CONSTRAINT fk_asset_financial_impact_std_deleter_user_id FOREIGN KEY ( std_deleter_user_id ) REFERENCES osc_physrisk_backend.user(std_id)   ,
	CONSTRAINT fk_asset_financial_impact_std_tenant_id FOREIGN KEY ( std_tenant_id ) REFERENCES osc_physrisk_backend.tenant(std_id)
 );
COMMENT ON TABLE osc_physrisk_financial_analysis.asset_financial_impact IS 'The financial impact result of a physical risk & resilience analysis for a particular asset. The result is determined by the chosen scenario, year, and hazard. If multiple scenarios/years/hazards were chosen, there will be multiple other rows containing the combined set of results. A financial impact can only occur if there is a corresponding impact row (see asset_vulnerability table)';


-- SETUP PERMISSIONS FOR A READER SQL SERVICE ACCOUNT (CREATE THAT USING A DATABASE TOOL)
--GRANT USAGE ON SCHEMA "osc_physrisk_backend" TO physrisk_reader_service;
--GRANT SELECT ON ALL TABLES IN SCHEMA "osc_physrisk_backend" TO physrisk_reader_service;
--GRANT USAGE ON SCHEMA "osc_physrisk_scenarios" TO physrisk_reader_service;
--GRANT SELECT ON ALL TABLES IN SCHEMA "osc_physrisk_scenarios" TO physrisk_reader_service;
--GRANT USAGE ON SCHEMA "osc_physrisk_assets" TO physrisk_reader_service;
--GRANT SELECT ON ALL TABLES IN SCHEMA "osc_physrisk_assets" TO physrisk_reader_service;
--GRANT USAGE ON SCHEMA "osc_physrisk_vulnerability_analysis" TO physrisk_reader_service;
--GRANT SELECT ON ALL TABLES IN SCHEMA "osc_physrisk_vulnerability_analysis" TO physrisk_reader_service;

-- SETUP PERMISSIONS FOR A READER/WRITER SQL SERVICE ACCOUNT (CREATE THAT USING A DATABASE TOOL)
--GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA "osc_physrisk_backend" TO physrisk_readerwriter_service;
--GRANT ALL ON ALL TABLES IN SCHEMA "osc_physrisk_backend" TO physrisk_readerwriter_service;
--GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA "osc_physrisk_scenarios" TO physrisk_readerwriter_service;
--GRANT ALL ON ALL TABLES IN SCHEMA "osc_physrisk_scenarios" TO physrisk_readerwriter_service;
--GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA "osc_physrisk_assets" TO physrisk_readerwriter_service;
--GRANT ALL ON ALL TABLES IN SCHEMA "osc_physrisk_assets" TO physrisk_readerwriter_service;
--GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA "osc_physrisk_vulnerability_analysis" TO physrisk_readerwriter_service;
--GRANT ALL ON ALL TABLES IN SCHEMA "osc_physrisk_vulnerability_analysis" TO physrisk_readerwriter_service;

-- DATA IN ENGLISH STARTS

INSERT INTO osc_physrisk_backend.user
	(std_id, std_datetime_utc_created, std_creator_user_id, std_datetime_utc_last_modified, std_last_modifier_user_id, std_is_deleted, std_deleter_user_id, std_datetime_utc_deleted, std_user_name, std_tenant_id, email_address, std_name, std_surname, std_is_active)
VALUES 
	(1,'2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'osc',1,'example@email','Open-Source','Climate','y')
;
INSERT INTO osc_physrisk_backend.tenant
	(std_id, std_datetime_utc_created, std_creator_user_id, std_datetime_utc_last_modified, std_last_modifier_user_id, std_is_deleted, std_deleter_user_id, std_datetime_utc_deleted, std_tenancy_name, std_name, std_is_active)
VALUES 
	(1,'2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL,'Default','Default','y');


-- INSERT COUNTRIES
INSERT INTO osc_physrisk_backend.geo_country(std_name,std_name_display,std_slug,std_abbreviation,std_description_full,std_description_short,std_tags,std_datetime_utc_created,std_creator_user_id,std_datetime_utc_last_modified,std_last_modifier_user_id,std_is_deleted,std_deleter_user_id,std_datetime_utc_deleted,std_culture,std_checksum,std_seq_num,std_translated_from_id,std_is_active,std_is_published,std_publisher_id,std_datetime_utc_published,std_version,un_global_code,un_global_name,un_region_code,un_region_name,un_subregion_code,un_subregion_name,un_intermediateregion_code,un_intermediateregion_name,un_code_m49,un_is_ldc,un_is_lldc,un_is_sids,iso_code_alpha2,iso_code_alpha3) VALUES ('Algeria','Algeria','/countries/africa/algeria',null,'Algeria','Algeria','{}','2024-07-14 20:00',1,'2024-07-14 20:00',1,'n',null,null,'en',' std_checksum',1,null,'y','y',1,'2024-07-14 20:00','1',1,'World',2,'Africa',15,'Northern Africa',null,'Algeria',12,'n','n','n','DZ','DZA'),('Egypt','Egypt','/countries/africa/egypt',null,'Egypt','Egypt','{}','2024-07-14 20:00',1,'2024-07-14 20:00',1,'n',null,null,'en',' std_checksum',1,null,'y','y',1,'2024-07-14 20:00','1',1,'World',2,'Africa',15,'Northern Africa',null,null,818,'n','n','n','EG','EGY'),('Libya','Libya','/countries/africa/libya',null,'Libya','Libya','{}','2024-07-14 20:00',1,'2024-07-14 20:00',1,'n',null,null,'en',' std_checksum',1,null,'y','y',1,'2024-07-14 20:00','1',1,'World',2,'Africa',15,'Northern Africa',null,null,434,'n','n','n','LY','LBY'),('Morocco','Morocco','/countries/africa/morocco',null,'Morocco','Morocco','{}','2024-07-14 20:00',1,'2024-07-14 20:00',1,'n',null,null,'en',' std_checksum',1,null,'y','y',1,'2024-07-14 20:00','1',1,'World',2,'Africa',15,'Northern Africa',null,null,504,'n','n','n','MA','MAR'),('Sudan','Sudan','/countries/africa/sudan',null,'Sudan','Sudan','{}','2024-07-14 20:00',1,'2024-07-14 20:00',1,'n',null,null,'en',' std_checksum',1,null,'y','y',1,'2024-07-14 20:00','1',1,'World',2,'Africa',15,'Northern Africa',null,null,729,'y','n','n','SD','SDN'),('Tunisia','Tunisia','/countries/africa/tunisia',null,'Tunisia','Tunisia','{}','2024-07-14 20:00',1,'2024-07-14 20:00',1,'n',null,null,'en',' std_checksum',1,null,'y','y',1,'2024-07-14 20:00','1',1,'World',2,'Africa',15,'Northern Africa',null,null,788,'n','n','n','TN','TUN'),('Western Sahara','Western Sahara','/countries/africa/western%20sahara',null,'Western Sahara','Western Sahara','{}','2024-07-14 20:00',1,'2024-07-14 20:00',1,'n',null,null,'en',' std_checksum',1,null,'y','y',1,'2024-07-14 20:00','1',1,'World',2,'Africa',15,'Northern Africa',null,null,732,'n','n','n','EH','ESH'),('British Indian Ocean Territory','British Indian Ocean Territory','/countries/africa/british%20indian%20ocean%20territory',null,'British Indian Ocean Territory','British Indian Ocean Territory','{}','2024-07-14 20:00',1,'2024-07-14 20:00',1,'n',null,null,'en',' std_checksum',1,null,'y','y',1,'2024-07-14 20:00','1',1,'World',2,'Africa',202,'Sub-Saharan Africa',14,'Eastern Africa',86,'n','n','n','IO','IOT'),('Burundi','Burundi','/countries/africa/burundi',null,'Burundi','Burundi','{}','2024-07-14 20:00',1,'2024-07-14 20:00',1,'n',null,null,'en',' std_checksum',1,null,'y','y',1,'2024-07-14 20:00','1',1,'World',2,'Africa',202,'Sub-Saharan Africa',14,'Eastern Africa',108,'y','y','n','BI','BDI'),('Comoros','Comoros','/countries/africa/comoros',null,'Comoros','Comoros','{}','2024-07-14 20:00',1,'2024-07-14 20:00',1,'n',null,null,'en',' std_checksum',1,null,'y','y',1,'2024-07-14 20:00','1',1,'World',2,'Africa',202,'Sub-Saharan Africa',14,'Eastern Africa',174,'y','n','y','KM','COM'),('Djibouti','Djibouti','/countries/africa/djibouti',null,'Djibouti','Djibouti','{}','2024-07-14 20:00',1,'2024-07-14 20:00',1,'n',null,null,'en',' std_checksum',1,null,'y','y',1,'2024-07-14 20:00','1',1,'World',2,'Africa',202,'Sub-Saharan Africa',14,'Eastern Africa',262,'y','n','n','DJ','DJI'),('Eritrea','Eritrea','/countries/africa/eritrea',null,'Eritrea','Eritrea','{}','2024-07-14 20:00',1,'2024-07-14 20:00',1,'n',null,null,'en',' std_checksum',1,null,'y','y',1,'2024-07-14 20:00','1',1,'World',2,'Africa',202,'Sub-Saharan Africa',14,'Eastern Africa',232,'y','n','n','ER','ERI'),('Ethiopia','Ethiopia','/countries/africa/ethiopia',null,'Ethiopia','Ethiopia','{}','2024-07-14 20:00',1,'2024-07-14 20:00',1,'n',null,null,'en',' std_checksum',1,null,'y','y',1,'2024-07-14 20:00','1',1,'World',2,'Africa',202,'Sub-Saharan Africa',14,'Eastern Africa',231,'y','y','n','ET','ETH'),('French Southern Territories','French Southern Territories','/countries/africa/french%20southern%20territories',null,'French Southern Territories','French Southern Territories','{}','2024-07-14 20:00',1,'2024-07-14 20:00',1,'n',null,null,'en',' std_checksum',1,null,'y','y',1,'2024-07-14 20:00','1',1,'World',2,'Africa',202,'Sub-Saharan Africa',14,'Eastern Africa',260,'n','n','n','TF','ATF'),('Kenya','Kenya','/countries/africa/kenya',null,'Kenya','Kenya','{}','2024-07-14 20:00',1,'2024-07-14 20:00',1,'n',null,null,'en',' std_checksum',1,null,'y','y',1,'2024-07-14 20:00','1',1,'World',2,'Africa',202,'Sub-Saharan Africa',14,'Eastern Africa',404,'n','n','n','KE','KEN'),('Madagascar','Madagascar','/countries/africa/madagascar',null,'Madagascar','Madagascar','{}','2024-07-14 20:00',1,'2024-07-14 20:00',1,'n',null,null,'en',' std_checksum',1,null,'y','y',1,'2024-07-14 20:00','1',1,'World',2,'Africa',202,'Sub-Saharan Africa',14,'Eastern Africa',450,'y','n','n','MG','MDG'),('Malawi','Malawi','/countries/africa/malawi',null,'Malawi','Malawi','{}','2024-07-14 20:00',1,'2024-07-14 20:00',1,'n',null,null,'en',' std_checksum',1,null,'y','y',1,'2024-07-14 20:00','1',1,'World',2,'Africa',202,'Sub-Saharan Africa',14,'Eastern Africa',454,'y','y','n','MW','MWI'),('Mauritius','Mauritius','/countries/africa/mauritius',null,'Mauritius','Mauritius','{}','2024-07-14 20:00',1,'2024-07-14 20:00',1,'n',null,null,'en',' std_checksum',1,null,'y','y',1,'2024-07-14 20:00','1',1,'World',2,'Africa',202,'Sub-Saharan Africa',14,'Eastern Africa',480,'n','n','y','MU','MUS'),('Mayotte','Mayotte','/countries/africa/mayotte',null,'Mayotte','Mayotte','{}','2024-07-14 20:00',1,'2024-07-14 20:00',1,'n',null,null,'en',' std_checksum',1,null,'y','y',1,'2024-07-14 20:00','1',1,'World',2,'Africa',202,'Sub-Saharan Africa',14,'Eastern Africa',175,'n','n','n','YT','MYT'),('Mozambique','Mozambique','/countries/africa/mozambique',null,'Mozambique','Mozambique','{}','2024-07-14 20:00',1,'2024-07-14 20:00',1,'n',null,null,'en',' std_checksum',1,null,'y','y',1,'2024-07-14 20:00','1',1,'World',2,'Africa',202,'Sub-Saharan Africa',14,'Eastern Africa',508,'y','n','n','MZ','MOZ'),('Réunion','Réunion','/countries/africa/reunion',null,'Réunion','Réunion','{}','2024-07-14 20:00',1,'2024-07-14 20:00',1,'n',null,null,'en',' std_checksum',1,null,'y','y',1,'2024-07-14 20:00','1',1,'World',2,'Africa',202,'Sub-Saharan Africa',14,'Eastern Africa',638,'n','n','n','RE','REU'),('Rwanda','Rwanda','/countries/africa/rwanda',null,'Rwanda','Rwanda','{}','2024-07-14 20:00',1,'2024-07-14 20:00',1,'n',null,null,'en',' std_checksum',1,null,'y','y',1,'2024-07-14 20:00','1',1,'World',2,'Africa',202,'Sub-Saharan Africa',14,'Eastern Africa',646,'y','y','n','RW','RWA'),('Seychelles','Seychelles','/countries/africa/seychelles',null,'Seychelles','Seychelles','{}','2024-07-14 20:00',1,'2024-07-14 20:00',1,'n',null,null,'en',' std_checksum',1,null,'y','y',1,'2024-07-14 20:00','1',1,'World',2,'Africa',202,'Sub-Saharan Africa',14,'Eastern Africa',690,'n','n','y','SC','SYC'),('Somalia','Somalia','/countries/africa/somalia',null,'Somalia','Somalia','{}','2024-07-14 20:00',1,'2024-07-14 20:00',1,'n',null,null,'en',' std_checksum',1,null,'y','y',1,'2024-07-14 20:00','1',1,'World',2,'Africa',202,'Sub-Saharan Africa',14,'Eastern Africa',706,'y','n','n','SO','SOM'),('South Sudan','South Sudan','/countries/africa/south%20sudan',null,'South Sudan','South Sudan','{}','2024-07-14 20:00',1,'2024-07-14 20:00',1,'n',null,null,'en',' std_checksum',1,null,'y','y',1,'2024-07-14 20:00','1',1,'World',2,'Africa',202,'Sub-Saharan Africa',14,'Eastern Africa',728,'y','y','n','SS','SSD');
INSERT INTO osc_physrisk_backend.geo_country(std_name,std_name_display,std_slug,std_abbreviation,std_description_full,std_description_short,std_tags,std_datetime_utc_created,std_creator_user_id,std_datetime_utc_last_modified,std_last_modifier_user_id,std_is_deleted,std_deleter_user_id,std_datetime_utc_deleted,std_culture,std_checksum,std_seq_num,std_translated_from_id,std_is_active,std_is_published,std_publisher_id,std_datetime_utc_published,std_version,un_global_code,un_global_name,un_region_code,un_region_name,un_subregion_code,un_subregion_name,un_intermediateregion_code,un_intermediateregion_name,un_code_m49,un_is_ldc,un_is_lldc,un_is_sids,iso_code_alpha2,iso_code_alpha3) VALUES ('Uganda','Uganda','/countries/africa/uganda',null,'Uganda','Uganda','{}','2024-07-14 20:00',1,'2024-07-14 20:00',1,'n',null,null,'en',' std_checksum',1,null,'y','y',1,'2024-07-14 20:00','1',1,'World',2,'Africa',202,'Sub-Saharan Africa',14,'Eastern Africa',800,'y','y','n','UG','UGA'),('United Republic of Tanzania','United Republic of Tanzania','/countries/africa/united%20republic%20of%20tanzania',null,'United Republic of Tanzania','United Republic of Tanzania','{}','2024-07-14 20:00',1,'2024-07-14 20:00',1,'n',null,null,'en',' std_checksum',1,null,'y','y',1,'2024-07-14 20:00','1',1,'World',2,'Africa',202,'Sub-Saharan Africa',14,'Eastern Africa',834,'y','n','n','TZ','TZA'),('Zambia','Zambia','/countries/africa/zambia',null,'Zambia','Zambia','{}','2024-07-14 20:00',1,'2024-07-14 20:00',1,'n',null,null,'en',' std_checksum',1,null,'y','y',1,'2024-07-14 20:00','1',1,'World',2,'Africa',202,'Sub-Saharan Africa',14,'Eastern Africa',894,'y','y','n','ZM','ZMB'),('Zimbabwe','Zimbabwe','/countries/africa/zimbabwe',null,'Zimbabwe','Zimbabwe','{}','2024-07-14 20:00',1,'2024-07-14 20:00',1,'n',null,null,'en',' std_checksum',1,null,'y','y',1,'2024-07-14 20:00','1',1,'World',2,'Africa',202,'Sub-Saharan Africa',14,'Eastern Africa',716,'n','y','n','ZW','ZWE'),('Angola','Angola','/countries/africa/angola',null,'Angola','Angola','{}','2024-07-14 20:00',1,'2024-07-14 20:00',1,'n',null,null,'en',' std_checksum',1,null,'y','y',1,'2024-07-14 20:00','1',1,'World',2,'Africa',202,'Sub-Saharan Africa',17,'Middle Africa',24,'y','n','n','AO','AGO'),('Cameroon','Cameroon','/countries/africa/cameroon',null,'Cameroon','Cameroon','{}','2024-07-14 20:00',1,'2024-07-14 20:00',1,'n',null,null,'en',' std_checksum',1,null,'y','y',1,'2024-07-14 20:00','1',1,'World',2,'Africa',202,'Sub-Saharan Africa',17,'Middle Africa',120,'n','n','n','CM','CMR'),('Central African Republic','Central African Republic','/countries/africa/central%20african%20republic',null,'Central African Republic','Central African Republic','{}','2024-07-14 20:00',1,'2024-07-14 20:00',1,'n',null,null,'en',' std_checksum',1,null,'y','y',1,'2024-07-14 20:00','1',1,'World',2,'Africa',202,'Sub-Saharan Africa',17,'Middle Africa',140,'y','y','n','CF','CAF'),('Chad','Chad','/countries/africa/chad',null,'Chad','Chad','{}','2024-07-14 20:00',1,'2024-07-14 20:00',1,'n',null,null,'en',' std_checksum',1,null,'y','y',1,'2024-07-14 20:00','1',1,'World',2,'Africa',202,'Sub-Saharan Africa',17,'Middle Africa',148,'y','y','n','TD','TCD'),('Congo','Congo','/countries/africa/congo',null,'Congo','Congo','{}','2024-07-14 20:00',1,'2024-07-14 20:00',1,'n',null,null,'en',' std_checksum',1,null,'y','y',1,'2024-07-14 20:00','1',1,'World',2,'Africa',202,'Sub-Saharan Africa',17,'Middle Africa',178,'n','n','n','CG','COG'),('Democratic Republic of the Congo','Democratic Republic of the Congo','/countries/africa/democratic%20republic%20of%20the%20congo',null,'Democratic Republic of the Congo','Democratic Republic of the Congo','{}','2024-07-14 20:00',1,'2024-07-14 20:00',1,'n',null,null,'en',' std_checksum',1,null,'y','y',1,'2024-07-14 20:00','1',1,'World',2,'Africa',202,'Sub-Saharan Africa',17,'Middle Africa',180,'y','n','n','CD','COD'),('Equatorial Guinea','Equatorial Guinea','/countries/africa/equatorial%20guinea',null,'Equatorial Guinea','Equatorial Guinea','{}','2024-07-14 20:00',1,'2024-07-14 20:00',1,'n',null,null,'en',' std_checksum',1,null,'y','y',1,'2024-07-14 20:00','1',1,'World',2,'Africa',202,'Sub-Saharan Africa',17,'Middle Africa',226,'n','n','n','GQ','GNQ'),('Gabon','Gabon','/countries/africa/gabon',null,'Gabon','Gabon','{}','2024-07-14 20:00',1,'2024-07-14 20:00',1,'n',null,null,'en',' std_checksum',1,null,'y','y',1,'2024-07-14 20:00','1',1,'World',2,'Africa',202,'Sub-Saharan Africa',17,'Middle Africa',266,'n','n','n','GA','GAB'),('Sao Tome and Principe','Sao Tome and Principe','/countries/africa/sao%20tome%20and%20principe',null,'Sao Tome and Principe','Sao Tome and Principe','{}','2024-07-14 20:00',1,'2024-07-14 20:00',1,'n',null,null,'en',' std_checksum',1,null,'y','y',1,'2024-07-14 20:00','1',1,'World',2,'Africa',202,'Sub-Saharan Africa',17,'Middle Africa',678,'y','n','y','ST','STP'),('Botswana','Botswana','/countries/africa/botswana',null,'Botswana','Botswana','{}','2024-07-14 20:00',1,'2024-07-14 20:00',1,'n',null,null,'en',' std_checksum',1,null,'y','y',1,'2024-07-14 20:00','1',1,'World',2,'Africa',202,'Sub-Saharan Africa',18,'Southern Africa',72,'n','y','n','BW','BWA'),('Eswatini','Eswatini','/countries/africa/eswatini',null,'Eswatini','Eswatini','{}','2024-07-14 20:00',1,'2024-07-14 20:00',1,'n',null,null,'en',' std_checksum',1,null,'y','y',1,'2024-07-14 20:00','1',1,'World',2,'Africa',202,'Sub-Saharan Africa',18,'Southern Africa',748,'n','y','n','SZ','SWZ'),('Lesotho','Lesotho','/countries/africa/lesotho',null,'Lesotho','Lesotho','{}','2024-07-14 20:00',1,'2024-07-14 20:00',1,'n',null,null,'en',' std_checksum',1,null,'y','y',1,'2024-07-14 20:00','1',1,'World',2,'Africa',202,'Sub-Saharan Africa',18,'Southern Africa',426,'y','y','n','LS','LSO'),('Namibia','Namibia','/countries/africa/namibia',null,'Namibia','Namibia','{}','2024-07-14 20:00',1,'2024-07-14 20:00',1,'n',null,null,'en',' std_checksum',1,null,'y','y',1,'2024-07-14 20:00','1',1,'World',2,'Africa',202,'Sub-Saharan Africa',18,'Southern Africa',516,'n','n','n','NA','NAM'),('South Africa','South Africa','/countries/africa/south%20africa',null,'South Africa','South Africa','{}','2024-07-14 20:00',1,'2024-07-14 20:00',1,'n',null,null,'en',' std_checksum',1,null,'y','y',1,'2024-07-14 20:00','1',1,'World',2,'Africa',202,'Sub-Saharan Africa',18,'Southern Africa',710,'n','n','n','ZA','ZAF'),('Benin','Benin','/countries/africa/benin',null,'Benin','Benin','{}','2024-07-14 20:00',1,'2024-07-14 20:00',1,'n',null,null,'en',' std_checksum',1,null,'y','y',1,'2024-07-14 20:00','1',1,'World',2,'Africa',202,'Sub-Saharan Africa',11,'Western Africa',204,'y','n','n','BJ','BEN'),('Burkina Faso','Burkina Faso','/countries/africa/burkina%20faso',null,'Burkina Faso','Burkina Faso','{}','2024-07-14 20:00',1,'2024-07-14 20:00',1,'n',null,null,'en',' std_checksum',1,null,'y','y',1,'2024-07-14 20:00','1',1,'World',2,'Africa',202,'Sub-Saharan Africa',11,'Western Africa',854,'y','y','n','BF','BFA'),('Cabo Verde','Cabo Verde','/countries/africa/cabo%20verde',null,'Cabo Verde','Cabo Verde','{}','2024-07-14 20:00',1,'2024-07-14 20:00',1,'n',null,null,'en',' std_checksum',1,null,'y','y',1,'2024-07-14 20:00','1',1,'World',2,'Africa',202,'Sub-Saharan Africa',11,'Western Africa',132,'n','n','y','CV','CPV'),('Côte d''Ivoire','Côte d''Ivoire','/countries/africa/cote%20divoire',null,'Côte d''Ivoire','Côte d''Ivoire','{}','2024-07-14 20:00',1,'2024-07-14 20:00',1,'n',null,null,'en',' std_checksum',1,null,'y','y',1,'2024-07-14 20:00','1',1,'World',2,'Africa',202,'Sub-Saharan Africa',11,'Western Africa',384,'n','n','n','CI','CIV'),('Gambia','Gambia','/countries/africa/gambia',null,'Gambia','Gambia','{}','2024-07-14 20:00',1,'2024-07-14 20:00',1,'n',null,null,'en',' std_checksum',1,null,'y','y',1,'2024-07-14 20:00','1',1,'World',2,'Africa',202,'Sub-Saharan Africa',11,'Western Africa',270,'y','n','n','GM','GMB'),('Ghana','Ghana','/countries/africa/ghana',null,'Ghana','Ghana','{}','2024-07-14 20:00',1,'2024-07-14 20:00',1,'n',null,null,'en',' std_checksum',1,null,'y','y',1,'2024-07-14 20:00','1',1,'World',2,'Africa',202,'Sub-Saharan Africa',11,'Western Africa',288,'n','n','n','GH','GHA'),('Guinea','Guinea','/countries/africa/guinea',null,'Guinea','Guinea','{}','2024-07-14 20:00',1,'2024-07-14 20:00',1,'n',null,null,'en',' std_checksum',1,null,'y','y',1,'2024-07-14 20:00','1',1,'World',2,'Africa',202,'Sub-Saharan Africa',11,'Western Africa',324,'y','n','n','GN','GIN');
INSERT INTO osc_physrisk_backend.geo_country(std_name,std_name_display,std_slug,std_abbreviation,std_description_full,std_description_short,std_tags,std_datetime_utc_created,std_creator_user_id,std_datetime_utc_last_modified,std_last_modifier_user_id,std_is_deleted,std_deleter_user_id,std_datetime_utc_deleted,std_culture,std_checksum,std_seq_num,std_translated_from_id,std_is_active,std_is_published,std_publisher_id,std_datetime_utc_published,std_version,un_global_code,un_global_name,un_region_code,un_region_name,un_subregion_code,un_subregion_name,un_intermediateregion_code,un_intermediateregion_name,un_code_m49,un_is_ldc,un_is_lldc,un_is_sids,iso_code_alpha2,iso_code_alpha3) VALUES ('Guinea-Bissau','Guinea-Bissau','/countries/africa/guinea-bissau',null,'Guinea-Bissau','Guinea-Bissau','{}','2024-07-14 20:00',1,'2024-07-14 20:00',1,'n',null,null,'en',' std_checksum',1,null,'y','y',1,'2024-07-14 20:00','1',1,'World',2,'Africa',202,'Sub-Saharan Africa',11,'Western Africa',624,'y','n','y','GW','GNB'),('Liberia','Liberia','/countries/africa/liberia',null,'Liberia','Liberia','{}','2024-07-14 20:00',1,'2024-07-14 20:00',1,'n',null,null,'en',' std_checksum',1,null,'y','y',1,'2024-07-14 20:00','1',1,'World',2,'Africa',202,'Sub-Saharan Africa',11,'Western Africa',430,'y','n','n','LR','LBR'),('Mali','Mali','/countries/africa/mali',null,'Mali','Mali','{}','2024-07-14 20:00',1,'2024-07-14 20:00',1,'n',null,null,'en',' std_checksum',1,null,'y','y',1,'2024-07-14 20:00','1',1,'World',2,'Africa',202,'Sub-Saharan Africa',11,'Western Africa',466,'y','y','n','ML','MLI'),('Mauritania','Mauritania','/countries/africa/mauritania',null,'Mauritania','Mauritania','{}','2024-07-14 20:00',1,'2024-07-14 20:00',1,'n',null,null,'en',' std_checksum',1,null,'y','y',1,'2024-07-14 20:00','1',1,'World',2,'Africa',202,'Sub-Saharan Africa',11,'Western Africa',478,'y','n','n','MR','MRT'),('Niger','Niger','/countries/africa/niger',null,'Niger','Niger','{}','2024-07-14 20:00',1,'2024-07-14 20:00',1,'n',null,null,'en',' std_checksum',1,null,'y','y',1,'2024-07-14 20:00','1',1,'World',2,'Africa',202,'Sub-Saharan Africa',11,'Western Africa',562,'y','y','n','NE','NER'),('Nigeria','Nigeria','/countries/africa/nigeria',null,'Nigeria','Nigeria','{}','2024-07-14 20:00',1,'2024-07-14 20:00',1,'n',null,null,'en',' std_checksum',1,null,'y','y',1,'2024-07-14 20:00','1',1,'World',2,'Africa',202,'Sub-Saharan Africa',11,'Western Africa',566,'n','n','n','NG','NGA'),('Saint Helena','Saint Helena','/countries/africa/saint%20helena',null,'Saint Helena','Saint Helena','{}','2024-07-14 20:00',1,'2024-07-14 20:00',1,'n',null,null,'en',' std_checksum',1,null,'y','y',1,'2024-07-14 20:00','1',1,'World',2,'Africa',202,'Sub-Saharan Africa',11,'Western Africa',654,'n','n','n','SH','SHN'),('Senegal','Senegal','/countries/africa/senegal',null,'Senegal','Senegal','{}','2024-07-14 20:00',1,'2024-07-14 20:00',1,'n',null,null,'en',' std_checksum',1,null,'y','y',1,'2024-07-14 20:00','1',1,'World',2,'Africa',202,'Sub-Saharan Africa',11,'Western Africa',686,'y','n','n','SN','SEN'),('Sierra Leone','Sierra Leone','/countries/africa/sierra%20leone',null,'Sierra Leone','Sierra Leone','{}','2024-07-14 20:00',1,'2024-07-14 20:00',1,'n',null,null,'en',' std_checksum',1,null,'y','y',1,'2024-07-14 20:00','1',1,'World',2,'Africa',202,'Sub-Saharan Africa',11,'Western Africa',694,'y','n','n','SL','SLE'),('Togo','Togo','/countries/africa/togo',null,'Togo','Togo','{}','2024-07-14 20:00',1,'2024-07-14 20:00',1,'n',null,null,'en',' std_checksum',1,null,'y','y',1,'2024-07-14 20:00','1',1,'World',2,'Africa',202,'Sub-Saharan Africa',11,'Western Africa',768,'y','n','n','TG','TGO'),('Anguilla','Anguilla','/countries/americas/anguilla',null,'Anguilla','Anguilla','{}','2024-07-14 20:00',1,'2024-07-14 20:00',1,'n',null,null,'en',' std_checksum',1,null,'y','y',1,'2024-07-14 20:00','1',1,'World',19,'Americas',419,'Latin America and the Caribbean',29,'Caribbean',660,'n','n','y','AI','AIA'),('Antigua and Barbuda','Antigua and Barbuda','/countries/americas/antigua%20and%20barbuda',null,'Antigua and Barbuda','Antigua and Barbuda','{}','2024-07-14 20:00',1,'2024-07-14 20:00',1,'n',null,null,'en',' std_checksum',1,null,'y','y',1,'2024-07-14 20:00','1',1,'World',19,'Americas',419,'Latin America and the Caribbean',29,'Caribbean',28,'n','n','y','AG','ATG'),('Aruba','Aruba','/countries/americas/aruba',null,'Aruba','Aruba','{}','2024-07-14 20:00',1,'2024-07-14 20:00',1,'n',null,null,'en',' std_checksum',1,null,'y','y',1,'2024-07-14 20:00','1',1,'World',19,'Americas',419,'Latin America and the Caribbean',29,'Caribbean',533,'n','n','y','AW','ABW'),('Bahamas','Bahamas','/countries/americas/bahamas',null,'Bahamas','Bahamas','{}','2024-07-14 20:00',1,'2024-07-14 20:00',1,'n',null,null,'en',' std_checksum',1,null,'y','y',1,'2024-07-14 20:00','1',1,'World',19,'Americas',419,'Latin America and the Caribbean',29,'Caribbean',44,'n','n','y','BS','BHS'),('Barbados','Barbados','/countries/americas/barbados',null,'Barbados','Barbados','{}','2024-07-14 20:00',1,'2024-07-14 20:00',1,'n',null,null,'en',' std_checksum',1,null,'y','y',1,'2024-07-14 20:00','1',1,'World',19,'Americas',419,'Latin America and the Caribbean',29,'Caribbean',52,'n','n','y','BB','BRB'),('Bonaire, Sint Eustatius and Saba','Bonaire, Sint Eustatius and Saba','/countries/americas/bonaire,%20sint%20eustatius%20and%20saba',null,'Bonaire, Sint Eustatius and Saba','Bonaire, Sint Eustatius and Saba','{}','2024-07-14 20:00',1,'2024-07-14 20:00',1,'n',null,null,'en',' std_checksum',1,null,'y','y',1,'2024-07-14 20:00','1',1,'World',19,'Americas',419,'Latin America and the Caribbean',29,'Caribbean',535,'n','n','y','BQ','BES'),('British Virgin Islands','British Virgin Islands','/countries/americas/british%20virgin%20islands',null,'British Virgin Islands','British Virgin Islands','{}','2024-07-14 20:00',1,'2024-07-14 20:00',1,'n',null,null,'en',' std_checksum',1,null,'y','y',1,'2024-07-14 20:00','1',1,'World',19,'Americas',419,'Latin America and the Caribbean',29,'Caribbean',92,'n','n','y','VG','VGB'),('Cayman Islands','Cayman Islands','/countries/americas/cayman%20islands',null,'Cayman Islands','Cayman Islands','{}','2024-07-14 20:00',1,'2024-07-14 20:00',1,'n',null,null,'en',' std_checksum',1,null,'y','y',1,'2024-07-14 20:00','1',1,'World',19,'Americas',419,'Latin America and the Caribbean',29,'Caribbean',136,'n','n','n','KY','CYM'),('Cuba','Cuba','/countries/americas/cuba',null,'Cuba','Cuba','{}','2024-07-14 20:00',1,'2024-07-14 20:00',1,'n',null,null,'en',' std_checksum',1,null,'y','y',1,'2024-07-14 20:00','1',1,'World',19,'Americas',419,'Latin America and the Caribbean',29,'Caribbean',192,'n','n','y','CU','CUB'),('Cura?ao','Cura?ao','/countries/americas/cura?ao',null,'Cura?ao','Cura?ao','{}','2024-07-14 20:00',1,'2024-07-14 20:00',1,'n',null,null,'en',' std_checksum',1,null,'y','y',1,'2024-07-14 20:00','1',1,'World',19,'Americas',419,'Latin America and the Caribbean',29,'Caribbean',531,'n','n','y','CW','CUW'),('Dominica','Dominica','/countries/americas/dominica',null,'Dominica','Dominica','{}','2024-07-14 20:00',1,'2024-07-14 20:00',1,'n',null,null,'en',' std_checksum',1,null,'y','y',1,'2024-07-14 20:00','1',1,'World',19,'Americas',419,'Latin America and the Caribbean',29,'Caribbean',212,'n','n','y','DM','DMA'),('Dominican Republic','Dominican Republic','/countries/americas/dominican%20republic',null,'Dominican Republic','Dominican Republic','{}','2024-07-14 20:00',1,'2024-07-14 20:00',1,'n',null,null,'en',' std_checksum',1,null,'y','y',1,'2024-07-14 20:00','1',1,'World',19,'Americas',419,'Latin America and the Caribbean',29,'Caribbean',214,'n','n','y','DO','DOM'),('Grenada','Grenada','/countries/americas/grenada',null,'Grenada','Grenada','{}','2024-07-14 20:00',1,'2024-07-14 20:00',1,'n',null,null,'en',' std_checksum',1,null,'y','y',1,'2024-07-14 20:00','1',1,'World',19,'Americas',419,'Latin America and the Caribbean',29,'Caribbean',308,'n','n','y','GD','GRD'),('Guadeloupe','Guadeloupe','/countries/americas/guadeloupe',null,'Guadeloupe','Guadeloupe','{}','2024-07-14 20:00',1,'2024-07-14 20:00',1,'n',null,null,'en',' std_checksum',1,null,'y','y',1,'2024-07-14 20:00','1',1,'World',19,'Americas',419,'Latin America and the Caribbean',29,'Caribbean',312,'n','n','n','GP','GLP'),('Haiti','Haiti','/countries/americas/haiti',null,'Haiti','Haiti','{}','2024-07-14 20:00',1,'2024-07-14 20:00',1,'n',null,null,'en',' std_checksum',1,null,'y','y',1,'2024-07-14 20:00','1',1,'World',19,'Americas',419,'Latin America and the Caribbean',29,'Caribbean',332,'y','n','y','HT','HTI');
INSERT INTO osc_physrisk_backend.geo_country(std_name,std_name_display,std_slug,std_abbreviation,std_description_full,std_description_short,std_tags,std_datetime_utc_created,std_creator_user_id,std_datetime_utc_last_modified,std_last_modifier_user_id,std_is_deleted,std_deleter_user_id,std_datetime_utc_deleted,std_culture,std_checksum,std_seq_num,std_translated_from_id,std_is_active,std_is_published,std_publisher_id,std_datetime_utc_published,std_version,un_global_code,un_global_name,un_region_code,un_region_name,un_subregion_code,un_subregion_name,un_intermediateregion_code,un_intermediateregion_name,un_code_m49,un_is_ldc,un_is_lldc,un_is_sids,iso_code_alpha2,iso_code_alpha3) VALUES ('Jamaica','Jamaica','/countries/americas/jamaica',null,'Jamaica','Jamaica','{}','2024-07-14 20:00',1,'2024-07-14 20:00',1,'n',null,null,'en',' std_checksum',1,null,'y','y',1,'2024-07-14 20:00','1',1,'World',19,'Americas',419,'Latin America and the Caribbean',29,'Caribbean',388,'n','n','y','JM','JAM'),('Martinique','Martinique','/countries/americas/martinique',null,'Martinique','Martinique','{}','2024-07-14 20:00',1,'2024-07-14 20:00',1,'n',null,null,'en',' std_checksum',1,null,'y','y',1,'2024-07-14 20:00','1',1,'World',19,'Americas',419,'Latin America and the Caribbean',29,'Caribbean',474,'n','n','n','MQ','MTQ'),('Montserrat','Montserrat','/countries/americas/montserrat',null,'Montserrat','Montserrat','{}','2024-07-14 20:00',1,'2024-07-14 20:00',1,'n',null,null,'en',' std_checksum',1,null,'y','y',1,'2024-07-14 20:00','1',1,'World',19,'Americas',419,'Latin America and the Caribbean',29,'Caribbean',500,'n','n','y','MS','MSR'),('Puerto Rico','Puerto Rico','/countries/americas/puerto%20rico',null,'Puerto Rico','Puerto Rico','{}','2024-07-14 20:00',1,'2024-07-14 20:00',1,'n',null,null,'en',' std_checksum',1,null,'y','y',1,'2024-07-14 20:00','1',1,'World',19,'Americas',419,'Latin America and the Caribbean',29,'Caribbean',630,'n','n','y','PR','PRI'),('Saint Barthélemy','Saint Barthélemy','/countries/americas/saint%20barth?lemy',null,'Saint Barthélemy','Saint Barthélemy','{}','2024-07-14 20:00',1,'2024-07-14 20:00',1,'n',null,null,'en',' std_checksum',1,null,'y','y',1,'2024-07-14 20:00','1',1,'World',19,'Americas',419,'Latin America and the Caribbean',29,'Caribbean',652,'n','n','n','BL','BLM'),('Saint Kitts and Nevis','Saint Kitts and Nevis','/countries/americas/saint%20kitts%20and%20nevis',null,'Saint Kitts and Nevis','Saint Kitts and Nevis','{}','2024-07-14 20:00',1,'2024-07-14 20:00',1,'n',null,null,'en',' std_checksum',1,null,'y','y',1,'2024-07-14 20:00','1',1,'World',19,'Americas',419,'Latin America and the Caribbean',29,'Caribbean',659,'n','n','y','KN','KNA'),('Saint Lucia','Saint Lucia','/countries/americas/saint%20lucia',null,'Saint Lucia','Saint Lucia','{}','2024-07-14 20:00',1,'2024-07-14 20:00',1,'n',null,null,'en',' std_checksum',1,null,'y','y',1,'2024-07-14 20:00','1',1,'World',19,'Americas',419,'Latin America and the Caribbean',29,'Caribbean',662,'n','n','y','LC','LCA'),('Saint Martin (French Part)','Saint Martin (French Part)','/countries/americas/saint%20martin%20&#40;french%20part&#41;',null,'Saint Martin (French Part)','Saint Martin (French Part)','{}','2024-07-14 20:00',1,'2024-07-14 20:00',1,'n',null,null,'en',' std_checksum',1,null,'y','y',1,'2024-07-14 20:00','1',1,'World',19,'Americas',419,'Latin America and the Caribbean',29,'Caribbean',663,'n','n','n','MF','MAF'),('Saint Vincent and the Grenadines','Saint Vincent and the Grenadines','/countries/americas/saint%20vincent%20and%20the%20grenadines',null,'Saint Vincent and the Grenadines','Saint Vincent and the Grenadines','{}','2024-07-14 20:00',1,'2024-07-14 20:00',1,'n',null,null,'en',' std_checksum',1,null,'y','y',1,'2024-07-14 20:00','1',1,'World',19,'Americas',419,'Latin America and the Caribbean',29,'Caribbean',670,'n','n','y','VC','VCT'),('Sint Maarten (Dutch part)','Sint Maarten (Dutch part)','/countries/americas/sint%20maarten%20&#40;dutch%20part&#41;',null,'Sint Maarten (Dutch part)','Sint Maarten (Dutch part)','{}','2024-07-14 20:00',1,'2024-07-14 20:00',1,'n',null,null,'en',' std_checksum',1,null,'y','y',1,'2024-07-14 20:00','1',1,'World',19,'Americas',419,'Latin America and the Caribbean',29,'Caribbean',534,'n','n','y','SX','SXM'),('Trinidad and Tobago','Trinidad and Tobago','/countries/americas/trinidad%20and%20tobago',null,'Trinidad and Tobago','Trinidad and Tobago','{}','2024-07-14 20:00',1,'2024-07-14 20:00',1,'n',null,null,'en',' std_checksum',1,null,'y','y',1,'2024-07-14 20:00','1',1,'World',19,'Americas',419,'Latin America and the Caribbean',29,'Caribbean',780,'n','n','y','TT','TTO'),('Turks and Caicos Islands','Turks and Caicos Islands','/countries/americas/turks%20and%20caicos%20islands',null,'Turks and Caicos Islands','Turks and Caicos Islands','{}','2024-07-14 20:00',1,'2024-07-14 20:00',1,'n',null,null,'en',' std_checksum',1,null,'y','y',1,'2024-07-14 20:00','1',1,'World',19,'Americas',419,'Latin America and the Caribbean',29,'Caribbean',796,'n','n','n','TC','TCA'),('United States Virgin Islands','United States Virgin Islands','/countries/americas/united%20states%20virgin%20islands',null,'United States Virgin Islands','United States Virgin Islands','{}','2024-07-14 20:00',1,'2024-07-14 20:00',1,'n',null,null,'en',' std_checksum',1,null,'y','y',1,'2024-07-14 20:00','1',1,'World',19,'Americas',419,'Latin America and the Caribbean',29,'Caribbean',850,'n','n','y','VI','VIR'),('Belize','Belize','/countries/americas/belize',null,'Belize','Belize','{}','2024-07-14 20:00',1,'2024-07-14 20:00',1,'n',null,null,'en',' std_checksum',1,null,'y','y',1,'2024-07-14 20:00','1',1,'World',19,'Americas',419,'Latin America and the Caribbean',13,'Central America',84,'n','n','y','BZ','BLZ'),('Costa Rica','Costa Rica','/countries/americas/costa%20rica',null,'Costa Rica','Costa Rica','{}','2024-07-14 20:00',1,'2024-07-14 20:00',1,'n',null,null,'en',' std_checksum',1,null,'y','y',1,'2024-07-14 20:00','1',1,'World',19,'Americas',419,'Latin America and the Caribbean',13,'Central America',188,'n','n','n','CR','CRI'),('El Salvador','El Salvador','/countries/americas/el%20salvador',null,'El Salvador','El Salvador','{}','2024-07-14 20:00',1,'2024-07-14 20:00',1,'n',null,null,'en',' std_checksum',1,null,'y','y',1,'2024-07-14 20:00','1',1,'World',19,'Americas',419,'Latin America and the Caribbean',13,'Central America',222,'n','n','n','SV','SLV'),('Guatemala','Guatemala','/countries/americas/guatemala',null,'Guatemala','Guatemala','{}','2024-07-14 20:00',1,'2024-07-14 20:00',1,'n',null,null,'en',' std_checksum',1,null,'y','y',1,'2024-07-14 20:00','1',1,'World',19,'Americas',419,'Latin America and the Caribbean',13,'Central America',320,'n','n','n','GT','GTM'),('Honduras','Honduras','/countries/americas/honduras',null,'Honduras','Honduras','{}','2024-07-14 20:00',1,'2024-07-14 20:00',1,'n',null,null,'en',' std_checksum',1,null,'y','y',1,'2024-07-14 20:00','1',1,'World',19,'Americas',419,'Latin America and the Caribbean',13,'Central America',340,'n','n','n','HN','HND'),('Mexico','Mexico','/countries/americas/mexico',null,'Mexico','Mexico','{}','2024-07-14 20:00',1,'2024-07-14 20:00',1,'n',null,null,'en',' std_checksum',1,null,'y','y',1,'2024-07-14 20:00','1',1,'World',19,'Americas',419,'Latin America and the Caribbean',13,'Central America',484,'n','n','n','MX','MEX'),('Nicaragua','Nicaragua','/countries/americas/nicaragua',null,'Nicaragua','Nicaragua','{}','2024-07-14 20:00',1,'2024-07-14 20:00',1,'n',null,null,'en',' std_checksum',1,null,'y','y',1,'2024-07-14 20:00','1',1,'World',19,'Americas',419,'Latin America and the Caribbean',13,'Central America',558,'n','n','n','NI','NIC'),('Panama','Panama','/countries/americas/panama',null,'Panama','Panama','{}','2024-07-14 20:00',1,'2024-07-14 20:00',1,'n',null,null,'en',' std_checksum',1,null,'y','y',1,'2024-07-14 20:00','1',1,'World',19,'Americas',419,'Latin America and the Caribbean',13,'Central America',591,'n','n','n','PA','PAN'),('Argentina','Argentina','/countries/americas/argentina',null,'Argentina','Argentina','{}','2024-07-14 20:00',1,'2024-07-14 20:00',1,'n',null,null,'en',' std_checksum',1,null,'y','y',1,'2024-07-14 20:00','1',1,'World',19,'Americas',419,'Latin America and the Caribbean',5,'South America',32,'n','n','n','AR','ARG'),('Bolivia (Plurinational State of)','Bolivia (Plurinational State of)','/countries/americas/bolivia%20&#40;plurinational%20state%20of&#41;',null,'Bolivia (Plurinational State of)','Bolivia (Plurinational State of)','{}','2024-07-14 20:00',1,'2024-07-14 20:00',1,'n',null,null,'en',' std_checksum',1,null,'y','y',1,'2024-07-14 20:00','1',1,'World',19,'Americas',419,'Latin America and the Caribbean',5,'South America',68,'n','y','n','BO','BOL'),('Bouvet Island','Bouvet Island','/countries/americas/bouvet%20island',null,'Bouvet Island','Bouvet Island','{}','2024-07-14 20:00',1,'2024-07-14 20:00',1,'n',null,null,'en',' std_checksum',1,null,'y','y',1,'2024-07-14 20:00','1',1,'World',19,'Americas',419,'Latin America and the Caribbean',5,'South America',74,'n','n','n','BV','BVT'),('Brazil','Brazil','/countries/americas/brazil',null,'Brazil','Brazil','{}','2024-07-14 20:00',1,'2024-07-14 20:00',1,'n',null,null,'en',' std_checksum',1,null,'y','y',1,'2024-07-14 20:00','1',1,'World',19,'Americas',419,'Latin America and the Caribbean',5,'South America',76,'n','n','n','BR','BRA');
INSERT INTO osc_physrisk_backend.geo_country(std_name,std_name_display,std_slug,std_abbreviation,std_description_full,std_description_short,std_tags,std_datetime_utc_created,std_creator_user_id,std_datetime_utc_last_modified,std_last_modifier_user_id,std_is_deleted,std_deleter_user_id,std_datetime_utc_deleted,std_culture,std_checksum,std_seq_num,std_translated_from_id,std_is_active,std_is_published,std_publisher_id,std_datetime_utc_published,std_version,un_global_code,un_global_name,un_region_code,un_region_name,un_subregion_code,un_subregion_name,un_intermediateregion_code,un_intermediateregion_name,un_code_m49,un_is_ldc,un_is_lldc,un_is_sids,iso_code_alpha2,iso_code_alpha3) VALUES ('Chile','Chile','/countries/americas/chile',null,'Chile','Chile','{}','2024-07-14 20:00',1,'2024-07-14 20:00',1,'n',null,null,'en',' std_checksum',1,null,'y','y',1,'2024-07-14 20:00','1',1,'World',19,'Americas',419,'Latin America and the Caribbean',5,'South America',152,'n','n','n','CL','CHL'),('Colombia','Colombia','/countries/americas/colombia',null,'Colombia','Colombia','{}','2024-07-14 20:00',1,'2024-07-14 20:00',1,'n',null,null,'en',' std_checksum',1,null,'y','y',1,'2024-07-14 20:00','1',1,'World',19,'Americas',419,'Latin America and the Caribbean',5,'South America',170,'n','n','n','CO','COL'),('Ecuador','Ecuador','/countries/americas/ecuador',null,'Ecuador','Ecuador','{}','2024-07-14 20:00',1,'2024-07-14 20:00',1,'n',null,null,'en',' std_checksum',1,null,'y','y',1,'2024-07-14 20:00','1',1,'World',19,'Americas',419,'Latin America and the Caribbean',5,'South America',218,'n','n','n','EC','ECU'),('Falkland Islands (Malvinas)','Falkland Islands (Malvinas)','/countries/americas/falkland%20islands%20&#40;malvinas&#41;',null,'Falkland Islands (Malvinas)','Falkland Islands (Malvinas)','{}','2024-07-14 20:00',1,'2024-07-14 20:00',1,'n',null,null,'en',' std_checksum',1,null,'y','y',1,'2024-07-14 20:00','1',1,'World',19,'Americas',419,'Latin America and the Caribbean',5,'South America',238,'n','n','n','FK','FLK'),('French Guiana','French Guiana','/countries/americas/french%20guiana',null,'French Guiana','French Guiana','{}','2024-07-14 20:00',1,'2024-07-14 20:00',1,'n',null,null,'en',' std_checksum',1,null,'y','y',1,'2024-07-14 20:00','1',1,'World',19,'Americas',419,'Latin America and the Caribbean',5,'South America',254,'n','n','n','GF','GUF'),('Guyana','Guyana','/countries/americas/guyana',null,'Guyana','Guyana','{}','2024-07-14 20:00',1,'2024-07-14 20:00',1,'n',null,null,'en',' std_checksum',1,null,'y','y',1,'2024-07-14 20:00','1',1,'World',19,'Americas',419,'Latin America and the Caribbean',5,'South America',328,'n','n','y','GY','GUY'),('Paraguay','Paraguay','/countries/americas/paraguay',null,'Paraguay','Paraguay','{}','2024-07-14 20:00',1,'2024-07-14 20:00',1,'n',null,null,'en',' std_checksum',1,null,'y','y',1,'2024-07-14 20:00','1',1,'World',19,'Americas',419,'Latin America and the Caribbean',5,'South America',600,'n','y','n','PY','PRY'),('Peru','Peru','/countries/americas/peru',null,'Peru','Peru','{}','2024-07-14 20:00',1,'2024-07-14 20:00',1,'n',null,null,'en',' std_checksum',1,null,'y','y',1,'2024-07-14 20:00','1',1,'World',19,'Americas',419,'Latin America and the Caribbean',5,'South America',604,'n','n','n','PE','PER'),('South Georgia and the South Sandwich Islands','South Georgia and the South Sandwich Islands','/countries/americas/south%20georgia%20and%20the%20south%20sandwich%20islands',null,'South Georgia and the South Sandwich Islands','South Georgia and the South Sandwich Islands','{}','2024-07-14 20:00',1,'2024-07-14 20:00',1,'n',null,null,'en',' std_checksum',1,null,'y','y',1,'2024-07-14 20:00','1',1,'World',19,'Americas',419,'Latin America and the Caribbean',5,'South America',239,'n','n','n','GS','SGS'),('Suriname','Suriname','/countries/americas/suriname',null,'Suriname','Suriname','{}','2024-07-14 20:00',1,'2024-07-14 20:00',1,'n',null,null,'en',' std_checksum',1,null,'y','y',1,'2024-07-14 20:00','1',1,'World',19,'Americas',419,'Latin America and the Caribbean',5,'South America',740,'n','n','y','SR','SUR'),('Uruguay','Uruguay','/countries/americas/uruguay',null,'Uruguay','Uruguay','{}','2024-07-14 20:00',1,'2024-07-14 20:00',1,'n',null,null,'en',' std_checksum',1,null,'y','y',1,'2024-07-14 20:00','1',1,'World',19,'Americas',419,'Latin America and the Caribbean',5,'South America',858,'n','n','n','UY','URY'),('Venezuela (Bolivarian Republic of)','Venezuela (Bolivarian Republic of)','/countries/americas/venezuela%20&#40;bolivarian%20republic%20of&#41;',null,'Venezuela (Bolivarian Republic of)','Venezuela (Bolivarian Republic of)','{}','2024-07-14 20:00',1,'2024-07-14 20:00',1,'n',null,null,'en',' std_checksum',1,null,'y','y',1,'2024-07-14 20:00','1',1,'World',19,'Americas',419,'Latin America and the Caribbean',5,'South America',862,'n','n','n','VE','VEN'),('Bermuda','Bermuda','/countries/americas/bermuda',null,'Bermuda','Bermuda','{}','2024-07-14 20:00',1,'2024-07-14 20:00',1,'n',null,null,'en',' std_checksum',1,null,'y','y',1,'2024-07-14 20:00','1',1,'World',19,'Americas',21,'Northern America',null,null,60,'n','n','n','BM','BMU'),('Canada','Canada','/countries/americas/canada',null,'Canada','Canada','{}','2024-07-14 20:00',1,'2024-07-14 20:00',1,'n',null,null,'en',' std_checksum',1,null,'y','y',1,'2024-07-14 20:00','1',1,'World',19,'Americas',21,'Northern America',null,null,124,'n','n','n','CA','CAN'),('Greenland','Greenland','/countries/americas/greenland',null,'Greenland','Greenland','{}','2024-07-14 20:00',1,'2024-07-14 20:00',1,'n',null,null,'en',' std_checksum',1,null,'y','y',1,'2024-07-14 20:00','1',1,'World',19,'Americas',21,'Northern America',null,null,304,'n','n','n','GL','GRL'),('Saint Pierre and Miquelon','Saint Pierre and Miquelon','/countries/americas/saint%20pierre%20and%20miquelon',null,'Saint Pierre and Miquelon','Saint Pierre and Miquelon','{}','2024-07-14 20:00',1,'2024-07-14 20:00',1,'n',null,null,'en',' std_checksum',1,null,'y','y',1,'2024-07-14 20:00','1',1,'World',19,'Americas',21,'Northern America',null,null,666,'n','n','n','PM','SPM'),('United States of America','United States of America','/countries/americas/united%20states%20of%20america',null,'United States of America','United States of America','{}','2024-07-14 20:00',1,'2024-07-14 20:00',1,'n',null,null,'en',' std_checksum',1,null,'y','y',1,'2024-07-14 20:00','1',1,'World',19,'Americas',21,'Northern America',null,null,840,'n','n','n','US','USA'),('Antarctica','Antarctica','/countries/antarctica',null,'Antarctica','Antarctica','{}','2024-07-14 20:00',1,'2024-07-14 20:00',1,'n',null,null,'en',' std_checksum',1,null,'y','y',1,'2024-07-14 20:00','1',1,'World',0,'Antarctica',0,'Antarctica',null,'Antarctica',10,'n','n','n','AQ','ATA'),('Kazakhstan','Kazakhstan','/countries/asia/kazakhstan',null,'Kazakhstan','Kazakhstan','{}','2024-07-14 20:00',1,'2024-07-14 20:00',1,'n',null,null,'en',' std_checksum',1,null,'y','y',1,'2024-07-14 20:00','1',1,'World',142,'Asia',143,'Central Asia',null,null,398,'n','y','n','KZ','KAZ'),('Kyrgyzstan','Kyrgyzstan','/countries/asia/kyrgyzstan',null,'Kyrgyzstan','Kyrgyzstan','{}','2024-07-14 20:00',1,'2024-07-14 20:00',1,'n',null,null,'en',' std_checksum',1,null,'y','y',1,'2024-07-14 20:00','1',1,'World',142,'Asia',143,'Central Asia',null,null,417,'n','y','n','KG','KGZ'),('Tajikistan','Tajikistan','/countries/asia/tajikistan',null,'Tajikistan','Tajikistan','{}','2024-07-14 20:00',1,'2024-07-14 20:00',1,'n',null,null,'en',' std_checksum',1,null,'y','y',1,'2024-07-14 20:00','1',1,'World',142,'Asia',143,'Central Asia',null,null,762,'n','y','n','TJ','TJK'),('Turkmenistan','Turkmenistan','/countries/asia/turkmenistan',null,'Turkmenistan','Turkmenistan','{}','2024-07-14 20:00',1,'2024-07-14 20:00',1,'n',null,null,'en',' std_checksum',1,null,'y','y',1,'2024-07-14 20:00','1',1,'World',142,'Asia',143,'Central Asia',null,null,795,'n','y','n','TM','TKM'),('Uzbekistan','Uzbekistan','/countries/asia/uzbekistan',null,'Uzbekistan','Uzbekistan','{}','2024-07-14 20:00',1,'2024-07-14 20:00',1,'n',null,null,'en',' std_checksum',1,null,'y','y',1,'2024-07-14 20:00','1',1,'World',142,'Asia',143,'Central Asia',null,null,860,'n','y','n','UZ','UZB'),('China','China','/countries/asia/china',null,'China','China','{}','2024-07-14 20:00',1,'2024-07-14 20:00',1,'n',null,null,'en',' std_checksum',1,null,'y','y',1,'2024-07-14 20:00','1',1,'World',142,'Asia',30,'Eastern Asia',null,null,156,'n','n','n','CN','CHN'),('China, Hong Kong Special Administrative Region','China, Hong Kong Special Administrative Region','/countries/asia/china,%20hong%20kong%20special%20administrative%20region',null,'China, Hong Kong Special Administrative Region','China, Hong Kong Special Administrative Region','{}','2024-07-14 20:00',1,'2024-07-14 20:00',1,'n',null,null,'en',' std_checksum',1,null,'y','y',1,'2024-07-14 20:00','1',1,'World',142,'Asia',30,'Eastern Asia',null,null,344,'n','n','n','HK','HKG');
INSERT INTO osc_physrisk_backend.geo_country(std_name,std_name_display,std_slug,std_abbreviation,std_description_full,std_description_short,std_tags,std_datetime_utc_created,std_creator_user_id,std_datetime_utc_last_modified,std_last_modifier_user_id,std_is_deleted,std_deleter_user_id,std_datetime_utc_deleted,std_culture,std_checksum,std_seq_num,std_translated_from_id,std_is_active,std_is_published,std_publisher_id,std_datetime_utc_published,std_version,un_global_code,un_global_name,un_region_code,un_region_name,un_subregion_code,un_subregion_name,un_intermediateregion_code,un_intermediateregion_name,un_code_m49,un_is_ldc,un_is_lldc,un_is_sids,iso_code_alpha2,iso_code_alpha3) VALUES ('China, Macao Special Administrative Region','China, Macao Special Administrative Region','/countries/asia/china,%20macao%20special%20administrative%20region',null,'China, Macao Special Administrative Region','China, Macao Special Administrative Region','{}','2024-07-14 20:00',1,'2024-07-14 20:00',1,'n',null,null,'en',' std_checksum',1,null,'y','y',1,'2024-07-14 20:00','1',1,'World',142,'Asia',30,'Eastern Asia',null,null,446,'n','n','n','MO','MAC'),('Democratic People''s Republic of Korea','Democratic People''s Republic of Korea','/countries/asia/democratic%20peoples%20republic%20of%20korea',null,'Democratic People''s Republic of Korea','Democratic People''s Republic of Korea','{}','2024-07-14 20:00',1,'2024-07-14 20:00',1,'n',null,null,'en',' std_checksum',1,null,'y','y',1,'2024-07-14 20:00','1',1,'World',142,'Asia',30,'Eastern Asia',null,null,408,'n','n','n','KP','PRK'),('Japan','Japan','/countries/asia/japan',null,'Japan','Japan','{}','2024-07-14 20:00',1,'2024-07-14 20:00',1,'n',null,null,'en',' std_checksum',1,null,'y','y',1,'2024-07-14 20:00','1',1,'World',142,'Asia',30,'Eastern Asia',null,null,392,'n','n','n','JP','JPN'),('Mongolia','Mongolia','/countries/asia/mongolia',null,'Mongolia','Mongolia','{}','2024-07-14 20:00',1,'2024-07-14 20:00',1,'n',null,null,'en',' std_checksum',1,null,'y','y',1,'2024-07-14 20:00','1',1,'World',142,'Asia',30,'Eastern Asia',null,null,496,'n','y','n','MN','MNG'),('Republic of Korea','Republic of Korea','/countries/asia/republic%20of%20korea',null,'Republic of Korea','Republic of Korea','{}','2024-07-14 20:00',1,'2024-07-14 20:00',1,'n',null,null,'en',' std_checksum',1,null,'y','y',1,'2024-07-14 20:00','1',1,'World',142,'Asia',30,'Eastern Asia',null,null,410,'n','n','n','KR','KOR'),('Brunei Darussalam','Brunei Darussalam','/countries/asia/brunei%20darussalam',null,'Brunei Darussalam','Brunei Darussalam','{}','2024-07-14 20:00',1,'2024-07-14 20:00',1,'n',null,null,'en',' std_checksum',1,null,'y','y',1,'2024-07-14 20:00','1',1,'World',142,'Asia',35,'South-eastern Asia',null,null,96,'n','n','n','BN','BRN'),('Cambodia','Cambodia','/countries/asia/cambodia',null,'Cambodia','Cambodia','{}','2024-07-14 20:00',1,'2024-07-14 20:00',1,'n',null,null,'en',' std_checksum',1,null,'y','y',1,'2024-07-14 20:00','1',1,'World',142,'Asia',35,'South-eastern Asia',null,null,116,'y','n','n','KH','KHM'),('Indonesia','Indonesia','/countries/asia/indonesia',null,'Indonesia','Indonesia','{}','2024-07-14 20:00',1,'2024-07-14 20:00',1,'n',null,null,'en',' std_checksum',1,null,'y','y',1,'2024-07-14 20:00','1',1,'World',142,'Asia',35,'South-eastern Asia',null,null,360,'n','n','n','ID','IDN'),('Lao People''s Democratic Republic','Lao People''s Democratic Republic','/countries/asia/lao%20peoples%20democratic%20republic',null,'Lao People''s Democratic Republic','Lao People''s Democratic Republic','{}','2024-07-14 20:00',1,'2024-07-14 20:00',1,'n',null,null,'en',' std_checksum',1,null,'y','y',1,'2024-07-14 20:00','1',1,'World',142,'Asia',35,'South-eastern Asia',null,null,418,'y','y','n','LA','LAO'),('Malaysia','Malaysia','/countries/asia/malaysia',null,'Malaysia','Malaysia','{}','2024-07-14 20:00',1,'2024-07-14 20:00',1,'n',null,null,'en',' std_checksum',1,null,'y','y',1,'2024-07-14 20:00','1',1,'World',142,'Asia',35,'South-eastern Asia',null,null,458,'n','n','n','MY','MYS'),('Myanmar','Myanmar','/countries/asia/myanmar',null,'Myanmar','Myanmar','{}','2024-07-14 20:00',1,'2024-07-14 20:00',1,'n',null,null,'en',' std_checksum',1,null,'y','y',1,'2024-07-14 20:00','1',1,'World',142,'Asia',35,'South-eastern Asia',null,null,104,'y','n','n','MM','MMR'),('Philippines','Philippines','/countries/asia/philippines',null,'Philippines','Philippines','{}','2024-07-14 20:00',1,'2024-07-14 20:00',1,'n',null,null,'en',' std_checksum',1,null,'y','y',1,'2024-07-14 20:00','1',1,'World',142,'Asia',35,'South-eastern Asia',null,null,608,'n','n','n','PH','PHL'),('Singapore','Singapore','/countries/asia/singapore',null,'Singapore','Singapore','{}','2024-07-14 20:00',1,'2024-07-14 20:00',1,'n',null,null,'en',' std_checksum',1,null,'y','y',1,'2024-07-14 20:00','1',1,'World',142,'Asia',35,'South-eastern Asia',null,null,702,'n','n','y','SG','SGP'),('Thailand','Thailand','/countries/asia/thailand',null,'Thailand','Thailand','{}','2024-07-14 20:00',1,'2024-07-14 20:00',1,'n',null,null,'en',' std_checksum',1,null,'y','y',1,'2024-07-14 20:00','1',1,'World',142,'Asia',35,'South-eastern Asia',null,null,764,'n','n','n','TH','THA'),('Timor-Leste','Timor-Leste','/countries/asia/timor-leste',null,'Timor-Leste','Timor-Leste','{}','2024-07-14 20:00',1,'2024-07-14 20:00',1,'n',null,null,'en',' std_checksum',1,null,'y','y',1,'2024-07-14 20:00','1',1,'World',142,'Asia',35,'South-eastern Asia',null,null,626,'y','n','y','TL','TLS'),('Viet Nam','Viet Nam','/countries/asia/viet%20nam',null,'Viet Nam','Viet Nam','{}','2024-07-14 20:00',1,'2024-07-14 20:00',1,'n',null,null,'en',' std_checksum',1,null,'y','y',1,'2024-07-14 20:00','1',1,'World',142,'Asia',35,'South-eastern Asia',null,null,704,'n','n','n','VN','VNM'),('Afghanistan','Afghanistan','/countries/asia/afghanistan',null,'Afghanistan','Afghanistan','{}','2024-07-14 20:00',1,'2024-07-14 20:00',1,'n',null,null,'en',' std_checksum',1,null,'y','y',1,'2024-07-14 20:00','1',1,'World',142,'Asia',34,'Southern Asia',null,null,4,'y','y','n','AF','AFG'),('Bangladesh','Bangladesh','/countries/asia/bangladesh',null,'Bangladesh','Bangladesh','{}','2024-07-14 20:00',1,'2024-07-14 20:00',1,'n',null,null,'en',' std_checksum',1,null,'y','y',1,'2024-07-14 20:00','1',1,'World',142,'Asia',34,'Southern Asia',null,null,50,'y','n','n','BD','BGD'),('Bhutan','Bhutan','/countries/asia/bhutan',null,'Bhutan','Bhutan','{}','2024-07-14 20:00',1,'2024-07-14 20:00',1,'n',null,null,'en',' std_checksum',1,null,'y','y',1,'2024-07-14 20:00','1',1,'World',142,'Asia',34,'Southern Asia',null,null,64,'n','y','n','BT','BTN'),('India','India','/countries/asia/india',null,'India','India','{}','2024-07-14 20:00',1,'2024-07-14 20:00',1,'n',null,null,'en',' std_checksum',1,null,'y','y',1,'2024-07-14 20:00','1',1,'World',142,'Asia',34,'Southern Asia',null,null,356,'n','n','n','IN','IND'),('Iran (Islamic Republic of)','Iran (Islamic Republic of)','/countries/asia/iran%20&#40;islamic%20republic%20of&#41;',null,'Iran (Islamic Republic of)','Iran (Islamic Republic of)','{}','2024-07-14 20:00',1,'2024-07-14 20:00',1,'n',null,null,'en',' std_checksum',1,null,'y','y',1,'2024-07-14 20:00','1',1,'World',142,'Asia',34,'Southern Asia',null,null,364,'n','n','n','IR','IRN'),('Maldives','Maldives','/countries/asia/maldives',null,'Maldives','Maldives','{}','2024-07-14 20:00',1,'2024-07-14 20:00',1,'n',null,null,'en',' std_checksum',1,null,'y','y',1,'2024-07-14 20:00','1',1,'World',142,'Asia',34,'Southern Asia',null,null,462,'n','n','y','MV','MDV'),('Nepal','Nepal','/countries/asia/nepal',null,'Nepal','Nepal','{}','2024-07-14 20:00',1,'2024-07-14 20:00',1,'n',null,null,'en',' std_checksum',1,null,'y','y',1,'2024-07-14 20:00','1',1,'World',142,'Asia',34,'Southern Asia',null,null,524,'y','y','n','NP','NPL'),('Pakistan','Pakistan','/countries/asia/pakistan',null,'Pakistan','Pakistan','{}','2024-07-14 20:00',1,'2024-07-14 20:00',1,'n',null,null,'en',' std_checksum',1,null,'y','y',1,'2024-07-14 20:00','1',1,'World',142,'Asia',34,'Southern Asia',null,null,586,'n','n','n','PK','PAK'),('Sri Lanka','Sri Lanka','/countries/asia/sri%20lanka',null,'Sri Lanka','Sri Lanka','{}','2024-07-14 20:00',1,'2024-07-14 20:00',1,'n',null,null,'en',' std_checksum',1,null,'y','y',1,'2024-07-14 20:00','1',1,'World',142,'Asia',34,'Southern Asia',null,null,144,'n','n','n','LK','LKA');
INSERT INTO osc_physrisk_backend.geo_country(std_name,std_name_display,std_slug,std_abbreviation,std_description_full,std_description_short,std_tags,std_datetime_utc_created,std_creator_user_id,std_datetime_utc_last_modified,std_last_modifier_user_id,std_is_deleted,std_deleter_user_id,std_datetime_utc_deleted,std_culture,std_checksum,std_seq_num,std_translated_from_id,std_is_active,std_is_published,std_publisher_id,std_datetime_utc_published,std_version,un_global_code,un_global_name,un_region_code,un_region_name,un_subregion_code,un_subregion_name,un_intermediateregion_code,un_intermediateregion_name,un_code_m49,un_is_ldc,un_is_lldc,un_is_sids,iso_code_alpha2,iso_code_alpha3) VALUES ('Armenia','Armenia','/countries/asia/armenia',null,'Armenia','Armenia','{}','2024-07-14 20:00',1,'2024-07-14 20:00',1,'n',null,null,'en',' std_checksum',1,null,'y','y',1,'2024-07-14 20:00','1',1,'World',142,'Asia',145,'Western Asia',null,null,51,'n','y','n','AM','ARM'),('Azerbaijan','Azerbaijan','/countries/asia/azerbaijan',null,'Azerbaijan','Azerbaijan','{}','2024-07-14 20:00',1,'2024-07-14 20:00',1,'n',null,null,'en',' std_checksum',1,null,'y','y',1,'2024-07-14 20:00','1',1,'World',142,'Asia',145,'Western Asia',null,null,31,'n','y','n','AZ','AZE'),('Bahrain','Bahrain','/countries/asia/bahrain',null,'Bahrain','Bahrain','{}','2024-07-14 20:00',1,'2024-07-14 20:00',1,'n',null,null,'en',' std_checksum',1,null,'y','y',1,'2024-07-14 20:00','1',1,'World',142,'Asia',145,'Western Asia',null,null,48,'n','n','n','BH','BHR'),('Cyprus','Cyprus','/countries/asia/cyprus',null,'Cyprus','Cyprus','{}','2024-07-14 20:00',1,'2024-07-14 20:00',1,'n',null,null,'en',' std_checksum',1,null,'y','y',1,'2024-07-14 20:00','1',1,'World',142,'Asia',145,'Western Asia',null,null,196,'n','n','n','CY','CYP'),('Georgia','Georgia','/countries/asia/georgia',null,'Georgia','Georgia','{}','2024-07-14 20:00',1,'2024-07-14 20:00',1,'n',null,null,'en',' std_checksum',1,null,'y','y',1,'2024-07-14 20:00','1',1,'World',142,'Asia',145,'Western Asia',null,null,268,'n','n','n','GE','GEO'),('Iraq','Iraq','/countries/asia/iraq',null,'Iraq','Iraq','{}','2024-07-14 20:00',1,'2024-07-14 20:00',1,'n',null,null,'en',' std_checksum',1,null,'y','y',1,'2024-07-14 20:00','1',1,'World',142,'Asia',145,'Western Asia',null,null,368,'n','n','n','IQ','IRQ'),('Israel','Israel','/countries/asia/israel',null,'Israel','Israel','{}','2024-07-14 20:00',1,'2024-07-14 20:00',1,'n',null,null,'en',' std_checksum',1,null,'y','y',1,'2024-07-14 20:00','1',1,'World',142,'Asia',145,'Western Asia',null,null,376,'n','n','n','IL','ISR'),('Jordan','Jordan','/countries/asia/jordan',null,'Jordan','Jordan','{}','2024-07-14 20:00',1,'2024-07-14 20:00',1,'n',null,null,'en',' std_checksum',1,null,'y','y',1,'2024-07-14 20:00','1',1,'World',142,'Asia',145,'Western Asia',null,null,400,'n','n','n','JO','JOR'),('Kuwait','Kuwait','/countries/asia/kuwait',null,'Kuwait','Kuwait','{}','2024-07-14 20:00',1,'2024-07-14 20:00',1,'n',null,null,'en',' std_checksum',1,null,'y','y',1,'2024-07-14 20:00','1',1,'World',142,'Asia',145,'Western Asia',null,null,414,'n','n','n','KW','KWT'),('Lebanon','Lebanon','/countries/asia/lebanon',null,'Lebanon','Lebanon','{}','2024-07-14 20:00',1,'2024-07-14 20:00',1,'n',null,null,'en',' std_checksum',1,null,'y','y',1,'2024-07-14 20:00','1',1,'World',142,'Asia',145,'Western Asia',null,null,422,'n','n','n','LB','LBN'),('Oman','Oman','/countries/asia/oman',null,'Oman','Oman','{}','2024-07-14 20:00',1,'2024-07-14 20:00',1,'n',null,null,'en',' std_checksum',1,null,'y','y',1,'2024-07-14 20:00','1',1,'World',142,'Asia',145,'Western Asia',null,null,512,'n','n','n','OM','OMN'),('Qatar','Qatar','/countries/asia/qatar',null,'Qatar','Qatar','{}','2024-07-14 20:00',1,'2024-07-14 20:00',1,'n',null,null,'en',' std_checksum',1,null,'y','y',1,'2024-07-14 20:00','1',1,'World',142,'Asia',145,'Western Asia',null,null,634,'n','n','n','QA','QAT'),('Saudi Arabia','Saudi Arabia','/countries/asia/saudi%20arabia',null,'Saudi Arabia','Saudi Arabia','{}','2024-07-14 20:00',1,'2024-07-14 20:00',1,'n',null,null,'en',' std_checksum',1,null,'y','y',1,'2024-07-14 20:00','1',1,'World',142,'Asia',145,'Western Asia',null,null,682,'n','n','n','SA','SAU'),('State of Palestine','State of Palestine','/countries/asia/state%20of%20palestine',null,'State of Palestine','State of Palestine','{}','2024-07-14 20:00',1,'2024-07-14 20:00',1,'n',null,null,'en',' std_checksum',1,null,'y','y',1,'2024-07-14 20:00','1',1,'World',142,'Asia',145,'Western Asia',null,null,275,null,'n','n','PS','PSE'),('Syrian Arab Republic','Syrian Arab Republic','/countries/asia/syrian%20arab%20republic',null,'Syrian Arab Republic','Syrian Arab Republic','{}','2024-07-14 20:00',1,'2024-07-14 20:00',1,'n',null,null,'en',' std_checksum',1,null,'y','y',1,'2024-07-14 20:00','1',1,'World',142,'Asia',145,'Western Asia',null,null,760,null,'n','n','SY','SYR'),('Türkiye','Türkiye','/countries/asia/turkiye',null,'Türkiye','Türkiye','{}','2024-07-14 20:00',1,'2024-07-14 20:00',1,'n',null,null,'en',' std_checksum',1,null,'y','y',1,'2024-07-14 20:00','1',1,'World',142,'Asia',145,'Western Asia',null,null,792,null,'n','n','TR','TUR'),('United Arab Emirates','United Arab Emirates','/countries/asia/united%20arab%20emirates',null,'United Arab Emirates','United Arab Emirates','{}','2024-07-14 20:00',1,'2024-07-14 20:00',1,'n',null,null,'en',' std_checksum',1,null,'y','y',1,'2024-07-14 20:00','1',1,'World',142,'Asia',145,'Western Asia',null,null,784,null,'n','n','AE','ARE'),('Yemen','Yemen','/countries/asia/yemen',null,'Yemen','Yemen','{}','2024-07-14 20:00',1,'2024-07-14 20:00',1,'n',null,null,'en',' std_checksum',1,null,'y','y',1,'2024-07-14 20:00','1',1,'World',142,'Asia',145,'Western Asia',null,null,887,'y','n','n','YE','YEM'),('Belarus','Belarus','/countries/europe/belarus',null,'Belarus','Belarus','{}','2024-07-14 20:00',1,'2024-07-14 20:00',1,'n',null,null,'en',' std_checksum',1,null,'y','y',1,'2024-07-14 20:00','1',1,'World',150,'Europe',151,'Eastern Europe',null,null,112,'n','n','n','BY','BLR'),('Bulgaria','Bulgaria','/countries/europe/bulgaria',null,'Bulgaria','Bulgaria','{}','2024-07-14 20:00',1,'2024-07-14 20:00',1,'n',null,null,'en',' std_checksum',1,null,'y','y',1,'2024-07-14 20:00','1',1,'World',150,'Europe',151,'Eastern Europe',null,null,100,'n','n','n','BG','BGR'),('Czechia','Czechia','/countries/europe/czechia',null,'Czechia','Czechia','{}','2024-07-14 20:00',1,'2024-07-14 20:00',1,'n',null,null,'en',' std_checksum',1,null,'y','y',1,'2024-07-14 20:00','1',1,'World',150,'Europe',151,'Eastern Europe',null,null,203,'n','n','n','CZ','CZE'),('Hungary','Hungary','/countries/europe/hungary',null,'Hungary','Hungary','{}','2024-07-14 20:00',1,'2024-07-14 20:00',1,'n',null,null,'en',' std_checksum',1,null,'y','y',1,'2024-07-14 20:00','1',1,'World',150,'Europe',151,'Eastern Europe',null,null,348,'n','n','n','HU','HUN'),('Poland','Poland','/countries/europe/poland',null,'Poland','Poland','{}','2024-07-14 20:00',1,'2024-07-14 20:00',1,'n',null,null,'en',' std_checksum',1,null,'y','y',1,'2024-07-14 20:00','1',1,'World',150,'Europe',151,'Eastern Europe',null,null,616,'n','n','n','PL','POL'),('Republic of Moldova','Republic of Moldova','/countries/europe/republic%20of%20moldova',null,'Republic of Moldova','Republic of Moldova','{}','2024-07-14 20:00',1,'2024-07-14 20:00',1,'n',null,null,'en',' std_checksum',1,null,'y','y',1,'2024-07-14 20:00','1',1,'World',150,'Europe',151,'Eastern Europe',null,null,498,'n','y','n','MD','MDA'),('Romania','Romania','/countries/europe/romania',null,'Romania','Romania','{}','2024-07-14 20:00',1,'2024-07-14 20:00',1,'n',null,null,'en',' std_checksum',1,null,'y','y',1,'2024-07-14 20:00','1',1,'World',150,'Europe',151,'Eastern Europe',null,null,642,'n','n','n','RO','ROU');
INSERT INTO osc_physrisk_backend.geo_country(std_name,std_name_display,std_slug,std_abbreviation,std_description_full,std_description_short,std_tags,std_datetime_utc_created,std_creator_user_id,std_datetime_utc_last_modified,std_last_modifier_user_id,std_is_deleted,std_deleter_user_id,std_datetime_utc_deleted,std_culture,std_checksum,std_seq_num,std_translated_from_id,std_is_active,std_is_published,std_publisher_id,std_datetime_utc_published,std_version,un_global_code,un_global_name,un_region_code,un_region_name,un_subregion_code,un_subregion_name,un_intermediateregion_code,un_intermediateregion_name,un_code_m49,un_is_ldc,un_is_lldc,un_is_sids,iso_code_alpha2,iso_code_alpha3) VALUES ('Russian Federation','Russian Federation','/countries/europe/russian%20federation',null,'Russian Federation','Russian Federation','{}','2024-07-14 20:00',1,'2024-07-14 20:00',1,'n',null,null,'en',' std_checksum',1,null,'y','y',1,'2024-07-14 20:00','1',1,'World',150,'Europe',151,'Eastern Europe',null,null,643,'n','n','n','RU','RUS'),('Slovakia','Slovakia','/countries/europe/slovakia',null,'Slovakia','Slovakia','{}','2024-07-14 20:00',1,'2024-07-14 20:00',1,'n',null,null,'en',' std_checksum',1,null,'y','y',1,'2024-07-14 20:00','1',1,'World',150,'Europe',151,'Eastern Europe',null,null,703,'n','n','n','SK','SVK'),('Ukraine','Ukraine','/countries/europe/ukraine',null,'Ukraine','Ukraine','{}','2024-07-14 20:00',1,'2024-07-14 20:00',1,'n',null,null,'en',' std_checksum',1,null,'y','y',1,'2024-07-14 20:00','1',1,'World',150,'Europe',151,'Eastern Europe',null,null,804,'n','n','n','UA','UKR'),('Åland Islands','Åland Islands','/countries/europe/aland%20islands',null,'Åland Islands','Åland Islands','{}','2024-07-14 20:00',1,'2024-07-14 20:00',1,'n',null,null,'en',' std_checksum',1,null,'y','y',1,'2024-07-14 20:00','1',1,'World',150,'Europe',154,'Northern Europe',null,null,248,'n','n','n','AX','ALA'),('Denmark','Denmark','/countries/europe/denmark',null,'Denmark','Denmark','{}','2024-07-14 20:00',1,'2024-07-14 20:00',1,'n',null,null,'en',' std_checksum',1,null,'y','y',1,'2024-07-14 20:00','1',1,'World',150,'Europe',154,'Northern Europe',null,null,208,'n','n','n','DK','DNK'),('Estonia','Estonia','/countries/europe/estonia',null,'Estonia','Estonia','{}','2024-07-14 20:00',1,'2024-07-14 20:00',1,'n',null,null,'en',' std_checksum',1,null,'y','y',1,'2024-07-14 20:00','1',1,'World',150,'Europe',154,'Northern Europe',null,null,233,'n','n','n','EE','EST'),('Faroe Islands','Faroe Islands','/countries/europe/faroe%20islands',null,'Faroe Islands','Faroe Islands','{}','2024-07-14 20:00',1,'2024-07-14 20:00',1,'n',null,null,'en',' std_checksum',1,null,'y','y',1,'2024-07-14 20:00','1',1,'World',150,'Europe',154,'Northern Europe',null,null,234,'n','n','n','FO','FRO'),('Finland','Finland','/countries/europe/finland',null,'Finland','Finland','{}','2024-07-14 20:00',1,'2024-07-14 20:00',1,'n',null,null,'en',' std_checksum',1,null,'y','y',1,'2024-07-14 20:00','1',1,'World',150,'Europe',154,'Northern Europe',null,null,246,'n','n','n','FI','FIN'),('Guernsey','Guernsey','/countries/europe/guernsey',null,'Guernsey','Guernsey','{}','2024-07-14 20:00',1,'2024-07-14 20:00',1,'n',null,null,'en',' std_checksum',1,null,'y','y',1,'2024-07-14 20:00','1',1,'World',150,'Europe',154,'Northern Europe',null,null,831,'n','n','n','GG','GGY'),('Iceland','Iceland','/countries/europe/iceland',null,'Iceland','Iceland','{}','2024-07-14 20:00',1,'2024-07-14 20:00',1,'n',null,null,'en',' std_checksum',1,null,'y','y',1,'2024-07-14 20:00','1',1,'World',150,'Europe',154,'Northern Europe',null,null,352,'n','n','n','IS','ISL'),('Ireland','Ireland','/countries/europe/ireland',null,'Ireland','Ireland','{}','2024-07-14 20:00',1,'2024-07-14 20:00',1,'n',null,null,'en',' std_checksum',1,null,'y','y',1,'2024-07-14 20:00','1',1,'World',150,'Europe',154,'Northern Europe',null,null,372,'n','n','n','IE','IRL'),('Isle of Man','Isle of Man','/countries/europe/isle%20of%20man',null,'Isle of Man','Isle of Man','{}','2024-07-14 20:00',1,'2024-07-14 20:00',1,'n',null,null,'en',' std_checksum',1,null,'y','y',1,'2024-07-14 20:00','1',1,'World',150,'Europe',154,'Northern Europe',null,null,833,'n','n','n','IM','IMN'),('Jersey','Jersey','/countries/europe/jersey',null,'Jersey','Jersey','{}','2024-07-14 20:00',1,'2024-07-14 20:00',1,'n',null,null,'en',' std_checksum',1,null,'y','y',1,'2024-07-14 20:00','1',1,'World',150,'Europe',154,'Northern Europe',null,null,832,'n','n','n','JE','JEY'),('Latvia','Latvia','/countries/europe/latvia',null,'Latvia','Latvia','{}','2024-07-14 20:00',1,'2024-07-14 20:00',1,'n',null,null,'en',' std_checksum',1,null,'y','y',1,'2024-07-14 20:00','1',1,'World',150,'Europe',154,'Northern Europe',null,null,428,'n','n','n','LV','LVA'),('Lithuania','Lithuania','/countries/europe/lithuania',null,'Lithuania','Lithuania','{}','2024-07-14 20:00',1,'2024-07-14 20:00',1,'n',null,null,'en',' std_checksum',1,null,'y','y',1,'2024-07-14 20:00','1',1,'World',150,'Europe',154,'Northern Europe',null,null,440,'n','n','n','LT','LTU'),('Norway','Norway','/countries/europe/norway',null,'Norway','Norway','{}','2024-07-14 20:00',1,'2024-07-14 20:00',1,'n',null,null,'en',' std_checksum',1,null,'y','y',1,'2024-07-14 20:00','1',1,'World',150,'Europe',154,'Northern Europe',null,null,578,'n','n','n','NO','NOR'),('Svalbard and Jan Mayen Islands','Svalbard and Jan Mayen Islands','/countries/europe/svalbard%20and%20jan%20mayen%20islands',null,'Svalbard and Jan Mayen Islands','Svalbard and Jan Mayen Islands','{}','2024-07-14 20:00',1,'2024-07-14 20:00',1,'n',null,null,'en',' std_checksum',1,null,'y','y',1,'2024-07-14 20:00','1',1,'World',150,'Europe',154,'Northern Europe',null,null,744,'n','n','n','SJ','SJM'),('Sweden','Sweden','/countries/europe/sweden',null,'Sweden','Sweden','{}','2024-07-14 20:00',1,'2024-07-14 20:00',1,'n',null,null,'en',' std_checksum',1,null,'y','y',1,'2024-07-14 20:00','1',1,'World',150,'Europe',154,'Northern Europe',null,null,752,'n','n','n','SE','SWE'),('United Kingdom of Great Britain and Northern Ireland','United Kingdom of Great Britain and Northern Ireland','/countries/europe/united%20kingdom%20of%20great%20britain%20and%20northern%20ireland',null,'United Kingdom of Great Britain and Northern Ireland','United Kingdom of Great Britain and Northern Ireland','{}','2024-07-14 20:00',1,'2024-07-14 20:00',1,'n',null,null,'en',' std_checksum',1,null,'y','y',1,'2024-07-14 20:00','1',1,'World',150,'Europe',154,'Northern Europe',null,null,826,'n','n','n','GB','GBR'),('Albania','Albania','/countries/europe/albania',null,'Albania','Albania','{}','2024-07-14 20:00',1,'2024-07-14 20:00',1,'n',null,null,'en',' std_checksum',1,null,'y','y',1,'2024-07-14 20:00','1',1,'World',150,'Europe',39,'Southern Europe',null,null,8,'n','n','n','AL','ALB'),('Andorra','Andorra','/countries/europe/andorra',null,'Andorra','Andorra','{}','2024-07-14 20:00',1,'2024-07-14 20:00',1,'n',null,null,'en',' std_checksum',1,null,'y','y',1,'2024-07-14 20:00','1',1,'World',150,'Europe',39,'Southern Europe',null,null,20,'n','n','n','AD','AND'),('Bosnia and Herzegovina','Bosnia and Herzegovina','/countries/europe/bosnia%20and%20herzegovina',null,'Bosnia and Herzegovina','Bosnia and Herzegovina','{}','2024-07-14 20:00',1,'2024-07-14 20:00',1,'n',null,null,'en',' std_checksum',1,null,'y','y',1,'2024-07-14 20:00','1',1,'World',150,'Europe',39,'Southern Europe',null,null,70,'n','n','n','BA','BIH'),('Croatia','Croatia','/countries/europe/croatia',null,'Croatia','Croatia','{}','2024-07-14 20:00',1,'2024-07-14 20:00',1,'n',null,null,'en',' std_checksum',1,null,'y','y',1,'2024-07-14 20:00','1',1,'World',150,'Europe',39,'Southern Europe',null,null,191,'n','n','n','HR','HRV'),('Gibraltar','Gibraltar','/countries/europe/gibraltar',null,'Gibraltar','Gibraltar','{}','2024-07-14 20:00',1,'2024-07-14 20:00',1,'n',null,null,'en',' std_checksum',1,null,'y','y',1,'2024-07-14 20:00','1',1,'World',150,'Europe',39,'Southern Europe',null,null,292,'n','n','n','GI','GIB'),('Greece','Greece','/countries/europe/greece',null,'Greece','Greece','{}','2024-07-14 20:00',1,'2024-07-14 20:00',1,'n',null,null,'en',' std_checksum',1,null,'y','y',1,'2024-07-14 20:00','1',1,'World',150,'Europe',39,'Southern Europe',null,null,300,'n','n','n','GR','GRC');
INSERT INTO osc_physrisk_backend.geo_country(std_name,std_name_display,std_slug,std_abbreviation,std_description_full,std_description_short,std_tags,std_datetime_utc_created,std_creator_user_id,std_datetime_utc_last_modified,std_last_modifier_user_id,std_is_deleted,std_deleter_user_id,std_datetime_utc_deleted,std_culture,std_checksum,std_seq_num,std_translated_from_id,std_is_active,std_is_published,std_publisher_id,std_datetime_utc_published,std_version,un_global_code,un_global_name,un_region_code,un_region_name,un_subregion_code,un_subregion_name,un_intermediateregion_code,un_intermediateregion_name,un_code_m49,un_is_ldc,un_is_lldc,un_is_sids,iso_code_alpha2,iso_code_alpha3) VALUES ('Holy See','Holy See','/countries/europe/holy%20see',null,'Holy See','Holy See','{}','2024-07-14 20:00',1,'2024-07-14 20:00',1,'n',null,null,'en',' std_checksum',1,null,'y','y',1,'2024-07-14 20:00','1',1,'World',150,'Europe',39,'Southern Europe',null,null,336,'n','n','n','VA','VAT'),('Italy','Italy','/countries/europe/italy',null,'Italy','Italy','{}','2024-07-14 20:00',1,'2024-07-14 20:00',1,'n',null,null,'en',' std_checksum',1,null,'y','y',1,'2024-07-14 20:00','1',1,'World',150,'Europe',39,'Southern Europe',null,null,380,'n','n','n','IT','ITA'),('Malta','Malta','/countries/europe/malta',null,'Malta','Malta','{}','2024-07-14 20:00',1,'2024-07-14 20:00',1,'n',null,null,'en',' std_checksum',1,null,'y','y',1,'2024-07-14 20:00','1',1,'World',150,'Europe',39,'Southern Europe',null,null,470,'n','n','n','MT','MLT'),('Montenegro','Montenegro','/countries/europe/montenegro',null,'Montenegro','Montenegro','{}','2024-07-14 20:00',1,'2024-07-14 20:00',1,'n',null,null,'en',' std_checksum',1,null,'y','y',1,'2024-07-14 20:00','1',1,'World',150,'Europe',39,'Southern Europe',null,null,499,'n','n','n','ME','MNE'),('North Macedonia','North Macedonia','/countries/europe/north%20macedonia',null,'North Macedonia','North Macedonia','{}','2024-07-14 20:00',1,'2024-07-14 20:00',1,'n',null,null,'en',' std_checksum',1,null,'y','y',1,'2024-07-14 20:00','1',1,'World',150,'Europe',39,'Southern Europe',null,null,807,'n','y','n','MK','MKD'),('Portugal','Portugal','/countries/europe/portugal',null,'Portugal','Portugal','{}','2024-07-14 20:00',1,'2024-07-14 20:00',1,'n',null,null,'en',' std_checksum',1,null,'y','y',1,'2024-07-14 20:00','1',1,'World',150,'Europe',39,'Southern Europe',null,null,620,'n','n','n','PT','PRT'),('San Marino','San Marino','/countries/europe/san%20marino',null,'San Marino','San Marino','{}','2024-07-14 20:00',1,'2024-07-14 20:00',1,'n',null,null,'en',' std_checksum',1,null,'y','y',1,'2024-07-14 20:00','1',1,'World',150,'Europe',39,'Southern Europe',null,null,674,'n','n','n','SM','SMR'),('Serbia','Serbia','/countries/europe/serbia',null,'Serbia','Serbia','{}','2024-07-14 20:00',1,'2024-07-14 20:00',1,'n',null,null,'en',' std_checksum',1,null,'y','y',1,'2024-07-14 20:00','1',1,'World',150,'Europe',39,'Southern Europe',null,null,688,'n','n','n','RS','SRB'),('Slovenia','Slovenia','/countries/europe/slovenia',null,'Slovenia','Slovenia','{}','2024-07-14 20:00',1,'2024-07-14 20:00',1,'n',null,null,'en',' std_checksum',1,null,'y','y',1,'2024-07-14 20:00','1',1,'World',150,'Europe',39,'Southern Europe',null,null,705,'n','n','n','SI','SVN'),('Spain','Spain','/countries/europe/spain',null,'Spain','Spain','{}','2024-07-14 20:00',1,'2024-07-14 20:00',1,'n',null,null,'en',' std_checksum',1,null,'y','y',1,'2024-07-14 20:00','1',1,'World',150,'Europe',39,'Southern Europe',null,null,724,'n','n','n','ES','ESP'),('Austria','Austria','/countries/europe/austria',null,'Austria','Austria','{}','2024-07-14 20:00',1,'2024-07-14 20:00',1,'n',null,null,'en',' std_checksum',1,null,'y','y',1,'2024-07-14 20:00','1',1,'World',150,'Europe',155,'Western Europe',null,null,40,'n','n','n','AT','AUT'),('Belgium','Belgium','/countries/europe/belgium',null,'Belgium','Belgium','{}','2024-07-14 20:00',1,'2024-07-14 20:00',1,'n',null,null,'en',' std_checksum',1,null,'y','y',1,'2024-07-14 20:00','1',1,'World',150,'Europe',155,'Western Europe',null,null,56,'n','n','n','BE','BEL'),('France','France','/countries/europe/france',null,'France','France','{}','2024-07-14 20:00',1,'2024-07-14 20:00',1,'n',null,null,'en',' std_checksum',1,null,'y','y',1,'2024-07-14 20:00','1',1,'World',150,'Europe',155,'Western Europe',null,null,250,'n','n','n','FR','FRA'),('Germany','Germany','/countries/europe/germany',null,'Germany','Germany','{}','2024-07-14 20:00',1,'2024-07-14 20:00',1,'n',null,null,'en',' std_checksum',1,null,'y','y',1,'2024-07-14 20:00','1',1,'World',150,'Europe',155,'Western Europe',null,null,276,'n','n','n','DE','DEU'),('Liechtenstein','Liechtenstein','/countries/europe/liechtenstein',null,'Liechtenstein','Liechtenstein','{}','2024-07-14 20:00',1,'2024-07-14 20:00',1,'n',null,null,'en',' std_checksum',1,null,'y','y',1,'2024-07-14 20:00','1',1,'World',150,'Europe',155,'Western Europe',null,null,438,'n','n','n','LI','LIE'),('Luxembourg','Luxembourg','/countries/europe/luxembourg',null,'Luxembourg','Luxembourg','{}','2024-07-14 20:00',1,'2024-07-14 20:00',1,'n',null,null,'en',' std_checksum',1,null,'y','y',1,'2024-07-14 20:00','1',1,'World',150,'Europe',155,'Western Europe',null,null,442,'n','n','n','LU','LUX'),('Monaco','Monaco','/countries/europe/monaco',null,'Monaco','Monaco','{}','2024-07-14 20:00',1,'2024-07-14 20:00',1,'n',null,null,'en',' std_checksum',1,null,'y','y',1,'2024-07-14 20:00','1',1,'World',150,'Europe',155,'Western Europe',null,null,492,'n','n','n','MC','MCO'),('Netherlands (Kingdom of the)','Netherlands (Kingdom of the)','/countries/europe/netherlands%20&#40;kingdom%20of%20the&#41;',null,'Netherlands (Kingdom of the)','Netherlands (Kingdom of the)','{}','2024-07-14 20:00',1,'2024-07-14 20:00',1,'n',null,null,'en',' std_checksum',1,null,'y','y',1,'2024-07-14 20:00','1',1,'World',150,'Europe',155,'Western Europe',null,null,528,'n','n','n','NL','NLD'),('Switzerland','Switzerland','/countries/europe/switzerland',null,'Switzerland','Switzerland','{}','2024-07-14 20:00',1,'2024-07-14 20:00',1,'n',null,null,'en',' std_checksum',1,null,'y','y',1,'2024-07-14 20:00','1',1,'World',150,'Europe',155,'Western Europe',null,null,756,'n','n','n','CH','CHE'),('Australia','Australia','/countries/oceania/australia',null,'Australia','Australia','{}','2024-07-14 20:00',1,'2024-07-14 20:00',1,'n',null,null,'en',' std_checksum',1,null,'y','y',1,'2024-07-14 20:00','1',1,'World',9,'Oceania',53,'Australia and New Zealand',null,null,36,'n','n','n','AU','AUS'),('Christmas Island','Christmas Island','/countries/oceania/christmas%20island',null,'Christmas Island','Christmas Island','{}','2024-07-14 20:00',1,'2024-07-14 20:00',1,'n',null,null,'en',' std_checksum',1,null,'y','y',1,'2024-07-14 20:00','1',1,'World',9,'Oceania',53,'Australia and New Zealand',null,null,162,'n','n','n','CX','CXR'),('Cocos (Keeling) Islands','Cocos (Keeling) Islands','/countries/oceania/cocos%20&#40;keeling&#41;%20islands',null,'Cocos (Keeling) Islands','Cocos (Keeling) Islands','{}','2024-07-14 20:00',1,'2024-07-14 20:00',1,'n',null,null,'en',' std_checksum',1,null,'y','y',1,'2024-07-14 20:00','1',1,'World',9,'Oceania',53,'Australia and New Zealand',null,null,166,'n','n','n','CC','CCK'),('Heard Island and McDonald Islands','Heard Island and McDonald Islands','/countries/oceania/heard%20island%20and%20mcdonald%20islands',null,'Heard Island and McDonald Islands','Heard Island and McDonald Islands','{}','2024-07-14 20:00',1,'2024-07-14 20:00',1,'n',null,null,'en',' std_checksum',1,null,'y','y',1,'2024-07-14 20:00','1',1,'World',9,'Oceania',53,'Australia and New Zealand',null,null,334,'n','n','n','HM','HMD'),('New Zealand','New Zealand','/countries/oceania/new%20zealand',null,'New Zealand','New Zealand','{}','2024-07-14 20:00',1,'2024-07-14 20:00',1,'n',null,null,'en',' std_checksum',1,null,'y','y',1,'2024-07-14 20:00','1',1,'World',9,'Oceania',53,'Australia and New Zealand',null,null,554,'n','n','n','NZ','NZL'),('Norfolk Island','Norfolk Island','/countries/oceania/norfolk%20island',null,'Norfolk Island','Norfolk Island','{}','2024-07-14 20:00',1,'2024-07-14 20:00',1,'n',null,null,'en',' std_checksum',1,null,'y','y',1,'2024-07-14 20:00','1',1,'World',9,'Oceania',53,'Australia and New Zealand',null,null,574,'n','n','n','NF','NFK');
INSERT INTO osc_physrisk_backend.geo_country(std_name,std_name_display,std_slug,std_abbreviation,std_description_full,std_description_short,std_tags,std_datetime_utc_created,std_creator_user_id,std_datetime_utc_last_modified,std_last_modifier_user_id,std_is_deleted,std_deleter_user_id,std_datetime_utc_deleted,std_culture,std_checksum,std_seq_num,std_translated_from_id,std_is_active,std_is_published,std_publisher_id,std_datetime_utc_published,std_version,un_global_code,un_global_name,un_region_code,un_region_name,un_subregion_code,un_subregion_name,un_intermediateregion_code,un_intermediateregion_name,un_code_m49,un_is_ldc,un_is_lldc,un_is_sids,iso_code_alpha2,iso_code_alpha3) VALUES ('Fiji','Fiji','/countries/oceania/fiji',null,'Fiji','Fiji','{}','2024-07-14 20:00',1,'2024-07-14 20:00',1,'n',null,null,'en',' std_checksum',1,null,'y','y',1,'2024-07-14 20:00','1',1,'World',9,'Oceania',54,'Melanesia',null,null,242,'n','n','y','FJ','FJI'),('New Caledonia','New Caledonia','/countries/oceania/new%20caledonia',null,'New Caledonia','New Caledonia','{}','2024-07-14 20:00',1,'2024-07-14 20:00',1,'n',null,null,'en',' std_checksum',1,null,'y','y',1,'2024-07-14 20:00','1',1,'World',9,'Oceania',54,'Melanesia',null,null,540,'n','n','y','NC','NCL'),('Papua New Guinea','Papua New Guinea','/countries/oceania/papua%20new%20guinea',null,'Papua New Guinea','Papua New Guinea','{}','2024-07-14 20:00',1,'2024-07-14 20:00',1,'n',null,null,'en',' std_checksum',1,null,'y','y',1,'2024-07-14 20:00','1',1,'World',9,'Oceania',54,'Melanesia',null,null,598,'n','n','y','PG','PNG'),('Solomon Islands','Solomon Islands','/countries/oceania/solomon%20islands',null,'Solomon Islands','Solomon Islands','{}','2024-07-14 20:00',1,'2024-07-14 20:00',1,'n',null,null,'en',' std_checksum',1,null,'y','y',1,'2024-07-14 20:00','1',1,'World',9,'Oceania',54,'Melanesia',null,null,90,'y','n','y','SB','SLB'),('Vanuatu','Vanuatu','/countries/oceania/vanuatu',null,'Vanuatu','Vanuatu','{}','2024-07-14 20:00',1,'2024-07-14 20:00',1,'n',null,null,'en',' std_checksum',1,null,'y','y',1,'2024-07-14 20:00','1',1,'World',9,'Oceania',54,'Melanesia',null,null,548,'n','n','y','VU','VUT'),('Guam','Guam','/countries/oceania/guam',null,'Guam','Guam','{}','2024-07-14 20:00',1,'2024-07-14 20:00',1,'n',null,null,'en',' std_checksum',1,null,'y','y',1,'2024-07-14 20:00','1',1,'World',9,'Oceania',57,'Micronesia',null,null,316,'n','n','y','GU','GUM'),('Kiribati','Kiribati','/countries/oceania/kiribati',null,'Kiribati','Kiribati','{}','2024-07-14 20:00',1,'2024-07-14 20:00',1,'n',null,null,'en',' std_checksum',1,null,'y','y',1,'2024-07-14 20:00','1',1,'World',9,'Oceania',57,'Micronesia',null,null,296,'y','n','y','KI','KIR'),('Marshall Islands','Marshall Islands','/countries/oceania/marshall%20islands',null,'Marshall Islands','Marshall Islands','{}','2024-07-14 20:00',1,'2024-07-14 20:00',1,'n',null,null,'en',' std_checksum',1,null,'y','y',1,'2024-07-14 20:00','1',1,'World',9,'Oceania',57,'Micronesia',null,null,584,'n','n','y','MH','MHL'),('Micronesia (Federated States of)','Micronesia (Federated States of)','/countries/oceania/micronesia%20&#40;federated%20states%20of&#41;',null,'Micronesia (Federated States of)','Micronesia (Federated States of)','{}','2024-07-14 20:00',1,'2024-07-14 20:00',1,'n',null,null,'en',' std_checksum',1,null,'y','y',1,'2024-07-14 20:00','1',1,'World',9,'Oceania',57,'Micronesia',null,null,583,'n','n','y','FM','FSM'),('Nauru','Nauru','/countries/oceania/nauru',null,'Nauru','Nauru','{}','2024-07-14 20:00',1,'2024-07-14 20:00',1,'n',null,null,'en',' std_checksum',1,null,'y','y',1,'2024-07-14 20:00','1',1,'World',9,'Oceania',57,'Micronesia',null,null,520,'n','n','y','NR','NRU'),('Northern Mariana Islands','Northern Mariana Islands','/countries/oceania/northern%20mariana%20islands',null,'Northern Mariana Islands','Northern Mariana Islands','{}','2024-07-14 20:00',1,'2024-07-14 20:00',1,'n',null,null,'en',' std_checksum',1,null,'y','y',1,'2024-07-14 20:00','1',1,'World',9,'Oceania',57,'Micronesia',null,null,580,'n','n','y','MP','MNP'),('Palau','Palau','/countries/oceania/palau',null,'Palau','Palau','{}','2024-07-14 20:00',1,'2024-07-14 20:00',1,'n',null,null,'en',' std_checksum',1,null,'y','y',1,'2024-07-14 20:00','1',1,'World',9,'Oceania',57,'Micronesia',null,null,585,'n','n','y','PW','PLW'),('United States Minor Outlying Islands','United States Minor Outlying Islands','/countries/oceania/united%20states%20minor%20outlying%20islands',null,'United States Minor Outlying Islands','United States Minor Outlying Islands','{}','2024-07-14 20:00',1,'2024-07-14 20:00',1,'n',null,null,'en',' std_checksum',1,null,'y','y',1,'2024-07-14 20:00','1',1,'World',9,'Oceania',57,'Micronesia',null,null,581,'n','n','n','UM','UMI'),('American Samoa','American Samoa','/countries/oceania/american%20samoa',null,'American Samoa','American Samoa','{}','2024-07-14 20:00',1,'2024-07-14 20:00',1,'n',null,null,'en',' std_checksum',1,null,'y','y',1,'2024-07-14 20:00','1',1,'World',9,'Oceania',61,'Polynesia',null,null,16,'n','n','y','AS','ASM'),('Cook Islands','Cook Islands','/countries/oceania/cook%20islands',null,'Cook Islands','Cook Islands','{}','2024-07-14 20:00',1,'2024-07-14 20:00',1,'n',null,null,'en',' std_checksum',1,null,'y','y',1,'2024-07-14 20:00','1',1,'World',9,'Oceania',61,'Polynesia',null,null,184,'n','n','y','CK','COK'),('French Polynesia','French Polynesia','/countries/oceania/french%20polynesia',null,'French Polynesia','French Polynesia','{}','2024-07-14 20:00',1,'2024-07-14 20:00',1,'n',null,null,'en',' std_checksum',1,null,'y','y',1,'2024-07-14 20:00','1',1,'World',9,'Oceania',61,'Polynesia',null,null,258,'n','n','y','PF','PYF'),('Niue','Niue','/countries/oceania/niue',null,'Niue','Niue','{}','2024-07-14 20:00',1,'2024-07-14 20:00',1,'n',null,null,'en',' std_checksum',1,null,'y','y',1,'2024-07-14 20:00','1',1,'World',9,'Oceania',61,'Polynesia',null,null,570,'n','n','y','NU','NIU'),('Pitcairn','Pitcairn','/countries/oceania/pitcairn',null,'Pitcairn','Pitcairn','{}','2024-07-14 20:00',1,'2024-07-14 20:00',1,'n',null,null,'en',' std_checksum',1,null,'y','y',1,'2024-07-14 20:00','1',1,'World',9,'Oceania',61,'Polynesia',null,null,612,'n','n','n','PN','PCN'),('Samoa','Samoa','/countries/oceania/samoa',null,'Samoa','Samoa','{}','2024-07-14 20:00',1,'2024-07-14 20:00',1,'n',null,null,'en',' std_checksum',1,null,'y','y',1,'2024-07-14 20:00','1',1,'World',9,'Oceania',61,'Polynesia',null,null,882,'n','n','y','WS','WSM'),('Tokelau','Tokelau','/countries/oceania/tokelau',null,'Tokelau','Tokelau','{}','2024-07-14 20:00',1,'2024-07-14 20:00',1,'n',null,null,'en',' std_checksum',1,null,'y','y',1,'2024-07-14 20:00','1',1,'World',9,'Oceania',61,'Polynesia',null,null,772,'n','n','n','TK','TKL'),('Tonga','Tonga','/countries/oceania/tonga',null,'Tonga','Tonga','{}','2024-07-14 20:00',1,'2024-07-14 20:00',1,'n',null,null,'en',' std_checksum',1,null,'y','y',1,'2024-07-14 20:00','1',1,'World',9,'Oceania',61,'Polynesia',null,null,776,'n','n','y','TO','TON'),('Tuvalu','Tuvalu','/countries/oceania/tuvalu',null,'Tuvalu','Tuvalu','{}','2024-07-14 20:00',1,'2024-07-14 20:00',1,'n',null,null,'en',' std_checksum',1,null,'y','y',1,'2024-07-14 20:00','1',1,'World',9,'Oceania',61,'Polynesia',null,null,798,'y','n','y','TV','TUV'),('Wallis and Futuna Islands','Wallis and Futuna Islands','/countries/oceania/wallis%20and%20futuna%20islands',null,'Wallis and Futuna Islands','Wallis and Futuna Islands','{}','2024-07-14 20:00',1,'2024-07-14 20:00',1,'n',null,null,'en',' std_checksum',1,null,'y','y',1,'2024-07-14 20:00','1',1,'World',9,'Oceania',61,'Polynesia',null,null,876,'n','n','n','WF','WLF');


INSERT INTO osc_physrisk_scenarios.scenario
	(std_id, std_description_full, std_description_short, std_name_display, std_name, std_tags, std_datetime_utc_created, std_creator_user_id, std_datetime_utc_last_modified, std_last_modifier_user_id, std_is_deleted, std_deleter_user_id, std_datetime_utc_deleted, std_culture, std_checksum, std_seq_num, std_translated_from_id, std_is_active, std_is_published, std_publisher_id, std_datetime_utc_published)
VALUES 
	('8b3b38fd-a6f5-4878-b4b4-0a251ec0363a', 'Unknown/Not Selected', 'Unknown/Not Selected', 'Unknown/Not Selected', 'Unknown/Not Selected','{ "key1":"value1", "key2":"value2"}', '2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'en', 'f098938cd8cc7c4f1c71c8e97db0f075',1,NULL, 'y','y', 1,'2024-07-15T00:00:01Z')
;
INSERT INTO osc_physrisk_scenarios.scenario
	(std_id, std_slug, std_description_full, std_description_short, std_name_display, std_name,std_tags,  std_datetime_utc_created, std_creator_user_id, std_datetime_utc_last_modified, std_last_modifier_user_id, std_is_deleted, std_deleter_user_id, std_datetime_utc_deleted, std_culture, std_checksum, std_seq_num, std_translated_from_id, std_is_active, std_is_published, std_publisher_id, std_datetime_utc_published)
VALUES 
	('7faf5507-9a0a-4554-aef3-6efe5cffee63','en-climate-scenario-historical', 'History (before 2014). See "Shared Socioeconomic Pathways in the IPCC Sixth Assessment Report" (https://www.ipcc.ch/report/sixth-assessment-report-working-group-i/).', 'History (before 2014)', 'History (- 2014)', 'History (- 2014)','{ "key1":"value1", "key2":"value2"}','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'en', 'std_checksum',1,NULL, 'y','y', 1,'2024-07-15T00:00:01Z')
;
INSERT INTO osc_physrisk_scenarios.scenario
	(std_id, std_slug, std_description_full, std_description_short, std_name_display, std_name, std_tags, std_datetime_utc_created, std_creator_user_id, std_datetime_utc_last_modified, std_last_modifier_user_id, std_is_deleted, std_deleter_user_id, std_datetime_utc_deleted, std_culture, std_checksum, std_seq_num, std_translated_from_id, std_is_active, std_is_published, std_publisher_id, std_datetime_utc_published)
VALUES 
	('0ab07b1d-864d-4f0a-9656-29e9b088df3b','en-climate-scenario-SSP1-19', 'SSP1-1.9 -  very low GHG emissions: CO2 emissions cut to net zero around 2050. See "Shared Socioeconomic Pathways in the IPCC Sixth Assessment Report" (https://www.ipcc.ch/report/sixth-assessment-report-working-group-i/).', 'SSP1-1.9', 'SSP1-1.9', 'SSP1-1.9','{ "key1":"value1", "key2":"value2"}','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'en', 'std_checksum',1,NULL, 'y','y', 1,'2024-07-15T00:00:01Z')
;
INSERT INTO osc_physrisk_scenarios.scenario
	(std_id, std_slug, std_description_full, std_description_short, std_name_display, std_name,std_tags,  std_datetime_utc_created, std_creator_user_id, std_datetime_utc_last_modified, std_last_modifier_user_id, std_is_deleted, std_deleter_user_id, std_datetime_utc_deleted, std_culture, std_checksum, std_seq_num, std_translated_from_id, std_is_active, std_is_published, std_publisher_id, std_datetime_utc_published)
VALUES 
	('cb68b9c6-6dff-4f0d-8650-768249f2689d', 'en-climate-scenario-SSP1-26', 'SSP1-2.6 - low GHG emissions: CO2 emissions cut to net zero around 2075. See "Shared Socioeconomic Pathways in the IPCC Sixth Assessment Report" (https://www.ipcc.ch/report/sixth-assessment-report-working-group-i/).', 'SSP1-2.6', 'SSP1-2.6', 'SSP1-2.6','{ "key1":"value1", "key2":"value2"}','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'en', 'std_checksum',1,NULL, 'y','y', 1,'2024-07-15T00:00:01Z')
;
INSERT INTO osc_physrisk_scenarios.scenario
	(std_id, std_slug, std_description_full, std_description_short, std_name_display, std_name, std_tags, std_datetime_utc_created, std_creator_user_id, std_datetime_utc_last_modified, std_last_modifier_user_id, std_is_deleted, std_deleter_user_id, std_datetime_utc_deleted, std_culture, std_checksum, std_seq_num, std_translated_from_id, std_is_active, std_is_published, std_publisher_id, std_datetime_utc_published)
VALUES 
	('5d1081f3-fd0e-4f53-b06b-8358be82644c', 'en-climate-scenario-SSP2-45', 'SSP2-4.5 - intermediate GHG emissions: CO2 emissions around current levels until 2050, then falling but not reaching net zero by 2100. See "Shared Socioeconomic Pathways in the IPCC Sixth Assessment Report" (https://www.ipcc.ch/report/sixth-assessment-report-working-group-i/).', 'SSP2-4.5', 'SSP2-4.5', 'SSP2-4.5','{ "key1":"value1", "key2":"value2"}','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'en', 'std_checksum',1,NULL, 'y','y', 1,'2024-07-15T00:00:01Z')
;
INSERT INTO osc_physrisk_scenarios.scenario
	(std_id, std_slug, std_description_full, std_description_short, std_name_display, std_name, std_tags, std_datetime_utc_created, std_creator_user_id, std_datetime_utc_last_modified, std_last_modifier_user_id, std_is_deleted, std_deleter_user_id, std_datetime_utc_deleted, std_culture, std_checksum, std_seq_num, std_translated_from_id, std_is_active, std_is_published, std_publisher_id, std_datetime_utc_published)
VALUES 
	('f9ba343c-78b6-426c-be56-5d845e305d58', 'en-climate-scenario-SSP3-70', 'SSP3-7.0 - high GHG emissions: CO2 emissions double by 2100. See "Shared Socioeconomic Pathways in the IPCC Sixth Assessment Report" (https://www.ipcc.ch/report/sixth-assessment-report-working-group-i/).', 'SSP3-7.0', 'SSP3-7.0', 'SSP3-7.0','{ "key1":"value1", "key2":"value2"}','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'en', 'std_checksum',1,NULL, 'y','y', 1,'2024-07-15T00:00:01Z')
;
INSERT INTO osc_physrisk_scenarios.scenario
	(std_id, std_slug, std_description_full, std_description_short, std_name_display, std_name, std_tags, std_datetime_utc_created, std_creator_user_id, std_datetime_utc_last_modified, std_last_modifier_user_id, std_is_deleted, std_deleter_user_id, std_datetime_utc_deleted, std_culture, std_checksum, std_seq_num, std_translated_from_id, std_is_active, std_is_published, std_publisher_id, std_datetime_utc_published)
VALUES 
	('fd76becb-28e9-424b-8c6e-c96aaf6988e5', 'en-climate-scenario-SSP5-85', 'SSP5-8.5 - very high GHG emissions: CO2 emissions triple by 2075. See "Shared Socioeconomic Pathways in the IPCC Sixth Assessment Report" (https://www.ipcc.ch/report/sixth-assessment-report-working-group-i/).', 'SSP5-8.5', 'SSP5-8.5', 'SSP5-8.5','{ "key1":"value1", "key2":"value2"}','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'en', 'std_checksum',1,NULL, 'y','y', 1,'2024-07-15T00:00:01Z')
;
INSERT INTO osc_physrisk_scenarios.scenario
	(std_id, std_slug, std_description_full, std_description_short, std_name_display, std_name, std_tags, std_datetime_utc_created, std_creator_user_id, std_datetime_utc_last_modified, std_last_modifier_user_id, std_is_deleted, std_deleter_user_id, std_datetime_utc_deleted, std_culture, std_checksum, std_seq_num, std_translated_from_id, std_is_active, std_is_published, std_publisher_id, std_datetime_utc_published)
VALUES 
	('3cd34fae-620a-47ae-862c-5349533e73b8', 'en-climate-scenario-RCP26', 'RCP2.6 - Peak in radiative forcing at ~ 3 W/m2 before 2100 and decline. See "REPRESENTATIVE CONCENTRATION PATHWAYS (RCPs)" (https://sedac.ciesin.columbia.edu/ddc/ar5_scenario_process/RCPs.html)', 'RCP2.6', 'RCP2.6', 'RCP2.6','{ "key1":"value1", "key2":"value2"}','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'en', 'std_checksum',1,NULL, 'y','y', 1,'2024-07-15T00:00:01Z')
;
INSERT INTO osc_physrisk_scenarios.scenario
	(std_id, std_slug, std_description_full, std_description_short, std_name_display, std_name, std_tags, std_datetime_utc_created, std_creator_user_id, std_datetime_utc_last_modified, std_last_modifier_user_id, std_is_deleted, std_deleter_user_id, std_datetime_utc_deleted, std_culture, std_checksum, std_seq_num, std_translated_from_id, std_is_active, std_is_published, std_publisher_id, std_datetime_utc_published)
VALUES 
	('e64b3f6a-69a6-403f-a4bb-e099fe099222', 'en-climate-scenario-RCP45', 'RCP4.5 - Stabilization without overshoot pathway to 4.5 W/m2 at stabilization after 2100. See "REPRESENTATIVE CONCENTRATION PATHWAYS (RCPs)" (https://sedac.ciesin.columbia.edu/ddc/ar5_scenario_process/RCPs.html)', 'RCP4.5', 'RCP4.5', 'RCP4.5','{ "key1":"value1", "key2":"value2"}','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'en', 'std_checksum',1,NULL, 'y','y', 1,'2024-07-15T00:00:01Z')
;
INSERT INTO osc_physrisk_scenarios.scenario
	(std_id, std_slug, std_description_full, std_description_short, std_name_display, std_name, std_tags, std_datetime_utc_created, std_creator_user_id, std_datetime_utc_last_modified, std_last_modifier_user_id, std_is_deleted, std_deleter_user_id, std_datetime_utc_deleted, std_culture, std_checksum, std_seq_num, std_translated_from_id, std_is_active, std_is_published, std_publisher_id, std_datetime_utc_published)
VALUES 
	('bb01865e-2a53-48a3-9437-35764ba52639',  'en-climate-scenario-RCP6', 'RCP6 - Stabilization without overshoot pathway to 6 W/m2 at stabilization after 2100. See "REPRESENTATIVE CONCENTRATION PATHWAYS (RCPs)" (https://sedac.ciesin.columbia.edu/ddc/ar5_scenario_process/RCPs.html)', 'RCP6', 'RCP6', 'RCP6','{ "key1":"value1", "key2":"value2"}','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'en', 'std_checksum',1,NULL, 'y','y', 1,'2024-07-15T00:00:01Z')
;
INSERT INTO osc_physrisk_scenarios.scenario
	(std_id, std_slug, std_description_full, std_description_short, std_name_display, std_name,std_tags,  std_datetime_utc_created, std_creator_user_id, std_datetime_utc_last_modified, std_last_modifier_user_id, std_is_deleted, std_deleter_user_id, std_datetime_utc_deleted, std_culture, std_checksum, std_seq_num, std_translated_from_id, std_is_active, std_is_published, std_publisher_id, std_datetime_utc_published)
VALUES 
	('893a6b75-8660-47ff-80d3-08b4ddc259c3', 'en-climate-scenario-RCP85', 'RCP8.5 - Rising radiative forcing pathway leading to 8.5 W/m2 in 2100. See "REPRESENTATIVE CONCENTRATION PATHWAYS (RCPs)" (https://sedac.ciesin.columbia.edu/ddc/ar5_scenario_process/RCPs.html)', 'RCP8.5', 'RCP8.5', 'RCP8.5','{ "key1":"value1", "key2":"value2"}','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'en', 'std_checksum',1,NULL, 'y','y', 1,'2024-07-15T00:00:01Z')
;

INSERT INTO osc_physrisk_vulnerability_analysis.vulnerability_type
	(std_id, std_description_full, std_description_short, std_name_display, std_name, std_tags, std_datetime_utc_created, std_creator_user_id, std_datetime_utc_last_modified, std_last_modifier_user_id, std_is_deleted, std_deleter_user_id, std_datetime_utc_deleted, std_culture, std_checksum, std_seq_num, std_translated_from_id, std_is_active, std_is_published, std_publisher_id, std_datetime_utc_published)
VALUES 
	(-1, 'Unknown Damage or Disruption', 'Unknown Damage or Disruption', 'Unknown Damage or Disruption', 'Unknown Damage or Disruption','{ "key1":"value1", "key2":"value2"}','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'f',NULL,NULL, 'en', 'std_checksum',1,NULL, 't',  't',1 ,'2024-07-15T00:00:01Z')
;
INSERT INTO osc_physrisk_vulnerability_analysis.vulnerability_type
	(std_id, std_description_full, std_description_short, std_name_display, std_name, std_tags, std_datetime_utc_created, std_creator_user_id, std_datetime_utc_last_modified, std_last_modifier_user_id, std_is_deleted, std_deleter_user_id, std_datetime_utc_deleted, std_culture, std_checksum, std_seq_num, std_translated_from_id, std_is_active, std_is_published, std_publisher_id, std_datetime_utc_published)
VALUES 
	(1, 'Damage as percentage of asset value', 'Damage as percentage of asset value', 'Damage as percentage of asset value', 'Damage as percentage of asset value','{ "key1":"value1", "key2":"value2"}','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'f',NULL,NULL, 'en', 'std_checksum',1,NULL, 't',  't',1 ,'2024-07-15T00:00:01Z')
;
INSERT INTO osc_physrisk_vulnerability_analysis.vulnerability_type
	(std_id, std_description_full, std_description_short, std_name_display, std_name, std_tags, std_datetime_utc_created, std_creator_user_id, std_datetime_utc_last_modified, std_last_modifier_user_id, std_is_deleted, std_deleter_user_id, std_datetime_utc_deleted, std_culture, std_checksum, std_seq_num, std_translated_from_id, std_is_active, std_is_published, std_publisher_id, std_datetime_utc_published)
VALUES 
	(2, 'Disruption in number of production units', 'Disruption in number of production units', 'Disruption in number of production units', 'Disruption in number of production units','{ "key1":"value1", "key2":"value2"}','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'f',NULL,NULL, 'en', 'std_checksum',1,NULL, 't',  't',1 ,'2024-07-15T00:00:01Z')
;

INSERT INTO osc_physrisk_financial_analysis.financial_impact_type
	(std_id, std_description_full, std_description_short, std_name_display, std_name, std_tags, std_datetime_utc_created, std_creator_user_id, std_datetime_utc_last_modified, std_last_modifier_user_id, std_is_deleted, std_deleter_user_id, std_datetime_utc_deleted, std_culture, std_checksum, std_seq_num, std_translated_from_id, std_is_active, std_is_published, std_publisher_id, std_datetime_utc_published)
VALUES 
	(-1, 'Unknown Damage or Disruption', 'Unknown Damage or Disruption', 'Unknown Damage or Disruption', 'Unknown Damage or Disruption','{ "key1":"value1", "key2":"value2"}','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'f',NULL,NULL, 'en', 'std_checksum',1,NULL, 't',  't',1 ,'2024-07-15T00:00:01Z')
;
INSERT INTO osc_physrisk_financial_analysis.financial_impact_type
	(std_id, std_name, std_name_display, std_description_full, std_description_short, std_tags, std_datetime_utc_created, std_creator_user_id, std_datetime_utc_last_modified, std_last_modifier_user_id, std_is_deleted, std_deleter_user_id, std_datetime_utc_deleted, std_culture, std_checksum, std_seq_num, std_translated_from_id, std_is_active, std_is_published, std_publisher_id, std_datetime_utc_published, accounting_category)
VALUES 
	(1, 'Asset repairs and construction', 'Asset repairs and construction', 'Asset repairs and construction','Asset repairs and construction', '{ "key1":"value1", "key2":"value2"}', '2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1, 'false',NULL,NULL, 'en', 'std_checksum',1,NULL, 't',  't',1 ,'2024-07-15T00:00:01Z','Capex' );
INSERT INTO osc_physrisk_financial_analysis.financial_impact_type
	(std_id, std_name, std_name_display, std_description_full, std_description_short, std_tags, std_datetime_utc_created, std_creator_user_id, std_datetime_utc_last_modified, std_last_modifier_user_id, std_is_deleted, std_deleter_user_id, std_datetime_utc_deleted, std_culture, std_checksum, std_seq_num, std_translated_from_id, std_is_active, std_is_published, std_publisher_id, std_datetime_utc_published, accounting_category)
VALUES 
	(2, 'Revenue loss due to asset restoration', 'Revenue loss due to asset restoration', 'Revenue loss due to asset restoration','Revenue loss due to asset restoration', '{ "key1":"value1", "key2":"value2"}', '2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1, 'false',NULL,NULL, 'en', 'std_checksum',1,NULL, 't',  't',1 ,'2024-07-15T00:00:01Z','Revenue' );
INSERT INTO osc_physrisk_financial_analysis.financial_impact_type
	(std_id, std_name, std_name_display, std_description_full, std_description_short, std_tags, std_datetime_utc_created, std_creator_user_id, std_datetime_utc_last_modified, std_last_modifier_user_id, std_is_deleted, std_deleter_user_id, std_datetime_utc_deleted, std_culture, std_checksum, std_seq_num, std_translated_from_id, std_is_active, std_is_published, std_publisher_id, std_datetime_utc_published, accounting_category)
VALUES 
	(3, 'Revenue loss due to productivity impact', 'Revenue loss due to productivity impact', 'Revenue loss due to productivity impact','Revenue loss due to productivity impact', '{ "key1":"value1", "key2":"value2"}', '2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1, 'false',NULL,NULL, 'en', 'std_checksum',1,NULL, 't',  't',1 ,'2024-07-15T00:00:01Z','Revenue' );
INSERT INTO osc_physrisk_financial_analysis.financial_impact_type
	(std_id, std_name, std_name_display, std_description_full, std_description_short, std_tags, std_datetime_utc_created, std_creator_user_id, std_datetime_utc_last_modified, std_last_modifier_user_id, std_is_deleted, std_deleter_user_id, std_datetime_utc_deleted, std_culture, std_checksum, std_seq_num, std_translated_from_id, std_is_active, std_is_published, std_publisher_id, std_datetime_utc_published, accounting_category)
VALUES 
	(4, 'Recurring cost increase (chronic)', 'Recurring cost increase (chronic)', 'Recurring cost increase (chronic)','Recurring cost increase (chronic)', '{ "key1":"value1", "key2":"value2"}', '2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1, 'false',NULL,NULL, 'en', 'std_checksum',1,NULL, 't',  't',1 ,'2024-07-15T00:00:01Z','OpEx' );
INSERT INTO osc_physrisk_financial_analysis.financial_impact_type
	(std_id, std_name, std_name_display, std_description_full, std_description_short, std_tags, std_datetime_utc_created, std_creator_user_id, std_datetime_utc_last_modified, std_last_modifier_user_id, std_is_deleted, std_deleter_user_id, std_datetime_utc_deleted, std_culture, std_checksum, std_seq_num, std_translated_from_id, std_is_active, std_is_published, std_publisher_id, std_datetime_utc_published, accounting_category)
VALUES 
	(5, 'Recurring cost increase (acute)', 'Recurring cost increase (acute)', 'Recurring cost increase (acute)','Recurring cost increase (acute)', '{ "key1":"value1", "key2":"value2"}', '2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1, 'false',NULL,NULL, 'en', 'std_checksum',1,NULL, 't',  't',1 ,'2024-07-15T00:00:01Z','OpEx' );
INSERT INTO osc_physrisk_scenarios.hazard
	(std_id, std_slug, std_name, std_name_display, std_description_full, std_description_short, std_tags, std_datetime_utc_created, std_creator_user_id, std_datetime_utc_last_modified, std_last_modifier_user_id, std_is_deleted, std_deleter_user_id, std_datetime_utc_deleted, std_culture, std_checksum, std_seq_num, std_translated_from_id, std_is_active, std_is_published, std_publisher_id, std_datetime_utc_published)
VALUES 
	('8159d927-e596-444d-8f1a-494494339fad', 'en-climate-hazard-type-unknown', 'Unknown hazard/Not selected', 'Unknown hazard/Not selected', 'Unknown hazard/Not selected', 'Unknown hazard/Not selected', '{ "key1":"value1", "key2":"value2"}','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'en', 'std_checksum',1, NULL,'y','y',1,'2024-07-15T00:00:01Z')
;
INSERT INTO osc_physrisk_scenarios.hazard
	(std_id, std_slug, std_name, std_name_display, std_description_full, std_description_short, std_tags, std_datetime_utc_created, std_creator_user_id, std_datetime_utc_last_modified, std_last_modifier_user_id, std_is_deleted, std_deleter_user_id, std_datetime_utc_deleted, std_culture, std_checksum, std_seq_num, std_translated_from_id, std_is_active, std_is_published, std_publisher_id, std_datetime_utc_published)
VALUES 
	('63ed7943-c4c4-43ea-abd2-86bb1997a094', 'en-climate-hazard-type-inundation-riverine', 'Riverine Inundation', 'Riverine Inundation', 'Riverine Inundation', 'Riverine Inundation', '{ "key1":"value1", "key2":"value2"}','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'en', 'std_checksum',1, NULL,'y', 'y',1,'2024-07-15T00:00:01Z')
;
INSERT INTO osc_physrisk_scenarios.hazard
	(std_id, std_slug, std_name, std_name_display, std_description_full, std_description_short, std_tags, std_datetime_utc_created, std_creator_user_id, std_datetime_utc_last_modified, std_last_modifier_user_id, std_is_deleted, std_deleter_user_id, std_datetime_utc_deleted, std_culture, std_checksum, std_seq_num, std_translated_from_id, std_is_active, std_is_published, std_publisher_id, std_datetime_utc_published)
VALUES 
	('28a095cd-4cde-40a1-90d9-cbb0ca673c06', 'en-climate-hazard-type-inundation-coastal', 'Coastal Inundation', 'Coastal Inundation', 'Coastal Inundation', 'Coastal Inundation', '{ "key1":"value1", "key2":"value2"}','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'en', 'std_checksum',1, NULL,'y','y',1,'2024-07-15T00:00:01Z')
;
INSERT INTO osc_physrisk_scenarios.hazard
	(std_id, std_slug,std_name,  std_name_display, std_description_full, std_description_short, std_tags, std_datetime_utc_created, std_creator_user_id, std_datetime_utc_last_modified, std_last_modifier_user_id, std_is_deleted, std_deleter_user_id, std_datetime_utc_deleted, std_culture, std_checksum, std_seq_num, std_translated_from_id, std_is_active, std_is_published, std_publisher_id, std_datetime_utc_published)
VALUES 
	('338ea109-828e-4aaf-b212-12d8eaf70a7e', 'en-climate-hazard-type-inundation-combined','Combined Inundation', 'Combined Inundation', 'Combined Inundation', 'Combined Inundation', '{ "key1":"value1", "key2":"value2"}','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'en', 'std_checksum',1, NULL,'y','y',1,'2024-07-15T00:00:01Z')
;
INSERT INTO osc_physrisk_scenarios.hazard
	(std_id, std_slug, std_name, std_name_display, std_description_full, std_description_short, std_tags, std_datetime_utc_created, std_creator_user_id, std_datetime_utc_last_modified, std_last_modifier_user_id, std_is_deleted, std_deleter_user_id, std_datetime_utc_deleted, std_culture, std_checksum, std_seq_num, std_translated_from_id, std_is_active, std_is_published, std_publisher_id, std_datetime_utc_published)
VALUES 
	('d08db675-ee1e-48fe-b9e1-b0da27de8f2b', 'en-climate-hazard-type-chronic-heat', 'Chronic Heat', 'Chronic Heat', 'Chronic Heat', 'Chronic Heat', '{ "key1":"value1", "key2":"value2"}','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'en', 'std_checksum',1, NULL,'y','y',1,'2024-07-15T00:00:01Z')
;
INSERT INTO osc_physrisk_scenarios.hazard
	(std_id, std_slug, std_name, std_name_display, std_description_full, std_description_short, std_tags, std_datetime_utc_created, std_creator_user_id, std_datetime_utc_last_modified, std_last_modifier_user_id, std_is_deleted, std_deleter_user_id, std_datetime_utc_deleted, std_culture, std_checksum, std_seq_num, std_translated_from_id, std_is_active, std_is_published, std_publisher_id, std_datetime_utc_published)
VALUES 
	('64fee0d3-b78b-49bf-911a-029695585d6a', 'en-climate-hazard-type-fire','Fire', 'Fire', 'Fire', 'Fire', '{ "key1":"value1", "key2":"value2"}','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'en', 'std_checksum',1, NULL,'y','y',1,'2024-07-15T00:00:01Z')
;
INSERT INTO osc_physrisk_scenarios.hazard
	(std_id, std_slug, std_name, std_name_display, std_description_full, std_description_short, std_tags, std_datetime_utc_created, std_creator_user_id, std_datetime_utc_last_modified, std_last_modifier_user_id, std_is_deleted, std_deleter_user_id, std_datetime_utc_deleted, std_culture, std_checksum, std_seq_num, std_translated_from_id, std_is_active, std_is_published, std_publisher_id, std_datetime_utc_published)
VALUES 
	('35ace20f-86dc-4735-9536-129b51b6d25d', 'en-climate-hazard-type-drought','Drought', 'Drought', 'Drought', 'Drought', '{ "key1":"value1", "key2":"value2"}','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'en', 'std_checksum',1, NULL,'y','y',1,'2024-07-15T00:00:01Z')
;
INSERT INTO osc_physrisk_scenarios.hazard
	(std_id, std_slug,std_name,  std_name_display, std_description_full, std_description_short, std_tags, std_datetime_utc_created, std_creator_user_id, std_datetime_utc_last_modified, std_last_modifier_user_id, std_is_deleted, std_deleter_user_id, std_datetime_utc_deleted, std_culture, std_checksum, std_seq_num, std_translated_from_id, std_is_active, std_is_published, std_publisher_id, std_datetime_utc_published)
VALUES 
	('2faed491-2c5d-499e-9568-fad6e3b3c0ec', 'en-climate-hazard-type-precipitation','Precipitation', 'Precipitation', 'Precipitation', 'Precipitation', '{ "key1":"value1", "key2":"value2"}','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'en', 'std_checksum',1, NULL,'y','y',1,'2024-07-15T00:00:01Z')
;
INSERT INTO osc_physrisk_scenarios.hazard
	(std_id, std_slug, std_name, std_name_display, std_description_full, std_description_short, std_tags, std_datetime_utc_created, std_creator_user_id, std_datetime_utc_last_modified, std_last_modifier_user_id, std_is_deleted, std_deleter_user_id, std_datetime_utc_deleted, std_culture, std_checksum, std_seq_num, std_translated_from_id, std_is_active, std_is_published, std_publisher_id, std_datetime_utc_published)
VALUES 
	('29514258-18cb-4f2b-8798-203e0d513803', 'en-climate-hazard-type-water-risk','Water Risk', 'Water Risk', 'Water Risk', 'Water Risk', '{ "key1":"value1", "key2":"value2"}','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'en', 'std_checksum',1, NULL,'y','y',1,'2024-07-15T00:00:01Z')
;
INSERT INTO osc_physrisk_scenarios.hazard
	(std_id, std_slug, std_name, std_name_display, std_description_full, std_description_short, std_tags, std_datetime_utc_created, std_creator_user_id, std_datetime_utc_last_modified, std_last_modifier_user_id, std_is_deleted, std_deleter_user_id, std_datetime_utc_deleted, std_culture, std_checksum, std_seq_num, std_translated_from_id, std_is_active, std_is_published, std_publisher_id, std_datetime_utc_published)
VALUES 
	('e4e4e199-367e-4568-824d-3f916e355567', 'en-climate-hazard-type-hail','Hail', 'Hail', 'Hail', 'Hail', '{ "key1":"value1", "key2":"value2"}','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'en', 'std_checksum',1, NULL,'y','y',1,'2024-07-15T00:00:01Z')
;
INSERT INTO osc_physrisk_scenarios.hazard
	(std_id, std_slug, std_name, std_name_display, std_description_full, std_description_short, std_tags, std_datetime_utc_created, std_creator_user_id, std_datetime_utc_last_modified, std_last_modifier_user_id, std_is_deleted, std_deleter_user_id, std_datetime_utc_deleted, std_culture, std_checksum, std_seq_num, std_translated_from_id, std_is_active, std_is_published, std_publisher_id, std_datetime_utc_published)
VALUES 
	('0184b858-404d-4282-8f0d-2b4c42f7acd7', 'en-climate-hazard-type-wind','Wind', 'Wind', 'Wind', 'Wind', '{ "key1":"value1", "key2":"value2"}','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'en', 'std_checksum',1, NULL,'y','y',1,'2024-07-15T00:00:01Z')
;
INSERT INTO osc_physrisk_scenarios.hazard
	(std_id, std_slug, std_name, std_name_display, std_description_full, std_description_short, std_tags, std_datetime_utc_created, std_creator_user_id, std_datetime_utc_last_modified, std_last_modifier_user_id, std_is_deleted, std_deleter_user_id, std_datetime_utc_deleted, std_culture, std_checksum, std_seq_num, std_translated_from_id, std_is_active, std_is_published, std_publisher_id, std_datetime_utc_published)
VALUES 
	('4441cf3b-1460-4131-aff6-b51bf01cd084', 'en-climate-hazard-type-subsidence','subsidence', 'subsidence', 'subsidence', 'subsidence', '{ "key1":"value1", "key2":"value2"}','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'en', 'std_checksum',1, NULL,'y','y',1,'2024-07-15T00:00:01Z')
;
INSERT INTO osc_physrisk_scenarios.hazard_indicator
	(std_id, std_name, std_name_display, std_description_full, std_description_short, std_tags, std_datetime_utc_created, std_creator_user_id, std_datetime_utc_last_modified, std_last_modifier_user_id, std_is_deleted, std_deleter_user_id, std_datetime_utc_deleted, std_culture, std_checksum, std_seq_num, std_translated_from_id, std_is_active, std_is_published, std_publisher_id, std_datetime_utc_published, hazard_id)
VALUES 
	('57a7df66-420d-4730-9669-1547f8200272', 'Flood depth (TUDelft)', 'Flood depth (TUDelft)', 'Flood depth (TUDelft)', 'Flood depth (TUDelft)', '{ "key1":"value1", "key2":"value2"}','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'en', 'std_checksum',1, NULL,'y','y',1,'2024-07-15T00:00:01Z', '63ed7943-c4c4-43ea-abd2-86bb1997a094')
;
INSERT INTO osc_physrisk_scenarios.hazard_indicator
	(std_id, std_name, std_name_display, std_description_full, std_description_short, std_tags, std_datetime_utc_created, std_creator_user_id, std_datetime_utc_last_modified, std_last_modifier_user_id, std_is_deleted, std_deleter_user_id, std_datetime_utc_deleted, std_culture, std_checksum, std_seq_num, std_translated_from_id, std_is_active, std_is_published, std_publisher_id, std_datetime_utc_published, hazard_id)
VALUES 
	('5fb27cc6-ee01-4133-b2e9-6c1f22ed5b40', 'Flood depth/GFDL-ESM2M (WRI)', 'Flood depth/GFDL-ESM2M (WRI)', 'Flood depth/GFDL-ESM2M (WRI)', 'Flood depth/GFDL-ESM2M (WRI)', '{ "key1":"value1", "key2":"value2"}','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'en', 'std_checksum',1, NULL,'y','y',1,'2024-07-15T00:00:01Z', '63ed7943-c4c4-43ea-abd2-86bb1997a094')
;
INSERT INTO osc_physrisk_scenarios.hazard_indicator
	(std_id, std_name, std_name_display, std_description_full, std_description_short, std_tags, std_datetime_utc_created, std_creator_user_id, std_datetime_utc_last_modified, std_last_modifier_user_id, std_is_deleted, std_deleter_user_id, std_datetime_utc_deleted, std_culture, std_checksum, std_seq_num, std_translated_from_id, std_is_active, std_is_published, std_publisher_id, std_datetime_utc_published, hazard_id)
VALUES 
	('79555143-ba2a-47b0-bbe7-7aac3685dedb', 'Flood depth/HadGEM2-ES (WRI)', 'Flood depth/HadGEM2-ES (WRI)', 'Flood depth/HadGEM2-ES (WRI)', 'Flood depth/HadGEM2-ES (WRI)', '{ "key1":"value1", "key2":"value2"}','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'en', 'std_checksum',1, NULL,'y','y',1,'2024-07-15T00:00:01Z', '63ed7943-c4c4-43ea-abd2-86bb1997a094')
;
INSERT INTO osc_physrisk_scenarios.hazard_indicator
	(std_id, std_name, std_name_display, std_description_full, std_description_short, std_tags, std_datetime_utc_created, std_creator_user_id, std_datetime_utc_last_modified, std_last_modifier_user_id, std_is_deleted, std_deleter_user_id, std_datetime_utc_deleted, std_culture, std_checksum, std_seq_num, std_translated_from_id, std_is_active, std_is_published, std_publisher_id, std_datetime_utc_published, hazard_id)
VALUES 
	('6fe5ccb1-5d38-4a3e-b0a5-d4cc70981035', 'Flood depth/IPSL-CM5A-LR (WRI)', 'Flood depth/IPSL-CM5A-LR (WRI)', 'Flood depth/IPSL-CM5A-LR (WRI)', 'Flood depth/IPSL-CM5A-LR (WRI)', '{ "key1":"value1", "key2":"value2"}','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'en', 'std_checksum',1, NULL,'y','y',1,'2024-07-15T00:00:01Z', '63ed7943-c4c4-43ea-abd2-86bb1997a094')
;
INSERT INTO osc_physrisk_scenarios.hazard_indicator
	(std_id, std_name, std_name_display, std_description_full, std_description_short, std_tags, std_datetime_utc_created, std_creator_user_id, std_datetime_utc_last_modified, std_last_modifier_user_id, std_is_deleted, std_deleter_user_id, std_datetime_utc_deleted, std_culture, std_checksum, std_seq_num, std_translated_from_id, std_is_active, std_is_published, std_publisher_id, std_datetime_utc_published, hazard_id)
VALUES 
	('e4f10569-95be-4b5b-8d34-763eb95e730b', 'Flood depth/MIROC-ESM-CHEM (WRI)', 'Flood depth/MIROC-ESM-CHEM (WRI)', 'Flood depth/MIROC-ESM-CHEM (WRI)', 'Flood depth/MIROC-ESM-CHEM (WRI)', '{ "key1":"value1", "key2":"value2"}','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'en', 'std_checksum',1, NULL,'y','y',1,'2024-07-15T00:00:01Z', '63ed7943-c4c4-43ea-abd2-86bb1997a094')
;
INSERT INTO osc_physrisk_scenarios.hazard_indicator
	(std_id, std_name, std_name_display, std_description_full, std_description_short, std_tags, std_datetime_utc_created, std_creator_user_id, std_datetime_utc_last_modified, std_last_modifier_user_id, std_is_deleted, std_deleter_user_id, std_datetime_utc_deleted, std_culture, std_checksum, std_seq_num, std_translated_from_id, std_is_active, std_is_published, std_publisher_id, std_datetime_utc_published, hazard_id)
VALUES 
	('690e01eb-f7e6-4fbf-84e4-f8195656abb3', 'Flood depth/NorESM1-M (WRI)', 'Flood depth/NorESM1-M (WRI)', 'Flood depth/NorESM1-M (WRI)', 'Flood depth/NorESM1-M (WRI)', '{ "key1":"value1", "key2":"value2"}','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'en', 'std_checksum',1, NULL,'y','y',1,'2024-07-15T00:00:01Z', '63ed7943-c4c4-43ea-abd2-86bb1997a094')
;
INSERT INTO osc_physrisk_scenarios.hazard_indicator
	(std_id, std_name, std_name_display, std_description_full, std_description_short, std_tags, std_datetime_utc_created, std_creator_user_id, std_datetime_utc_last_modified, std_last_modifier_user_id, std_is_deleted, std_deleter_user_id, std_datetime_utc_deleted, std_culture, std_checksum, std_seq_num, std_translated_from_id, std_is_active, std_is_published, std_publisher_id, std_datetime_utc_published, hazard_id)
VALUES 
	('5f396b97-badc-40d2-b0b3-c8be8f3053ba', 'Flood depth/baseline (WRI)', 'Flood depth/baseline (WRI)', 'Flood depth/baseline (WRI)', 'Flood depth/baseline (WRI)', '{ "key1":"value1", "key2":"value2"}','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'en', 'std_checksum',1, NULL,'y','y',1,'2024-07-15T00:00:01Z', '63ed7943-c4c4-43ea-abd2-86bb1997a094')
;
INSERT INTO osc_physrisk_scenarios.hazard_indicator
	(std_id, std_name, std_name_display, std_description_full, std_description_short, std_tags, std_datetime_utc_created, std_creator_user_id, std_datetime_utc_last_modified, std_last_modifier_user_id, std_is_deleted, std_deleter_user_id, std_datetime_utc_deleted, std_culture, std_checksum, std_seq_num, std_translated_from_id, std_is_active, std_is_published, std_publisher_id, std_datetime_utc_published, hazard_id)
VALUES 
	('901cbd14-9223-4d36-8ab4-658945d913a4', 'Standard of protection (TUDelft)', 'Standard of protection (TUDelft)', 'Standard of protection (TUDelft)', 'Standard of protection (TUDelft)', '{ "key1":"value1", "key2":"value2"}','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'en', 'std_checksum',1, NULL,'y','y',1,'2024-07-15T00:00:01Z', '63ed7943-c4c4-43ea-abd2-86bb1997a094')
;
INSERT INTO osc_physrisk_scenarios.hazard_indicator
	(std_id, std_name, std_name_display, std_description_full, std_description_short, std_tags, std_datetime_utc_created, std_creator_user_id, std_datetime_utc_last_modified, std_last_modifier_user_id, std_is_deleted, std_deleter_user_id, std_datetime_utc_deleted, std_culture, std_checksum, std_seq_num, std_translated_from_id, std_is_active, std_is_published, std_publisher_id, std_datetime_utc_published, hazard_id)
VALUES 
	('be44d6fb-08cb-4f52-8ff2-bf1b7366a7a0', 'Flood depth/5%, no subsstd_idence (WRI)', 'Flood depth/5%, no subsstd_idence (WRI)', 'Flood depth/5%, no subsstd_idence (WRI)', 'Flood depth/5%, no subsstd_idence (WRI)', '{ "key1":"value1", "key2":"value2"}','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'en', 'std_checksum',1, NULL,'y','y',1,'2024-07-15T00:00:01Z', '28a095cd-4cde-40a1-90d9-cbb0ca673c06')
;
INSERT INTO osc_physrisk_scenarios.hazard_indicator
	(std_id, std_name, std_name_display, std_description_full, std_description_short, std_tags, std_datetime_utc_created, std_creator_user_id, std_datetime_utc_last_modified, std_last_modifier_user_id, std_is_deleted, std_deleter_user_id, std_datetime_utc_deleted, std_culture, std_checksum, std_seq_num, std_translated_from_id, std_is_active, std_is_published, std_publisher_id, std_datetime_utc_published, hazard_id)
VALUES 
	('c87fc5c3-c2ae-4732-ba52-7d9156044d7b', 'Flood depth/5%, with subsstd_idence (WRI)', 'Flood depth/5%, with subsstd_idence (WRI)', 'Flood depth/5%, with subsstd_idence (WRI)', 'Flood depth/5%, with subsstd_idence (WRI)', '{ "key1":"value1", "key2":"value2"}','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'en', 'std_checksum',1, NULL,'y','y',1,'2024-07-15T00:00:01Z', '28a095cd-4cde-40a1-90d9-cbb0ca673c06')
;
INSERT INTO osc_physrisk_scenarios.hazard_indicator
	(std_id, std_name, std_name_display, std_description_full, std_description_short, std_tags, std_datetime_utc_created, std_creator_user_id, std_datetime_utc_last_modified, std_last_modifier_user_id, std_is_deleted, std_deleter_user_id, std_datetime_utc_deleted, std_culture, std_checksum, std_seq_num, std_translated_from_id, std_is_active, std_is_published, std_publisher_id, std_datetime_utc_published, hazard_id)
VALUES 
	('60c90be9-5cfb-4f6a-b9eb-e84e7da5a456', 'Flood depth/50%, no subsstd_idence (WRI)', 'Flood depth/50%, no subsstd_idence (WRI)', 'Flood depth/50%, no subsstd_idence (WRI)', 'Flood depth/50%, no subsstd_idence (WRI)', '{ "key1":"value1", "key2":"value2"}','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'en', 'std_checksum',1, NULL,'y','y',1,'2024-07-15T00:00:01Z', '28a095cd-4cde-40a1-90d9-cbb0ca673c06')
;
INSERT INTO osc_physrisk_scenarios.hazard_indicator
	(std_id, std_name, std_name_display, std_description_full, std_description_short, std_tags, std_datetime_utc_created, std_creator_user_id, std_datetime_utc_last_modified, std_last_modifier_user_id, std_is_deleted, std_deleter_user_id, std_datetime_utc_deleted, std_culture, std_checksum, std_seq_num, std_translated_from_id, std_is_active, std_is_published, std_publisher_id, std_datetime_utc_published, hazard_id)
VALUES 
	('e7623e9e-649e-460a-8b81-ae9d01711f75', 'Flood depth/50%, with subsstd_idence (WRI)', 'Flood depth/50%, with subsstd_idence (WRI)', 'Flood depth/50%, with subsstd_idence (WRI)', 'Flood depth/50%, with subsstd_idence (WRI)', '{ "key1":"value1", "key2":"value2"}','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'en', 'std_checksum',1, NULL,'y','y',1,'2024-07-15T00:00:01Z', '28a095cd-4cde-40a1-90d9-cbb0ca673c06')
;
INSERT INTO osc_physrisk_scenarios.hazard_indicator
	(std_id, std_name, std_name_display, std_description_full, std_description_short, std_tags, std_datetime_utc_created, std_creator_user_id, std_datetime_utc_last_modified, std_last_modifier_user_id, std_is_deleted, std_deleter_user_id, std_datetime_utc_deleted, std_culture, std_checksum, std_seq_num, std_translated_from_id, std_is_active, std_is_published, std_publisher_id, std_datetime_utc_published, hazard_id)
VALUES 
	('28fbe059-a661-4fe6-8ba7-0fa626a9312b', 'Flood depth/95%, no subsstd_idence (WRI)', 'Flood depth/95%, no subsstd_idence (WRI)', 'Flood depth/95%, no subsstd_idence (WRI)', 'Flood depth/95%, no subsstd_idence (WRI)', '{ "key1":"value1", "key2":"value2"}','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'en', 'std_checksum',1, NULL,'y','y',1,'2024-07-15T00:00:01Z', '28a095cd-4cde-40a1-90d9-cbb0ca673c06')
;
INSERT INTO osc_physrisk_scenarios.hazard_indicator
	(std_id, std_name, std_name_display, std_description_full, std_description_short, std_tags, std_datetime_utc_created, std_creator_user_id, std_datetime_utc_last_modified, std_last_modifier_user_id, std_is_deleted, std_deleter_user_id, std_datetime_utc_deleted, std_culture, std_checksum, std_seq_num, std_translated_from_id, std_is_active, std_is_published, std_publisher_id, std_datetime_utc_published, hazard_id)
VALUES 
	('ea005e03-f025-4aa4-a37e-981eea5bcfdb', 'Flood depth/95%, with subsstd_idence (WRI)', 'Flood depth/95%, with subsstd_idence (WRI)', 'Flood depth/95%, with subsstd_idence (WRI)', 'Flood depth/95%, with subsstd_idence (WRI)', '{ "key1":"value1", "key2":"value2"}','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'en', 'std_checksum',1, NULL,'y','y',1,'2024-07-15T00:00:01Z', '28a095cd-4cde-40a1-90d9-cbb0ca673c06')
;
INSERT INTO osc_physrisk_scenarios.hazard_indicator
	(std_id, std_name, std_name_display, std_description_full, std_description_short, std_tags, std_datetime_utc_created, std_creator_user_id, std_datetime_utc_last_modified, std_last_modifier_user_id, std_is_deleted, std_deleter_user_id, std_datetime_utc_deleted, std_culture, std_checksum, std_seq_num, std_translated_from_id, std_is_active, std_is_published, std_publisher_id, std_datetime_utc_published, hazard_id)
VALUES 
	('12651bc5-04a2-4225-ba25-f1c0e09bdb90', 'Flood depth/baseline, no subsstd_idence (WRI)', 'Flood depth/baseline, no subsstd_idence (WRI)', 'Flood depth/baseline, no subsstd_idence (WRI)', 'Flood depth/baseline, no subsstd_idence (WRI)', '{ "key1":"value1", "key2":"value2"}','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'en', 'std_checksum',1, NULL,'y','y',1,'2024-07-15T00:00:01Z', '28a095cd-4cde-40a1-90d9-cbb0ca673c06')
;
INSERT INTO osc_physrisk_scenarios.hazard_indicator
	(std_id, std_name, std_name_display, std_description_full, std_description_short, std_tags, std_datetime_utc_created, std_creator_user_id, std_datetime_utc_last_modified, std_last_modifier_user_id, std_is_deleted, std_deleter_user_id, std_datetime_utc_deleted, std_culture, std_checksum, std_seq_num, std_translated_from_id, std_is_active, std_is_published, std_publisher_id, std_datetime_utc_published, hazard_id)
VALUES 
	('6ba57474-6c7a-4ea3-aca8-25e30f27cec1', 'Flood depth/baseline, with subsstd_idence (WRI)', 'Flood depth/baseline, with subsstd_idence (WRI)', 'Flood depth/baseline, with subsstd_idence (WRI)', 'Flood depth/baseline, with subsstd_idence (WRI)', '{ "key1":"value1", "key2":"value2"}','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'en', 'std_checksum',1, NULL,'y','y',1,'2024-07-15T00:00:01Z', '28a095cd-4cde-40a1-90d9-cbb0ca673c06')
;
INSERT INTO osc_physrisk_scenarios.hazard_indicator
	(std_id, std_name, std_name_display, std_description_full, std_description_short, std_tags, std_datetime_utc_created, std_creator_user_id, std_datetime_utc_last_modified, std_last_modifier_user_id, std_is_deleted, std_deleter_user_id, std_datetime_utc_deleted, std_culture, std_checksum, std_seq_num, std_translated_from_id, std_is_active, std_is_published, std_publisher_id, std_datetime_utc_published, hazard_id)
VALUES 
	('e0b5afc2-eed8-4760-9667-c14fdbf374db', 'Days with average temperature above 25°C/ACCESS-CM2', 'Days with average temperature above 25°C/ACCESS-CM2', 'Days with average temperature above 25°C/ACCESS-CM2', 'Days with average temperature above 25°C/ACCESS-CM2', '{ "key1":"value1", "key2":"value2"}','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'en', 'std_checksum',1, NULL,'y','y',1,'2024-07-15T00:00:01Z', 'd08db675-ee1e-48fe-b9e1-b0da27de8f2b')
;
INSERT INTO osc_physrisk_scenarios.hazard_indicator
	(std_id, std_name, std_name_display, std_description_full, std_description_short, std_tags, std_datetime_utc_created, std_creator_user_id, std_datetime_utc_last_modified, std_last_modifier_user_id, std_is_deleted, std_deleter_user_id, std_datetime_utc_deleted, std_culture, std_checksum, std_seq_num, std_translated_from_id, std_is_active, std_is_published, std_publisher_id, std_datetime_utc_published, hazard_id)
VALUES 
	('b795a8af-12cc-4773-83ee-a50badd1fe74', 'Days with average temperature above 25°C/CMCC-ESM2', 'Days with average temperature above 25°C/CMCC-ESM2', 'Days with average temperature above 25°C/CMCC-ESM2', 'Days with average temperature above 25°C/CMCC-ESM2', '{ "key1":"value1", "key2":"value2"}','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'en', 'std_checksum',1, NULL,'y','y',1,'2024-07-15T00:00:01Z', 'd08db675-ee1e-48fe-b9e1-b0da27de8f2b')
;
INSERT INTO osc_physrisk_scenarios.hazard_indicator
	(std_id, std_name, std_name_display, std_description_full, std_description_short, std_tags, std_datetime_utc_created, std_creator_user_id, std_datetime_utc_last_modified, std_last_modifier_user_id, std_is_deleted, std_deleter_user_id, std_datetime_utc_deleted, std_culture, std_checksum, std_seq_num, std_translated_from_id, std_is_active, std_is_published, std_publisher_id, std_datetime_utc_published, hazard_id)
VALUES 
	('81213608-0a01-42b0-a54f-a070fb104b95', 'Days with average temperature above 25°C/CNRM-CM6-1', 'Days with average temperature above 25°C/CNRM-CM6-1', 'Days with average temperature above 25°C/CNRM-CM6-1', 'Days with average temperature above 25°C/CNRM-CM6-1', '{ "key1":"value1", "key2":"value2"}','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'en', 'std_checksum',1, NULL,'y','y',1,'2024-07-15T00:00:01Z', 'd08db675-ee1e-48fe-b9e1-b0da27de8f2b')
;
INSERT INTO osc_physrisk_scenarios.hazard_indicator
	(std_id, std_name, std_name_display, std_description_full, std_description_short, std_tags, std_datetime_utc_created, std_creator_user_id, std_datetime_utc_last_modified, std_last_modifier_user_id, std_is_deleted, std_deleter_user_id, std_datetime_utc_deleted, std_culture, std_checksum, std_seq_num, std_translated_from_id, std_is_active, std_is_published, std_publisher_id, std_datetime_utc_published, hazard_id)
VALUES 
	('98692238-6a8f-4e58-a779-9f96eeaf1abd', 'Days with average temperature above 25°C/MIROC6', 'Days with average temperature above 25°C/MIROC6', 'Days with average temperature above 25°C/MIROC6', 'Days with average temperature above 25°C/MIROC6', '{ "key1":"value1", "key2":"value2"}','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'en', 'std_checksum',1, NULL,'y','y',1,'2024-07-15T00:00:01Z', 'd08db675-ee1e-48fe-b9e1-b0da27de8f2b')
;
INSERT INTO osc_physrisk_scenarios.hazard_indicator
	(std_id, std_name, std_name_display, std_description_full, std_description_short, std_tags, std_datetime_utc_created, std_creator_user_id, std_datetime_utc_last_modified, std_last_modifier_user_id, std_is_deleted, std_deleter_user_id, std_datetime_utc_deleted, std_culture, std_checksum, std_seq_num, std_translated_from_id, std_is_active, std_is_published, std_publisher_id, std_datetime_utc_published, hazard_id)
VALUES 
	('3dbf253a-d880-4440-baa5-3e4a9fcac355', 'Days with average temperature above 25°C/ESM1-2-LR', 'Days with average temperature above 25°C/ESM1-2-LR', 'Days with average temperature above 25°C/ESM1-2-LR', 'Days with average temperature above 25°C/ESM1-2-LR', '{ "key1":"value1", "key2":"value2"}','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'en', 'std_checksum',1, NULL,'y','y',1,'2024-07-15T00:00:01Z', 'd08db675-ee1e-48fe-b9e1-b0da27de8f2b')
;
INSERT INTO osc_physrisk_scenarios.hazard_indicator
	(std_id, std_name, std_name_display, std_description_full, std_description_short, std_tags, std_datetime_utc_created, std_creator_user_id, std_datetime_utc_last_modified, std_last_modifier_user_id, std_is_deleted, std_deleter_user_id, std_datetime_utc_deleted, std_culture, std_checksum, std_seq_num, std_translated_from_id, std_is_active, std_is_published, std_publisher_id, std_datetime_utc_published, hazard_id)
VALUES 
	('5fcca03b-ffff-4632-b896-78ceb9777e4b', 'Days with average temperature above 25°C/NorESM2-MM', 'Days with average temperature above 25°C/NorESM2-MM', 'Days with average temperature above 25°C/NorESM2-MM', 'Days with average temperature above 25°C/NorESM2-MM', '{ "key1":"value1", "key2":"value2"}','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'en', 'std_checksum',1, NULL,'y','y',1,'2024-07-15T00:00:01Z', 'd08db675-ee1e-48fe-b9e1-b0da27de8f2b')
;
INSERT INTO osc_physrisk_scenarios.hazard_indicator
	(std_id, std_name, std_name_display, std_description_full, std_description_short, std_tags, std_datetime_utc_created, std_creator_user_id, std_datetime_utc_last_modified, std_last_modifier_user_id, std_is_deleted, std_deleter_user_id, std_datetime_utc_deleted, std_culture, std_checksum, std_seq_num, std_translated_from_id, std_is_active, std_is_published, std_publisher_id, std_datetime_utc_published, hazard_id)
VALUES 
	('77f04d46-303f-40f2-a892-d0068d6ab64a', 'Days with average temperature above 30°C/ACCESS-CM2', 'Days with average temperature above 30°C/ACCESS-CM2', 'Days with average temperature above 30°C/ACCESS-CM2', 'Days with average temperature above 30°C/ACCESS-CM2', '{ "key1":"value1", "key2":"value2"}','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'en', 'std_checksum',1, NULL,'y','y',1,'2024-07-15T00:00:01Z', 'd08db675-ee1e-48fe-b9e1-b0da27de8f2b')
;
INSERT INTO osc_physrisk_scenarios.hazard_indicator
	(std_id, std_name, std_name_display, std_description_full, std_description_short, std_tags, std_datetime_utc_created, std_creator_user_id, std_datetime_utc_last_modified, std_last_modifier_user_id, std_is_deleted, std_deleter_user_id, std_datetime_utc_deleted, std_culture, std_checksum, std_seq_num, std_translated_from_id, std_is_active, std_is_published, std_publisher_id, std_datetime_utc_published, hazard_id)
VALUES 
	('c47e4dfa-e850-4060-aed9-af9100c65986', 'Days with average temperature above 30°C/CMCC-ESM2', 'Days with average temperature above 30°C/CMCC-ESM2', 'Days with average temperature above 30°C/CMCC-ESM2', 'Days with average temperature above 30°C/CMCC-ESM2', '{ "key1":"value1", "key2":"value2"}','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'en', 'std_checksum',1, NULL,'y','y',1,'2024-07-15T00:00:01Z', 'd08db675-ee1e-48fe-b9e1-b0da27de8f2b')
;
INSERT INTO osc_physrisk_scenarios.hazard_indicator
	(std_id, std_name, std_name_display, std_description_full, std_description_short, std_tags, std_datetime_utc_created, std_creator_user_id, std_datetime_utc_last_modified, std_last_modifier_user_id, std_is_deleted, std_deleter_user_id, std_datetime_utc_deleted, std_culture, std_checksum, std_seq_num, std_translated_from_id, std_is_active, std_is_published, std_publisher_id, std_datetime_utc_published, hazard_id)
VALUES 
	('ba1e06be-1cf5-4b5d-8f93-8f64e47af2b8', 'Days with average temperature above 30°C/CNRM-CM6-1', 'Days with average temperature above 30°C/CNRM-CM6-1', 'Days with average temperature above 30°C/CNRM-CM6-1', 'Days with average temperature above 30°C/CNRM-CM6-1', '{ "key1":"value1", "key2":"value2"}','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'en', 'std_checksum',1, NULL,'y','y',1,'2024-07-15T00:00:01Z', 'd08db675-ee1e-48fe-b9e1-b0da27de8f2b')
;
INSERT INTO osc_physrisk_scenarios.hazard_indicator
	(std_id, std_name, std_name_display, std_description_full, std_description_short, std_tags, std_datetime_utc_created, std_creator_user_id, std_datetime_utc_last_modified, std_last_modifier_user_id, std_is_deleted, std_deleter_user_id, std_datetime_utc_deleted, std_culture, std_checksum, std_seq_num, std_translated_from_id, std_is_active, std_is_published, std_publisher_id, std_datetime_utc_published, hazard_id)
VALUES 
	('b882a67c-acea-4dbe-9939-1594775e6f78', 'Days with average temperature above 30°C/MIROC6', 'Days with average temperature above 30°C/MIROC6', 'Days with average temperature above 30°C/MIROC6', 'Days with average temperature above 30°C/MIROC6', '{ "key1":"value1", "key2":"value2"}','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'en', 'std_checksum',1, NULL,'y','y',1,'2024-07-15T00:00:01Z', 'd08db675-ee1e-48fe-b9e1-b0da27de8f2b')
;
INSERT INTO osc_physrisk_scenarios.hazard_indicator
	(std_id, std_name, std_name_display, std_description_full, std_description_short, std_tags, std_datetime_utc_created, std_creator_user_id, std_datetime_utc_last_modified, std_last_modifier_user_id, std_is_deleted, std_deleter_user_id, std_datetime_utc_deleted, std_culture, std_checksum, std_seq_num, std_translated_from_id, std_is_active, std_is_published, std_publisher_id, std_datetime_utc_published, hazard_id)
VALUES 
	('0ae16260-45b7-48fe-924e-a2bd2bc25f39', 'Days with average temperature above 30°C/ESM1-2-LR', 'Days with average temperature above 30°C/ESM1-2-LR', 'Days with average temperature above 30°C/ESM1-2-LR', 'Days with average temperature above 30°C/ESM1-2-LR', '{ "key1":"value1", "key2":"value2"}','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'en', 'std_checksum',1, NULL,'y','y',1,'2024-07-15T00:00:01Z', 'd08db675-ee1e-48fe-b9e1-b0da27de8f2b')
;
INSERT INTO osc_physrisk_scenarios.hazard_indicator
	(std_id, std_name, std_name_display, std_description_full, std_description_short, std_tags, std_datetime_utc_created, std_creator_user_id, std_datetime_utc_last_modified, std_last_modifier_user_id, std_is_deleted, std_deleter_user_id, std_datetime_utc_deleted, std_culture, std_checksum, std_seq_num, std_translated_from_id, std_is_active, std_is_published, std_publisher_id, std_datetime_utc_published, hazard_id)
VALUES 
	('151fe933-f1be-4fb1-bcaf-d534a5023c78', 'Days with average temperature above 30°C/NorESM2-MM', 'Days with average temperature above 30°C/NorESM2-MM', 'Days with average temperature above 30°C/NorESM2-MM', 'Days with average temperature above 30°C/NorESM2-MM', '{ "key1":"value1", "key2":"value2"}','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'en', 'std_checksum',1, NULL,'y','y',1,'2024-07-15T00:00:01Z', 'd08db675-ee1e-48fe-b9e1-b0da27de8f2b')
;
INSERT INTO osc_physrisk_scenarios.hazard_indicator
	(std_id, std_name, std_name_display, std_description_full, std_description_short, std_tags, std_datetime_utc_created, std_creator_user_id, std_datetime_utc_last_modified, std_last_modifier_user_id, std_is_deleted, std_deleter_user_id, std_datetime_utc_deleted, std_culture, std_checksum, std_seq_num, std_translated_from_id, std_is_active, std_is_published, std_publisher_id, std_datetime_utc_published, hazard_id)
VALUES 
	('96e6fcc5-d843-4f59-9746-2d0d341b6bdc', 'Days with average temperature above 35°C/ACCESS-CM2', 'Days with average temperature above 35°C/ACCESS-CM2', 'Days with average temperature above 35°C/ACCESS-CM2', 'Days with average temperature above 35°C/ACCESS-CM2', '{ "key1":"value1", "key2":"value2"}','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'en', 'std_checksum',1, NULL,'y','y',1,'2024-07-15T00:00:01Z', 'd08db675-ee1e-48fe-b9e1-b0da27de8f2b')
;
INSERT INTO osc_physrisk_scenarios.hazard_indicator
	(std_id, std_name, std_name_display, std_description_full, std_description_short, std_tags, std_datetime_utc_created, std_creator_user_id, std_datetime_utc_last_modified, std_last_modifier_user_id, std_is_deleted, std_deleter_user_id, std_datetime_utc_deleted, std_culture, std_checksum, std_seq_num, std_translated_from_id, std_is_active, std_is_published, std_publisher_id, std_datetime_utc_published, hazard_id)
VALUES 
	('2c485594-5220-4e5e-85f0-3e67a09bacd9', 'Days with average temperature above 35°C/CMCC-ESM2', 'Days with average temperature above 35°C/CMCC-ESM2', 'Days with average temperature above 35°C/CMCC-ESM2', 'Days with average temperature above 35°C/CMCC-ESM2', '{ "key1":"value1", "key2":"value2"}','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'en', 'std_checksum',1, NULL,'y','y',1,'2024-07-15T00:00:01Z', 'd08db675-ee1e-48fe-b9e1-b0da27de8f2b')
;
INSERT INTO osc_physrisk_scenarios.hazard_indicator
	(std_id, std_name, std_name_display, std_description_full, std_description_short, std_tags, std_datetime_utc_created, std_creator_user_id, std_datetime_utc_last_modified, std_last_modifier_user_id, std_is_deleted, std_deleter_user_id, std_datetime_utc_deleted, std_culture, std_checksum, std_seq_num, std_translated_from_id, std_is_active, std_is_published, std_publisher_id, std_datetime_utc_published, hazard_id)
VALUES 
	('db9a09b3-3386-4081-bf0c-79b6c8ebd38e', 'Days with average temperature above 35°C/CNRM-CM6-1', 'Days with average temperature above 35°C/CNRM-CM6-1', 'Days with average temperature above 35°C/CNRM-CM6-1', 'Days with average temperature above 35°C/CNRM-CM6-1', '{ "key1":"value1", "key2":"value2"}','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'en', 'std_checksum',1, NULL,'y','y',1,'2024-07-15T00:00:01Z', 'd08db675-ee1e-48fe-b9e1-b0da27de8f2b')
;
INSERT INTO osc_physrisk_scenarios.hazard_indicator
	(std_id, std_name, std_name_display, std_description_full, std_description_short, std_tags, std_datetime_utc_created, std_creator_user_id, std_datetime_utc_last_modified, std_last_modifier_user_id, std_is_deleted, std_deleter_user_id, std_datetime_utc_deleted, std_culture, std_checksum, std_seq_num, std_translated_from_id, std_is_active, std_is_published, std_publisher_id, std_datetime_utc_published, hazard_id)
VALUES 
	('3f77c47d-9a26-4a3f-a289-ecf56678ec69', 'Days with average temperature above 35°C/MIROC6', 'Days with average temperature above 35°C/MIROC6', 'Days with average temperature above 35°C/MIROC6', 'Days with average temperature above 35°C/MIROC6', '{ "key1":"value1", "key2":"value2"}','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'en', 'std_checksum',1, NULL,'y','y',1,'2024-07-15T00:00:01Z', 'd08db675-ee1e-48fe-b9e1-b0da27de8f2b')
;
INSERT INTO osc_physrisk_scenarios.hazard_indicator
	(std_id, std_name, std_name_display, std_description_full, std_description_short, std_tags, std_datetime_utc_created, std_creator_user_id, std_datetime_utc_last_modified, std_last_modifier_user_id, std_is_deleted, std_deleter_user_id, std_datetime_utc_deleted, std_culture, std_checksum, std_seq_num, std_translated_from_id, std_is_active, std_is_published, std_publisher_id, std_datetime_utc_published, hazard_id)
VALUES 
	('f197975a-acea-4514-acbf-35cb070b0b5c', 'Days with average temperature above 35°C/ESM1-2-LR', 'Days with average temperature above 35°C/ESM1-2-LR', 'Days with average temperature above 35°C/ESM1-2-LR', 'Days with average temperature above 35°C/ESM1-2-LR', '{ "key1":"value1", "key2":"value2"}','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'en', 'std_checksum',1, NULL,'y','y',1,'2024-07-15T00:00:01Z', 'd08db675-ee1e-48fe-b9e1-b0da27de8f2b')
;
INSERT INTO osc_physrisk_scenarios.hazard_indicator
	(std_id, std_name, std_name_display, std_description_full, std_description_short, std_tags, std_datetime_utc_created, std_creator_user_id, std_datetime_utc_last_modified, std_last_modifier_user_id, std_is_deleted, std_deleter_user_id, std_datetime_utc_deleted, std_culture, std_checksum, std_seq_num, std_translated_from_id, std_is_active, std_is_published, std_publisher_id, std_datetime_utc_published, hazard_id)
VALUES 
	('d4d610b4-060e-4212-9b0c-05fe551a0128', 'Days with average temperature above 35°C/NorESM2-MM', 'Days with average temperature above 35°C/NorESM2-MM', 'Days with average temperature above 35°C/NorESM2-MM', 'Days with average temperature above 35°C/NorESM2-MM', '{ "key1":"value1", "key2":"value2"}','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'en', 'std_checksum',1, NULL,'y','y',1,'2024-07-15T00:00:01Z', 'd08db675-ee1e-48fe-b9e1-b0da27de8f2b')
;
INSERT INTO osc_physrisk_scenarios.hazard_indicator
	(std_id, std_name, std_name_display, std_description_full, std_description_short, std_tags, std_datetime_utc_created, std_creator_user_id, std_datetime_utc_last_modified, std_last_modifier_user_id, std_is_deleted, std_deleter_user_id, std_datetime_utc_deleted, std_culture, std_checksum, std_seq_num, std_translated_from_id, std_is_active, std_is_published, std_publisher_id, std_datetime_utc_published, hazard_id)
VALUES 
	('f38a4529-0b9e-4a31-9b16-f6e070a4f001', 'Days with average temperature above 40°C/ACCESS-CM2', 'Days with average temperature above 40°C/ACCESS-CM2', 'Days with average temperature above 40°C/ACCESS-CM2', 'Days with average temperature above 40°C/ACCESS-CM2', '{ "key1":"value1", "key2":"value2"}','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'en', 'std_checksum',1, NULL,'y','y',1,'2024-07-15T00:00:01Z', 'd08db675-ee1e-48fe-b9e1-b0da27de8f2b')
;
INSERT INTO osc_physrisk_scenarios.hazard_indicator
	(std_id, std_name, std_name_display, std_description_full, std_description_short, std_tags, std_datetime_utc_created, std_creator_user_id, std_datetime_utc_last_modified, std_last_modifier_user_id, std_is_deleted, std_deleter_user_id, std_datetime_utc_deleted, std_culture, std_checksum, std_seq_num, std_translated_from_id, std_is_active, std_is_published, std_publisher_id, std_datetime_utc_published, hazard_id)
VALUES 
	('bae5ce0d-079c-44c8-87f2-705e13806371', 'Days with average temperature above 40°C/CMCC-ESM2', 'Days with average temperature above 40°C/CMCC-ESM2', 'Days with average temperature above 40°C/CMCC-ESM2', 'Days with average temperature above 40°C/CMCC-ESM2', '{ "key1":"value1", "key2":"value2"}','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'en', 'std_checksum',1, NULL,'y','y',1,'2024-07-15T00:00:01Z', 'd08db675-ee1e-48fe-b9e1-b0da27de8f2b')
;
INSERT INTO osc_physrisk_scenarios.hazard_indicator
	(std_id, std_name, std_name_display, std_description_full, std_description_short, std_tags, std_datetime_utc_created, std_creator_user_id, std_datetime_utc_last_modified, std_last_modifier_user_id, std_is_deleted, std_deleter_user_id, std_datetime_utc_deleted, std_culture, std_checksum, std_seq_num, std_translated_from_id, std_is_active, std_is_published, std_publisher_id, std_datetime_utc_published, hazard_id)
VALUES 
	('19049eb2-9270-4b1b-9aea-8e2c610ea6b0', 'Days with average temperature above 40°C/CNRM-CM6-1', 'Days with average temperature above 40°C/CNRM-CM6-1', 'Days with average temperature above 40°C/CNRM-CM6-1', 'Days with average temperature above 40°C/CNRM-CM6-1', '{ "key1":"value1", "key2":"value2"}','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'en', 'std_checksum',1, NULL,'y','y',1,'2024-07-15T00:00:01Z', 'd08db675-ee1e-48fe-b9e1-b0da27de8f2b')
;
INSERT INTO osc_physrisk_scenarios.hazard_indicator
	(std_id, std_name, std_name_display, std_description_full, std_description_short, std_tags, std_datetime_utc_created, std_creator_user_id, std_datetime_utc_last_modified, std_last_modifier_user_id, std_is_deleted, std_deleter_user_id, std_datetime_utc_deleted, std_culture, std_checksum, std_seq_num, std_translated_from_id, std_is_active, std_is_published, std_publisher_id, std_datetime_utc_published, hazard_id)
VALUES 
	('a35f8652-5736-4b83-b9ec-2bcd53dd2b75', 'Days with average temperature above 40°C/MIROC6', 'Days with average temperature above 40°C/MIROC6', 'Days with average temperature above 40°C/MIROC6', 'Days with average temperature above 40°C/MIROC6', '{ "key1":"value1", "key2":"value2"}','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'en', 'std_checksum',1, NULL,'y','y',1,'2024-07-15T00:00:01Z', 'd08db675-ee1e-48fe-b9e1-b0da27de8f2b')
;
INSERT INTO osc_physrisk_scenarios.hazard_indicator
	(std_id, std_name, std_name_display, std_description_full, std_description_short, std_tags, std_datetime_utc_created, std_creator_user_id, std_datetime_utc_last_modified, std_last_modifier_user_id, std_is_deleted, std_deleter_user_id, std_datetime_utc_deleted, std_culture, std_checksum, std_seq_num, std_translated_from_id, std_is_active, std_is_published, std_publisher_id, std_datetime_utc_published, hazard_id)
VALUES 
	('6a23417d-27fc-49f5-9147-43f9a761e13d', 'Days with average temperature above 40°C/ESM1-2-LR', 'Days with average temperature above 40°C/ESM1-2-LR', 'Days with average temperature above 40°C/ESM1-2-LR', 'Days with average temperature above 40°C/ESM1-2-LR', '{ "key1":"value1", "key2":"value2"}','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'en', 'std_checksum',1, NULL,'y','y',1,'2024-07-15T00:00:01Z', 'd08db675-ee1e-48fe-b9e1-b0da27de8f2b')
;
INSERT INTO osc_physrisk_scenarios.hazard_indicator
	(std_id, std_name, std_name_display, std_description_full, std_description_short, std_tags, std_datetime_utc_created, std_creator_user_id, std_datetime_utc_last_modified, std_last_modifier_user_id, std_is_deleted, std_deleter_user_id, std_datetime_utc_deleted, std_culture, std_checksum, std_seq_num, std_translated_from_id, std_is_active, std_is_published, std_publisher_id, std_datetime_utc_published, hazard_id)
VALUES 
	('9fd1aafe-d942-4dd7-8b5f-cc3983d12616', 'Days with average temperature above 40°C/NorESM2-MM', 'Days with average temperature above 40°C/NorESM2-MM', 'Days with average temperature above 40°C/NorESM2-MM', 'Days with average temperature above 40°C/NorESM2-MM', '{ "key1":"value1", "key2":"value2"}','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'en', 'std_checksum',1, NULL,'y','y',1,'2024-07-15T00:00:01Z', 'd08db675-ee1e-48fe-b9e1-b0da27de8f2b')
;
INSERT INTO osc_physrisk_scenarios.hazard_indicator
	(std_id, std_name, std_name_display, std_description_full, std_description_short, std_tags, std_datetime_utc_created, std_creator_user_id, std_datetime_utc_last_modified, std_last_modifier_user_id, std_is_deleted, std_deleter_user_id, std_datetime_utc_deleted, std_culture, std_checksum, std_seq_num, std_translated_from_id, std_is_active, std_is_published, std_publisher_id, std_datetime_utc_published, hazard_id)
VALUES 
	('801009ff-7135-4252-a956-8f32cd9fb17d', 'Days with average temperature above 45°C/ACCESS-CM2', 'Days with average temperature above 45°C/ACCESS-CM2', 'Days with average temperature above 45°C/ACCESS-CM2', 'Days with average temperature above 45°C/ACCESS-CM2', '{ "key1":"value1", "key2":"value2"}','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'en', 'std_checksum',1, NULL,'y','y',1,'2024-07-15T00:00:01Z', 'd08db675-ee1e-48fe-b9e1-b0da27de8f2b')
;
INSERT INTO osc_physrisk_scenarios.hazard_indicator
	(std_id, std_name, std_name_display, std_description_full, std_description_short, std_tags, std_datetime_utc_created, std_creator_user_id, std_datetime_utc_last_modified, std_last_modifier_user_id, std_is_deleted, std_deleter_user_id, std_datetime_utc_deleted, std_culture, std_checksum, std_seq_num, std_translated_from_id, std_is_active, std_is_published, std_publisher_id, std_datetime_utc_published, hazard_id)
VALUES 
	('ea8be4c4-a3f0-441f-b1cd-b4de8b9e885c', 'Days with average temperature above 45°C/CMCC-ESM2', 'Days with average temperature above 45°C/CMCC-ESM2', 'Days with average temperature above 45°C/CMCC-ESM2', 'Days with average temperature above 45°C/CMCC-ESM2', '{ "key1":"value1", "key2":"value2"}','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'en', 'std_checksum',1, NULL,'y','y',1,'2024-07-15T00:00:01Z', 'd08db675-ee1e-48fe-b9e1-b0da27de8f2b')
;
INSERT INTO osc_physrisk_scenarios.hazard_indicator
	(std_id, std_name, std_name_display, std_description_full, std_description_short, std_tags, std_datetime_utc_created, std_creator_user_id, std_datetime_utc_last_modified, std_last_modifier_user_id, std_is_deleted, std_deleter_user_id, std_datetime_utc_deleted, std_culture, std_checksum, std_seq_num, std_translated_from_id, std_is_active, std_is_published, std_publisher_id, std_datetime_utc_published, hazard_id)
VALUES 
	('69053bee-35fd-45bd-9dd1-8fe485ae7715', 'Days with average temperature above 45°C/CNRM-CM6-1', 'Days with average temperature above 45°C/CNRM-CM6-1', 'Days with average temperature above 45°C/CNRM-CM6-1', 'Days with average temperature above 45°C/CNRM-CM6-1', '{ "key1":"value1", "key2":"value2"}','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'en', 'std_checksum',1, NULL,'y','y',1,'2024-07-15T00:00:01Z', 'd08db675-ee1e-48fe-b9e1-b0da27de8f2b')
;
INSERT INTO osc_physrisk_scenarios.hazard_indicator
	(std_id, std_name, std_name_display, std_description_full, std_description_short, std_tags, std_datetime_utc_created, std_creator_user_id, std_datetime_utc_last_modified, std_last_modifier_user_id, std_is_deleted, std_deleter_user_id, std_datetime_utc_deleted, std_culture, std_checksum, std_seq_num, std_translated_from_id, std_is_active, std_is_published, std_publisher_id, std_datetime_utc_published, hazard_id)
VALUES 
	('1f48f1f2-03ab-43b8-9185-038fd656ebcd', 'Days with average temperature above 45°C/MIROC6', 'Days with average temperature above 45°C/MIROC6', 'Days with average temperature above 45°C/MIROC6', 'Days with average temperature above 45°C/MIROC6', '{ "key1":"value1", "key2":"value2"}','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'en', 'std_checksum',1, NULL,'y','y',1,'2024-07-15T00:00:01Z', 'd08db675-ee1e-48fe-b9e1-b0da27de8f2b')
;
INSERT INTO osc_physrisk_scenarios.hazard_indicator
	(std_id, std_name, std_name_display, std_description_full, std_description_short, std_tags, std_datetime_utc_created, std_creator_user_id, std_datetime_utc_last_modified, std_last_modifier_user_id, std_is_deleted, std_deleter_user_id, std_datetime_utc_deleted, std_culture, std_checksum, std_seq_num, std_translated_from_id, std_is_active, std_is_published, std_publisher_id, std_datetime_utc_published, hazard_id)
VALUES 
	('8960452e-86b1-4134-b03d-5bea69079fcc', 'Days with average temperature above 45°C/ESM1-2-LR', 'Days with average temperature above 45°C/ESM1-2-LR', 'Days with average temperature above 45°C/ESM1-2-LR', 'Days with average temperature above 45°C/ESM1-2-LR', '{ "key1":"value1", "key2":"value2"}','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'en', 'std_checksum',1, NULL,'y','y',1,'2024-07-15T00:00:01Z', 'd08db675-ee1e-48fe-b9e1-b0da27de8f2b')
;
INSERT INTO osc_physrisk_scenarios.hazard_indicator
	(std_id, std_name, std_name_display, std_description_full, std_description_short, std_tags, std_datetime_utc_created, std_creator_user_id, std_datetime_utc_last_modified, std_last_modifier_user_id, std_is_deleted, std_deleter_user_id, std_datetime_utc_deleted, std_culture, std_checksum, std_seq_num, std_translated_from_id, std_is_active, std_is_published, std_publisher_id, std_datetime_utc_published, hazard_id)
VALUES 
	('3676521f-16ee-4ce6-b8b4-d00aaba44281', 'Days with average temperature above 45°C/NorESM2-MM', 'Days with average temperature above 45°C/NorESM2-MM', 'Days with average temperature above 45°C/NorESM2-MM', 'Days with average temperature above 45°C/NorESM2-MM', '{ "key1":"value1", "key2":"value2"}','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'en', 'std_checksum',1, NULL,'y','y',1,'2024-07-15T00:00:01Z', 'd08db675-ee1e-48fe-b9e1-b0da27de8f2b')
;
INSERT INTO osc_physrisk_scenarios.hazard_indicator
	(std_id, std_name, std_name_display, std_description_full, std_description_short, std_tags, std_datetime_utc_created, std_creator_user_id, std_datetime_utc_last_modified, std_last_modifier_user_id, std_is_deleted, std_deleter_user_id, std_datetime_utc_deleted, std_culture, std_checksum, std_seq_num, std_translated_from_id, std_is_active, std_is_published, std_publisher_id, std_datetime_utc_published, hazard_id)
VALUES 
	('8bfe29fb-85e3-4497-b340-ad3f4eadfc3f', 'Days with average temperature above 50°C/ACCESS-CM2', 'Days with average temperature above 50°C/ACCESS-CM2', 'Days with average temperature above 50°C/ACCESS-CM2', 'Days with average temperature above 50°C/ACCESS-CM2', '{ "key1":"value1", "key2":"value2"}','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'en', 'std_checksum',1, NULL,'y','y',1,'2024-07-15T00:00:01Z', 'd08db675-ee1e-48fe-b9e1-b0da27de8f2b')
;
INSERT INTO osc_physrisk_scenarios.hazard_indicator
	(std_id, std_name, std_name_display, std_description_full, std_description_short, std_tags, std_datetime_utc_created, std_creator_user_id, std_datetime_utc_last_modified, std_last_modifier_user_id, std_is_deleted, std_deleter_user_id, std_datetime_utc_deleted, std_culture, std_checksum, std_seq_num, std_translated_from_id, std_is_active, std_is_published, std_publisher_id, std_datetime_utc_published, hazard_id)
VALUES 
	('fb684a2f-ce48-4d02-ba49-9c5cd49654df', 'Days with average temperature above 50°C/CMCC-ESM2', 'Days with average temperature above 50°C/CMCC-ESM2', 'Days with average temperature above 50°C/CMCC-ESM2', 'Days with average temperature above 50°C/CMCC-ESM2', '{ "key1":"value1", "key2":"value2"}','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'en', 'std_checksum',1, NULL,'y','y',1,'2024-07-15T00:00:01Z', 'd08db675-ee1e-48fe-b9e1-b0da27de8f2b')
;
INSERT INTO osc_physrisk_scenarios.hazard_indicator
	(std_id, std_name, std_name_display, std_description_full, std_description_short, std_tags, std_datetime_utc_created, std_creator_user_id, std_datetime_utc_last_modified, std_last_modifier_user_id, std_is_deleted, std_deleter_user_id, std_datetime_utc_deleted, std_culture, std_checksum, std_seq_num, std_translated_from_id, std_is_active, std_is_published, std_publisher_id, std_datetime_utc_published, hazard_id)
VALUES 
	('56fb7c3a-7d9c-41d2-ab1d-37bab5544748', 'Days with average temperature above 50°C/CNRM-CM6-1', 'Days with average temperature above 50°C/CNRM-CM6-1', 'Days with average temperature above 50°C/CNRM-CM6-1', 'Days with average temperature above 50°C/CNRM-CM6-1', '{ "key1":"value1", "key2":"value2"}','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'en', 'std_checksum',1, NULL,'y','y',1,'2024-07-15T00:00:01Z', 'd08db675-ee1e-48fe-b9e1-b0da27de8f2b')
;
INSERT INTO osc_physrisk_scenarios.hazard_indicator
	(std_id, std_name, std_name_display, std_description_full, std_description_short, std_tags, std_datetime_utc_created, std_creator_user_id, std_datetime_utc_last_modified, std_last_modifier_user_id, std_is_deleted, std_deleter_user_id, std_datetime_utc_deleted, std_culture, std_checksum, std_seq_num, std_translated_from_id, std_is_active, std_is_published, std_publisher_id, std_datetime_utc_published, hazard_id)
VALUES 
	('12a84609-f114-4975-a90a-aed809452897', 'Days with average temperature above 50°C/MIROC6', 'Days with average temperature above 50°C/MIROC6', 'Days with average temperature above 50°C/MIROC6', 'Days with average temperature above 50°C/MIROC6', '{ "key1":"value1", "key2":"value2"}','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'en', 'std_checksum',1, NULL,'y','y',1,'2024-07-15T00:00:01Z', 'd08db675-ee1e-48fe-b9e1-b0da27de8f2b')
;
INSERT INTO osc_physrisk_scenarios.hazard_indicator
	(std_id, std_name, std_name_display, std_description_full, std_description_short, std_tags, std_datetime_utc_created, std_creator_user_id, std_datetime_utc_last_modified, std_last_modifier_user_id, std_is_deleted, std_deleter_user_id, std_datetime_utc_deleted, std_culture, std_checksum, std_seq_num, std_translated_from_id, std_is_active, std_is_published, std_publisher_id, std_datetime_utc_published, hazard_id)
VALUES 
	('22ce6754-f68b-4f96-b083-8bb2a5c4deb6', 'Days with average temperature above 50°C/ESM1-2-LR', 'Days with average temperature above 50°C/ESM1-2-LR', 'Days with average temperature above 50°C/ESM1-2-LR', 'Days with average temperature above 50°C/ESM1-2-LR', '{ "key1":"value1", "key2":"value2"}','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'en', 'std_checksum',1, NULL,'y','y',1,'2024-07-15T00:00:01Z', 'd08db675-ee1e-48fe-b9e1-b0da27de8f2b')
;
INSERT INTO osc_physrisk_scenarios.hazard_indicator
	(std_id, std_name, std_name_display, std_description_full, std_description_short, std_tags, std_datetime_utc_created, std_creator_user_id, std_datetime_utc_last_modified, std_last_modifier_user_id, std_is_deleted, std_deleter_user_id, std_datetime_utc_deleted, std_culture, std_checksum, std_seq_num, std_translated_from_id, std_is_active, std_is_published, std_publisher_id, std_datetime_utc_published, hazard_id)
VALUES 
	('ec4c8b74-816a-4260-8321-fc03b6850c37', 'Days with average temperature above 50°C/NorESM2-MM', 'Days with average temperature above 50°C/NorESM2-MM', 'Days with average temperature above 50°C/NorESM2-MM', 'Days with average temperature above 50°C/NorESM2-MM', '{ "key1":"value1", "key2":"value2"}','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'en', 'std_checksum',1, NULL,'y','y',1,'2024-07-15T00:00:01Z', 'd08db675-ee1e-48fe-b9e1-b0da27de8f2b')
;
INSERT INTO osc_physrisk_scenarios.hazard_indicator
	(std_id, std_name, std_name_display, std_description_full, std_description_short, std_tags, std_datetime_utc_created, std_creator_user_id, std_datetime_utc_last_modified, std_last_modifier_user_id, std_is_deleted, std_deleter_user_id, std_datetime_utc_deleted, std_culture, std_checksum, std_seq_num, std_translated_from_id, std_is_active, std_is_published, std_publisher_id, std_datetime_utc_published, hazard_id)
VALUES 
	('7f06ac9f-f6ac-467a-9a88-d14a91465141', 'Days with average temperature above 55°C/ACCESS-CM2', 'Days with average temperature above 55°C/ACCESS-CM2', 'Days with average temperature above 55°C/ACCESS-CM2', 'Days with average temperature above 55°C/ACCESS-CM2', '{ "key1":"value1", "key2":"value2"}','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'en', 'std_checksum',1, NULL,'y','y',1,'2024-07-15T00:00:01Z', 'd08db675-ee1e-48fe-b9e1-b0da27de8f2b')
;
INSERT INTO osc_physrisk_scenarios.hazard_indicator
	(std_id, std_name, std_name_display, std_description_full, std_description_short, std_tags, std_datetime_utc_created, std_creator_user_id, std_datetime_utc_last_modified, std_last_modifier_user_id, std_is_deleted, std_deleter_user_id, std_datetime_utc_deleted, std_culture, std_checksum, std_seq_num, std_translated_from_id, std_is_active, std_is_published, std_publisher_id, std_datetime_utc_published, hazard_id)
VALUES 
	('c9edfa0d-5450-4de5-8680-4a26874cac2d', 'Days with average temperature above 55°C/CMCC-ESM2', 'Days with average temperature above 55°C/CMCC-ESM2', 'Days with average temperature above 55°C/CMCC-ESM2', 'Days with average temperature above 55°C/CMCC-ESM2', '{ "key1":"value1", "key2":"value2"}','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'en', 'std_checksum',1, NULL,'y','y',1,'2024-07-15T00:00:01Z', 'd08db675-ee1e-48fe-b9e1-b0da27de8f2b')
;
INSERT INTO osc_physrisk_scenarios.hazard_indicator
	(std_id, std_name, std_name_display, std_description_full, std_description_short, std_tags, std_datetime_utc_created, std_creator_user_id, std_datetime_utc_last_modified, std_last_modifier_user_id, std_is_deleted, std_deleter_user_id, std_datetime_utc_deleted, std_culture, std_checksum, std_seq_num, std_translated_from_id, std_is_active, std_is_published, std_publisher_id, std_datetime_utc_published, hazard_id)
VALUES 
	('431a89ea-17bd-4dee-a2af-9ba18e737fe5', 'Days with average temperature above 55°C/CNRM-CM6-1', 'Days with average temperature above 55°C/CNRM-CM6-1', 'Days with average temperature above 55°C/CNRM-CM6-1', 'Days with average temperature above 55°C/CNRM-CM6-1', '{ "key1":"value1", "key2":"value2"}','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'en', 'std_checksum',1, NULL,'y','y',1,'2024-07-15T00:00:01Z', 'd08db675-ee1e-48fe-b9e1-b0da27de8f2b')
;
INSERT INTO osc_physrisk_scenarios.hazard_indicator
	(std_id, std_name, std_name_display, std_description_full, std_description_short, std_tags, std_datetime_utc_created, std_creator_user_id, std_datetime_utc_last_modified, std_last_modifier_user_id, std_is_deleted, std_deleter_user_id, std_datetime_utc_deleted, std_culture, std_checksum, std_seq_num, std_translated_from_id, std_is_active, std_is_published, std_publisher_id, std_datetime_utc_published, hazard_id)
VALUES 
	('158038b5-1f09-471a-ac5b-85aae409148b', 'Days with average temperature above 55°C/MIROC6', 'Days with average temperature above 55°C/MIROC6', 'Days with average temperature above 55°C/MIROC6', 'Days with average temperature above 55°C/MIROC6', '{ "key1":"value1", "key2":"value2"}','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'en', 'std_checksum',1, NULL,'y','y',1,'2024-07-15T00:00:01Z', 'd08db675-ee1e-48fe-b9e1-b0da27de8f2b')
;
INSERT INTO osc_physrisk_scenarios.hazard_indicator
	(std_id, std_name, std_name_display, std_description_full, std_description_short, std_tags, std_datetime_utc_created, std_creator_user_id, std_datetime_utc_last_modified, std_last_modifier_user_id, std_is_deleted, std_deleter_user_id, std_datetime_utc_deleted, std_culture, std_checksum, std_seq_num, std_translated_from_id, std_is_active, std_is_published, std_publisher_id, std_datetime_utc_published, hazard_id)
VALUES 
	('a5810ce7-eec7-4881-a182-33e0e3156a26', 'Days with average temperature above 55°C/ESM1-2-LR', 'Days with average temperature above 55°C/ESM1-2-LR', 'Days with average temperature above 55°C/ESM1-2-LR', 'Days with average temperature above 55°C/ESM1-2-LR', '{ "key1":"value1", "key2":"value2"}','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'en', 'std_checksum',1, NULL,'y','y',1,'2024-07-15T00:00:01Z', 'd08db675-ee1e-48fe-b9e1-b0da27de8f2b')
;
INSERT INTO osc_physrisk_scenarios.hazard_indicator
	(std_id, std_name, std_name_display, std_description_full, std_description_short, std_tags, std_datetime_utc_created, std_creator_user_id, std_datetime_utc_last_modified, std_last_modifier_user_id, std_is_deleted, std_deleter_user_id, std_datetime_utc_deleted, std_culture, std_checksum, std_seq_num, std_translated_from_id, std_is_active, std_is_published, std_publisher_id, std_datetime_utc_published, hazard_id)
VALUES 
	('41705043-bdad-4d2d-ab2b-3d884375b52d', 'Days with average temperature above 55°C/NorESM2-MM', 'Days with average temperature above 55°C/NorESM2-MM', 'Days with average temperature above 55°C/NorESM2-MM', 'Days with average temperature above 55°C/NorESM2-MM', '{ "key1":"value1", "key2":"value2"}','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'en', 'std_checksum',1, NULL,'y','y',1,'2024-07-15T00:00:01Z', 'd08db675-ee1e-48fe-b9e1-b0da27de8f2b')
;

-- DATA IN ENGLISH ENDS


-- INSERT ASSET PORTFOLIO EXAMPLE
-- INCLUDING EXAMPLE ASSET WITH OED AND NAICS std_tags
INSERT INTO osc_physrisk_assets.asset_class
	(std_id, std_abbreviation, std_name, std_slug, std_name_display, std_description_full, std_description_short, std_tags, std_datetime_utc_created, std_creator_user_id, std_datetime_utc_last_modified, std_last_modifier_user_id, std_is_deleted, std_deleter_user_id, std_datetime_utc_deleted, std_culture, std_checksum, std_seq_num, std_translated_from_id, std_is_active, std_is_published, std_publisher_id, std_datetime_utc_published)
VALUES 
	('db4a14a2-a27b-4bb0-8249-a07fb78438f4', 'Residential','Residential Buildings','en-asset-class-residential', 'Residential Buildings', 'Homes, apartments, and other residential structures.', 'Homes, apartments, and other residential structures.', '{"naics":[53],"oed:occupancy:oed_code":1050,"oed:occupancy:air_code":301}','2024-07-25T00:00:01Z',1,'2024-07-25T00:00:01Z',1,'n',NULL,NULL, 'en', 'std_checksum',1,NULL, 'y','y',1,'2024-07-25T00:00:01Z');
INSERT INTO osc_physrisk_assets.asset_class
	(std_id, std_abbreviation, std_name, std_slug, std_name_display, std_description_full, std_description_short, std_tags, std_datetime_utc_created, std_creator_user_id, std_datetime_utc_last_modified, std_last_modifier_user_id, std_is_deleted, std_deleter_user_id, std_datetime_utc_deleted, std_culture, std_checksum, std_seq_num, std_translated_from_id, std_is_active, std_is_published, std_publisher_id, std_datetime_utc_published)
VALUES 
	('536e8cee-682f-4cd6-b23e-b32e885cc094', 'Commercial', 'Commercial Buildings','en-asset-class-commercial', 'Commercial Buildings', 'Offices, retail spaces, and other commercial properties.', 'Offices, retail spaces, and other commercial properties.', '{"naics":[44,45,49],"oed:occupancy:oed_code":1100,"oed:occupancy:air_code":311}','2024-07-25T00:00:01Z',1,'2024-07-25T00:00:01Z',1,'n',NULL,NULL, 'en', 'std_checksum',1,NULL, 'y','y',1,'2024-07-25T00:00:01Z');
INSERT INTO osc_physrisk_assets.asset_class
	(std_id, std_abbreviation, std_name, std_slug, std_name_display, std_description_full, std_description_short, std_tags, std_datetime_utc_created, std_creator_user_id, std_datetime_utc_last_modified, std_last_modifier_user_id, std_is_deleted, std_deleter_user_id, std_datetime_utc_deleted, std_culture, std_checksum, std_seq_num, std_translated_from_id, std_is_active, std_is_published, std_publisher_id, std_datetime_utc_published)
VALUES 
	('f2baa602-44fe-49be-a5c9-d8b8208d9499', 'Infra','Infrastructure','en-asset-class-infrastructure', 'Infrastructure', 'Roads, bridges, railways, airports, ports, and utilities (water, electricity, telecommunications).', 'Roads, bridges, railways, airports, ports, and utilities (water, electricity, telecommunications).', '{"oed:occupancy:oed_code":1256,"oed:occupancy:oed_code":1305}','2024-07-25T00:00:01Z',1,'2024-07-25T00:00:01Z',1,'n',NULL,NULL, 'en', 'std_checksum',1,NULL, 'y','y',1,'2024-07-25T00:00:01Z');
INSERT INTO osc_physrisk_assets.asset_class
	(std_id, std_abbreviation, std_name, std_slug, std_name_display, std_description_full, std_description_short, std_tags, std_datetime_utc_created, std_creator_user_id, std_datetime_utc_last_modified, std_last_modifier_user_id, std_is_deleted, std_deleter_user_id, std_datetime_utc_deleted, std_culture, std_checksum, std_seq_num, std_translated_from_id, std_is_active, std_is_published, std_publisher_id, std_datetime_utc_published)
VALUES 
	('a9da716f-6667-4efe-bac7-f91c1cdcc2f1', 'Agri','Agricultural Assets','en-asset-class-agricultural', 'Agricultural Assets', 'Cropland, livestock, agricultural facilities, and equipment.', 'Cropland, livestock, agricultural facilities, and equipment.', '{"oed:occupancy:oed_code":2700,"oed:occupancy:air_code":484}','2024-07-25T00:00:01Z',1,'2024-07-25T00:00:01Z',1,'n',NULL,NULL, 'en', 'std_checksum',1,NULL, 'y','y',1,'2024-07-25T00:00:01Z');
INSERT INTO osc_physrisk_assets.asset_class
	(std_id, std_abbreviation, std_name, std_slug, std_name_display, std_description_full, std_description_short, std_tags, std_datetime_utc_created, std_creator_user_id, std_datetime_utc_last_modified, std_last_modifier_user_id, std_is_deleted, std_deleter_user_id, std_datetime_utc_deleted, std_culture, std_checksum, std_seq_num, std_translated_from_id, std_is_active, std_is_published, std_publisher_id, std_datetime_utc_published)
VALUES 
	('1ad910c8-fba0-4f45-845e-5a1901b9ffbe', 'Industrial','Industrial Facilities', 'en-asset-class-industrial','Industrial Facilities', 'Factories, warehouses, and other industrial properties.', 'Factories, warehouses, and other industrial properties.', '{"oed:occupancy:oed_code":1150,"oed:occupancy:air_code":321}','2024-07-25T00:00:01Z',1,'2024-07-25T00:00:01Z',1,'n',NULL,NULL, 'en', 'std_checksum',1,NULL, 'y','y',1,'2024-07-25T00:00:01Z');
INSERT INTO osc_physrisk_assets.asset_class
	(std_id, std_abbreviation, std_name, std_slug, std_name_display, std_description_full, std_description_short, std_tags, std_datetime_utc_created, std_creator_user_id, std_datetime_utc_last_modified, std_last_modifier_user_id, std_is_deleted, std_deleter_user_id, std_datetime_utc_deleted, std_culture, std_checksum, std_seq_num, std_translated_from_id, std_is_active, std_is_published, std_publisher_id, std_datetime_utc_published)
VALUES 
	('2b5557e6-05ee-49d6-b6a6-b7ef54948af7', 'Natural','Natural Assets', 'en-asset-class-natural','Natural Assets', 'Forests, wetlands, rivers, and other natural environments.', 'Forests, wetlands, rivers, and other natural environments.', '{"oed:occupancy:oed_code":1000,"oed:occupancy:air_code":300}','2024-07-25T00:00:01Z',1,'2024-07-25T00:00:01Z',1,'n',NULL,NULL, 'en', 'std_checksum',1,NULL, 'y','y',1,'2024-07-25T00:00:01Z');
INSERT INTO osc_physrisk_assets.asset_class
	(std_id, std_abbreviation, std_name, std_slug, std_name_display, std_description_full, std_description_short, std_tags, std_datetime_utc_created, std_creator_user_id, std_datetime_utc_last_modified, std_last_modifier_user_id, std_is_deleted, std_deleter_user_id, std_datetime_utc_deleted, std_culture, std_checksum, std_seq_num, std_translated_from_id, std_is_active, std_is_published, std_publisher_id, std_datetime_utc_published)
VALUES 
	('beafc1fa-f6c8-4c72-9717-a243eea1a2ef', 'Cultural','Cultural Heritage Sites', 'en-asset-class-cultural','Cultural Heritage Sites', 'Historical buildings, monuments, and sites of cultural significance.', 'Historical buildings, monuments, and sites of cultural significance.', '{"oed:occupancy:oed_code":1000,"oed:occupancy:air_code":300}','2024-07-25T00:00:01Z',1,'2024-07-25T00:00:01Z',1,'n',NULL,NULL, 'en', 'std_checksum',1,NULL, 'y','y',1,'2024-07-25T00:00:01Z');


INSERT INTO osc_physrisk_assets.asset_type
	(std_id, std_name, std_name_display, std_description_full, std_description_short, std_tags, std_datetime_utc_created, std_creator_user_id, std_datetime_utc_last_modified, std_last_modifier_user_id, std_is_deleted, std_deleter_user_id, std_datetime_utc_deleted, std_culture, std_checksum, std_seq_num, std_translated_from_id, std_is_active, std_is_published, std_publisher_id, std_datetime_utc_published,asset_class_id)
VALUES 
	('fa3d647a-4ab8-494a-b68e-6abf48404462', 'Single-family Homes', 'Single-family Homes', 'Single-family Homes', 'Single-family Homes', '{}','2024-07-25T00:00:01Z',1,'2024-07-25T00:00:01Z',1,'n',NULL,NULL, 'en', 'std_checksum',1,NULL, 'y','y',1,'2024-07-25T00:00:01Z','db4a14a2-a27b-4bb0-8249-a07fb78438f4');
INSERT INTO osc_physrisk_assets.asset_type
	(std_id, std_name, std_name_display, std_description_full, std_description_short, std_tags, std_datetime_utc_created, std_creator_user_id, std_datetime_utc_last_modified, std_last_modifier_user_id, std_is_deleted, std_deleter_user_id, std_datetime_utc_deleted, std_culture, std_checksum, std_seq_num, std_translated_from_id, std_is_active, std_is_published, std_publisher_id, std_datetime_utc_published,asset_class_id)
VALUES 
	('d1317024-2a21-4c89-8e7c-8609798dcc09', 'Multi-family apartments', 'Multi-family apartments', 'Multi-family apartments', 'Multi-family apartments', '{}','2024-07-25T00:00:01Z',1,'2024-07-25T00:00:01Z',1,'n',NULL,NULL, 'en', 'std_checksum',1,NULL, 'y','y',1,'2024-07-25T00:00:01Z','db4a14a2-a27b-4bb0-8249-a07fb78438f4');
INSERT INTO osc_physrisk_assets.asset_type
	(std_id, std_name, std_name_display, std_description_full, std_description_short, std_tags, std_datetime_utc_created, std_creator_user_id, std_datetime_utc_last_modified, std_last_modifier_user_id, std_is_deleted, std_deleter_user_id, std_datetime_utc_deleted, std_culture, std_checksum, std_seq_num, std_translated_from_id, std_is_active, std_is_published, std_publisher_id, std_datetime_utc_published,asset_class_id)
VALUES 
	('6ba2fda4-c6a7-4142-9e63-19948fe385f3', 'High-rise residential buildings', 'High-rise residential buildings', 'High-rise residential buildings', 'High-rise residential buildings', '{}','2024-07-25T00:00:01Z',1,'2024-07-25T00:00:01Z',1,'n',NULL,NULL, 'en', 'std_checksum',1,NULL, 'y','y',1,'2024-07-25T00:00:01Z','db4a14a2-a27b-4bb0-8249-a07fb78438f4');
INSERT INTO osc_physrisk_assets.asset_type
	(std_id, std_name, std_name_display, std_description_full, std_description_short, std_tags, std_datetime_utc_created, std_creator_user_id, std_datetime_utc_last_modified, std_last_modifier_user_id, std_is_deleted, std_deleter_user_id, std_datetime_utc_deleted, std_culture, std_checksum, std_seq_num, std_translated_from_id, std_is_active, std_is_published, std_publisher_id, std_datetime_utc_published,asset_class_id)
VALUES 
	('85246f30-e622-4af9-af86-16b23e8671a7', 'Retail Stores', 'Retail Stores', 'Retail Stores', 'Retail Stores', '{}','2024-07-25T00:00:01Z',1,'2024-07-25T00:00:01Z',1,'n',NULL,NULL, 'en', 'std_checksum',1,NULL, 'y','y',1,'2024-07-25T00:00:01Z','536e8cee-682f-4cd6-b23e-b32e885cc094');
INSERT INTO osc_physrisk_assets.asset_type
	(std_id, std_name, std_name_display, std_description_full, std_description_short, std_tags, std_datetime_utc_created, std_creator_user_id, std_datetime_utc_last_modified, std_last_modifier_user_id, std_is_deleted, std_deleter_user_id, std_datetime_utc_deleted, std_culture, std_checksum, std_seq_num, std_translated_from_id, std_is_active, std_is_published, std_publisher_id, std_datetime_utc_published,asset_class_id)
VALUES 
	('e9d9c1d6-915b-4450-ae2e-9fb2ad624478', 'Office buildings', 'Office buildings', 'Office buildings', 'Office buildings', '{}','2024-07-25T00:00:01Z',1,'2024-07-25T00:00:01Z',1,'n',NULL,NULL, 'en', 'std_checksum',1,NULL, 'y','y',1,'2024-07-25T00:00:01Z','536e8cee-682f-4cd6-b23e-b32e885cc094');
INSERT INTO osc_physrisk_assets.asset_type
	(std_id, std_name, std_name_display, std_description_full, std_description_short, std_tags, std_datetime_utc_created, std_creator_user_id, std_datetime_utc_last_modified, std_last_modifier_user_id, std_is_deleted, std_deleter_user_id, std_datetime_utc_deleted, std_culture, std_checksum, std_seq_num, std_translated_from_id, std_is_active, std_is_published, std_publisher_id, std_datetime_utc_published,asset_class_id)
VALUES 
	('f403566e-04eb-47aa-8327-ce6a43220867', 'Hotels and hospitality facilities', 'Hotels and hospitality facilities', 'Hotels and hospitality facilities', 'Hotels and hospitality facilities', '{}','2024-07-25T00:00:01Z',1,'2024-07-25T00:00:01Z',1,'n',NULL,NULL, 'en', 'std_checksum',1,NULL, 'y','y',1,'2024-07-25T00:00:01Z','536e8cee-682f-4cd6-b23e-b32e885cc094');

INSERT INTO osc_physrisk_assets.asset_type
	(std_id, std_name, std_name_display, std_description_full, std_description_short, std_tags, std_datetime_utc_created, std_creator_user_id, std_datetime_utc_last_modified, std_last_modifier_user_id, std_is_deleted, std_deleter_user_id, std_datetime_utc_deleted, std_culture, std_checksum, std_seq_num, std_translated_from_id, std_is_active, std_is_published, std_publisher_id, std_datetime_utc_published,asset_class_id)
VALUES 
	('ce606ca8-8f4c-429b-bdea-da87ed28087e', 'Highways', 'Highways', 'Highways', 'Highways', '{}','2024-07-25T00:00:01Z',1,'2024-07-25T00:00:01Z',1,'n',NULL,NULL, 'en', 'std_checksum',1,NULL, 'y','y',1,'2024-07-25T00:00:01Z','f2baa602-44fe-49be-a5c9-d8b8208d9499');
INSERT INTO osc_physrisk_assets.asset_type
	(std_id, std_name, std_name_display, std_description_full, std_description_short, std_tags, std_datetime_utc_created, std_creator_user_id, std_datetime_utc_last_modified, std_last_modifier_user_id, std_is_deleted, std_deleter_user_id, std_datetime_utc_deleted, std_culture, std_checksum, std_seq_num, std_translated_from_id, std_is_active, std_is_published, std_publisher_id, std_datetime_utc_published,asset_class_id)
VALUES 
	('20265e12-495b-46ee-af68-246216f0dacb', 'Bridges', 'Bridges', 'Bridges', 'Bridges', '{}','2024-07-25T00:00:01Z',1,'2024-07-25T00:00:01Z',1,'n',NULL,NULL, 'en', 'std_checksum',1,NULL, 'y','y',1,'2024-07-25T00:00:01Z','f2baa602-44fe-49be-a5c9-d8b8208d9499');
INSERT INTO osc_physrisk_assets.asset_type
	(std_id, std_name, std_name_display, std_description_full, std_description_short, std_tags, std_datetime_utc_created, std_creator_user_id, std_datetime_utc_last_modified, std_last_modifier_user_id, std_is_deleted, std_deleter_user_id, std_datetime_utc_deleted, std_culture, std_checksum, std_seq_num, std_translated_from_id, std_is_active, std_is_published, std_publisher_id, std_datetime_utc_published,asset_class_id)
VALUES 
	('64d4ffe2-e8b2-480d-9234-da51e53661d1', 'Railroads', 'Railroads', 'Railroads', 'Railroads', '{}','2024-07-25T00:00:01Z',1,'2024-07-25T00:00:01Z',1,'n',NULL,NULL, 'en', 'std_checksum',1,NULL, 'y','y',1,'2024-07-25T00:00:01Z','f2baa602-44fe-49be-a5c9-d8b8208d9499');
INSERT INTO osc_physrisk_assets.asset_type
	(std_id, std_name, std_name_display, std_description_full, std_description_short, std_tags, std_datetime_utc_created, std_creator_user_id, std_datetime_utc_last_modified, std_last_modifier_user_id, std_is_deleted, std_deleter_user_id, std_datetime_utc_deleted, std_culture, std_checksum, std_seq_num, std_translated_from_id, std_is_active, std_is_published, std_publisher_id, std_datetime_utc_published,asset_class_id)
VALUES 
	('3a568df0-cf71-4598-9bc7-2fb5997fb30d', 'Power transmission lines', 'Power transmission lines', 'Power transmission lines', 'Power transmission lines', '{}','2024-07-25T00:00:01Z',1,'2024-07-25T00:00:01Z',1,'n',NULL,NULL, 'en', 'std_checksum',1,NULL, 'y','y',1,'2024-07-25T00:00:01Z','f2baa602-44fe-49be-a5c9-d8b8208d9499');
INSERT INTO osc_physrisk_assets.asset_type
	(std_id, std_name, std_name_display, std_description_full, std_description_short, std_tags, std_datetime_utc_created, std_creator_user_id, std_datetime_utc_last_modified, std_last_modifier_user_id, std_is_deleted, std_deleter_user_id, std_datetime_utc_deleted, std_culture, std_checksum, std_seq_num, std_translated_from_id, std_is_active, std_is_published, std_publisher_id, std_datetime_utc_published,asset_class_id)
VALUES 
	('c7431f81-f1a7-42ca-90bd-6f43defe7931', 'Water treatment plants', 'Water treatment plants', 'Water treatment plants', 'Water treatment plants', '{}','2024-07-25T00:00:01Z',1,'2024-07-25T00:00:01Z',1,'n',NULL,NULL, 'en', 'std_checksum',1,NULL, 'y','y',1,'2024-07-25T00:00:01Z','f2baa602-44fe-49be-a5c9-d8b8208d9499');

INSERT INTO osc_physrisk_assets.asset_type
	(std_id, std_name, std_name_display, std_description_full, std_description_short, std_tags, std_datetime_utc_created, std_creator_user_id, std_datetime_utc_last_modified, std_last_modifier_user_id, std_is_deleted, std_deleter_user_id, std_datetime_utc_deleted, std_culture, std_checksum, std_seq_num, std_translated_from_id, std_is_active, std_is_published, std_publisher_id, std_datetime_utc_published,asset_class_id)
VALUES 
	('34ec5bde-96dc-4f50-86f4-71bef7f2271a', 'Irrigated cropland', 'Irrigated cropland', 'Irrigated cropland', 'Irrigated cropland', '{}','2024-07-25T00:00:01Z',1,'2024-07-25T00:00:01Z',1,'n',NULL,NULL, 'en', 'std_checksum',1,NULL, 'y','y',1,'2024-07-25T00:00:01Z','a9da716f-6667-4efe-bac7-f91c1cdcc2f1');
INSERT INTO osc_physrisk_assets.asset_type
	(std_id, std_name, std_name_display, std_description_full, std_description_short, std_tags, std_datetime_utc_created, std_creator_user_id, std_datetime_utc_last_modified, std_last_modifier_user_id, std_is_deleted, std_deleter_user_id, std_datetime_utc_deleted, std_culture, std_checksum, std_seq_num, std_translated_from_id, std_is_active, std_is_published, std_publisher_id, std_datetime_utc_published,asset_class_id)
VALUES 
	('9115c6ec-776f-45c2-a74b-010f7a21355c', 'Non-irrigated cropland', 'Non-irrigated cropland', 'Non-irrigated cropland', 'Non-irrigated cropland', '{}','2024-07-25T00:00:01Z',1,'2024-07-25T00:00:01Z',1,'n',NULL,NULL, 'en', 'std_checksum',1,NULL, 'y','y',1,'2024-07-25T00:00:01Z','a9da716f-6667-4efe-bac7-f91c1cdcc2f1');
INSERT INTO osc_physrisk_assets.asset_type
	(std_id, std_name, std_name_display, std_description_full, std_description_short, std_tags, std_datetime_utc_created, std_creator_user_id, std_datetime_utc_last_modified, std_last_modifier_user_id, std_is_deleted, std_deleter_user_id, std_datetime_utc_deleted, std_culture, std_checksum, std_seq_num, std_translated_from_id, std_is_active, std_is_published, std_publisher_id, std_datetime_utc_published,asset_class_id)
VALUES 
	('076c1110-a9e8-435c-994e-499bed18bc11', 'Livestock farms', 'Livestock farms', 'Livestock farms', 'Livestock farms', '{}','2024-07-25T00:00:01Z',1,'2024-07-25T00:00:01Z',1,'n',NULL,NULL, 'en', 'std_checksum',1,NULL, 'y','y',1,'2024-07-25T00:00:01Z','a9da716f-6667-4efe-bac7-f91c1cdcc2f1');
INSERT INTO osc_physrisk_assets.asset_type
	(std_id, std_name, std_name_display, std_description_full, std_description_short, std_tags, std_datetime_utc_created, std_creator_user_id, std_datetime_utc_last_modified, std_last_modifier_user_id, std_is_deleted, std_deleter_user_id, std_datetime_utc_deleted, std_culture, std_checksum, std_seq_num, std_translated_from_id, std_is_active, std_is_published, std_publisher_id, std_datetime_utc_published,asset_class_id)
VALUES 
	('8135bb62-54e7-4eb4-ad76-5b2b8e08c02e', 'Greenhouses', 'Greenhouses', 'Greenhouses', 'Greenhouses', '{}','2024-07-25T00:00:01Z',1,'2024-07-25T00:00:01Z',1,'n',NULL,NULL, 'en', 'std_checksum',1,NULL, 'y','y',1,'2024-07-25T00:00:01Z','a9da716f-6667-4efe-bac7-f91c1cdcc2f1');
INSERT INTO osc_physrisk_assets.asset_type
	(std_id, std_name, std_name_display, std_description_full, std_description_short, std_tags, std_datetime_utc_created, std_creator_user_id, std_datetime_utc_last_modified, std_last_modifier_user_id, std_is_deleted, std_deleter_user_id, std_datetime_utc_deleted, std_culture, std_checksum, std_seq_num, std_translated_from_id, std_is_active, std_is_published, std_publisher_id, std_datetime_utc_published,asset_class_id)
VALUES 
	('8bd9e90c-cfa9-404e-ad02-c3e53fad0210', 'Manufacturing plants', 'Manufacturing plants', 'Manufacturing plants', 'Manufacturing plants', '{}','2024-07-25T00:00:01Z',1,'2024-07-25T00:00:01Z',1,'n',NULL,NULL, 'en', 'std_checksum',1,NULL, 'y','y',1,'2024-07-25T00:00:01Z','1ad910c8-fba0-4f45-845e-5a1901b9ffbe');
INSERT INTO osc_physrisk_assets.asset_type
	(std_id, std_name, std_name_display, std_description_full, std_description_short, std_tags, std_datetime_utc_created, std_creator_user_id, std_datetime_utc_last_modified, std_last_modifier_user_id, std_is_deleted, std_deleter_user_id, std_datetime_utc_deleted, std_culture, std_checksum, std_seq_num, std_translated_from_id, std_is_active, std_is_published, std_publisher_id, std_datetime_utc_published,asset_class_id)
VALUES 
	('b5c703ea-336e-4a97-8883-971f1a275b69', 'Storage warehouses', 'Storage warehouses', 'Storage warehouses', 'Storage warehouses', '{}','2024-07-25T00:00:01Z',1,'2024-07-25T00:00:01Z',1,'n',NULL,NULL, 'en', 'std_checksum',1,NULL, 'y','y',1,'2024-07-25T00:00:01Z','1ad910c8-fba0-4f45-845e-5a1901b9ffbe');
INSERT INTO osc_physrisk_assets.asset_type
	(std_id, std_name, std_name_display, std_description_full, std_description_short, std_tags, std_datetime_utc_created, std_creator_user_id, std_datetime_utc_last_modified, std_last_modifier_user_id, std_is_deleted, std_deleter_user_id, std_datetime_utc_deleted, std_culture, std_checksum, std_seq_num, std_translated_from_id, std_is_active, std_is_published, std_publisher_id, std_datetime_utc_published,asset_class_id)
VALUES 
	('94face63-24ef-46ef-ac13-7565c7d81789', 'Chemical processing facilities', 'Chemical processing facilities', 'Chemical processing facilities', 'Chemical processing facilities', '{}','2024-07-25T00:00:01Z',1,'2024-07-25T00:00:01Z',1,'n',NULL,NULL, 'en', 'std_checksum',1,NULL, 'y','y',1,'2024-07-25T00:00:01Z','1ad910c8-fba0-4f45-845e-5a1901b9ffbe');


INSERT INTO osc_physrisk_assets.asset_type
	(std_id, std_name, std_name_display, std_description_full, std_description_short, std_tags, std_datetime_utc_created, std_creator_user_id, std_datetime_utc_last_modified, std_last_modifier_user_id, std_is_deleted, std_deleter_user_id, std_datetime_utc_deleted, std_culture, std_checksum, std_seq_num, std_translated_from_id, std_is_active, std_is_published, std_publisher_id, std_datetime_utc_published,asset_class_id)
VALUES 
	('7eb31e49-883b-4c0d-9464-404fc49b8eaa', 'Forest ecosystems', 'Forest ecosystems', 'Forest ecosystems', 'Forest ecosystems', '{}','2024-07-25T00:00:01Z',1,'2024-07-25T00:00:01Z',1,'n',NULL,NULL, 'en', 'std_checksum',1,NULL, 'y','y',1,'2024-07-25T00:00:01Z','2b5557e6-05ee-49d6-b6a6-b7ef54948af7');
INSERT INTO osc_physrisk_assets.asset_type
	(std_id, std_name, std_name_display, std_description_full, std_description_short, std_tags, std_datetime_utc_created, std_creator_user_id, std_datetime_utc_last_modified, std_last_modifier_user_id, std_is_deleted, std_deleter_user_id, std_datetime_utc_deleted, std_culture, std_checksum, std_seq_num, std_translated_from_id, std_is_active, std_is_published, std_publisher_id, std_datetime_utc_published,asset_class_id)
VALUES 
	('ae7851b9-123f-4ab6-8d26-594c88e2a6f5', 'River basins', 'River basins', 'River basins', 'River basins', '{}','2024-07-25T00:00:01Z',1,'2024-07-25T00:00:01Z',1,'n',NULL,NULL, 'en', 'std_checksum',1,NULL, 'y','y',1,'2024-07-25T00:00:01Z','2b5557e6-05ee-49d6-b6a6-b7ef54948af7');
INSERT INTO osc_physrisk_assets.asset_type
	(std_id, std_name, std_name_display, std_description_full, std_description_short, std_tags, std_datetime_utc_created, std_creator_user_id, std_datetime_utc_last_modified, std_last_modifier_user_id, std_is_deleted, std_deleter_user_id, std_datetime_utc_deleted, std_culture, std_checksum, std_seq_num, std_translated_from_id, std_is_active, std_is_published, std_publisher_id, std_datetime_utc_published,asset_class_id)
VALUES 
	('ef7cbcbc-adec-462f-84e6-d49de80fb882', 'Coastal wetlands', 'Coastal wetlands', 'Coastal wetlands', 'Coastal wetlands', '{}','2024-07-25T00:00:01Z',1,'2024-07-25T00:00:01Z',1,'n',NULL,NULL, 'en', 'std_checksum',1,NULL, 'y','y',1,'2024-07-25T00:00:01Z','2b5557e6-05ee-49d6-b6a6-b7ef54948af7');
INSERT INTO osc_physrisk_assets.asset_type
	(std_id, std_name, std_name_display, std_description_full, std_description_short, std_tags, std_datetime_utc_created, std_creator_user_id, std_datetime_utc_last_modified, std_last_modifier_user_id, std_is_deleted, std_deleter_user_id, std_datetime_utc_deleted, std_culture, std_checksum, std_seq_num, std_translated_from_id, std_is_active, std_is_published, std_publisher_id, std_datetime_utc_published,asset_class_id)
VALUES 
	('27628236-0486-4816-9487-dd9d9ccc9c5d', 'Historic buildings', 'Historic buildings', 'Historic buildings', 'Historic buildings', '{}','2024-07-25T00:00:01Z',1,'2024-07-25T00:00:01Z',1,'n',NULL,NULL, 'en', 'std_checksum',1,NULL, 'y','y',1,'2024-07-25T00:00:01Z','beafc1fa-f6c8-4c72-9717-a243eea1a2ef');
INSERT INTO osc_physrisk_assets.asset_type
	(std_id, std_name, std_name_display, std_description_full, std_description_short, std_tags, std_datetime_utc_created, std_creator_user_id, std_datetime_utc_last_modified, std_last_modifier_user_id, std_is_deleted, std_deleter_user_id, std_datetime_utc_deleted, std_culture, std_checksum, std_seq_num, std_translated_from_id, std_is_active, std_is_published, std_publisher_id, std_datetime_utc_published,asset_class_id)
VALUES 
	('82a14f2d-4db9-4df4-b62b-11b4aa157ebf', 'Archaeological Sites', 'Archaeological Sites', 'Archaeological Sites', 'Archaeological Sites', '{}','2024-07-25T00:00:01Z',1,'2024-07-25T00:00:01Z',1,'n',NULL,NULL, 'en', 'std_checksum',1,NULL, 'y','y',1,'2024-07-25T00:00:01Z','beafc1fa-f6c8-4c72-9717-a243eea1a2ef');
INSERT INTO osc_physrisk_assets.asset_type
	(std_id, std_name, std_name_display, std_description_full, std_description_short, std_tags, std_datetime_utc_created, std_creator_user_id, std_datetime_utc_last_modified, std_last_modifier_user_id, std_is_deleted, std_deleter_user_id, std_datetime_utc_deleted, std_culture, std_checksum, std_seq_num, std_translated_from_id, std_is_active, std_is_published, std_publisher_id, std_datetime_utc_published,asset_class_id)
VALUES 
	('bdea3237-f764-4907-98cd-e0d131e099c5', 'Museums', 'Museums', 'Museums', 'Museums', '{}','2024-07-25T00:00:01Z',1,'2024-07-25T00:00:01Z',1,'n',NULL,NULL, 'en', 'std_checksum',1,NULL, 'y','y',1,'2024-07-25T00:00:01Z','beafc1fa-f6c8-4c72-9717-a243eea1a2ef');



INSERT INTO osc_physrisk_assets.portfolio
	(std_id, std_name, std_name_display, std_description_full, std_description_short, std_tags, std_datetime_utc_created, std_creator_user_id, std_datetime_utc_last_modified, std_last_modifier_user_id, std_is_deleted, std_deleter_user_id, std_datetime_utc_deleted, std_culture, std_checksum, std_seq_num, std_translated_from_id, std_is_active, std_tenant_id, std_is_published, std_publisher_id, std_datetime_utc_published, value_total, value_currency_alphabetic_code)
VALUES 
	('07c629be-42c6-4dbe-bd56-83e64253368d', 'Example Portfolio 1', 'Example Portfolio 1', 'Example Portfolio 1', 'Example Portfolio 1', '{}','2024-07-25T00:00:01Z',1,'2024-07-25T00:00:01Z',1,'n',NULL,NULL, 'en', 'std_checksum',1,NULL, 'y', 1,'y',1,'2024-07-25T00:00:01Z', 12345678.90, 'USD');

INSERT INTO osc_physrisk_assets.asset_realestate
	(std_id, std_name, std_name_display, std_description_full, std_description_short, std_tags, std_datetime_utc_created, std_creator_user_id, std_datetime_utc_last_modified, std_last_modifier_user_id, std_is_deleted, std_deleter_user_id, std_datetime_utc_deleted, std_culture, std_checksum, std_seq_num, std_translated_from_id, std_is_active,std_tenant_id, std_is_published, std_publisher_id, std_datetime_utc_published, portfolio_id, std_geo_location_name, std_geo_location_coordinates, std_geo_overture_features, std_geo_h3_index, std_geo_h3_resolution, asset_type_id, owner_bloomberg_id, owner_lei_id, value_total, value_currency_alphabetic_code, value_ltv)
VALUES 
	('281d68cc-ffd3-4740-acd6-1ea23bce902f', 'Commercial Real Estate asset example', 'Commercial Real Estate asset example', 'Commercial Real Estate asset example', 'Commercial Real Estate asset example', '{"naics":[531111],"oed:occupancy:oed_code":1050,"oed:occupancy:air_code":301}','2024-07-25T00:00:01Z',1,'2024-07-25T00:00:01Z',1,'n',NULL,NULL, 'en', 'std_checksum',1,NULL, 'y', 1,'y',1,'2024-07-25T00:00:01Z' , '07c629be-42c6-4dbe-bd56-83e64253368d', 'Fake location', ST_GeomFromText('POINT(-71.064544 42.28787)'), '{}', '1234', 12, '85246f30-e622-4af9-af86-16b23e8671a7', 'BBG000BLNQ16', '', 12345678.90, 'USD','{LTV value ratio}')
;
INSERT INTO osc_physrisk_assets.asset_powergeneratingutility
	(std_id, std_name, std_name_display, std_description_full, std_description_short, std_tags, std_datetime_utc_created, std_creator_user_id, std_datetime_utc_last_modified, std_last_modifier_user_id, std_is_deleted, std_deleter_user_id, std_datetime_utc_deleted, std_culture, std_checksum, std_seq_num, std_translated_from_id, std_is_active, std_tenant_id, std_is_published, std_publisher_id, std_datetime_utc_published, portfolio_id, std_geo_location_name, std_geo_location_coordinates, std_geo_overture_features, std_geo_h3_index, std_geo_h3_resolution,asset_type_id,  owner_bloomberg_id, owner_lei_id, value_total, value_currency_alphabetic_code, production, capacity, availability_rate)
VALUES 
	('78cb5382-5e4f-4762-b2e8-7cb33954f788', 'Electrical Power Generating Utility example', 'Electrical Power Generating Utility example', 'Electrical Power Generating Utility example', 'Electrical Power Generating Utility example', '{"naics":[22111],"oed:occupancy:oed_code":1300,"oed:occupancy:air_code":361}','2024-07-25T00:00:01Z',1,'2024-07-25T00:00:01Z',1,'n',NULL,NULL, 'en', 'std_checksum',1,NULL, 'y', 1,'y',1,'2024-07-25T00:00:01Z' , '07c629be-42c6-4dbe-bd56-83e64253368d', 'Fake location', ST_GeomFromText('POINT(-71.064544 42.28787)'), '{}', '1234', 12, '3a568df0-cf71-4598-9bc7-2fb5997fb30d', 'BBG000BLNQ16', '', 12345678.90, 'USD', 12345.0,100.00,95.00)
;

-- INSERT EXPOSURE, VULNERABILITY, AND FINANCIAL MODELS
INSERT INTO osc_physrisk.osc_physrisk_vulnerability_analysis.exposure_function
	(std_id, std_name, std_name_display, std_slug, std_abbreviation, std_description_full, std_description_short, std_tags, std_datetime_utc_created, std_creator_user_id, std_datetime_utc_last_modified, std_last_modifier_user_id, std_is_active, std_is_deleted, std_deleter_user_id, std_datetime_utc_deleted, std_tenant_id, std_culture, std_checksum, std_seq_num, std_translated_from_id, std_is_published, std_publisher_id, std_datetime_utc_published, std_version, std_dataset_id)
VALUES 
	('3f2a5033-cd68-4a04-93a6-a1ce2b5270eb', 'OS-C Phys Risk Flood Exposure & Vulnerability Model', 'OS-C Phys Risk Flood Exposure & Vulnerability Model', 'osc-physrisk-model-vulnerability-flooda','OS-C Flood', 'OS-C Phys Risk Flood Vulnerability Model', 'OS-C Phys Risk Flood Vulnerability Model', '{}', '2024-07-25T00:00:01Z',1,'2024-07-25T00:00:01Z',1,'y','n',NULL,NULL, 1,'en', 'std_checksum',1,NULL, 'y', 1,'2024-07-25T00:00:01Z','1.0',NULL)
;

INSERT INTO osc_physrisk.osc_physrisk_vulnerability_analysis.vulnerability_function
	(std_id, std_name, std_name_display, std_slug, std_abbreviation, std_description_full, std_description_short, std_tags, std_datetime_utc_created, std_creator_user_id, std_datetime_utc_last_modified, std_last_modifier_user_id, std_is_active, std_is_deleted, std_deleter_user_id, std_datetime_utc_deleted, std_tenant_id, std_culture, std_checksum, std_seq_num, std_translated_from_id, std_is_published, std_publisher_id, std_datetime_utc_published, std_version, std_dataset_id)
VALUES 
	('0a980ae7-5c2c-4996-8d87-e0337d92c13b', 'OS-C Phys Risk Flood Vulnerability Model', 'OS-C Phys Risk Flood Vulnerability Model', 'osc-physrisk-model-vulnerability-flooda','OS-C Flood', 'OS-C Phys Risk Flood Vulnerability Model', 'OS-C Phys Risk Flood Vulnerability Model', '{}', '2024-07-25T00:00:01Z',1,'2024-07-25T00:00:01Z',1,'y','n',NULL,NULL, 1,'en', 'std_checksum',1,NULL, 'y', 1,'2024-07-25T00:00:01Z','1.0',NULL)
;

-- INSERT PRECALCULATED IMPACT EXAMPLE
INSERT INTO osc_physrisk_vulnerability_analysis.geolocated_precalculated_vulnerability
	(std_id, std_name, std_name_display, std_abbreviation, std_description_full, std_description_short, std_tags, std_datetime_utc_created, std_creator_user_id, std_datetime_utc_last_modified, std_last_modifier_user_id, std_is_deleted, std_deleter_user_id, std_datetime_utc_deleted, std_culture, std_checksum, std_seq_num, std_translated_from_id, std_is_active, std_tenant_id,std_is_published, std_publisher_id, std_datetime_utc_published, hazard_indicator_id, scenario_id, scenario_year, std_geo_location_name, std_geo_location_address, std_geo_location_coordinates, std_geo_overture_features, std_geo_h3_index, std_geo_h3_resolution, vulnerability_level, vulnerability_historically, std_datetime_utc_start, std_datetime_utc_end, exposure_function_id, exposure_level, exposure_data_raw, vulnerability_function_id, vulnerability_type_id, vulnerability_data_raw)
VALUES 
	('3bbb4a0e-f719-4e78-864b-3962e7f9e3a4', 'Example stored precalculated impact damage curve for Utility', 'Example stored precalculated impact damage curve for Utility', NULL, 'Example stored precalculated impact damage curve for Utility','Example stored precalculated impact damage curve for Utility', '{ "key1":"value1", "key2":"value2"}','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'en', 'std_checksum',1,NULL,'y', 1,'y',1,'2024-07-15T00:00:01Z','57a7df66-420d-4730-9669-1547f8200272', '5d1081f3-fd0e-4f53-b06b-8358be82644c', 2040, '07c629be-42c6-4dbe-bd56-83e64253368d', 'Fake location', ST_GeomFromText('POINT(-71.064544 42.28787)'), '{}', '1234', 12, 0.5, 'n',NULL ,NULL ,	
	'3f2a5033-cd68-4a04-93a6-a1ce2b5270eb',
	0.6,
	'{ "some":"exposure_data"}',
	'0a980ae7-5c2c-4996-8d87-e0337d92c13b',
	1,	
	'{
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
            "financial_impact_type": "Disruption",
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
            "financial_impact_type": "Disruption",
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
            "financial_impact_type": "Disruption",
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
            "financial_impact_type": "Disruption",
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
            "financial_impact_type": "Disruption",
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
            "financial_impact_type": "Disruption",
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
            "financial_impact_type": "Disruption",
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
            "financial_impact_type": "Disruption",
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
            "financial_impact_type": "Disruption",
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
            "financial_impact_type": "Disruption",
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
            "financial_impact_type": "Disruption",
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
            "financial_impact_type": "Disruption",
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
            "financial_impact_type": "Disruption",
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


	-- DATA IN FRENCH STARTS
INSERT INTO osc_physrisk_scenarios.scenario
	(std_id, std_description_full, std_description_short, std_name_display, std_name, std_tags, std_datetime_utc_created, std_creator_user_id, std_datetime_utc_last_modified, std_last_modifier_user_id, std_is_deleted, std_deleter_user_id, std_datetime_utc_deleted, std_culture, std_checksum, std_seq_num, std_translated_from_id, std_is_active, std_is_published, std_publisher_id, std_datetime_utc_published)
VALUES 
	('0c438638-0ce2-4be1-b669-4d3e0d0e97e5', 'Inconnu/Aucun selection', 'Inconnu/Aucun selection', 'Inconnu/Aucun selection', 'Inconnu/Aucun selection','{ "key1":"value1", "key2":"value2"}','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'fr', 'std_checksum',1,'8b3b38fd-a6f5-4878-b4b4-0a251ec0363a', 'y','y', 1,'2024-07-15T00:00:01Z')
;
INSERT INTO osc_physrisk_scenarios.scenario
	(std_id, std_description_full, std_description_short, std_name_display, std_name, std_tags, std_datetime_utc_created, std_creator_user_id, std_datetime_utc_last_modified, std_last_modifier_user_id, std_is_deleted, std_deleter_user_id, std_datetime_utc_deleted, std_culture, std_checksum, std_seq_num, std_translated_from_id, std_is_active, std_is_published, std_publisher_id, std_datetime_utc_published)
VALUES 
	('c7450c04-42d3-41bf-a2a7-eb9af0e70873', 'Historique (avant 2014). Voir "Scénarios d''émissions et de réchauffement futurs dans le sixième Rapport d''évaluation du GIEC" (https://www.ipcc.ch/report/ar6/wg1/downloads/report/IPCC_AR6_WG1_SPM_French.pdf).', 'Historique (avant 2014)', 'Historique (avant 2014)', 'Historique (avant 2014)','{ "key1":"value1", "key2":"value2"}','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'fr', 'std_checksum',1,'7faf5507-9a0a-4554-aef3-6efe5cffee63', 'y','y', 1,'2024-07-15T00:00:01Z')
;
INSERT INTO osc_physrisk_scenarios.scenario
	(std_id, std_description_full, std_description_short, std_name_display, std_name, std_tags, std_datetime_utc_created, std_creator_user_id, std_datetime_utc_last_modified, std_last_modifier_user_id, std_is_deleted, std_deleter_user_id, std_datetime_utc_deleted, std_culture, std_checksum, std_seq_num, std_translated_from_id, std_is_active, std_is_published, std_publisher_id, std_datetime_utc_published)
VALUES 
	('08501b6b-92eb-407b-8b37-e6d23645a2d8', 'SSP1-1,9 — émissions de GES en baisse dès 2025, zéro émission nette de CO2 avant 2050, émissions négatives ensuite. Voir "Scénarios d''émissions et de réchauffement futurs dans le sixième Rapport d''évaluation du GIEC" (https://www.ipcc.ch/report/ar6/wg1/downloads/report/IPCC_AR6_WG1_SPM_French.pdf).', 'SSP1-1,9', 'SSP1-1,9', 'SSP1-1,9','{ "key1":"value1", "key2":"value2"}','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'fr', 'std_checksum',1,'0ab07b1d-864d-4f0a-9656-29e9b088df3b', 'y','y', 1,'2024-07-15T00:00:01Z')
;
INSERT INTO osc_physrisk_scenarios.scenario
	(std_id, std_description_full, std_description_short, std_name_display, std_name, std_tags, std_datetime_utc_created, std_creator_user_id, std_datetime_utc_last_modified, std_last_modifier_user_id, std_is_deleted, std_deleter_user_id, std_datetime_utc_deleted, std_culture, std_checksum, std_seq_num, std_translated_from_id, std_is_active, std_is_published, std_publisher_id, std_datetime_utc_published)
VALUES 
	('cb86a7f4-7116-497a-8f7b-14b8b5710e6a', 'SSP1-2,6 — similaire au précédent, mais le zéro émission nette de CO2 est atteint après 2050. Voir "Scénarios d''émissions et de réchauffement futurs dans le sixième Rapport d''évaluation du GIEC" (https://www.ipcc.ch/report/ar6/wg1/downloads/report/IPCC_AR6_WG1_SPM_French.pdf).', 'SSP1-2,6', 'SSP1-2,6', 'SSP1-2,6','{ "key1":"value1", "key2":"value2"}','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'fr', 'std_checksum',1,'cb68b9c6-6dff-4f0d-8650-768249f2689d', 'y','y', 1,'2024-07-15T00:00:01Z')
;
INSERT INTO osc_physrisk_scenarios.scenario
	(std_id, std_description_full, std_description_short, std_name_display, std_name, std_tags, std_datetime_utc_created, std_creator_user_id, std_datetime_utc_last_modified, std_last_modifier_user_id, std_is_deleted, std_deleter_user_id, std_datetime_utc_deleted, std_culture, std_checksum, std_seq_num, std_translated_from_id, std_is_active, std_is_published, std_publisher_id, std_datetime_utc_published)
VALUES 
	('877f33ef-bfc9-47ff-80ed-9fe4bc20f873', 'SSP2-4,5 — maintien des émissions courantes jusqu''en 2050, division par quatre d''ici 2100. Voir "Scénarios d''émissions et de réchauffement futurs dans le sixième Rapport d''évaluation du GIEC" (https://www.ipcc.ch/report/ar6/wg1/downloads/report/IPCC_AR6_WG1_SPM_French.pdf).', 'SSP2-4,5', 'SSP2-4,5', 'SSP2-4,5','{ "key1":"value1", "key2":"value2"}','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'fr', 'std_checksum',1,'5d1081f3-fd0e-4f53-b06b-8358be82644c', 'y','y', 1,'2024-07-15T00:00:01Z')
;
INSERT INTO osc_physrisk_scenarios.scenario
	(std_id, std_description_full, std_description_short, std_name_display, std_name, std_tags, std_datetime_utc_created, std_creator_user_id, std_datetime_utc_last_modified, std_last_modifier_user_id, std_is_deleted, std_deleter_user_id, std_datetime_utc_deleted, std_culture, std_checksum, std_seq_num, std_translated_from_id, std_is_active, std_is_published, std_publisher_id, std_datetime_utc_published)
VALUES 
	('a29cf80d-3c13-4be4-989f-afb8e0ae4a1a', 'SSP3-7,0 — doublement des émissions de GES en 2100. Voir "Scénarios d''émissions et de réchauffement futurs dans le sixième Rapport d''évaluation du GIEC" (https://www.ipcc.ch/report/ar6/wg1/downloads/report/IPCC_AR6_WG1_SPM_French.pdf).', 'SSP3-7,0', 'SSP3-7,0', 'SSP3-7,0','{ "key1":"value1", "key2":"value2"}','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'fr', 'std_checksum',1,'f9ba343c-78b6-426c-be56-5d845e305d58', 'y','y', 1,'2024-07-15T00:00:01Z')
;
INSERT INTO osc_physrisk_scenarios.scenario
	(std_id, std_description_full, std_description_short, std_name_display, std_name, std_tags, std_datetime_utc_created, std_creator_user_id, std_datetime_utc_last_modified, std_last_modifier_user_id, std_is_deleted, std_deleter_user_id, std_datetime_utc_deleted, std_culture, std_checksum, std_seq_num, std_translated_from_id, std_is_active, std_is_published, std_publisher_id, std_datetime_utc_published)
VALUES 
	('8568c7aa-6052-42f0-9c7d-fb2b0962571a', 'SSP5-8,5 — émissions de GES en forte augmentation, doublement en 2050. Voir "Scénarios d''émissions et de réchauffement futurs dans le sixième Rapport d''évaluation du GIEC" (https://www.ipcc.ch/report/ar6/wg1/downloads/report/IPCC_AR6_WG1_SPM_French.pdf).', 'SSP5-8,5', 'SSP5-8,5', 'SSP5-8,5','{ "key1":"value1", "key2":"value2"}','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'fr', 'std_checksum',1,'fd76becb-28e9-424b-8c6e-c96aaf6988e5', 'y','y', 1,'2024-07-15T00:00:01Z')
;
INSERT INTO osc_physrisk_scenarios.scenario
	(std_id, std_description_full, std_description_short, std_name_display, std_name, std_tags, std_datetime_utc_created, std_creator_user_id, std_datetime_utc_last_modified, std_last_modifier_user_id, std_is_deleted, std_deleter_user_id, std_datetime_utc_deleted, std_culture, std_checksum, std_seq_num, std_translated_from_id, std_is_active, std_is_published, std_publisher_id, std_datetime_utc_published)
VALUES 
	('38fa655f-7caf-4102-968f-f4d9420e143e', 'RCP2.6 - le scénario d''émissions faibles, nous présente un futur où nous limitons les changements climatiques d''origine humaine. Le maximum des émissions de carbone est atteint rapstd_idement, suivi d''une réduction qui mène vers une valeur presque nulle bien avant la fin du siècle. Voir « Scénarios d''émissions : les RCP » (https://donneesclimatiques.ca/interactive/scenarios-demissions-les-rcp/)', 'RCP2.6', 'RCP2.6', 'RCP2.6','{ "key1":"value1", "key2":"value2"}','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'fr', 'std_checksum',1,'3cd34fae-620a-47ae-862c-5349533e73b8', 'y','y', 1,'2024-07-15T00:00:01Z')
;
INSERT INTO osc_physrisk_scenarios.scenario
	(std_id, std_description_full, std_description_short, std_name_display, std_name, std_tags, std_datetime_utc_created, std_creator_user_id, std_datetime_utc_last_modified, std_last_modifier_user_id, std_is_deleted, std_deleter_user_id, std_datetime_utc_deleted, std_culture, std_checksum, std_seq_num, std_translated_from_id, std_is_active, std_is_published, std_publisher_id, std_datetime_utc_published)
VALUES 
	('6cd8cb27-7682-4340-95c3-eec02dc69d07', 'RCP4.5 - un scénario d''émissions modérées, nous présente un futur où nous incluons des mesures pour limiter les changements climatiques d''origine humaine. Ce scénario exige que les émissions mondiales de carbone soient stabilisées d''ici la fin du siècle. Voir « Scénarios d''émissions : les RCP » (https://donneesclimatiques.ca/interactive/scenarios-demissions-les-rcp/)', 'RCP4.5', 'RCP4.5', 'RCP4.5','{ "key1":"value1", "key2":"value2"}','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'fr', 'std_checksum',1,'e64b3f6a-69a6-403f-a4bb-e099fe099222', 'y','y', 1,'2024-07-15T00:00:01Z')
;
INSERT INTO osc_physrisk_scenarios.scenario
	(std_id, std_description_full, std_description_short, std_name_display, std_name, std_tags, std_datetime_utc_created, std_creator_user_id, std_datetime_utc_last_modified, std_last_modifier_user_id, std_is_deleted, std_deleter_user_id, std_datetime_utc_deleted, std_culture, std_checksum, std_seq_num, std_translated_from_id, std_is_active, std_is_published, std_publisher_id, std_datetime_utc_published)
VALUES 
	('980ae46b-f6e6-408c-8536-0794e1e2f7a9', 'RCP6 -  Voir « Scénarios d''émissions : les RCP » (https://donneesclimatiques.ca/interactive/scenarios-demissions-les-rcp/)', 'RCP6', 'RCP6', 'RCP6','{ "key1":"value1", "key2":"value2"}','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'fr', 'std_checksum',1,'bb01865e-2a53-48a3-9437-35764ba52639', 'y','y', 1,'2024-07-15T00:00:01Z')
;
INSERT INTO osc_physrisk_scenarios.scenario
	(std_id, std_description_full, std_description_short, std_name_display, std_name, std_tags, std_datetime_utc_created, std_creator_user_id, std_datetime_utc_last_modified, std_last_modifier_user_id, std_is_deleted, std_deleter_user_id, std_datetime_utc_deleted, std_culture, std_checksum, std_seq_num, std_translated_from_id, std_is_active, std_is_published, std_publisher_id, std_datetime_utc_published)
VALUES 
	('ab959faf-edd2-4ea1-ac1e-b824c3b8f4d8', 'RCP8.5 - le scénario d''émissions élevées, nous présente un futur où peu de restrictions aux émissions ont été mises en place. Les émissions continuent d''augmenter rapstd_idement au cours de ce siècle, et se stabilisent seulement après 2250. Voir « Scénarios d''émissions : les RCP » (https://donneesclimatiques.ca/interactive/scenarios-demissions-les-rcp/)', 'RCP8.5', 'RCP8.5', 'RCP8.5','{ "key1":"value1", "key2":"value2"}','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'fr', 'std_checksum',1,'893a6b75-8660-47ff-80d3-08b4ddc259c3', 'y','y', 1,'2024-07-15T00:00:01Z')
;
-- DATA IN FRENCH ENDS

-- DATA IN SPANISH BEGINS
INSERT INTO osc_physrisk_scenarios.scenario
	(std_id, std_description_full, std_description_short, std_name_display, std_name, std_tags, std_datetime_utc_created, std_creator_user_id, std_datetime_utc_last_modified, std_last_modifier_user_id, std_is_deleted, std_deleter_user_id, std_datetime_utc_deleted, std_culture, std_checksum, std_seq_num, std_translated_from_id, std_is_active, std_is_published, std_publisher_id, std_datetime_utc_published)
VALUES 
	('ad206f5e-865c-4f8c-a837-3ea65a894e07', 'Desconocstd_ido/no seleccionado', 'Desconocstd_ido/no seleccionado', 'Desconocstd_ido/no seleccionado', 'Desconocstd_ido/no seleccionado','{ "key1":"value1", "key2":"value2"}','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'es', 'std_checksum',1,'8b3b38fd-a6f5-4878-b4b4-0a251ec0363a', 'y','y', 1,'2024-07-15T00:00:01Z')
;
INSERT INTO osc_physrisk_scenarios.scenario
	(std_id, std_description_full, std_description_short, std_name_display, std_name, std_tags, std_datetime_utc_created, std_creator_user_id, std_datetime_utc_last_modified, std_last_modifier_user_id, std_is_deleted, std_deleter_user_id, std_datetime_utc_deleted, std_culture, std_checksum, std_seq_num, std_translated_from_id, std_is_active, std_is_published, std_publisher_id, std_datetime_utc_published)
VALUES 
	('9a50e648-2619-48af-94cb-e18cbe9b07bd', 'Histórico (antes 2014). Ver "El Grupo Interguberstd_namental de Expertos sobre el Cambio Climático (IPCC)" (https://www.ipcc.ch/languages-2/spanish/).', 'Histórico (antes 2014)', 'Histórico (antes 2014)', 'Histórico (antes 2014)','{ "key1":"value1", "key2":"value2"}','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'es', 'std_checksum',1,'7faf5507-9a0a-4554-aef3-6efe5cffee63', 'y','y', 1,'2024-07-15T00:00:01Z')
;
INSERT INTO osc_physrisk_scenarios.scenario
	(std_id, std_description_full, std_description_short, std_name_display, std_name, std_tags, std_datetime_utc_created, std_creator_user_id, std_datetime_utc_last_modified, std_last_modifier_user_id, std_is_deleted, std_deleter_user_id, std_datetime_utc_deleted, std_culture, std_checksum, std_seq_num, std_translated_from_id, std_is_active, std_is_published, std_publisher_id, std_datetime_utc_published)
VALUES 
	('0cd4961c-2f86-4a3c-94c9-817eb0e53028', 'SSP1-1.9 — Las trayectorias socioeconómicas compartstd_idas (SSP, por sus siglas en inglés) son escenarios de cambios socioeconómicos globales proyectados hasta 2100. Ver "El Grupo Interguberstd_namental de Expertos sobre el Cambio Climático (IPCC)" (https://www.ipcc.ch/languages-2/spanish/).', 'SSP1-1,9', 'SSP1-1,9', 'SSP1-1,9','{ "key1":"value1", "key2":"value2"}','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'es', 'std_checksum',1,'0ab07b1d-864d-4f0a-9656-29e9b088df3b', 'y','y', 1,'2024-07-15T00:00:01Z')
;
INSERT INTO osc_physrisk_scenarios.scenario
	(std_id, std_description_full, std_description_short, std_name_display, std_name, std_tags, std_datetime_utc_created, std_creator_user_id, std_datetime_utc_last_modified, std_last_modifier_user_id, std_is_deleted, std_deleter_user_id, std_datetime_utc_deleted, std_culture, std_checksum, std_seq_num, std_translated_from_id, std_is_active, std_is_published, std_publisher_id, std_datetime_utc_published)
VALUES 
	('c4176c8b-be83-4e2d-8fcb-1e5660a0224e', 'SSP1-2.6 - Las trayectorias socioeconómicas compartstd_idas (SSP, por sus siglas en inglés) son escenarios de cambios socioeconómicos globales proyectados hasta 2100. Ver "El Grupo Interguberstd_namental de Expertos sobre el Cambio Climático (IPCC)" (https://www.ipcc.ch/languages-2/spanish/).', 'SSP1-2.6', 'SSP1-2.6', 'SSP1-2.6','{ "key1":"value1", "key2":"value2"}','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'es', 'std_checksum',1,'cb68b9c6-6dff-4f0d-8650-768249f2689d', 'y','y', 1,'2024-07-15T00:00:01Z')
;
INSERT INTO osc_physrisk_scenarios.scenario
	(std_id, std_description_full, std_description_short, std_name_display, std_name,std_tags,  std_datetime_utc_created, std_creator_user_id, std_datetime_utc_last_modified, std_last_modifier_user_id, std_is_deleted, std_deleter_user_id, std_datetime_utc_deleted, std_culture, std_checksum, std_seq_num, std_translated_from_id, std_is_active, std_is_published, std_publisher_id, std_datetime_utc_published)
VALUES 
	('41ab06bc-506e-4d73-ba2d-20f2b48075e1', 'SSP2-4.5 Las trayectorias socioeconómicas compartstd_idas (SSP, por sus siglas en inglés) son escenarios de cambios socioeconómicos globales proyectados hasta 2100. Ver "El Grupo Interguberstd_namental de Expertos sobre el Cambio Climático (IPCC)" (https://www.ipcc.ch/languages-2/spanish/).', 'SSP2-4.5', 'SSP2-4.5', 'SSP2-4.5','{ "key1":"value1", "key2":"value2"}','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'es', 'std_checksum',1,'5d1081f3-fd0e-4f53-b06b-8358be82644c', 'y','y', 1,'2024-07-15T00:00:01Z')
;
INSERT INTO osc_physrisk_scenarios.scenario
	(std_id, std_description_full, std_description_short, std_name_display, std_name, std_tags, std_datetime_utc_created, std_creator_user_id, std_datetime_utc_last_modified, std_last_modifier_user_id, std_is_deleted, std_deleter_user_id, std_datetime_utc_deleted, std_culture, std_checksum, std_seq_num, std_translated_from_id, std_is_active, std_is_published, std_publisher_id, std_datetime_utc_published)
VALUES 
	('0190968c-5146-4bec-a3bb-c710d192517e', 'SSP3-7.0 - Las trayectorias socioeconómicas compartstd_idas (SSP, por sus siglas en inglés) son escenarios de cambios socioeconómicos globales proyectados hasta 2100. Ver "El Grupo Interguberstd_namental de Expertos sobre el Cambio Climático (IPCC)" (https://www.ipcc.ch/languages-2/spanish/).', 'SSP3-7.0', 'SSP3-7.0', 'SSP3-7.0','{ "key1":"value1", "key2":"value2"}','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'es', 'std_checksum',1,'f9ba343c-78b6-426c-be56-5d845e305d58', 'y','y', 1,'2024-07-15T00:00:01Z')
;
INSERT INTO osc_physrisk_scenarios.scenario
	(std_id, std_description_full, std_description_short, std_name_display, std_name, std_tags, std_datetime_utc_created, std_creator_user_id, std_datetime_utc_last_modified, std_last_modifier_user_id, std_is_deleted, std_deleter_user_id, std_datetime_utc_deleted, std_culture, std_checksum, std_seq_num, std_translated_from_id, std_is_active, std_is_published, std_publisher_id, std_datetime_utc_published)
VALUES 
	('f200a91a-bdbe-4983-a423-de84026b729e', 'SSP5-8.5 - Las trayectorias socioeconómicas compartstd_idas (SSP, por sus siglas en inglés) son escenarios de cambios socioeconómicos globales proyectados hasta 2100. Ver "El Grupo Interguberstd_namental de Expertos sobre el Cambio Climático (IPCC)" (https://www.ipcc.ch/languages-2/spanish/).', 'SSP5-8.5', 'SSP5-8.5', 'SSP5-8.5','{ "key1":"value1", "key2":"value2"}','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'es', 'std_checksum',1,'fd76becb-28e9-424b-8c6e-c96aaf6988e5', 'y','y', 1,'2024-07-15T00:00:01Z')
;
INSERT INTO osc_physrisk_scenarios.scenario
	(std_id, std_description_full, std_description_short, std_name_display, std_name, std_tags, std_datetime_utc_created, std_creator_user_id, std_datetime_utc_last_modified, std_last_modifier_user_id, std_is_deleted, std_deleter_user_id, std_datetime_utc_deleted, std_culture, std_checksum, std_seq_num, std_translated_from_id, std_is_active, std_is_published, std_publisher_id, std_datetime_utc_published)
VALUES 
	('50a460ce-3eff-404c-bd51-73e8df75c2af', 'RCP2.6 Una trayectoria de concentración representativa (RCP, por sus siglas en inglés) es una proyección teórica de una trayectoria de concentración de gases de efecto invernadero (no emisiones) adoptada por el IPCC. Ver "El Grupo Interguberstd_namental de Expertos sobre el Cambio Climático (IPCC)" (https://www.ipcc.ch/languages-2/spanish/).', 'RCP2.6', 'RCP2.6', 'RCP2.6','{ "key1":"value1", "key2":"value2"}','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'es', 'std_checksum',1,'3cd34fae-620a-47ae-862c-5349533e73b8', 'y','y', 1,'2024-07-15T00:00:01Z')
;
INSERT INTO osc_physrisk_scenarios.scenario
	(std_id, std_description_full, std_description_short, std_name_display, std_name, std_tags, std_datetime_utc_created, std_creator_user_id, std_datetime_utc_last_modified, std_last_modifier_user_id, std_is_deleted, std_deleter_user_id, std_datetime_utc_deleted, std_culture, std_checksum, std_seq_num, std_translated_from_id, std_is_active, std_is_published, std_publisher_id, std_datetime_utc_published)
VALUES 
	('61421647-083e-4f1a-8aa7-60314caec48c', 'RCP4.5 - Una trayectoria de concentración representativa (RCP, por sus siglas en inglés) es una proyección teórica de una trayectoria de concentración de gases de efecto invernadero (no emisiones) adoptada por el IPCC. Ver "El Grupo Interguberstd_namental de Expertos sobre el Cambio Climático (IPCC)" (https://www.ipcc.ch/languages-2/spanish/).', 'RCP4.5', 'RCP4.5', 'RCP4.5','{ "key1":"value1", "key2":"value2"}','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'es', 'std_checksum',1,'e64b3f6a-69a6-403f-a4bb-e099fe099222', 'y','y', 1,'2024-07-15T00:00:01Z')
;
INSERT INTO osc_physrisk_scenarios.scenario
	(std_id, std_description_full, std_description_short, std_name_display, std_name,std_tags,  std_datetime_utc_created, std_creator_user_id, std_datetime_utc_last_modified, std_last_modifier_user_id, std_is_deleted, std_deleter_user_id, std_datetime_utc_deleted, std_culture, std_checksum, std_seq_num, std_translated_from_id, std_is_active, std_is_published, std_publisher_id, std_datetime_utc_published)
VALUES 
	('1eb58f59-7e05-4e80-b226-2034e18fe8ac', 'RCP6 - Una trayectoria de concentración representativa (RCP, por sus siglas en inglés) es una proyección teórica de una trayectoria de concentración de gases de efecto invernadero (no emisiones) adoptada por el IPCC. Ver "El Grupo Interguberstd_namental de Expertos sobre el Cambio Climático (IPCC)" (https://www.ipcc.ch/languages-2/spanish/).', 'RCP6', 'RCP6', 'RCP6','{ "key1":"value1", "key2":"value2"}','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'es', 'std_checksum',1,'bb01865e-2a53-48a3-9437-35764ba52639', 'y','y', 1,'2024-07-15T00:00:01Z')
;
INSERT INTO osc_physrisk_scenarios.scenario
	(std_id, std_description_full, std_description_short, std_name_display, std_name, std_tags, std_datetime_utc_created, std_creator_user_id, std_datetime_utc_last_modified, std_last_modifier_user_id, std_is_deleted, std_deleter_user_id, std_datetime_utc_deleted, std_culture, std_checksum, std_seq_num, std_translated_from_id, std_is_active, std_is_published, std_publisher_id, std_datetime_utc_published)
VALUES 
	('5faf38ce-ad9a-4cce-a2a8-807f61b7ec5f', 'RCP8.5 - Una trayectoria de concentración representativa (RCP, por sus siglas en inglés) es una proyección teórica de una trayectoria de concentración de gases de efecto invernadero (no emisiones) adoptada por el IPCC. Ver "El Grupo Interguberstd_namental de Expertos sobre el Cambio Climático (IPCC)" (https://www.ipcc.ch/languages-2/spanish/).', 'RCP8.5', 'RCP8.5', 'RCP8.5','{ "key1":"value1", "key2":"value2"}','2024-07-15T00:00:01Z',1,'2024-07-15T00:00:01Z',1,'n',NULL,NULL, 'es', 'std_checksum',1,'893a6b75-8660-47ff-80d3-08b4ddc259c3', 'y','y', 1,'2024-07-15T00:00:01Z')
;

-- DATA IN SPANISH ENDS

-- EXAMPLE QUERIES
-- VIEW SCENARIOS IN DIFFERENT LANGUAGES
SELECT * FROM osc_physrisk_scenarios.scenario WHERE std_culture='en';
SELECT * FROM osc_physrisk_scenarios.scenario WHERE std_culture='fr';
SELECT * FROM osc_physrisk_scenarios.scenario WHERE std_culture='es';

SELECT a.std_name as "English std_name",  b.std_culture as "Translated std_culture",  b.std_name as "Translated std_name", b.std_description_full as "Translated Description", b.std_tags as "Translated std_tags" FROM osc_physrisk_scenarios.scenario a 
INNER JOIN osc_physrisk_scenarios.scenario b ON a.std_id = b.std_translated_from_id
WHERE b.std_culture='es'  ;

-- QUERY BY std_tags EXAMPLE: FIND ASSETS WITH A CERTAIN NAICS OR OED OCCUPANCY VALUE (SHOWS HOW TO SUPPORT MULTIPLE STANDARDS)
SELECT a.std_name,  a.std_description_full, a.std_tags, b.std_name as asset_class FROM osc_physrisk_assets.asset_powergeneratingutility a INNER JOIN osc_physrisk_assets.asset_class b ON a.std_id = b.std_id
--WHERE a.std_tags -> 'naics'='22111' OR a.std_tags -> 'oed:occupancy:oed_code'='1300' OR a.std_tags -> 'oed:occupancy:air_code'='361' 
;

SELECT a.std_name,  a.std_description_full, a.std_tags, b.std_name as asset_class FROM osc_physrisk_assets.asset_powergeneratingutility a INNER JOIN osc_physrisk_assets.asset_class b ON a.std_id = b.std_id
WHERE a.std_tags -> 'naics' =  '53'
 ;

-- QUERY BY std_tags EXAMPLE: FIND SCENARIOS WITH CERTAIN std_tags
SELECT a.std_name,  a.std_description_full, a.std_tags FROM osc_physrisk_scenarios.scenario a
WHERE a.std_tags -> 'key1'='"value1"' OR a.std_tags -> 'key2'='"value4"'  
;

-- SHOW IMPACT ANALYSIS EXAMPLE (CURRENTLY EMPTY - TODO MISSING TEST DATA)
SELECT	* FROM	osc_physrisk_financial_analysis.portfolio_financial_impact;
SELECT * FROM osc_physrisk_financial_analysis.asset_financial_impact;

-- VIEW RIVERINE INUNDATION HAZARD INDICATORS
SELECT	*
FROM
	osc_physrisk_scenarios.hazard haz INNER JOIN osc_physrisk_scenarios.hazard_indicator hi ON hi.hazard_id = haz.std_id
WHERE haz.std_name = 'Riverine Inundation' -- more likely written as WHERE haz.std_id = '63ed7943-c4c4-43ea-abd2-86bb1997a094'
;

-- VIEW COASTAL INUNDATION HAZARD INDICATORS
SELECT	*
FROM
	 osc_physrisk_scenarios.hazard haz INNER JOIN osc_physrisk_scenarios.hazard_indicator hi ON hi.hazard_id = haz.std_id
WHERE haz.std_id = '28a095cd-4cde-40a1-90d9-cbb0ca673c06'
;

-- VIEW CHRONIC HEAT HAZARD INDICATORS
SELECT	*
FROM
	 osc_physrisk_scenarios.hazard haz INNER JOIN osc_physrisk_scenarios.hazard_indicator hi ON hi.hazard_id = haz.std_id
WHERE haz.std_id = 'd08db675-ee1e-48fe-b9e1-b0da27de8f2b'
;

-- SAMPLE std_checksum UPDATE
--UPDATE osc_physrisk_scenarios.scenario
--	SET std_checksum = md5(concat('Unknown/Not Selected', 'Unknown/Not Selected', 'Unknown/Not Selected', 'Unknown/Not Selected')) WHERE scenario_std_id = -1
--;

-- SELECT DIFFERENT ASSET TYPES
SELECT b.std_name as "Asset Class", a.std_name as "Asset Type", a.std_description_full as "Asset Type Description", b.std_tags as "Asset Class Tags", a.std_tags as "Asset Type Tags" FROM osc_physrisk_assets.asset_type a INNER JOIN osc_physrisk_assets.asset_class b ON a.asset_class_id = b.std_id
WHERE b.std_tags -> 'naics' @>  '45'
--WHERE b.std_tags ->> 'oed:occupancy:oed_code' = '1100'
ORDER BY b.std_name ASC
;

SELECT * from osc_physrisk_assets.generic_asset; -- NOTICE THESE ARE THE GENERIC ASSET COLUMNS AND ALL ASSETS ARE RETURNED
SELECT std_name, value_loan, value_ltv from osc_physrisk_assets.asset_realestate; -- NOTICE THE COLUMNS INCLUDE RE-SPECIFIC FIELDS AND ONLY RE ASSETS ARE RETURNED
SELECT std_name, production, capacity, availability_rate from osc_physrisk_assets.asset_powergeneratingutility; -- NOTICE THE COLUMNS INCLUDE UTILITY-SPECIFIC FIELDS AND ONLY UTILITY ASSETS ARE RETURNED

-- WE CAN ALSO DO A JOIN BY ASSET CLASS TO FILTER THE RESULTS
SELECT * from osc_physrisk_assets.generic_asset a INNER JOIN osc_physrisk_assets.asset_class b ON a.std_id = b.std_id
WHERE b.std_name LIKE '%Utility%'
; -- NOTICE ONLY UTILITY ROW IS RETURNED

-- QUERY PRECALCULATED DAMAGE CURVES AT A CERTAIN LOCATION
SELECT
	std_geo_h3_index, std_geo_h3_resolution, ST_X(std_geo_location_coordinates::geometry) as Long, ST_Y(std_geo_location_coordinates::geometry) as Lat, std_geo_overture_features, vulnerability_level, vulnerability_historically, vulnerability_data_raw
FROM
	osc_physrisk_vulnerability_analysis.geolocated_precalculated_vulnerability
WHERE std_geo_h3_index = '1234'
	;


