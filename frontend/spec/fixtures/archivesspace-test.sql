-- MySQL dump 10.13  Distrib 8.0.36, for Linux (x86_64)
--
-- Host: 127.0.0.1    Database: archivesspace
-- ------------------------------------------------------
-- Server version	8.0.35

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!50503 SET NAMES utf8mb4 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `accession`
--

DROP TABLE IF EXISTS `accession`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `accession` (
  `id` int NOT NULL AUTO_INCREMENT,
  `lock_version` int NOT NULL DEFAULT '0',
  `json_schema_version` int NOT NULL,
  `repo_id` int NOT NULL,
  `suppressed` int NOT NULL DEFAULT '0',
  `identifier` varchar(255) NOT NULL,
  `title` varchar(8704) DEFAULT NULL,
  `display_string` text,
  `publish` int DEFAULT NULL,
  `content_description` text,
  `condition_description` text,
  `disposition` text,
  `inventory` text,
  `provenance` text,
  `general_note` text,
  `resource_type_id` int DEFAULT NULL,
  `acquisition_type_id` int DEFAULT NULL,
  `accession_date` date DEFAULT NULL,
  `restrictions_apply` int DEFAULT NULL,
  `retention_rule` text,
  `access_restrictions` int DEFAULT NULL,
  `access_restrictions_note` text,
  `use_restrictions` int DEFAULT NULL,
  `use_restrictions_note` text,
  `created_by` varchar(255) DEFAULT NULL,
  `last_modified_by` varchar(255) DEFAULT NULL,
  `create_time` datetime NOT NULL,
  `system_mtime` datetime NOT NULL,
  `user_mtime` datetime NOT NULL,
  `slug` varchar(255) DEFAULT NULL,
  `is_slug_auto` int DEFAULT '0',
  `language_id` int DEFAULT NULL,
  `script_id` int DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `accession_unique_identifier` (`repo_id`,`identifier`),
  KEY `resource_type_id` (`resource_type_id`),
  KEY `acquisition_type_id` (`acquisition_type_id`),
  KEY `accession_system_mtime_index` (`system_mtime`),
  KEY `accession_user_mtime_index` (`user_mtime`),
  KEY `accession_suppressed_index` (`suppressed`),
  CONSTRAINT `accession_ibfk_1` FOREIGN KEY (`resource_type_id`) REFERENCES `enumeration_value` (`id`),
  CONSTRAINT `accession_ibfk_2` FOREIGN KEY (`acquisition_type_id`) REFERENCES `enumeration_value` (`id`),
  CONSTRAINT `accession_ibfk_3` FOREIGN KEY (`repo_id`) REFERENCES `repository` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `accession`
--

LOCK TABLES `accession` WRITE;
/*!40000 ALTER TABLE `accession` DISABLE KEYS */;
/*!40000 ALTER TABLE `accession` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `accession_component_links_rlshp`
--

DROP TABLE IF EXISTS `accession_component_links_rlshp`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `accession_component_links_rlshp` (
  `id` int NOT NULL AUTO_INCREMENT,
  `accession_id` int DEFAULT NULL,
  `archival_object_id` int DEFAULT NULL,
  `suppressed` int DEFAULT '0',
  `aspace_relationship_position` int DEFAULT NULL,
  `created_by` varchar(255) DEFAULT NULL,
  `last_modified_by` varchar(255) DEFAULT NULL,
  `system_mtime` datetime NOT NULL,
  `user_mtime` datetime NOT NULL,
  PRIMARY KEY (`id`),
  KEY `accession_component_links_rlshp_system_mtime_index` (`system_mtime`),
  KEY `accession_component_links_rlshp_user_mtime_index` (`user_mtime`),
  KEY `accession_id` (`accession_id`),
  KEY `archival_object_id` (`archival_object_id`),
  CONSTRAINT `accession_component_links_rlshp_ibfk_1` FOREIGN KEY (`accession_id`) REFERENCES `accession` (`id`),
  CONSTRAINT `accession_component_links_rlshp_ibfk_2` FOREIGN KEY (`archival_object_id`) REFERENCES `archival_object` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `accession_component_links_rlshp`
--

LOCK TABLES `accession_component_links_rlshp` WRITE;
/*!40000 ALTER TABLE `accession_component_links_rlshp` DISABLE KEYS */;
/*!40000 ALTER TABLE `accession_component_links_rlshp` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `active_edit`
--

DROP TABLE IF EXISTS `active_edit`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `active_edit` (
  `id` int NOT NULL AUTO_INCREMENT,
  `uri` varchar(255) NOT NULL,
  `operator` varchar(255) NOT NULL,
  `timestamp` datetime NOT NULL,
  PRIMARY KEY (`id`),
  KEY `active_edit_timestamp_index` (`timestamp`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `active_edit`
--

LOCK TABLES `active_edit` WRITE;
/*!40000 ALTER TABLE `active_edit` DISABLE KEYS */;
/*!40000 ALTER TABLE `active_edit` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `agent_alternate_set`
--

DROP TABLE IF EXISTS `agent_alternate_set`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `agent_alternate_set` (
  `id` int NOT NULL AUTO_INCREMENT,
  `file_version_xlink_actuate_attribute_id` int DEFAULT NULL,
  `file_version_xlink_show_attribute_id` int DEFAULT NULL,
  `set_component` varchar(255) DEFAULT NULL,
  `descriptive_note` text,
  `file_uri` varchar(255) DEFAULT NULL,
  `xlink_title_attribute` varchar(255) DEFAULT NULL,
  `xlink_role_attribute` varchar(255) DEFAULT NULL,
  `xlink_arcrole_attribute` varchar(255) DEFAULT NULL,
  `last_verified_date` datetime DEFAULT NULL,
  `agent_person_id` int DEFAULT NULL,
  `agent_family_id` int DEFAULT NULL,
  `agent_corporate_entity_id` int DEFAULT NULL,
  `agent_software_id` int DEFAULT NULL,
  `created_by` varchar(255) DEFAULT NULL,
  `last_modified_by` varchar(255) DEFAULT NULL,
  `create_time` datetime NOT NULL,
  `system_mtime` datetime NOT NULL,
  `user_mtime` datetime NOT NULL,
  `lock_version` int NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`),
  KEY `agent_alternate_set_system_mtime_index` (`system_mtime`),
  KEY `agent_alternate_set_user_mtime_index` (`user_mtime`),
  KEY `agent_person_id` (`agent_person_id`),
  KEY `agent_family_id` (`agent_family_id`),
  KEY `agent_corporate_entity_id` (`agent_corporate_entity_id`),
  KEY `agent_software_id` (`agent_software_id`),
  CONSTRAINT `agent_alternate_set_ibfk_1` FOREIGN KEY (`agent_person_id`) REFERENCES `agent_person` (`id`),
  CONSTRAINT `agent_alternate_set_ibfk_2` FOREIGN KEY (`agent_family_id`) REFERENCES `agent_family` (`id`),
  CONSTRAINT `agent_alternate_set_ibfk_3` FOREIGN KEY (`agent_corporate_entity_id`) REFERENCES `agent_corporate_entity` (`id`),
  CONSTRAINT `agent_alternate_set_ibfk_4` FOREIGN KEY (`agent_software_id`) REFERENCES `agent_software` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `agent_alternate_set`
--

LOCK TABLES `agent_alternate_set` WRITE;
/*!40000 ALTER TABLE `agent_alternate_set` DISABLE KEYS */;
/*!40000 ALTER TABLE `agent_alternate_set` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `agent_contact`
--

DROP TABLE IF EXISTS `agent_contact`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `agent_contact` (
  `id` int NOT NULL AUTO_INCREMENT,
  `lock_version` int NOT NULL DEFAULT '0',
  `json_schema_version` int NOT NULL,
  `agent_person_id` int DEFAULT NULL,
  `agent_family_id` int DEFAULT NULL,
  `agent_corporate_entity_id` int DEFAULT NULL,
  `agent_software_id` int DEFAULT NULL,
  `name` text NOT NULL,
  `salutation_id` int DEFAULT NULL,
  `address_1` text,
  `address_2` text,
  `address_3` text,
  `city` text,
  `region` text,
  `country` text,
  `post_code` text,
  `email` text,
  `email_signature` text,
  `created_by` varchar(255) DEFAULT NULL,
  `last_modified_by` varchar(255) DEFAULT NULL,
  `create_time` datetime NOT NULL,
  `system_mtime` datetime NOT NULL,
  `user_mtime` datetime NOT NULL,
  `is_representative` int DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `agent_person_one_representative_contact` (`is_representative`,`agent_person_id`),
  UNIQUE KEY `agent_corporate_entity_one_representative_contact` (`is_representative`,`agent_corporate_entity_id`),
  UNIQUE KEY `agent_family_one_representative_contact` (`is_representative`,`agent_family_id`),
  UNIQUE KEY `agent_software_one_representative_contact` (`is_representative`,`agent_software_id`),
  KEY `salutation_id` (`salutation_id`),
  KEY `agent_contact_system_mtime_index` (`system_mtime`),
  KEY `agent_contact_user_mtime_index` (`user_mtime`),
  KEY `agent_person_id` (`agent_person_id`),
  KEY `agent_family_id` (`agent_family_id`),
  KEY `agent_corporate_entity_id` (`agent_corporate_entity_id`),
  KEY `agent_software_id` (`agent_software_id`),
  CONSTRAINT `agent_contact_ibfk_1` FOREIGN KEY (`salutation_id`) REFERENCES `enumeration_value` (`id`),
  CONSTRAINT `agent_contact_ibfk_2` FOREIGN KEY (`agent_person_id`) REFERENCES `agent_person` (`id`),
  CONSTRAINT `agent_contact_ibfk_3` FOREIGN KEY (`agent_family_id`) REFERENCES `agent_family` (`id`),
  CONSTRAINT `agent_contact_ibfk_4` FOREIGN KEY (`agent_corporate_entity_id`) REFERENCES `agent_corporate_entity` (`id`),
  CONSTRAINT `agent_contact_ibfk_5` FOREIGN KEY (`agent_software_id`) REFERENCES `agent_software` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `agent_contact`
--

LOCK TABLES `agent_contact` WRITE;
/*!40000 ALTER TABLE `agent_contact` DISABLE KEYS */;
/*!40000 ALTER TABLE `agent_contact` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `agent_conventions_declaration`
--

DROP TABLE IF EXISTS `agent_conventions_declaration`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `agent_conventions_declaration` (
  `id` int NOT NULL AUTO_INCREMENT,
  `name_rule_id` int DEFAULT NULL,
  `file_version_xlink_actuate_attribute_id` int DEFAULT NULL,
  `file_version_xlink_show_attribute_id` int DEFAULT NULL,
  `citation` varchar(255) DEFAULT NULL,
  `descriptive_note` text NOT NULL,
  `file_uri` varchar(255) DEFAULT NULL,
  `xlink_title_attribute` varchar(255) DEFAULT NULL,
  `xlink_role_attribute` varchar(255) DEFAULT NULL,
  `xlink_arcrole_attribute` varchar(255) DEFAULT NULL,
  `last_verified_date` datetime DEFAULT NULL,
  `agent_person_id` int DEFAULT NULL,
  `agent_family_id` int DEFAULT NULL,
  `agent_corporate_entity_id` int DEFAULT NULL,
  `agent_software_id` int DEFAULT NULL,
  `created_by` varchar(255) DEFAULT NULL,
  `last_modified_by` varchar(255) DEFAULT NULL,
  `create_time` datetime NOT NULL,
  `system_mtime` datetime NOT NULL,
  `user_mtime` datetime NOT NULL,
  `lock_version` int NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`),
  KEY `agent_conventions_declaration_system_mtime_index` (`system_mtime`),
  KEY `agent_conventions_declaration_user_mtime_index` (`user_mtime`),
  KEY `agent_person_id` (`agent_person_id`),
  KEY `agent_family_id` (`agent_family_id`),
  KEY `agent_corporate_entity_id` (`agent_corporate_entity_id`),
  KEY `agent_software_id` (`agent_software_id`),
  CONSTRAINT `agent_conventions_declaration_ibfk_1` FOREIGN KEY (`agent_person_id`) REFERENCES `agent_person` (`id`),
  CONSTRAINT `agent_conventions_declaration_ibfk_2` FOREIGN KEY (`agent_family_id`) REFERENCES `agent_family` (`id`),
  CONSTRAINT `agent_conventions_declaration_ibfk_3` FOREIGN KEY (`agent_corporate_entity_id`) REFERENCES `agent_corporate_entity` (`id`),
  CONSTRAINT `agent_conventions_declaration_ibfk_4` FOREIGN KEY (`agent_software_id`) REFERENCES `agent_software` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `agent_conventions_declaration`
--

LOCK TABLES `agent_conventions_declaration` WRITE;
/*!40000 ALTER TABLE `agent_conventions_declaration` DISABLE KEYS */;
/*!40000 ALTER TABLE `agent_conventions_declaration` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `agent_corporate_entity`
--

DROP TABLE IF EXISTS `agent_corporate_entity`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `agent_corporate_entity` (
  `id` int NOT NULL AUTO_INCREMENT,
  `lock_version` int NOT NULL DEFAULT '0',
  `json_schema_version` int NOT NULL,
  `publish` int DEFAULT NULL,
  `created_by` varchar(255) DEFAULT NULL,
  `last_modified_by` varchar(255) DEFAULT NULL,
  `create_time` datetime NOT NULL,
  `system_mtime` datetime NOT NULL,
  `user_mtime` datetime NOT NULL,
  `agent_sha1` varchar(255) NOT NULL,
  `slug` varchar(255) DEFAULT NULL,
  `is_slug_auto` int DEFAULT '0',
  PRIMARY KEY (`id`),
  UNIQUE KEY `sha1_agent_corporate_entity` (`agent_sha1`),
  KEY `agent_corporate_entity_system_mtime_index` (`system_mtime`),
  KEY `agent_corporate_entity_user_mtime_index` (`user_mtime`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `agent_corporate_entity`
--

LOCK TABLES `agent_corporate_entity` WRITE;
/*!40000 ALTER TABLE `agent_corporate_entity` DISABLE KEYS */;
/*!40000 ALTER TABLE `agent_corporate_entity` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `agent_family`
--

DROP TABLE IF EXISTS `agent_family`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `agent_family` (
  `id` int NOT NULL AUTO_INCREMENT,
  `lock_version` int NOT NULL DEFAULT '0',
  `json_schema_version` int NOT NULL,
  `publish` int DEFAULT NULL,
  `created_by` varchar(255) DEFAULT NULL,
  `last_modified_by` varchar(255) DEFAULT NULL,
  `create_time` datetime NOT NULL,
  `system_mtime` datetime NOT NULL,
  `user_mtime` datetime NOT NULL,
  `agent_sha1` varchar(255) NOT NULL,
  `slug` varchar(255) DEFAULT NULL,
  `is_slug_auto` int DEFAULT '0',
  PRIMARY KEY (`id`),
  UNIQUE KEY `sha1_agent_family` (`agent_sha1`),
  KEY `agent_family_system_mtime_index` (`system_mtime`),
  KEY `agent_family_user_mtime_index` (`user_mtime`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `agent_family`
--

LOCK TABLES `agent_family` WRITE;
/*!40000 ALTER TABLE `agent_family` DISABLE KEYS */;
/*!40000 ALTER TABLE `agent_family` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `agent_function`
--

DROP TABLE IF EXISTS `agent_function`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `agent_function` (
  `id` int NOT NULL AUTO_INCREMENT,
  `agent_person_id` int DEFAULT NULL,
  `agent_family_id` int DEFAULT NULL,
  `agent_corporate_entity_id` int DEFAULT NULL,
  `agent_software_id` int DEFAULT NULL,
  `publish` int DEFAULT NULL,
  `suppressed` int DEFAULT NULL,
  `created_by` varchar(255) DEFAULT NULL,
  `last_modified_by` varchar(255) DEFAULT NULL,
  `create_time` datetime NOT NULL,
  `system_mtime` datetime NOT NULL,
  `user_mtime` datetime NOT NULL,
  `lock_version` int NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`),
  KEY `agent_function_system_mtime_index` (`system_mtime`),
  KEY `agent_function_user_mtime_index` (`user_mtime`),
  KEY `agent_person_id` (`agent_person_id`),
  KEY `agent_family_id` (`agent_family_id`),
  KEY `agent_corporate_entity_id` (`agent_corporate_entity_id`),
  KEY `agent_software_id` (`agent_software_id`),
  CONSTRAINT `agent_function_ibfk_1` FOREIGN KEY (`agent_person_id`) REFERENCES `agent_person` (`id`),
  CONSTRAINT `agent_function_ibfk_2` FOREIGN KEY (`agent_family_id`) REFERENCES `agent_family` (`id`),
  CONSTRAINT `agent_function_ibfk_3` FOREIGN KEY (`agent_corporate_entity_id`) REFERENCES `agent_corporate_entity` (`id`),
  CONSTRAINT `agent_function_ibfk_4` FOREIGN KEY (`agent_software_id`) REFERENCES `agent_software` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `agent_function`
--

LOCK TABLES `agent_function` WRITE;
/*!40000 ALTER TABLE `agent_function` DISABLE KEYS */;
/*!40000 ALTER TABLE `agent_function` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `agent_gender`
--

DROP TABLE IF EXISTS `agent_gender`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `agent_gender` (
  `id` int NOT NULL AUTO_INCREMENT,
  `gender_id` int NOT NULL,
  `agent_person_id` int DEFAULT NULL,
  `created_by` varchar(255) DEFAULT NULL,
  `last_modified_by` varchar(255) DEFAULT NULL,
  `create_time` datetime NOT NULL,
  `system_mtime` datetime NOT NULL,
  `user_mtime` datetime NOT NULL,
  `lock_version` int NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`),
  KEY `agent_gender_system_mtime_index` (`system_mtime`),
  KEY `agent_gender_user_mtime_index` (`user_mtime`),
  KEY `agent_person_id` (`agent_person_id`),
  CONSTRAINT `agent_gender_ibfk_1` FOREIGN KEY (`agent_person_id`) REFERENCES `agent_person` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `agent_gender`
--

LOCK TABLES `agent_gender` WRITE;
/*!40000 ALTER TABLE `agent_gender` DISABLE KEYS */;
/*!40000 ALTER TABLE `agent_gender` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `agent_identifier`
--

DROP TABLE IF EXISTS `agent_identifier`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `agent_identifier` (
  `id` int NOT NULL AUTO_INCREMENT,
  `identifier_type_id` int DEFAULT NULL,
  `entity_identifier` varchar(255) NOT NULL,
  `agent_person_id` int DEFAULT NULL,
  `agent_family_id` int DEFAULT NULL,
  `agent_corporate_entity_id` int DEFAULT NULL,
  `agent_software_id` int DEFAULT NULL,
  `created_by` varchar(255) DEFAULT NULL,
  `last_modified_by` varchar(255) DEFAULT NULL,
  `create_time` datetime NOT NULL,
  `system_mtime` datetime NOT NULL,
  `user_mtime` datetime NOT NULL,
  `lock_version` int NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`),
  KEY `agent_identifier_system_mtime_index` (`system_mtime`),
  KEY `agent_identifier_user_mtime_index` (`user_mtime`),
  KEY `agent_person_id` (`agent_person_id`),
  KEY `agent_family_id` (`agent_family_id`),
  KEY `agent_corporate_entity_id` (`agent_corporate_entity_id`),
  KEY `agent_software_id` (`agent_software_id`),
  CONSTRAINT `agent_identifier_ibfk_1` FOREIGN KEY (`agent_person_id`) REFERENCES `agent_person` (`id`),
  CONSTRAINT `agent_identifier_ibfk_2` FOREIGN KEY (`agent_family_id`) REFERENCES `agent_family` (`id`),
  CONSTRAINT `agent_identifier_ibfk_3` FOREIGN KEY (`agent_corporate_entity_id`) REFERENCES `agent_corporate_entity` (`id`),
  CONSTRAINT `agent_identifier_ibfk_4` FOREIGN KEY (`agent_software_id`) REFERENCES `agent_software` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `agent_identifier`
--

LOCK TABLES `agent_identifier` WRITE;
/*!40000 ALTER TABLE `agent_identifier` DISABLE KEYS */;
/*!40000 ALTER TABLE `agent_identifier` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `agent_maintenance_history`
--

DROP TABLE IF EXISTS `agent_maintenance_history`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `agent_maintenance_history` (
  `id` int NOT NULL AUTO_INCREMENT,
  `maintenance_event_type_id` int NOT NULL,
  `maintenance_agent_type_id` int NOT NULL,
  `event_date` datetime NOT NULL,
  `agent` varchar(255) NOT NULL,
  `descriptive_note` text NOT NULL,
  `agent_person_id` int DEFAULT NULL,
  `agent_family_id` int DEFAULT NULL,
  `agent_corporate_entity_id` int DEFAULT NULL,
  `agent_software_id` int DEFAULT NULL,
  `created_by` varchar(255) DEFAULT NULL,
  `last_modified_by` varchar(255) DEFAULT NULL,
  `create_time` datetime NOT NULL,
  `system_mtime` datetime NOT NULL,
  `user_mtime` datetime NOT NULL,
  `lock_version` int NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`),
  KEY `agent_maintenance_history_system_mtime_index` (`system_mtime`),
  KEY `agent_maintenance_history_user_mtime_index` (`user_mtime`),
  KEY `agent_person_id` (`agent_person_id`),
  KEY `agent_family_id` (`agent_family_id`),
  KEY `agent_corporate_entity_id` (`agent_corporate_entity_id`),
  KEY `agent_software_id` (`agent_software_id`),
  CONSTRAINT `agent_maintenance_history_ibfk_1` FOREIGN KEY (`agent_person_id`) REFERENCES `agent_person` (`id`),
  CONSTRAINT `agent_maintenance_history_ibfk_2` FOREIGN KEY (`agent_family_id`) REFERENCES `agent_family` (`id`),
  CONSTRAINT `agent_maintenance_history_ibfk_3` FOREIGN KEY (`agent_corporate_entity_id`) REFERENCES `agent_corporate_entity` (`id`),
  CONSTRAINT `agent_maintenance_history_ibfk_4` FOREIGN KEY (`agent_software_id`) REFERENCES `agent_software` (`id`),
  CONSTRAINT `agent_maintenance_history_ibfk_5` FOREIGN KEY (`agent_person_id`) REFERENCES `agent_person` (`id`),
  CONSTRAINT `agent_maintenance_history_ibfk_6` FOREIGN KEY (`agent_family_id`) REFERENCES `agent_family` (`id`),
  CONSTRAINT `agent_maintenance_history_ibfk_7` FOREIGN KEY (`agent_corporate_entity_id`) REFERENCES `agent_corporate_entity` (`id`),
  CONSTRAINT `agent_maintenance_history_ibfk_8` FOREIGN KEY (`agent_software_id`) REFERENCES `agent_software` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `agent_maintenance_history`
--

LOCK TABLES `agent_maintenance_history` WRITE;
/*!40000 ALTER TABLE `agent_maintenance_history` DISABLE KEYS */;
/*!40000 ALTER TABLE `agent_maintenance_history` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `agent_occupation`
--

DROP TABLE IF EXISTS `agent_occupation`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `agent_occupation` (
  `id` int NOT NULL AUTO_INCREMENT,
  `agent_person_id` int DEFAULT NULL,
  `agent_family_id` int DEFAULT NULL,
  `agent_corporate_entity_id` int DEFAULT NULL,
  `agent_software_id` int DEFAULT NULL,
  `publish` int DEFAULT NULL,
  `suppressed` int DEFAULT NULL,
  `created_by` varchar(255) DEFAULT NULL,
  `last_modified_by` varchar(255) DEFAULT NULL,
  `create_time` datetime NOT NULL,
  `system_mtime` datetime NOT NULL,
  `user_mtime` datetime NOT NULL,
  `lock_version` int NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`),
  KEY `agent_occupation_system_mtime_index` (`system_mtime`),
  KEY `agent_occupation_user_mtime_index` (`user_mtime`),
  KEY `agent_person_id` (`agent_person_id`),
  KEY `agent_family_id` (`agent_family_id`),
  KEY `agent_corporate_entity_id` (`agent_corporate_entity_id`),
  KEY `agent_software_id` (`agent_software_id`),
  CONSTRAINT `agent_occupation_ibfk_1` FOREIGN KEY (`agent_person_id`) REFERENCES `agent_person` (`id`),
  CONSTRAINT `agent_occupation_ibfk_2` FOREIGN KEY (`agent_family_id`) REFERENCES `agent_family` (`id`),
  CONSTRAINT `agent_occupation_ibfk_3` FOREIGN KEY (`agent_corporate_entity_id`) REFERENCES `agent_corporate_entity` (`id`),
  CONSTRAINT `agent_occupation_ibfk_4` FOREIGN KEY (`agent_software_id`) REFERENCES `agent_software` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `agent_occupation`
--

LOCK TABLES `agent_occupation` WRITE;
/*!40000 ALTER TABLE `agent_occupation` DISABLE KEYS */;
/*!40000 ALTER TABLE `agent_occupation` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `agent_other_agency_codes`
--

DROP TABLE IF EXISTS `agent_other_agency_codes`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `agent_other_agency_codes` (
  `id` int NOT NULL AUTO_INCREMENT,
  `agency_code_type_id` int DEFAULT NULL,
  `maintenance_agency` varchar(255) NOT NULL,
  `agent_person_id` int DEFAULT NULL,
  `agent_family_id` int DEFAULT NULL,
  `agent_corporate_entity_id` int DEFAULT NULL,
  `agent_software_id` int DEFAULT NULL,
  `created_by` varchar(255) DEFAULT NULL,
  `last_modified_by` varchar(255) DEFAULT NULL,
  `create_time` datetime NOT NULL,
  `system_mtime` datetime NOT NULL,
  `user_mtime` datetime NOT NULL,
  `lock_version` int NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`),
  KEY `agent_other_agency_codes_system_mtime_index` (`system_mtime`),
  KEY `agent_other_agency_codes_user_mtime_index` (`user_mtime`),
  KEY `agent_person_id` (`agent_person_id`),
  KEY `agent_family_id` (`agent_family_id`),
  KEY `agent_corporate_entity_id` (`agent_corporate_entity_id`),
  KEY `agent_software_id` (`agent_software_id`),
  CONSTRAINT `agent_other_agency_codes_ibfk_1` FOREIGN KEY (`agent_person_id`) REFERENCES `agent_person` (`id`),
  CONSTRAINT `agent_other_agency_codes_ibfk_2` FOREIGN KEY (`agent_family_id`) REFERENCES `agent_family` (`id`),
  CONSTRAINT `agent_other_agency_codes_ibfk_3` FOREIGN KEY (`agent_corporate_entity_id`) REFERENCES `agent_corporate_entity` (`id`),
  CONSTRAINT `agent_other_agency_codes_ibfk_4` FOREIGN KEY (`agent_software_id`) REFERENCES `agent_software` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `agent_other_agency_codes`
--

LOCK TABLES `agent_other_agency_codes` WRITE;
/*!40000 ALTER TABLE `agent_other_agency_codes` DISABLE KEYS */;
/*!40000 ALTER TABLE `agent_other_agency_codes` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `agent_person`
--

DROP TABLE IF EXISTS `agent_person`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `agent_person` (
  `id` int NOT NULL AUTO_INCREMENT,
  `lock_version` int NOT NULL DEFAULT '0',
  `json_schema_version` int NOT NULL,
  `publish` int DEFAULT NULL,
  `created_by` varchar(255) DEFAULT NULL,
  `last_modified_by` varchar(255) DEFAULT NULL,
  `create_time` datetime NOT NULL,
  `system_mtime` datetime NOT NULL,
  `user_mtime` datetime NOT NULL,
  `agent_sha1` varchar(255) NOT NULL,
  `slug` varchar(255) DEFAULT NULL,
  `is_slug_auto` int DEFAULT '0',
  PRIMARY KEY (`id`),
  UNIQUE KEY `sha1_agent_person` (`agent_sha1`),
  KEY `agent_person_system_mtime_index` (`system_mtime`),
  KEY `agent_person_user_mtime_index` (`user_mtime`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `agent_person`
--

LOCK TABLES `agent_person` WRITE;
/*!40000 ALTER TABLE `agent_person` DISABLE KEYS */;
/*!40000 ALTER TABLE `agent_person` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `agent_place`
--

DROP TABLE IF EXISTS `agent_place`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `agent_place` (
  `id` int NOT NULL AUTO_INCREMENT,
  `place_role_id` int DEFAULT NULL,
  `agent_person_id` int DEFAULT NULL,
  `agent_family_id` int DEFAULT NULL,
  `agent_corporate_entity_id` int DEFAULT NULL,
  `agent_software_id` int DEFAULT NULL,
  `publish` int DEFAULT NULL,
  `suppressed` int DEFAULT NULL,
  `created_by` varchar(255) DEFAULT NULL,
  `last_modified_by` varchar(255) DEFAULT NULL,
  `create_time` datetime NOT NULL,
  `system_mtime` datetime NOT NULL,
  `user_mtime` datetime NOT NULL,
  `lock_version` int NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`),
  KEY `agent_place_system_mtime_index` (`system_mtime`),
  KEY `agent_place_user_mtime_index` (`user_mtime`),
  KEY `agent_person_id` (`agent_person_id`),
  KEY `agent_family_id` (`agent_family_id`),
  KEY `agent_corporate_entity_id` (`agent_corporate_entity_id`),
  KEY `agent_software_id` (`agent_software_id`),
  CONSTRAINT `agent_place_ibfk_1` FOREIGN KEY (`agent_person_id`) REFERENCES `agent_person` (`id`),
  CONSTRAINT `agent_place_ibfk_2` FOREIGN KEY (`agent_family_id`) REFERENCES `agent_family` (`id`),
  CONSTRAINT `agent_place_ibfk_3` FOREIGN KEY (`agent_corporate_entity_id`) REFERENCES `agent_corporate_entity` (`id`),
  CONSTRAINT `agent_place_ibfk_4` FOREIGN KEY (`agent_software_id`) REFERENCES `agent_software` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `agent_place`
--

LOCK TABLES `agent_place` WRITE;
/*!40000 ALTER TABLE `agent_place` DISABLE KEYS */;
/*!40000 ALTER TABLE `agent_place` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `agent_record_control`
--

DROP TABLE IF EXISTS `agent_record_control`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `agent_record_control` (
  `id` int NOT NULL AUTO_INCREMENT,
  `maintenance_status_id` int NOT NULL,
  `publication_status_id` int DEFAULT NULL,
  `government_agency_type_id` int DEFAULT NULL,
  `reference_evaluation_id` int DEFAULT NULL,
  `name_type_id` int DEFAULT NULL,
  `level_of_detail_id` int DEFAULT NULL,
  `modified_record_id` int DEFAULT NULL,
  `cataloging_source_id` int DEFAULT NULL,
  `language_id` int DEFAULT NULL,
  `script_id` int DEFAULT NULL,
  `romanization_id` int DEFAULT NULL,
  `maintenance_agency` varchar(255) DEFAULT NULL,
  `agency_name` varchar(255) DEFAULT NULL,
  `maintenance_agency_note` text,
  `language_note` text,
  `agent_person_id` int DEFAULT NULL,
  `agent_family_id` int DEFAULT NULL,
  `agent_corporate_entity_id` int DEFAULT NULL,
  `agent_software_id` int DEFAULT NULL,
  `created_by` varchar(255) DEFAULT NULL,
  `last_modified_by` varchar(255) DEFAULT NULL,
  `create_time` datetime NOT NULL,
  `system_mtime` datetime NOT NULL,
  `user_mtime` datetime NOT NULL,
  `lock_version` int NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`),
  KEY `agent_record_control_system_mtime_index` (`system_mtime`),
  KEY `agent_record_control_user_mtime_index` (`user_mtime`),
  KEY `agent_person_id` (`agent_person_id`),
  KEY `agent_family_id` (`agent_family_id`),
  KEY `agent_corporate_entity_id` (`agent_corporate_entity_id`),
  KEY `agent_software_id` (`agent_software_id`),
  CONSTRAINT `agent_record_control_ibfk_1` FOREIGN KEY (`agent_person_id`) REFERENCES `agent_person` (`id`),
  CONSTRAINT `agent_record_control_ibfk_2` FOREIGN KEY (`agent_family_id`) REFERENCES `agent_family` (`id`),
  CONSTRAINT `agent_record_control_ibfk_3` FOREIGN KEY (`agent_corporate_entity_id`) REFERENCES `agent_corporate_entity` (`id`),
  CONSTRAINT `agent_record_control_ibfk_4` FOREIGN KEY (`agent_software_id`) REFERENCES `agent_software` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `agent_record_control`
--

LOCK TABLES `agent_record_control` WRITE;
/*!40000 ALTER TABLE `agent_record_control` DISABLE KEYS */;
/*!40000 ALTER TABLE `agent_record_control` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `agent_record_identifier`
--

DROP TABLE IF EXISTS `agent_record_identifier`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `agent_record_identifier` (
  `id` int NOT NULL AUTO_INCREMENT,
  `identifier_type_id` int DEFAULT NULL,
  `source_id` int NOT NULL,
  `primary_identifier` int NOT NULL,
  `record_identifier` varchar(255) NOT NULL,
  `agent_person_id` int DEFAULT NULL,
  `agent_family_id` int DEFAULT NULL,
  `agent_corporate_entity_id` int DEFAULT NULL,
  `agent_software_id` int DEFAULT NULL,
  `created_by` varchar(255) DEFAULT NULL,
  `last_modified_by` varchar(255) DEFAULT NULL,
  `create_time` datetime NOT NULL,
  `system_mtime` datetime NOT NULL,
  `user_mtime` datetime NOT NULL,
  `lock_version` int NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`),
  KEY `agent_record_identifier_system_mtime_index` (`system_mtime`),
  KEY `agent_record_identifier_user_mtime_index` (`user_mtime`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `agent_record_identifier`
--

LOCK TABLES `agent_record_identifier` WRITE;
/*!40000 ALTER TABLE `agent_record_identifier` DISABLE KEYS */;
/*!40000 ALTER TABLE `agent_record_identifier` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `agent_resource`
--

DROP TABLE IF EXISTS `agent_resource`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `agent_resource` (
  `id` int NOT NULL AUTO_INCREMENT,
  `linked_agent_role_id` int NOT NULL,
  `linked_resource` varchar(8704) NOT NULL,
  `linked_resource_description` text,
  `file_uri` varchar(255) DEFAULT NULL,
  `file_version_xlink_actuate_attribute_id` int DEFAULT NULL,
  `file_version_xlink_show_attribute_id` int DEFAULT NULL,
  `xlink_title_attribute` varchar(255) DEFAULT NULL,
  `xlink_role_attribute` varchar(255) DEFAULT NULL,
  `xlink_arcrole_attribute` varchar(255) DEFAULT NULL,
  `last_verified_date` datetime DEFAULT NULL,
  `agent_person_id` int DEFAULT NULL,
  `agent_family_id` int DEFAULT NULL,
  `agent_corporate_entity_id` int DEFAULT NULL,
  `agent_software_id` int DEFAULT NULL,
  `publish` int DEFAULT NULL,
  `suppressed` int DEFAULT NULL,
  `created_by` varchar(255) DEFAULT NULL,
  `last_modified_by` varchar(255) DEFAULT NULL,
  `create_time` datetime NOT NULL,
  `system_mtime` datetime NOT NULL,
  `user_mtime` datetime NOT NULL,
  `lock_version` int NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`),
  KEY `agent_resource_system_mtime_index` (`system_mtime`),
  KEY `agent_resource_user_mtime_index` (`user_mtime`),
  KEY `agent_person_id` (`agent_person_id`),
  KEY `agent_family_id` (`agent_family_id`),
  KEY `agent_corporate_entity_id` (`agent_corporate_entity_id`),
  KEY `agent_software_id` (`agent_software_id`),
  CONSTRAINT `agent_resource_ibfk_1` FOREIGN KEY (`agent_person_id`) REFERENCES `agent_person` (`id`),
  CONSTRAINT `agent_resource_ibfk_2` FOREIGN KEY (`agent_family_id`) REFERENCES `agent_family` (`id`),
  CONSTRAINT `agent_resource_ibfk_3` FOREIGN KEY (`agent_corporate_entity_id`) REFERENCES `agent_corporate_entity` (`id`),
  CONSTRAINT `agent_resource_ibfk_4` FOREIGN KEY (`agent_software_id`) REFERENCES `agent_software` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `agent_resource`
--

LOCK TABLES `agent_resource` WRITE;
/*!40000 ALTER TABLE `agent_resource` DISABLE KEYS */;
/*!40000 ALTER TABLE `agent_resource` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `agent_software`
--

DROP TABLE IF EXISTS `agent_software`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `agent_software` (
  `id` int NOT NULL AUTO_INCREMENT,
  `system_role` varchar(255) NOT NULL DEFAULT 'none',
  `lock_version` int NOT NULL DEFAULT '0',
  `json_schema_version` int NOT NULL,
  `publish` int DEFAULT NULL,
  `created_by` varchar(255) DEFAULT NULL,
  `last_modified_by` varchar(255) DEFAULT NULL,
  `create_time` datetime NOT NULL,
  `system_mtime` datetime NOT NULL,
  `user_mtime` datetime NOT NULL,
  `agent_sha1` varchar(255) NOT NULL,
  `slug` varchar(255) DEFAULT NULL,
  `is_slug_auto` int DEFAULT '0',
  PRIMARY KEY (`id`),
  UNIQUE KEY `sha1_agent_software` (`agent_sha1`),
  KEY `agent_software_system_role_index` (`system_role`),
  KEY `agent_software_system_mtime_index` (`system_mtime`),
  KEY `agent_software_user_mtime_index` (`user_mtime`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `agent_software`
--

LOCK TABLES `agent_software` WRITE;
/*!40000 ALTER TABLE `agent_software` DISABLE KEYS */;
/*!40000 ALTER TABLE `agent_software` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `agent_sources`
--

DROP TABLE IF EXISTS `agent_sources`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `agent_sources` (
  `id` int NOT NULL AUTO_INCREMENT,
  `source_entry` varchar(255) DEFAULT NULL,
  `descriptive_note` text,
  `file_uri` varchar(255) DEFAULT NULL,
  `file_version_xlink_actuate_attribute_id` int DEFAULT NULL,
  `file_version_xlink_show_attribute_id` int DEFAULT NULL,
  `xlink_title_attribute` varchar(255) DEFAULT NULL,
  `xlink_role_attribute` varchar(255) DEFAULT NULL,
  `xlink_arcrole_attribute` varchar(255) DEFAULT NULL,
  `last_verified_date` datetime DEFAULT NULL,
  `agent_person_id` int DEFAULT NULL,
  `agent_family_id` int DEFAULT NULL,
  `agent_corporate_entity_id` int DEFAULT NULL,
  `agent_software_id` int DEFAULT NULL,
  `created_by` varchar(255) DEFAULT NULL,
  `last_modified_by` varchar(255) DEFAULT NULL,
  `create_time` datetime NOT NULL,
  `system_mtime` datetime NOT NULL,
  `user_mtime` datetime NOT NULL,
  `lock_version` int NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`),
  KEY `agent_sources_system_mtime_index` (`system_mtime`),
  KEY `agent_sources_user_mtime_index` (`user_mtime`),
  KEY `agent_person_id` (`agent_person_id`),
  KEY `agent_family_id` (`agent_family_id`),
  KEY `agent_corporate_entity_id` (`agent_corporate_entity_id`),
  KEY `agent_software_id` (`agent_software_id`),
  CONSTRAINT `agent_sources_ibfk_1` FOREIGN KEY (`agent_person_id`) REFERENCES `agent_person` (`id`),
  CONSTRAINT `agent_sources_ibfk_2` FOREIGN KEY (`agent_family_id`) REFERENCES `agent_family` (`id`),
  CONSTRAINT `agent_sources_ibfk_3` FOREIGN KEY (`agent_corporate_entity_id`) REFERENCES `agent_corporate_entity` (`id`),
  CONSTRAINT `agent_sources_ibfk_4` FOREIGN KEY (`agent_software_id`) REFERENCES `agent_software` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `agent_sources`
--

LOCK TABLES `agent_sources` WRITE;
/*!40000 ALTER TABLE `agent_sources` DISABLE KEYS */;
/*!40000 ALTER TABLE `agent_sources` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `agent_topic`
--

DROP TABLE IF EXISTS `agent_topic`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `agent_topic` (
  `id` int NOT NULL AUTO_INCREMENT,
  `agent_person_id` int DEFAULT NULL,
  `agent_family_id` int DEFAULT NULL,
  `agent_corporate_entity_id` int DEFAULT NULL,
  `agent_software_id` int DEFAULT NULL,
  `publish` int DEFAULT NULL,
  `suppressed` int DEFAULT NULL,
  `created_by` varchar(255) DEFAULT NULL,
  `last_modified_by` varchar(255) DEFAULT NULL,
  `create_time` datetime NOT NULL,
  `system_mtime` datetime NOT NULL,
  `user_mtime` datetime NOT NULL,
  `lock_version` int NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`),
  KEY `agent_topic_system_mtime_index` (`system_mtime`),
  KEY `agent_topic_user_mtime_index` (`user_mtime`),
  KEY `agent_person_id` (`agent_person_id`),
  KEY `agent_family_id` (`agent_family_id`),
  KEY `agent_corporate_entity_id` (`agent_corporate_entity_id`),
  KEY `agent_software_id` (`agent_software_id`),
  CONSTRAINT `agent_topic_ibfk_1` FOREIGN KEY (`agent_person_id`) REFERENCES `agent_person` (`id`),
  CONSTRAINT `agent_topic_ibfk_2` FOREIGN KEY (`agent_family_id`) REFERENCES `agent_family` (`id`),
  CONSTRAINT `agent_topic_ibfk_3` FOREIGN KEY (`agent_corporate_entity_id`) REFERENCES `agent_corporate_entity` (`id`),
  CONSTRAINT `agent_topic_ibfk_4` FOREIGN KEY (`agent_software_id`) REFERENCES `agent_software` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `agent_topic`
--

LOCK TABLES `agent_topic` WRITE;
/*!40000 ALTER TABLE `agent_topic` DISABLE KEYS */;
/*!40000 ALTER TABLE `agent_topic` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `archival_object`
--

DROP TABLE IF EXISTS `archival_object`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `archival_object` (
  `id` int NOT NULL AUTO_INCREMENT,
  `lock_version` int NOT NULL DEFAULT '0',
  `json_schema_version` int NOT NULL,
  `repo_id` int NOT NULL,
  `root_record_id` int DEFAULT NULL,
  `parent_id` int DEFAULT NULL,
  `parent_name` varchar(255) DEFAULT NULL,
  `position` int NOT NULL,
  `publish` int NOT NULL DEFAULT '0',
  `ref_id` varchar(255) NOT NULL,
  `component_id` varchar(255) DEFAULT NULL,
  `title` varchar(8704) DEFAULT NULL,
  `display_string` text,
  `level_id` int NOT NULL,
  `other_level` varchar(255) DEFAULT NULL,
  `system_generated` int DEFAULT '0',
  `restrictions_apply` int DEFAULT NULL,
  `repository_processing_note` text,
  `created_by` varchar(255) DEFAULT NULL,
  `last_modified_by` varchar(255) DEFAULT NULL,
  `create_time` datetime NOT NULL,
  `system_mtime` datetime NOT NULL,
  `user_mtime` datetime NOT NULL,
  `suppressed` int NOT NULL DEFAULT '0',
  `slug` varchar(255) DEFAULT NULL,
  `is_slug_auto` int DEFAULT '0',
  PRIMARY KEY (`id`),
  UNIQUE KEY `ao_unique_refid` (`root_record_id`,`ref_id`),
  UNIQUE KEY `uniq_ao_pos` (`parent_name`,`position`),
  KEY `level_id` (`level_id`),
  KEY `archival_object_system_mtime_index` (`system_mtime`),
  KEY `archival_object_user_mtime_index` (`user_mtime`),
  KEY `repo_id` (`repo_id`),
  KEY `ao_parent_root_idx` (`parent_id`,`root_record_id`),
  KEY `archival_object_ref_id_index` (`ref_id`),
  KEY `archival_object_component_id_index` (`component_id`),
  CONSTRAINT `archival_object_ibfk_1` FOREIGN KEY (`level_id`) REFERENCES `enumeration_value` (`id`),
  CONSTRAINT `archival_object_ibfk_3` FOREIGN KEY (`repo_id`) REFERENCES `repository` (`id`),
  CONSTRAINT `archival_object_ibfk_4` FOREIGN KEY (`root_record_id`) REFERENCES `resource` (`id`),
  CONSTRAINT `archival_object_ibfk_5` FOREIGN KEY (`parent_id`) REFERENCES `archival_object` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `archival_object`
--

LOCK TABLES `archival_object` WRITE;
/*!40000 ALTER TABLE `archival_object` DISABLE KEYS */;
/*!40000 ALTER TABLE `archival_object` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `ark_name`
--

DROP TABLE IF EXISTS `ark_name`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `ark_name` (
  `id` int NOT NULL AUTO_INCREMENT,
  `archival_object_id` int DEFAULT NULL,
  `resource_id` int DEFAULT NULL,
  `created_by` varchar(255) DEFAULT NULL,
  `last_modified_by` varchar(255) DEFAULT NULL,
  `create_time` datetime DEFAULT NULL,
  `system_mtime` datetime DEFAULT NULL,
  `user_mtime` datetime DEFAULT NULL,
  `lock_version` int NOT NULL DEFAULT '0',
  `ark_value` varchar(255) NOT NULL,
  `is_current` int NOT NULL DEFAULT '0',
  `is_external_url` int DEFAULT '0',
  `retired_at_epoch_ms` bigint NOT NULL DEFAULT '0',
  `version_key` varchar(255) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `ark_name_ao_uniq` (`archival_object_id`,`is_current`,`retired_at_epoch_ms`),
  UNIQUE KEY `ark_name_resource_uniq` (`resource_id`,`is_current`,`retired_at_epoch_ms`),
  KEY `ark_name_archival_object_id_index` (`archival_object_id`),
  KEY `ark_name_resource_id_index` (`resource_id`),
  KEY `ark_name_ark_value_res_idx` (`ark_value`,`resource_id`),
  KEY `ark_name_ark_value_ao_idx` (`ark_value`,`archival_object_id`),
  CONSTRAINT `ark_name_ibfk_1` FOREIGN KEY (`resource_id`) REFERENCES `resource` (`id`),
  CONSTRAINT `ark_name_ibfk_2` FOREIGN KEY (`archival_object_id`) REFERENCES `archival_object` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `ark_name`
--

LOCK TABLES `ark_name` WRITE;
/*!40000 ALTER TABLE `ark_name` DISABLE KEYS */;
/*!40000 ALTER TABLE `ark_name` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `ark_uniq_check`
--

DROP TABLE IF EXISTS `ark_uniq_check`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `ark_uniq_check` (
  `id` int NOT NULL AUTO_INCREMENT,
  `record_uri` varchar(255) NOT NULL,
  `value` varchar(255) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `unique_ark_value` (`value`),
  KEY `record_uri_uniq_check_idx` (`record_uri`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `ark_uniq_check`
--

LOCK TABLES `ark_uniq_check` WRITE;
/*!40000 ALTER TABLE `ark_uniq_check` DISABLE KEYS */;
/*!40000 ALTER TABLE `ark_uniq_check` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `assessment`
--

DROP TABLE IF EXISTS `assessment`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `assessment` (
  `id` int NOT NULL AUTO_INCREMENT,
  `lock_version` int NOT NULL DEFAULT '0',
  `json_schema_version` int NOT NULL,
  `repo_id` int NOT NULL,
  `accession_report` int NOT NULL DEFAULT '0',
  `appraisal` int NOT NULL DEFAULT '0',
  `container_list` int NOT NULL DEFAULT '0',
  `catalog_record` int NOT NULL DEFAULT '0',
  `control_file` int NOT NULL DEFAULT '0',
  `finding_aid_ead` int NOT NULL DEFAULT '0',
  `finding_aid_paper` int NOT NULL DEFAULT '0',
  `finding_aid_word` int NOT NULL DEFAULT '0',
  `finding_aid_spreadsheet` int NOT NULL DEFAULT '0',
  `surveyed_duration` varchar(255) DEFAULT NULL,
  `surveyed_extent` text,
  `review_required` int NOT NULL DEFAULT '0',
  `purpose` text,
  `scope` text,
  `sensitive_material` int NOT NULL DEFAULT '0',
  `general_assessment_note` text,
  `special_format_note` text,
  `exhibition_value_note` text,
  `deed_of_gift` int DEFAULT NULL,
  `finding_aid_online` int DEFAULT NULL,
  `related_eac_records` int DEFAULT NULL,
  `existing_description_notes` text,
  `survey_begin` date NOT NULL DEFAULT '1970-01-01',
  `survey_end` date DEFAULT NULL,
  `review_note` text,
  `inactive` int DEFAULT NULL,
  `monetary_value` decimal(16,2) DEFAULT NULL,
  `monetary_value_note` text,
  `conservation_note` text,
  `created_by` varchar(255) DEFAULT NULL,
  `last_modified_by` varchar(255) DEFAULT NULL,
  `create_time` datetime NOT NULL,
  `system_mtime` datetime NOT NULL,
  `user_mtime` datetime NOT NULL,
  PRIMARY KEY (`id`),
  KEY `assessment_system_mtime_index` (`system_mtime`),
  KEY `assessment_user_mtime_index` (`user_mtime`),
  KEY `repo_id` (`repo_id`),
  CONSTRAINT `assessment_ibfk_1` FOREIGN KEY (`repo_id`) REFERENCES `repository` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `assessment`
--

LOCK TABLES `assessment` WRITE;
/*!40000 ALTER TABLE `assessment` DISABLE KEYS */;
/*!40000 ALTER TABLE `assessment` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `assessment_attribute`
--

DROP TABLE IF EXISTS `assessment_attribute`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `assessment_attribute` (
  `id` int NOT NULL AUTO_INCREMENT,
  `assessment_id` int NOT NULL,
  `assessment_attribute_definition_id` int NOT NULL,
  `value` varchar(255) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `assessment_id` (`assessment_id`),
  KEY `assessment_attribute_definition_id` (`assessment_attribute_definition_id`),
  CONSTRAINT `assessment_attribute_ibfk_1` FOREIGN KEY (`assessment_id`) REFERENCES `assessment` (`id`),
  CONSTRAINT `assessment_attribute_ibfk_2` FOREIGN KEY (`assessment_attribute_definition_id`) REFERENCES `assessment_attribute_definition` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `assessment_attribute`
--

LOCK TABLES `assessment_attribute` WRITE;
/*!40000 ALTER TABLE `assessment_attribute` DISABLE KEYS */;
/*!40000 ALTER TABLE `assessment_attribute` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `assessment_attribute_definition`
--

DROP TABLE IF EXISTS `assessment_attribute_definition`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `assessment_attribute_definition` (
  `id` int NOT NULL AUTO_INCREMENT,
  `repo_id` int NOT NULL,
  `label` varchar(255) NOT NULL,
  `type` varchar(255) NOT NULL,
  `position` int NOT NULL,
  `readonly` int NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`),
  UNIQUE KEY `assessment_attr_unique_label` (`repo_id`,`type`,`label`)
) ENGINE=InnoDB AUTO_INCREMENT=34 DEFAULT CHARSET=utf8mb3;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `assessment_attribute_definition`
--

LOCK TABLES `assessment_attribute_definition` WRITE;
/*!40000 ALTER TABLE `assessment_attribute_definition` DISABLE KEYS */;
INSERT INTO `assessment_attribute_definition` VALUES (1,1,'Reformatting Readiness','rating',0,0),(2,1,'Housing Quality','rating',1,0),(3,1,'Physical Condition','rating',2,0),(4,1,'Physical Access (arrangement)','rating',3,0),(5,1,'Intellectual Access (description)','rating',4,0),(6,1,'Interest','rating',5,0),(7,1,'Documentation Quality','rating',6,0),(8,1,'Research Value','rating',7,1),(9,1,'Architectural Materials','format',7,0),(10,1,'Art Originals','format',8,0),(11,1,'Artifacts','format',9,0),(12,1,'Audio Materials','format',10,0),(13,1,'Biological Specimens','format',11,0),(14,1,'Botanical Specimens','format',12,0),(15,1,'Computer Storage Units','format',13,0),(16,1,'Film (negative, slide, or motion picture)','format',14,0),(17,1,'Glass','format',15,0),(18,1,'Photographs','format',16,0),(19,1,'Scrapbooks','format',17,0),(20,1,'Technical Drawings & Schematics','format',18,0),(21,1,'Textiles','format',19,0),(22,1,'Vellum & Parchment','format',20,0),(23,1,'Video Materials','format',21,0),(24,1,'Other','format',22,0),(25,1,'Potential Mold or Mold Damage','conservation_issue',23,0),(26,1,'Recent Pest Damage','conservation_issue',24,0),(27,1,'Deteriorating Film Base','conservation_issue',25,0),(28,1,'Brittle Paper','conservation_issue',26,0),(29,1,'Metal Fasteners','conservation_issue',27,0),(30,1,'Newspaper','conservation_issue',28,0),(31,1,'Tape','conservation_issue',29,0),(32,1,'Heat-Sensitive Paper','conservation_issue',30,0),(33,1,'Water Damage','conservation_issue',31,0);
/*!40000 ALTER TABLE `assessment_attribute_definition` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `assessment_attribute_note`
--

DROP TABLE IF EXISTS `assessment_attribute_note`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `assessment_attribute_note` (
  `id` int NOT NULL AUTO_INCREMENT,
  `assessment_id` int NOT NULL,
  `assessment_attribute_definition_id` int NOT NULL,
  `note` text NOT NULL,
  PRIMARY KEY (`id`),
  KEY `assessment_id` (`assessment_id`),
  KEY `assessment_attribute_definition_id` (`assessment_attribute_definition_id`),
  CONSTRAINT `assessment_attribute_note_ibfk_1` FOREIGN KEY (`assessment_id`) REFERENCES `assessment` (`id`),
  CONSTRAINT `assessment_attribute_note_ibfk_2` FOREIGN KEY (`assessment_attribute_definition_id`) REFERENCES `assessment_attribute_definition` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `assessment_attribute_note`
--

LOCK TABLES `assessment_attribute_note` WRITE;
/*!40000 ALTER TABLE `assessment_attribute_note` DISABLE KEYS */;
/*!40000 ALTER TABLE `assessment_attribute_note` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `assessment_reviewer_rlshp`
--

DROP TABLE IF EXISTS `assessment_reviewer_rlshp`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `assessment_reviewer_rlshp` (
  `id` int NOT NULL AUTO_INCREMENT,
  `assessment_id` int NOT NULL,
  `agent_person_id` int DEFAULT NULL,
  `aspace_relationship_position` int DEFAULT NULL,
  `suppressed` int NOT NULL DEFAULT '0',
  `created_by` varchar(255) DEFAULT NULL,
  `last_modified_by` varchar(255) DEFAULT NULL,
  `system_mtime` datetime NOT NULL,
  `user_mtime` datetime NOT NULL,
  PRIMARY KEY (`id`),
  KEY `assessment_reviewer_rlshp_system_mtime_index` (`system_mtime`),
  KEY `assessment_reviewer_rlshp_user_mtime_index` (`user_mtime`),
  KEY `assessment_id` (`assessment_id`),
  KEY `agent_person_id` (`agent_person_id`),
  CONSTRAINT `assessment_reviewer_rlshp_ibfk_1` FOREIGN KEY (`assessment_id`) REFERENCES `assessment` (`id`),
  CONSTRAINT `assessment_reviewer_rlshp_ibfk_2` FOREIGN KEY (`agent_person_id`) REFERENCES `agent_person` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `assessment_reviewer_rlshp`
--

LOCK TABLES `assessment_reviewer_rlshp` WRITE;
/*!40000 ALTER TABLE `assessment_reviewer_rlshp` DISABLE KEYS */;
/*!40000 ALTER TABLE `assessment_reviewer_rlshp` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `assessment_rlshp`
--

DROP TABLE IF EXISTS `assessment_rlshp`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `assessment_rlshp` (
  `id` int NOT NULL AUTO_INCREMENT,
  `assessment_id` int NOT NULL,
  `accession_id` int DEFAULT NULL,
  `resource_id` int DEFAULT NULL,
  `archival_object_id` int DEFAULT NULL,
  `digital_object_id` int DEFAULT NULL,
  `aspace_relationship_position` int DEFAULT NULL,
  `suppressed` int NOT NULL DEFAULT '0',
  `created_by` varchar(255) DEFAULT NULL,
  `last_modified_by` varchar(255) DEFAULT NULL,
  `system_mtime` datetime NOT NULL,
  `user_mtime` datetime NOT NULL,
  PRIMARY KEY (`id`),
  KEY `assessment_rlshp_system_mtime_index` (`system_mtime`),
  KEY `assessment_rlshp_user_mtime_index` (`user_mtime`),
  KEY `assessment_id` (`assessment_id`),
  KEY `accession_id` (`accession_id`),
  KEY `resource_id` (`resource_id`),
  KEY `archival_object_id` (`archival_object_id`),
  KEY `digital_object_id` (`digital_object_id`),
  CONSTRAINT `assessment_rlshp_ibfk_1` FOREIGN KEY (`assessment_id`) REFERENCES `assessment` (`id`),
  CONSTRAINT `assessment_rlshp_ibfk_2` FOREIGN KEY (`accession_id`) REFERENCES `accession` (`id`),
  CONSTRAINT `assessment_rlshp_ibfk_3` FOREIGN KEY (`resource_id`) REFERENCES `resource` (`id`),
  CONSTRAINT `assessment_rlshp_ibfk_4` FOREIGN KEY (`archival_object_id`) REFERENCES `archival_object` (`id`),
  CONSTRAINT `assessment_rlshp_ibfk_5` FOREIGN KEY (`digital_object_id`) REFERENCES `digital_object` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `assessment_rlshp`
--

LOCK TABLES `assessment_rlshp` WRITE;
/*!40000 ALTER TABLE `assessment_rlshp` DISABLE KEYS */;
/*!40000 ALTER TABLE `assessment_rlshp` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `auth_db`
--

DROP TABLE IF EXISTS `auth_db`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `auth_db` (
  `id` int NOT NULL AUTO_INCREMENT,
  `username` varchar(255) NOT NULL,
  `create_time` datetime NOT NULL,
  `system_mtime` datetime NOT NULL,
  `pwhash` varchar(255) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `username` (`username`),
  KEY `auth_db_system_mtime_index` (`system_mtime`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `auth_db`
--

LOCK TABLES `auth_db` WRITE;
/*!40000 ALTER TABLE `auth_db` DISABLE KEYS */;
/*!40000 ALTER TABLE `auth_db` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `classification`
--

DROP TABLE IF EXISTS `classification`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `classification` (
  `id` int NOT NULL AUTO_INCREMENT,
  `repo_id` int NOT NULL,
  `lock_version` int NOT NULL DEFAULT '0',
  `json_schema_version` int NOT NULL,
  `identifier` varchar(255) NOT NULL,
  `title` varchar(8704) NOT NULL,
  `description` text,
  `created_by` varchar(255) DEFAULT NULL,
  `last_modified_by` varchar(255) DEFAULT NULL,
  `create_time` datetime NOT NULL,
  `system_mtime` datetime NOT NULL,
  `user_mtime` datetime NOT NULL,
  `publish` int DEFAULT '1',
  `suppressed` int DEFAULT '0',
  `slug` varchar(255) DEFAULT NULL,
  `is_slug_auto` int DEFAULT '0',
  PRIMARY KEY (`id`),
  KEY `classification_system_mtime_index` (`system_mtime`),
  KEY `classification_user_mtime_index` (`user_mtime`),
  KEY `repo_id` (`repo_id`),
  CONSTRAINT `classification_ibfk_1` FOREIGN KEY (`repo_id`) REFERENCES `repository` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `classification`
--

LOCK TABLES `classification` WRITE;
/*!40000 ALTER TABLE `classification` DISABLE KEYS */;
/*!40000 ALTER TABLE `classification` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `classification_creator_rlshp`
--

DROP TABLE IF EXISTS `classification_creator_rlshp`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `classification_creator_rlshp` (
  `id` int NOT NULL AUTO_INCREMENT,
  `agent_person_id` int DEFAULT NULL,
  `agent_software_id` int DEFAULT NULL,
  `agent_family_id` int DEFAULT NULL,
  `agent_corporate_entity_id` int DEFAULT NULL,
  `classification_id` int DEFAULT NULL,
  `aspace_relationship_position` int DEFAULT NULL,
  `created_by` varchar(255) DEFAULT NULL,
  `last_modified_by` varchar(255) DEFAULT NULL,
  `system_mtime` datetime NOT NULL,
  `user_mtime` datetime NOT NULL,
  `suppressed` int NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`),
  KEY `classification_creator_rlshp_system_mtime_index` (`system_mtime`),
  KEY `classification_creator_rlshp_user_mtime_index` (`user_mtime`),
  KEY `agent_person_id` (`agent_person_id`),
  KEY `agent_family_id` (`agent_family_id`),
  KEY `agent_corporate_entity_id` (`agent_corporate_entity_id`),
  KEY `agent_software_id` (`agent_software_id`),
  KEY `classification_id` (`classification_id`),
  CONSTRAINT `classification_creator_rlshp_ibfk_1` FOREIGN KEY (`agent_person_id`) REFERENCES `agent_person` (`id`),
  CONSTRAINT `classification_creator_rlshp_ibfk_2` FOREIGN KEY (`agent_family_id`) REFERENCES `agent_family` (`id`),
  CONSTRAINT `classification_creator_rlshp_ibfk_3` FOREIGN KEY (`agent_corporate_entity_id`) REFERENCES `agent_corporate_entity` (`id`),
  CONSTRAINT `classification_creator_rlshp_ibfk_4` FOREIGN KEY (`agent_software_id`) REFERENCES `agent_software` (`id`),
  CONSTRAINT `classification_creator_rlshp_ibfk_5` FOREIGN KEY (`classification_id`) REFERENCES `classification` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `classification_creator_rlshp`
--

LOCK TABLES `classification_creator_rlshp` WRITE;
/*!40000 ALTER TABLE `classification_creator_rlshp` DISABLE KEYS */;
/*!40000 ALTER TABLE `classification_creator_rlshp` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `classification_rlshp`
--

DROP TABLE IF EXISTS `classification_rlshp`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `classification_rlshp` (
  `id` int NOT NULL AUTO_INCREMENT,
  `resource_id` int DEFAULT NULL,
  `accession_id` int DEFAULT NULL,
  `classification_id` int DEFAULT NULL,
  `classification_term_id` int DEFAULT NULL,
  `aspace_relationship_position` int DEFAULT NULL,
  `created_by` varchar(255) DEFAULT NULL,
  `last_modified_by` varchar(255) DEFAULT NULL,
  `system_mtime` datetime NOT NULL,
  `user_mtime` datetime NOT NULL,
  `suppressed` int NOT NULL DEFAULT '0',
  `digital_object_id` int DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `classification_rlshp_system_mtime_index` (`system_mtime`),
  KEY `classification_rlshp_user_mtime_index` (`user_mtime`),
  KEY `resource_id` (`resource_id`),
  KEY `accession_id` (`accession_id`),
  KEY `classification_id` (`classification_id`),
  KEY `classification_term_id` (`classification_term_id`),
  CONSTRAINT `classification_rlshp_ibfk_1` FOREIGN KEY (`resource_id`) REFERENCES `resource` (`id`),
  CONSTRAINT `classification_rlshp_ibfk_2` FOREIGN KEY (`accession_id`) REFERENCES `accession` (`id`),
  CONSTRAINT `classification_rlshp_ibfk_3` FOREIGN KEY (`classification_id`) REFERENCES `classification` (`id`),
  CONSTRAINT `classification_rlshp_ibfk_4` FOREIGN KEY (`classification_term_id`) REFERENCES `classification_term` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `classification_rlshp`
--

LOCK TABLES `classification_rlshp` WRITE;
/*!40000 ALTER TABLE `classification_rlshp` DISABLE KEYS */;
/*!40000 ALTER TABLE `classification_rlshp` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `classification_term`
--

DROP TABLE IF EXISTS `classification_term`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `classification_term` (
  `id` int NOT NULL AUTO_INCREMENT,
  `repo_id` int NOT NULL,
  `lock_version` int NOT NULL DEFAULT '0',
  `json_schema_version` int NOT NULL,
  `identifier` varchar(255) NOT NULL,
  `title` varchar(8704) NOT NULL,
  `title_sha1` varchar(255) NOT NULL,
  `description` text,
  `root_record_id` int DEFAULT NULL,
  `parent_id` int DEFAULT NULL,
  `parent_name` varchar(255) DEFAULT NULL,
  `position` int NOT NULL,
  `created_by` varchar(255) DEFAULT NULL,
  `last_modified_by` varchar(255) DEFAULT NULL,
  `create_time` datetime NOT NULL,
  `system_mtime` datetime NOT NULL,
  `user_mtime` datetime NOT NULL,
  `publish` int DEFAULT '1',
  `suppressed` int DEFAULT '0',
  `display_string` text NOT NULL,
  `slug` varchar(255) DEFAULT NULL,
  `is_slug_auto` int DEFAULT '0',
  PRIMARY KEY (`id`),
  UNIQUE KEY `classification_term_parent_name_title_sha1_index` (`parent_name`,`title_sha1`),
  UNIQUE KEY `classification_term_parent_name_identifier_index` (`parent_name`,`identifier`),
  UNIQUE KEY `uniq_ct_pos` (`parent_name`,`position`),
  KEY `classification_term_system_mtime_index` (`system_mtime`),
  KEY `classification_term_user_mtime_index` (`user_mtime`),
  KEY `repo_id` (`repo_id`),
  CONSTRAINT `classification_term_ibfk_1` FOREIGN KEY (`repo_id`) REFERENCES `repository` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `classification_term`
--

LOCK TABLES `classification_term` WRITE;
/*!40000 ALTER TABLE `classification_term` DISABLE KEYS */;
/*!40000 ALTER TABLE `classification_term` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `classification_term_creator_rlshp`
--

DROP TABLE IF EXISTS `classification_term_creator_rlshp`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `classification_term_creator_rlshp` (
  `id` int NOT NULL AUTO_INCREMENT,
  `agent_person_id` int DEFAULT NULL,
  `agent_software_id` int DEFAULT NULL,
  `agent_family_id` int DEFAULT NULL,
  `agent_corporate_entity_id` int DEFAULT NULL,
  `classification_term_id` int DEFAULT NULL,
  `aspace_relationship_position` int DEFAULT NULL,
  `created_by` varchar(255) DEFAULT NULL,
  `last_modified_by` varchar(255) DEFAULT NULL,
  `system_mtime` datetime NOT NULL,
  `user_mtime` datetime NOT NULL,
  `suppressed` int NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`),
  KEY `classification_term_creator_rlshp_system_mtime_index` (`system_mtime`),
  KEY `classification_term_creator_rlshp_user_mtime_index` (`user_mtime`),
  KEY `agent_person_id` (`agent_person_id`),
  KEY `agent_family_id` (`agent_family_id`),
  KEY `agent_corporate_entity_id` (`agent_corporate_entity_id`),
  KEY `agent_software_id` (`agent_software_id`),
  KEY `classification_term_id` (`classification_term_id`),
  CONSTRAINT `classification_term_creator_rlshp_ibfk_1` FOREIGN KEY (`agent_person_id`) REFERENCES `agent_person` (`id`),
  CONSTRAINT `classification_term_creator_rlshp_ibfk_2` FOREIGN KEY (`agent_family_id`) REFERENCES `agent_family` (`id`),
  CONSTRAINT `classification_term_creator_rlshp_ibfk_3` FOREIGN KEY (`agent_corporate_entity_id`) REFERENCES `agent_corporate_entity` (`id`),
  CONSTRAINT `classification_term_creator_rlshp_ibfk_4` FOREIGN KEY (`agent_software_id`) REFERENCES `agent_software` (`id`),
  CONSTRAINT `classification_term_creator_rlshp_ibfk_5` FOREIGN KEY (`classification_term_id`) REFERENCES `classification_term` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `classification_term_creator_rlshp`
--

LOCK TABLES `classification_term_creator_rlshp` WRITE;
/*!40000 ALTER TABLE `classification_term_creator_rlshp` DISABLE KEYS */;
/*!40000 ALTER TABLE `classification_term_creator_rlshp` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `collection_management`
--

DROP TABLE IF EXISTS `collection_management`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `collection_management` (
  `id` int NOT NULL AUTO_INCREMENT,
  `lock_version` int NOT NULL DEFAULT '0',
  `json_schema_version` int NOT NULL,
  `accession_id` int DEFAULT NULL,
  `resource_id` int DEFAULT NULL,
  `digital_object_id` int DEFAULT NULL,
  `processing_hours_per_foot_estimate` varchar(255) DEFAULT NULL,
  `processing_total_extent` varchar(255) DEFAULT NULL,
  `processing_total_extent_type_id` int DEFAULT NULL,
  `processing_hours_total` varchar(255) DEFAULT NULL,
  `processing_plan` text,
  `processing_priority_id` int DEFAULT NULL,
  `processing_status_id` int DEFAULT NULL,
  `processing_funding_source` text,
  `processors` text,
  `rights_determined` int NOT NULL DEFAULT '0',
  `created_by` varchar(255) DEFAULT NULL,
  `last_modified_by` varchar(255) DEFAULT NULL,
  `create_time` datetime NOT NULL,
  `system_mtime` datetime NOT NULL,
  `user_mtime` datetime NOT NULL,
  PRIMARY KEY (`id`),
  KEY `processing_total_extent_type_id` (`processing_total_extent_type_id`),
  KEY `processing_priority_id` (`processing_priority_id`),
  KEY `processing_status_id` (`processing_status_id`),
  KEY `collection_management_system_mtime_index` (`system_mtime`),
  KEY `collection_management_user_mtime_index` (`user_mtime`),
  KEY `accession_id` (`accession_id`),
  KEY `resource_id` (`resource_id`),
  KEY `digital_object_id` (`digital_object_id`),
  CONSTRAINT `collection_management_ibfk_1` FOREIGN KEY (`processing_total_extent_type_id`) REFERENCES `enumeration_value` (`id`),
  CONSTRAINT `collection_management_ibfk_2` FOREIGN KEY (`processing_priority_id`) REFERENCES `enumeration_value` (`id`),
  CONSTRAINT `collection_management_ibfk_3` FOREIGN KEY (`processing_status_id`) REFERENCES `enumeration_value` (`id`),
  CONSTRAINT `collection_management_ibfk_4` FOREIGN KEY (`accession_id`) REFERENCES `accession` (`id`),
  CONSTRAINT `collection_management_ibfk_5` FOREIGN KEY (`resource_id`) REFERENCES `resource` (`id`),
  CONSTRAINT `collection_management_ibfk_6` FOREIGN KEY (`digital_object_id`) REFERENCES `digital_object` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `collection_management`
--

LOCK TABLES `collection_management` WRITE;
/*!40000 ALTER TABLE `collection_management` DISABLE KEYS */;
/*!40000 ALTER TABLE `collection_management` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `container_profile`
--

DROP TABLE IF EXISTS `container_profile`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `container_profile` (
  `id` int NOT NULL AUTO_INCREMENT,
  `lock_version` int NOT NULL DEFAULT '0',
  `name` varchar(255) DEFAULT NULL,
  `url` varchar(255) DEFAULT NULL,
  `extent_dimension` varchar(255) DEFAULT NULL,
  `dimension_units_id` int DEFAULT NULL,
  `height` varchar(255) DEFAULT NULL,
  `width` varchar(255) DEFAULT NULL,
  `depth` varchar(255) DEFAULT NULL,
  `created_by` varchar(255) DEFAULT NULL,
  `last_modified_by` varchar(255) DEFAULT NULL,
  `create_time` datetime NOT NULL,
  `system_mtime` datetime NOT NULL,
  `user_mtime` datetime NOT NULL,
  `stacking_limit` varchar(255) DEFAULT NULL,
  `notes` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `container_profile_name_uniq` (`name`),
  KEY `dimension_units_id` (`dimension_units_id`),
  KEY `container_profile_system_mtime_index` (`system_mtime`),
  KEY `container_profile_user_mtime_index` (`user_mtime`),
  CONSTRAINT `container_profile_ibfk_1` FOREIGN KEY (`dimension_units_id`) REFERENCES `enumeration_value` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `container_profile`
--

LOCK TABLES `container_profile` WRITE;
/*!40000 ALTER TABLE `container_profile` DISABLE KEYS */;
/*!40000 ALTER TABLE `container_profile` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `custom_report_template`
--

DROP TABLE IF EXISTS `custom_report_template`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `custom_report_template` (
  `id` int NOT NULL AUTO_INCREMENT,
  `lock_version` int NOT NULL DEFAULT '0',
  `json_schema_version` int NOT NULL,
  `repo_id` int NOT NULL,
  `name` varchar(255) NOT NULL,
  `description` varchar(255) DEFAULT NULL,
  `data` text NOT NULL,
  `created_by` varchar(255) DEFAULT NULL,
  `last_modified_by` varchar(255) DEFAULT NULL,
  `create_time` datetime NOT NULL,
  `system_mtime` datetime NOT NULL,
  `user_mtime` datetime NOT NULL,
  `limit` int DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `name` (`name`),
  KEY `custom_report_template_system_mtime_index` (`system_mtime`),
  KEY `custom_report_template_user_mtime_index` (`user_mtime`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `custom_report_template`
--

LOCK TABLES `custom_report_template` WRITE;
/*!40000 ALTER TABLE `custom_report_template` DISABLE KEYS */;
/*!40000 ALTER TABLE `custom_report_template` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `date`
--

DROP TABLE IF EXISTS `date`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `date` (
  `id` int NOT NULL AUTO_INCREMENT,
  `lock_version` int NOT NULL DEFAULT '0',
  `json_schema_version` int NOT NULL,
  `accession_id` int DEFAULT NULL,
  `deaccession_id` int DEFAULT NULL,
  `archival_object_id` int DEFAULT NULL,
  `resource_id` int DEFAULT NULL,
  `event_id` int DEFAULT NULL,
  `digital_object_id` int DEFAULT NULL,
  `digital_object_component_id` int DEFAULT NULL,
  `date_type_id` int DEFAULT NULL,
  `label_id` int NOT NULL,
  `certainty_id` int DEFAULT NULL,
  `expression` varchar(255) DEFAULT NULL,
  `begin` varchar(255) DEFAULT NULL,
  `end` varchar(255) DEFAULT NULL,
  `era_id` int DEFAULT NULL,
  `calendar_id` int DEFAULT NULL,
  `created_by` varchar(255) DEFAULT NULL,
  `last_modified_by` varchar(255) DEFAULT NULL,
  `create_time` datetime NOT NULL,
  `system_mtime` datetime NOT NULL,
  `user_mtime` datetime NOT NULL,
  PRIMARY KEY (`id`),
  KEY `date_type_id` (`date_type_id`),
  KEY `label_id` (`label_id`),
  KEY `certainty_id` (`certainty_id`),
  KEY `era_id` (`era_id`),
  KEY `calendar_id` (`calendar_id`),
  KEY `date_system_mtime_index` (`system_mtime`),
  KEY `date_user_mtime_index` (`user_mtime`),
  KEY `accession_id` (`accession_id`),
  KEY `archival_object_id` (`archival_object_id`),
  KEY `resource_id` (`resource_id`),
  KEY `event_id` (`event_id`),
  KEY `deaccession_id` (`deaccession_id`),
  KEY `digital_object_id` (`digital_object_id`),
  KEY `digital_object_component_id` (`digital_object_component_id`),
  CONSTRAINT `date_ibfk_1` FOREIGN KEY (`date_type_id`) REFERENCES `enumeration_value` (`id`),
  CONSTRAINT `date_ibfk_10` FOREIGN KEY (`deaccession_id`) REFERENCES `deaccession` (`id`),
  CONSTRAINT `date_ibfk_12` FOREIGN KEY (`digital_object_id`) REFERENCES `digital_object` (`id`),
  CONSTRAINT `date_ibfk_13` FOREIGN KEY (`digital_object_component_id`) REFERENCES `digital_object_component` (`id`),
  CONSTRAINT `date_ibfk_2` FOREIGN KEY (`label_id`) REFERENCES `enumeration_value` (`id`),
  CONSTRAINT `date_ibfk_3` FOREIGN KEY (`certainty_id`) REFERENCES `enumeration_value` (`id`),
  CONSTRAINT `date_ibfk_4` FOREIGN KEY (`era_id`) REFERENCES `enumeration_value` (`id`),
  CONSTRAINT `date_ibfk_5` FOREIGN KEY (`calendar_id`) REFERENCES `enumeration_value` (`id`),
  CONSTRAINT `date_ibfk_6` FOREIGN KEY (`accession_id`) REFERENCES `accession` (`id`),
  CONSTRAINT `date_ibfk_7` FOREIGN KEY (`archival_object_id`) REFERENCES `archival_object` (`id`),
  CONSTRAINT `date_ibfk_8` FOREIGN KEY (`resource_id`) REFERENCES `resource` (`id`),
  CONSTRAINT `date_ibfk_9` FOREIGN KEY (`event_id`) REFERENCES `event` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `date`
--

LOCK TABLES `date` WRITE;
/*!40000 ALTER TABLE `date` DISABLE KEYS */;
/*!40000 ALTER TABLE `date` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `deaccession`
--

DROP TABLE IF EXISTS `deaccession`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `deaccession` (
  `id` int NOT NULL AUTO_INCREMENT,
  `lock_version` int NOT NULL DEFAULT '0',
  `json_schema_version` int NOT NULL,
  `accession_id` int DEFAULT NULL,
  `resource_id` int DEFAULT NULL,
  `scope_id` int NOT NULL,
  `description` text NOT NULL,
  `reason` text,
  `disposition` text,
  `notification` int DEFAULT NULL,
  `created_by` varchar(255) DEFAULT NULL,
  `last_modified_by` varchar(255) DEFAULT NULL,
  `create_time` datetime NOT NULL,
  `system_mtime` datetime NOT NULL,
  `user_mtime` datetime NOT NULL,
  PRIMARY KEY (`id`),
  KEY `scope_id` (`scope_id`),
  KEY `deaccession_system_mtime_index` (`system_mtime`),
  KEY `deaccession_user_mtime_index` (`user_mtime`),
  KEY `accession_id` (`accession_id`),
  KEY `resource_id` (`resource_id`),
  CONSTRAINT `deaccession_ibfk_1` FOREIGN KEY (`scope_id`) REFERENCES `enumeration_value` (`id`),
  CONSTRAINT `deaccession_ibfk_2` FOREIGN KEY (`accession_id`) REFERENCES `accession` (`id`),
  CONSTRAINT `deaccession_ibfk_3` FOREIGN KEY (`resource_id`) REFERENCES `resource` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `deaccession`
--

LOCK TABLES `deaccession` WRITE;
/*!40000 ALTER TABLE `deaccession` DISABLE KEYS */;
/*!40000 ALTER TABLE `deaccession` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `default_values`
--

DROP TABLE IF EXISTS `default_values`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `default_values` (
  `lock_version` int NOT NULL DEFAULT '0',
  `id` varchar(255) NOT NULL,
  `blob` blob NOT NULL,
  `repo_id` int NOT NULL,
  `record_type` varchar(255) NOT NULL,
  `created_by` varchar(255) DEFAULT NULL,
  `last_modified_by` varchar(255) DEFAULT NULL,
  `create_time` datetime NOT NULL,
  `system_mtime` datetime NOT NULL,
  `user_mtime` datetime NOT NULL,
  PRIMARY KEY (`id`),
  KEY `default_values_system_mtime_index` (`system_mtime`),
  KEY `default_values_user_mtime_index` (`user_mtime`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `default_values`
--

LOCK TABLES `default_values` WRITE;
/*!40000 ALTER TABLE `default_values` DISABLE KEYS */;
/*!40000 ALTER TABLE `default_values` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `deleted_records`
--

DROP TABLE IF EXISTS `deleted_records`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `deleted_records` (
  `id` int NOT NULL AUTO_INCREMENT,
  `uri` varchar(255) NOT NULL,
  `operator` varchar(255) NOT NULL,
  `timestamp` datetime NOT NULL,
  PRIMARY KEY (`id`),
  KEY `deleted_records_uri_index` (`uri`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `deleted_records`
--

LOCK TABLES `deleted_records` WRITE;
/*!40000 ALTER TABLE `deleted_records` DISABLE KEYS */;
/*!40000 ALTER TABLE `deleted_records` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `digital_object`
--

DROP TABLE IF EXISTS `digital_object`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `digital_object` (
  `id` int NOT NULL AUTO_INCREMENT,
  `lock_version` int NOT NULL DEFAULT '0',
  `json_schema_version` int NOT NULL,
  `repo_id` int NOT NULL,
  `digital_object_id` varchar(255) NOT NULL,
  `title` varchar(8704) DEFAULT NULL,
  `level_id` int DEFAULT NULL,
  `digital_object_type_id` int DEFAULT NULL,
  `publish` int DEFAULT NULL,
  `restrictions` int DEFAULT NULL,
  `system_generated` int DEFAULT '0',
  `created_by` varchar(255) DEFAULT NULL,
  `last_modified_by` varchar(255) DEFAULT NULL,
  `create_time` datetime NOT NULL,
  `system_mtime` datetime NOT NULL,
  `user_mtime` datetime NOT NULL,
  `suppressed` int NOT NULL DEFAULT '0',
  `slug` varchar(255) DEFAULT NULL,
  `is_slug_auto` int DEFAULT '0',
  PRIMARY KEY (`id`),
  UNIQUE KEY `digital_object_repo_id_digital_object_id_index` (`repo_id`,`digital_object_id`),
  KEY `level_id` (`level_id`),
  KEY `digital_object_type_id` (`digital_object_type_id`),
  KEY `digital_object_system_mtime_index` (`system_mtime`),
  KEY `digital_object_user_mtime_index` (`user_mtime`),
  CONSTRAINT `digital_object_ibfk_1` FOREIGN KEY (`level_id`) REFERENCES `enumeration_value` (`id`),
  CONSTRAINT `digital_object_ibfk_2` FOREIGN KEY (`digital_object_type_id`) REFERENCES `enumeration_value` (`id`),
  CONSTRAINT `digital_object_ibfk_4` FOREIGN KEY (`repo_id`) REFERENCES `repository` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `digital_object`
--

LOCK TABLES `digital_object` WRITE;
/*!40000 ALTER TABLE `digital_object` DISABLE KEYS */;
/*!40000 ALTER TABLE `digital_object` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `digital_object_component`
--

DROP TABLE IF EXISTS `digital_object_component`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `digital_object_component` (
  `id` int NOT NULL AUTO_INCREMENT,
  `lock_version` int NOT NULL DEFAULT '0',
  `json_schema_version` int NOT NULL,
  `repo_id` int NOT NULL,
  `root_record_id` int DEFAULT NULL,
  `parent_id` int DEFAULT NULL,
  `position` int NOT NULL,
  `parent_name` varchar(255) DEFAULT NULL,
  `publish` int DEFAULT NULL,
  `component_id` varchar(255) DEFAULT NULL,
  `title` varchar(8704) DEFAULT NULL,
  `display_string` text,
  `label` varchar(255) DEFAULT NULL,
  `system_generated` int DEFAULT '0',
  `created_by` varchar(255) DEFAULT NULL,
  `last_modified_by` varchar(255) DEFAULT NULL,
  `create_time` datetime NOT NULL,
  `system_mtime` datetime NOT NULL,
  `user_mtime` datetime NOT NULL,
  `suppressed` int NOT NULL DEFAULT '0',
  `slug` varchar(255) DEFAULT NULL,
  `is_slug_auto` int DEFAULT '0',
  PRIMARY KEY (`id`),
  UNIQUE KEY `doc_unique_identifier` (`repo_id`,`component_id`),
  UNIQUE KEY `uniq_do_pos` (`parent_name`,`position`),
  KEY `digital_object_component_system_mtime_index` (`system_mtime`),
  KEY `digital_object_component_user_mtime_index` (`user_mtime`),
  KEY `root_record_id` (`root_record_id`),
  KEY `parent_id` (`parent_id`),
  KEY `digital_object_component_component_id_index` (`component_id`),
  CONSTRAINT `digital_object_component_ibfk_2` FOREIGN KEY (`repo_id`) REFERENCES `repository` (`id`),
  CONSTRAINT `digital_object_component_ibfk_3` FOREIGN KEY (`root_record_id`) REFERENCES `digital_object` (`id`),
  CONSTRAINT `digital_object_component_ibfk_4` FOREIGN KEY (`parent_id`) REFERENCES `digital_object_component` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `digital_object_component`
--

LOCK TABLES `digital_object_component` WRITE;
/*!40000 ALTER TABLE `digital_object_component` DISABLE KEYS */;
/*!40000 ALTER TABLE `digital_object_component` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `enumeration`
--

DROP TABLE IF EXISTS `enumeration`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `enumeration` (
  `id` int NOT NULL AUTO_INCREMENT,
  `lock_version` int NOT NULL DEFAULT '0',
  `json_schema_version` int NOT NULL,
  `name` varchar(255) NOT NULL,
  `default_value` int DEFAULT NULL,
  `editable` int DEFAULT '1',
  `created_by` varchar(255) DEFAULT NULL,
  `last_modified_by` varchar(255) DEFAULT NULL,
  `create_time` datetime NOT NULL,
  `system_mtime` datetime NOT NULL,
  `user_mtime` datetime NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `name` (`name`),
  KEY `enumeration_system_mtime_index` (`system_mtime`),
  KEY `enumeration_user_mtime_index` (`user_mtime`),
  KEY `enumeration_default_value_fk` (`default_value`),
  CONSTRAINT `enumeration_default_value_fk` FOREIGN KEY (`default_value`) REFERENCES `enumeration_value` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB AUTO_INCREMENT=103 DEFAULT CHARSET=utf8mb3;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `enumeration`
--

LOCK TABLES `enumeration` WRITE;
/*!40000 ALTER TABLE `enumeration` DISABLE KEYS */;
INSERT INTO `enumeration` VALUES (1,0,1,'linked_agent_archival_record_relators',NULL,1,NULL,NULL,'2024-04-18 15:42:54','2024-04-18 15:42:54','2024-04-18 15:42:54'),(2,0,1,'linked_event_archival_record_roles',NULL,0,NULL,NULL,'2024-04-18 15:43:00','2024-04-18 15:43:00','2024-04-18 15:43:00'),(3,0,1,'linked_agent_event_roles',NULL,1,NULL,NULL,'2024-04-18 15:43:00','2024-04-18 15:43:00','2024-04-18 15:43:00'),(4,0,1,'name_source',NULL,1,NULL,NULL,'2024-04-18 15:43:01','2024-04-18 15:43:01','2024-04-18 15:43:01'),(5,0,1,'name_rule',NULL,1,NULL,NULL,'2024-04-18 15:43:01','2024-04-18 15:43:01','2024-04-18 15:43:01'),(6,0,1,'accession_acquisition_type',NULL,1,NULL,NULL,'2024-04-18 15:43:01','2024-04-18 15:43:01','2024-04-18 15:43:01'),(7,0,1,'accession_resource_type',NULL,1,NULL,NULL,'2024-04-18 15:43:01','2024-04-18 15:43:01','2024-04-18 15:43:01'),(8,0,1,'collection_management_processing_priority',NULL,1,NULL,NULL,'2024-04-18 15:43:01','2024-04-18 15:43:01','2024-04-18 15:43:01'),(9,0,1,'collection_management_processing_status',NULL,1,NULL,NULL,'2024-04-18 15:43:01','2024-04-18 15:43:01','2024-04-18 15:43:01'),(10,0,1,'date_era',NULL,1,NULL,NULL,'2024-04-18 15:43:01','2024-04-18 15:43:01','2024-04-18 15:43:01'),(11,0,1,'date_calendar',NULL,1,NULL,NULL,'2024-04-18 15:43:01','2024-04-18 15:43:01','2024-04-18 15:43:01'),(12,0,1,'digital_object_digital_object_type',NULL,1,NULL,NULL,'2024-04-18 15:43:01','2024-04-18 15:43:01','2024-04-18 15:43:01'),(13,0,1,'digital_object_level',NULL,1,NULL,NULL,'2024-04-18 15:43:02','2024-04-18 15:43:02','2024-04-18 15:43:02'),(14,0,1,'extent_extent_type',NULL,1,NULL,NULL,'2024-04-18 15:43:02','2024-04-18 15:43:02','2024-04-18 15:43:02'),(15,0,1,'event_event_type',NULL,1,NULL,NULL,'2024-04-18 15:43:02','2024-04-18 15:43:02','2024-04-18 15:43:02'),(16,0,1,'container_type',NULL,1,NULL,NULL,'2024-04-18 15:43:03','2024-04-18 15:43:03','2024-04-18 15:43:03'),(17,0,1,'agent_contact_salutation',NULL,1,NULL,NULL,'2024-04-18 15:43:03','2024-04-18 15:43:03','2024-04-18 15:43:03'),(18,0,1,'event_outcome',NULL,1,NULL,NULL,'2024-04-18 15:43:03','2024-04-18 15:43:03','2024-04-18 15:43:03'),(19,0,1,'resource_resource_type',NULL,1,NULL,NULL,'2024-04-18 15:43:03','2024-04-18 15:43:03','2024-04-18 15:43:03'),(20,0,1,'resource_finding_aid_description_rules',NULL,1,NULL,NULL,'2024-04-18 15:43:04','2024-04-18 15:43:04','2024-04-18 15:43:04'),(21,0,1,'resource_finding_aid_status',NULL,1,NULL,NULL,'2024-04-18 15:43:04','2024-04-18 15:43:04','2024-04-18 15:43:04'),(22,0,1,'instance_instance_type',NULL,1,NULL,NULL,'2024-04-18 15:43:04','2024-04-18 15:43:04','2024-04-18 15:43:04'),(23,0,1,'subject_source',NULL,1,NULL,NULL,'2024-04-18 15:43:04','2024-04-18 15:43:04','2024-04-18 15:43:04'),(24,0,1,'file_version_use_statement',NULL,1,NULL,NULL,'2024-04-18 15:43:04','2024-04-18 15:43:04','2024-04-18 15:43:04'),(25,0,1,'file_version_checksum_methods',NULL,1,NULL,NULL,'2024-04-18 15:43:05','2024-04-18 15:43:05','2024-04-18 15:43:05'),(26,0,1,'language_iso639_2',NULL,0,NULL,NULL,'2024-04-18 15:43:05','2024-04-18 15:43:05','2024-04-18 15:43:05'),(27,0,1,'linked_agent_role',NULL,0,NULL,NULL,'2024-04-18 15:43:18','2024-04-18 15:43:18','2024-04-18 15:43:18'),(28,0,1,'agent_relationship_associative_relator',NULL,0,NULL,NULL,'2024-04-18 15:43:18','2024-04-18 15:43:18','2024-04-18 15:43:18'),(29,0,1,'agent_relationship_earlierlater_relator',NULL,0,NULL,NULL,'2024-04-18 15:43:18','2024-04-18 15:43:18','2024-04-18 15:43:18'),(30,0,1,'agent_relationship_parentchild_relator',NULL,0,NULL,NULL,'2024-04-18 15:43:18','2024-04-18 15:43:18','2024-04-18 15:43:18'),(31,0,1,'agent_relationship_subordinatesuperior_relator',NULL,0,NULL,NULL,'2024-04-18 15:43:18','2024-04-18 15:43:18','2024-04-18 15:43:18'),(32,0,1,'archival_record_level',NULL,0,NULL,NULL,'2024-04-18 15:43:18','2024-04-18 15:43:18','2024-04-18 15:43:18'),(33,0,1,'container_location_status',899,0,NULL,NULL,'2024-04-18 15:43:19','2024-04-18 15:43:19','2024-04-18 15:43:19'),(34,0,1,'date_type',NULL,0,NULL,NULL,'2024-04-18 15:43:19','2024-04-18 15:43:19','2024-04-18 15:43:19'),(35,0,1,'date_label',NULL,1,NULL,NULL,'2024-04-18 15:43:19','2024-04-18 15:43:19','2024-04-18 15:43:19'),(36,0,1,'date_certainty',NULL,0,NULL,NULL,'2024-04-18 15:43:19','2024-04-18 15:43:19','2024-04-18 15:43:19'),(37,0,1,'deaccession_scope',921,0,NULL,NULL,'2024-04-18 15:43:19','2024-04-18 15:43:19','2024-04-18 15:43:19'),(38,0,1,'extent_portion',923,0,NULL,NULL,'2024-04-18 15:43:20','2024-04-18 15:43:20','2024-04-18 15:43:20'),(39,0,1,'file_version_xlink_actuate_attribute',NULL,0,NULL,NULL,'2024-04-18 15:43:20','2024-04-18 15:43:20','2024-04-18 15:43:20'),(40,0,1,'file_version_xlink_show_attribute',NULL,0,NULL,NULL,'2024-04-18 15:43:20','2024-04-18 15:43:20','2024-04-18 15:43:20'),(41,0,1,'file_version_file_format_name',NULL,1,NULL,NULL,'2024-04-18 15:43:20','2024-04-18 15:43:20','2024-04-18 15:43:20'),(42,0,1,'location_temporary',NULL,1,NULL,NULL,'2024-04-18 15:43:20','2024-04-18 15:43:20','2024-04-18 15:43:20'),(43,0,1,'name_person_name_order',946,0,NULL,NULL,'2024-04-18 15:43:20','2024-04-18 15:43:20','2024-04-18 15:43:20'),(44,0,1,'note_digital_object_type',NULL,0,NULL,NULL,'2024-04-18 15:43:20','2024-04-18 15:43:20','2024-04-18 15:43:20'),(45,0,1,'note_multipart_type',NULL,0,NULL,NULL,'2024-04-18 15:43:21','2024-04-18 15:43:21','2024-04-18 15:43:21'),(46,0,1,'note_orderedlist_enumeration',NULL,0,NULL,NULL,'2024-04-18 15:43:22','2024-04-18 15:43:22','2024-04-18 15:43:22'),(47,0,1,'note_singlepart_type',NULL,0,NULL,NULL,'2024-04-18 15:43:22','2024-04-18 15:43:22','2024-04-18 15:43:22'),(48,0,1,'note_bibliography_type',NULL,0,NULL,NULL,'2024-04-18 15:43:22','2024-04-18 15:43:22','2024-04-18 15:43:22'),(49,0,1,'note_index_type',NULL,0,NULL,NULL,'2024-04-18 15:43:22','2024-04-18 15:43:22','2024-04-18 15:43:22'),(50,0,1,'note_index_item_type',NULL,0,NULL,NULL,'2024-04-18 15:43:22','2024-04-18 15:43:22','2024-04-18 15:43:22'),(51,0,1,'country_iso_3166',NULL,0,NULL,NULL,'2024-04-18 15:43:22','2024-04-18 15:43:22','2024-04-18 15:43:22'),(52,0,1,'rights_statement_rights_type',NULL,0,NULL,NULL,'2024-04-18 15:43:29','2024-04-18 15:43:29','2024-04-18 15:43:29'),(53,0,1,'rights_statement_ip_status',NULL,0,NULL,NULL,'2024-04-18 15:43:29','2024-04-18 15:43:29','2024-04-18 15:43:29'),(54,0,1,'subject_term_type',NULL,0,NULL,NULL,'2024-04-18 15:43:29','2024-04-18 15:43:29','2024-04-18 15:43:29'),(55,0,1,'user_defined_enum_1',NULL,1,NULL,NULL,'2024-04-18 15:44:11','2024-04-18 15:44:11','2024-04-18 15:44:11'),(56,0,1,'user_defined_enum_2',NULL,1,NULL,NULL,'2024-04-18 15:44:11','2024-04-18 15:44:11','2024-04-18 15:44:11'),(57,0,1,'user_defined_enum_3',NULL,1,NULL,NULL,'2024-04-18 15:44:11','2024-04-18 15:44:11','2024-04-18 15:44:11'),(58,0,1,'user_defined_enum_4',NULL,1,NULL,NULL,'2024-04-18 15:44:11','2024-04-18 15:44:11','2024-04-18 15:44:11'),(59,0,1,'accession_parts_relator',NULL,0,NULL,NULL,'2024-04-18 15:44:45','2024-04-18 15:44:45','2024-04-18 15:44:45'),(60,0,1,'accession_parts_relator_type',NULL,1,NULL,NULL,'2024-04-18 15:44:45','2024-04-18 15:44:45','2024-04-18 15:44:45'),(61,0,1,'accession_sibling_relator',NULL,0,NULL,NULL,'2024-04-18 15:44:45','2024-04-18 15:44:45','2024-04-18 15:44:45'),(62,0,1,'accession_sibling_relator_type',NULL,1,NULL,NULL,'2024-04-18 15:44:46','2024-04-18 15:44:46','2024-04-18 15:44:46'),(64,0,1,'telephone_number_type',NULL,1,NULL,NULL,'2024-04-18 15:45:37','2024-04-18 15:45:37','2024-04-18 15:45:37'),(65,0,1,'restriction_type',NULL,1,NULL,NULL,'2024-04-18 15:45:43','2024-04-18 15:45:43','2024-04-18 15:45:43'),(66,0,1,'dimension_units',NULL,0,NULL,NULL,'2024-04-18 15:45:44','2024-04-18 15:45:44','2024-04-18 15:45:44'),(67,0,1,'location_function_type',NULL,1,NULL,NULL,'2024-04-18 15:45:57','2024-04-18 15:45:57','2024-04-18 15:45:57'),(68,0,1,'rights_statement_act_type',NULL,1,NULL,NULL,'2024-04-18 15:46:03','2024-04-18 15:46:03','2024-04-18 15:46:03'),(69,0,1,'rights_statement_act_restriction',NULL,1,NULL,NULL,'2024-04-18 15:46:03','2024-04-18 15:46:03','2024-04-18 15:46:03'),(70,0,1,'note_rights_statement_act_type',NULL,0,NULL,NULL,'2024-04-18 15:46:04','2024-04-18 15:46:04','2024-04-18 15:46:04'),(71,0,1,'note_rights_statement_type',NULL,0,NULL,NULL,'2024-04-18 15:46:06','2024-04-18 15:46:06','2024-04-18 15:46:06'),(72,0,1,'rights_statement_external_document_identifier_type',NULL,1,NULL,NULL,'2024-04-18 15:46:07','2024-04-18 15:46:07','2024-04-18 15:46:07'),(73,0,1,'rights_statement_other_rights_basis',NULL,1,NULL,NULL,'2024-04-18 15:46:11','2024-04-18 15:46:11','2024-04-18 15:46:11'),(74,0,1,'script_iso15924',NULL,1,NULL,NULL,'2024-04-18 15:46:29','2024-04-18 15:46:29','2024-04-18 15:46:29'),(75,0,1,'note_langmaterial_type',NULL,0,NULL,NULL,'2024-04-18 15:46:38','2024-04-18 15:46:38','2024-04-18 15:46:38'),(76,0,1,'maintenance_status',NULL,0,NULL,NULL,'2024-04-18 15:46:43','2024-04-18 15:46:43','2024-04-18 15:46:43'),(77,0,1,'publication_status',NULL,0,NULL,NULL,'2024-04-18 15:46:44','2024-04-18 15:46:44','2024-04-18 15:46:44'),(78,0,1,'romanization',NULL,1,NULL,NULL,'2024-04-18 15:46:44','2024-04-18 15:46:44','2024-04-18 15:46:44'),(79,0,1,'transliteration',NULL,1,NULL,NULL,'2024-04-18 15:46:44','2024-04-18 15:46:44','2024-04-18 15:46:44'),(80,0,1,'government_agency_type',NULL,0,NULL,NULL,'2024-04-18 15:46:44','2024-04-18 15:46:44','2024-04-18 15:46:44'),(81,0,1,'reference_evaluation',NULL,0,NULL,NULL,'2024-04-18 15:46:44','2024-04-18 15:46:44','2024-04-18 15:46:44'),(82,0,1,'name_type',NULL,0,NULL,NULL,'2024-04-18 15:46:44','2024-04-18 15:46:44','2024-04-18 15:46:44'),(83,0,1,'level_of_detail',NULL,0,NULL,NULL,'2024-04-18 15:46:45','2024-04-18 15:46:45','2024-04-18 15:46:45'),(84,0,1,'modified_record',NULL,0,NULL,NULL,'2024-04-18 15:46:45','2024-04-18 15:46:45','2024-04-18 15:46:45'),(85,0,1,'cataloging_source',NULL,0,NULL,NULL,'2024-04-18 15:46:45','2024-04-18 15:46:45','2024-04-18 15:46:45'),(86,0,1,'identifier_type',NULL,1,NULL,NULL,'2024-04-18 15:46:45','2024-04-18 15:46:45','2024-04-18 15:46:45'),(87,0,1,'agency_code_type',NULL,1,NULL,NULL,'2024-04-18 15:46:45','2024-04-18 15:46:45','2024-04-18 15:46:45'),(88,0,1,'maintenance_event_type',NULL,0,NULL,NULL,'2024-04-18 15:46:45','2024-04-18 15:46:45','2024-04-18 15:46:45'),(89,0,1,'maintenance_agent_type',1763,0,NULL,NULL,'2024-04-18 15:46:45','2024-04-18 15:46:45','2024-04-18 15:46:45'),(90,0,1,'date_type_structured',NULL,0,NULL,NULL,'2024-04-18 15:46:46','2024-04-18 15:46:46','2024-04-18 15:46:46'),(91,0,1,'date_role',NULL,0,NULL,NULL,'2024-04-18 15:46:46','2024-04-18 15:46:46','2024-04-18 15:46:46'),(92,0,1,'date_standardized_type',NULL,0,NULL,NULL,'2024-04-18 15:46:46','2024-04-18 15:46:46','2024-04-18 15:46:46'),(93,0,1,'begin_date_standardized_type',NULL,0,NULL,NULL,'2024-04-18 15:46:46','2024-04-18 15:46:46','2024-04-18 15:46:46'),(94,0,1,'end_date_standardized_type',NULL,0,NULL,NULL,'2024-04-18 15:46:46','2024-04-18 15:46:46','2024-04-18 15:46:46'),(95,0,1,'place_role',NULL,1,NULL,NULL,'2024-04-18 15:46:46','2024-04-18 15:46:46','2024-04-18 15:46:46'),(96,0,1,'agent_relationship_identity_relator',NULL,0,NULL,NULL,'2024-04-18 15:46:46','2024-04-18 15:46:46','2024-04-18 15:46:46'),(97,0,1,'agent_relationship_hierarchical_relator',NULL,0,NULL,NULL,'2024-04-18 15:46:46','2024-04-18 15:46:46','2024-04-18 15:46:46'),(98,0,1,'agent_relationship_temporal_relator',NULL,0,NULL,NULL,'2024-04-18 15:46:46','2024-04-18 15:46:46','2024-04-18 15:46:46'),(99,0,1,'agent_relationship_family_relator',NULL,0,NULL,NULL,'2024-04-18 15:46:46','2024-04-18 15:46:46','2024-04-18 15:46:46'),(100,0,1,'gender',NULL,1,NULL,NULL,'2024-04-18 15:46:46','2024-04-18 15:46:46','2024-04-18 15:46:46'),(101,0,1,'agent_relationship_specific_relator',NULL,1,NULL,NULL,'2024-04-18 15:46:57','2024-04-18 15:46:57','2024-04-18 15:46:57'),(102,0,1,'metadata_license',NULL,1,NULL,NULL,'2024-04-18 15:47:00','2024-04-18 15:47:00','2024-04-18 15:47:00');
/*!40000 ALTER TABLE `enumeration` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `enumeration_value`
--

DROP TABLE IF EXISTS `enumeration_value`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `enumeration_value` (
  `id` int NOT NULL AUTO_INCREMENT,
  `enumeration_id` int NOT NULL,
  `value` varchar(255) CHARACTER SET utf8mb3 COLLATE utf8mb3_bin NOT NULL,
  `readonly` int DEFAULT '0',
  `position` int NOT NULL DEFAULT '0',
  `suppressed` int DEFAULT '0',
  `lock_version` int NOT NULL DEFAULT '0',
  `json_schema_version` int NOT NULL DEFAULT '1',
  `created_by` varchar(255) CHARACTER SET utf8mb3 COLLATE utf8mb3_bin DEFAULT NULL,
  `last_modified_by` varchar(255) CHARACTER SET utf8mb3 COLLATE utf8mb3_bin DEFAULT NULL,
  `create_time` datetime DEFAULT NULL,
  `system_mtime` datetime DEFAULT NULL,
  `user_mtime` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `enumeration_value_uniq` (`enumeration_id`,`value`),
  UNIQUE KEY `enumeration_position_uniq` (`enumeration_id`,`position`),
  KEY `enumeration_value_enumeration_id_index` (`enumeration_id`),
  KEY `enumeration_value_value_index` (`value`),
  CONSTRAINT `enumeration_value_ibfk_1` FOREIGN KEY (`enumeration_id`) REFERENCES `enumeration` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=1796 DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_bin;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `enumeration_value`
--

LOCK TABLES `enumeration_value` WRITE;
/*!40000 ALTER TABLE `enumeration_value` DISABLE KEYS */;
INSERT INTO `enumeration_value` VALUES (1,1,'act',0,1,0,0,1,NULL,NULL,'2024-04-18 15:45:15','2024-04-18 15:45:15','2024-04-18 15:45:15'),(2,1,'adp',0,2,0,0,1,NULL,NULL,'2024-04-18 15:45:15','2024-04-18 15:45:15','2024-04-18 15:45:15'),(3,1,'anl',0,4,0,0,1,NULL,NULL,'2024-04-18 15:45:16','2024-04-18 15:45:16','2024-04-18 15:45:16'),(4,1,'anm',0,5,0,0,1,NULL,NULL,'2024-04-18 15:45:16','2024-04-18 15:45:16','2024-04-18 15:45:16'),(5,1,'ann',0,6,0,0,1,NULL,NULL,'2024-04-18 15:45:16','2024-04-18 15:45:16','2024-04-18 15:45:16'),(6,1,'app',0,8,0,0,1,NULL,NULL,'2024-04-18 15:45:16','2024-04-18 15:45:16','2024-04-18 15:45:16'),(7,1,'arc',0,10,0,0,1,NULL,NULL,'2024-04-18 15:45:16','2024-04-18 15:45:16','2024-04-18 15:45:16'),(8,1,'arr',0,12,0,0,1,NULL,NULL,'2024-04-18 15:45:16','2024-04-18 15:45:16','2024-04-18 15:45:16'),(9,1,'acp',0,0,0,0,1,NULL,NULL,'2024-04-18 15:45:15','2024-04-18 15:45:15','2024-04-18 15:45:15'),(10,1,'art',0,13,0,0,1,NULL,NULL,'2024-04-18 15:45:16','2024-04-18 15:45:16','2024-04-18 15:45:16'),(11,1,'ard',0,11,0,0,1,NULL,NULL,'2024-04-18 15:45:16','2024-04-18 15:45:16','2024-04-18 15:45:16'),(12,1,'asg',0,14,0,0,1,NULL,NULL,'2024-04-18 15:45:16','2024-04-18 15:45:16','2024-04-18 15:45:16'),(13,1,'asn',0,15,0,0,1,NULL,NULL,'2024-04-18 15:45:16','2024-04-18 15:45:16','2024-04-18 15:45:16'),(14,1,'att',0,16,0,0,1,NULL,NULL,'2024-04-18 15:45:16','2024-04-18 15:45:16','2024-04-18 15:45:16'),(15,1,'auc',0,17,0,0,1,NULL,NULL,'2024-04-18 15:45:16','2024-04-18 15:45:16','2024-04-18 15:45:16'),(16,1,'aut',0,21,0,0,1,NULL,NULL,'2024-04-18 15:45:16','2024-04-18 15:45:16','2024-04-18 15:45:16'),(17,1,'aqt',0,9,0,0,1,NULL,NULL,'2024-04-18 15:45:16','2024-04-18 15:45:16','2024-04-18 15:45:16'),(18,1,'aft',0,3,0,0,1,NULL,NULL,'2024-04-18 15:45:16','2024-04-18 15:45:16','2024-04-18 15:45:16'),(19,1,'aud',0,18,0,0,1,NULL,NULL,'2024-04-18 15:45:16','2024-04-18 15:45:16','2024-04-18 15:45:16'),(20,1,'aui',0,19,0,0,1,NULL,NULL,'2024-04-18 15:45:16','2024-04-18 15:45:16','2024-04-18 15:45:16'),(21,1,'aus',0,20,0,0,1,NULL,NULL,'2024-04-18 15:45:16','2024-04-18 15:45:16','2024-04-18 15:45:16'),(22,1,'ant',0,7,0,0,1,NULL,NULL,'2024-04-18 15:45:16','2024-04-18 15:45:16','2024-04-18 15:45:16'),(23,1,'bnd',0,27,0,0,1,NULL,NULL,'2024-04-18 15:45:16','2024-04-18 15:45:16','2024-04-18 15:45:16'),(24,1,'bdd',0,22,0,0,1,NULL,NULL,'2024-04-18 15:45:16','2024-04-18 15:45:16','2024-04-18 15:45:16'),(25,1,'blw',0,26,0,0,1,NULL,NULL,'2024-04-18 15:45:16','2024-04-18 15:45:16','2024-04-18 15:45:16'),(26,1,'bkd',0,24,0,0,1,NULL,NULL,'2024-04-18 15:45:16','2024-04-18 15:45:16','2024-04-18 15:45:16'),(27,1,'bkp',0,25,0,0,1,NULL,NULL,'2024-04-18 15:45:16','2024-04-18 15:45:16','2024-04-18 15:45:16'),(28,1,'bjd',0,23,0,0,1,NULL,NULL,'2024-04-18 15:45:16','2024-04-18 15:45:16','2024-04-18 15:45:16'),(29,1,'bpd',0,28,0,0,1,NULL,NULL,'2024-04-18 15:45:16','2024-04-18 15:45:16','2024-04-18 15:45:16'),(30,1,'bsl',0,29,0,0,1,NULL,NULL,'2024-04-18 15:45:16','2024-04-18 15:45:16','2024-04-18 15:45:16'),(31,1,'cll',0,34,0,0,1,NULL,NULL,'2024-04-18 15:45:16','2024-04-18 15:45:16','2024-04-18 15:45:16'),(32,1,'ctg',0,63,0,0,1,NULL,NULL,'2024-04-18 15:45:17','2024-04-18 15:45:17','2024-04-18 15:45:17'),(33,1,'cns',0,42,0,0,1,NULL,NULL,'2024-04-18 15:45:17','2024-04-18 15:45:17','2024-04-18 15:45:17'),(34,1,'chr',0,31,0,0,1,NULL,NULL,'2024-04-18 15:45:16','2024-04-18 15:45:16','2024-04-18 15:45:16'),(35,1,'cng',0,41,0,0,1,NULL,NULL,'2024-04-18 15:45:17','2024-04-18 15:45:17','2024-04-18 15:45:17'),(36,1,'cli',0,33,0,0,1,NULL,NULL,'2024-04-18 15:45:16','2024-04-18 15:45:16','2024-04-18 15:45:16'),(37,1,'clb',0,32,0,0,1,NULL,NULL,'2024-04-18 15:45:16','2024-04-18 15:45:16','2024-04-18 15:45:16'),(38,1,'col',0,44,0,0,1,NULL,NULL,'2024-04-18 15:45:17','2024-04-18 15:45:17','2024-04-18 15:45:17'),(39,1,'clt',0,36,0,0,1,NULL,NULL,'2024-04-18 15:45:16','2024-04-18 15:45:16','2024-04-18 15:45:16'),(40,1,'clr',0,35,0,0,1,NULL,NULL,'2024-04-18 15:45:16','2024-04-18 15:45:16','2024-04-18 15:45:16'),(41,1,'cmm',0,37,0,0,1,NULL,NULL,'2024-04-18 15:45:17','2024-04-18 15:45:17','2024-04-18 15:45:17'),(42,1,'cwt',0,68,0,0,1,NULL,NULL,'2024-04-18 15:45:17','2024-04-18 15:45:17','2024-04-18 15:45:17'),(43,1,'com',0,45,0,0,1,NULL,NULL,'2024-04-18 15:45:17','2024-04-18 15:45:17','2024-04-18 15:45:17'),(44,1,'cpl',0,53,0,0,1,NULL,NULL,'2024-04-18 15:45:17','2024-04-18 15:45:17','2024-04-18 15:45:17'),(45,1,'cpt',0,54,0,0,1,NULL,NULL,'2024-04-18 15:45:17','2024-04-18 15:45:17','2024-04-18 15:45:17'),(46,1,'cpe',0,51,0,0,1,NULL,NULL,'2024-04-18 15:45:17','2024-04-18 15:45:17','2024-04-18 15:45:17'),(47,1,'cmp',0,38,0,0,1,NULL,NULL,'2024-04-18 15:45:17','2024-04-18 15:45:17','2024-04-18 15:45:17'),(48,1,'cmt',0,39,0,0,1,NULL,NULL,'2024-04-18 15:45:17','2024-04-18 15:45:17','2024-04-18 15:45:17'),(49,1,'ccp',0,30,0,0,1,NULL,NULL,'2024-04-18 15:45:16','2024-04-18 15:45:16','2024-04-18 15:45:16'),(50,1,'cnd',0,40,0,0,1,NULL,NULL,'2024-04-18 15:45:17','2024-04-18 15:45:17','2024-04-18 15:45:17'),(51,1,'con',0,46,0,0,1,NULL,NULL,'2024-04-18 15:45:17','2024-04-18 15:45:17','2024-04-18 15:45:17'),(52,1,'csl',0,58,0,0,1,NULL,NULL,'2024-04-18 15:45:17','2024-04-18 15:45:17','2024-04-18 15:45:17'),(53,1,'csp',0,59,0,0,1,NULL,NULL,'2024-04-18 15:45:17','2024-04-18 15:45:17','2024-04-18 15:45:17'),(54,1,'cos',0,47,0,0,1,NULL,NULL,'2024-04-18 15:45:17','2024-04-18 15:45:17','2024-04-18 15:45:17'),(55,1,'cot',0,48,0,0,1,NULL,NULL,'2024-04-18 15:45:17','2024-04-18 15:45:17','2024-04-18 15:45:17'),(56,1,'coe',0,43,0,0,1,NULL,NULL,'2024-04-18 15:45:17','2024-04-18 15:45:17','2024-04-18 15:45:17'),(57,1,'cts',0,65,0,0,1,NULL,NULL,'2024-04-18 15:45:17','2024-04-18 15:45:17','2024-04-18 15:45:17'),(58,1,'ctt',0,66,0,0,1,NULL,NULL,'2024-04-18 15:45:17','2024-04-18 15:45:17','2024-04-18 15:45:17'),(59,1,'cte',0,62,0,0,1,NULL,NULL,'2024-04-18 15:45:17','2024-04-18 15:45:17','2024-04-18 15:45:17'),(60,1,'ctr',0,64,0,0,1,NULL,NULL,'2024-04-18 15:45:17','2024-04-18 15:45:17','2024-04-18 15:45:17'),(61,1,'ctb',0,61,0,0,1,NULL,NULL,'2024-04-18 15:45:17','2024-04-18 15:45:17','2024-04-18 15:45:17'),(62,1,'cpc',0,50,0,0,1,NULL,NULL,'2024-04-18 15:45:17','2024-04-18 15:45:17','2024-04-18 15:45:17'),(63,1,'cph',0,52,0,0,1,NULL,NULL,'2024-04-18 15:45:17','2024-04-18 15:45:17','2024-04-18 15:45:17'),(64,1,'crr',0,57,0,0,1,NULL,NULL,'2024-04-18 15:45:17','2024-04-18 15:45:17','2024-04-18 15:45:17'),(65,1,'crp',0,56,0,0,1,NULL,NULL,'2024-04-18 15:45:17','2024-04-18 15:45:17','2024-04-18 15:45:17'),(66,1,'cst',0,60,0,0,1,NULL,NULL,'2024-04-18 15:45:17','2024-04-18 15:45:17','2024-04-18 15:45:17'),(67,1,'cov',0,49,0,0,1,NULL,NULL,'2024-04-18 15:45:17','2024-04-18 15:45:17','2024-04-18 15:45:17'),(68,1,'cre',0,55,0,0,1,NULL,NULL,'2024-04-18 15:45:17','2024-04-18 15:45:17','2024-04-18 15:45:17'),(69,1,'cur',0,67,0,0,1,NULL,NULL,'2024-04-18 15:45:17','2024-04-18 15:45:17','2024-04-18 15:45:17'),(70,1,'dnc',0,76,0,0,1,NULL,NULL,'2024-04-18 15:45:18','2024-04-18 15:45:18','2024-04-18 15:45:18'),(71,1,'dtc',0,84,0,0,1,NULL,NULL,'2024-04-18 15:45:18','2024-04-18 15:45:18','2024-04-18 15:45:18'),(72,1,'dtm',0,86,0,0,1,NULL,NULL,'2024-04-18 15:45:18','2024-04-18 15:45:18','2024-04-18 15:45:18'),(73,1,'dte',0,85,0,0,1,NULL,NULL,'2024-04-18 15:45:18','2024-04-18 15:45:18','2024-04-18 15:45:18'),(74,1,'dto',0,87,0,0,1,NULL,NULL,'2024-04-18 15:45:18','2024-04-18 15:45:18','2024-04-18 15:45:18'),(75,1,'dfd',0,70,0,0,1,NULL,NULL,'2024-04-18 15:45:17','2024-04-18 15:45:17','2024-04-18 15:45:17'),(76,1,'dft',0,72,0,0,1,NULL,NULL,'2024-04-18 15:45:17','2024-04-18 15:45:17','2024-04-18 15:45:17'),(77,1,'dfe',0,71,0,0,1,NULL,NULL,'2024-04-18 15:45:17','2024-04-18 15:45:17','2024-04-18 15:45:17'),(78,1,'dgg',0,73,0,0,1,NULL,NULL,'2024-04-18 15:45:18','2024-04-18 15:45:18','2024-04-18 15:45:18'),(79,1,'dln',0,75,0,0,1,NULL,NULL,'2024-04-18 15:45:18','2024-04-18 15:45:18','2024-04-18 15:45:18'),(80,1,'dpc',0,78,0,0,1,NULL,NULL,'2024-04-18 15:45:18','2024-04-18 15:45:18','2024-04-18 15:45:18'),(81,1,'dpt',0,79,0,0,1,NULL,NULL,'2024-04-18 15:45:18','2024-04-18 15:45:18','2024-04-18 15:45:18'),(82,1,'dsr',0,82,0,0,1,NULL,NULL,'2024-04-18 15:45:18','2024-04-18 15:45:18','2024-04-18 15:45:18'),(83,1,'drt',0,81,0,0,1,NULL,NULL,'2024-04-18 15:45:18','2024-04-18 15:45:18','2024-04-18 15:45:18'),(84,1,'dis',0,74,0,0,1,NULL,NULL,'2024-04-18 15:45:18','2024-04-18 15:45:18','2024-04-18 15:45:18'),(85,1,'dbp',0,69,0,0,1,NULL,NULL,'2024-04-18 15:45:17','2024-04-18 15:45:17','2024-04-18 15:45:17'),(86,1,'dst',0,83,0,0,1,NULL,NULL,'2024-04-18 15:45:18','2024-04-18 15:45:18','2024-04-18 15:45:18'),(87,1,'drm',0,80,0,0,1,NULL,NULL,'2024-04-18 15:45:18','2024-04-18 15:45:18','2024-04-18 15:45:18'),(88,1,'dub',0,88,0,0,1,NULL,NULL,'2024-04-18 15:45:18','2024-04-18 15:45:18','2024-04-18 15:45:18'),(89,1,'edt',0,89,0,0,1,NULL,NULL,'2024-04-18 15:45:18','2024-04-18 15:45:18','2024-04-18 15:45:18'),(90,1,'elg',0,91,0,0,1,NULL,NULL,'2024-04-18 15:45:18','2024-04-18 15:45:18','2024-04-18 15:45:18'),(91,1,'elt',0,92,0,0,1,NULL,NULL,'2024-04-18 15:45:18','2024-04-18 15:45:18','2024-04-18 15:45:18'),(92,1,'eng',0,93,0,0,1,NULL,NULL,'2024-04-18 15:45:18','2024-04-18 15:45:18','2024-04-18 15:45:18'),(93,1,'egr',0,90,0,0,1,NULL,NULL,'2024-04-18 15:45:18','2024-04-18 15:45:18','2024-04-18 15:45:18'),(94,1,'etr',0,94,0,0,1,NULL,NULL,'2024-04-18 15:45:18','2024-04-18 15:45:18','2024-04-18 15:45:18'),(95,1,'evp',0,95,0,0,1,NULL,NULL,'2024-04-18 15:45:18','2024-04-18 15:45:18','2024-04-18 15:45:18'),(96,1,'exp',0,96,0,0,1,NULL,NULL,'2024-04-18 15:45:18','2024-04-18 15:45:18','2024-04-18 15:45:18'),(97,1,'fac',0,97,0,0,1,NULL,NULL,'2024-04-18 15:45:18','2024-04-18 15:45:18','2024-04-18 15:45:18'),(98,1,'fld',0,98,0,0,1,NULL,NULL,'2024-04-18 15:45:18','2024-04-18 15:45:18','2024-04-18 15:45:18'),(99,1,'flm',0,99,0,0,1,NULL,NULL,'2024-04-18 15:45:18','2024-04-18 15:45:18','2024-04-18 15:45:18'),(100,1,'fpy',0,102,0,0,1,NULL,NULL,'2024-04-18 15:45:18','2024-04-18 15:45:18','2024-04-18 15:45:18'),(101,1,'frg',0,103,0,0,1,NULL,NULL,'2024-04-18 15:45:18','2024-04-18 15:45:18','2024-04-18 15:45:18'),(102,1,'fmo',0,100,0,0,1,NULL,NULL,'2024-04-18 15:45:18','2024-04-18 15:45:18','2024-04-18 15:45:18'),(103,1,'dnr',0,77,0,0,1,NULL,NULL,'2024-04-18 15:45:18','2024-04-18 15:45:18','2024-04-18 15:45:18'),(104,1,'fnd',0,101,0,0,1,NULL,NULL,'2024-04-18 15:45:18','2024-04-18 15:45:18','2024-04-18 15:45:18'),(105,1,'gis',0,104,0,0,1,NULL,NULL,'2024-04-18 15:45:18','2024-04-18 15:45:18','2024-04-18 15:45:18'),(106,1,'grt',0,105,0,0,1,NULL,NULL,'2024-04-18 15:45:18','2024-04-18 15:45:18','2024-04-18 15:45:18'),(107,1,'hnr',0,106,0,0,1,NULL,NULL,'2024-04-18 15:45:18','2024-04-18 15:45:18','2024-04-18 15:45:18'),(108,1,'hst',0,107,0,0,1,NULL,NULL,'2024-04-18 15:45:19','2024-04-18 15:45:19','2024-04-18 15:45:19'),(109,1,'ilu',0,109,0,0,1,NULL,NULL,'2024-04-18 15:45:19','2024-04-18 15:45:19','2024-04-18 15:45:19'),(110,1,'ill',0,108,0,0,1,NULL,NULL,'2024-04-18 15:45:19','2024-04-18 15:45:19','2024-04-18 15:45:19'),(111,1,'ins',0,110,0,0,1,NULL,NULL,'2024-04-18 15:45:19','2024-04-18 15:45:19','2024-04-18 15:45:19'),(112,1,'itr',0,112,0,0,1,NULL,NULL,'2024-04-18 15:45:19','2024-04-18 15:45:19','2024-04-18 15:45:19'),(113,1,'ive',0,113,0,0,1,NULL,NULL,'2024-04-18 15:45:19','2024-04-18 15:45:19','2024-04-18 15:45:19'),(114,1,'ivr',0,114,0,0,1,NULL,NULL,'2024-04-18 15:45:19','2024-04-18 15:45:19','2024-04-18 15:45:19'),(115,1,'inv',0,111,0,0,1,NULL,NULL,'2024-04-18 15:45:19','2024-04-18 15:45:19','2024-04-18 15:45:19'),(116,1,'lbr',0,115,0,0,1,NULL,NULL,'2024-04-18 15:45:19','2024-04-18 15:45:19','2024-04-18 15:45:19'),(117,1,'ldr',0,117,0,0,1,NULL,NULL,'2024-04-18 15:45:19','2024-04-18 15:45:19','2024-04-18 15:45:19'),(118,1,'lsa',0,127,0,0,1,NULL,NULL,'2024-04-18 15:45:19','2024-04-18 15:45:19','2024-04-18 15:45:19'),(119,1,'led',0,118,0,0,1,NULL,NULL,'2024-04-18 15:45:19','2024-04-18 15:45:19','2024-04-18 15:45:19'),(120,1,'len',0,121,0,0,1,NULL,NULL,'2024-04-18 15:45:19','2024-04-18 15:45:19','2024-04-18 15:45:19'),(121,1,'lil',0,125,0,0,1,NULL,NULL,'2024-04-18 15:45:19','2024-04-18 15:45:19','2024-04-18 15:45:19'),(122,1,'lit',0,126,0,0,1,NULL,NULL,'2024-04-18 15:45:19','2024-04-18 15:45:19','2024-04-18 15:45:19'),(123,1,'lie',0,124,0,0,1,NULL,NULL,'2024-04-18 15:45:19','2024-04-18 15:45:19','2024-04-18 15:45:19'),(124,1,'lel',0,120,0,0,1,NULL,NULL,'2024-04-18 15:45:19','2024-04-18 15:45:19','2024-04-18 15:45:19'),(125,1,'let',0,122,0,0,1,NULL,NULL,'2024-04-18 15:45:19','2024-04-18 15:45:19','2024-04-18 15:45:19'),(126,1,'lee',0,119,0,0,1,NULL,NULL,'2024-04-18 15:45:19','2024-04-18 15:45:19','2024-04-18 15:45:19'),(127,1,'lbt',0,116,0,0,1,NULL,NULL,'2024-04-18 15:45:19','2024-04-18 15:45:19','2024-04-18 15:45:19'),(128,1,'lse',0,128,0,0,1,NULL,NULL,'2024-04-18 15:45:19','2024-04-18 15:45:19','2024-04-18 15:45:19'),(129,1,'lso',0,129,0,0,1,NULL,NULL,'2024-04-18 15:45:19','2024-04-18 15:45:19','2024-04-18 15:45:19'),(130,1,'lgd',0,123,0,0,1,NULL,NULL,'2024-04-18 15:45:19','2024-04-18 15:45:19','2024-04-18 15:45:19'),(131,1,'ltg',0,130,0,0,1,NULL,NULL,'2024-04-18 15:45:19','2024-04-18 15:45:19','2024-04-18 15:45:19'),(132,1,'lyr',0,131,0,0,1,NULL,NULL,'2024-04-18 15:45:19','2024-04-18 15:45:19','2024-04-18 15:45:19'),(133,1,'mfp',0,134,0,0,1,NULL,NULL,'2024-04-18 15:45:19','2024-04-18 15:45:19','2024-04-18 15:45:19'),(134,1,'mfr',0,135,0,0,1,NULL,NULL,'2024-04-18 15:45:19','2024-04-18 15:45:19','2024-04-18 15:45:19'),(135,1,'mrb',0,138,0,0,1,NULL,NULL,'2024-04-18 15:45:19','2024-04-18 15:45:19','2024-04-18 15:45:19'),(136,1,'mrk',0,139,0,0,1,NULL,NULL,'2024-04-18 15:45:19','2024-04-18 15:45:19','2024-04-18 15:45:19'),(137,1,'mdc',0,133,0,0,1,NULL,NULL,'2024-04-18 15:45:19','2024-04-18 15:45:19','2024-04-18 15:45:19'),(138,1,'mte',0,141,0,0,1,NULL,NULL,'2024-04-18 15:45:19','2024-04-18 15:45:19','2024-04-18 15:45:19'),(139,1,'mod',0,136,0,0,1,NULL,NULL,'2024-04-18 15:45:19','2024-04-18 15:45:19','2024-04-18 15:45:19'),(140,1,'mon',0,137,0,0,1,NULL,NULL,'2024-04-18 15:45:19','2024-04-18 15:45:19','2024-04-18 15:45:19'),(141,1,'mcp',0,132,0,0,1,NULL,NULL,'2024-04-18 15:45:19','2024-04-18 15:45:19','2024-04-18 15:45:19'),(142,1,'msd',0,140,0,0,1,NULL,NULL,'2024-04-18 15:45:19','2024-04-18 15:45:19','2024-04-18 15:45:19'),(143,1,'mus',0,142,0,0,1,NULL,NULL,'2024-04-18 15:45:20','2024-04-18 15:45:20','2024-04-18 15:45:20'),(144,1,'nrt',0,143,0,0,1,NULL,NULL,'2024-04-18 15:45:20','2024-04-18 15:45:20','2024-04-18 15:45:20'),(145,1,'opn',0,144,0,0,1,NULL,NULL,'2024-04-18 15:45:20','2024-04-18 15:45:20','2024-04-18 15:45:20'),(146,1,'orm',0,146,0,0,1,NULL,NULL,'2024-04-18 15:45:20','2024-04-18 15:45:20','2024-04-18 15:45:20'),(147,1,'org',0,145,0,0,1,NULL,NULL,'2024-04-18 15:45:20','2024-04-18 15:45:20','2024-04-18 15:45:20'),(148,1,'oth',0,147,0,0,1,NULL,NULL,'2024-04-18 15:45:20','2024-04-18 15:45:20','2024-04-18 15:45:20'),(149,1,'own',0,148,0,0,1,NULL,NULL,'2024-04-18 15:45:20','2024-04-18 15:45:20','2024-04-18 15:45:20'),(150,1,'ppm',0,159,0,0,1,NULL,NULL,'2024-04-18 15:45:20','2024-04-18 15:45:20','2024-04-18 15:45:20'),(151,1,'pta',0,170,0,0,1,NULL,NULL,'2024-04-18 15:45:20','2024-04-18 15:45:20','2024-04-18 15:45:20'),(152,1,'pth',0,173,0,0,1,NULL,NULL,'2024-04-18 15:45:20','2024-04-18 15:45:20','2024-04-18 15:45:20'),(153,1,'pat',0,149,0,0,1,NULL,NULL,'2024-04-18 15:45:20','2024-04-18 15:45:20','2024-04-18 15:45:20'),(154,1,'prf',0,163,0,0,1,NULL,NULL,'2024-04-18 15:45:20','2024-04-18 15:45:20','2024-04-18 15:45:20'),(155,1,'pma',0,156,0,0,1,NULL,NULL,'2024-04-18 15:45:20','2024-04-18 15:45:20','2024-04-18 15:45:20'),(156,1,'pht',0,154,0,0,1,NULL,NULL,'2024-04-18 15:45:20','2024-04-18 15:45:20','2024-04-18 15:45:20'),(157,1,'ptf',0,172,0,0,1,NULL,NULL,'2024-04-18 15:45:20','2024-04-18 15:45:20','2024-04-18 15:45:20'),(158,1,'ptt',0,174,0,0,1,NULL,NULL,'2024-04-18 15:45:20','2024-04-18 15:45:20','2024-04-18 15:45:20'),(159,1,'pte',0,171,0,0,1,NULL,NULL,'2024-04-18 15:45:20','2024-04-18 15:45:20','2024-04-18 15:45:20'),(160,1,'plt',0,155,0,0,1,NULL,NULL,'2024-04-18 15:45:20','2024-04-18 15:45:20','2024-04-18 15:45:20'),(161,1,'prt',0,168,0,0,1,NULL,NULL,'2024-04-18 15:45:20','2024-04-18 15:45:20','2024-04-18 15:45:20'),(162,1,'pop',0,158,0,0,1,NULL,NULL,'2024-04-18 15:45:20','2024-04-18 15:45:20','2024-04-18 15:45:20'),(163,1,'prm',0,165,0,0,1,NULL,NULL,'2024-04-18 15:45:20','2024-04-18 15:45:20','2024-04-18 15:45:20'),(164,1,'prc',0,161,0,0,1,NULL,NULL,'2024-04-18 15:45:20','2024-04-18 15:45:20','2024-04-18 15:45:20'),(165,1,'pro',0,166,0,0,1,NULL,NULL,'2024-04-18 15:45:20','2024-04-18 15:45:20','2024-04-18 15:45:20'),(166,1,'pmn',0,157,0,0,1,NULL,NULL,'2024-04-18 15:45:20','2024-04-18 15:45:20','2024-04-18 15:45:20'),(167,1,'prd',0,162,0,0,1,NULL,NULL,'2024-04-18 15:45:20','2024-04-18 15:45:20','2024-04-18 15:45:20'),(168,1,'prp',0,167,0,0,1,NULL,NULL,'2024-04-18 15:45:20','2024-04-18 15:45:20','2024-04-18 15:45:20'),(169,1,'prg',0,164,0,0,1,NULL,NULL,'2024-04-18 15:45:20','2024-04-18 15:45:20','2024-04-18 15:45:20'),(170,1,'pdr',0,152,0,0,1,NULL,NULL,'2024-04-18 15:45:20','2024-04-18 15:45:20','2024-04-18 15:45:20'),(171,1,'pfr',0,153,0,0,1,NULL,NULL,'2024-04-18 15:45:20','2024-04-18 15:45:20','2024-04-18 15:45:20'),(172,1,'prv',0,169,0,0,1,NULL,NULL,'2024-04-18 15:45:20','2024-04-18 15:45:20','2024-04-18 15:45:20'),(173,1,'pup',0,175,0,0,1,NULL,NULL,'2024-04-18 15:45:20','2024-04-18 15:45:20','2024-04-18 15:45:20'),(174,1,'pbl',0,151,0,0,1,NULL,NULL,'2024-04-18 15:45:20','2024-04-18 15:45:20','2024-04-18 15:45:20'),(175,1,'pbd',0,150,0,0,1,NULL,NULL,'2024-04-18 15:45:20','2024-04-18 15:45:20','2024-04-18 15:45:20'),(176,1,'ppt',0,160,0,0,1,NULL,NULL,'2024-04-18 15:45:20','2024-04-18 15:45:20','2024-04-18 15:45:20'),(177,1,'rcp',0,179,0,0,1,NULL,NULL,'2024-04-18 15:45:21','2024-04-18 15:45:21','2024-04-18 15:45:21'),(178,1,'rce',0,178,0,0,1,NULL,NULL,'2024-04-18 15:45:21','2024-04-18 15:45:21','2024-04-18 15:45:21'),(179,1,'rcd',0,177,0,0,1,NULL,NULL,'2024-04-18 15:45:21','2024-04-18 15:45:21','2024-04-18 15:45:21'),(180,1,'red',0,180,0,0,1,NULL,NULL,'2024-04-18 15:45:21','2024-04-18 15:45:21','2024-04-18 15:45:21'),(181,1,'ren',0,181,0,0,1,NULL,NULL,'2024-04-18 15:45:21','2024-04-18 15:45:21','2024-04-18 15:45:21'),(182,1,'rpt',0,185,0,0,1,NULL,NULL,'2024-04-18 15:45:21','2024-04-18 15:45:21','2024-04-18 15:45:21'),(183,1,'rps',0,184,0,0,1,NULL,NULL,'2024-04-18 15:45:21','2024-04-18 15:45:21','2024-04-18 15:45:21'),(184,1,'rth',0,191,0,0,1,NULL,NULL,'2024-04-18 15:45:21','2024-04-18 15:45:21','2024-04-18 15:45:21'),(185,1,'rtm',0,192,0,0,1,NULL,NULL,'2024-04-18 15:45:21','2024-04-18 15:45:21','2024-04-18 15:45:21'),(186,1,'res',0,182,0,0,1,NULL,NULL,'2024-04-18 15:45:21','2024-04-18 15:45:21','2024-04-18 15:45:21'),(187,1,'rsp',0,189,0,0,1,NULL,NULL,'2024-04-18 15:45:21','2024-04-18 15:45:21','2024-04-18 15:45:21'),(188,1,'rst',0,190,0,0,1,NULL,NULL,'2024-04-18 15:45:21','2024-04-18 15:45:21','2024-04-18 15:45:21'),(189,1,'rse',0,187,0,0,1,NULL,NULL,'2024-04-18 15:45:21','2024-04-18 15:45:21','2024-04-18 15:45:21'),(190,1,'rpy',0,186,0,0,1,NULL,NULL,'2024-04-18 15:45:21','2024-04-18 15:45:21','2024-04-18 15:45:21'),(191,1,'rsg',0,188,0,0,1,NULL,NULL,'2024-04-18 15:45:21','2024-04-18 15:45:21','2024-04-18 15:45:21'),(192,1,'rev',0,183,0,0,1,NULL,NULL,'2024-04-18 15:45:21','2024-04-18 15:45:21','2024-04-18 15:45:21'),(193,1,'rbr',0,176,0,0,1,NULL,NULL,'2024-04-18 15:45:21','2024-04-18 15:45:21','2024-04-18 15:45:21'),(194,1,'sce',0,194,0,0,1,NULL,NULL,'2024-04-18 15:45:21','2024-04-18 15:45:21','2024-04-18 15:45:21'),(195,1,'sad',0,193,0,0,1,NULL,NULL,'2024-04-18 15:45:21','2024-04-18 15:45:21','2024-04-18 15:45:21'),(196,1,'scr',0,196,0,0,1,NULL,NULL,'2024-04-18 15:45:21','2024-04-18 15:45:21','2024-04-18 15:45:21'),(197,1,'scl',0,195,0,0,1,NULL,NULL,'2024-04-18 15:45:21','2024-04-18 15:45:21','2024-04-18 15:45:21'),(198,1,'spy',0,204,0,0,1,NULL,NULL,'2024-04-18 15:45:21','2024-04-18 15:45:21','2024-04-18 15:45:21'),(199,1,'sec',0,198,0,0,1,NULL,NULL,'2024-04-18 15:45:21','2024-04-18 15:45:21','2024-04-18 15:45:21'),(200,1,'std',0,206,0,0,1,NULL,NULL,'2024-04-18 15:45:21','2024-04-18 15:45:21','2024-04-18 15:45:21'),(201,1,'stg',0,207,0,0,1,NULL,NULL,'2024-04-18 15:45:21','2024-04-18 15:45:21','2024-04-18 15:45:21'),(202,1,'sgn',0,199,0,0,1,NULL,NULL,'2024-04-18 15:45:21','2024-04-18 15:45:21','2024-04-18 15:45:21'),(203,1,'sng',0,201,0,0,1,NULL,NULL,'2024-04-18 15:45:21','2024-04-18 15:45:21','2024-04-18 15:45:21'),(204,1,'sds',0,197,0,0,1,NULL,NULL,'2024-04-18 15:45:21','2024-04-18 15:45:21','2024-04-18 15:45:21'),(205,1,'spk',0,202,0,0,1,NULL,NULL,'2024-04-18 15:45:21','2024-04-18 15:45:21','2024-04-18 15:45:21'),(206,1,'spn',0,203,0,0,1,NULL,NULL,'2024-04-18 15:45:21','2024-04-18 15:45:21','2024-04-18 15:45:21'),(207,1,'stm',0,209,0,0,1,NULL,NULL,'2024-04-18 15:45:21','2024-04-18 15:45:21','2024-04-18 15:45:21'),(208,1,'stn',0,210,0,0,1,NULL,NULL,'2024-04-18 15:45:21','2024-04-18 15:45:21','2024-04-18 15:45:21'),(209,1,'str',0,211,0,0,1,NULL,NULL,'2024-04-18 15:45:22','2024-04-18 15:45:22','2024-04-18 15:45:22'),(210,1,'stl',0,208,0,0,1,NULL,NULL,'2024-04-18 15:45:21','2024-04-18 15:45:21','2024-04-18 15:45:21'),(211,1,'sht',0,200,0,0,1,NULL,NULL,'2024-04-18 15:45:21','2024-04-18 15:45:21','2024-04-18 15:45:21'),(212,1,'srv',0,205,0,0,1,NULL,NULL,'2024-04-18 15:45:21','2024-04-18 15:45:21','2024-04-18 15:45:21'),(213,1,'tch',0,213,0,0,1,NULL,NULL,'2024-04-18 15:45:22','2024-04-18 15:45:22','2024-04-18 15:45:22'),(214,1,'tcd',0,212,0,0,1,NULL,NULL,'2024-04-18 15:45:22','2024-04-18 15:45:22','2024-04-18 15:45:22'),(215,1,'ths',0,214,0,0,1,NULL,NULL,'2024-04-18 15:45:22','2024-04-18 15:45:22','2024-04-18 15:45:22'),(216,1,'trc',0,215,0,0,1,NULL,NULL,'2024-04-18 15:45:22','2024-04-18 15:45:22','2024-04-18 15:45:22'),(217,1,'trl',0,216,0,0,1,NULL,NULL,'2024-04-18 15:45:22','2024-04-18 15:45:22','2024-04-18 15:45:22'),(218,1,'tyd',0,217,0,0,1,NULL,NULL,'2024-04-18 15:45:22','2024-04-18 15:45:22','2024-04-18 15:45:22'),(219,1,'tyg',0,218,0,0,1,NULL,NULL,'2024-04-18 15:45:22','2024-04-18 15:45:22','2024-04-18 15:45:22'),(220,1,'uvp',0,219,0,0,1,NULL,NULL,'2024-04-18 15:45:22','2024-04-18 15:45:22','2024-04-18 15:45:22'),(221,1,'vdg',0,220,0,0,1,NULL,NULL,'2024-04-18 15:45:22','2024-04-18 15:45:22','2024-04-18 15:45:22'),(222,1,'voc',0,221,0,0,1,NULL,NULL,'2024-04-18 15:45:22','2024-04-18 15:45:22','2024-04-18 15:45:22'),(223,1,'wit',0,225,0,0,1,NULL,NULL,'2024-04-18 15:45:22','2024-04-18 15:45:22','2024-04-18 15:45:22'),(224,1,'wde',0,224,0,0,1,NULL,NULL,'2024-04-18 15:45:22','2024-04-18 15:45:22','2024-04-18 15:45:22'),(225,1,'wdc',0,223,0,0,1,NULL,NULL,'2024-04-18 15:45:22','2024-04-18 15:45:22','2024-04-18 15:45:22'),(226,1,'wam',0,222,0,0,1,NULL,NULL,'2024-04-18 15:45:22','2024-04-18 15:45:22','2024-04-18 15:45:22'),(227,2,'source',0,1,0,0,1,NULL,NULL,'2024-04-18 15:45:28','2024-04-18 15:45:28','2024-04-18 15:45:28'),(228,2,'outcome',0,0,0,0,1,NULL,NULL,'2024-04-18 15:45:28','2024-04-18 15:45:28','2024-04-18 15:45:28'),(229,2,'transfer',0,2,0,0,1,NULL,NULL,'2024-04-18 15:45:28','2024-04-18 15:45:28','2024-04-18 15:45:28'),(230,3,'authorizer',0,0,0,0,1,NULL,NULL,'2024-04-18 15:45:23','2024-04-18 15:45:23','2024-04-18 15:45:23'),(231,3,'executing_program',0,1,0,0,1,NULL,NULL,'2024-04-18 15:45:24','2024-04-18 15:45:24','2024-04-18 15:45:24'),(232,3,'implementer',0,2,0,0,1,NULL,NULL,'2024-04-18 15:45:24','2024-04-18 15:45:24','2024-04-18 15:45:24'),(233,3,'recipient',0,3,0,0,1,NULL,NULL,'2024-04-18 15:45:24','2024-04-18 15:45:24','2024-04-18 15:45:24'),(234,3,'transmitter',0,4,0,0,1,NULL,NULL,'2024-04-18 15:45:24','2024-04-18 15:45:24','2024-04-18 15:45:24'),(235,3,'validator',0,5,0,0,1,NULL,NULL,'2024-04-18 15:45:24','2024-04-18 15:45:24','2024-04-18 15:45:24'),(236,4,'local',0,0,0,0,1,NULL,NULL,'2024-04-18 15:45:27','2024-04-18 15:45:27','2024-04-18 15:45:27'),(237,4,'naf',0,2,0,0,1,NULL,NULL,'2024-04-18 15:45:27','2024-04-18 15:45:27','2024-04-18 15:45:27'),(238,4,'nad',0,1,0,0,1,NULL,NULL,'2024-04-18 15:45:27','2024-04-18 15:45:27','2024-04-18 15:45:27'),(239,4,'ulan',0,3,0,0,1,NULL,NULL,'2024-04-18 15:45:27','2024-04-18 15:45:27','2024-04-18 15:45:27'),(240,5,'local',0,2,0,0,1,NULL,NULL,'2024-04-18 15:44:59','2024-04-18 15:44:59','2024-04-18 15:44:59'),(241,5,'aacr',0,0,0,0,1,NULL,NULL,'2024-04-18 15:44:59','2024-04-18 15:44:59','2024-04-18 15:44:59'),(242,5,'dacs',0,1,0,0,1,NULL,NULL,'2024-04-18 15:44:59','2024-04-18 15:44:59','2024-04-18 15:44:59'),(243,5,'rda',0,3,0,0,1,NULL,NULL,'2024-04-18 15:44:59','2024-04-18 15:44:59','2024-04-18 15:44:59'),(244,6,'deposit',0,0,0,0,1,NULL,NULL,'2024-04-18 15:45:26','2024-04-18 15:45:26','2024-04-18 15:45:26'),(245,6,'gift',0,1,0,0,1,NULL,NULL,'2024-04-18 15:45:26','2024-04-18 15:45:26','2024-04-18 15:45:26'),(246,6,'purchase',0,2,0,0,1,NULL,NULL,'2024-04-18 15:45:26','2024-04-18 15:45:26','2024-04-18 15:45:26'),(247,6,'transfer',0,3,0,0,1,NULL,NULL,'2024-04-18 15:45:26','2024-04-18 15:45:26','2024-04-18 15:45:26'),(248,7,'collection',0,0,0,0,1,NULL,NULL,'2024-04-18 15:45:25','2024-04-18 15:45:25','2024-04-18 15:45:25'),(249,7,'publications',0,2,0,0,1,NULL,NULL,'2024-04-18 15:45:25','2024-04-18 15:45:25','2024-04-18 15:45:25'),(250,7,'papers',0,1,0,0,1,NULL,NULL,'2024-04-18 15:45:25','2024-04-18 15:45:25','2024-04-18 15:45:25'),(251,7,'records',0,3,0,0,1,NULL,NULL,'2024-04-18 15:45:25','2024-04-18 15:45:25','2024-04-18 15:45:25'),(252,8,'high',0,0,0,0,1,NULL,NULL,'2024-04-18 15:45:27','2024-04-18 15:45:27','2024-04-18 15:45:27'),(253,8,'medium',0,2,0,0,1,NULL,NULL,'2024-04-18 15:45:27','2024-04-18 15:45:27','2024-04-18 15:45:27'),(254,8,'low',0,1,0,0,1,NULL,NULL,'2024-04-18 15:45:27','2024-04-18 15:45:27','2024-04-18 15:45:27'),(255,9,'new',0,2,0,0,1,NULL,NULL,'2024-04-18 15:45:25','2024-04-18 15:45:25','2024-04-18 15:45:25'),(256,9,'in_progress',0,1,0,0,1,NULL,NULL,'2024-04-18 15:45:25','2024-04-18 15:45:25','2024-04-18 15:45:25'),(257,9,'completed',0,0,0,0,1,NULL,NULL,'2024-04-18 15:45:25','2024-04-18 15:45:25','2024-04-18 15:45:25'),(258,10,'ce',0,0,0,0,1,NULL,NULL,'2024-04-18 15:45:25','2024-04-18 15:45:25','2024-04-18 15:45:25'),(259,11,'gregorian',0,0,0,0,1,NULL,NULL,'2024-04-18 15:45:27','2024-04-18 15:45:27','2024-04-18 15:45:27'),(260,12,'cartographic',0,0,0,0,1,NULL,NULL,'2024-04-18 15:45:24','2024-04-18 15:45:24','2024-04-18 15:45:24'),(261,12,'mixed_materials',0,1,0,0,1,NULL,NULL,'2024-04-18 15:45:24','2024-04-18 15:45:24','2024-04-18 15:45:24'),(262,12,'moving_image',0,2,0,0,1,NULL,NULL,'2024-04-18 15:45:24','2024-04-18 15:45:24','2024-04-18 15:45:24'),(263,12,'notated_music',0,3,0,0,1,NULL,NULL,'2024-04-18 15:45:24','2024-04-18 15:45:24','2024-04-18 15:45:24'),(264,12,'software_multimedia',0,4,0,0,1,NULL,NULL,'2024-04-18 15:45:24','2024-04-18 15:45:24','2024-04-18 15:45:24'),(265,12,'sound_recording',0,5,0,0,1,NULL,NULL,'2024-04-18 15:45:24','2024-04-18 15:45:24','2024-04-18 15:45:24'),(266,12,'sound_recording_musical',0,6,0,0,1,NULL,NULL,'2024-04-18 15:45:24','2024-04-18 15:45:24','2024-04-18 15:45:24'),(267,12,'sound_recording_nonmusical',0,7,0,0,1,NULL,NULL,'2024-04-18 15:45:24','2024-04-18 15:45:24','2024-04-18 15:45:24'),(268,12,'still_image',0,8,0,0,1,NULL,NULL,'2024-04-18 15:45:24','2024-04-18 15:45:24','2024-04-18 15:45:24'),(269,12,'text',0,9,0,0,1,NULL,NULL,'2024-04-18 15:45:24','2024-04-18 15:45:24','2024-04-18 15:45:24'),(270,13,'collection',0,0,0,0,1,NULL,NULL,'2024-04-18 15:45:25','2024-04-18 15:45:25','2024-04-18 15:45:25'),(271,13,'work',0,2,0,0,1,NULL,NULL,'2024-04-18 15:45:25','2024-04-18 15:45:25','2024-04-18 15:45:25'),(272,13,'image',0,1,0,0,1,NULL,NULL,'2024-04-18 15:45:25','2024-04-18 15:45:25','2024-04-18 15:45:25'),(273,14,'cassettes',0,0,0,0,1,NULL,NULL,'2024-04-18 15:45:24','2024-04-18 15:45:24','2024-04-18 15:45:24'),(274,14,'cubic_feet',0,1,0,0,1,NULL,NULL,'2024-04-18 15:45:24','2024-04-18 15:45:24','2024-04-18 15:45:24'),(275,14,'gigabytes',0,2,0,0,1,NULL,NULL,'2024-04-18 15:45:24','2024-04-18 15:45:24','2024-04-18 15:45:24'),(276,14,'leaves',0,3,0,0,1,NULL,NULL,'2024-04-18 15:45:24','2024-04-18 15:45:24','2024-04-18 15:45:24'),(277,14,'linear_feet',0,4,0,0,1,NULL,NULL,'2024-04-18 15:45:24','2024-04-18 15:45:24','2024-04-18 15:45:24'),(278,14,'megabytes',0,5,0,0,1,NULL,NULL,'2024-04-18 15:45:24','2024-04-18 15:45:24','2024-04-18 15:45:24'),(279,14,'photographic_prints',0,6,0,0,1,NULL,NULL,'2024-04-18 15:45:24','2024-04-18 15:45:24','2024-04-18 15:45:24'),(280,14,'photographic_slides',0,7,0,0,1,NULL,NULL,'2024-04-18 15:45:24','2024-04-18 15:45:24','2024-04-18 15:45:24'),(281,14,'reels',0,8,0,0,1,NULL,NULL,'2024-04-18 15:45:24','2024-04-18 15:45:24','2024-04-18 15:45:24'),(282,14,'sheets',0,9,0,0,1,NULL,NULL,'2024-04-18 15:45:24','2024-04-18 15:45:24','2024-04-18 15:45:24'),(283,14,'terabytes',0,10,0,0,1,NULL,NULL,'2024-04-18 15:45:25','2024-04-18 15:45:25','2024-04-18 15:45:25'),(284,14,'volumes',0,11,0,0,1,NULL,NULL,'2024-04-18 15:45:25','2024-04-18 15:45:25','2024-04-18 15:45:25'),(285,15,'accession',0,0,0,0,1,NULL,NULL,'2024-04-18 15:45:13','2024-04-18 15:45:13','2024-04-18 15:45:13'),(286,15,'accumulation',0,1,0,0,1,NULL,NULL,'2024-04-18 15:45:13','2024-04-18 15:45:13','2024-04-18 15:45:13'),(287,15,'acknowledgement_sent',0,3,0,0,1,NULL,NULL,'2024-04-18 15:45:13','2024-04-18 15:45:13','2024-04-18 15:45:13'),(288,15,'acknowledgement_received',0,2,0,0,1,NULL,NULL,'2024-04-18 15:45:13','2024-04-18 15:45:13','2024-04-18 15:45:13'),(289,15,'agreement_signed',0,6,0,0,1,NULL,NULL,'2024-04-18 15:45:13','2024-04-18 15:45:13','2024-04-18 15:45:13'),(290,15,'agreement_received',0,4,0,0,1,NULL,NULL,'2024-04-18 15:45:13','2024-04-18 15:45:13','2024-04-18 15:45:13'),(291,15,'agreement_sent',0,5,0,0,1,NULL,NULL,'2024-04-18 15:45:13','2024-04-18 15:45:13','2024-04-18 15:45:13'),(292,15,'appraisal',0,7,0,0,1,NULL,NULL,'2024-04-18 15:45:13','2024-04-18 15:45:13','2024-04-18 15:45:13'),(293,15,'assessment',0,8,0,0,1,NULL,NULL,'2024-04-18 15:45:13','2024-04-18 15:45:13','2024-04-18 15:45:13'),(294,15,'capture',0,9,0,0,1,NULL,NULL,'2024-04-18 15:45:13','2024-04-18 15:45:13','2024-04-18 15:45:13'),(295,15,'cataloged',0,10,0,0,1,NULL,NULL,'2024-04-18 15:45:13','2024-04-18 15:45:13','2024-04-18 15:45:13'),(296,15,'collection',0,11,0,0,1,NULL,NULL,'2024-04-18 15:45:13','2024-04-18 15:45:13','2024-04-18 15:45:13'),(297,15,'compression',0,13,0,0,1,NULL,NULL,'2024-04-18 15:45:13','2024-04-18 15:45:13','2024-04-18 15:45:13'),(298,15,'contribution',0,14,0,0,1,NULL,NULL,'2024-04-18 15:45:13','2024-04-18 15:45:13','2024-04-18 15:45:13'),(299,15,'component_transfer',0,12,0,0,1,NULL,NULL,'2024-04-18 15:45:13','2024-04-18 15:45:13','2024-04-18 15:45:13'),(300,15,'copyright_transfer',0,15,0,0,1,NULL,NULL,'2024-04-18 15:45:13','2024-04-18 15:45:13','2024-04-18 15:45:13'),(301,15,'custody_transfer',0,16,0,0,1,NULL,NULL,'2024-04-18 15:45:13','2024-04-18 15:45:13','2024-04-18 15:45:13'),(302,15,'deaccession',0,17,0,0,1,NULL,NULL,'2024-04-18 15:45:13','2024-04-18 15:45:13','2024-04-18 15:45:13'),(303,15,'decompression',0,18,0,0,1,NULL,NULL,'2024-04-18 15:45:13','2024-04-18 15:45:13','2024-04-18 15:45:13'),(304,15,'decryption',0,19,0,0,1,NULL,NULL,'2024-04-18 15:45:13','2024-04-18 15:45:13','2024-04-18 15:45:13'),(305,15,'deletion',0,20,0,0,1,NULL,NULL,'2024-04-18 15:45:14','2024-04-18 15:45:14','2024-04-18 15:45:14'),(306,15,'digital_signature_validation',0,21,0,0,1,NULL,NULL,'2024-04-18 15:45:14','2024-04-18 15:45:14','2024-04-18 15:45:14'),(307,15,'fixity_check',0,22,0,0,1,NULL,NULL,'2024-04-18 15:45:14','2024-04-18 15:45:14','2024-04-18 15:45:14'),(308,15,'ingestion',0,23,0,0,1,NULL,NULL,'2024-04-18 15:45:14','2024-04-18 15:45:14','2024-04-18 15:45:14'),(309,15,'message_digest_calculation',0,24,0,0,1,NULL,NULL,'2024-04-18 15:45:14','2024-04-18 15:45:14','2024-04-18 15:45:14'),(310,15,'migration',0,25,0,0,1,NULL,NULL,'2024-04-18 15:45:14','2024-04-18 15:45:14','2024-04-18 15:45:14'),(311,15,'normalization',0,26,0,0,1,NULL,NULL,'2024-04-18 15:45:14','2024-04-18 15:45:14','2024-04-18 15:45:14'),(312,15,'processed',0,27,0,0,1,NULL,NULL,'2024-04-18 15:45:14','2024-04-18 15:45:14','2024-04-18 15:45:14'),(313,15,'publication',0,28,0,0,1,NULL,NULL,'2024-04-18 15:45:14','2024-04-18 15:45:14','2024-04-18 15:45:14'),(314,15,'replication',0,29,0,0,1,NULL,NULL,'2024-04-18 15:45:14','2024-04-18 15:45:14','2024-04-18 15:45:14'),(315,15,'validation',0,30,0,0,1,NULL,NULL,'2024-04-18 15:45:14','2024-04-18 15:45:14','2024-04-18 15:45:14'),(316,15,'virus_check',0,31,0,0,1,NULL,NULL,'2024-04-18 15:45:14','2024-04-18 15:45:14','2024-04-18 15:45:14'),(317,16,'box',0,0,0,0,1,NULL,NULL,'2024-04-18 15:45:24','2024-04-18 15:45:24','2024-04-18 15:45:24'),(318,16,'carton',0,1,0,0,1,NULL,NULL,'2024-04-18 15:45:24','2024-04-18 15:45:24','2024-04-18 15:45:24'),(319,16,'case',0,2,0,0,1,NULL,NULL,'2024-04-18 15:45:24','2024-04-18 15:45:24','2024-04-18 15:45:24'),(320,16,'folder',0,3,0,0,1,NULL,NULL,'2024-04-18 15:45:24','2024-04-18 15:45:24','2024-04-18 15:45:24'),(321,16,'frame',0,4,0,0,1,NULL,NULL,'2024-04-18 15:45:24','2024-04-18 15:45:24','2024-04-18 15:45:24'),(322,16,'object',0,5,0,0,1,NULL,NULL,'2024-04-18 15:45:24','2024-04-18 15:45:24','2024-04-18 15:45:24'),(323,16,'reel',0,6,0,0,1,NULL,NULL,'2024-04-18 15:45:24','2024-04-18 15:45:24','2024-04-18 15:45:24'),(324,17,'mr',0,1,0,0,1,NULL,NULL,'2024-04-18 15:45:27','2024-04-18 15:45:27','2024-04-18 15:45:27'),(325,17,'mrs',0,2,0,0,1,NULL,NULL,'2024-04-18 15:45:27','2024-04-18 15:45:27','2024-04-18 15:45:27'),(326,17,'ms',0,3,0,0,1,NULL,NULL,'2024-04-18 15:45:28','2024-04-18 15:45:28','2024-04-18 15:45:28'),(327,17,'madame',0,0,0,0,1,NULL,NULL,'2024-04-18 15:45:27','2024-04-18 15:45:27','2024-04-18 15:45:27'),(328,17,'sir',0,4,0,0,1,NULL,NULL,'2024-04-18 15:45:28','2024-04-18 15:45:28','2024-04-18 15:45:28'),(329,18,'pass',0,2,0,0,1,NULL,NULL,'2024-04-18 15:45:27','2024-04-18 15:45:27','2024-04-18 15:45:27'),(330,18,'partial pass',0,1,0,0,1,NULL,NULL,'2024-04-18 15:45:27','2024-04-18 15:45:27','2024-04-18 15:45:27'),(331,18,'fail',0,0,0,0,1,NULL,NULL,'2024-04-18 15:45:27','2024-04-18 15:45:27','2024-04-18 15:45:27'),(332,19,'collection',0,0,0,0,1,NULL,NULL,'2024-04-18 15:45:25','2024-04-18 15:45:25','2024-04-18 15:45:25'),(333,19,'publications',0,2,0,0,1,NULL,NULL,'2024-04-18 15:45:25','2024-04-18 15:45:25','2024-04-18 15:45:25'),(334,19,'papers',0,1,0,0,1,NULL,NULL,'2024-04-18 15:45:25','2024-04-18 15:45:25','2024-04-18 15:45:25'),(335,19,'records',0,3,0,0,1,NULL,NULL,'2024-04-18 15:45:25','2024-04-18 15:45:25','2024-04-18 15:45:25'),(336,20,'aacr',0,0,0,0,1,NULL,NULL,'2024-04-18 15:44:59','2024-04-18 15:44:59','2024-04-18 15:44:59'),(337,20,'cco',0,1,0,0,1,NULL,NULL,'2024-04-18 15:44:59','2024-04-18 15:44:59','2024-04-18 15:44:59'),(338,20,'dacs',0,2,0,0,1,NULL,NULL,'2024-04-18 15:44:59','2024-04-18 15:44:59','2024-04-18 15:44:59'),(339,20,'rad',0,4,0,0,1,NULL,NULL,'2024-04-18 15:44:59','2024-04-18 15:44:59','2024-04-18 15:44:59'),(340,20,'isadg',0,3,0,0,1,NULL,NULL,'2024-04-18 15:44:59','2024-04-18 15:44:59','2024-04-18 15:44:59'),(341,21,'completed',0,0,0,0,1,NULL,NULL,'2024-04-18 15:45:25','2024-04-18 15:45:25','2024-04-18 15:45:25'),(342,21,'in_progress',0,1,0,0,1,NULL,NULL,'2024-04-18 15:45:25','2024-04-18 15:45:25','2024-04-18 15:45:25'),(343,21,'under_revision',0,2,0,0,1,NULL,NULL,'2024-04-18 15:45:25','2024-04-18 15:45:25','2024-04-18 15:45:25'),(344,21,'unprocessed',0,3,0,0,1,NULL,NULL,'2024-04-18 15:45:25','2024-04-18 15:45:25','2024-04-18 15:45:25'),(345,22,'accession',0,0,0,0,1,NULL,NULL,'2024-04-18 15:45:14','2024-04-18 15:45:14','2024-04-18 15:45:14'),(346,22,'audio',0,1,0,0,1,NULL,NULL,'2024-04-18 15:45:14','2024-04-18 15:45:14','2024-04-18 15:45:14'),(347,22,'books',0,2,0,0,1,NULL,NULL,'2024-04-18 15:45:14','2024-04-18 15:45:14','2024-04-18 15:45:14'),(348,22,'computer_disks',0,3,0,0,1,NULL,NULL,'2024-04-18 15:45:14','2024-04-18 15:45:14','2024-04-18 15:45:14'),(349,22,'digital_object',1,4,0,0,1,NULL,NULL,'2024-04-18 15:45:14','2024-04-18 15:45:14','2024-04-18 15:45:14'),(350,22,'graphic_materials',0,5,0,0,1,NULL,NULL,'2024-04-18 15:45:14','2024-04-18 15:45:14','2024-04-18 15:45:14'),(351,22,'maps',0,6,0,0,1,NULL,NULL,'2024-04-18 15:45:14','2024-04-18 15:45:14','2024-04-18 15:45:14'),(352,22,'microform',0,7,0,0,1,NULL,NULL,'2024-04-18 15:45:14','2024-04-18 15:45:14','2024-04-18 15:45:14'),(353,22,'mixed_materials',0,8,0,0,1,NULL,NULL,'2024-04-18 15:45:14','2024-04-18 15:45:14','2024-04-18 15:45:14'),(354,22,'moving_images',0,9,0,0,1,NULL,NULL,'2024-04-18 15:45:14','2024-04-18 15:45:14','2024-04-18 15:45:14'),(355,22,'realia',0,10,0,0,1,NULL,NULL,'2024-04-18 15:45:14','2024-04-18 15:45:14','2024-04-18 15:45:14'),(356,22,'text',0,11,0,0,1,NULL,NULL,'2024-04-18 15:45:14','2024-04-18 15:45:14','2024-04-18 15:45:14'),(357,23,'aat',0,0,0,0,1,NULL,NULL,'2024-04-18 15:45:13','2024-04-18 15:45:13','2024-04-18 15:45:13'),(358,23,'rbgenr',0,5,0,0,1,NULL,NULL,'2024-04-18 15:45:13','2024-04-18 15:45:13','2024-04-18 15:45:13'),(359,23,'tgn',0,6,0,0,1,NULL,NULL,'2024-04-18 15:45:13','2024-04-18 15:45:13','2024-04-18 15:45:13'),(360,23,'lcsh',0,2,0,0,1,NULL,NULL,'2024-04-18 15:45:13','2024-04-18 15:45:13','2024-04-18 15:45:13'),(361,23,'local',0,3,0,0,1,NULL,NULL,'2024-04-18 15:45:13','2024-04-18 15:45:13','2024-04-18 15:45:13'),(362,23,'mesh',0,4,0,0,1,NULL,NULL,'2024-04-18 15:45:13','2024-04-18 15:45:13','2024-04-18 15:45:13'),(363,23,'gmgpc',0,1,0,0,1,NULL,NULL,'2024-04-18 15:45:13','2024-04-18 15:45:13','2024-04-18 15:45:13'),(364,24,'application',0,0,0,0,1,NULL,NULL,'2024-04-18 15:45:23','2024-04-18 15:45:23','2024-04-18 15:45:23'),(365,24,'application-pdf',0,1,0,0,1,NULL,NULL,'2024-04-18 15:45:23','2024-04-18 15:45:23','2024-04-18 15:45:23'),(366,24,'audio-clip',0,2,0,0,1,NULL,NULL,'2024-04-18 15:45:23','2024-04-18 15:45:23','2024-04-18 15:45:23'),(367,24,'audio-master',0,3,0,0,1,NULL,NULL,'2024-04-18 15:45:23','2024-04-18 15:45:23','2024-04-18 15:45:23'),(368,24,'audio-master-edited',0,4,0,0,1,NULL,NULL,'2024-04-18 15:45:23','2024-04-18 15:45:23','2024-04-18 15:45:23'),(369,24,'audio-service',0,5,0,0,1,NULL,NULL,'2024-04-18 15:45:23','2024-04-18 15:45:23','2024-04-18 15:45:23'),(370,24,'image-master',0,6,0,0,1,NULL,NULL,'2024-04-18 15:45:23','2024-04-18 15:45:23','2024-04-18 15:45:23'),(371,24,'image-master-edited',0,7,0,0,1,NULL,NULL,'2024-04-18 15:45:23','2024-04-18 15:45:23','2024-04-18 15:45:23'),(372,24,'image-service',0,8,0,0,1,NULL,NULL,'2024-04-18 15:45:23','2024-04-18 15:45:23','2024-04-18 15:45:23'),(373,24,'image-service-edited',0,9,0,0,1,NULL,NULL,'2024-04-18 15:45:23','2024-04-18 15:45:23','2024-04-18 15:45:23'),(374,24,'image-thumbnail',0,10,0,0,1,NULL,NULL,'2024-04-18 15:45:23','2024-04-18 15:45:23','2024-04-18 15:45:23'),(375,24,'text-codebook',0,12,0,0,1,NULL,NULL,'2024-04-18 15:45:23','2024-04-18 15:45:23','2024-04-18 15:45:23'),(376,24,'test-data',0,11,0,0,1,NULL,NULL,'2024-04-18 15:45:23','2024-04-18 15:45:23','2024-04-18 15:45:23'),(377,24,'text-data_definition',0,13,0,0,1,NULL,NULL,'2024-04-18 15:45:23','2024-04-18 15:45:23','2024-04-18 15:45:23'),(378,24,'text-georeference',0,14,0,0,1,NULL,NULL,'2024-04-18 15:45:23','2024-04-18 15:45:23','2024-04-18 15:45:23'),(379,24,'text-ocr-edited',0,15,0,0,1,NULL,NULL,'2024-04-18 15:45:23','2024-04-18 15:45:23','2024-04-18 15:45:23'),(380,24,'text-ocr-unedited',0,16,0,0,1,NULL,NULL,'2024-04-18 15:45:23','2024-04-18 15:45:23','2024-04-18 15:45:23'),(381,24,'text-tei-transcripted',0,17,0,0,1,NULL,NULL,'2024-04-18 15:45:23','2024-04-18 15:45:23','2024-04-18 15:45:23'),(382,24,'text-tei-translated',0,18,0,0,1,NULL,NULL,'2024-04-18 15:45:23','2024-04-18 15:45:23','2024-04-18 15:45:23'),(383,24,'video-clip',0,19,0,0,1,NULL,NULL,'2024-04-18 15:45:23','2024-04-18 15:45:23','2024-04-18 15:45:23'),(384,24,'video-master',0,20,0,0,1,NULL,NULL,'2024-04-18 15:45:23','2024-04-18 15:45:23','2024-04-18 15:45:23'),(385,24,'video-master-edited',0,21,0,0,1,NULL,NULL,'2024-04-18 15:45:23','2024-04-18 15:45:23','2024-04-18 15:45:23'),(386,24,'video-service',0,22,0,0,1,NULL,NULL,'2024-04-18 15:45:23','2024-04-18 15:45:23','2024-04-18 15:45:23'),(387,24,'video-streaming',0,23,0,0,1,NULL,NULL,'2024-04-18 15:45:23','2024-04-18 15:45:23','2024-04-18 15:45:23'),(388,25,'md5',0,0,0,0,1,NULL,NULL,'2024-04-18 15:45:28','2024-04-18 15:45:28','2024-04-18 15:45:28'),(389,25,'sha-1',0,1,0,0,1,NULL,NULL,'2024-04-18 15:45:28','2024-04-18 15:45:28','2024-04-18 15:45:28'),(390,25,'sha-256',0,2,0,0,1,NULL,NULL,'2024-04-18 15:45:28','2024-04-18 15:45:28','2024-04-18 15:45:28'),(391,25,'sha-384',0,3,0,0,1,NULL,NULL,'2024-04-18 15:45:28','2024-04-18 15:45:28','2024-04-18 15:45:28'),(392,25,'sha-512',0,4,0,0,1,NULL,NULL,'2024-04-18 15:45:28','2024-04-18 15:45:28','2024-04-18 15:45:28'),(393,26,'aar',0,0,0,0,1,NULL,NULL,'2024-04-18 15:44:59','2024-04-18 15:44:59','2024-04-18 15:44:59'),(394,26,'abk',0,1,0,0,1,NULL,NULL,'2024-04-18 15:44:59','2024-04-18 15:44:59','2024-04-18 15:44:59'),(395,26,'ace',0,2,0,0,1,NULL,NULL,'2024-04-18 15:45:00','2024-04-18 15:45:00','2024-04-18 15:45:00'),(396,26,'ach',0,3,0,0,1,NULL,NULL,'2024-04-18 15:45:00','2024-04-18 15:45:00','2024-04-18 15:45:00'),(397,26,'ada',0,4,0,0,1,NULL,NULL,'2024-04-18 15:45:00','2024-04-18 15:45:00','2024-04-18 15:45:00'),(398,26,'ady',0,5,0,0,1,NULL,NULL,'2024-04-18 15:45:00','2024-04-18 15:45:00','2024-04-18 15:45:00'),(399,26,'afa',0,6,0,0,1,NULL,NULL,'2024-04-18 15:45:00','2024-04-18 15:45:00','2024-04-18 15:45:00'),(400,26,'afh',0,7,0,0,1,NULL,NULL,'2024-04-18 15:45:00','2024-04-18 15:45:00','2024-04-18 15:45:00'),(401,26,'afr',0,8,0,0,1,NULL,NULL,'2024-04-18 15:45:00','2024-04-18 15:45:00','2024-04-18 15:45:00'),(402,26,'ain',0,9,0,0,1,NULL,NULL,'2024-04-18 15:45:00','2024-04-18 15:45:00','2024-04-18 15:45:00'),(403,26,'aka',0,10,0,0,1,NULL,NULL,'2024-04-18 15:45:00','2024-04-18 15:45:00','2024-04-18 15:45:00'),(404,26,'akk',0,11,0,0,1,NULL,NULL,'2024-04-18 15:45:00','2024-04-18 15:45:00','2024-04-18 15:45:00'),(405,26,'alb',0,12,0,0,1,NULL,NULL,'2024-04-18 15:45:00','2024-04-18 15:45:00','2024-04-18 15:45:00'),(406,26,'ale',0,13,0,0,1,NULL,NULL,'2024-04-18 15:45:00','2024-04-18 15:45:00','2024-04-18 15:45:00'),(407,26,'alg',0,14,0,0,1,NULL,NULL,'2024-04-18 15:45:00','2024-04-18 15:45:00','2024-04-18 15:45:00'),(408,26,'alt',0,15,0,0,1,NULL,NULL,'2024-04-18 15:45:00','2024-04-18 15:45:00','2024-04-18 15:45:00'),(409,26,'amh',0,16,0,0,1,NULL,NULL,'2024-04-18 15:45:00','2024-04-18 15:45:00','2024-04-18 15:45:00'),(410,26,'ang',0,17,0,0,1,NULL,NULL,'2024-04-18 15:45:00','2024-04-18 15:45:00','2024-04-18 15:45:00'),(411,26,'anp',0,18,0,0,1,NULL,NULL,'2024-04-18 15:45:00','2024-04-18 15:45:00','2024-04-18 15:45:00'),(412,26,'apa',0,19,0,0,1,NULL,NULL,'2024-04-18 15:45:00','2024-04-18 15:45:00','2024-04-18 15:45:00'),(413,26,'ara',0,20,0,0,1,NULL,NULL,'2024-04-18 15:45:00','2024-04-18 15:45:00','2024-04-18 15:45:00'),(414,26,'arc',0,21,0,0,1,NULL,NULL,'2024-04-18 15:45:00','2024-04-18 15:45:00','2024-04-18 15:45:00'),(415,26,'arg',0,22,0,0,1,NULL,NULL,'2024-04-18 15:45:00','2024-04-18 15:45:00','2024-04-18 15:45:00'),(416,26,'arm',0,23,0,0,1,NULL,NULL,'2024-04-18 15:45:00','2024-04-18 15:45:00','2024-04-18 15:45:00'),(417,26,'arn',0,24,0,0,1,NULL,NULL,'2024-04-18 15:45:00','2024-04-18 15:45:00','2024-04-18 15:45:00'),(418,26,'arp',0,25,0,0,1,NULL,NULL,'2024-04-18 15:45:00','2024-04-18 15:45:00','2024-04-18 15:45:00'),(419,26,'art',0,26,0,0,1,NULL,NULL,'2024-04-18 15:45:00','2024-04-18 15:45:00','2024-04-18 15:45:00'),(420,26,'arw',0,27,0,0,1,NULL,NULL,'2024-04-18 15:45:00','2024-04-18 15:45:00','2024-04-18 15:45:00'),(421,26,'asm',0,28,0,0,1,NULL,NULL,'2024-04-18 15:45:00','2024-04-18 15:45:00','2024-04-18 15:45:00'),(422,26,'ast',0,29,0,0,1,NULL,NULL,'2024-04-18 15:45:00','2024-04-18 15:45:00','2024-04-18 15:45:00'),(423,26,'ath',0,30,0,0,1,NULL,NULL,'2024-04-18 15:45:00','2024-04-18 15:45:00','2024-04-18 15:45:00'),(424,26,'aus',0,31,0,0,1,NULL,NULL,'2024-04-18 15:45:00','2024-04-18 15:45:00','2024-04-18 15:45:00'),(425,26,'ava',0,32,0,0,1,NULL,NULL,'2024-04-18 15:45:00','2024-04-18 15:45:00','2024-04-18 15:45:00'),(426,26,'ave',0,33,0,0,1,NULL,NULL,'2024-04-18 15:45:00','2024-04-18 15:45:00','2024-04-18 15:45:00'),(427,26,'awa',0,34,0,0,1,NULL,NULL,'2024-04-18 15:45:00','2024-04-18 15:45:00','2024-04-18 15:45:00'),(428,26,'aym',0,35,0,0,1,NULL,NULL,'2024-04-18 15:45:00','2024-04-18 15:45:00','2024-04-18 15:45:00'),(429,26,'aze',0,36,0,0,1,NULL,NULL,'2024-04-18 15:45:00','2024-04-18 15:45:00','2024-04-18 15:45:00'),(430,26,'bad',0,37,0,0,1,NULL,NULL,'2024-04-18 15:45:00','2024-04-18 15:45:00','2024-04-18 15:45:00'),(431,26,'bai',0,38,0,0,1,NULL,NULL,'2024-04-18 15:45:00','2024-04-18 15:45:00','2024-04-18 15:45:00'),(432,26,'bak',0,39,0,0,1,NULL,NULL,'2024-04-18 15:45:00','2024-04-18 15:45:00','2024-04-18 15:45:00'),(433,26,'bal',0,40,0,0,1,NULL,NULL,'2024-04-18 15:45:01','2024-04-18 15:45:01','2024-04-18 15:45:01'),(434,26,'bam',0,41,0,0,1,NULL,NULL,'2024-04-18 15:45:01','2024-04-18 15:45:01','2024-04-18 15:45:01'),(435,26,'ban',0,42,0,0,1,NULL,NULL,'2024-04-18 15:45:01','2024-04-18 15:45:01','2024-04-18 15:45:01'),(436,26,'baq',0,43,0,0,1,NULL,NULL,'2024-04-18 15:45:01','2024-04-18 15:45:01','2024-04-18 15:45:01'),(437,26,'bas',0,44,0,0,1,NULL,NULL,'2024-04-18 15:45:01','2024-04-18 15:45:01','2024-04-18 15:45:01'),(438,26,'bat',0,45,0,0,1,NULL,NULL,'2024-04-18 15:45:01','2024-04-18 15:45:01','2024-04-18 15:45:01'),(439,26,'bej',0,46,0,0,1,NULL,NULL,'2024-04-18 15:45:01','2024-04-18 15:45:01','2024-04-18 15:45:01'),(440,26,'bel',0,47,0,0,1,NULL,NULL,'2024-04-18 15:45:01','2024-04-18 15:45:01','2024-04-18 15:45:01'),(441,26,'bem',0,48,0,0,1,NULL,NULL,'2024-04-18 15:45:01','2024-04-18 15:45:01','2024-04-18 15:45:01'),(442,26,'ben',0,49,0,0,1,NULL,NULL,'2024-04-18 15:45:01','2024-04-18 15:45:01','2024-04-18 15:45:01'),(443,26,'ber',0,50,0,0,1,NULL,NULL,'2024-04-18 15:45:01','2024-04-18 15:45:01','2024-04-18 15:45:01'),(444,26,'bho',0,51,0,0,1,NULL,NULL,'2024-04-18 15:45:01','2024-04-18 15:45:01','2024-04-18 15:45:01'),(445,26,'bih',0,52,0,0,1,NULL,NULL,'2024-04-18 15:45:01','2024-04-18 15:45:01','2024-04-18 15:45:01'),(446,26,'bik',0,53,0,0,1,NULL,NULL,'2024-04-18 15:45:01','2024-04-18 15:45:01','2024-04-18 15:45:01'),(447,26,'bin',0,54,0,0,1,NULL,NULL,'2024-04-18 15:45:01','2024-04-18 15:45:01','2024-04-18 15:45:01'),(448,26,'bis',0,55,0,0,1,NULL,NULL,'2024-04-18 15:45:01','2024-04-18 15:45:01','2024-04-18 15:45:01'),(449,26,'bla',0,56,0,0,1,NULL,NULL,'2024-04-18 15:45:01','2024-04-18 15:45:01','2024-04-18 15:45:01'),(450,26,'bnt',0,57,0,0,1,NULL,NULL,'2024-04-18 15:45:01','2024-04-18 15:45:01','2024-04-18 15:45:01'),(451,26,'bos',0,58,0,0,1,NULL,NULL,'2024-04-18 15:45:01','2024-04-18 15:45:01','2024-04-18 15:45:01'),(452,26,'bra',0,59,0,0,1,NULL,NULL,'2024-04-18 15:45:01','2024-04-18 15:45:01','2024-04-18 15:45:01'),(453,26,'bre',0,60,0,0,1,NULL,NULL,'2024-04-18 15:45:01','2024-04-18 15:45:01','2024-04-18 15:45:01'),(454,26,'btk',0,61,0,0,1,NULL,NULL,'2024-04-18 15:45:01','2024-04-18 15:45:01','2024-04-18 15:45:01'),(455,26,'bua',0,62,0,0,1,NULL,NULL,'2024-04-18 15:45:01','2024-04-18 15:45:01','2024-04-18 15:45:01'),(456,26,'bug',0,63,0,0,1,NULL,NULL,'2024-04-18 15:45:01','2024-04-18 15:45:01','2024-04-18 15:45:01'),(457,26,'bul',0,64,0,0,1,NULL,NULL,'2024-04-18 15:45:01','2024-04-18 15:45:01','2024-04-18 15:45:01'),(458,26,'bur',0,65,0,0,1,NULL,NULL,'2024-04-18 15:45:01','2024-04-18 15:45:01','2024-04-18 15:45:01'),(459,26,'byn',0,66,0,0,1,NULL,NULL,'2024-04-18 15:45:01','2024-04-18 15:45:01','2024-04-18 15:45:01'),(460,26,'cad',0,67,0,0,1,NULL,NULL,'2024-04-18 15:45:01','2024-04-18 15:45:01','2024-04-18 15:45:01'),(461,26,'cai',0,68,0,0,1,NULL,NULL,'2024-04-18 15:45:01','2024-04-18 15:45:01','2024-04-18 15:45:01'),(462,26,'car',0,69,0,0,1,NULL,NULL,'2024-04-18 15:45:01','2024-04-18 15:45:01','2024-04-18 15:45:01'),(463,26,'cat',0,70,0,0,1,NULL,NULL,'2024-04-18 15:45:01','2024-04-18 15:45:01','2024-04-18 15:45:01'),(464,26,'cau',0,71,0,0,1,NULL,NULL,'2024-04-18 15:45:01','2024-04-18 15:45:01','2024-04-18 15:45:01'),(465,26,'ceb',0,72,0,0,1,NULL,NULL,'2024-04-18 15:45:01','2024-04-18 15:45:01','2024-04-18 15:45:01'),(466,26,'cel',0,73,0,0,1,NULL,NULL,'2024-04-18 15:45:01','2024-04-18 15:45:01','2024-04-18 15:45:01'),(467,26,'cha',0,74,0,0,1,NULL,NULL,'2024-04-18 15:45:01','2024-04-18 15:45:01','2024-04-18 15:45:01'),(468,26,'chb',0,75,0,0,1,NULL,NULL,'2024-04-18 15:45:01','2024-04-18 15:45:01','2024-04-18 15:45:01'),(469,26,'che',0,76,0,0,1,NULL,NULL,'2024-04-18 15:45:01','2024-04-18 15:45:01','2024-04-18 15:45:01'),(470,26,'chg',0,77,0,0,1,NULL,NULL,'2024-04-18 15:45:01','2024-04-18 15:45:01','2024-04-18 15:45:01'),(471,26,'chi',0,78,0,0,1,NULL,NULL,'2024-04-18 15:45:01','2024-04-18 15:45:01','2024-04-18 15:45:01'),(472,26,'chk',0,79,0,0,1,NULL,NULL,'2024-04-18 15:45:02','2024-04-18 15:45:02','2024-04-18 15:45:02'),(473,26,'chm',0,80,0,0,1,NULL,NULL,'2024-04-18 15:45:02','2024-04-18 15:45:02','2024-04-18 15:45:02'),(474,26,'chn',0,81,0,0,1,NULL,NULL,'2024-04-18 15:45:02','2024-04-18 15:45:02','2024-04-18 15:45:02'),(475,26,'cho',0,82,0,0,1,NULL,NULL,'2024-04-18 15:45:02','2024-04-18 15:45:02','2024-04-18 15:45:02'),(476,26,'chp',0,83,0,0,1,NULL,NULL,'2024-04-18 15:45:02','2024-04-18 15:45:02','2024-04-18 15:45:02'),(477,26,'chr',0,84,0,0,1,NULL,NULL,'2024-04-18 15:45:02','2024-04-18 15:45:02','2024-04-18 15:45:02'),(478,26,'chu',0,85,0,0,1,NULL,NULL,'2024-04-18 15:45:02','2024-04-18 15:45:02','2024-04-18 15:45:02'),(479,26,'chv',0,86,0,0,1,NULL,NULL,'2024-04-18 15:45:02','2024-04-18 15:45:02','2024-04-18 15:45:02'),(480,26,'chy',0,87,0,0,1,NULL,NULL,'2024-04-18 15:45:02','2024-04-18 15:45:02','2024-04-18 15:45:02'),(481,26,'cmc',0,88,0,0,1,NULL,NULL,'2024-04-18 15:45:02','2024-04-18 15:45:02','2024-04-18 15:45:02'),(482,26,'cop',0,89,0,0,1,NULL,NULL,'2024-04-18 15:45:02','2024-04-18 15:45:02','2024-04-18 15:45:02'),(483,26,'cor',0,90,0,0,1,NULL,NULL,'2024-04-18 15:45:02','2024-04-18 15:45:02','2024-04-18 15:45:02'),(484,26,'cos',0,91,0,0,1,NULL,NULL,'2024-04-18 15:45:02','2024-04-18 15:45:02','2024-04-18 15:45:02'),(485,26,'cpe',0,92,0,0,1,NULL,NULL,'2024-04-18 15:45:02','2024-04-18 15:45:02','2024-04-18 15:45:02'),(486,26,'cpf',0,93,0,0,1,NULL,NULL,'2024-04-18 15:45:02','2024-04-18 15:45:02','2024-04-18 15:45:02'),(487,26,'cpp',0,94,0,0,1,NULL,NULL,'2024-04-18 15:45:02','2024-04-18 15:45:02','2024-04-18 15:45:02'),(488,26,'cre',0,95,0,0,1,NULL,NULL,'2024-04-18 15:45:02','2024-04-18 15:45:02','2024-04-18 15:45:02'),(489,26,'crh',0,96,0,0,1,NULL,NULL,'2024-04-18 15:45:02','2024-04-18 15:45:02','2024-04-18 15:45:02'),(490,26,'crp',0,97,0,0,1,NULL,NULL,'2024-04-18 15:45:02','2024-04-18 15:45:02','2024-04-18 15:45:02'),(491,26,'csb',0,98,0,0,1,NULL,NULL,'2024-04-18 15:45:02','2024-04-18 15:45:02','2024-04-18 15:45:02'),(492,26,'cus',0,99,0,0,1,NULL,NULL,'2024-04-18 15:45:02','2024-04-18 15:45:02','2024-04-18 15:45:02'),(493,26,'cze',0,100,0,0,1,NULL,NULL,'2024-04-18 15:45:02','2024-04-18 15:45:02','2024-04-18 15:45:02'),(494,26,'dak',0,101,0,0,1,NULL,NULL,'2024-04-18 15:45:02','2024-04-18 15:45:02','2024-04-18 15:45:02'),(495,26,'dan',0,102,0,0,1,NULL,NULL,'2024-04-18 15:45:02','2024-04-18 15:45:02','2024-04-18 15:45:02'),(496,26,'dar',0,103,0,0,1,NULL,NULL,'2024-04-18 15:45:02','2024-04-18 15:45:02','2024-04-18 15:45:02'),(497,26,'day',0,104,0,0,1,NULL,NULL,'2024-04-18 15:45:02','2024-04-18 15:45:02','2024-04-18 15:45:02'),(498,26,'del',0,105,0,0,1,NULL,NULL,'2024-04-18 15:45:02','2024-04-18 15:45:02','2024-04-18 15:45:02'),(499,26,'den',0,106,0,0,1,NULL,NULL,'2024-04-18 15:45:02','2024-04-18 15:45:02','2024-04-18 15:45:02'),(500,26,'dgr',0,107,0,0,1,NULL,NULL,'2024-04-18 15:45:02','2024-04-18 15:45:02','2024-04-18 15:45:02'),(501,26,'din',0,108,0,0,1,NULL,NULL,'2024-04-18 15:45:02','2024-04-18 15:45:02','2024-04-18 15:45:02'),(502,26,'div',0,109,0,0,1,NULL,NULL,'2024-04-18 15:45:02','2024-04-18 15:45:02','2024-04-18 15:45:02'),(503,26,'doi',0,110,0,0,1,NULL,NULL,'2024-04-18 15:45:02','2024-04-18 15:45:02','2024-04-18 15:45:02'),(504,26,'dra',0,111,0,0,1,NULL,NULL,'2024-04-18 15:45:02','2024-04-18 15:45:02','2024-04-18 15:45:02'),(505,26,'dsb',0,112,0,0,1,NULL,NULL,'2024-04-18 15:45:02','2024-04-18 15:45:02','2024-04-18 15:45:02'),(506,26,'dua',0,113,0,0,1,NULL,NULL,'2024-04-18 15:45:02','2024-04-18 15:45:02','2024-04-18 15:45:02'),(507,26,'dum',0,114,0,0,1,NULL,NULL,'2024-04-18 15:45:03','2024-04-18 15:45:03','2024-04-18 15:45:03'),(508,26,'dut',0,115,0,0,1,NULL,NULL,'2024-04-18 15:45:03','2024-04-18 15:45:03','2024-04-18 15:45:03'),(509,26,'dyu',0,116,0,0,1,NULL,NULL,'2024-04-18 15:45:03','2024-04-18 15:45:03','2024-04-18 15:45:03'),(510,26,'dzo',0,117,0,0,1,NULL,NULL,'2024-04-18 15:45:03','2024-04-18 15:45:03','2024-04-18 15:45:03'),(511,26,'efi',0,118,0,0,1,NULL,NULL,'2024-04-18 15:45:03','2024-04-18 15:45:03','2024-04-18 15:45:03'),(512,26,'egy',0,119,0,0,1,NULL,NULL,'2024-04-18 15:45:03','2024-04-18 15:45:03','2024-04-18 15:45:03'),(513,26,'eka',0,120,0,0,1,NULL,NULL,'2024-04-18 15:45:03','2024-04-18 15:45:03','2024-04-18 15:45:03'),(514,26,'elx',0,121,0,0,1,NULL,NULL,'2024-04-18 15:45:03','2024-04-18 15:45:03','2024-04-18 15:45:03'),(515,26,'eng',0,122,0,0,1,NULL,NULL,'2024-04-18 15:45:03','2024-04-18 15:45:03','2024-04-18 15:45:03'),(516,26,'enm',0,123,0,0,1,NULL,NULL,'2024-04-18 15:45:03','2024-04-18 15:45:03','2024-04-18 15:45:03'),(517,26,'epo',0,124,0,0,1,NULL,NULL,'2024-04-18 15:45:03','2024-04-18 15:45:03','2024-04-18 15:45:03'),(518,26,'est',0,125,0,0,1,NULL,NULL,'2024-04-18 15:45:03','2024-04-18 15:45:03','2024-04-18 15:45:03'),(519,26,'ewe',0,126,0,0,1,NULL,NULL,'2024-04-18 15:45:03','2024-04-18 15:45:03','2024-04-18 15:45:03'),(520,26,'ewo',0,127,0,0,1,NULL,NULL,'2024-04-18 15:45:03','2024-04-18 15:45:03','2024-04-18 15:45:03'),(521,26,'fan',0,128,0,0,1,NULL,NULL,'2024-04-18 15:45:03','2024-04-18 15:45:03','2024-04-18 15:45:03'),(522,26,'fao',0,129,0,0,1,NULL,NULL,'2024-04-18 15:45:03','2024-04-18 15:45:03','2024-04-18 15:45:03'),(523,26,'fat',0,130,0,0,1,NULL,NULL,'2024-04-18 15:45:03','2024-04-18 15:45:03','2024-04-18 15:45:03'),(524,26,'fij',0,131,0,0,1,NULL,NULL,'2024-04-18 15:45:03','2024-04-18 15:45:03','2024-04-18 15:45:03'),(525,26,'fil',0,132,0,0,1,NULL,NULL,'2024-04-18 15:45:03','2024-04-18 15:45:03','2024-04-18 15:45:03'),(526,26,'fin',0,133,0,0,1,NULL,NULL,'2024-04-18 15:45:03','2024-04-18 15:45:03','2024-04-18 15:45:03'),(527,26,'fiu',0,134,0,0,1,NULL,NULL,'2024-04-18 15:45:03','2024-04-18 15:45:03','2024-04-18 15:45:03'),(528,26,'fon',0,135,0,0,1,NULL,NULL,'2024-04-18 15:45:03','2024-04-18 15:45:03','2024-04-18 15:45:03'),(529,26,'fre',0,136,0,0,1,NULL,NULL,'2024-04-18 15:45:03','2024-04-18 15:45:03','2024-04-18 15:45:03'),(530,26,'frm',0,137,0,0,1,NULL,NULL,'2024-04-18 15:45:03','2024-04-18 15:45:03','2024-04-18 15:45:03'),(531,26,'fro',0,138,0,0,1,NULL,NULL,'2024-04-18 15:45:03','2024-04-18 15:45:03','2024-04-18 15:45:03'),(532,26,'frr',0,139,0,0,1,NULL,NULL,'2024-04-18 15:45:03','2024-04-18 15:45:03','2024-04-18 15:45:03'),(533,26,'frs',0,140,0,0,1,NULL,NULL,'2024-04-18 15:45:03','2024-04-18 15:45:03','2024-04-18 15:45:03'),(534,26,'fry',0,141,0,0,1,NULL,NULL,'2024-04-18 15:45:03','2024-04-18 15:45:03','2024-04-18 15:45:03'),(535,26,'ful',0,142,0,0,1,NULL,NULL,'2024-04-18 15:45:03','2024-04-18 15:45:03','2024-04-18 15:45:03'),(536,26,'fur',0,143,0,0,1,NULL,NULL,'2024-04-18 15:45:03','2024-04-18 15:45:03','2024-04-18 15:45:03'),(537,26,'gaa',0,144,0,0,1,NULL,NULL,'2024-04-18 15:45:03','2024-04-18 15:45:03','2024-04-18 15:45:03'),(538,26,'gay',0,145,0,0,1,NULL,NULL,'2024-04-18 15:45:03','2024-04-18 15:45:03','2024-04-18 15:45:03'),(539,26,'gba',0,146,0,0,1,NULL,NULL,'2024-04-18 15:45:03','2024-04-18 15:45:03','2024-04-18 15:45:03'),(540,26,'gem',0,147,0,0,1,NULL,NULL,'2024-04-18 15:45:03','2024-04-18 15:45:03','2024-04-18 15:45:03'),(541,26,'geo',0,148,0,0,1,NULL,NULL,'2024-04-18 15:45:03','2024-04-18 15:45:03','2024-04-18 15:45:03'),(542,26,'ger',0,149,0,0,1,NULL,NULL,'2024-04-18 15:45:04','2024-04-18 15:45:04','2024-04-18 15:45:04'),(543,26,'gez',0,150,0,0,1,NULL,NULL,'2024-04-18 15:45:04','2024-04-18 15:45:04','2024-04-18 15:45:04'),(544,26,'gil',0,151,0,0,1,NULL,NULL,'2024-04-18 15:45:04','2024-04-18 15:45:04','2024-04-18 15:45:04'),(545,26,'gla',0,152,0,0,1,NULL,NULL,'2024-04-18 15:45:04','2024-04-18 15:45:04','2024-04-18 15:45:04'),(546,26,'gle',0,153,0,0,1,NULL,NULL,'2024-04-18 15:45:04','2024-04-18 15:45:04','2024-04-18 15:45:04'),(547,26,'glg',0,154,0,0,1,NULL,NULL,'2024-04-18 15:45:04','2024-04-18 15:45:04','2024-04-18 15:45:04'),(548,26,'glv',0,155,0,0,1,NULL,NULL,'2024-04-18 15:45:04','2024-04-18 15:45:04','2024-04-18 15:45:04'),(549,26,'gmh',0,156,0,0,1,NULL,NULL,'2024-04-18 15:45:04','2024-04-18 15:45:04','2024-04-18 15:45:04'),(550,26,'goh',0,157,0,0,1,NULL,NULL,'2024-04-18 15:45:04','2024-04-18 15:45:04','2024-04-18 15:45:04'),(551,26,'gon',0,158,0,0,1,NULL,NULL,'2024-04-18 15:45:04','2024-04-18 15:45:04','2024-04-18 15:45:04'),(552,26,'gor',0,159,0,0,1,NULL,NULL,'2024-04-18 15:45:04','2024-04-18 15:45:04','2024-04-18 15:45:04'),(553,26,'got',0,160,0,0,1,NULL,NULL,'2024-04-18 15:45:04','2024-04-18 15:45:04','2024-04-18 15:45:04'),(554,26,'grb',0,161,0,0,1,NULL,NULL,'2024-04-18 15:45:04','2024-04-18 15:45:04','2024-04-18 15:45:04'),(555,26,'grc',0,162,0,0,1,NULL,NULL,'2024-04-18 15:45:04','2024-04-18 15:45:04','2024-04-18 15:45:04'),(556,26,'gre',0,163,0,0,1,NULL,NULL,'2024-04-18 15:45:04','2024-04-18 15:45:04','2024-04-18 15:45:04'),(557,26,'grn',0,164,0,0,1,NULL,NULL,'2024-04-18 15:45:04','2024-04-18 15:45:04','2024-04-18 15:45:04'),(558,26,'gsw',0,165,0,0,1,NULL,NULL,'2024-04-18 15:45:04','2024-04-18 15:45:04','2024-04-18 15:45:04'),(559,26,'guj',0,166,0,0,1,NULL,NULL,'2024-04-18 15:45:04','2024-04-18 15:45:04','2024-04-18 15:45:04'),(560,26,'gwi',0,167,0,0,1,NULL,NULL,'2024-04-18 15:45:04','2024-04-18 15:45:04','2024-04-18 15:45:04'),(561,26,'hai',0,168,0,0,1,NULL,NULL,'2024-04-18 15:45:04','2024-04-18 15:45:04','2024-04-18 15:45:04'),(562,26,'hat',0,169,0,0,1,NULL,NULL,'2024-04-18 15:45:04','2024-04-18 15:45:04','2024-04-18 15:45:04'),(563,26,'hau',0,170,0,0,1,NULL,NULL,'2024-04-18 15:45:04','2024-04-18 15:45:04','2024-04-18 15:45:04'),(564,26,'haw',0,171,0,0,1,NULL,NULL,'2024-04-18 15:45:04','2024-04-18 15:45:04','2024-04-18 15:45:04'),(565,26,'heb',0,172,0,0,1,NULL,NULL,'2024-04-18 15:45:04','2024-04-18 15:45:04','2024-04-18 15:45:04'),(566,26,'her',0,173,0,0,1,NULL,NULL,'2024-04-18 15:45:04','2024-04-18 15:45:04','2024-04-18 15:45:04'),(567,26,'hil',0,174,0,0,1,NULL,NULL,'2024-04-18 15:45:04','2024-04-18 15:45:04','2024-04-18 15:45:04'),(568,26,'him',0,175,0,0,1,NULL,NULL,'2024-04-18 15:45:04','2024-04-18 15:45:04','2024-04-18 15:45:04'),(569,26,'hin',0,176,0,0,1,NULL,NULL,'2024-04-18 15:45:04','2024-04-18 15:45:04','2024-04-18 15:45:04'),(570,26,'hit',0,177,0,0,1,NULL,NULL,'2024-04-18 15:45:04','2024-04-18 15:45:04','2024-04-18 15:45:04'),(571,26,'hmn',0,178,0,0,1,NULL,NULL,'2024-04-18 15:45:04','2024-04-18 15:45:04','2024-04-18 15:45:04'),(572,26,'hmo',0,179,0,0,1,NULL,NULL,'2024-04-18 15:45:04','2024-04-18 15:45:04','2024-04-18 15:45:04'),(573,26,'hrv',0,180,0,0,1,NULL,NULL,'2024-04-18 15:45:04','2024-04-18 15:45:04','2024-04-18 15:45:04'),(574,26,'hsb',0,181,0,0,1,NULL,NULL,'2024-04-18 15:45:04','2024-04-18 15:45:04','2024-04-18 15:45:04'),(575,26,'hun',0,182,0,0,1,NULL,NULL,'2024-04-18 15:45:04','2024-04-18 15:45:04','2024-04-18 15:45:04'),(576,26,'hup',0,183,0,0,1,NULL,NULL,'2024-04-18 15:45:04','2024-04-18 15:45:04','2024-04-18 15:45:04'),(577,26,'iba',0,184,0,0,1,NULL,NULL,'2024-04-18 15:45:04','2024-04-18 15:45:04','2024-04-18 15:45:04'),(578,26,'ibo',0,185,0,0,1,NULL,NULL,'2024-04-18 15:45:04','2024-04-18 15:45:04','2024-04-18 15:45:04'),(579,26,'ice',0,186,0,0,1,NULL,NULL,'2024-04-18 15:45:05','2024-04-18 15:45:05','2024-04-18 15:45:05'),(580,26,'ido',0,187,0,0,1,NULL,NULL,'2024-04-18 15:45:05','2024-04-18 15:45:05','2024-04-18 15:45:05'),(581,26,'iii',0,188,0,0,1,NULL,NULL,'2024-04-18 15:45:05','2024-04-18 15:45:05','2024-04-18 15:45:05'),(582,26,'ijo',0,189,0,0,1,NULL,NULL,'2024-04-18 15:45:05','2024-04-18 15:45:05','2024-04-18 15:45:05'),(583,26,'iku',0,190,0,0,1,NULL,NULL,'2024-04-18 15:45:05','2024-04-18 15:45:05','2024-04-18 15:45:05'),(584,26,'ile',0,191,0,0,1,NULL,NULL,'2024-04-18 15:45:05','2024-04-18 15:45:05','2024-04-18 15:45:05'),(585,26,'ilo',0,192,0,0,1,NULL,NULL,'2024-04-18 15:45:05','2024-04-18 15:45:05','2024-04-18 15:45:05'),(586,26,'ina',0,193,0,0,1,NULL,NULL,'2024-04-18 15:45:05','2024-04-18 15:45:05','2024-04-18 15:45:05'),(587,26,'inc',0,194,0,0,1,NULL,NULL,'2024-04-18 15:45:05','2024-04-18 15:45:05','2024-04-18 15:45:05'),(588,26,'ind',0,195,0,0,1,NULL,NULL,'2024-04-18 15:45:05','2024-04-18 15:45:05','2024-04-18 15:45:05'),(589,26,'ine',0,196,0,0,1,NULL,NULL,'2024-04-18 15:45:05','2024-04-18 15:45:05','2024-04-18 15:45:05'),(590,26,'inh',0,197,0,0,1,NULL,NULL,'2024-04-18 15:45:05','2024-04-18 15:45:05','2024-04-18 15:45:05'),(591,26,'ipk',0,198,0,0,1,NULL,NULL,'2024-04-18 15:45:05','2024-04-18 15:45:05','2024-04-18 15:45:05'),(592,26,'ira',0,199,0,0,1,NULL,NULL,'2024-04-18 15:45:05','2024-04-18 15:45:05','2024-04-18 15:45:05'),(593,26,'iro',0,200,0,0,1,NULL,NULL,'2024-04-18 15:45:05','2024-04-18 15:45:05','2024-04-18 15:45:05'),(594,26,'ita',0,201,0,0,1,NULL,NULL,'2024-04-18 15:45:05','2024-04-18 15:45:05','2024-04-18 15:45:05'),(595,26,'jav',0,202,0,0,1,NULL,NULL,'2024-04-18 15:45:05','2024-04-18 15:45:05','2024-04-18 15:45:05'),(596,26,'jbo',0,203,0,0,1,NULL,NULL,'2024-04-18 15:45:05','2024-04-18 15:45:05','2024-04-18 15:45:05'),(597,26,'jpn',0,204,0,0,1,NULL,NULL,'2024-04-18 15:45:05','2024-04-18 15:45:05','2024-04-18 15:45:05'),(598,26,'jpr',0,205,0,0,1,NULL,NULL,'2024-04-18 15:45:05','2024-04-18 15:45:05','2024-04-18 15:45:05'),(599,26,'jrb',0,206,0,0,1,NULL,NULL,'2024-04-18 15:45:05','2024-04-18 15:45:05','2024-04-18 15:45:05'),(600,26,'kaa',0,207,0,0,1,NULL,NULL,'2024-04-18 15:45:05','2024-04-18 15:45:05','2024-04-18 15:45:05'),(601,26,'kab',0,208,0,0,1,NULL,NULL,'2024-04-18 15:45:05','2024-04-18 15:45:05','2024-04-18 15:45:05'),(602,26,'kac',0,209,0,0,1,NULL,NULL,'2024-04-18 15:45:05','2024-04-18 15:45:05','2024-04-18 15:45:05'),(603,26,'kal',0,210,0,0,1,NULL,NULL,'2024-04-18 15:45:05','2024-04-18 15:45:05','2024-04-18 15:45:05'),(604,26,'kam',0,211,0,0,1,NULL,NULL,'2024-04-18 15:45:05','2024-04-18 15:45:05','2024-04-18 15:45:05'),(605,26,'kan',0,212,0,0,1,NULL,NULL,'2024-04-18 15:45:05','2024-04-18 15:45:05','2024-04-18 15:45:05'),(606,26,'kar',0,213,0,0,1,NULL,NULL,'2024-04-18 15:45:05','2024-04-18 15:45:05','2024-04-18 15:45:05'),(607,26,'kas',0,214,0,0,1,NULL,NULL,'2024-04-18 15:45:05','2024-04-18 15:45:05','2024-04-18 15:45:05'),(608,26,'kau',0,215,0,0,1,NULL,NULL,'2024-04-18 15:45:05','2024-04-18 15:45:05','2024-04-18 15:45:05'),(609,26,'kaw',0,216,0,0,1,NULL,NULL,'2024-04-18 15:45:05','2024-04-18 15:45:05','2024-04-18 15:45:05'),(610,26,'kaz',0,217,0,0,1,NULL,NULL,'2024-04-18 15:45:05','2024-04-18 15:45:05','2024-04-18 15:45:05'),(611,26,'kbd',0,218,0,0,1,NULL,NULL,'2024-04-18 15:45:05','2024-04-18 15:45:05','2024-04-18 15:45:05'),(612,26,'kha',0,219,0,0,1,NULL,NULL,'2024-04-18 15:45:05','2024-04-18 15:45:05','2024-04-18 15:45:05'),(613,26,'khi',0,220,0,0,1,NULL,NULL,'2024-04-18 15:45:05','2024-04-18 15:45:05','2024-04-18 15:45:05'),(614,26,'khm',0,221,0,0,1,NULL,NULL,'2024-04-18 15:45:05','2024-04-18 15:45:05','2024-04-18 15:45:05'),(615,26,'kho',0,222,0,0,1,NULL,NULL,'2024-04-18 15:45:05','2024-04-18 15:45:05','2024-04-18 15:45:05'),(616,26,'kik',0,223,0,0,1,NULL,NULL,'2024-04-18 15:45:06','2024-04-18 15:45:06','2024-04-18 15:45:06'),(617,26,'kin',0,224,0,0,1,NULL,NULL,'2024-04-18 15:45:06','2024-04-18 15:45:06','2024-04-18 15:45:06'),(618,26,'kir',0,225,0,0,1,NULL,NULL,'2024-04-18 15:45:06','2024-04-18 15:45:06','2024-04-18 15:45:06'),(619,26,'kmb',0,226,0,0,1,NULL,NULL,'2024-04-18 15:45:06','2024-04-18 15:45:06','2024-04-18 15:45:06'),(620,26,'kok',0,227,0,0,1,NULL,NULL,'2024-04-18 15:45:06','2024-04-18 15:45:06','2024-04-18 15:45:06'),(621,26,'kom',0,228,0,0,1,NULL,NULL,'2024-04-18 15:45:06','2024-04-18 15:45:06','2024-04-18 15:45:06'),(622,26,'kon',0,229,0,0,1,NULL,NULL,'2024-04-18 15:45:06','2024-04-18 15:45:06','2024-04-18 15:45:06'),(623,26,'kor',0,230,0,0,1,NULL,NULL,'2024-04-18 15:45:06','2024-04-18 15:45:06','2024-04-18 15:45:06'),(624,26,'kos',0,231,0,0,1,NULL,NULL,'2024-04-18 15:45:06','2024-04-18 15:45:06','2024-04-18 15:45:06'),(625,26,'kpe',0,232,0,0,1,NULL,NULL,'2024-04-18 15:45:06','2024-04-18 15:45:06','2024-04-18 15:45:06'),(626,26,'krc',0,233,0,0,1,NULL,NULL,'2024-04-18 15:45:06','2024-04-18 15:45:06','2024-04-18 15:45:06'),(627,26,'krl',0,234,0,0,1,NULL,NULL,'2024-04-18 15:45:06','2024-04-18 15:45:06','2024-04-18 15:45:06'),(628,26,'kro',0,235,0,0,1,NULL,NULL,'2024-04-18 15:45:06','2024-04-18 15:45:06','2024-04-18 15:45:06'),(629,26,'kru',0,236,0,0,1,NULL,NULL,'2024-04-18 15:45:06','2024-04-18 15:45:06','2024-04-18 15:45:06'),(630,26,'kua',0,237,0,0,1,NULL,NULL,'2024-04-18 15:45:06','2024-04-18 15:45:06','2024-04-18 15:45:06'),(631,26,'kum',0,238,0,0,1,NULL,NULL,'2024-04-18 15:45:06','2024-04-18 15:45:06','2024-04-18 15:45:06'),(632,26,'kur',0,239,0,0,1,NULL,NULL,'2024-04-18 15:45:06','2024-04-18 15:45:06','2024-04-18 15:45:06'),(633,26,'kut',0,240,0,0,1,NULL,NULL,'2024-04-18 15:45:06','2024-04-18 15:45:06','2024-04-18 15:45:06'),(634,26,'lad',0,241,0,0,1,NULL,NULL,'2024-04-18 15:45:06','2024-04-18 15:45:06','2024-04-18 15:45:06'),(635,26,'lah',0,242,0,0,1,NULL,NULL,'2024-04-18 15:45:06','2024-04-18 15:45:06','2024-04-18 15:45:06'),(636,26,'lam',0,243,0,0,1,NULL,NULL,'2024-04-18 15:45:06','2024-04-18 15:45:06','2024-04-18 15:45:06'),(637,26,'lao',0,244,0,0,1,NULL,NULL,'2024-04-18 15:45:06','2024-04-18 15:45:06','2024-04-18 15:45:06'),(638,26,'lat',0,245,0,0,1,NULL,NULL,'2024-04-18 15:45:06','2024-04-18 15:45:06','2024-04-18 15:45:06'),(639,26,'lav',0,246,0,0,1,NULL,NULL,'2024-04-18 15:45:06','2024-04-18 15:45:06','2024-04-18 15:45:06'),(640,26,'lez',0,247,0,0,1,NULL,NULL,'2024-04-18 15:45:06','2024-04-18 15:45:06','2024-04-18 15:45:06'),(641,26,'lim',0,248,0,0,1,NULL,NULL,'2024-04-18 15:45:06','2024-04-18 15:45:06','2024-04-18 15:45:06'),(642,26,'lin',0,249,0,0,1,NULL,NULL,'2024-04-18 15:45:06','2024-04-18 15:45:06','2024-04-18 15:45:06'),(643,26,'lit',0,250,0,0,1,NULL,NULL,'2024-04-18 15:45:06','2024-04-18 15:45:06','2024-04-18 15:45:06'),(644,26,'lol',0,251,0,0,1,NULL,NULL,'2024-04-18 15:45:06','2024-04-18 15:45:06','2024-04-18 15:45:06'),(645,26,'loz',0,252,0,0,1,NULL,NULL,'2024-04-18 15:45:06','2024-04-18 15:45:06','2024-04-18 15:45:06'),(646,26,'ltz',0,253,0,0,1,NULL,NULL,'2024-04-18 15:45:06','2024-04-18 15:45:06','2024-04-18 15:45:06'),(647,26,'lua',0,254,0,0,1,NULL,NULL,'2024-04-18 15:45:06','2024-04-18 15:45:06','2024-04-18 15:45:06'),(648,26,'lub',0,255,0,0,1,NULL,NULL,'2024-04-18 15:45:06','2024-04-18 15:45:06','2024-04-18 15:45:06'),(649,26,'lug',0,256,0,0,1,NULL,NULL,'2024-04-18 15:45:06','2024-04-18 15:45:06','2024-04-18 15:45:06'),(650,26,'lui',0,257,0,0,1,NULL,NULL,'2024-04-18 15:45:06','2024-04-18 15:45:06','2024-04-18 15:45:06'),(651,26,'lun',0,258,0,0,1,NULL,NULL,'2024-04-18 15:45:07','2024-04-18 15:45:07','2024-04-18 15:45:07'),(652,26,'luo',0,259,0,0,1,NULL,NULL,'2024-04-18 15:45:07','2024-04-18 15:45:07','2024-04-18 15:45:07'),(653,26,'lus',0,260,0,0,1,NULL,NULL,'2024-04-18 15:45:07','2024-04-18 15:45:07','2024-04-18 15:45:07'),(654,26,'mac',0,261,0,0,1,NULL,NULL,'2024-04-18 15:45:07','2024-04-18 15:45:07','2024-04-18 15:45:07'),(655,26,'mad',0,262,0,0,1,NULL,NULL,'2024-04-18 15:45:07','2024-04-18 15:45:07','2024-04-18 15:45:07'),(656,26,'mag',0,263,0,0,1,NULL,NULL,'2024-04-18 15:45:07','2024-04-18 15:45:07','2024-04-18 15:45:07'),(657,26,'mah',0,264,0,0,1,NULL,NULL,'2024-04-18 15:45:07','2024-04-18 15:45:07','2024-04-18 15:45:07'),(658,26,'mai',0,265,0,0,1,NULL,NULL,'2024-04-18 15:45:07','2024-04-18 15:45:07','2024-04-18 15:45:07'),(659,26,'mak',0,266,0,0,1,NULL,NULL,'2024-04-18 15:45:07','2024-04-18 15:45:07','2024-04-18 15:45:07'),(660,26,'mal',0,267,0,0,1,NULL,NULL,'2024-04-18 15:45:07','2024-04-18 15:45:07','2024-04-18 15:45:07'),(661,26,'man',0,268,0,0,1,NULL,NULL,'2024-04-18 15:45:07','2024-04-18 15:45:07','2024-04-18 15:45:07'),(662,26,'mao',0,269,0,0,1,NULL,NULL,'2024-04-18 15:45:07','2024-04-18 15:45:07','2024-04-18 15:45:07'),(663,26,'map',0,270,0,0,1,NULL,NULL,'2024-04-18 15:45:07','2024-04-18 15:45:07','2024-04-18 15:45:07'),(664,26,'mar',0,271,0,0,1,NULL,NULL,'2024-04-18 15:45:07','2024-04-18 15:45:07','2024-04-18 15:45:07'),(665,26,'mas',0,272,0,0,1,NULL,NULL,'2024-04-18 15:45:07','2024-04-18 15:45:07','2024-04-18 15:45:07'),(666,26,'may',0,273,0,0,1,NULL,NULL,'2024-04-18 15:45:07','2024-04-18 15:45:07','2024-04-18 15:45:07'),(667,26,'mdf',0,274,0,0,1,NULL,NULL,'2024-04-18 15:45:07','2024-04-18 15:45:07','2024-04-18 15:45:07'),(668,26,'mdr',0,275,0,0,1,NULL,NULL,'2024-04-18 15:45:07','2024-04-18 15:45:07','2024-04-18 15:45:07'),(669,26,'men',0,276,0,0,1,NULL,NULL,'2024-04-18 15:45:07','2024-04-18 15:45:07','2024-04-18 15:45:07'),(670,26,'mga',0,277,0,0,1,NULL,NULL,'2024-04-18 15:45:07','2024-04-18 15:45:07','2024-04-18 15:45:07'),(671,26,'mic',0,278,0,0,1,NULL,NULL,'2024-04-18 15:45:07','2024-04-18 15:45:07','2024-04-18 15:45:07'),(672,26,'min',0,279,0,0,1,NULL,NULL,'2024-04-18 15:45:07','2024-04-18 15:45:07','2024-04-18 15:45:07'),(673,26,'mis',0,280,0,0,1,NULL,NULL,'2024-04-18 15:45:07','2024-04-18 15:45:07','2024-04-18 15:45:07'),(674,26,'mkh',0,281,0,0,1,NULL,NULL,'2024-04-18 15:45:07','2024-04-18 15:45:07','2024-04-18 15:45:07'),(675,26,'mlg',0,282,0,0,1,NULL,NULL,'2024-04-18 15:45:07','2024-04-18 15:45:07','2024-04-18 15:45:07'),(676,26,'mlt',0,283,0,0,1,NULL,NULL,'2024-04-18 15:45:07','2024-04-18 15:45:07','2024-04-18 15:45:07'),(677,26,'mnc',0,284,0,0,1,NULL,NULL,'2024-04-18 15:45:07','2024-04-18 15:45:07','2024-04-18 15:45:07'),(678,26,'mni',0,285,0,0,1,NULL,NULL,'2024-04-18 15:45:07','2024-04-18 15:45:07','2024-04-18 15:45:07'),(679,26,'mno',0,286,0,0,1,NULL,NULL,'2024-04-18 15:45:07','2024-04-18 15:45:07','2024-04-18 15:45:07'),(680,26,'moh',0,287,0,0,1,NULL,NULL,'2024-04-18 15:45:07','2024-04-18 15:45:07','2024-04-18 15:45:07'),(681,26,'mon',0,288,0,0,1,NULL,NULL,'2024-04-18 15:45:07','2024-04-18 15:45:07','2024-04-18 15:45:07'),(682,26,'mos',0,289,0,0,1,NULL,NULL,'2024-04-18 15:45:07','2024-04-18 15:45:07','2024-04-18 15:45:07'),(683,26,'mul',0,290,0,0,1,NULL,NULL,'2024-04-18 15:45:07','2024-04-18 15:45:07','2024-04-18 15:45:07'),(684,26,'mun',0,291,0,0,1,NULL,NULL,'2024-04-18 15:45:07','2024-04-18 15:45:07','2024-04-18 15:45:07'),(685,26,'mus',0,292,0,0,1,NULL,NULL,'2024-04-18 15:45:07','2024-04-18 15:45:07','2024-04-18 15:45:07'),(686,26,'mwl',0,293,0,0,1,NULL,NULL,'2024-04-18 15:45:07','2024-04-18 15:45:07','2024-04-18 15:45:07'),(687,26,'mwr',0,294,0,0,1,NULL,NULL,'2024-04-18 15:45:08','2024-04-18 15:45:08','2024-04-18 15:45:08'),(688,26,'myn',0,295,0,0,1,NULL,NULL,'2024-04-18 15:45:08','2024-04-18 15:45:08','2024-04-18 15:45:08'),(689,26,'myv',0,296,0,0,1,NULL,NULL,'2024-04-18 15:45:08','2024-04-18 15:45:08','2024-04-18 15:45:08'),(690,26,'nah',0,297,0,0,1,NULL,NULL,'2024-04-18 15:45:08','2024-04-18 15:45:08','2024-04-18 15:45:08'),(691,26,'nai',0,298,0,0,1,NULL,NULL,'2024-04-18 15:45:08','2024-04-18 15:45:08','2024-04-18 15:45:08'),(692,26,'nap',0,299,0,0,1,NULL,NULL,'2024-04-18 15:45:08','2024-04-18 15:45:08','2024-04-18 15:45:08'),(693,26,'nau',0,300,0,0,1,NULL,NULL,'2024-04-18 15:45:08','2024-04-18 15:45:08','2024-04-18 15:45:08'),(694,26,'nav',0,301,0,0,1,NULL,NULL,'2024-04-18 15:45:08','2024-04-18 15:45:08','2024-04-18 15:45:08'),(695,26,'nbl',0,302,0,0,1,NULL,NULL,'2024-04-18 15:45:08','2024-04-18 15:45:08','2024-04-18 15:45:08'),(696,26,'nde',0,303,0,0,1,NULL,NULL,'2024-04-18 15:45:08','2024-04-18 15:45:08','2024-04-18 15:45:08'),(697,26,'ndo',0,304,0,0,1,NULL,NULL,'2024-04-18 15:45:08','2024-04-18 15:45:08','2024-04-18 15:45:08'),(698,26,'nds',0,305,0,0,1,NULL,NULL,'2024-04-18 15:45:08','2024-04-18 15:45:08','2024-04-18 15:45:08'),(699,26,'nep',0,306,0,0,1,NULL,NULL,'2024-04-18 15:45:08','2024-04-18 15:45:08','2024-04-18 15:45:08'),(700,26,'new',0,307,0,0,1,NULL,NULL,'2024-04-18 15:45:08','2024-04-18 15:45:08','2024-04-18 15:45:08'),(701,26,'nia',0,308,0,0,1,NULL,NULL,'2024-04-18 15:45:08','2024-04-18 15:45:08','2024-04-18 15:45:08'),(702,26,'nic',0,309,0,0,1,NULL,NULL,'2024-04-18 15:45:08','2024-04-18 15:45:08','2024-04-18 15:45:08'),(703,26,'niu',0,310,0,0,1,NULL,NULL,'2024-04-18 15:45:08','2024-04-18 15:45:08','2024-04-18 15:45:08'),(704,26,'nno',0,311,0,0,1,NULL,NULL,'2024-04-18 15:45:08','2024-04-18 15:45:08','2024-04-18 15:45:08'),(705,26,'nob',0,312,0,0,1,NULL,NULL,'2024-04-18 15:45:08','2024-04-18 15:45:08','2024-04-18 15:45:08'),(706,26,'nog',0,313,0,0,1,NULL,NULL,'2024-04-18 15:45:08','2024-04-18 15:45:08','2024-04-18 15:45:08'),(707,26,'non',0,314,0,0,1,NULL,NULL,'2024-04-18 15:45:08','2024-04-18 15:45:08','2024-04-18 15:45:08'),(708,26,'nor',0,315,0,0,1,NULL,NULL,'2024-04-18 15:45:08','2024-04-18 15:45:08','2024-04-18 15:45:08'),(709,26,'nqo',0,316,0,0,1,NULL,NULL,'2024-04-18 15:45:08','2024-04-18 15:45:08','2024-04-18 15:45:08'),(710,26,'nso',0,317,0,0,1,NULL,NULL,'2024-04-18 15:45:08','2024-04-18 15:45:08','2024-04-18 15:45:08'),(711,26,'nub',0,318,0,0,1,NULL,NULL,'2024-04-18 15:45:08','2024-04-18 15:45:08','2024-04-18 15:45:08'),(712,26,'nwc',0,319,0,0,1,NULL,NULL,'2024-04-18 15:45:08','2024-04-18 15:45:08','2024-04-18 15:45:08'),(713,26,'nya',0,320,0,0,1,NULL,NULL,'2024-04-18 15:45:08','2024-04-18 15:45:08','2024-04-18 15:45:08'),(714,26,'nym',0,321,0,0,1,NULL,NULL,'2024-04-18 15:45:08','2024-04-18 15:45:08','2024-04-18 15:45:08'),(715,26,'nyn',0,322,0,0,1,NULL,NULL,'2024-04-18 15:45:08','2024-04-18 15:45:08','2024-04-18 15:45:08'),(716,26,'nyo',0,323,0,0,1,NULL,NULL,'2024-04-18 15:45:08','2024-04-18 15:45:08','2024-04-18 15:45:08'),(717,26,'nzi',0,324,0,0,1,NULL,NULL,'2024-04-18 15:45:08','2024-04-18 15:45:08','2024-04-18 15:45:08'),(718,26,'oci',0,325,0,0,1,NULL,NULL,'2024-04-18 15:45:08','2024-04-18 15:45:08','2024-04-18 15:45:08'),(719,26,'oji',0,326,0,0,1,NULL,NULL,'2024-04-18 15:45:08','2024-04-18 15:45:08','2024-04-18 15:45:08'),(720,26,'ori',0,327,0,0,1,NULL,NULL,'2024-04-18 15:45:08','2024-04-18 15:45:08','2024-04-18 15:45:08'),(721,26,'orm',0,328,0,0,1,NULL,NULL,'2024-04-18 15:45:08','2024-04-18 15:45:08','2024-04-18 15:45:08'),(722,26,'osa',0,329,0,0,1,NULL,NULL,'2024-04-18 15:45:08','2024-04-18 15:45:08','2024-04-18 15:45:08'),(723,26,'oss',0,330,0,0,1,NULL,NULL,'2024-04-18 15:45:08','2024-04-18 15:45:08','2024-04-18 15:45:08'),(724,26,'ota',0,331,0,0,1,NULL,NULL,'2024-04-18 15:45:08','2024-04-18 15:45:08','2024-04-18 15:45:08'),(725,26,'oto',0,332,0,0,1,NULL,NULL,'2024-04-18 15:45:08','2024-04-18 15:45:08','2024-04-18 15:45:08'),(726,26,'paa',0,333,0,0,1,NULL,NULL,'2024-04-18 15:45:09','2024-04-18 15:45:09','2024-04-18 15:45:09'),(727,26,'pag',0,334,0,0,1,NULL,NULL,'2024-04-18 15:45:09','2024-04-18 15:45:09','2024-04-18 15:45:09'),(728,26,'pal',0,335,0,0,1,NULL,NULL,'2024-04-18 15:45:09','2024-04-18 15:45:09','2024-04-18 15:45:09'),(729,26,'pam',0,336,0,0,1,NULL,NULL,'2024-04-18 15:45:09','2024-04-18 15:45:09','2024-04-18 15:45:09'),(730,26,'pan',0,337,0,0,1,NULL,NULL,'2024-04-18 15:45:09','2024-04-18 15:45:09','2024-04-18 15:45:09'),(731,26,'pap',0,338,0,0,1,NULL,NULL,'2024-04-18 15:45:09','2024-04-18 15:45:09','2024-04-18 15:45:09'),(732,26,'pau',0,339,0,0,1,NULL,NULL,'2024-04-18 15:45:09','2024-04-18 15:45:09','2024-04-18 15:45:09'),(733,26,'peo',0,340,0,0,1,NULL,NULL,'2024-04-18 15:45:09','2024-04-18 15:45:09','2024-04-18 15:45:09'),(734,26,'per',0,341,0,0,1,NULL,NULL,'2024-04-18 15:45:09','2024-04-18 15:45:09','2024-04-18 15:45:09'),(735,26,'phi',0,342,0,0,1,NULL,NULL,'2024-04-18 15:45:09','2024-04-18 15:45:09','2024-04-18 15:45:09'),(736,26,'phn',0,343,0,0,1,NULL,NULL,'2024-04-18 15:45:09','2024-04-18 15:45:09','2024-04-18 15:45:09'),(737,26,'pli',0,344,0,0,1,NULL,NULL,'2024-04-18 15:45:09','2024-04-18 15:45:09','2024-04-18 15:45:09'),(738,26,'pol',0,345,0,0,1,NULL,NULL,'2024-04-18 15:45:09','2024-04-18 15:45:09','2024-04-18 15:45:09'),(739,26,'pon',0,346,0,0,1,NULL,NULL,'2024-04-18 15:45:09','2024-04-18 15:45:09','2024-04-18 15:45:09'),(740,26,'por',0,347,0,0,1,NULL,NULL,'2024-04-18 15:45:09','2024-04-18 15:45:09','2024-04-18 15:45:09'),(741,26,'pra',0,348,0,0,1,NULL,NULL,'2024-04-18 15:45:09','2024-04-18 15:45:09','2024-04-18 15:45:09'),(742,26,'pro',0,349,0,0,1,NULL,NULL,'2024-04-18 15:45:09','2024-04-18 15:45:09','2024-04-18 15:45:09'),(743,26,'pus',0,350,0,0,1,NULL,NULL,'2024-04-18 15:45:09','2024-04-18 15:45:09','2024-04-18 15:45:09'),(745,26,'que',0,352,0,0,1,NULL,NULL,'2024-04-18 15:45:09','2024-04-18 15:45:09','2024-04-18 15:45:09'),(746,26,'raj',0,353,0,0,1,NULL,NULL,'2024-04-18 15:45:09','2024-04-18 15:45:09','2024-04-18 15:45:09'),(747,26,'rap',0,354,0,0,1,NULL,NULL,'2024-04-18 15:45:09','2024-04-18 15:45:09','2024-04-18 15:45:09'),(748,26,'rar',0,355,0,0,1,NULL,NULL,'2024-04-18 15:45:09','2024-04-18 15:45:09','2024-04-18 15:45:09'),(749,26,'roa',0,356,0,0,1,NULL,NULL,'2024-04-18 15:45:09','2024-04-18 15:45:09','2024-04-18 15:45:09'),(750,26,'roh',0,357,0,0,1,NULL,NULL,'2024-04-18 15:45:09','2024-04-18 15:45:09','2024-04-18 15:45:09'),(751,26,'rom',0,358,0,0,1,NULL,NULL,'2024-04-18 15:45:09','2024-04-18 15:45:09','2024-04-18 15:45:09'),(752,26,'rum',0,359,0,0,1,NULL,NULL,'2024-04-18 15:45:09','2024-04-18 15:45:09','2024-04-18 15:45:09'),(753,26,'run',0,360,0,0,1,NULL,NULL,'2024-04-18 15:45:09','2024-04-18 15:45:09','2024-04-18 15:45:09'),(754,26,'rup',0,361,0,0,1,NULL,NULL,'2024-04-18 15:45:09','2024-04-18 15:45:09','2024-04-18 15:45:09'),(755,26,'rus',0,362,0,0,1,NULL,NULL,'2024-04-18 15:45:09','2024-04-18 15:45:09','2024-04-18 15:45:09'),(756,26,'sad',0,363,0,0,1,NULL,NULL,'2024-04-18 15:45:09','2024-04-18 15:45:09','2024-04-18 15:45:09'),(757,26,'sag',0,364,0,0,1,NULL,NULL,'2024-04-18 15:45:09','2024-04-18 15:45:09','2024-04-18 15:45:09'),(758,26,'sah',0,365,0,0,1,NULL,NULL,'2024-04-18 15:45:09','2024-04-18 15:45:09','2024-04-18 15:45:09'),(759,26,'sai',0,366,0,0,1,NULL,NULL,'2024-04-18 15:45:09','2024-04-18 15:45:09','2024-04-18 15:45:09'),(760,26,'sal',0,367,0,0,1,NULL,NULL,'2024-04-18 15:45:09','2024-04-18 15:45:09','2024-04-18 15:45:09'),(761,26,'sam',0,368,0,0,1,NULL,NULL,'2024-04-18 15:45:09','2024-04-18 15:45:09','2024-04-18 15:45:09'),(762,26,'san',0,369,0,0,1,NULL,NULL,'2024-04-18 15:45:09','2024-04-18 15:45:09','2024-04-18 15:45:09'),(763,26,'sas',0,370,0,0,1,NULL,NULL,'2024-04-18 15:45:10','2024-04-18 15:45:10','2024-04-18 15:45:10'),(764,26,'sat',0,371,0,0,1,NULL,NULL,'2024-04-18 15:45:10','2024-04-18 15:45:10','2024-04-18 15:45:10'),(765,26,'scn',0,372,0,0,1,NULL,NULL,'2024-04-18 15:45:10','2024-04-18 15:45:10','2024-04-18 15:45:10'),(766,26,'sco',0,373,0,0,1,NULL,NULL,'2024-04-18 15:45:10','2024-04-18 15:45:10','2024-04-18 15:45:10'),(767,26,'sel',0,374,0,0,1,NULL,NULL,'2024-04-18 15:45:10','2024-04-18 15:45:10','2024-04-18 15:45:10'),(768,26,'sem',0,375,0,0,1,NULL,NULL,'2024-04-18 15:45:10','2024-04-18 15:45:10','2024-04-18 15:45:10'),(769,26,'sga',0,376,0,0,1,NULL,NULL,'2024-04-18 15:45:10','2024-04-18 15:45:10','2024-04-18 15:45:10'),(770,26,'sgn',0,377,0,0,1,NULL,NULL,'2024-04-18 15:45:10','2024-04-18 15:45:10','2024-04-18 15:45:10'),(771,26,'shn',0,378,0,0,1,NULL,NULL,'2024-04-18 15:45:10','2024-04-18 15:45:10','2024-04-18 15:45:10'),(772,26,'sid',0,379,0,0,1,NULL,NULL,'2024-04-18 15:45:10','2024-04-18 15:45:10','2024-04-18 15:45:10'),(773,26,'sin',0,380,0,0,1,NULL,NULL,'2024-04-18 15:45:10','2024-04-18 15:45:10','2024-04-18 15:45:10'),(774,26,'sio',0,381,0,0,1,NULL,NULL,'2024-04-18 15:45:10','2024-04-18 15:45:10','2024-04-18 15:45:10'),(775,26,'sit',0,382,0,0,1,NULL,NULL,'2024-04-18 15:45:10','2024-04-18 15:45:10','2024-04-18 15:45:10'),(776,26,'sla',0,383,0,0,1,NULL,NULL,'2024-04-18 15:45:10','2024-04-18 15:45:10','2024-04-18 15:45:10'),(777,26,'slo',0,384,0,0,1,NULL,NULL,'2024-04-18 15:45:10','2024-04-18 15:45:10','2024-04-18 15:45:10'),(778,26,'slv',0,385,0,0,1,NULL,NULL,'2024-04-18 15:45:10','2024-04-18 15:45:10','2024-04-18 15:45:10'),(779,26,'sma',0,386,0,0,1,NULL,NULL,'2024-04-18 15:45:10','2024-04-18 15:45:10','2024-04-18 15:45:10'),(780,26,'sme',0,387,0,0,1,NULL,NULL,'2024-04-18 15:45:10','2024-04-18 15:45:10','2024-04-18 15:45:10'),(781,26,'smi',0,388,0,0,1,NULL,NULL,'2024-04-18 15:45:10','2024-04-18 15:45:10','2024-04-18 15:45:10'),(782,26,'smj',0,389,0,0,1,NULL,NULL,'2024-04-18 15:45:10','2024-04-18 15:45:10','2024-04-18 15:45:10'),(783,26,'smn',0,390,0,0,1,NULL,NULL,'2024-04-18 15:45:10','2024-04-18 15:45:10','2024-04-18 15:45:10'),(784,26,'smo',0,391,0,0,1,NULL,NULL,'2024-04-18 15:45:10','2024-04-18 15:45:10','2024-04-18 15:45:10'),(785,26,'sms',0,392,0,0,1,NULL,NULL,'2024-04-18 15:45:10','2024-04-18 15:45:10','2024-04-18 15:45:10'),(786,26,'sna',0,393,0,0,1,NULL,NULL,'2024-04-18 15:45:10','2024-04-18 15:45:10','2024-04-18 15:45:10'),(787,26,'snd',0,394,0,0,1,NULL,NULL,'2024-04-18 15:45:10','2024-04-18 15:45:10','2024-04-18 15:45:10'),(788,26,'snk',0,395,0,0,1,NULL,NULL,'2024-04-18 15:45:10','2024-04-18 15:45:10','2024-04-18 15:45:10'),(789,26,'sog',0,396,0,0,1,NULL,NULL,'2024-04-18 15:45:10','2024-04-18 15:45:10','2024-04-18 15:45:10'),(790,26,'som',0,397,0,0,1,NULL,NULL,'2024-04-18 15:45:10','2024-04-18 15:45:10','2024-04-18 15:45:10'),(791,26,'son',0,398,0,0,1,NULL,NULL,'2024-04-18 15:45:10','2024-04-18 15:45:10','2024-04-18 15:45:10'),(792,26,'sot',0,399,0,0,1,NULL,NULL,'2024-04-18 15:45:10','2024-04-18 15:45:10','2024-04-18 15:45:10'),(793,26,'spa',0,400,0,0,1,NULL,NULL,'2024-04-18 15:45:10','2024-04-18 15:45:10','2024-04-18 15:45:10'),(794,26,'srd',0,401,0,0,1,NULL,NULL,'2024-04-18 15:45:10','2024-04-18 15:45:10','2024-04-18 15:45:10'),(795,26,'srn',0,402,0,0,1,NULL,NULL,'2024-04-18 15:45:10','2024-04-18 15:45:10','2024-04-18 15:45:10'),(796,26,'srp',0,403,0,0,1,NULL,NULL,'2024-04-18 15:45:10','2024-04-18 15:45:10','2024-04-18 15:45:10'),(797,26,'srr',0,404,0,0,1,NULL,NULL,'2024-04-18 15:45:10','2024-04-18 15:45:10','2024-04-18 15:45:10'),(798,26,'ssa',0,405,0,0,1,NULL,NULL,'2024-04-18 15:45:10','2024-04-18 15:45:10','2024-04-18 15:45:10'),(799,26,'ssw',0,406,0,0,1,NULL,NULL,'2024-04-18 15:45:10','2024-04-18 15:45:10','2024-04-18 15:45:10'),(800,26,'suk',0,407,0,0,1,NULL,NULL,'2024-04-18 15:45:10','2024-04-18 15:45:10','2024-04-18 15:45:10'),(801,26,'sun',0,408,0,0,1,NULL,NULL,'2024-04-18 15:45:10','2024-04-18 15:45:10','2024-04-18 15:45:10'),(802,26,'sus',0,409,0,0,1,NULL,NULL,'2024-04-18 15:45:11','2024-04-18 15:45:11','2024-04-18 15:45:11'),(803,26,'sux',0,410,0,0,1,NULL,NULL,'2024-04-18 15:45:11','2024-04-18 15:45:11','2024-04-18 15:45:11'),(804,26,'swa',0,411,0,0,1,NULL,NULL,'2024-04-18 15:45:11','2024-04-18 15:45:11','2024-04-18 15:45:11'),(805,26,'swe',0,412,0,0,1,NULL,NULL,'2024-04-18 15:45:11','2024-04-18 15:45:11','2024-04-18 15:45:11'),(806,26,'syc',0,413,0,0,1,NULL,NULL,'2024-04-18 15:45:11','2024-04-18 15:45:11','2024-04-18 15:45:11'),(807,26,'syr',0,414,0,0,1,NULL,NULL,'2024-04-18 15:45:11','2024-04-18 15:45:11','2024-04-18 15:45:11'),(808,26,'tah',0,415,0,0,1,NULL,NULL,'2024-04-18 15:45:11','2024-04-18 15:45:11','2024-04-18 15:45:11'),(809,26,'tai',0,416,0,0,1,NULL,NULL,'2024-04-18 15:45:11','2024-04-18 15:45:11','2024-04-18 15:45:11'),(810,26,'tam',0,417,0,0,1,NULL,NULL,'2024-04-18 15:45:11','2024-04-18 15:45:11','2024-04-18 15:45:11'),(811,26,'tat',0,418,0,0,1,NULL,NULL,'2024-04-18 15:45:11','2024-04-18 15:45:11','2024-04-18 15:45:11'),(812,26,'tel',0,419,0,0,1,NULL,NULL,'2024-04-18 15:45:11','2024-04-18 15:45:11','2024-04-18 15:45:11'),(813,26,'tem',0,420,0,0,1,NULL,NULL,'2024-04-18 15:45:11','2024-04-18 15:45:11','2024-04-18 15:45:11'),(814,26,'ter',0,421,0,0,1,NULL,NULL,'2024-04-18 15:45:11','2024-04-18 15:45:11','2024-04-18 15:45:11'),(815,26,'tet',0,422,0,0,1,NULL,NULL,'2024-04-18 15:45:11','2024-04-18 15:45:11','2024-04-18 15:45:11'),(816,26,'tgk',0,423,0,0,1,NULL,NULL,'2024-04-18 15:45:11','2024-04-18 15:45:11','2024-04-18 15:45:11'),(817,26,'tgl',0,424,0,0,1,NULL,NULL,'2024-04-18 15:45:11','2024-04-18 15:45:11','2024-04-18 15:45:11'),(818,26,'tha',0,425,0,0,1,NULL,NULL,'2024-04-18 15:45:11','2024-04-18 15:45:11','2024-04-18 15:45:11'),(819,26,'tib',0,426,0,0,1,NULL,NULL,'2024-04-18 15:45:11','2024-04-18 15:45:11','2024-04-18 15:45:11'),(820,26,'tig',0,427,0,0,1,NULL,NULL,'2024-04-18 15:45:11','2024-04-18 15:45:11','2024-04-18 15:45:11'),(821,26,'tir',0,428,0,0,1,NULL,NULL,'2024-04-18 15:45:11','2024-04-18 15:45:11','2024-04-18 15:45:11'),(822,26,'tiv',0,429,0,0,1,NULL,NULL,'2024-04-18 15:45:11','2024-04-18 15:45:11','2024-04-18 15:45:11'),(823,26,'tkl',0,430,0,0,1,NULL,NULL,'2024-04-18 15:45:11','2024-04-18 15:45:11','2024-04-18 15:45:11'),(824,26,'tlh',0,431,0,0,1,NULL,NULL,'2024-04-18 15:45:11','2024-04-18 15:45:11','2024-04-18 15:45:11'),(825,26,'tli',0,432,0,0,1,NULL,NULL,'2024-04-18 15:45:11','2024-04-18 15:45:11','2024-04-18 15:45:11'),(826,26,'tmh',0,433,0,0,1,NULL,NULL,'2024-04-18 15:45:11','2024-04-18 15:45:11','2024-04-18 15:45:11'),(827,26,'tog',0,434,0,0,1,NULL,NULL,'2024-04-18 15:45:11','2024-04-18 15:45:11','2024-04-18 15:45:11'),(828,26,'ton',0,435,0,0,1,NULL,NULL,'2024-04-18 15:45:11','2024-04-18 15:45:11','2024-04-18 15:45:11'),(829,26,'tpi',0,436,0,0,1,NULL,NULL,'2024-04-18 15:45:11','2024-04-18 15:45:11','2024-04-18 15:45:11'),(830,26,'tsi',0,437,0,0,1,NULL,NULL,'2024-04-18 15:45:11','2024-04-18 15:45:11','2024-04-18 15:45:11'),(831,26,'tsn',0,438,0,0,1,NULL,NULL,'2024-04-18 15:45:11','2024-04-18 15:45:11','2024-04-18 15:45:11'),(832,26,'tso',0,439,0,0,1,NULL,NULL,'2024-04-18 15:45:11','2024-04-18 15:45:11','2024-04-18 15:45:11'),(833,26,'tuk',0,440,0,0,1,NULL,NULL,'2024-04-18 15:45:11','2024-04-18 15:45:11','2024-04-18 15:45:11'),(834,26,'tum',0,441,0,0,1,NULL,NULL,'2024-04-18 15:45:11','2024-04-18 15:45:11','2024-04-18 15:45:11'),(835,26,'tup',0,442,0,0,1,NULL,NULL,'2024-04-18 15:45:11','2024-04-18 15:45:11','2024-04-18 15:45:11'),(836,26,'tur',0,443,0,0,1,NULL,NULL,'2024-04-18 15:45:11','2024-04-18 15:45:11','2024-04-18 15:45:11'),(837,26,'tut',0,444,0,0,1,NULL,NULL,'2024-04-18 15:45:11','2024-04-18 15:45:11','2024-04-18 15:45:11'),(838,26,'tvl',0,445,0,0,1,NULL,NULL,'2024-04-18 15:45:12','2024-04-18 15:45:12','2024-04-18 15:45:12'),(839,26,'twi',0,446,0,0,1,NULL,NULL,'2024-04-18 15:45:12','2024-04-18 15:45:12','2024-04-18 15:45:12'),(840,26,'tyv',0,447,0,0,1,NULL,NULL,'2024-04-18 15:45:12','2024-04-18 15:45:12','2024-04-18 15:45:12'),(841,26,'udm',0,448,0,0,1,NULL,NULL,'2024-04-18 15:45:12','2024-04-18 15:45:12','2024-04-18 15:45:12'),(842,26,'uga',0,449,0,0,1,NULL,NULL,'2024-04-18 15:45:12','2024-04-18 15:45:12','2024-04-18 15:45:12'),(843,26,'uig',0,450,0,0,1,NULL,NULL,'2024-04-18 15:45:12','2024-04-18 15:45:12','2024-04-18 15:45:12'),(844,26,'ukr',0,451,0,0,1,NULL,NULL,'2024-04-18 15:45:12','2024-04-18 15:45:12','2024-04-18 15:45:12'),(845,26,'umb',0,452,0,0,1,NULL,NULL,'2024-04-18 15:45:12','2024-04-18 15:45:12','2024-04-18 15:45:12'),(846,26,'und',0,453,0,0,1,NULL,NULL,'2024-04-18 15:45:12','2024-04-18 15:45:12','2024-04-18 15:45:12'),(847,26,'urd',0,454,0,0,1,NULL,NULL,'2024-04-18 15:45:12','2024-04-18 15:45:12','2024-04-18 15:45:12'),(848,26,'uzb',0,455,0,0,1,NULL,NULL,'2024-04-18 15:45:12','2024-04-18 15:45:12','2024-04-18 15:45:12'),(849,26,'vai',0,456,0,0,1,NULL,NULL,'2024-04-18 15:45:12','2024-04-18 15:45:12','2024-04-18 15:45:12'),(850,26,'ven',0,457,0,0,1,NULL,NULL,'2024-04-18 15:45:12','2024-04-18 15:45:12','2024-04-18 15:45:12'),(851,26,'vie',0,458,0,0,1,NULL,NULL,'2024-04-18 15:45:12','2024-04-18 15:45:12','2024-04-18 15:45:12'),(852,26,'vol',0,459,0,0,1,NULL,NULL,'2024-04-18 15:45:12','2024-04-18 15:45:12','2024-04-18 15:45:12'),(853,26,'vot',0,460,0,0,1,NULL,NULL,'2024-04-18 15:45:12','2024-04-18 15:45:12','2024-04-18 15:45:12'),(854,26,'wak',0,461,0,0,1,NULL,NULL,'2024-04-18 15:45:12','2024-04-18 15:45:12','2024-04-18 15:45:12'),(855,26,'wal',0,462,0,0,1,NULL,NULL,'2024-04-18 15:45:12','2024-04-18 15:45:12','2024-04-18 15:45:12'),(856,26,'war',0,463,0,0,1,NULL,NULL,'2024-04-18 15:45:12','2024-04-18 15:45:12','2024-04-18 15:45:12'),(857,26,'was',0,464,0,0,1,NULL,NULL,'2024-04-18 15:45:12','2024-04-18 15:45:12','2024-04-18 15:45:12'),(858,26,'wel',0,465,0,0,1,NULL,NULL,'2024-04-18 15:45:12','2024-04-18 15:45:12','2024-04-18 15:45:12'),(859,26,'wen',0,466,0,0,1,NULL,NULL,'2024-04-18 15:45:12','2024-04-18 15:45:12','2024-04-18 15:45:12'),(860,26,'wln',0,467,0,0,1,NULL,NULL,'2024-04-18 15:45:12','2024-04-18 15:45:12','2024-04-18 15:45:12'),(861,26,'wol',0,468,0,0,1,NULL,NULL,'2024-04-18 15:45:12','2024-04-18 15:45:12','2024-04-18 15:45:12'),(862,26,'xal',0,469,0,0,1,NULL,NULL,'2024-04-18 15:45:12','2024-04-18 15:45:12','2024-04-18 15:45:12'),(863,26,'xho',0,470,0,0,1,NULL,NULL,'2024-04-18 15:45:12','2024-04-18 15:45:12','2024-04-18 15:45:12'),(864,26,'yao',0,471,0,0,1,NULL,NULL,'2024-04-18 15:45:12','2024-04-18 15:45:12','2024-04-18 15:45:12'),(865,26,'yap',0,472,0,0,1,NULL,NULL,'2024-04-18 15:45:12','2024-04-18 15:45:12','2024-04-18 15:45:12'),(866,26,'yid',0,473,0,0,1,NULL,NULL,'2024-04-18 15:45:12','2024-04-18 15:45:12','2024-04-18 15:45:12'),(867,26,'yor',0,474,0,0,1,NULL,NULL,'2024-04-18 15:45:12','2024-04-18 15:45:12','2024-04-18 15:45:12'),(868,26,'ypk',0,475,0,0,1,NULL,NULL,'2024-04-18 15:45:12','2024-04-18 15:45:12','2024-04-18 15:45:12'),(869,26,'zap',0,476,0,0,1,NULL,NULL,'2024-04-18 15:45:12','2024-04-18 15:45:12','2024-04-18 15:45:12'),(870,26,'zbl',0,477,0,0,1,NULL,NULL,'2024-04-18 15:45:12','2024-04-18 15:45:12','2024-04-18 15:45:12'),(871,26,'zen',0,478,0,0,1,NULL,NULL,'2024-04-18 15:45:12','2024-04-18 15:45:12','2024-04-18 15:45:12'),(872,26,'zha',0,479,0,0,1,NULL,NULL,'2024-04-18 15:45:12','2024-04-18 15:45:12','2024-04-18 15:45:12'),(873,26,'znd',0,480,0,0,1,NULL,NULL,'2024-04-18 15:45:12','2024-04-18 15:45:12','2024-04-18 15:45:12'),(874,26,'zul',0,481,0,0,1,NULL,NULL,'2024-04-18 15:45:13','2024-04-18 15:45:13','2024-04-18 15:45:13'),(875,26,'zun',0,482,0,0,1,NULL,NULL,'2024-04-18 15:45:13','2024-04-18 15:45:13','2024-04-18 15:45:13'),(876,26,'zxx',0,483,0,0,1,NULL,NULL,'2024-04-18 15:45:13','2024-04-18 15:45:13','2024-04-18 15:45:13'),(877,26,'zza',0,484,0,0,1,NULL,NULL,'2024-04-18 15:45:13','2024-04-18 15:45:13','2024-04-18 15:45:13'),(878,27,'creator',0,0,0,0,1,NULL,NULL,'2024-04-18 15:45:26','2024-04-18 15:45:26','2024-04-18 15:45:26'),(879,27,'source',0,1,0,0,1,NULL,NULL,'2024-04-18 15:45:26','2024-04-18 15:45:26','2024-04-18 15:45:26'),(880,27,'subject',0,2,0,0,1,NULL,NULL,'2024-04-18 15:45:26','2024-04-18 15:45:26','2024-04-18 15:45:26'),(881,28,'is_associative_with',1,0,0,0,1,NULL,NULL,'2024-04-18 15:45:27','2024-04-18 15:45:27','2024-04-18 15:45:27'),(882,29,'is_earlier_form_of',1,0,0,0,1,NULL,NULL,'2024-04-18 15:45:27','2024-04-18 15:45:27','2024-04-18 15:45:27'),(883,29,'is_later_form_of',1,1,0,0,1,NULL,NULL,'2024-04-18 15:45:27','2024-04-18 15:45:27','2024-04-18 15:45:27'),(884,30,'is_parent_of',1,1,0,0,1,NULL,NULL,'2024-04-18 15:45:27','2024-04-18 15:45:27','2024-04-18 15:45:27'),(885,30,'is_child_of',1,0,0,0,1,NULL,NULL,'2024-04-18 15:45:27','2024-04-18 15:45:27','2024-04-18 15:45:27'),(886,31,'is_subordinate_to',1,0,0,0,1,NULL,NULL,'2024-04-18 15:45:27','2024-04-18 15:45:27','2024-04-18 15:45:27'),(887,31,'is_superior_of',1,1,0,0,1,NULL,NULL,'2024-04-18 15:45:27','2024-04-18 15:45:27','2024-04-18 15:45:27'),(888,32,'class',0,0,0,0,1,NULL,NULL,'2024-04-18 15:45:25','2024-04-18 15:45:25','2024-04-18 15:45:25'),(889,32,'collection',0,1,0,0,1,NULL,NULL,'2024-04-18 15:45:25','2024-04-18 15:45:25','2024-04-18 15:45:25'),(890,32,'file',0,2,0,0,1,NULL,NULL,'2024-04-18 15:45:25','2024-04-18 15:45:25','2024-04-18 15:45:25'),(891,32,'fonds',0,3,0,0,1,NULL,NULL,'2024-04-18 15:45:25','2024-04-18 15:45:25','2024-04-18 15:45:25'),(892,32,'item',0,4,0,0,1,NULL,NULL,'2024-04-18 15:45:25','2024-04-18 15:45:25','2024-04-18 15:45:25'),(893,32,'otherlevel',0,5,0,0,1,NULL,NULL,'2024-04-18 15:45:25','2024-04-18 15:45:25','2024-04-18 15:45:25'),(894,32,'recordgrp',0,6,0,0,1,NULL,NULL,'2024-04-18 15:45:25','2024-04-18 15:45:25','2024-04-18 15:45:25'),(895,32,'series',0,7,0,0,1,NULL,NULL,'2024-04-18 15:45:25','2024-04-18 15:45:25','2024-04-18 15:45:25'),(896,32,'subfonds',0,8,0,0,1,NULL,NULL,'2024-04-18 15:45:25','2024-04-18 15:45:25','2024-04-18 15:45:25'),(897,32,'subgrp',0,9,0,0,1,NULL,NULL,'2024-04-18 15:45:25','2024-04-18 15:45:25','2024-04-18 15:45:25'),(898,32,'subseries',0,10,0,0,1,NULL,NULL,'2024-04-18 15:45:25','2024-04-18 15:45:25','2024-04-18 15:45:25'),(899,33,'current',0,0,0,0,1,NULL,NULL,'2024-04-18 15:45:26','2024-04-18 15:45:26','2024-04-18 15:45:26'),(900,33,'previous',0,1,0,0,1,NULL,NULL,'2024-04-18 15:45:26','2024-04-18 15:45:26','2024-04-18 15:45:26'),(901,34,'single',0,3,0,0,1,NULL,NULL,'2024-04-18 15:45:24','2024-04-18 15:45:24','2024-04-18 15:45:24'),(902,34,'bulk',0,0,0,0,1,NULL,NULL,'2024-04-18 15:45:24','2024-04-18 15:45:24','2024-04-18 15:45:24'),(903,34,'inclusive',0,1,0,0,1,NULL,NULL,'2024-04-18 15:45:24','2024-04-18 15:45:24','2024-04-18 15:45:24'),(904,35,'broadcast',0,1,0,0,1,NULL,NULL,'2024-04-18 15:45:22','2024-04-18 15:45:22','2024-04-18 15:45:22'),(905,35,'copyright',0,2,0,0,1,NULL,NULL,'2024-04-18 15:45:22','2024-04-18 15:45:22','2024-04-18 15:45:22'),(906,35,'creation',0,3,0,0,1,NULL,NULL,'2024-04-18 15:45:22','2024-04-18 15:45:22','2024-04-18 15:45:22'),(907,35,'deaccession',0,4,0,0,1,NULL,NULL,'2024-04-18 15:45:22','2024-04-18 15:45:22','2024-04-18 15:45:22'),(908,35,'digitized',0,5,0,0,1,NULL,NULL,'2024-04-18 15:45:22','2024-04-18 15:45:22','2024-04-18 15:45:22'),(909,35,'event',0,6,0,0,1,NULL,NULL,'2024-04-18 15:45:22','2024-04-18 15:45:22','2024-04-18 15:45:22'),(910,35,'issued',0,8,0,0,1,NULL,NULL,'2024-04-18 15:45:22','2024-04-18 15:45:22','2024-04-18 15:45:22'),(911,35,'modified',0,9,0,0,1,NULL,NULL,'2024-04-18 15:45:22','2024-04-18 15:45:22','2024-04-18 15:45:22'),(912,35,'publication',0,11,0,0,1,NULL,NULL,'2024-04-18 15:45:22','2024-04-18 15:45:22','2024-04-18 15:45:22'),(913,35,'agent_relation',0,0,0,0,1,NULL,NULL,'2024-04-18 15:45:22','2024-04-18 15:45:22','2024-04-18 15:45:22'),(914,35,'other',0,10,0,0,1,NULL,NULL,'2024-04-18 15:45:22','2024-04-18 15:45:22','2024-04-18 15:45:22'),(915,35,'usage',0,13,0,0,1,NULL,NULL,'2024-04-18 15:45:22','2024-04-18 15:45:22','2024-04-18 15:45:22'),(916,35,'existence',1,7,0,0,1,NULL,NULL,'2024-04-18 15:45:22','2024-04-18 15:45:22','2024-04-18 15:45:22'),(917,35,'record_keeping',0,12,0,0,1,NULL,NULL,'2024-04-18 15:45:22','2024-04-18 15:45:22','2024-04-18 15:45:22'),(918,36,'approximate',0,0,0,0,1,NULL,NULL,'2024-04-18 15:45:23','2024-04-18 15:45:23','2024-04-18 15:45:23'),(919,36,'inferred',0,1,0,0,1,NULL,NULL,'2024-04-18 15:45:23','2024-04-18 15:45:23','2024-04-18 15:45:23'),(920,36,'questionable',0,2,0,0,1,NULL,NULL,'2024-04-18 15:45:23','2024-04-18 15:45:23','2024-04-18 15:45:23'),(921,37,'whole',0,1,0,0,1,NULL,NULL,'2024-04-18 15:45:28','2024-04-18 15:45:28','2024-04-18 15:45:28'),(922,37,'part',0,0,0,0,1,NULL,NULL,'2024-04-18 15:45:28','2024-04-18 15:45:28','2024-04-18 15:45:28'),(923,38,'whole',0,1,0,0,1,NULL,NULL,'2024-04-18 15:45:28','2024-04-18 15:45:28','2024-04-18 15:45:28'),(924,38,'part',0,0,0,0,1,NULL,NULL,'2024-04-18 15:45:28','2024-04-18 15:45:28','2024-04-18 15:45:28'),(925,39,'none',0,0,0,0,1,NULL,NULL,'2024-04-18 15:45:28','2024-04-18 15:45:28','2024-04-18 15:45:28'),(926,39,'other',0,3,0,0,1,NULL,NULL,'2024-04-18 15:45:28','2024-04-18 15:45:28','2024-04-18 15:45:28'),(927,39,'onLoad',0,1,0,0,1,NULL,NULL,'2024-04-18 15:45:28','2024-04-18 15:45:28','2024-04-18 15:45:28'),(928,39,'onRequest',0,2,0,0,1,NULL,NULL,'2024-04-18 15:45:28','2024-04-18 15:45:28','2024-04-18 15:45:28'),(929,40,'new',0,1,0,0,1,NULL,NULL,'2024-04-18 15:45:27','2024-04-18 15:45:27','2024-04-18 15:45:27'),(930,40,'replace',0,4,0,0,1,NULL,NULL,'2024-04-18 15:45:27','2024-04-18 15:45:27','2024-04-18 15:45:27'),(931,40,'embed',0,0,0,0,1,NULL,NULL,'2024-04-18 15:45:26','2024-04-18 15:45:26','2024-04-18 15:45:26'),(932,40,'other',0,3,0,0,1,NULL,NULL,'2024-04-18 15:45:27','2024-04-18 15:45:27','2024-04-18 15:45:27'),(933,40,'none',0,2,0,0,1,NULL,NULL,'2024-04-18 15:45:27','2024-04-18 15:45:27','2024-04-18 15:45:27'),(934,41,'aiff',0,0,0,0,1,NULL,NULL,'2024-04-18 15:45:22','2024-04-18 15:45:22','2024-04-18 15:45:22'),(935,41,'avi',0,1,0,0,1,NULL,NULL,'2024-04-18 15:45:22','2024-04-18 15:45:22','2024-04-18 15:45:22'),(936,41,'gif',0,2,0,0,1,NULL,NULL,'2024-04-18 15:45:22','2024-04-18 15:45:22','2024-04-18 15:45:22'),(937,41,'jpeg',0,3,0,0,1,NULL,NULL,'2024-04-18 15:45:22','2024-04-18 15:45:22','2024-04-18 15:45:22'),(938,41,'mp3',0,4,0,0,1,NULL,NULL,'2024-04-18 15:45:22','2024-04-18 15:45:22','2024-04-18 15:45:22'),(939,41,'pdf',0,5,0,0,1,NULL,NULL,'2024-04-18 15:45:22','2024-04-18 15:45:22','2024-04-18 15:45:22'),(940,41,'tiff',0,6,0,0,1,NULL,NULL,'2024-04-18 15:45:22','2024-04-18 15:45:22','2024-04-18 15:45:22'),(941,41,'txt',0,7,0,0,1,NULL,NULL,'2024-04-18 15:45:23','2024-04-18 15:45:23','2024-04-18 15:45:23'),(942,42,'conservation',0,0,0,0,1,NULL,NULL,'2024-04-18 15:45:25','2024-04-18 15:45:25','2024-04-18 15:45:25'),(943,42,'exhibit',0,1,0,0,1,NULL,NULL,'2024-04-18 15:45:25','2024-04-18 15:45:25','2024-04-18 15:45:25'),(944,42,'loan',0,2,0,0,1,NULL,NULL,'2024-04-18 15:45:25','2024-04-18 15:45:25','2024-04-18 15:45:25'),(945,42,'reading_room',0,3,0,0,1,NULL,NULL,'2024-04-18 15:45:25','2024-04-18 15:45:25','2024-04-18 15:45:25'),(946,43,'inverted',0,1,0,0,1,NULL,NULL,'2024-04-18 15:45:26','2024-04-18 15:45:26','2024-04-18 15:45:26'),(947,43,'direct',0,0,0,0,1,NULL,NULL,'2024-04-18 15:45:26','2024-04-18 15:45:26','2024-04-18 15:45:26'),(948,44,'summary',0,17,0,0,1,NULL,NULL,'2024-04-18 15:45:15','2024-04-18 15:45:15','2024-04-18 15:45:15'),(949,44,'bioghist',0,3,0,0,1,NULL,NULL,'2024-04-18 15:45:14','2024-04-18 15:45:14','2024-04-18 15:45:14'),(950,44,'accessrestrict',0,0,0,0,1,NULL,NULL,'2024-04-18 15:45:14','2024-04-18 15:45:14','2024-04-18 15:45:14'),(951,44,'userestrict',0,18,0,0,1,NULL,NULL,'2024-04-18 15:45:15','2024-04-18 15:45:15','2024-04-18 15:45:15'),(952,44,'custodhist',0,4,0,0,1,NULL,NULL,'2024-04-18 15:45:14','2024-04-18 15:45:14','2024-04-18 15:45:14'),(953,44,'dimensions',0,5,0,0,1,NULL,NULL,'2024-04-18 15:45:14','2024-04-18 15:45:14','2024-04-18 15:45:14'),(954,44,'edition',0,6,0,0,1,NULL,NULL,'2024-04-18 15:45:14','2024-04-18 15:45:14','2024-04-18 15:45:14'),(955,44,'extent',0,7,0,0,1,NULL,NULL,'2024-04-18 15:45:14','2024-04-18 15:45:14','2024-04-18 15:45:14'),(956,44,'altformavail',0,2,0,0,1,NULL,NULL,'2024-04-18 15:45:14','2024-04-18 15:45:14','2024-04-18 15:45:14'),(957,44,'originalsloc',0,12,0,0,1,NULL,NULL,'2024-04-18 15:45:15','2024-04-18 15:45:15','2024-04-18 15:45:15'),(958,44,'note',0,11,0,0,1,NULL,NULL,'2024-04-18 15:45:15','2024-04-18 15:45:15','2024-04-18 15:45:15'),(959,44,'acqinfo',0,1,0,0,1,NULL,NULL,'2024-04-18 15:45:14','2024-04-18 15:45:14','2024-04-18 15:45:14'),(960,44,'inscription',0,8,0,0,1,NULL,NULL,'2024-04-18 15:45:14','2024-04-18 15:45:14','2024-04-18 15:45:14'),(962,44,'legalstatus',0,10,0,0,1,NULL,NULL,'2024-04-18 15:45:15','2024-04-18 15:45:15','2024-04-18 15:45:15'),(963,44,'physdesc',0,13,0,0,1,NULL,NULL,'2024-04-18 15:45:15','2024-04-18 15:45:15','2024-04-18 15:45:15'),(964,44,'prefercite',0,14,0,0,1,NULL,NULL,'2024-04-18 15:45:15','2024-04-18 15:45:15','2024-04-18 15:45:15'),(965,44,'processinfo',0,15,0,0,1,NULL,NULL,'2024-04-18 15:45:15','2024-04-18 15:45:15','2024-04-18 15:45:15'),(966,44,'relatedmaterial',0,16,0,0,1,NULL,NULL,'2024-04-18 15:45:15','2024-04-18 15:45:15','2024-04-18 15:45:15'),(967,45,'accruals',0,1,0,0,1,NULL,NULL,'2024-04-18 15:45:15','2024-04-18 15:45:15','2024-04-18 15:45:15'),(968,45,'appraisal',0,4,0,0,1,NULL,NULL,'2024-04-18 15:45:15','2024-04-18 15:45:15','2024-04-18 15:45:15'),(969,45,'arrangement',0,5,0,0,1,NULL,NULL,'2024-04-18 15:45:15','2024-04-18 15:45:15','2024-04-18 15:45:15'),(970,45,'bioghist',0,6,0,0,1,NULL,NULL,'2024-04-18 15:45:15','2024-04-18 15:45:15','2024-04-18 15:45:15'),(971,45,'accessrestrict',0,0,0,0,1,NULL,NULL,'2024-04-18 15:45:15','2024-04-18 15:45:15','2024-04-18 15:45:15'),(972,45,'userestrict',0,20,0,0,1,NULL,NULL,'2024-04-18 15:45:15','2024-04-18 15:45:15','2024-04-18 15:45:15'),(973,45,'custodhist',0,7,0,0,1,NULL,NULL,'2024-04-18 15:45:15','2024-04-18 15:45:15','2024-04-18 15:45:15'),(974,45,'dimensions',0,8,0,0,1,NULL,NULL,'2024-04-18 15:45:15','2024-04-18 15:45:15','2024-04-18 15:45:15'),(975,45,'altformavail',0,3,0,0,1,NULL,NULL,'2024-04-18 15:45:15','2024-04-18 15:45:15','2024-04-18 15:45:15'),(976,45,'originalsloc',0,12,0,0,1,NULL,NULL,'2024-04-18 15:45:15','2024-04-18 15:45:15','2024-04-18 15:45:15'),(977,45,'fileplan',0,9,0,0,1,NULL,NULL,'2024-04-18 15:45:15','2024-04-18 15:45:15','2024-04-18 15:45:15'),(978,45,'odd',0,11,0,0,1,NULL,NULL,'2024-04-18 15:45:15','2024-04-18 15:45:15','2024-04-18 15:45:15'),(979,45,'acqinfo',0,2,0,0,1,NULL,NULL,'2024-04-18 15:45:15','2024-04-18 15:45:15','2024-04-18 15:45:15'),(980,45,'legalstatus',0,10,0,0,1,NULL,NULL,'2024-04-18 15:45:15','2024-04-18 15:45:15','2024-04-18 15:45:15'),(981,45,'otherfindaid',0,13,0,0,1,NULL,NULL,'2024-04-18 15:45:15','2024-04-18 15:45:15','2024-04-18 15:45:15'),(982,45,'phystech',0,14,0,0,1,NULL,NULL,'2024-04-18 15:45:15','2024-04-18 15:45:15','2024-04-18 15:45:15'),(983,45,'prefercite',0,15,0,0,1,NULL,NULL,'2024-04-18 15:45:15','2024-04-18 15:45:15','2024-04-18 15:45:15'),(984,45,'processinfo',0,16,0,0,1,NULL,NULL,'2024-04-18 15:45:15','2024-04-18 15:45:15','2024-04-18 15:45:15'),(985,45,'relatedmaterial',0,17,0,0,1,NULL,NULL,'2024-04-18 15:45:15','2024-04-18 15:45:15','2024-04-18 15:45:15'),(986,45,'scopecontent',0,18,0,0,1,NULL,NULL,'2024-04-18 15:45:15','2024-04-18 15:45:15','2024-04-18 15:45:15'),(987,45,'separatedmaterial',0,19,0,0,1,NULL,NULL,'2024-04-18 15:45:15','2024-04-18 15:45:15','2024-04-18 15:45:15'),(988,46,'arabic',0,0,0,0,1,NULL,NULL,'2024-04-18 15:45:23','2024-04-18 15:45:23','2024-04-18 15:45:23'),(989,46,'loweralpha',0,1,0,0,1,NULL,NULL,'2024-04-18 15:45:23','2024-04-18 15:45:23','2024-04-18 15:45:23'),(990,46,'upperalpha',0,3,0,0,1,NULL,NULL,'2024-04-18 15:45:23','2024-04-18 15:45:23','2024-04-18 15:45:23'),(991,46,'lowerroman',0,2,0,0,1,NULL,NULL,'2024-04-18 15:45:23','2024-04-18 15:45:23','2024-04-18 15:45:23'),(992,46,'upperroman',0,4,0,0,1,NULL,NULL,'2024-04-18 15:45:23','2024-04-18 15:45:23','2024-04-18 15:45:23'),(993,47,'abstract',0,0,0,0,1,NULL,NULL,'2024-04-18 15:45:13','2024-04-18 15:45:13','2024-04-18 15:45:13'),(994,47,'physdesc',0,3,0,0,1,NULL,NULL,'2024-04-18 15:45:13','2024-04-18 15:45:13','2024-04-18 15:45:13'),(996,47,'physloc',0,5,0,0,1,NULL,NULL,'2024-04-18 15:45:13','2024-04-18 15:45:13','2024-04-18 15:45:13'),(997,47,'materialspec',0,2,0,0,1,NULL,NULL,'2024-04-18 15:45:13','2024-04-18 15:45:13','2024-04-18 15:45:13'),(998,47,'physfacet',0,4,0,0,1,NULL,NULL,'2024-04-18 15:45:13','2024-04-18 15:45:13','2024-04-18 15:45:13'),(999,48,'bibliography',0,0,0,0,1,NULL,NULL,'2024-04-18 15:45:24','2024-04-18 15:45:24','2024-04-18 15:45:24'),(1000,49,'index',0,0,0,0,1,NULL,NULL,'2024-04-18 15:45:27','2024-04-18 15:45:27','2024-04-18 15:45:27'),(1001,50,'name',0,5,0,0,1,NULL,NULL,'2024-04-18 15:45:26','2024-04-18 15:45:26','2024-04-18 15:45:26'),(1002,50,'person',0,7,0,0,1,NULL,NULL,'2024-04-18 15:45:26','2024-04-18 15:45:26','2024-04-18 15:45:26'),(1003,50,'family',0,1,0,0,1,NULL,NULL,'2024-04-18 15:45:26','2024-04-18 15:45:26','2024-04-18 15:45:26'),(1004,50,'corporate_entity',0,0,0,0,1,NULL,NULL,'2024-04-18 15:45:26','2024-04-18 15:45:26','2024-04-18 15:45:26'),(1005,50,'subject',0,8,0,0,1,NULL,NULL,'2024-04-18 15:45:26','2024-04-18 15:45:26','2024-04-18 15:45:26'),(1006,50,'function',0,2,0,0,1,NULL,NULL,'2024-04-18 15:45:26','2024-04-18 15:45:26','2024-04-18 15:45:26'),(1007,50,'occupation',0,6,0,0,1,NULL,NULL,'2024-04-18 15:45:26','2024-04-18 15:45:26','2024-04-18 15:45:26'),(1008,50,'title',0,9,0,0,1,NULL,NULL,'2024-04-18 15:45:26','2024-04-18 15:45:26','2024-04-18 15:45:26'),(1009,50,'geographic_name',0,4,0,0,1,NULL,NULL,'2024-04-18 15:45:26','2024-04-18 15:45:26','2024-04-18 15:45:26'),(1010,50,'genre_form',0,3,0,0,1,NULL,NULL,'2024-04-18 15:45:26','2024-04-18 15:45:26','2024-04-18 15:45:26'),(1011,51,'AF',0,2,0,0,1,NULL,NULL,'2024-04-18 15:44:52','2024-04-18 15:44:52','2024-04-18 15:44:52'),(1012,51,'AX',0,14,0,0,1,NULL,NULL,'2024-04-18 15:44:53','2024-04-18 15:44:53','2024-04-18 15:44:53'),(1013,51,'AL',0,5,0,0,1,NULL,NULL,'2024-04-18 15:44:53','2024-04-18 15:44:53','2024-04-18 15:44:53'),(1014,51,'DZ',0,61,0,0,1,NULL,NULL,'2024-04-18 15:44:54','2024-04-18 15:44:54','2024-04-18 15:44:54'),(1015,51,'AS',0,10,0,0,1,NULL,NULL,'2024-04-18 15:44:53','2024-04-18 15:44:53','2024-04-18 15:44:53'),(1016,51,'AD',0,0,0,0,1,NULL,NULL,'2024-04-18 15:44:52','2024-04-18 15:44:52','2024-04-18 15:44:52'),(1017,51,'AO',0,7,0,0,1,NULL,NULL,'2024-04-18 15:44:53','2024-04-18 15:44:53','2024-04-18 15:44:53'),(1018,51,'AI',0,4,0,0,1,NULL,NULL,'2024-04-18 15:44:53','2024-04-18 15:44:53','2024-04-18 15:44:53'),(1019,51,'AQ',0,8,0,0,1,NULL,NULL,'2024-04-18 15:44:53','2024-04-18 15:44:53','2024-04-18 15:44:53'),(1020,51,'AG',0,3,0,0,1,NULL,NULL,'2024-04-18 15:44:52','2024-04-18 15:44:52','2024-04-18 15:44:52'),(1021,51,'AR',0,9,0,0,1,NULL,NULL,'2024-04-18 15:44:53','2024-04-18 15:44:53','2024-04-18 15:44:53'),(1022,51,'AM',0,6,0,0,1,NULL,NULL,'2024-04-18 15:44:53','2024-04-18 15:44:53','2024-04-18 15:44:53'),(1023,51,'AW',0,13,0,0,1,NULL,NULL,'2024-04-18 15:44:53','2024-04-18 15:44:53','2024-04-18 15:44:53'),(1024,51,'AU',0,12,0,0,1,NULL,NULL,'2024-04-18 15:44:53','2024-04-18 15:44:53','2024-04-18 15:44:53'),(1025,51,'AT',0,11,0,0,1,NULL,NULL,'2024-04-18 15:44:53','2024-04-18 15:44:53','2024-04-18 15:44:53'),(1026,51,'AZ',0,15,0,0,1,NULL,NULL,'2024-04-18 15:44:53','2024-04-18 15:44:53','2024-04-18 15:44:53'),(1027,51,'BS',0,31,0,0,1,NULL,NULL,'2024-04-18 15:44:53','2024-04-18 15:44:53','2024-04-18 15:44:53'),(1028,51,'BH',0,22,0,0,1,NULL,NULL,'2024-04-18 15:44:53','2024-04-18 15:44:53','2024-04-18 15:44:53'),(1029,51,'BD',0,18,0,0,1,NULL,NULL,'2024-04-18 15:44:53','2024-04-18 15:44:53','2024-04-18 15:44:53'),(1030,51,'BB',0,17,0,0,1,NULL,NULL,'2024-04-18 15:44:53','2024-04-18 15:44:53','2024-04-18 15:44:53'),(1031,51,'BY',0,35,0,0,1,NULL,NULL,'2024-04-18 15:44:53','2024-04-18 15:44:53','2024-04-18 15:44:53'),(1032,51,'BE',0,19,0,0,1,NULL,NULL,'2024-04-18 15:44:53','2024-04-18 15:44:53','2024-04-18 15:44:53'),(1033,51,'BZ',0,36,0,0,1,NULL,NULL,'2024-04-18 15:44:53','2024-04-18 15:44:53','2024-04-18 15:44:53'),(1034,51,'BJ',0,24,0,0,1,NULL,NULL,'2024-04-18 15:44:53','2024-04-18 15:44:53','2024-04-18 15:44:53'),(1035,51,'BM',0,26,0,0,1,NULL,NULL,'2024-04-18 15:44:53','2024-04-18 15:44:53','2024-04-18 15:44:53'),(1036,51,'BT',0,32,0,0,1,NULL,NULL,'2024-04-18 15:44:53','2024-04-18 15:44:53','2024-04-18 15:44:53'),(1037,51,'BO',0,28,0,0,1,NULL,NULL,'2024-04-18 15:44:53','2024-04-18 15:44:53','2024-04-18 15:44:53'),(1038,51,'BQ',0,29,0,0,1,NULL,NULL,'2024-04-18 15:44:53','2024-04-18 15:44:53','2024-04-18 15:44:53'),(1039,51,'BA',0,16,0,0,1,NULL,NULL,'2024-04-18 15:44:53','2024-04-18 15:44:53','2024-04-18 15:44:53'),(1040,51,'BW',0,34,0,0,1,NULL,NULL,'2024-04-18 15:44:53','2024-04-18 15:44:53','2024-04-18 15:44:53'),(1041,51,'BV',0,33,0,0,1,NULL,NULL,'2024-04-18 15:44:53','2024-04-18 15:44:53','2024-04-18 15:44:53'),(1042,51,'BR',0,30,0,0,1,NULL,NULL,'2024-04-18 15:44:53','2024-04-18 15:44:53','2024-04-18 15:44:53'),(1043,51,'IO',0,105,0,0,1,NULL,NULL,'2024-04-18 15:44:55','2024-04-18 15:44:55','2024-04-18 15:44:55'),(1044,51,'BN',0,27,0,0,1,NULL,NULL,'2024-04-18 15:44:53','2024-04-18 15:44:53','2024-04-18 15:44:53'),(1045,51,'BG',0,21,0,0,1,NULL,NULL,'2024-04-18 15:44:53','2024-04-18 15:44:53','2024-04-18 15:44:53'),(1046,51,'BF',0,20,0,0,1,NULL,NULL,'2024-04-18 15:44:53','2024-04-18 15:44:53','2024-04-18 15:44:53'),(1047,51,'BI',0,23,0,0,1,NULL,NULL,'2024-04-18 15:44:53','2024-04-18 15:44:53','2024-04-18 15:44:53'),(1048,51,'KH',0,116,0,0,1,NULL,NULL,'2024-04-18 15:44:56','2024-04-18 15:44:56','2024-04-18 15:44:56'),(1049,51,'CM',0,46,0,0,1,NULL,NULL,'2024-04-18 15:44:54','2024-04-18 15:44:54','2024-04-18 15:44:54'),(1050,51,'CA',0,37,0,0,1,NULL,NULL,'2024-04-18 15:44:53','2024-04-18 15:44:53','2024-04-18 15:44:53'),(1051,51,'CV',0,51,0,0,1,NULL,NULL,'2024-04-18 15:44:54','2024-04-18 15:44:54','2024-04-18 15:44:54'),(1052,51,'KY',0,123,0,0,1,NULL,NULL,'2024-04-18 15:44:56','2024-04-18 15:44:56','2024-04-18 15:44:56'),(1053,51,'CF',0,40,0,0,1,NULL,NULL,'2024-04-18 15:44:54','2024-04-18 15:44:54','2024-04-18 15:44:54'),(1054,51,'TD',0,214,0,0,1,NULL,NULL,'2024-04-18 15:44:58','2024-04-18 15:44:58','2024-04-18 15:44:58'),(1055,51,'CL',0,45,0,0,1,NULL,NULL,'2024-04-18 15:44:54','2024-04-18 15:44:54','2024-04-18 15:44:54'),(1056,51,'CN',0,47,0,0,1,NULL,NULL,'2024-04-18 15:44:54','2024-04-18 15:44:54','2024-04-18 15:44:54'),(1057,51,'CX',0,53,0,0,1,NULL,NULL,'2024-04-18 15:44:54','2024-04-18 15:44:54','2024-04-18 15:44:54'),(1058,51,'CC',0,38,0,0,1,NULL,NULL,'2024-04-18 15:44:53','2024-04-18 15:44:53','2024-04-18 15:44:53'),(1059,51,'CO',0,48,0,0,1,NULL,NULL,'2024-04-18 15:44:54','2024-04-18 15:44:54','2024-04-18 15:44:54'),(1060,51,'KM',0,118,0,0,1,NULL,NULL,'2024-04-18 15:44:56','2024-04-18 15:44:56','2024-04-18 15:44:56'),(1061,51,'CG',0,41,0,0,1,NULL,NULL,'2024-04-18 15:44:54','2024-04-18 15:44:54','2024-04-18 15:44:54'),(1062,51,'CD',0,39,0,0,1,NULL,NULL,'2024-04-18 15:44:54','2024-04-18 15:44:54','2024-04-18 15:44:54'),(1063,51,'CK',0,44,0,0,1,NULL,NULL,'2024-04-18 15:44:54','2024-04-18 15:44:54','2024-04-18 15:44:54'),(1064,51,'CR',0,49,0,0,1,NULL,NULL,'2024-04-18 15:44:54','2024-04-18 15:44:54','2024-04-18 15:44:54'),(1065,51,'CI',0,43,0,0,1,NULL,NULL,'2024-04-18 15:44:54','2024-04-18 15:44:54','2024-04-18 15:44:54'),(1066,51,'HR',0,97,0,0,1,NULL,NULL,'2024-04-18 15:44:55','2024-04-18 15:44:55','2024-04-18 15:44:55'),(1067,51,'CU',0,50,0,0,1,NULL,NULL,'2024-04-18 15:44:54','2024-04-18 15:44:54','2024-04-18 15:44:54'),(1068,51,'CW',0,52,0,0,1,NULL,NULL,'2024-04-18 15:44:54','2024-04-18 15:44:54','2024-04-18 15:44:54'),(1069,51,'CY',0,54,0,0,1,NULL,NULL,'2024-04-18 15:44:54','2024-04-18 15:44:54','2024-04-18 15:44:54'),(1070,51,'CZ',0,55,0,0,1,NULL,NULL,'2024-04-18 15:44:54','2024-04-18 15:44:54','2024-04-18 15:44:54'),(1071,51,'DK',0,58,0,0,1,NULL,NULL,'2024-04-18 15:44:54','2024-04-18 15:44:54','2024-04-18 15:44:54'),(1072,51,'DJ',0,57,0,0,1,NULL,NULL,'2024-04-18 15:44:54','2024-04-18 15:44:54','2024-04-18 15:44:54'),(1073,51,'DM',0,59,0,0,1,NULL,NULL,'2024-04-18 15:44:54','2024-04-18 15:44:54','2024-04-18 15:44:54'),(1074,51,'DO',0,60,0,0,1,NULL,NULL,'2024-04-18 15:44:54','2024-04-18 15:44:54','2024-04-18 15:44:54'),(1075,51,'EC',0,62,0,0,1,NULL,NULL,'2024-04-18 15:44:54','2024-04-18 15:44:54','2024-04-18 15:44:54'),(1076,51,'EG',0,64,0,0,1,NULL,NULL,'2024-04-18 15:44:54','2024-04-18 15:44:54','2024-04-18 15:44:54'),(1077,51,'SV',0,209,0,0,1,NULL,NULL,'2024-04-18 15:44:58','2024-04-18 15:44:58','2024-04-18 15:44:58'),(1078,51,'GQ',0,87,0,0,1,NULL,NULL,'2024-04-18 15:44:55','2024-04-18 15:44:55','2024-04-18 15:44:55'),(1079,51,'ER',0,66,0,0,1,NULL,NULL,'2024-04-18 15:44:54','2024-04-18 15:44:54','2024-04-18 15:44:54'),(1080,51,'EE',0,63,0,0,1,NULL,NULL,'2024-04-18 15:44:54','2024-04-18 15:44:54','2024-04-18 15:44:54'),(1081,51,'ET',0,68,0,0,1,NULL,NULL,'2024-04-18 15:44:54','2024-04-18 15:44:54','2024-04-18 15:44:54'),(1082,51,'FK',0,71,0,0,1,NULL,NULL,'2024-04-18 15:44:54','2024-04-18 15:44:54','2024-04-18 15:44:54'),(1083,51,'FO',0,73,0,0,1,NULL,NULL,'2024-04-18 15:44:54','2024-04-18 15:44:54','2024-04-18 15:44:54'),(1084,51,'FJ',0,70,0,0,1,NULL,NULL,'2024-04-18 15:44:54','2024-04-18 15:44:54','2024-04-18 15:44:54'),(1085,51,'FI',0,69,0,0,1,NULL,NULL,'2024-04-18 15:44:54','2024-04-18 15:44:54','2024-04-18 15:44:54'),(1086,51,'FR',0,74,0,0,1,NULL,NULL,'2024-04-18 15:44:54','2024-04-18 15:44:54','2024-04-18 15:44:54'),(1087,51,'GF',0,79,0,0,1,NULL,NULL,'2024-04-18 15:44:55','2024-04-18 15:44:55','2024-04-18 15:44:55'),(1088,51,'PF',0,174,0,0,1,NULL,NULL,'2024-04-18 15:44:57','2024-04-18 15:44:57','2024-04-18 15:44:57'),(1089,51,'TF',0,215,0,0,1,NULL,NULL,'2024-04-18 15:44:58','2024-04-18 15:44:58','2024-04-18 15:44:58'),(1090,51,'GA',0,75,0,0,1,NULL,NULL,'2024-04-18 15:44:55','2024-04-18 15:44:55','2024-04-18 15:44:55'),(1091,51,'GM',0,84,0,0,1,NULL,NULL,'2024-04-18 15:44:55','2024-04-18 15:44:55','2024-04-18 15:44:55'),(1092,51,'GE',0,78,0,0,1,NULL,NULL,'2024-04-18 15:44:55','2024-04-18 15:44:55','2024-04-18 15:44:55'),(1093,51,'DE',0,56,0,0,1,NULL,NULL,'2024-04-18 15:44:54','2024-04-18 15:44:54','2024-04-18 15:44:54'),(1094,51,'GH',0,81,0,0,1,NULL,NULL,'2024-04-18 15:44:55','2024-04-18 15:44:55','2024-04-18 15:44:55'),(1095,51,'GI',0,82,0,0,1,NULL,NULL,'2024-04-18 15:44:55','2024-04-18 15:44:55','2024-04-18 15:44:55'),(1096,51,'GR',0,88,0,0,1,NULL,NULL,'2024-04-18 15:44:55','2024-04-18 15:44:55','2024-04-18 15:44:55'),(1097,51,'GL',0,83,0,0,1,NULL,NULL,'2024-04-18 15:44:55','2024-04-18 15:44:55','2024-04-18 15:44:55'),(1098,51,'GD',0,77,0,0,1,NULL,NULL,'2024-04-18 15:44:55','2024-04-18 15:44:55','2024-04-18 15:44:55'),(1099,51,'GP',0,86,0,0,1,NULL,NULL,'2024-04-18 15:44:55','2024-04-18 15:44:55','2024-04-18 15:44:55'),(1100,51,'GU',0,91,0,0,1,NULL,NULL,'2024-04-18 15:44:55','2024-04-18 15:44:55','2024-04-18 15:44:55'),(1101,51,'GT',0,90,0,0,1,NULL,NULL,'2024-04-18 15:44:55','2024-04-18 15:44:55','2024-04-18 15:44:55'),(1102,51,'GG',0,80,0,0,1,NULL,NULL,'2024-04-18 15:44:55','2024-04-18 15:44:55','2024-04-18 15:44:55'),(1103,51,'GN',0,85,0,0,1,NULL,NULL,'2024-04-18 15:44:55','2024-04-18 15:44:55','2024-04-18 15:44:55'),(1104,51,'GW',0,92,0,0,1,NULL,NULL,'2024-04-18 15:44:55','2024-04-18 15:44:55','2024-04-18 15:44:55'),(1105,51,'GY',0,93,0,0,1,NULL,NULL,'2024-04-18 15:44:55','2024-04-18 15:44:55','2024-04-18 15:44:55'),(1106,51,'HT',0,98,0,0,1,NULL,NULL,'2024-04-18 15:44:55','2024-04-18 15:44:55','2024-04-18 15:44:55'),(1107,51,'HM',0,95,0,0,1,NULL,NULL,'2024-04-18 15:44:55','2024-04-18 15:44:55','2024-04-18 15:44:55'),(1108,51,'VA',0,235,0,0,1,NULL,NULL,'2024-04-18 15:44:59','2024-04-18 15:44:59','2024-04-18 15:44:59'),(1109,51,'HN',0,96,0,0,1,NULL,NULL,'2024-04-18 15:44:55','2024-04-18 15:44:55','2024-04-18 15:44:55'),(1110,51,'HK',0,94,0,0,1,NULL,NULL,'2024-04-18 15:44:55','2024-04-18 15:44:55','2024-04-18 15:44:55'),(1111,51,'HU',0,99,0,0,1,NULL,NULL,'2024-04-18 15:44:55','2024-04-18 15:44:55','2024-04-18 15:44:55'),(1112,51,'IS',0,108,0,0,1,NULL,NULL,'2024-04-18 15:44:55','2024-04-18 15:44:55','2024-04-18 15:44:55'),(1113,51,'IN',0,104,0,0,1,NULL,NULL,'2024-04-18 15:44:55','2024-04-18 15:44:55','2024-04-18 15:44:55'),(1114,51,'ID',0,100,0,0,1,NULL,NULL,'2024-04-18 15:44:55','2024-04-18 15:44:55','2024-04-18 15:44:55'),(1115,51,'IR',0,107,0,0,1,NULL,NULL,'2024-04-18 15:44:55','2024-04-18 15:44:55','2024-04-18 15:44:55'),(1116,51,'IQ',0,106,0,0,1,NULL,NULL,'2024-04-18 15:44:55','2024-04-18 15:44:55','2024-04-18 15:44:55'),(1117,51,'IE',0,101,0,0,1,NULL,NULL,'2024-04-18 15:44:55','2024-04-18 15:44:55','2024-04-18 15:44:55'),(1118,51,'IM',0,103,0,0,1,NULL,NULL,'2024-04-18 15:44:55','2024-04-18 15:44:55','2024-04-18 15:44:55'),(1119,51,'IL',0,102,0,0,1,NULL,NULL,'2024-04-18 15:44:55','2024-04-18 15:44:55','2024-04-18 15:44:55'),(1120,51,'IT',0,109,0,0,1,NULL,NULL,'2024-04-18 15:44:56','2024-04-18 15:44:56','2024-04-18 15:44:56'),(1121,51,'JM',0,111,0,0,1,NULL,NULL,'2024-04-18 15:44:56','2024-04-18 15:44:56','2024-04-18 15:44:56'),(1122,51,'JP',0,113,0,0,1,NULL,NULL,'2024-04-18 15:44:56','2024-04-18 15:44:56','2024-04-18 15:44:56'),(1123,51,'JE',0,110,0,0,1,NULL,NULL,'2024-04-18 15:44:56','2024-04-18 15:44:56','2024-04-18 15:44:56'),(1124,51,'JO',0,112,0,0,1,NULL,NULL,'2024-04-18 15:44:56','2024-04-18 15:44:56','2024-04-18 15:44:56'),(1125,51,'KZ',0,124,0,0,1,NULL,NULL,'2024-04-18 15:44:56','2024-04-18 15:44:56','2024-04-18 15:44:56'),(1126,51,'KE',0,114,0,0,1,NULL,NULL,'2024-04-18 15:44:56','2024-04-18 15:44:56','2024-04-18 15:44:56'),(1127,51,'KI',0,117,0,0,1,NULL,NULL,'2024-04-18 15:44:56','2024-04-18 15:44:56','2024-04-18 15:44:56'),(1128,51,'KP',0,120,0,0,1,NULL,NULL,'2024-04-18 15:44:56','2024-04-18 15:44:56','2024-04-18 15:44:56'),(1129,51,'KR',0,121,0,0,1,NULL,NULL,'2024-04-18 15:44:56','2024-04-18 15:44:56','2024-04-18 15:44:56'),(1130,51,'KW',0,122,0,0,1,NULL,NULL,'2024-04-18 15:44:56','2024-04-18 15:44:56','2024-04-18 15:44:56'),(1131,51,'KG',0,115,0,0,1,NULL,NULL,'2024-04-18 15:44:56','2024-04-18 15:44:56','2024-04-18 15:44:56'),(1132,51,'LA',0,125,0,0,1,NULL,NULL,'2024-04-18 15:44:56','2024-04-18 15:44:56','2024-04-18 15:44:56'),(1133,51,'LV',0,134,0,0,1,NULL,NULL,'2024-04-18 15:44:56','2024-04-18 15:44:56','2024-04-18 15:44:56'),(1134,51,'LB',0,126,0,0,1,NULL,NULL,'2024-04-18 15:44:56','2024-04-18 15:44:56','2024-04-18 15:44:56'),(1135,51,'LS',0,131,0,0,1,NULL,NULL,'2024-04-18 15:44:56','2024-04-18 15:44:56','2024-04-18 15:44:56'),(1136,51,'LR',0,130,0,0,1,NULL,NULL,'2024-04-18 15:44:56','2024-04-18 15:44:56','2024-04-18 15:44:56'),(1137,51,'LY',0,135,0,0,1,NULL,NULL,'2024-04-18 15:44:56','2024-04-18 15:44:56','2024-04-18 15:44:56'),(1138,51,'LI',0,128,0,0,1,NULL,NULL,'2024-04-18 15:44:56','2024-04-18 15:44:56','2024-04-18 15:44:56'),(1139,51,'LT',0,132,0,0,1,NULL,NULL,'2024-04-18 15:44:56','2024-04-18 15:44:56','2024-04-18 15:44:56'),(1140,51,'LU',0,133,0,0,1,NULL,NULL,'2024-04-18 15:44:56','2024-04-18 15:44:56','2024-04-18 15:44:56'),(1141,51,'MO',0,147,0,0,1,NULL,NULL,'2024-04-18 15:44:57','2024-04-18 15:44:57','2024-04-18 15:44:57'),(1142,51,'MK',0,143,0,0,1,NULL,NULL,'2024-04-18 15:44:56','2024-04-18 15:44:56','2024-04-18 15:44:56'),(1143,51,'MG',0,141,0,0,1,NULL,NULL,'2024-04-18 15:44:56','2024-04-18 15:44:56','2024-04-18 15:44:56'),(1144,51,'MW',0,155,0,0,1,NULL,NULL,'2024-04-18 15:44:57','2024-04-18 15:44:57','2024-04-18 15:44:57'),(1145,51,'MY',0,157,0,0,1,NULL,NULL,'2024-04-18 15:44:57','2024-04-18 15:44:57','2024-04-18 15:44:57'),(1146,51,'MV',0,154,0,0,1,NULL,NULL,'2024-04-18 15:44:57','2024-04-18 15:44:57','2024-04-18 15:44:57'),(1147,51,'ML',0,144,0,0,1,NULL,NULL,'2024-04-18 15:44:57','2024-04-18 15:44:57','2024-04-18 15:44:57'),(1148,51,'MT',0,152,0,0,1,NULL,NULL,'2024-04-18 15:44:57','2024-04-18 15:44:57','2024-04-18 15:44:57'),(1149,51,'MH',0,142,0,0,1,NULL,NULL,'2024-04-18 15:44:56','2024-04-18 15:44:56','2024-04-18 15:44:56'),(1150,51,'MQ',0,149,0,0,1,NULL,NULL,'2024-04-18 15:44:57','2024-04-18 15:44:57','2024-04-18 15:44:57'),(1151,51,'MR',0,150,0,0,1,NULL,NULL,'2024-04-18 15:44:57','2024-04-18 15:44:57','2024-04-18 15:44:57'),(1152,51,'MU',0,153,0,0,1,NULL,NULL,'2024-04-18 15:44:57','2024-04-18 15:44:57','2024-04-18 15:44:57'),(1153,51,'YT',0,245,0,0,1,NULL,NULL,'2024-04-18 15:44:59','2024-04-18 15:44:59','2024-04-18 15:44:59'),(1154,51,'MX',0,156,0,0,1,NULL,NULL,'2024-04-18 15:44:57','2024-04-18 15:44:57','2024-04-18 15:44:57'),(1155,51,'FM',0,72,0,0,1,NULL,NULL,'2024-04-18 15:44:54','2024-04-18 15:44:54','2024-04-18 15:44:54'),(1156,51,'MD',0,138,0,0,1,NULL,NULL,'2024-04-18 15:44:56','2024-04-18 15:44:56','2024-04-18 15:44:56'),(1157,51,'MC',0,137,0,0,1,NULL,NULL,'2024-04-18 15:44:56','2024-04-18 15:44:56','2024-04-18 15:44:56'),(1158,51,'MN',0,146,0,0,1,NULL,NULL,'2024-04-18 15:44:57','2024-04-18 15:44:57','2024-04-18 15:44:57'),(1159,51,'ME',0,139,0,0,1,NULL,NULL,'2024-04-18 15:44:56','2024-04-18 15:44:56','2024-04-18 15:44:56'),(1160,51,'MS',0,151,0,0,1,NULL,NULL,'2024-04-18 15:44:57','2024-04-18 15:44:57','2024-04-18 15:44:57'),(1161,51,'MA',0,136,0,0,1,NULL,NULL,'2024-04-18 15:44:56','2024-04-18 15:44:56','2024-04-18 15:44:56'),(1162,51,'MZ',0,158,0,0,1,NULL,NULL,'2024-04-18 15:44:57','2024-04-18 15:44:57','2024-04-18 15:44:57'),(1163,51,'MM',0,145,0,0,1,NULL,NULL,'2024-04-18 15:44:57','2024-04-18 15:44:57','2024-04-18 15:44:57'),(1164,51,'NA',0,159,0,0,1,NULL,NULL,'2024-04-18 15:44:57','2024-04-18 15:44:57','2024-04-18 15:44:57'),(1165,51,'NR',0,168,0,0,1,NULL,NULL,'2024-04-18 15:44:57','2024-04-18 15:44:57','2024-04-18 15:44:57'),(1166,51,'NP',0,167,0,0,1,NULL,NULL,'2024-04-18 15:44:57','2024-04-18 15:44:57','2024-04-18 15:44:57'),(1167,51,'NL',0,165,0,0,1,NULL,NULL,'2024-04-18 15:44:57','2024-04-18 15:44:57','2024-04-18 15:44:57'),(1168,51,'NC',0,160,0,0,1,NULL,NULL,'2024-04-18 15:44:57','2024-04-18 15:44:57','2024-04-18 15:44:57'),(1169,51,'NZ',0,170,0,0,1,NULL,NULL,'2024-04-18 15:44:57','2024-04-18 15:44:57','2024-04-18 15:44:57'),(1170,51,'NI',0,164,0,0,1,NULL,NULL,'2024-04-18 15:44:57','2024-04-18 15:44:57','2024-04-18 15:44:57'),(1171,51,'NE',0,161,0,0,1,NULL,NULL,'2024-04-18 15:44:57','2024-04-18 15:44:57','2024-04-18 15:44:57'),(1172,51,'NG',0,163,0,0,1,NULL,NULL,'2024-04-18 15:44:57','2024-04-18 15:44:57','2024-04-18 15:44:57'),(1173,51,'NU',0,169,0,0,1,NULL,NULL,'2024-04-18 15:44:57','2024-04-18 15:44:57','2024-04-18 15:44:57'),(1174,51,'NF',0,162,0,0,1,NULL,NULL,'2024-04-18 15:44:57','2024-04-18 15:44:57','2024-04-18 15:44:57'),(1175,51,'MP',0,148,0,0,1,NULL,NULL,'2024-04-18 15:44:57','2024-04-18 15:44:57','2024-04-18 15:44:57'),(1176,51,'NO',0,166,0,0,1,NULL,NULL,'2024-04-18 15:44:57','2024-04-18 15:44:57','2024-04-18 15:44:57'),(1177,51,'OM',0,171,0,0,1,NULL,NULL,'2024-04-18 15:44:57','2024-04-18 15:44:57','2024-04-18 15:44:57'),(1178,51,'PK',0,177,0,0,1,NULL,NULL,'2024-04-18 15:44:57','2024-04-18 15:44:57','2024-04-18 15:44:57'),(1179,51,'PW',0,184,0,0,1,NULL,NULL,'2024-04-18 15:44:57','2024-04-18 15:44:57','2024-04-18 15:44:57'),(1180,51,'PS',0,182,0,0,1,NULL,NULL,'2024-04-18 15:44:57','2024-04-18 15:44:57','2024-04-18 15:44:57'),(1181,51,'PA',0,172,0,0,1,NULL,NULL,'2024-04-18 15:44:57','2024-04-18 15:44:57','2024-04-18 15:44:57'),(1182,51,'PG',0,175,0,0,1,NULL,NULL,'2024-04-18 15:44:57','2024-04-18 15:44:57','2024-04-18 15:44:57'),(1183,51,'PY',0,185,0,0,1,NULL,NULL,'2024-04-18 15:44:58','2024-04-18 15:44:58','2024-04-18 15:44:58'),(1184,51,'PE',0,173,0,0,1,NULL,NULL,'2024-04-18 15:44:57','2024-04-18 15:44:57','2024-04-18 15:44:57'),(1185,51,'PH',0,176,0,0,1,NULL,NULL,'2024-04-18 15:44:57','2024-04-18 15:44:57','2024-04-18 15:44:57'),(1186,51,'PN',0,180,0,0,1,NULL,NULL,'2024-04-18 15:44:57','2024-04-18 15:44:57','2024-04-18 15:44:57'),(1187,51,'PL',0,178,0,0,1,NULL,NULL,'2024-04-18 15:44:57','2024-04-18 15:44:57','2024-04-18 15:44:57'),(1188,51,'PT',0,183,0,0,1,NULL,NULL,'2024-04-18 15:44:57','2024-04-18 15:44:57','2024-04-18 15:44:57'),(1189,51,'PR',0,181,0,0,1,NULL,NULL,'2024-04-18 15:44:57','2024-04-18 15:44:57','2024-04-18 15:44:57'),(1190,51,'QA',0,186,0,0,1,NULL,NULL,'2024-04-18 15:44:58','2024-04-18 15:44:58','2024-04-18 15:44:58'),(1191,51,'RE',0,187,0,0,1,NULL,NULL,'2024-04-18 15:44:58','2024-04-18 15:44:58','2024-04-18 15:44:58'),(1192,51,'RO',0,188,0,0,1,NULL,NULL,'2024-04-18 15:44:58','2024-04-18 15:44:58','2024-04-18 15:44:58'),(1193,51,'RU',0,190,0,0,1,NULL,NULL,'2024-04-18 15:44:58','2024-04-18 15:44:58','2024-04-18 15:44:58'),(1194,51,'RW',0,191,0,0,1,NULL,NULL,'2024-04-18 15:44:58','2024-04-18 15:44:58','2024-04-18 15:44:58'),(1195,51,'BL',0,25,0,0,1,NULL,NULL,'2024-04-18 15:44:53','2024-04-18 15:44:53','2024-04-18 15:44:53'),(1196,51,'SH',0,198,0,0,1,NULL,NULL,'2024-04-18 15:44:58','2024-04-18 15:44:58','2024-04-18 15:44:58'),(1197,51,'KN',0,119,0,0,1,NULL,NULL,'2024-04-18 15:44:56','2024-04-18 15:44:56','2024-04-18 15:44:56'),(1198,51,'LC',0,127,0,0,1,NULL,NULL,'2024-04-18 15:44:56','2024-04-18 15:44:56','2024-04-18 15:44:56'),(1199,51,'MF',0,140,0,0,1,NULL,NULL,'2024-04-18 15:44:56','2024-04-18 15:44:56','2024-04-18 15:44:56'),(1200,51,'PM',0,179,0,0,1,NULL,NULL,'2024-04-18 15:44:57','2024-04-18 15:44:57','2024-04-18 15:44:57'),(1201,51,'VC',0,236,0,0,1,NULL,NULL,'2024-04-18 15:44:59','2024-04-18 15:44:59','2024-04-18 15:44:59'),(1202,51,'WS',0,243,0,0,1,NULL,NULL,'2024-04-18 15:44:59','2024-04-18 15:44:59','2024-04-18 15:44:59'),(1203,51,'SM',0,203,0,0,1,NULL,NULL,'2024-04-18 15:44:58','2024-04-18 15:44:58','2024-04-18 15:44:58'),(1204,51,'ST',0,208,0,0,1,NULL,NULL,'2024-04-18 15:44:58','2024-04-18 15:44:58','2024-04-18 15:44:58'),(1205,51,'SA',0,192,0,0,1,NULL,NULL,'2024-04-18 15:44:58','2024-04-18 15:44:58','2024-04-18 15:44:58'),(1206,51,'SN',0,204,0,0,1,NULL,NULL,'2024-04-18 15:44:58','2024-04-18 15:44:58','2024-04-18 15:44:58'),(1207,51,'RS',0,189,0,0,1,NULL,NULL,'2024-04-18 15:44:58','2024-04-18 15:44:58','2024-04-18 15:44:58'),(1208,51,'SC',0,194,0,0,1,NULL,NULL,'2024-04-18 15:44:58','2024-04-18 15:44:58','2024-04-18 15:44:58'),(1209,51,'SL',0,202,0,0,1,NULL,NULL,'2024-04-18 15:44:58','2024-04-18 15:44:58','2024-04-18 15:44:58'),(1210,51,'SG',0,197,0,0,1,NULL,NULL,'2024-04-18 15:44:58','2024-04-18 15:44:58','2024-04-18 15:44:58'),(1211,51,'SX',0,210,0,0,1,NULL,NULL,'2024-04-18 15:44:58','2024-04-18 15:44:58','2024-04-18 15:44:58'),(1212,51,'SK',0,201,0,0,1,NULL,NULL,'2024-04-18 15:44:58','2024-04-18 15:44:58','2024-04-18 15:44:58'),(1213,51,'SI',0,199,0,0,1,NULL,NULL,'2024-04-18 15:44:58','2024-04-18 15:44:58','2024-04-18 15:44:58'),(1214,51,'SB',0,193,0,0,1,NULL,NULL,'2024-04-18 15:44:58','2024-04-18 15:44:58','2024-04-18 15:44:58'),(1215,51,'SO',0,205,0,0,1,NULL,NULL,'2024-04-18 15:44:58','2024-04-18 15:44:58','2024-04-18 15:44:58'),(1216,51,'ZA',0,246,0,0,1,NULL,NULL,'2024-04-18 15:44:59','2024-04-18 15:44:59','2024-04-18 15:44:59'),(1217,51,'GS',0,89,0,0,1,NULL,NULL,'2024-04-18 15:44:55','2024-04-18 15:44:55','2024-04-18 15:44:55'),(1218,51,'SS',0,207,0,0,1,NULL,NULL,'2024-04-18 15:44:58','2024-04-18 15:44:58','2024-04-18 15:44:58'),(1219,51,'ES',0,67,0,0,1,NULL,NULL,'2024-04-18 15:44:54','2024-04-18 15:44:54','2024-04-18 15:44:54'),(1220,51,'LK',0,129,0,0,1,NULL,NULL,'2024-04-18 15:44:56','2024-04-18 15:44:56','2024-04-18 15:44:56'),(1221,51,'SD',0,195,0,0,1,NULL,NULL,'2024-04-18 15:44:58','2024-04-18 15:44:58','2024-04-18 15:44:58'),(1222,51,'SR',0,206,0,0,1,NULL,NULL,'2024-04-18 15:44:58','2024-04-18 15:44:58','2024-04-18 15:44:58'),(1223,51,'SJ',0,200,0,0,1,NULL,NULL,'2024-04-18 15:44:58','2024-04-18 15:44:58','2024-04-18 15:44:58'),(1224,51,'SZ',0,212,0,0,1,NULL,NULL,'2024-04-18 15:44:58','2024-04-18 15:44:58','2024-04-18 15:44:58'),(1225,51,'SE',0,196,0,0,1,NULL,NULL,'2024-04-18 15:44:58','2024-04-18 15:44:58','2024-04-18 15:44:58'),(1226,51,'CH',0,42,0,0,1,NULL,NULL,'2024-04-18 15:44:54','2024-04-18 15:44:54','2024-04-18 15:44:54'),(1227,51,'SY',0,211,0,0,1,NULL,NULL,'2024-04-18 15:44:58','2024-04-18 15:44:58','2024-04-18 15:44:58'),(1228,51,'TW',0,227,0,0,1,NULL,NULL,'2024-04-18 15:44:59','2024-04-18 15:44:59','2024-04-18 15:44:59'),(1229,51,'TJ',0,218,0,0,1,NULL,NULL,'2024-04-18 15:44:58','2024-04-18 15:44:58','2024-04-18 15:44:58'),(1230,51,'TZ',0,228,0,0,1,NULL,NULL,'2024-04-18 15:44:59','2024-04-18 15:44:59','2024-04-18 15:44:59'),(1231,51,'TH',0,217,0,0,1,NULL,NULL,'2024-04-18 15:44:58','2024-04-18 15:44:58','2024-04-18 15:44:58'),(1232,51,'TL',0,220,0,0,1,NULL,NULL,'2024-04-18 15:44:58','2024-04-18 15:44:58','2024-04-18 15:44:58'),(1233,51,'TG',0,216,0,0,1,NULL,NULL,'2024-04-18 15:44:58','2024-04-18 15:44:58','2024-04-18 15:44:58'),(1234,51,'TK',0,219,0,0,1,NULL,NULL,'2024-04-18 15:44:58','2024-04-18 15:44:58','2024-04-18 15:44:58'),(1235,51,'TO',0,223,0,0,1,NULL,NULL,'2024-04-18 15:44:59','2024-04-18 15:44:59','2024-04-18 15:44:59'),(1236,51,'TT',0,225,0,0,1,NULL,NULL,'2024-04-18 15:44:59','2024-04-18 15:44:59','2024-04-18 15:44:59'),(1237,51,'TN',0,222,0,0,1,NULL,NULL,'2024-04-18 15:44:59','2024-04-18 15:44:59','2024-04-18 15:44:59'),(1238,51,'TR',0,224,0,0,1,NULL,NULL,'2024-04-18 15:44:59','2024-04-18 15:44:59','2024-04-18 15:44:59'),(1239,51,'TM',0,221,0,0,1,NULL,NULL,'2024-04-18 15:44:58','2024-04-18 15:44:58','2024-04-18 15:44:58'),(1240,51,'TC',0,213,0,0,1,NULL,NULL,'2024-04-18 15:44:58','2024-04-18 15:44:58','2024-04-18 15:44:58'),(1241,51,'TV',0,226,0,0,1,NULL,NULL,'2024-04-18 15:44:59','2024-04-18 15:44:59','2024-04-18 15:44:59'),(1242,51,'UG',0,230,0,0,1,NULL,NULL,'2024-04-18 15:44:59','2024-04-18 15:44:59','2024-04-18 15:44:59'),(1243,51,'UA',0,229,0,0,1,NULL,NULL,'2024-04-18 15:44:59','2024-04-18 15:44:59','2024-04-18 15:44:59'),(1244,51,'AE',0,1,0,0,1,NULL,NULL,'2024-04-18 15:44:52','2024-04-18 15:44:52','2024-04-18 15:44:52'),(1245,51,'GB',0,76,0,0,1,NULL,NULL,'2024-04-18 15:44:55','2024-04-18 15:44:55','2024-04-18 15:44:55'),(1246,51,'US',0,232,0,0,1,NULL,NULL,'2024-04-18 15:44:59','2024-04-18 15:44:59','2024-04-18 15:44:59'),(1247,51,'UM',0,231,0,0,1,NULL,NULL,'2024-04-18 15:44:59','2024-04-18 15:44:59','2024-04-18 15:44:59'),(1248,51,'UY',0,233,0,0,1,NULL,NULL,'2024-04-18 15:44:59','2024-04-18 15:44:59','2024-04-18 15:44:59'),(1249,51,'UZ',0,234,0,0,1,NULL,NULL,'2024-04-18 15:44:59','2024-04-18 15:44:59','2024-04-18 15:44:59'),(1250,51,'VU',0,241,0,0,1,NULL,NULL,'2024-04-18 15:44:59','2024-04-18 15:44:59','2024-04-18 15:44:59'),(1251,51,'VE',0,237,0,0,1,NULL,NULL,'2024-04-18 15:44:59','2024-04-18 15:44:59','2024-04-18 15:44:59'),(1252,51,'VN',0,240,0,0,1,NULL,NULL,'2024-04-18 15:44:59','2024-04-18 15:44:59','2024-04-18 15:44:59'),(1253,51,'VG',0,238,0,0,1,NULL,NULL,'2024-04-18 15:44:59','2024-04-18 15:44:59','2024-04-18 15:44:59'),(1254,51,'VI',0,239,0,0,1,NULL,NULL,'2024-04-18 15:44:59','2024-04-18 15:44:59','2024-04-18 15:44:59'),(1255,51,'WF',0,242,0,0,1,NULL,NULL,'2024-04-18 15:44:59','2024-04-18 15:44:59','2024-04-18 15:44:59'),(1256,51,'EH',0,65,0,0,1,NULL,NULL,'2024-04-18 15:44:54','2024-04-18 15:44:54','2024-04-18 15:44:54'),(1257,51,'YE',0,244,0,0,1,NULL,NULL,'2024-04-18 15:44:59','2024-04-18 15:44:59','2024-04-18 15:44:59'),(1258,51,'ZM',0,247,0,0,1,NULL,NULL,'2024-04-18 15:44:59','2024-04-18 15:44:59','2024-04-18 15:44:59'),(1259,51,'ZW',0,248,0,0,1,NULL,NULL,'2024-04-18 15:44:59','2024-04-18 15:44:59','2024-04-18 15:44:59'),(1260,52,'copyright',0,0,0,0,1,NULL,NULL,'2024-04-18 15:45:27','2024-04-18 15:45:27','2024-04-18 15:45:27'),(1261,52,'license',0,1,0,0,1,NULL,NULL,'2024-04-18 15:45:27','2024-04-18 15:45:27','2024-04-18 15:45:27'),(1262,52,'statute',0,2,0,0,1,NULL,NULL,'2024-04-18 15:45:27','2024-04-18 15:45:27','2024-04-18 15:45:27'),(1263,52,'other',0,3,0,0,1,NULL,NULL,'2024-04-18 15:45:27','2024-04-18 15:45:27','2024-04-18 15:45:27'),(1264,53,'copyrighted',0,0,0,0,1,NULL,NULL,'2024-04-18 15:45:26','2024-04-18 15:45:26','2024-04-18 15:45:26'),(1265,53,'public_domain',0,1,0,0,1,NULL,NULL,'2024-04-18 15:45:26','2024-04-18 15:45:26','2024-04-18 15:45:26'),(1266,53,'unknown',0,2,0,0,1,NULL,NULL,'2024-04-18 15:45:26','2024-04-18 15:45:26','2024-04-18 15:45:26'),(1267,54,'cultural_context',0,0,0,0,1,NULL,NULL,'2024-04-18 15:45:26','2024-04-18 15:45:26','2024-04-18 15:45:26'),(1268,54,'function',0,1,0,0,1,NULL,NULL,'2024-04-18 15:45:26','2024-04-18 15:45:26','2024-04-18 15:45:26'),(1269,54,'geographic',0,3,0,0,1,NULL,NULL,'2024-04-18 15:45:26','2024-04-18 15:45:26','2024-04-18 15:45:26'),(1270,54,'genre_form',0,2,0,0,1,NULL,NULL,'2024-04-18 15:45:26','2024-04-18 15:45:26','2024-04-18 15:45:26'),(1271,54,'occupation',0,4,0,0,1,NULL,NULL,'2024-04-18 15:45:26','2024-04-18 15:45:26','2024-04-18 15:45:26'),(1272,54,'style_period',0,5,0,0,1,NULL,NULL,'2024-04-18 15:45:26','2024-04-18 15:45:26','2024-04-18 15:45:26'),(1273,54,'technique',0,6,0,0,1,NULL,NULL,'2024-04-18 15:45:26','2024-04-18 15:45:26','2024-04-18 15:45:26'),(1274,54,'temporal',0,7,0,0,1,NULL,NULL,'2024-04-18 15:45:26','2024-04-18 15:45:26','2024-04-18 15:45:26'),(1275,54,'topical',0,8,0,0,1,NULL,NULL,'2024-04-18 15:45:26','2024-04-18 15:45:26','2024-04-18 15:45:26'),(1276,54,'uniform_title',0,9,0,0,1,NULL,NULL,'2024-04-18 15:45:26','2024-04-18 15:45:26','2024-04-18 15:45:26'),(1277,55,'novalue',0,0,0,0,1,NULL,NULL,'2024-04-18 15:45:28','2024-04-18 15:45:28','2024-04-18 15:45:28'),(1278,56,'novalue',0,0,0,0,1,NULL,NULL,'2024-04-18 15:45:28','2024-04-18 15:45:28','2024-04-18 15:45:28'),(1279,57,'novalue',0,0,0,0,1,NULL,NULL,'2024-04-18 15:45:28','2024-04-18 15:45:28','2024-04-18 15:45:28'),(1280,58,'novalue',0,0,0,0,1,NULL,NULL,'2024-04-18 15:45:28','2024-04-18 15:45:28','2024-04-18 15:45:28'),(1281,34,'range',0,2,0,0,1,NULL,NULL,'2024-04-18 15:45:24','2024-04-18 15:45:24','2024-04-18 15:45:24'),(1282,59,'has_part',0,1,0,0,1,NULL,NULL,'2024-04-18 15:45:27','2024-04-18 15:45:27','2024-04-18 15:45:27'),(1283,59,'forms_part_of',0,0,0,0,1,NULL,NULL,'2024-04-18 15:45:27','2024-04-18 15:45:27','2024-04-18 15:45:27'),(1284,60,'part',0,0,0,0,1,NULL,NULL,'2024-04-18 15:45:28','2024-04-18 15:45:28','2024-04-18 15:45:28'),(1285,61,'sibling_of',0,0,0,0,1,NULL,NULL,'2024-04-18 15:45:28','2024-04-18 15:45:28','2024-04-18 15:45:28'),(1286,62,'bound_with',0,0,0,0,1,NULL,NULL,'2024-04-18 15:45:24','2024-04-18 15:45:24','2024-04-18 15:45:24'),(1290,1,'abr',0,226,0,0,1,NULL,NULL,NULL,NULL,NULL),(1291,1,'adi',0,227,0,0,1,NULL,NULL,NULL,NULL,NULL),(1292,1,'ape',0,228,0,0,1,NULL,NULL,NULL,NULL,NULL),(1293,1,'apl',0,229,0,0,1,NULL,NULL,NULL,NULL,NULL),(1294,1,'ato',0,230,0,0,1,NULL,NULL,NULL,NULL,NULL),(1295,1,'brd',0,231,0,0,1,NULL,NULL,NULL,NULL,NULL),(1296,1,'brl',0,232,0,0,1,NULL,NULL,NULL,NULL,NULL),(1297,1,'cas',0,233,0,0,1,NULL,NULL,NULL,NULL,NULL),(1298,1,'cor',0,234,0,0,1,NULL,NULL,NULL,NULL,NULL),(1299,1,'cou',0,235,0,0,1,NULL,NULL,NULL,NULL,NULL),(1300,1,'crt',0,236,0,0,1,NULL,NULL,NULL,NULL,NULL),(1301,1,'dgs',0,237,0,0,1,NULL,NULL,NULL,NULL,NULL),(1302,1,'edc',0,238,0,0,1,NULL,NULL,NULL,NULL,NULL),(1303,1,'edm',0,239,0,0,1,NULL,NULL,NULL,NULL,NULL),(1304,1,'enj',0,240,0,0,1,NULL,NULL,NULL,NULL,NULL),(1305,1,'fds',0,241,0,0,1,NULL,NULL,NULL,NULL,NULL),(1306,1,'fmd',0,242,0,0,1,NULL,NULL,NULL,NULL,NULL),(1307,1,'fmk',0,243,0,0,1,NULL,NULL,NULL,NULL,NULL),(1308,1,'fmp',0,244,0,0,1,NULL,NULL,NULL,NULL,NULL),(1309,1,'-grt',0,245,0,0,1,NULL,NULL,NULL,NULL,NULL),(1310,1,'his',0,246,0,0,1,NULL,NULL,NULL,NULL,NULL),(1311,1,'isb',0,247,0,0,1,NULL,NULL,NULL,NULL,NULL),(1312,1,'jud',0,248,0,0,1,NULL,NULL,NULL,NULL,NULL),(1313,1,'jug',0,249,0,0,1,NULL,NULL,NULL,NULL,NULL),(1314,1,'med',0,250,0,0,1,NULL,NULL,NULL,NULL,NULL),(1315,1,'mtk',0,251,0,0,1,NULL,NULL,NULL,NULL,NULL),(1316,1,'osp',0,252,0,0,1,NULL,NULL,NULL,NULL,NULL),(1317,1,'pan',0,253,0,0,1,NULL,NULL,NULL,NULL,NULL),(1318,1,'pra',0,254,0,0,1,NULL,NULL,NULL,NULL,NULL),(1319,1,'pre',0,255,0,0,1,NULL,NULL,NULL,NULL,NULL),(1320,1,'prn',0,256,0,0,1,NULL,NULL,NULL,NULL,NULL),(1321,1,'prs',0,257,0,0,1,NULL,NULL,NULL,NULL,NULL),(1322,1,'rdd',0,258,0,0,1,NULL,NULL,NULL,NULL,NULL),(1323,1,'rpc',0,259,0,0,1,NULL,NULL,NULL,NULL,NULL),(1324,1,'rsr',0,260,0,0,1,NULL,NULL,NULL,NULL,NULL),(1325,1,'sgd',0,261,0,0,1,NULL,NULL,NULL,NULL,NULL),(1326,1,'sll',0,262,0,0,1,NULL,NULL,NULL,NULL,NULL),(1327,1,'tld',0,263,0,0,1,NULL,NULL,NULL,NULL,NULL),(1328,1,'tlp',0,264,0,0,1,NULL,NULL,NULL,NULL,NULL),(1329,1,'vac',0,265,0,0,1,NULL,NULL,NULL,NULL,NULL),(1330,1,'wac',0,266,0,0,1,NULL,NULL,NULL,NULL,NULL),(1331,1,'wal',0,267,0,0,1,NULL,NULL,NULL,NULL,NULL),(1332,1,'wat',0,268,0,0,1,NULL,NULL,NULL,NULL,NULL),(1333,1,'win',0,269,0,0,1,NULL,NULL,NULL,NULL,NULL),(1334,1,'wpr',0,270,0,0,1,NULL,NULL,NULL,NULL,NULL),(1335,1,'wst',0,271,0,0,1,NULL,NULL,NULL,NULL,NULL),(1336,64,'business',0,0,0,0,1,NULL,NULL,NULL,NULL,NULL),(1337,64,'home',0,1,0,0,1,NULL,NULL,NULL,NULL,NULL),(1338,64,'cell',0,2,0,0,1,NULL,NULL,NULL,NULL,NULL),(1339,64,'fax',0,3,0,0,1,NULL,NULL,NULL,NULL,NULL),(1340,15,'processing_started',0,33,0,0,1,NULL,NULL,NULL,NULL,NULL),(1341,15,'processing_completed',0,34,0,0,1,NULL,NULL,NULL,NULL,NULL),(1342,15,'processing_in_progress',0,35,0,0,1,NULL,NULL,NULL,NULL,NULL),(1343,15,'processing_new',0,36,0,0,1,NULL,NULL,NULL,NULL,NULL),(1344,65,'RestrictedSpecColl',0,0,0,0,1,NULL,NULL,NULL,NULL,NULL),(1345,65,'RestrictedCurApprSpecColl',0,1,0,0,1,NULL,NULL,NULL,NULL,NULL),(1346,65,'RestrictedFragileSpecColl',0,2,0,0,1,NULL,NULL,NULL,NULL,NULL),(1347,65,'InProcessSpecColl',0,3,0,0,1,NULL,NULL,NULL,NULL,NULL),(1348,65,'ColdStorageBrbl',0,4,0,0,1,NULL,NULL,NULL,NULL,NULL),(1349,66,'inches',0,0,0,0,1,NULL,NULL,NULL,NULL,NULL),(1350,66,'feet',0,1,0,0,1,NULL,NULL,NULL,NULL,NULL),(1351,66,'yards',0,2,0,0,1,NULL,NULL,NULL,NULL,NULL),(1352,66,'millimeters',0,3,0,0,1,NULL,NULL,NULL,NULL,NULL),(1353,66,'centimeters',0,4,0,0,1,NULL,NULL,NULL,NULL,NULL),(1354,66,'meters',0,5,0,0,1,NULL,NULL,NULL,NULL,NULL),(1357,67,'av_materials',0,0,0,0,1,NULL,NULL,NULL,NULL,NULL),(1358,67,'arrivals',0,1,0,0,1,NULL,NULL,NULL,NULL,NULL),(1359,67,'shared',0,2,0,0,1,NULL,NULL,NULL,NULL,NULL),(1360,68,'delete',0,0,0,0,1,NULL,NULL,NULL,NULL,NULL),(1361,68,'disseminate',0,1,0,0,1,NULL,NULL,NULL,NULL,NULL),(1362,68,'migrate',0,2,0,0,1,NULL,NULL,NULL,NULL,NULL),(1363,68,'modify',0,3,0,0,1,NULL,NULL,NULL,NULL,NULL),(1364,68,'replicate',0,4,0,0,1,NULL,NULL,NULL,NULL,NULL),(1365,68,'use',0,5,0,0,1,NULL,NULL,NULL,NULL,NULL),(1366,69,'allow',0,0,0,0,1,NULL,NULL,NULL,NULL,NULL),(1367,69,'disallow',0,1,0,0,1,NULL,NULL,NULL,NULL,NULL),(1368,69,'conditional',0,2,0,0,1,NULL,NULL,NULL,NULL,NULL),(1369,70,'permissions',0,0,0,0,1,NULL,NULL,NULL,NULL,NULL),(1370,70,'restrictions',0,1,0,0,1,NULL,NULL,NULL,NULL,NULL),(1371,70,'extension',0,2,0,0,1,NULL,NULL,NULL,NULL,NULL),(1372,70,'expiration',0,3,0,0,1,NULL,NULL,NULL,NULL,NULL),(1373,70,'additional_information',0,4,0,0,1,NULL,NULL,NULL,NULL,NULL),(1374,71,'materials',0,0,0,0,1,NULL,NULL,NULL,NULL,NULL),(1375,71,'type_note',0,1,0,0,1,NULL,NULL,NULL,NULL,NULL),(1376,71,'additional_information',0,2,0,0,1,NULL,NULL,NULL,NULL,NULL),(1377,72,'agrovoc',0,0,0,0,1,NULL,NULL,NULL,NULL,NULL),(1378,72,'allmovie',0,1,0,0,1,NULL,NULL,NULL,NULL,NULL),(1379,72,'allmusic',0,2,0,0,1,NULL,NULL,NULL,NULL,NULL),(1380,72,'allocine',0,3,0,0,1,NULL,NULL,NULL,NULL,NULL),(1381,72,'amnbo',0,4,0,0,1,NULL,NULL,NULL,NULL,NULL),(1382,72,'ansi',0,5,0,0,1,NULL,NULL,NULL,NULL,NULL),(1383,72,'artsy',0,6,0,0,1,NULL,NULL,NULL,NULL,NULL),(1384,72,'bdusc',0,7,0,0,1,NULL,NULL,NULL,NULL,NULL),(1385,72,'bfi',0,8,0,0,1,NULL,NULL,NULL,NULL,NULL),(1386,72,'bnfcg',0,9,0,0,1,NULL,NULL,NULL,NULL,NULL),(1387,72,'cantic',0,10,0,0,1,NULL,NULL,NULL,NULL,NULL),(1388,72,'cgndb',0,11,0,0,1,NULL,NULL,NULL,NULL,NULL),(1389,72,'danacode',0,12,0,0,1,NULL,NULL,NULL,NULL,NULL),(1390,72,'datoses',0,13,0,0,1,NULL,NULL,NULL,NULL,NULL),(1391,72,'discogs',0,14,0,0,1,NULL,NULL,NULL,NULL,NULL),(1392,72,'dkfilm',0,15,0,0,1,NULL,NULL,NULL,NULL,NULL),(1393,72,'doi',0,16,0,0,1,NULL,NULL,NULL,NULL,NULL),(1394,72,'ean',0,17,0,0,1,NULL,NULL,NULL,NULL,NULL),(1395,72,'eidr',0,18,0,0,1,NULL,NULL,NULL,NULL,NULL),(1396,72,'fast',0,19,0,0,1,NULL,NULL,NULL,NULL,NULL),(1397,72,'filmport',0,20,0,0,1,NULL,NULL,NULL,NULL,NULL),(1398,72,'findagr',0,21,0,0,1,NULL,NULL,NULL,NULL,NULL),(1399,72,'freebase',0,22,0,0,1,NULL,NULL,NULL,NULL,NULL),(1400,72,'gec',0,23,0,0,1,NULL,NULL,NULL,NULL,NULL),(1401,72,'geogndb',0,24,0,0,1,NULL,NULL,NULL,NULL,NULL),(1402,72,'geonames',0,25,0,0,1,NULL,NULL,NULL,NULL,NULL),(1403,72,'gettytgn',0,26,0,0,1,NULL,NULL,NULL,NULL,NULL),(1404,72,'gettyulan',0,27,0,0,1,NULL,NULL,NULL,NULL,NULL),(1405,72,'gnd',0,28,0,0,1,NULL,NULL,NULL,NULL,NULL),(1406,72,'gnis',0,29,0,0,1,NULL,NULL,NULL,NULL,NULL),(1407,72,'gtin-14',0,30,0,0,1,NULL,NULL,NULL,NULL,NULL),(1408,72,'hdl',0,31,0,0,1,NULL,NULL,NULL,NULL,NULL),(1409,72,'ibdb',0,32,0,0,1,NULL,NULL,NULL,NULL,NULL),(1410,72,'idref',0,33,0,0,1,NULL,NULL,NULL,NULL,NULL),(1411,72,'imdb',0,34,0,0,1,NULL,NULL,NULL,NULL,NULL),(1412,72,'isan',0,35,0,0,1,NULL,NULL,NULL,NULL,NULL),(1413,72,'isbn',0,36,0,0,1,NULL,NULL,NULL,NULL,NULL),(1414,72,'isbn-a',0,37,0,0,1,NULL,NULL,NULL,NULL,NULL),(1415,72,'isbnre',0,38,0,0,1,NULL,NULL,NULL,NULL,NULL),(1416,72,'isil',0,39,0,0,1,NULL,NULL,NULL,NULL,NULL),(1417,72,'ismn',0,40,0,0,1,NULL,NULL,NULL,NULL,NULL),(1418,72,'isni',0,41,0,0,1,NULL,NULL,NULL,NULL,NULL),(1419,72,'iso',0,42,0,0,1,NULL,NULL,NULL,NULL,NULL),(1420,72,'isrc',0,43,0,0,1,NULL,NULL,NULL,NULL,NULL),(1421,72,'issn',0,44,0,0,1,NULL,NULL,NULL,NULL,NULL),(1422,72,'issn-l',0,45,0,0,1,NULL,NULL,NULL,NULL,NULL),(1423,72,'issue-number',0,46,0,0,1,NULL,NULL,NULL,NULL,NULL),(1424,72,'istc',0,47,0,0,1,NULL,NULL,NULL,NULL,NULL),(1425,72,'iswc',0,48,0,0,1,NULL,NULL,NULL,NULL,NULL),(1426,72,'itar',0,49,0,0,1,NULL,NULL,NULL,NULL,NULL),(1427,72,'kinopo',0,50,0,0,1,NULL,NULL,NULL,NULL,NULL),(1428,72,'lccn',0,51,0,0,1,NULL,NULL,NULL,NULL,NULL),(1429,72,'lcmd',0,52,0,0,1,NULL,NULL,NULL,NULL,NULL),(1430,72,'lcmpt',0,53,0,0,1,NULL,NULL,NULL,NULL,NULL),(1431,72,'libaus',0,54,0,0,1,NULL,NULL,NULL,NULL,NULL),(1432,72,'local',0,55,0,0,1,NULL,NULL,NULL,NULL,NULL),(1433,72,'matrix-number',0,56,0,0,1,NULL,NULL,NULL,NULL,NULL),(1434,72,'moma',0,57,0,0,1,NULL,NULL,NULL,NULL,NULL),(1435,72,'munzing',0,58,0,0,1,NULL,NULL,NULL,NULL,NULL),(1436,72,'music-plate',0,59,0,0,1,NULL,NULL,NULL,NULL,NULL),(1437,72,'music-publisher',0,60,0,0,1,NULL,NULL,NULL,NULL,NULL),(1438,72,'musicb',0,61,0,0,1,NULL,NULL,NULL,NULL,NULL),(1439,72,'natgazfid',0,62,0,0,1,NULL,NULL,NULL,NULL,NULL),(1440,72,'nga',0,63,0,0,1,NULL,NULL,NULL,NULL,NULL),(1441,72,'nipo',0,64,0,0,1,NULL,NULL,NULL,NULL,NULL),(1442,72,'nndb',0,65,0,0,1,NULL,NULL,NULL,NULL,NULL),(1443,72,'npg',0,66,0,0,1,NULL,NULL,NULL,NULL,NULL),(1444,72,'odnb',0,67,0,0,1,NULL,NULL,NULL,NULL,NULL),(1445,72,'opensm',0,68,0,0,1,NULL,NULL,NULL,NULL,NULL),(1446,72,'orcid',0,69,0,0,1,NULL,NULL,NULL,NULL,NULL),(1447,72,'oxforddnb',0,70,0,0,1,NULL,NULL,NULL,NULL,NULL),(1448,72,'porthu',0,71,0,0,1,NULL,NULL,NULL,NULL,NULL),(1449,72,'rbmsbt',0,72,0,0,1,NULL,NULL,NULL,NULL,NULL),(1450,72,'rbmsgt',0,73,0,0,1,NULL,NULL,NULL,NULL,NULL),(1451,72,'rbmspe',0,74,0,0,1,NULL,NULL,NULL,NULL,NULL),(1452,72,'rbmsppe',0,75,0,0,1,NULL,NULL,NULL,NULL,NULL),(1453,72,'rbmspt',0,76,0,0,1,NULL,NULL,NULL,NULL,NULL),(1454,72,'rbmsrd',0,77,0,0,1,NULL,NULL,NULL,NULL,NULL),(1455,72,'rbmste',0,78,0,0,1,NULL,NULL,NULL,NULL,NULL),(1456,72,'rid',0,79,0,0,1,NULL,NULL,NULL,NULL,NULL),(1457,72,'rkda',0,80,0,0,1,NULL,NULL,NULL,NULL,NULL),(1458,72,'saam',0,81,0,0,1,NULL,NULL,NULL,NULL,NULL),(1459,72,'scholaru',0,82,0,0,1,NULL,NULL,NULL,NULL,NULL),(1460,72,'scope',0,83,0,0,1,NULL,NULL,NULL,NULL,NULL),(1461,72,'scopus',0,84,0,0,1,NULL,NULL,NULL,NULL,NULL),(1462,72,'sici',0,85,0,0,1,NULL,NULL,NULL,NULL,NULL),(1463,72,'spotify',0,86,0,0,1,NULL,NULL,NULL,NULL,NULL),(1464,72,'sprfbsb',0,87,0,0,1,NULL,NULL,NULL,NULL,NULL),(1465,72,'sprfbsk',0,88,0,0,1,NULL,NULL,NULL,NULL,NULL),(1466,72,'sprfcbb',0,89,0,0,1,NULL,NULL,NULL,NULL,NULL),(1467,72,'sprfcfb',0,90,0,0,1,NULL,NULL,NULL,NULL,NULL),(1468,72,'sprfhoc',0,91,0,0,1,NULL,NULL,NULL,NULL,NULL),(1469,72,'sprfoly',0,92,0,0,1,NULL,NULL,NULL,NULL,NULL),(1470,72,'sprfpfb',0,93,0,0,1,NULL,NULL,NULL,NULL,NULL),(1471,72,'stock-number',0,94,0,0,1,NULL,NULL,NULL,NULL,NULL),(1472,72,'strn',0,95,0,0,1,NULL,NULL,NULL,NULL,NULL),(1473,72,'svfilm',0,96,0,0,1,NULL,NULL,NULL,NULL,NULL),(1474,72,'tatearid',0,97,0,0,1,NULL,NULL,NULL,NULL,NULL),(1475,72,'theatr',0,98,0,0,1,NULL,NULL,NULL,NULL,NULL),(1476,72,'trove',0,99,0,0,1,NULL,NULL,NULL,NULL,NULL),(1477,72,'upc',0,100,0,0,1,NULL,NULL,NULL,NULL,NULL),(1478,72,'uri',0,101,0,0,1,NULL,NULL,NULL,NULL,NULL),(1479,72,'urn',0,102,0,0,1,NULL,NULL,NULL,NULL,NULL),(1480,72,'viaf',0,103,0,0,1,NULL,NULL,NULL,NULL,NULL),(1481,72,'videorecording-identifier',0,104,0,0,1,NULL,NULL,NULL,NULL,NULL),(1482,72,'wikidata',0,105,0,0,1,NULL,NULL,NULL,NULL,NULL),(1483,72,'wndla',0,106,0,0,1,NULL,NULL,NULL,NULL,NULL),(1484,73,'donor',0,0,0,0,1,NULL,NULL,NULL,NULL,NULL),(1485,73,'policy',0,1,0,0,1,NULL,NULL,NULL,NULL,NULL),(1486,15,'request',1,37,0,0,1,NULL,NULL,'2024-04-18 15:46:23','2024-04-18 15:46:23','2024-04-18 15:46:23'),(1487,18,'cancelled',1,3,0,0,1,NULL,NULL,'2024-04-18 15:46:23','2024-04-18 15:46:23','2024-04-18 15:46:23'),(1488,18,'fulfilled',1,4,0,0,1,NULL,NULL,'2024-04-18 15:46:23','2024-04-18 15:46:23','2024-04-18 15:46:23'),(1489,18,'pending',1,5,0,0,1,NULL,NULL,'2024-04-18 15:46:23','2024-04-18 15:46:23','2024-04-18 15:46:23'),(1490,3,'requester',1,6,0,0,1,NULL,NULL,'2024-04-18 15:46:23','2024-04-18 15:46:23','2024-04-18 15:46:23'),(1491,2,'context',1,3,0,0,1,NULL,NULL,'2024-04-18 15:46:23','2024-04-18 15:46:23','2024-04-18 15:46:23'),(1492,2,'requested',1,4,0,0,1,NULL,NULL,'2024-04-18 15:46:23','2024-04-18 15:46:23','2024-04-18 15:46:23'),(1493,26,'cnr',0,485,0,0,1,NULL,NULL,NULL,NULL,NULL),(1494,26,'zgh',0,486,0,0,1,NULL,NULL,NULL,NULL,NULL),(1495,74,'Adlm',0,0,0,0,1,NULL,NULL,NULL,NULL,NULL),(1496,74,'Afak',0,1,0,0,1,NULL,NULL,NULL,NULL,NULL),(1497,74,'Aghb',0,2,0,0,1,NULL,NULL,NULL,NULL,NULL),(1498,74,'Ahom',0,3,0,0,1,NULL,NULL,NULL,NULL,NULL),(1499,74,'Arab',0,4,0,0,1,NULL,NULL,NULL,NULL,NULL),(1500,74,'Aran',0,5,0,0,1,NULL,NULL,NULL,NULL,NULL),(1501,74,'Armi',0,6,0,0,1,NULL,NULL,NULL,NULL,NULL),(1502,74,'Armn',0,7,0,0,1,NULL,NULL,NULL,NULL,NULL),(1503,74,'Avst',0,8,0,0,1,NULL,NULL,NULL,NULL,NULL),(1504,74,'Bali',0,9,0,0,1,NULL,NULL,NULL,NULL,NULL),(1505,74,'Bamu',0,10,0,0,1,NULL,NULL,NULL,NULL,NULL),(1506,74,'Bass',0,11,0,0,1,NULL,NULL,NULL,NULL,NULL),(1507,74,'Batk',0,12,0,0,1,NULL,NULL,NULL,NULL,NULL),(1508,74,'Beng',0,13,0,0,1,NULL,NULL,NULL,NULL,NULL),(1509,74,'Bhks',0,14,0,0,1,NULL,NULL,NULL,NULL,NULL),(1510,74,'Blis',0,15,0,0,1,NULL,NULL,NULL,NULL,NULL),(1511,74,'Bopo',0,16,0,0,1,NULL,NULL,NULL,NULL,NULL),(1512,74,'Brah',0,17,0,0,1,NULL,NULL,NULL,NULL,NULL),(1513,74,'Brai',0,18,0,0,1,NULL,NULL,NULL,NULL,NULL),(1514,74,'Bugi',0,19,0,0,1,NULL,NULL,NULL,NULL,NULL),(1515,74,'Buhd',0,20,0,0,1,NULL,NULL,NULL,NULL,NULL),(1516,74,'Cakm',0,21,0,0,1,NULL,NULL,NULL,NULL,NULL),(1517,74,'Cans',0,22,0,0,1,NULL,NULL,NULL,NULL,NULL),(1518,74,'Cari',0,23,0,0,1,NULL,NULL,NULL,NULL,NULL),(1519,74,'Cham',0,24,0,0,1,NULL,NULL,NULL,NULL,NULL),(1520,74,'Cher',0,25,0,0,1,NULL,NULL,NULL,NULL,NULL),(1521,74,'Cirt',0,26,0,0,1,NULL,NULL,NULL,NULL,NULL),(1522,74,'Copt',0,27,0,0,1,NULL,NULL,NULL,NULL,NULL),(1523,74,'Cpmn',0,28,0,0,1,NULL,NULL,NULL,NULL,NULL),(1524,74,'Cprt',0,29,0,0,1,NULL,NULL,NULL,NULL,NULL),(1525,74,'Cyrl',0,30,0,0,1,NULL,NULL,NULL,NULL,NULL),(1526,74,'Cyrs',0,31,0,0,1,NULL,NULL,NULL,NULL,NULL),(1527,74,'Deva',0,32,0,0,1,NULL,NULL,NULL,NULL,NULL),(1528,74,'Dogr',0,33,0,0,1,NULL,NULL,NULL,NULL,NULL),(1529,74,'Dsrt',0,34,0,0,1,NULL,NULL,NULL,NULL,NULL),(1530,74,'Dupl',0,35,0,0,1,NULL,NULL,NULL,NULL,NULL),(1531,74,'Egyd',0,36,0,0,1,NULL,NULL,NULL,NULL,NULL),(1532,74,'Egyh',0,37,0,0,1,NULL,NULL,NULL,NULL,NULL),(1533,74,'Egyp',0,38,0,0,1,NULL,NULL,NULL,NULL,NULL),(1534,74,'Elba',0,39,0,0,1,NULL,NULL,NULL,NULL,NULL),(1535,74,'Elym',0,40,0,0,1,NULL,NULL,NULL,NULL,NULL),(1536,74,'Ethi',0,41,0,0,1,NULL,NULL,NULL,NULL,NULL),(1537,74,'Geok',0,42,0,0,1,NULL,NULL,NULL,NULL,NULL),(1538,74,'Geor',0,43,0,0,1,NULL,NULL,NULL,NULL,NULL),(1539,74,'Glag',0,44,0,0,1,NULL,NULL,NULL,NULL,NULL),(1540,74,'Gong',0,45,0,0,1,NULL,NULL,NULL,NULL,NULL),(1541,74,'Gonm',0,46,0,0,1,NULL,NULL,NULL,NULL,NULL),(1542,74,'Goth',0,47,0,0,1,NULL,NULL,NULL,NULL,NULL),(1543,74,'Gran',0,48,0,0,1,NULL,NULL,NULL,NULL,NULL),(1544,74,'Grek',0,49,0,0,1,NULL,NULL,NULL,NULL,NULL),(1545,74,'Gujr',0,50,0,0,1,NULL,NULL,NULL,NULL,NULL),(1546,74,'Guru',0,51,0,0,1,NULL,NULL,NULL,NULL,NULL),(1547,74,'Hanb',0,52,0,0,1,NULL,NULL,NULL,NULL,NULL),(1548,74,'Hang',0,53,0,0,1,NULL,NULL,NULL,NULL,NULL),(1549,74,'Hani',0,54,0,0,1,NULL,NULL,NULL,NULL,NULL),(1550,74,'Hano',0,55,0,0,1,NULL,NULL,NULL,NULL,NULL),(1551,74,'Hans',0,56,0,0,1,NULL,NULL,NULL,NULL,NULL),(1552,74,'Hant',0,57,0,0,1,NULL,NULL,NULL,NULL,NULL),(1553,74,'Hatr',0,58,0,0,1,NULL,NULL,NULL,NULL,NULL),(1554,74,'Hebr',0,59,0,0,1,NULL,NULL,NULL,NULL,NULL),(1555,74,'Hira',0,60,0,0,1,NULL,NULL,NULL,NULL,NULL),(1556,74,'Hluw',0,61,0,0,1,NULL,NULL,NULL,NULL,NULL),(1557,74,'Hmng',0,62,0,0,1,NULL,NULL,NULL,NULL,NULL),(1558,74,'Hmnp',0,63,0,0,1,NULL,NULL,NULL,NULL,NULL),(1559,74,'Hrkt',0,64,0,0,1,NULL,NULL,NULL,NULL,NULL),(1560,74,'Hung',0,65,0,0,1,NULL,NULL,NULL,NULL,NULL),(1561,74,'Inds',0,66,0,0,1,NULL,NULL,NULL,NULL,NULL),(1562,74,'Ital',0,67,0,0,1,NULL,NULL,NULL,NULL,NULL),(1563,74,'Jamo',0,68,0,0,1,NULL,NULL,NULL,NULL,NULL),(1564,74,'Java',0,69,0,0,1,NULL,NULL,NULL,NULL,NULL),(1565,74,'Jpan',0,70,0,0,1,NULL,NULL,NULL,NULL,NULL),(1566,74,'Jurc',0,71,0,0,1,NULL,NULL,NULL,NULL,NULL),(1567,74,'Kali',0,72,0,0,1,NULL,NULL,NULL,NULL,NULL),(1568,74,'Kana',0,73,0,0,1,NULL,NULL,NULL,NULL,NULL),(1569,74,'Khar',0,74,0,0,1,NULL,NULL,NULL,NULL,NULL),(1570,74,'Khmr',0,75,0,0,1,NULL,NULL,NULL,NULL,NULL),(1571,74,'Khoj',0,76,0,0,1,NULL,NULL,NULL,NULL,NULL),(1572,74,'Kitl',0,77,0,0,1,NULL,NULL,NULL,NULL,NULL),(1573,74,'Kits',0,78,0,0,1,NULL,NULL,NULL,NULL,NULL),(1574,74,'Knda',0,79,0,0,1,NULL,NULL,NULL,NULL,NULL),(1575,74,'Kore',0,80,0,0,1,NULL,NULL,NULL,NULL,NULL),(1576,74,'Kpel',0,81,0,0,1,NULL,NULL,NULL,NULL,NULL),(1577,74,'Kthi',0,82,0,0,1,NULL,NULL,NULL,NULL,NULL),(1578,74,'Lana',0,83,0,0,1,NULL,NULL,NULL,NULL,NULL),(1579,74,'Laoo',0,84,0,0,1,NULL,NULL,NULL,NULL,NULL),(1580,74,'Latf',0,85,0,0,1,NULL,NULL,NULL,NULL,NULL),(1581,74,'Latg',0,86,0,0,1,NULL,NULL,NULL,NULL,NULL),(1582,74,'Latn',0,87,0,0,1,NULL,NULL,NULL,NULL,NULL),(1583,74,'Leke',0,88,0,0,1,NULL,NULL,NULL,NULL,NULL),(1584,74,'Lepc',0,89,0,0,1,NULL,NULL,NULL,NULL,NULL),(1585,74,'Limb',0,90,0,0,1,NULL,NULL,NULL,NULL,NULL),(1586,74,'Lina',0,91,0,0,1,NULL,NULL,NULL,NULL,NULL),(1587,74,'Linb',0,92,0,0,1,NULL,NULL,NULL,NULL,NULL),(1588,74,'Lisu',0,93,0,0,1,NULL,NULL,NULL,NULL,NULL),(1589,74,'Loma',0,94,0,0,1,NULL,NULL,NULL,NULL,NULL),(1590,74,'Lyci',0,95,0,0,1,NULL,NULL,NULL,NULL,NULL),(1591,74,'Lydi',0,96,0,0,1,NULL,NULL,NULL,NULL,NULL),(1592,74,'Mahj',0,97,0,0,1,NULL,NULL,NULL,NULL,NULL),(1593,74,'Maka',0,98,0,0,1,NULL,NULL,NULL,NULL,NULL),(1594,74,'Mand',0,99,0,0,1,NULL,NULL,NULL,NULL,NULL),(1595,74,'Mani',0,100,0,0,1,NULL,NULL,NULL,NULL,NULL),(1596,74,'Marc',0,101,0,0,1,NULL,NULL,NULL,NULL,NULL),(1597,74,'Maya',0,102,0,0,1,NULL,NULL,NULL,NULL,NULL),(1598,74,'Medf',0,103,0,0,1,NULL,NULL,NULL,NULL,NULL),(1599,74,'Mend',0,104,0,0,1,NULL,NULL,NULL,NULL,NULL),(1600,74,'Merc',0,105,0,0,1,NULL,NULL,NULL,NULL,NULL),(1601,74,'Mero',0,106,0,0,1,NULL,NULL,NULL,NULL,NULL),(1602,74,'Mlym',0,107,0,0,1,NULL,NULL,NULL,NULL,NULL),(1603,74,'Modi',0,108,0,0,1,NULL,NULL,NULL,NULL,NULL),(1604,74,'Mong',0,109,0,0,1,NULL,NULL,NULL,NULL,NULL),(1605,74,'Moon',0,110,0,0,1,NULL,NULL,NULL,NULL,NULL),(1606,74,'Mroo',0,111,0,0,1,NULL,NULL,NULL,NULL,NULL),(1607,74,'Mtei',0,112,0,0,1,NULL,NULL,NULL,NULL,NULL),(1608,74,'Mult',0,113,0,0,1,NULL,NULL,NULL,NULL,NULL),(1609,74,'Mymr',0,114,0,0,1,NULL,NULL,NULL,NULL,NULL),(1610,74,'Nand',0,115,0,0,1,NULL,NULL,NULL,NULL,NULL),(1611,74,'Narb',0,116,0,0,1,NULL,NULL,NULL,NULL,NULL),(1612,74,'Nbat',0,117,0,0,1,NULL,NULL,NULL,NULL,NULL),(1613,74,'Newa',0,118,0,0,1,NULL,NULL,NULL,NULL,NULL),(1614,74,'Nkdb',0,119,0,0,1,NULL,NULL,NULL,NULL,NULL),(1615,74,'Nkgb',0,120,0,0,1,NULL,NULL,NULL,NULL,NULL),(1616,74,'Nkoo',0,121,0,0,1,NULL,NULL,NULL,NULL,NULL),(1617,74,'Nshu',0,122,0,0,1,NULL,NULL,NULL,NULL,NULL),(1618,74,'Ogam',0,123,0,0,1,NULL,NULL,NULL,NULL,NULL),(1619,74,'Olck',0,124,0,0,1,NULL,NULL,NULL,NULL,NULL),(1620,74,'Orkh',0,125,0,0,1,NULL,NULL,NULL,NULL,NULL),(1621,74,'Orya',0,126,0,0,1,NULL,NULL,NULL,NULL,NULL),(1622,74,'Osge',0,127,0,0,1,NULL,NULL,NULL,NULL,NULL),(1623,74,'Osma',0,128,0,0,1,NULL,NULL,NULL,NULL,NULL),(1624,74,'Palm',0,129,0,0,1,NULL,NULL,NULL,NULL,NULL),(1625,74,'Pauc',0,130,0,0,1,NULL,NULL,NULL,NULL,NULL),(1626,74,'Perm',0,131,0,0,1,NULL,NULL,NULL,NULL,NULL),(1627,74,'Phag',0,132,0,0,1,NULL,NULL,NULL,NULL,NULL),(1628,74,'Phli',0,133,0,0,1,NULL,NULL,NULL,NULL,NULL),(1629,74,'Phlp',0,134,0,0,1,NULL,NULL,NULL,NULL,NULL),(1630,74,'Phlv',0,135,0,0,1,NULL,NULL,NULL,NULL,NULL),(1631,74,'Phnx',0,136,0,0,1,NULL,NULL,NULL,NULL,NULL),(1632,74,'Plrd',0,137,0,0,1,NULL,NULL,NULL,NULL,NULL),(1633,74,'Piqd',0,138,0,0,1,NULL,NULL,NULL,NULL,NULL),(1634,74,'Prti',0,139,0,0,1,NULL,NULL,NULL,NULL,NULL),(1635,74,'Qaaa',0,140,0,0,1,NULL,NULL,NULL,NULL,NULL),(1636,74,'Qabx',0,141,0,0,1,NULL,NULL,NULL,NULL,NULL),(1637,74,'Rjng',0,142,0,0,1,NULL,NULL,NULL,NULL,NULL),(1638,74,'Rohg',0,143,0,0,1,NULL,NULL,NULL,NULL,NULL),(1639,74,'Roro',0,144,0,0,1,NULL,NULL,NULL,NULL,NULL),(1640,74,'Runr',0,145,0,0,1,NULL,NULL,NULL,NULL,NULL),(1641,74,'Samr',0,146,0,0,1,NULL,NULL,NULL,NULL,NULL),(1642,74,'Sara',0,147,0,0,1,NULL,NULL,NULL,NULL,NULL),(1643,74,'Sarb',0,148,0,0,1,NULL,NULL,NULL,NULL,NULL),(1644,74,'Saur',0,149,0,0,1,NULL,NULL,NULL,NULL,NULL),(1645,74,'Sgnw',0,150,0,0,1,NULL,NULL,NULL,NULL,NULL),(1646,74,'Shaw',0,151,0,0,1,NULL,NULL,NULL,NULL,NULL),(1647,74,'Shrd',0,152,0,0,1,NULL,NULL,NULL,NULL,NULL),(1648,74,'Shui',0,153,0,0,1,NULL,NULL,NULL,NULL,NULL),(1649,74,'Sidd',0,154,0,0,1,NULL,NULL,NULL,NULL,NULL),(1650,74,'Sind',0,155,0,0,1,NULL,NULL,NULL,NULL,NULL),(1651,74,'Sinh',0,156,0,0,1,NULL,NULL,NULL,NULL,NULL),(1652,74,'Sogd',0,157,0,0,1,NULL,NULL,NULL,NULL,NULL),(1653,74,'Sogo',0,158,0,0,1,NULL,NULL,NULL,NULL,NULL),(1654,74,'Sora',0,159,0,0,1,NULL,NULL,NULL,NULL,NULL),(1655,74,'Soyo',0,160,0,0,1,NULL,NULL,NULL,NULL,NULL),(1656,74,'Sund',0,161,0,0,1,NULL,NULL,NULL,NULL,NULL),(1657,74,'Sylo',0,162,0,0,1,NULL,NULL,NULL,NULL,NULL),(1658,74,'Syrc',0,163,0,0,1,NULL,NULL,NULL,NULL,NULL),(1659,74,'Syre',0,164,0,0,1,NULL,NULL,NULL,NULL,NULL),(1660,74,'Syrj',0,165,0,0,1,NULL,NULL,NULL,NULL,NULL),(1661,74,'Syrn',0,166,0,0,1,NULL,NULL,NULL,NULL,NULL),(1662,74,'Tagb',0,167,0,0,1,NULL,NULL,NULL,NULL,NULL),(1663,74,'Takr',0,168,0,0,1,NULL,NULL,NULL,NULL,NULL),(1664,74,'Tale',0,169,0,0,1,NULL,NULL,NULL,NULL,NULL),(1665,74,'Talu',0,170,0,0,1,NULL,NULL,NULL,NULL,NULL),(1666,74,'Taml',0,171,0,0,1,NULL,NULL,NULL,NULL,NULL),(1667,74,'Tang',0,172,0,0,1,NULL,NULL,NULL,NULL,NULL),(1668,74,'Tavt',0,173,0,0,1,NULL,NULL,NULL,NULL,NULL),(1669,74,'Telu',0,174,0,0,1,NULL,NULL,NULL,NULL,NULL),(1670,74,'Teng',0,175,0,0,1,NULL,NULL,NULL,NULL,NULL),(1671,74,'Tfng',0,176,0,0,1,NULL,NULL,NULL,NULL,NULL),(1672,74,'Tglg',0,177,0,0,1,NULL,NULL,NULL,NULL,NULL),(1673,74,'Thaa',0,178,0,0,1,NULL,NULL,NULL,NULL,NULL),(1674,74,'Thai',0,179,0,0,1,NULL,NULL,NULL,NULL,NULL),(1675,74,'Tibt',0,180,0,0,1,NULL,NULL,NULL,NULL,NULL),(1676,74,'Tirh',0,181,0,0,1,NULL,NULL,NULL,NULL,NULL),(1677,74,'Ugar',0,182,0,0,1,NULL,NULL,NULL,NULL,NULL),(1678,74,'Vaii',0,183,0,0,1,NULL,NULL,NULL,NULL,NULL),(1679,74,'Visp',0,184,0,0,1,NULL,NULL,NULL,NULL,NULL),(1680,74,'Wara',0,185,0,0,1,NULL,NULL,NULL,NULL,NULL),(1681,74,'Wcho',0,186,0,0,1,NULL,NULL,NULL,NULL,NULL),(1682,74,'Wole',0,187,0,0,1,NULL,NULL,NULL,NULL,NULL),(1683,74,'Xpeo',0,188,0,0,1,NULL,NULL,NULL,NULL,NULL),(1684,74,'Xsux',0,189,0,0,1,NULL,NULL,NULL,NULL,NULL),(1685,74,'Yiii',0,190,0,0,1,NULL,NULL,NULL,NULL,NULL),(1686,74,'Zanb',0,191,0,0,1,NULL,NULL,NULL,NULL,NULL),(1687,74,'Zinh',0,192,0,0,1,NULL,NULL,NULL,NULL,NULL),(1688,74,'Zmth',0,193,0,0,1,NULL,NULL,NULL,NULL,NULL),(1689,74,'Zsye',0,194,0,0,1,NULL,NULL,NULL,NULL,NULL),(1690,74,'Zsym',0,195,0,0,1,NULL,NULL,NULL,NULL,NULL),(1691,74,'Zxxx',0,196,0,0,1,NULL,NULL,NULL,NULL,NULL),(1692,74,'Zyyy',0,197,0,0,1,NULL,NULL,NULL,NULL,NULL),(1693,74,'Zzzz',0,198,0,0,1,NULL,NULL,NULL,NULL,NULL),(1694,75,'langmaterial',0,0,0,0,1,NULL,NULL,NULL,NULL,NULL),(1695,4,'ingest',0,4,0,0,1,NULL,NULL,NULL,NULL,NULL),(1696,23,'ingest',0,7,0,0,1,NULL,NULL,NULL,NULL,NULL),(1697,76,'new',0,0,0,0,1,NULL,NULL,NULL,NULL,NULL),(1698,76,'upgraded',0,1,0,0,1,NULL,NULL,NULL,NULL,NULL),(1699,76,'revised_corrected',0,2,0,0,1,NULL,NULL,NULL,NULL,NULL),(1700,76,'derived',0,3,0,0,1,NULL,NULL,NULL,NULL,NULL),(1701,76,'deleted',0,4,0,0,1,NULL,NULL,NULL,NULL,NULL),(1702,76,'cancelled_obsolete',0,5,0,0,1,NULL,NULL,NULL,NULL,NULL),(1703,76,'deleted_split',0,6,0,0,1,NULL,NULL,NULL,NULL,NULL),(1704,76,'deleted_replaced',0,7,0,0,1,NULL,NULL,NULL,NULL,NULL),(1705,77,'in_process',0,0,0,0,1,NULL,NULL,NULL,NULL,NULL),(1706,77,'approved',0,1,0,0,1,NULL,NULL,NULL,NULL,NULL),(1707,78,'int_std',0,0,0,0,1,NULL,NULL,NULL,NULL,NULL),(1708,78,'nat_std',0,1,0,0,1,NULL,NULL,NULL,NULL,NULL),(1709,78,'nl_assoc_std',0,2,0,0,1,NULL,NULL,NULL,NULL,NULL),(1710,78,'nl_bib_agency_std',0,3,0,0,1,NULL,NULL,NULL,NULL,NULL),(1711,78,'local_standard',0,4,0,0,1,NULL,NULL,NULL,NULL,NULL),(1712,78,'unknown_standard',0,5,0,0,1,NULL,NULL,NULL,NULL,NULL),(1713,78,'conv_rom_cat_agency',0,6,0,0,1,NULL,NULL,NULL,NULL,NULL),(1714,78,'not_applicable',0,7,0,0,1,NULL,NULL,NULL,NULL,NULL),(1715,79,'ala-lc',0,0,0,0,1,NULL,NULL,NULL,NULL,NULL),(1716,80,'ngo',0,0,0,0,1,NULL,NULL,NULL,NULL,NULL),(1717,80,'sac',0,1,0,0,1,NULL,NULL,NULL,NULL,NULL),(1718,80,'multilocal',0,2,0,0,1,NULL,NULL,NULL,NULL,NULL),(1719,80,'fed',0,3,0,0,1,NULL,NULL,NULL,NULL,NULL),(1720,80,'int_gov',0,4,0,0,1,NULL,NULL,NULL,NULL,NULL),(1721,80,'local',0,5,0,0,1,NULL,NULL,NULL,NULL,NULL),(1722,80,'multistate',0,6,0,0,1,NULL,NULL,NULL,NULL,NULL),(1723,80,'undetermined',0,7,0,0,1,NULL,NULL,NULL,NULL,NULL),(1724,80,'provincial',0,8,0,0,1,NULL,NULL,NULL,NULL,NULL),(1725,80,'unknown',0,9,0,0,1,NULL,NULL,NULL,NULL,NULL),(1726,80,'other',0,10,0,0,1,NULL,NULL,NULL,NULL,NULL),(1727,80,'natc',0,11,0,0,1,NULL,NULL,NULL,NULL,NULL),(1728,81,'tr_consistent',0,0,0,0,1,NULL,NULL,NULL,NULL,NULL),(1729,81,'tr_inconsistent',0,1,0,0,1,NULL,NULL,NULL,NULL,NULL),(1730,81,'not_applicable',0,2,0,0,1,NULL,NULL,NULL,NULL,NULL),(1731,81,'natc',0,3,0,0,1,NULL,NULL,NULL,NULL,NULL),(1732,82,'differentiated',0,0,0,0,1,NULL,NULL,NULL,NULL,NULL),(1733,82,'undifferentiated',0,1,0,0,1,NULL,NULL,NULL,NULL,NULL),(1734,82,'not_applicable',0,2,0,0,1,NULL,NULL,NULL,NULL,NULL),(1735,82,'natc',0,3,0,0,1,NULL,NULL,NULL,NULL,NULL),(1736,83,'fully_established',0,0,0,0,1,NULL,NULL,NULL,NULL,NULL),(1737,83,'memorandum',0,1,0,0,1,NULL,NULL,NULL,NULL,NULL),(1738,83,'provisional',0,2,0,0,1,NULL,NULL,NULL,NULL,NULL),(1739,83,'preliminary',0,3,0,0,1,NULL,NULL,NULL,NULL,NULL),(1740,83,'not_applicable',0,4,0,0,1,NULL,NULL,NULL,NULL,NULL),(1741,83,'natc',0,5,0,0,1,NULL,NULL,NULL,NULL,NULL),(1742,84,'not_modified',0,0,0,0,1,NULL,NULL,NULL,NULL,NULL),(1743,84,'shortened',0,1,0,0,1,NULL,NULL,NULL,NULL,NULL),(1744,84,'missing_characters',0,2,0,0,1,NULL,NULL,NULL,NULL,NULL),(1745,84,'natc',0,3,0,0,1,NULL,NULL,NULL,NULL,NULL),(1746,85,'nat_bib_agency',0,0,0,0,1,NULL,NULL,NULL,NULL,NULL),(1747,85,'ccp',0,1,0,0,1,NULL,NULL,NULL,NULL,NULL),(1748,85,'other',0,2,0,0,1,NULL,NULL,NULL,NULL,NULL),(1749,85,'unknown',0,3,0,0,1,NULL,NULL,NULL,NULL,NULL),(1750,85,'natc',0,4,0,0,1,NULL,NULL,NULL,NULL,NULL),(1751,86,'loc',0,0,0,0,1,NULL,NULL,NULL,NULL,NULL),(1752,86,'lac',0,1,0,0,1,NULL,NULL,NULL,NULL,NULL),(1753,86,'local',0,2,0,0,1,NULL,NULL,NULL,NULL,NULL),(1754,86,'other_unmapped',0,3,0,0,1,NULL,NULL,NULL,NULL,NULL),(1755,87,'oclc',0,0,0,0,1,NULL,NULL,NULL,NULL,NULL),(1756,87,'local',0,1,0,0,1,NULL,NULL,NULL,NULL,NULL),(1757,88,'created',0,0,0,0,1,NULL,NULL,NULL,NULL,NULL),(1758,88,'cancelled',0,1,0,0,1,NULL,NULL,NULL,NULL,NULL),(1759,88,'deleted',0,2,0,0,1,NULL,NULL,NULL,NULL,NULL),(1760,88,'derived',0,3,0,0,1,NULL,NULL,NULL,NULL,NULL),(1761,88,'revised',0,4,0,0,1,NULL,NULL,NULL,NULL,NULL),(1762,88,'updated',0,5,0,0,1,NULL,NULL,NULL,NULL,NULL),(1763,89,'human',0,0,0,0,1,NULL,NULL,NULL,NULL,NULL),(1764,89,'machine',0,1,0,0,1,NULL,NULL,NULL,NULL,NULL),(1765,90,'single',0,0,0,0,1,NULL,NULL,NULL,NULL,NULL),(1766,90,'range',0,1,0,0,1,NULL,NULL,NULL,NULL,NULL),(1767,91,'begin',0,0,0,0,1,NULL,NULL,NULL,NULL,NULL),(1768,91,'end',0,1,0,0,1,NULL,NULL,NULL,NULL,NULL),(1769,92,'standard',0,0,0,0,1,NULL,NULL,NULL,NULL,NULL),(1770,92,'not_before',0,1,0,0,1,NULL,NULL,NULL,NULL,NULL),(1771,92,'not_after',0,2,0,0,1,NULL,NULL,NULL,NULL,NULL),(1772,93,'standard',0,0,0,0,1,NULL,NULL,NULL,NULL,NULL),(1773,93,'not_before',0,1,0,0,1,NULL,NULL,NULL,NULL,NULL),(1774,93,'not_after',0,2,0,0,1,NULL,NULL,NULL,NULL,NULL),(1775,94,'standard',0,0,0,0,1,NULL,NULL,NULL,NULL,NULL),(1776,94,'not_before',0,1,0,0,1,NULL,NULL,NULL,NULL,NULL),(1777,94,'not_after',0,2,0,0,1,NULL,NULL,NULL,NULL,NULL),(1778,95,'assoc_country',0,0,0,0,1,NULL,NULL,NULL,NULL,NULL),(1779,95,'residence',0,1,0,0,1,NULL,NULL,NULL,NULL,NULL),(1780,95,'other_assoc',0,2,0,0,1,NULL,NULL,NULL,NULL,NULL),(1781,95,'place_of_birth',0,3,0,0,1,NULL,NULL,NULL,NULL,NULL),(1782,95,'place_of_death',0,4,0,0,1,NULL,NULL,NULL,NULL,NULL),(1783,96,'is_identified_with',1,0,0,0,1,NULL,NULL,NULL,NULL,NULL),(1784,97,'is_hierarchical_with',1,0,0,0,1,NULL,NULL,NULL,NULL,NULL),(1785,98,'is_temporal_with',1,0,0,0,1,NULL,NULL,NULL,NULL,NULL),(1786,99,'is_related_with',1,0,0,0,1,NULL,NULL,NULL,NULL,NULL),(1787,100,'not_specified',0,0,0,0,1,NULL,NULL,NULL,NULL,NULL),(1788,4,'snac',0,5,0,0,1,NULL,NULL,NULL,NULL,NULL),(1789,102,'public_domain',0,0,0,0,1,NULL,NULL,NULL,NULL,NULL),(1790,102,'non_commercial',0,1,0,0,1,NULL,NULL,NULL,NULL,NULL),(1791,102,'non_commercial_no_derivatives',0,2,0,0,1,NULL,NULL,NULL,NULL,NULL),(1792,102,'no_derivatives',0,3,0,0,1,NULL,NULL,NULL,NULL,NULL),(1793,102,'share_a_like',0,4,0,0,1,NULL,NULL,NULL,NULL,NULL),(1794,102,'non_commercial_share_a_like',0,5,0,0,1,NULL,NULL,NULL,NULL,NULL),(1795,76,'deleted_merged',0,8,0,0,1,NULL,NULL,NULL,NULL,NULL);
/*!40000 ALTER TABLE `enumeration_value` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `event`
--

DROP TABLE IF EXISTS `event`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `event` (
  `id` int NOT NULL AUTO_INCREMENT,
  `lock_version` int NOT NULL DEFAULT '0',
  `json_schema_version` int NOT NULL,
  `suppressed` int NOT NULL DEFAULT '0',
  `repo_id` int NOT NULL,
  `event_type_id` int NOT NULL,
  `outcome_id` int DEFAULT NULL,
  `outcome_note` varchar(17408) DEFAULT NULL,
  `timestamp` datetime DEFAULT NULL,
  `created_by` varchar(255) DEFAULT NULL,
  `last_modified_by` varchar(255) DEFAULT NULL,
  `create_time` datetime NOT NULL,
  `system_mtime` datetime NOT NULL,
  `user_mtime` datetime NOT NULL,
  `refid` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `refid` (`refid`),
  KEY `event_type_id` (`event_type_id`),
  KEY `outcome_id` (`outcome_id`),
  KEY `event_system_mtime_index` (`system_mtime`),
  KEY `event_user_mtime_index` (`user_mtime`),
  KEY `event_suppressed_index` (`suppressed`),
  KEY `repo_id` (`repo_id`),
  CONSTRAINT `event_ibfk_1` FOREIGN KEY (`event_type_id`) REFERENCES `enumeration_value` (`id`),
  CONSTRAINT `event_ibfk_2` FOREIGN KEY (`outcome_id`) REFERENCES `enumeration_value` (`id`),
  CONSTRAINT `event_ibfk_3` FOREIGN KEY (`repo_id`) REFERENCES `repository` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `event`
--

LOCK TABLES `event` WRITE;
/*!40000 ALTER TABLE `event` DISABLE KEYS */;
/*!40000 ALTER TABLE `event` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `event_link_rlshp`
--

DROP TABLE IF EXISTS `event_link_rlshp`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `event_link_rlshp` (
  `id` int NOT NULL AUTO_INCREMENT,
  `accession_id` int DEFAULT NULL,
  `resource_id` int DEFAULT NULL,
  `archival_object_id` int DEFAULT NULL,
  `digital_object_id` int DEFAULT NULL,
  `digital_object_component_id` int DEFAULT NULL,
  `agent_person_id` int DEFAULT NULL,
  `agent_family_id` int DEFAULT NULL,
  `agent_corporate_entity_id` int DEFAULT NULL,
  `agent_software_id` int DEFAULT NULL,
  `event_id` int DEFAULT NULL,
  `aspace_relationship_position` int DEFAULT NULL,
  `created_by` varchar(255) DEFAULT NULL,
  `last_modified_by` varchar(255) DEFAULT NULL,
  `system_mtime` datetime NOT NULL,
  `user_mtime` datetime NOT NULL,
  `role_id` int DEFAULT NULL,
  `suppressed` int NOT NULL DEFAULT '0',
  `top_container_id` int DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `role_id` (`role_id`),
  KEY `event_link_rlshp_system_mtime_index` (`system_mtime`),
  KEY `event_link_rlshp_user_mtime_index` (`user_mtime`),
  KEY `accession_id` (`accession_id`),
  KEY `resource_id` (`resource_id`),
  KEY `archival_object_id` (`archival_object_id`),
  KEY `digital_object_id` (`digital_object_id`),
  KEY `agent_person_id` (`agent_person_id`),
  KEY `agent_family_id` (`agent_family_id`),
  KEY `agent_corporate_entity_id` (`agent_corporate_entity_id`),
  KEY `agent_software_id` (`agent_software_id`),
  KEY `event_id` (`event_id`),
  KEY `top_container_id` (`top_container_id`),
  CONSTRAINT `event_link_rlshp_ibfk_1` FOREIGN KEY (`role_id`) REFERENCES `enumeration_value` (`id`),
  CONSTRAINT `event_link_rlshp_ibfk_10` FOREIGN KEY (`event_id`) REFERENCES `event` (`id`),
  CONSTRAINT `event_link_rlshp_ibfk_11` FOREIGN KEY (`top_container_id`) REFERENCES `top_container` (`id`),
  CONSTRAINT `event_link_rlshp_ibfk_2` FOREIGN KEY (`accession_id`) REFERENCES `accession` (`id`),
  CONSTRAINT `event_link_rlshp_ibfk_3` FOREIGN KEY (`resource_id`) REFERENCES `resource` (`id`),
  CONSTRAINT `event_link_rlshp_ibfk_4` FOREIGN KEY (`archival_object_id`) REFERENCES `archival_object` (`id`),
  CONSTRAINT `event_link_rlshp_ibfk_5` FOREIGN KEY (`digital_object_id`) REFERENCES `digital_object` (`id`),
  CONSTRAINT `event_link_rlshp_ibfk_6` FOREIGN KEY (`agent_person_id`) REFERENCES `agent_person` (`id`),
  CONSTRAINT `event_link_rlshp_ibfk_7` FOREIGN KEY (`agent_family_id`) REFERENCES `agent_family` (`id`),
  CONSTRAINT `event_link_rlshp_ibfk_8` FOREIGN KEY (`agent_corporate_entity_id`) REFERENCES `agent_corporate_entity` (`id`),
  CONSTRAINT `event_link_rlshp_ibfk_9` FOREIGN KEY (`agent_software_id`) REFERENCES `agent_software` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `event_link_rlshp`
--

LOCK TABLES `event_link_rlshp` WRITE;
/*!40000 ALTER TABLE `event_link_rlshp` DISABLE KEYS */;
/*!40000 ALTER TABLE `event_link_rlshp` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `extent`
--

DROP TABLE IF EXISTS `extent`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `extent` (
  `id` int NOT NULL AUTO_INCREMENT,
  `lock_version` int NOT NULL DEFAULT '0',
  `json_schema_version` int NOT NULL,
  `accession_id` int DEFAULT NULL,
  `deaccession_id` int DEFAULT NULL,
  `archival_object_id` int DEFAULT NULL,
  `resource_id` int DEFAULT NULL,
  `digital_object_id` int DEFAULT NULL,
  `digital_object_component_id` int DEFAULT NULL,
  `portion_id` int NOT NULL,
  `number` varchar(255) NOT NULL,
  `extent_type_id` int NOT NULL,
  `container_summary` text,
  `physical_details` text,
  `dimensions` varchar(255) DEFAULT NULL,
  `created_by` varchar(255) DEFAULT NULL,
  `last_modified_by` varchar(255) DEFAULT NULL,
  `create_time` datetime NOT NULL,
  `system_mtime` datetime NOT NULL,
  `user_mtime` datetime NOT NULL,
  PRIMARY KEY (`id`),
  KEY `extent_type_id` (`extent_type_id`),
  KEY `extent_system_mtime_index` (`system_mtime`),
  KEY `extent_user_mtime_index` (`user_mtime`),
  KEY `accession_id` (`accession_id`),
  KEY `archival_object_id` (`archival_object_id`),
  KEY `resource_id` (`resource_id`),
  KEY `deaccession_id` (`deaccession_id`),
  KEY `digital_object_id` (`digital_object_id`),
  KEY `digital_object_component_id` (`digital_object_component_id`),
  CONSTRAINT `extent_ibfk_1` FOREIGN KEY (`extent_type_id`) REFERENCES `enumeration_value` (`id`),
  CONSTRAINT `extent_ibfk_2` FOREIGN KEY (`accession_id`) REFERENCES `accession` (`id`),
  CONSTRAINT `extent_ibfk_3` FOREIGN KEY (`archival_object_id`) REFERENCES `archival_object` (`id`),
  CONSTRAINT `extent_ibfk_4` FOREIGN KEY (`resource_id`) REFERENCES `resource` (`id`),
  CONSTRAINT `extent_ibfk_5` FOREIGN KEY (`deaccession_id`) REFERENCES `deaccession` (`id`),
  CONSTRAINT `extent_ibfk_6` FOREIGN KEY (`digital_object_id`) REFERENCES `digital_object` (`id`),
  CONSTRAINT `extent_ibfk_7` FOREIGN KEY (`digital_object_component_id`) REFERENCES `digital_object_component` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `extent`
--

LOCK TABLES `extent` WRITE;
/*!40000 ALTER TABLE `extent` DISABLE KEYS */;
/*!40000 ALTER TABLE `extent` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `external_document`
--

DROP TABLE IF EXISTS `external_document`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `external_document` (
  `id` int NOT NULL AUTO_INCREMENT,
  `lock_version` int NOT NULL DEFAULT '0',
  `json_schema_version` int NOT NULL,
  `title` varchar(8704) NOT NULL,
  `location` varchar(8704) NOT NULL,
  `publish` int DEFAULT NULL,
  `created_by` varchar(255) DEFAULT NULL,
  `last_modified_by` varchar(255) DEFAULT NULL,
  `create_time` datetime NOT NULL,
  `system_mtime` datetime NOT NULL,
  `user_mtime` datetime NOT NULL,
  `location_sha1` varchar(255) DEFAULT NULL,
  `accession_id` int DEFAULT NULL,
  `archival_object_id` int DEFAULT NULL,
  `resource_id` int DEFAULT NULL,
  `subject_id` int DEFAULT NULL,
  `agent_person_id` int DEFAULT NULL,
  `agent_family_id` int DEFAULT NULL,
  `agent_corporate_entity_id` int DEFAULT NULL,
  `agent_software_id` int DEFAULT NULL,
  `rights_statement_id` int DEFAULT NULL,
  `digital_object_id` int DEFAULT NULL,
  `digital_object_component_id` int DEFAULT NULL,
  `event_id` int DEFAULT NULL,
  `identifier_type_id` int DEFAULT NULL,
  `assessment_id` int DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uniq_exdoc_acc` (`accession_id`,`location_sha1`),
  UNIQUE KEY `uniq_exdoc_arc_obj` (`archival_object_id`,`location_sha1`),
  UNIQUE KEY `uniq_exdoc_res` (`resource_id`,`location_sha1`),
  UNIQUE KEY `uniq_exdoc_sub` (`subject_id`,`location_sha1`),
  UNIQUE KEY `uniq_exdoc_age_per` (`agent_person_id`,`location_sha1`),
  UNIQUE KEY `uniq_exdoc_age_fam` (`agent_family_id`,`location_sha1`),
  UNIQUE KEY `uniq_exdoc_age_cor_ent` (`agent_corporate_entity_id`,`location_sha1`),
  UNIQUE KEY `uniq_exdoc_age_sof` (`agent_software_id`,`location_sha1`),
  UNIQUE KEY `uniq_exdoc_rig_sta` (`rights_statement_id`,`location_sha1`),
  UNIQUE KEY `uniq_exdoc_dig_obj` (`digital_object_id`,`location_sha1`),
  UNIQUE KEY `uniq_exdoc_dig_obj_com` (`digital_object_component_id`,`location_sha1`),
  KEY `external_document_system_mtime_index` (`system_mtime`),
  KEY `external_document_user_mtime_index` (`user_mtime`),
  KEY `event_external_document_fk` (`event_id`),
  KEY `external_document_identifier_type_id_fk` (`identifier_type_id`),
  KEY `assessment_external_document_fk` (`assessment_id`),
  CONSTRAINT `assessment_external_document_fk` FOREIGN KEY (`assessment_id`) REFERENCES `event` (`id`),
  CONSTRAINT `event_external_document_fk` FOREIGN KEY (`event_id`) REFERENCES `event` (`id`),
  CONSTRAINT `external_document_ibfk_1` FOREIGN KEY (`accession_id`) REFERENCES `accession` (`id`),
  CONSTRAINT `external_document_ibfk_10` FOREIGN KEY (`digital_object_id`) REFERENCES `digital_object` (`id`),
  CONSTRAINT `external_document_ibfk_11` FOREIGN KEY (`digital_object_component_id`) REFERENCES `digital_object_component` (`id`),
  CONSTRAINT `external_document_ibfk_2` FOREIGN KEY (`archival_object_id`) REFERENCES `archival_object` (`id`),
  CONSTRAINT `external_document_ibfk_3` FOREIGN KEY (`resource_id`) REFERENCES `resource` (`id`),
  CONSTRAINT `external_document_ibfk_4` FOREIGN KEY (`subject_id`) REFERENCES `subject` (`id`),
  CONSTRAINT `external_document_ibfk_5` FOREIGN KEY (`agent_person_id`) REFERENCES `agent_person` (`id`),
  CONSTRAINT `external_document_ibfk_6` FOREIGN KEY (`agent_family_id`) REFERENCES `agent_family` (`id`),
  CONSTRAINT `external_document_ibfk_7` FOREIGN KEY (`agent_corporate_entity_id`) REFERENCES `agent_corporate_entity` (`id`),
  CONSTRAINT `external_document_ibfk_8` FOREIGN KEY (`agent_software_id`) REFERENCES `agent_software` (`id`),
  CONSTRAINT `external_document_ibfk_9` FOREIGN KEY (`rights_statement_id`) REFERENCES `rights_statement` (`id`),
  CONSTRAINT `external_document_identifier_type_id_fk` FOREIGN KEY (`identifier_type_id`) REFERENCES `enumeration_value` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `external_document`
--

LOCK TABLES `external_document` WRITE;
/*!40000 ALTER TABLE `external_document` DISABLE KEYS */;
/*!40000 ALTER TABLE `external_document` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `external_id`
--

DROP TABLE IF EXISTS `external_id`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `external_id` (
  `id` int NOT NULL AUTO_INCREMENT,
  `external_id` varchar(255) NOT NULL,
  `source` varchar(255) NOT NULL,
  `subject_id` int DEFAULT NULL,
  `accession_id` int DEFAULT NULL,
  `archival_object_id` int DEFAULT NULL,
  `collection_management_id` int DEFAULT NULL,
  `digital_object_id` int DEFAULT NULL,
  `digital_object_component_id` int DEFAULT NULL,
  `event_id` int DEFAULT NULL,
  `location_id` int DEFAULT NULL,
  `resource_id` int DEFAULT NULL,
  `created_by` varchar(255) DEFAULT NULL,
  `last_modified_by` varchar(255) DEFAULT NULL,
  `create_time` datetime NOT NULL,
  `system_mtime` datetime NOT NULL,
  `user_mtime` datetime NOT NULL,
  PRIMARY KEY (`id`),
  KEY `external_id_system_mtime_index` (`system_mtime`),
  KEY `external_id_user_mtime_index` (`user_mtime`),
  KEY `subject_id` (`subject_id`),
  KEY `accession_id` (`accession_id`),
  KEY `archival_object_id` (`archival_object_id`),
  KEY `collection_management_id` (`collection_management_id`),
  KEY `digital_object_id` (`digital_object_id`),
  KEY `digital_object_component_id` (`digital_object_component_id`),
  KEY `event_id` (`event_id`),
  KEY `location_id` (`location_id`),
  KEY `resource_id` (`resource_id`),
  CONSTRAINT `external_id_ibfk_1` FOREIGN KEY (`subject_id`) REFERENCES `subject` (`id`),
  CONSTRAINT `external_id_ibfk_2` FOREIGN KEY (`accession_id`) REFERENCES `accession` (`id`),
  CONSTRAINT `external_id_ibfk_3` FOREIGN KEY (`archival_object_id`) REFERENCES `archival_object` (`id`),
  CONSTRAINT `external_id_ibfk_4` FOREIGN KEY (`collection_management_id`) REFERENCES `collection_management` (`id`),
  CONSTRAINT `external_id_ibfk_5` FOREIGN KEY (`digital_object_id`) REFERENCES `digital_object` (`id`),
  CONSTRAINT `external_id_ibfk_6` FOREIGN KEY (`digital_object_component_id`) REFERENCES `digital_object_component` (`id`),
  CONSTRAINT `external_id_ibfk_7` FOREIGN KEY (`event_id`) REFERENCES `event` (`id`),
  CONSTRAINT `external_id_ibfk_8` FOREIGN KEY (`location_id`) REFERENCES `location` (`id`),
  CONSTRAINT `external_id_ibfk_9` FOREIGN KEY (`resource_id`) REFERENCES `resource` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `external_id`
--

LOCK TABLES `external_id` WRITE;
/*!40000 ALTER TABLE `external_id` DISABLE KEYS */;
/*!40000 ALTER TABLE `external_id` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `file_version`
--

DROP TABLE IF EXISTS `file_version`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `file_version` (
  `id` int NOT NULL AUTO_INCREMENT,
  `lock_version` int NOT NULL DEFAULT '0',
  `json_schema_version` int NOT NULL,
  `digital_object_id` int DEFAULT NULL,
  `digital_object_component_id` int DEFAULT NULL,
  `use_statement_id` int DEFAULT NULL,
  `checksum_method_id` int DEFAULT NULL,
  `file_uri` varchar(17408) NOT NULL,
  `publish` int DEFAULT NULL,
  `xlink_actuate_attribute_id` int DEFAULT NULL,
  `xlink_show_attribute_id` int DEFAULT NULL,
  `file_format_name_id` int DEFAULT NULL,
  `file_format_version` varchar(255) DEFAULT NULL,
  `file_size_bytes` bigint DEFAULT NULL,
  `checksum` varchar(255) DEFAULT NULL,
  `checksum_method` varchar(255) DEFAULT NULL,
  `created_by` varchar(255) DEFAULT NULL,
  `last_modified_by` varchar(255) DEFAULT NULL,
  `create_time` datetime NOT NULL,
  `system_mtime` datetime NOT NULL,
  `user_mtime` datetime NOT NULL,
  `is_representative` int DEFAULT NULL,
  `caption` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `digital_object_one_representative_file_version` (`is_representative`,`digital_object_id`),
  KEY `use_statement_id` (`use_statement_id`),
  KEY `checksum_method_id` (`checksum_method_id`),
  KEY `xlink_actuate_attribute_id` (`xlink_actuate_attribute_id`),
  KEY `xlink_show_attribute_id` (`xlink_show_attribute_id`),
  KEY `file_format_name_id` (`file_format_name_id`),
  KEY `file_version_system_mtime_index` (`system_mtime`),
  KEY `file_version_user_mtime_index` (`user_mtime`),
  KEY `digital_object_id` (`digital_object_id`),
  KEY `digital_object_component_id` (`digital_object_component_id`),
  CONSTRAINT `file_version_ibfk_1` FOREIGN KEY (`use_statement_id`) REFERENCES `enumeration_value` (`id`),
  CONSTRAINT `file_version_ibfk_2` FOREIGN KEY (`checksum_method_id`) REFERENCES `enumeration_value` (`id`),
  CONSTRAINT `file_version_ibfk_3` FOREIGN KEY (`xlink_actuate_attribute_id`) REFERENCES `enumeration_value` (`id`),
  CONSTRAINT `file_version_ibfk_4` FOREIGN KEY (`xlink_show_attribute_id`) REFERENCES `enumeration_value` (`id`),
  CONSTRAINT `file_version_ibfk_5` FOREIGN KEY (`file_format_name_id`) REFERENCES `enumeration_value` (`id`),
  CONSTRAINT `file_version_ibfk_6` FOREIGN KEY (`digital_object_id`) REFERENCES `digital_object` (`id`),
  CONSTRAINT `file_version_ibfk_7` FOREIGN KEY (`digital_object_component_id`) REFERENCES `digital_object_component` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `file_version`
--

LOCK TABLES `file_version` WRITE;
/*!40000 ALTER TABLE `file_version` DISABLE KEYS */;
/*!40000 ALTER TABLE `file_version` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `group`
--

DROP TABLE IF EXISTS `group`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `group` (
  `id` int NOT NULL AUTO_INCREMENT,
  `lock_version` int NOT NULL DEFAULT '0',
  `json_schema_version` int NOT NULL,
  `repo_id` int NOT NULL,
  `group_code` varchar(255) NOT NULL,
  `group_code_norm` varchar(255) NOT NULL,
  `description` text NOT NULL,
  `created_by` varchar(255) DEFAULT NULL,
  `last_modified_by` varchar(255) DEFAULT NULL,
  `create_time` datetime NOT NULL,
  `system_mtime` datetime NOT NULL,
  `user_mtime` datetime NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `group_uniq` (`repo_id`,`group_code_norm`),
  KEY `group_system_mtime_index` (`system_mtime`),
  KEY `group_user_mtime_index` (`user_mtime`),
  CONSTRAINT `group_repo_id_fk` FOREIGN KEY (`repo_id`) REFERENCES `repository` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `group`
--

LOCK TABLES `group` WRITE;
/*!40000 ALTER TABLE `group` DISABLE KEYS */;
/*!40000 ALTER TABLE `group` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `group_permission`
--

DROP TABLE IF EXISTS `group_permission`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `group_permission` (
  `id` int NOT NULL AUTO_INCREMENT,
  `permission_id` int NOT NULL,
  `group_id` int NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `group_permission_permission_id_group_id_index` (`permission_id`,`group_id`),
  KEY `group_permission_permission_id_index` (`permission_id`),
  KEY `group_permission_group_id_index` (`group_id`),
  CONSTRAINT `group_permission_group_id_fk` FOREIGN KEY (`group_id`) REFERENCES `group` (`id`) ON DELETE CASCADE,
  CONSTRAINT `group_permission_ibfk_1` FOREIGN KEY (`permission_id`) REFERENCES `permission` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `group_permission`
--

LOCK TABLES `group_permission` WRITE;
/*!40000 ALTER TABLE `group_permission` DISABLE KEYS */;
/*!40000 ALTER TABLE `group_permission` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `group_user`
--

DROP TABLE IF EXISTS `group_user`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `group_user` (
  `id` int NOT NULL AUTO_INCREMENT,
  `user_id` int NOT NULL,
  `group_id` int NOT NULL,
  PRIMARY KEY (`id`),
  KEY `group_user_group_id_index` (`group_id`),
  KEY `group_user_user_id_index` (`user_id`),
  CONSTRAINT `group_user_group_id_fk` FOREIGN KEY (`group_id`) REFERENCES `group` (`id`) ON DELETE CASCADE,
  CONSTRAINT `group_user_user_id_fk` FOREIGN KEY (`user_id`) REFERENCES `user` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `group_user`
--

LOCK TABLES `group_user` WRITE;
/*!40000 ALTER TABLE `group_user` DISABLE KEYS */;
/*!40000 ALTER TABLE `group_user` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `instance`
--

DROP TABLE IF EXISTS `instance`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `instance` (
  `id` int NOT NULL AUTO_INCREMENT,
  `lock_version` int NOT NULL DEFAULT '0',
  `json_schema_version` int NOT NULL,
  `resource_id` int DEFAULT NULL,
  `archival_object_id` int DEFAULT NULL,
  `accession_id` int DEFAULT NULL,
  `instance_type_id` int NOT NULL,
  `created_by` varchar(255) DEFAULT NULL,
  `last_modified_by` varchar(255) DEFAULT NULL,
  `create_time` datetime NOT NULL,
  `system_mtime` datetime NOT NULL,
  `user_mtime` datetime NOT NULL,
  `is_representative` int DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `resource_one_representative_instance` (`is_representative`,`resource_id`),
  UNIQUE KEY `component_one_representative_instance` (`is_representative`,`archival_object_id`),
  KEY `instance_type_id` (`instance_type_id`),
  KEY `instance_system_mtime_index` (`system_mtime`),
  KEY `instance_user_mtime_index` (`user_mtime`),
  KEY `resource_id` (`resource_id`),
  KEY `archival_object_id` (`archival_object_id`),
  KEY `accession_id` (`accession_id`),
  CONSTRAINT `instance_ibfk_1` FOREIGN KEY (`instance_type_id`) REFERENCES `enumeration_value` (`id`),
  CONSTRAINT `instance_ibfk_2` FOREIGN KEY (`resource_id`) REFERENCES `resource` (`id`),
  CONSTRAINT `instance_ibfk_3` FOREIGN KEY (`archival_object_id`) REFERENCES `archival_object` (`id`),
  CONSTRAINT `instance_ibfk_4` FOREIGN KEY (`accession_id`) REFERENCES `accession` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `instance`
--

LOCK TABLES `instance` WRITE;
/*!40000 ALTER TABLE `instance` DISABLE KEYS */;
/*!40000 ALTER TABLE `instance` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `instance_do_link_rlshp`
--

DROP TABLE IF EXISTS `instance_do_link_rlshp`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `instance_do_link_rlshp` (
  `id` int NOT NULL AUTO_INCREMENT,
  `digital_object_id` int DEFAULT NULL,
  `instance_id` int DEFAULT NULL,
  `aspace_relationship_position` int DEFAULT NULL,
  `created_by` varchar(255) DEFAULT NULL,
  `last_modified_by` varchar(255) DEFAULT NULL,
  `system_mtime` datetime NOT NULL,
  `user_mtime` datetime NOT NULL,
  `suppressed` int NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`),
  KEY `instance_do_link_rlshp_system_mtime_index` (`system_mtime`),
  KEY `instance_do_link_rlshp_user_mtime_index` (`user_mtime`),
  KEY `digital_object_id` (`digital_object_id`),
  KEY `instance_id` (`instance_id`),
  CONSTRAINT `instance_do_link_rlshp_ibfk_1` FOREIGN KEY (`digital_object_id`) REFERENCES `digital_object` (`id`),
  CONSTRAINT `instance_do_link_rlshp_ibfk_2` FOREIGN KEY (`instance_id`) REFERENCES `instance` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `instance_do_link_rlshp`
--

LOCK TABLES `instance_do_link_rlshp` WRITE;
/*!40000 ALTER TABLE `instance_do_link_rlshp` DISABLE KEYS */;
/*!40000 ALTER TABLE `instance_do_link_rlshp` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `job`
--

DROP TABLE IF EXISTS `job`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `job` (
  `id` int NOT NULL AUTO_INCREMENT,
  `repo_id` int NOT NULL,
  `lock_version` int NOT NULL DEFAULT '0',
  `json_schema_version` int NOT NULL,
  `job_blob` mediumblob NOT NULL,
  `time_submitted` datetime NOT NULL,
  `time_started` datetime DEFAULT NULL,
  `time_finished` datetime DEFAULT NULL,
  `owner_id` int NOT NULL,
  `status` varchar(255) NOT NULL,
  `created_by` varchar(255) DEFAULT NULL,
  `last_modified_by` varchar(255) DEFAULT NULL,
  `create_time` datetime NOT NULL,
  `system_mtime` datetime NOT NULL,
  `user_mtime` datetime NOT NULL,
  `job_params` varchar(255) DEFAULT NULL,
  `job_type` varchar(255) NOT NULL DEFAULT 'unknown_job_type',
  PRIMARY KEY (`id`),
  KEY `job_system_mtime_index` (`system_mtime`),
  KEY `job_user_mtime_index` (`user_mtime`),
  KEY `job_status_idx` (`status`),
  KEY `job_repo_id_fk` (`repo_id`),
  KEY `job_owner_id_fk` (`owner_id`),
  CONSTRAINT `job_owner_id_fk` FOREIGN KEY (`owner_id`) REFERENCES `user` (`id`) ON DELETE CASCADE,
  CONSTRAINT `job_repo_id_fk` FOREIGN KEY (`repo_id`) REFERENCES `repository` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `job`
--

LOCK TABLES `job` WRITE;
/*!40000 ALTER TABLE `job` DISABLE KEYS */;
/*!40000 ALTER TABLE `job` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `job_created_record`
--

DROP TABLE IF EXISTS `job_created_record`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `job_created_record` (
  `id` int NOT NULL AUTO_INCREMENT,
  `job_id` int NOT NULL,
  `record_uri` varchar(255) NOT NULL,
  `created_by` varchar(255) DEFAULT NULL,
  `last_modified_by` varchar(255) DEFAULT NULL,
  `create_time` datetime NOT NULL,
  `system_mtime` datetime NOT NULL,
  `user_mtime` datetime NOT NULL,
  PRIMARY KEY (`id`),
  KEY `job_created_record_system_mtime_index` (`system_mtime`),
  KEY `job_created_record_user_mtime_index` (`user_mtime`),
  KEY `job_created_record_job_id_fk` (`job_id`),
  CONSTRAINT `job_created_record_job_id_fk` FOREIGN KEY (`job_id`) REFERENCES `job` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `job_created_record`
--

LOCK TABLES `job_created_record` WRITE;
/*!40000 ALTER TABLE `job_created_record` DISABLE KEYS */;
/*!40000 ALTER TABLE `job_created_record` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `job_input_file`
--

DROP TABLE IF EXISTS `job_input_file`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `job_input_file` (
  `id` int NOT NULL AUTO_INCREMENT,
  `job_id` int NOT NULL,
  `file_path` varchar(255) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `job_input_file_job_id_fk` (`job_id`),
  CONSTRAINT `job_input_file_job_id_fk` FOREIGN KEY (`job_id`) REFERENCES `job` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `job_input_file`
--

LOCK TABLES `job_input_file` WRITE;
/*!40000 ALTER TABLE `job_input_file` DISABLE KEYS */;
/*!40000 ALTER TABLE `job_input_file` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `job_modified_record`
--

DROP TABLE IF EXISTS `job_modified_record`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `job_modified_record` (
  `id` int NOT NULL AUTO_INCREMENT,
  `job_id` int NOT NULL,
  `record_uri` varchar(255) NOT NULL,
  `created_by` varchar(255) DEFAULT NULL,
  `last_modified_by` varchar(255) DEFAULT NULL,
  `create_time` datetime NOT NULL,
  `system_mtime` datetime NOT NULL,
  `user_mtime` datetime NOT NULL,
  PRIMARY KEY (`id`),
  KEY `job_modified_record_system_mtime_index` (`system_mtime`),
  KEY `job_modified_record_user_mtime_index` (`user_mtime`),
  KEY `job_modified_record_job_id_fk` (`job_id`),
  CONSTRAINT `job_modified_record_job_id_fk` FOREIGN KEY (`job_id`) REFERENCES `job` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `job_modified_record`
--

LOCK TABLES `job_modified_record` WRITE;
/*!40000 ALTER TABLE `job_modified_record` DISABLE KEYS */;
/*!40000 ALTER TABLE `job_modified_record` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `lang_material`
--

DROP TABLE IF EXISTS `lang_material`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `lang_material` (
  `id` int NOT NULL AUTO_INCREMENT,
  `lock_version` int NOT NULL DEFAULT '0',
  `json_schema_version` int NOT NULL,
  `archival_object_id` int DEFAULT NULL,
  `resource_id` int DEFAULT NULL,
  `digital_object_id` int DEFAULT NULL,
  `digital_object_component_id` int DEFAULT NULL,
  `created_by` varchar(255) DEFAULT NULL,
  `last_modified_by` varchar(255) DEFAULT NULL,
  `create_time` datetime NOT NULL,
  `system_mtime` datetime NOT NULL,
  `user_mtime` datetime NOT NULL,
  `accession_id` int DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `lang_material_system_mtime_index` (`system_mtime`),
  KEY `lang_material_user_mtime_index` (`user_mtime`),
  KEY `archival_object_id` (`archival_object_id`),
  KEY `resource_id` (`resource_id`),
  KEY `digital_object_id` (`digital_object_id`),
  KEY `digital_object_component_id` (`digital_object_component_id`),
  KEY `accession_id` (`accession_id`),
  CONSTRAINT `lang_material_ibfk_1` FOREIGN KEY (`archival_object_id`) REFERENCES `archival_object` (`id`),
  CONSTRAINT `lang_material_ibfk_2` FOREIGN KEY (`resource_id`) REFERENCES `resource` (`id`),
  CONSTRAINT `lang_material_ibfk_3` FOREIGN KEY (`digital_object_id`) REFERENCES `digital_object` (`id`),
  CONSTRAINT `lang_material_ibfk_4` FOREIGN KEY (`digital_object_component_id`) REFERENCES `digital_object_component` (`id`),
  CONSTRAINT `lang_material_ibfk_5` FOREIGN KEY (`accession_id`) REFERENCES `accession` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `lang_material`
--

LOCK TABLES `lang_material` WRITE;
/*!40000 ALTER TABLE `lang_material` DISABLE KEYS */;
/*!40000 ALTER TABLE `lang_material` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `language_and_script`
--

DROP TABLE IF EXISTS `language_and_script`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `language_and_script` (
  `id` int NOT NULL AUTO_INCREMENT,
  `lock_version` int NOT NULL DEFAULT '0',
  `json_schema_version` int NOT NULL,
  `lang_material_id` int DEFAULT NULL,
  `language_id` int DEFAULT NULL,
  `script_id` int DEFAULT NULL,
  `created_by` varchar(255) DEFAULT NULL,
  `last_modified_by` varchar(255) DEFAULT NULL,
  `create_time` datetime NOT NULL,
  `system_mtime` datetime NOT NULL,
  `user_mtime` datetime NOT NULL,
  PRIMARY KEY (`id`),
  KEY `language_id` (`language_id`),
  KEY `script_id` (`script_id`),
  KEY `language_and_script_system_mtime_index` (`system_mtime`),
  KEY `language_and_script_user_mtime_index` (`user_mtime`),
  KEY `lang_material_id` (`lang_material_id`),
  CONSTRAINT `language_and_script_ibfk_1` FOREIGN KEY (`language_id`) REFERENCES `enumeration_value` (`id`),
  CONSTRAINT `language_and_script_ibfk_2` FOREIGN KEY (`script_id`) REFERENCES `enumeration_value` (`id`),
  CONSTRAINT `language_and_script_ibfk_3` FOREIGN KEY (`lang_material_id`) REFERENCES `lang_material` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `language_and_script`
--

LOCK TABLES `language_and_script` WRITE;
/*!40000 ALTER TABLE `language_and_script` DISABLE KEYS */;
/*!40000 ALTER TABLE `language_and_script` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `linked_agent_term`
--

DROP TABLE IF EXISTS `linked_agent_term`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `linked_agent_term` (
  `id` int NOT NULL AUTO_INCREMENT,
  `linked_agents_rlshp_id` int NOT NULL,
  `term_id` int NOT NULL,
  PRIMARY KEY (`id`),
  KEY `term_id` (`term_id`),
  KEY `linked_agent_term_idx` (`linked_agents_rlshp_id`,`term_id`),
  CONSTRAINT `linked_agent_term_ibfk_1` FOREIGN KEY (`linked_agents_rlshp_id`) REFERENCES `linked_agents_rlshp` (`id`),
  CONSTRAINT `linked_agent_term_ibfk_2` FOREIGN KEY (`term_id`) REFERENCES `term` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `linked_agent_term`
--

LOCK TABLES `linked_agent_term` WRITE;
/*!40000 ALTER TABLE `linked_agent_term` DISABLE KEYS */;
/*!40000 ALTER TABLE `linked_agent_term` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `linked_agents_rlshp`
--

DROP TABLE IF EXISTS `linked_agents_rlshp`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `linked_agents_rlshp` (
  `id` int NOT NULL AUTO_INCREMENT,
  `agent_person_id` int DEFAULT NULL,
  `agent_software_id` int DEFAULT NULL,
  `agent_family_id` int DEFAULT NULL,
  `agent_corporate_entity_id` int DEFAULT NULL,
  `accession_id` int DEFAULT NULL,
  `archival_object_id` int DEFAULT NULL,
  `digital_object_id` int DEFAULT NULL,
  `digital_object_component_id` int DEFAULT NULL,
  `event_id` int DEFAULT NULL,
  `resource_id` int DEFAULT NULL,
  `aspace_relationship_position` int DEFAULT NULL,
  `created_by` varchar(255) DEFAULT NULL,
  `last_modified_by` varchar(255) DEFAULT NULL,
  `create_time` datetime NOT NULL,
  `system_mtime` datetime NOT NULL,
  `user_mtime` datetime NOT NULL,
  `role_id` int DEFAULT NULL,
  `relator_id` int DEFAULT NULL,
  `title` varchar(8704) DEFAULT NULL,
  `suppressed` int NOT NULL DEFAULT '0',
  `rights_statement_id` int DEFAULT NULL,
  `is_primary` int DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `role_id` (`role_id`),
  KEY `relator_id` (`relator_id`),
  KEY `linked_agents_rlshp_system_mtime_index` (`system_mtime`),
  KEY `linked_agents_rlshp_user_mtime_index` (`user_mtime`),
  KEY `agent_person_id` (`agent_person_id`),
  KEY `agent_software_id` (`agent_software_id`),
  KEY `agent_family_id` (`agent_family_id`),
  KEY `agent_corporate_entity_id` (`agent_corporate_entity_id`),
  KEY `accession_id` (`accession_id`),
  KEY `archival_object_id` (`archival_object_id`),
  KEY `digital_object_id` (`digital_object_id`),
  KEY `digital_object_component_id` (`digital_object_component_id`),
  KEY `event_id` (`event_id`),
  KEY `resource_id` (`resource_id`),
  KEY `rights_statement_id` (`rights_statement_id`),
  CONSTRAINT `linked_agents_rlshp_ibfk_1` FOREIGN KEY (`role_id`) REFERENCES `enumeration_value` (`id`),
  CONSTRAINT `linked_agents_rlshp_ibfk_10` FOREIGN KEY (`digital_object_component_id`) REFERENCES `digital_object_component` (`id`),
  CONSTRAINT `linked_agents_rlshp_ibfk_11` FOREIGN KEY (`event_id`) REFERENCES `event` (`id`),
  CONSTRAINT `linked_agents_rlshp_ibfk_12` FOREIGN KEY (`resource_id`) REFERENCES `resource` (`id`),
  CONSTRAINT `linked_agents_rlshp_ibfk_13` FOREIGN KEY (`rights_statement_id`) REFERENCES `rights_statement` (`id`),
  CONSTRAINT `linked_agents_rlshp_ibfk_2` FOREIGN KEY (`relator_id`) REFERENCES `enumeration_value` (`id`),
  CONSTRAINT `linked_agents_rlshp_ibfk_3` FOREIGN KEY (`agent_person_id`) REFERENCES `agent_person` (`id`),
  CONSTRAINT `linked_agents_rlshp_ibfk_4` FOREIGN KEY (`agent_software_id`) REFERENCES `agent_software` (`id`),
  CONSTRAINT `linked_agents_rlshp_ibfk_5` FOREIGN KEY (`agent_family_id`) REFERENCES `agent_family` (`id`),
  CONSTRAINT `linked_agents_rlshp_ibfk_6` FOREIGN KEY (`agent_corporate_entity_id`) REFERENCES `agent_corporate_entity` (`id`),
  CONSTRAINT `linked_agents_rlshp_ibfk_7` FOREIGN KEY (`accession_id`) REFERENCES `accession` (`id`),
  CONSTRAINT `linked_agents_rlshp_ibfk_8` FOREIGN KEY (`archival_object_id`) REFERENCES `archival_object` (`id`),
  CONSTRAINT `linked_agents_rlshp_ibfk_9` FOREIGN KEY (`digital_object_id`) REFERENCES `digital_object` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `linked_agents_rlshp`
--

LOCK TABLES `linked_agents_rlshp` WRITE;
/*!40000 ALTER TABLE `linked_agents_rlshp` DISABLE KEYS */;
/*!40000 ALTER TABLE `linked_agents_rlshp` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `location`
--

DROP TABLE IF EXISTS `location`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `location` (
  `id` int NOT NULL AUTO_INCREMENT,
  `lock_version` int NOT NULL DEFAULT '0',
  `json_schema_version` int NOT NULL,
  `building` varchar(255) NOT NULL,
  `title` varchar(8704) DEFAULT NULL,
  `floor` varchar(255) DEFAULT NULL,
  `room` varchar(255) DEFAULT NULL,
  `area` varchar(255) DEFAULT NULL,
  `barcode` varchar(255) DEFAULT NULL,
  `classification` varchar(255) DEFAULT NULL,
  `coordinate_1_label` varchar(255) DEFAULT NULL,
  `coordinate_1_indicator` varchar(255) DEFAULT NULL,
  `coordinate_2_label` varchar(255) DEFAULT NULL,
  `coordinate_2_indicator` varchar(255) DEFAULT NULL,
  `coordinate_3_label` varchar(255) DEFAULT NULL,
  `coordinate_3_indicator` varchar(255) DEFAULT NULL,
  `temporary_id` int DEFAULT NULL,
  `created_by` varchar(255) DEFAULT NULL,
  `last_modified_by` varchar(255) DEFAULT NULL,
  `create_time` datetime NOT NULL,
  `system_mtime` datetime NOT NULL,
  `user_mtime` datetime NOT NULL,
  PRIMARY KEY (`id`),
  KEY `temporary_id` (`temporary_id`),
  KEY `location_system_mtime_index` (`system_mtime`),
  KEY `location_user_mtime_index` (`user_mtime`),
  CONSTRAINT `location_ibfk_1` FOREIGN KEY (`temporary_id`) REFERENCES `enumeration_value` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `location`
--

LOCK TABLES `location` WRITE;
/*!40000 ALTER TABLE `location` DISABLE KEYS */;
/*!40000 ALTER TABLE `location` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `location_function`
--

DROP TABLE IF EXISTS `location_function`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `location_function` (
  `id` int NOT NULL AUTO_INCREMENT,
  `lock_version` int NOT NULL DEFAULT '0',
  `json_schema_version` int NOT NULL,
  `location_id` int DEFAULT NULL,
  `location_function_type_id` int NOT NULL,
  `created_by` varchar(255) DEFAULT NULL,
  `last_modified_by` varchar(255) DEFAULT NULL,
  `create_time` datetime NOT NULL,
  `system_mtime` datetime NOT NULL,
  `user_mtime` datetime NOT NULL,
  PRIMARY KEY (`id`),
  KEY `location_function_type_id` (`location_function_type_id`),
  KEY `location_function_system_mtime_index` (`system_mtime`),
  KEY `location_function_user_mtime_index` (`user_mtime`),
  KEY `location_id` (`location_id`),
  CONSTRAINT `location_function_ibfk_1` FOREIGN KEY (`location_function_type_id`) REFERENCES `enumeration_value` (`id`),
  CONSTRAINT `location_function_ibfk_2` FOREIGN KEY (`location_id`) REFERENCES `location` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `location_function`
--

LOCK TABLES `location_function` WRITE;
/*!40000 ALTER TABLE `location_function` DISABLE KEYS */;
/*!40000 ALTER TABLE `location_function` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `location_profile`
--

DROP TABLE IF EXISTS `location_profile`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `location_profile` (
  `id` int NOT NULL AUTO_INCREMENT,
  `lock_version` int NOT NULL DEFAULT '0',
  `json_schema_version` int NOT NULL,
  `name` varchar(255) DEFAULT NULL,
  `dimension_units_id` int DEFAULT NULL,
  `height` varchar(255) DEFAULT NULL,
  `width` varchar(255) DEFAULT NULL,
  `depth` varchar(255) DEFAULT NULL,
  `created_by` varchar(255) DEFAULT NULL,
  `last_modified_by` varchar(255) DEFAULT NULL,
  `create_time` datetime NOT NULL,
  `system_mtime` datetime NOT NULL,
  `user_mtime` datetime NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `location_profile_name_uniq` (`name`),
  KEY `dimension_units_id` (`dimension_units_id`),
  KEY `location_profile_system_mtime_index` (`system_mtime`),
  KEY `location_profile_user_mtime_index` (`user_mtime`),
  CONSTRAINT `location_profile_ibfk_1` FOREIGN KEY (`dimension_units_id`) REFERENCES `enumeration_value` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `location_profile`
--

LOCK TABLES `location_profile` WRITE;
/*!40000 ALTER TABLE `location_profile` DISABLE KEYS */;
/*!40000 ALTER TABLE `location_profile` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `location_profile_rlshp`
--

DROP TABLE IF EXISTS `location_profile_rlshp`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `location_profile_rlshp` (
  `id` int NOT NULL AUTO_INCREMENT,
  `location_id` int DEFAULT NULL,
  `location_profile_id` int DEFAULT NULL,
  `aspace_relationship_position` int DEFAULT NULL,
  `suppressed` int NOT NULL DEFAULT '0',
  `created_by` varchar(255) DEFAULT NULL,
  `last_modified_by` varchar(255) DEFAULT NULL,
  `system_mtime` datetime NOT NULL,
  `user_mtime` datetime NOT NULL,
  PRIMARY KEY (`id`),
  KEY `location_profile_rlshp_system_mtime_index` (`system_mtime`),
  KEY `location_profile_rlshp_user_mtime_index` (`user_mtime`),
  KEY `location_id` (`location_id`),
  KEY `location_profile_id` (`location_profile_id`),
  CONSTRAINT `location_profile_rlshp_ibfk_1` FOREIGN KEY (`location_id`) REFERENCES `location` (`id`),
  CONSTRAINT `location_profile_rlshp_ibfk_2` FOREIGN KEY (`location_profile_id`) REFERENCES `location_profile` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `location_profile_rlshp`
--

LOCK TABLES `location_profile_rlshp` WRITE;
/*!40000 ALTER TABLE `location_profile_rlshp` DISABLE KEYS */;
/*!40000 ALTER TABLE `location_profile_rlshp` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `metadata_rights_declaration`
--

DROP TABLE IF EXISTS `metadata_rights_declaration`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `metadata_rights_declaration` (
  `id` int NOT NULL AUTO_INCREMENT,
  `accession_id` int DEFAULT NULL,
  `resource_id` int DEFAULT NULL,
  `digital_object_id` int DEFAULT NULL,
  `agent_person_id` int DEFAULT NULL,
  `agent_family_id` int DEFAULT NULL,
  `agent_corporate_entity_id` int DEFAULT NULL,
  `agent_software_id` int DEFAULT NULL,
  `subject_id` int DEFAULT NULL,
  `license_id` int DEFAULT NULL,
  `file_version_xlink_actuate_attribute_id` int DEFAULT NULL,
  `file_version_xlink_show_attribute_id` int DEFAULT NULL,
  `citation` varchar(255) DEFAULT NULL,
  `descriptive_note` text NOT NULL,
  `file_uri` varchar(255) DEFAULT NULL,
  `xlink_title_attribute` varchar(255) DEFAULT NULL,
  `xlink_role_attribute` varchar(255) DEFAULT NULL,
  `xlink_arcrole_attribute` varchar(255) DEFAULT NULL,
  `last_verified_date` datetime DEFAULT NULL,
  `created_by` varchar(255) DEFAULT NULL,
  `last_modified_by` varchar(255) DEFAULT NULL,
  `create_time` datetime NOT NULL,
  `system_mtime` datetime NOT NULL,
  `user_mtime` datetime NOT NULL,
  `lock_version` int NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`),
  KEY `metadata_rights_declaration_system_mtime_index` (`system_mtime`),
  KEY `metadata_rights_declaration_user_mtime_index` (`user_mtime`),
  KEY `accession_id` (`accession_id`),
  KEY `resource_id` (`resource_id`),
  KEY `digital_object_id` (`digital_object_id`),
  KEY `agent_person_id` (`agent_person_id`),
  KEY `agent_family_id` (`agent_family_id`),
  KEY `agent_corporate_entity_id` (`agent_corporate_entity_id`),
  KEY `agent_software_id` (`agent_software_id`),
  KEY `subject_id` (`subject_id`),
  CONSTRAINT `metadata_rights_declaration_ibfk_1` FOREIGN KEY (`accession_id`) REFERENCES `accession` (`id`),
  CONSTRAINT `metadata_rights_declaration_ibfk_2` FOREIGN KEY (`resource_id`) REFERENCES `resource` (`id`),
  CONSTRAINT `metadata_rights_declaration_ibfk_3` FOREIGN KEY (`digital_object_id`) REFERENCES `digital_object` (`id`),
  CONSTRAINT `metadata_rights_declaration_ibfk_4` FOREIGN KEY (`agent_person_id`) REFERENCES `agent_person` (`id`),
  CONSTRAINT `metadata_rights_declaration_ibfk_5` FOREIGN KEY (`agent_family_id`) REFERENCES `agent_family` (`id`),
  CONSTRAINT `metadata_rights_declaration_ibfk_6` FOREIGN KEY (`agent_corporate_entity_id`) REFERENCES `agent_corporate_entity` (`id`),
  CONSTRAINT `metadata_rights_declaration_ibfk_7` FOREIGN KEY (`agent_software_id`) REFERENCES `agent_software` (`id`),
  CONSTRAINT `metadata_rights_declaration_ibfk_8` FOREIGN KEY (`subject_id`) REFERENCES `subject` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `metadata_rights_declaration`
--

LOCK TABLES `metadata_rights_declaration` WRITE;
/*!40000 ALTER TABLE `metadata_rights_declaration` DISABLE KEYS */;
/*!40000 ALTER TABLE `metadata_rights_declaration` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `name_authority_id`
--

DROP TABLE IF EXISTS `name_authority_id`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `name_authority_id` (
  `id` int NOT NULL AUTO_INCREMENT,
  `lock_version` int NOT NULL DEFAULT '0',
  `name_person_id` int DEFAULT NULL,
  `name_family_id` int DEFAULT NULL,
  `name_software_id` int DEFAULT NULL,
  `name_corporate_entity_id` int DEFAULT NULL,
  `authority_id` varchar(255) NOT NULL,
  `created_by` varchar(255) DEFAULT NULL,
  `last_modified_by` varchar(255) DEFAULT NULL,
  `create_time` datetime NOT NULL,
  `system_mtime` datetime NOT NULL,
  `user_mtime` datetime NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `authority_id` (`authority_id`),
  KEY `name_authority_id_system_mtime_index` (`system_mtime`),
  KEY `name_authority_id_user_mtime_index` (`user_mtime`),
  KEY `name_person_id` (`name_person_id`),
  KEY `name_family_id` (`name_family_id`),
  KEY `name_software_id` (`name_software_id`),
  KEY `name_corporate_entity_id` (`name_corporate_entity_id`),
  CONSTRAINT `name_authority_id_ibfk_1` FOREIGN KEY (`name_person_id`) REFERENCES `name_person` (`id`),
  CONSTRAINT `name_authority_id_ibfk_2` FOREIGN KEY (`name_family_id`) REFERENCES `name_family` (`id`),
  CONSTRAINT `name_authority_id_ibfk_3` FOREIGN KEY (`name_software_id`) REFERENCES `name_software` (`id`),
  CONSTRAINT `name_authority_id_ibfk_4` FOREIGN KEY (`name_corporate_entity_id`) REFERENCES `name_corporate_entity` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `name_authority_id`
--

LOCK TABLES `name_authority_id` WRITE;
/*!40000 ALTER TABLE `name_authority_id` DISABLE KEYS */;
/*!40000 ALTER TABLE `name_authority_id` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `name_corporate_entity`
--

DROP TABLE IF EXISTS `name_corporate_entity`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `name_corporate_entity` (
  `id` int NOT NULL AUTO_INCREMENT,
  `lock_version` int NOT NULL DEFAULT '0',
  `json_schema_version` int NOT NULL,
  `agent_corporate_entity_id` int NOT NULL,
  `primary_name` text NOT NULL,
  `subordinate_name_1` text,
  `subordinate_name_2` text,
  `number` varchar(255) DEFAULT NULL,
  `dates` varchar(255) DEFAULT NULL,
  `qualifier` text,
  `source_id` int DEFAULT NULL,
  `rules_id` int DEFAULT NULL,
  `sort_name` text NOT NULL,
  `sort_name_auto_generate` int DEFAULT NULL,
  `created_by` varchar(255) DEFAULT NULL,
  `last_modified_by` varchar(255) DEFAULT NULL,
  `create_time` datetime NOT NULL,
  `system_mtime` datetime NOT NULL,
  `user_mtime` datetime NOT NULL,
  `authorized` int DEFAULT NULL,
  `is_display_name` int DEFAULT NULL,
  `location` varchar(255) DEFAULT NULL,
  `jurisdiction` int DEFAULT '0',
  `conference_meeting` int DEFAULT '0',
  `language_id` int DEFAULT NULL,
  `script_id` int DEFAULT NULL,
  `transliteration_id` int DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `corporate_entity_one_authorized` (`authorized`,`agent_corporate_entity_id`),
  UNIQUE KEY `corporate_entity_one_display_name` (`is_display_name`,`agent_corporate_entity_id`),
  KEY `source_id` (`source_id`),
  KEY `rules_id` (`rules_id`),
  KEY `name_corporate_entity_system_mtime_index` (`system_mtime`),
  KEY `name_corporate_entity_user_mtime_index` (`user_mtime`),
  KEY `agent_corporate_entity_id` (`agent_corporate_entity_id`),
  CONSTRAINT `name_corporate_entity_ibfk_1` FOREIGN KEY (`source_id`) REFERENCES `enumeration_value` (`id`),
  CONSTRAINT `name_corporate_entity_ibfk_2` FOREIGN KEY (`rules_id`) REFERENCES `enumeration_value` (`id`),
  CONSTRAINT `name_corporate_entity_ibfk_3` FOREIGN KEY (`agent_corporate_entity_id`) REFERENCES `agent_corporate_entity` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `name_corporate_entity`
--

LOCK TABLES `name_corporate_entity` WRITE;
/*!40000 ALTER TABLE `name_corporate_entity` DISABLE KEYS */;
/*!40000 ALTER TABLE `name_corporate_entity` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `name_family`
--

DROP TABLE IF EXISTS `name_family`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `name_family` (
  `id` int NOT NULL AUTO_INCREMENT,
  `lock_version` int NOT NULL DEFAULT '0',
  `json_schema_version` int NOT NULL,
  `agent_family_id` int NOT NULL,
  `family_name` text NOT NULL,
  `prefix` text,
  `dates` varchar(255) DEFAULT NULL,
  `qualifier` text,
  `source_id` int DEFAULT NULL,
  `rules_id` int DEFAULT NULL,
  `sort_name` text NOT NULL,
  `sort_name_auto_generate` int DEFAULT NULL,
  `created_by` varchar(255) DEFAULT NULL,
  `last_modified_by` varchar(255) DEFAULT NULL,
  `create_time` datetime NOT NULL,
  `system_mtime` datetime NOT NULL,
  `user_mtime` datetime NOT NULL,
  `authorized` int DEFAULT NULL,
  `is_display_name` int DEFAULT NULL,
  `family_type` varchar(255) DEFAULT NULL,
  `location` varchar(255) DEFAULT NULL,
  `language_id` int DEFAULT NULL,
  `script_id` int DEFAULT NULL,
  `transliteration_id` int DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `family_one_authorized` (`authorized`,`agent_family_id`),
  UNIQUE KEY `family_one_display_name` (`is_display_name`,`agent_family_id`),
  KEY `source_id` (`source_id`),
  KEY `rules_id` (`rules_id`),
  KEY `name_family_system_mtime_index` (`system_mtime`),
  KEY `name_family_user_mtime_index` (`user_mtime`),
  KEY `agent_family_id` (`agent_family_id`),
  CONSTRAINT `name_family_ibfk_1` FOREIGN KEY (`source_id`) REFERENCES `enumeration_value` (`id`),
  CONSTRAINT `name_family_ibfk_2` FOREIGN KEY (`rules_id`) REFERENCES `enumeration_value` (`id`),
  CONSTRAINT `name_family_ibfk_3` FOREIGN KEY (`agent_family_id`) REFERENCES `agent_family` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `name_family`
--

LOCK TABLES `name_family` WRITE;
/*!40000 ALTER TABLE `name_family` DISABLE KEYS */;
/*!40000 ALTER TABLE `name_family` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `name_person`
--

DROP TABLE IF EXISTS `name_person`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `name_person` (
  `id` int NOT NULL AUTO_INCREMENT,
  `lock_version` int NOT NULL DEFAULT '0',
  `json_schema_version` int NOT NULL,
  `agent_person_id` int NOT NULL,
  `primary_name` varchar(255) NOT NULL,
  `name_order_id` int NOT NULL,
  `title` varchar(8704) DEFAULT NULL,
  `prefix` text,
  `rest_of_name` text,
  `suffix` text,
  `fuller_form` text,
  `number` varchar(255) DEFAULT NULL,
  `dates` varchar(255) DEFAULT NULL,
  `qualifier` text,
  `source_id` int DEFAULT NULL,
  `rules_id` int DEFAULT NULL,
  `sort_name` text NOT NULL,
  `sort_name_auto_generate` int DEFAULT NULL,
  `created_by` varchar(255) DEFAULT NULL,
  `last_modified_by` varchar(255) DEFAULT NULL,
  `create_time` datetime NOT NULL,
  `system_mtime` datetime NOT NULL,
  `user_mtime` datetime NOT NULL,
  `authorized` int DEFAULT NULL,
  `is_display_name` int DEFAULT NULL,
  `language_id` int DEFAULT NULL,
  `script_id` int DEFAULT NULL,
  `transliteration_id` int DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `person_one_authorized` (`authorized`,`agent_person_id`),
  UNIQUE KEY `person_one_display_name` (`is_display_name`,`agent_person_id`),
  KEY `name_order_id` (`name_order_id`),
  KEY `source_id` (`source_id`),
  KEY `rules_id` (`rules_id`),
  KEY `name_person_system_mtime_index` (`system_mtime`),
  KEY `name_person_user_mtime_index` (`user_mtime`),
  KEY `agent_person_id` (`agent_person_id`),
  CONSTRAINT `name_person_ibfk_1` FOREIGN KEY (`name_order_id`) REFERENCES `enumeration_value` (`id`),
  CONSTRAINT `name_person_ibfk_2` FOREIGN KEY (`source_id`) REFERENCES `enumeration_value` (`id`),
  CONSTRAINT `name_person_ibfk_3` FOREIGN KEY (`rules_id`) REFERENCES `enumeration_value` (`id`),
  CONSTRAINT `name_person_ibfk_4` FOREIGN KEY (`agent_person_id`) REFERENCES `agent_person` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `name_person`
--

LOCK TABLES `name_person` WRITE;
/*!40000 ALTER TABLE `name_person` DISABLE KEYS */;
/*!40000 ALTER TABLE `name_person` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `name_software`
--

DROP TABLE IF EXISTS `name_software`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `name_software` (
  `id` int NOT NULL AUTO_INCREMENT,
  `lock_version` int NOT NULL DEFAULT '0',
  `json_schema_version` int NOT NULL,
  `agent_software_id` int NOT NULL,
  `software_name` text NOT NULL,
  `version` text,
  `manufacturer` text,
  `dates` varchar(255) DEFAULT NULL,
  `qualifier` text,
  `source_id` int DEFAULT NULL,
  `rules_id` int DEFAULT NULL,
  `sort_name` text NOT NULL,
  `sort_name_auto_generate` int DEFAULT NULL,
  `created_by` varchar(255) DEFAULT NULL,
  `last_modified_by` varchar(255) DEFAULT NULL,
  `create_time` datetime NOT NULL,
  `system_mtime` datetime NOT NULL,
  `user_mtime` datetime NOT NULL,
  `authorized` int DEFAULT NULL,
  `is_display_name` int DEFAULT NULL,
  `language_id` int DEFAULT NULL,
  `script_id` int DEFAULT NULL,
  `transliteration_id` int DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `software_one_authorized` (`authorized`,`agent_software_id`),
  UNIQUE KEY `software_one_display_name` (`is_display_name`,`agent_software_id`),
  KEY `source_id` (`source_id`),
  KEY `rules_id` (`rules_id`),
  KEY `name_software_system_mtime_index` (`system_mtime`),
  KEY `name_software_user_mtime_index` (`user_mtime`),
  KEY `agent_software_id` (`agent_software_id`),
  CONSTRAINT `name_software_ibfk_1` FOREIGN KEY (`source_id`) REFERENCES `enumeration_value` (`id`),
  CONSTRAINT `name_software_ibfk_2` FOREIGN KEY (`rules_id`) REFERENCES `enumeration_value` (`id`),
  CONSTRAINT `name_software_ibfk_3` FOREIGN KEY (`agent_software_id`) REFERENCES `agent_software` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `name_software`
--

LOCK TABLES `name_software` WRITE;
/*!40000 ALTER TABLE `name_software` DISABLE KEYS */;
/*!40000 ALTER TABLE `name_software` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `note`
--

DROP TABLE IF EXISTS `note`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `note` (
  `id` int NOT NULL AUTO_INCREMENT,
  `lock_version` int NOT NULL DEFAULT '1',
  `resource_id` int DEFAULT NULL,
  `archival_object_id` int DEFAULT NULL,
  `digital_object_id` int DEFAULT NULL,
  `digital_object_component_id` int DEFAULT NULL,
  `agent_person_id` int DEFAULT NULL,
  `agent_corporate_entity_id` int DEFAULT NULL,
  `agent_family_id` int DEFAULT NULL,
  `agent_software_id` int DEFAULT NULL,
  `publish` int DEFAULT NULL,
  `notes_json_schema_version` int NOT NULL,
  `notes` mediumblob NOT NULL,
  `created_by` varchar(255) DEFAULT NULL,
  `last_modified_by` varchar(255) DEFAULT NULL,
  `create_time` datetime NOT NULL,
  `system_mtime` datetime NOT NULL,
  `user_mtime` datetime NOT NULL,
  `rights_statement_act_id` int DEFAULT NULL,
  `rights_statement_id` int DEFAULT NULL,
  `lang_material_id` int DEFAULT NULL,
  `agent_topic_id` int DEFAULT NULL,
  `agent_place_id` int DEFAULT NULL,
  `agent_occupation_id` int DEFAULT NULL,
  `agent_function_id` int DEFAULT NULL,
  `agent_gender_id` int DEFAULT NULL,
  `used_language_id` int DEFAULT NULL,
  `agent_contact_id` int DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `note_system_mtime_index` (`system_mtime`),
  KEY `note_user_mtime_index` (`user_mtime`),
  KEY `resource_id` (`resource_id`),
  KEY `archival_object_id` (`archival_object_id`),
  KEY `digital_object_id` (`digital_object_id`),
  KEY `digital_object_component_id` (`digital_object_component_id`),
  KEY `agent_person_id` (`agent_person_id`),
  KEY `agent_corporate_entity_id` (`agent_corporate_entity_id`),
  KEY `agent_family_id` (`agent_family_id`),
  KEY `agent_software_id` (`agent_software_id`),
  KEY `rights_statement_act_id` (`rights_statement_act_id`),
  KEY `rights_statement_id` (`rights_statement_id`),
  KEY `lang_material_id` (`lang_material_id`),
  CONSTRAINT `note_ibfk_1` FOREIGN KEY (`resource_id`) REFERENCES `resource` (`id`),
  CONSTRAINT `note_ibfk_10` FOREIGN KEY (`rights_statement_id`) REFERENCES `rights_statement` (`id`),
  CONSTRAINT `note_ibfk_11` FOREIGN KEY (`lang_material_id`) REFERENCES `lang_material` (`id`),
  CONSTRAINT `note_ibfk_2` FOREIGN KEY (`archival_object_id`) REFERENCES `archival_object` (`id`),
  CONSTRAINT `note_ibfk_3` FOREIGN KEY (`digital_object_id`) REFERENCES `digital_object` (`id`),
  CONSTRAINT `note_ibfk_4` FOREIGN KEY (`digital_object_component_id`) REFERENCES `digital_object_component` (`id`),
  CONSTRAINT `note_ibfk_5` FOREIGN KEY (`agent_person_id`) REFERENCES `agent_person` (`id`),
  CONSTRAINT `note_ibfk_6` FOREIGN KEY (`agent_corporate_entity_id`) REFERENCES `agent_corporate_entity` (`id`),
  CONSTRAINT `note_ibfk_7` FOREIGN KEY (`agent_family_id`) REFERENCES `agent_family` (`id`),
  CONSTRAINT `note_ibfk_8` FOREIGN KEY (`agent_software_id`) REFERENCES `agent_software` (`id`),
  CONSTRAINT `note_ibfk_9` FOREIGN KEY (`rights_statement_act_id`) REFERENCES `rights_statement_act` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `note`
--

LOCK TABLES `note` WRITE;
/*!40000 ALTER TABLE `note` DISABLE KEYS */;
/*!40000 ALTER TABLE `note` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `note_persistent_id`
--

DROP TABLE IF EXISTS `note_persistent_id`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `note_persistent_id` (
  `id` int NOT NULL AUTO_INCREMENT,
  `note_id` int NOT NULL,
  `persistent_id` varchar(255) NOT NULL,
  `parent_type` varchar(255) NOT NULL,
  `parent_id` int NOT NULL,
  PRIMARY KEY (`id`),
  KEY `note_id` (`note_id`),
  CONSTRAINT `note_persistent_id_ibfk_1` FOREIGN KEY (`note_id`) REFERENCES `note` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `note_persistent_id`
--

LOCK TABLES `note_persistent_id` WRITE;
/*!40000 ALTER TABLE `note_persistent_id` DISABLE KEYS */;
/*!40000 ALTER TABLE `note_persistent_id` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `notification`
--

DROP TABLE IF EXISTS `notification`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `notification` (
  `id` int NOT NULL AUTO_INCREMENT,
  `time` datetime NOT NULL,
  `code` varchar(255) NOT NULL,
  `params` blob NOT NULL,
  PRIMARY KEY (`id`),
  KEY `notification_time_index` (`time`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `notification`
--

LOCK TABLES `notification` WRITE;
/*!40000 ALTER TABLE `notification` DISABLE KEYS */;
/*!40000 ALTER TABLE `notification` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `oai_config`
--

DROP TABLE IF EXISTS `oai_config`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `oai_config` (
  `id` int NOT NULL AUTO_INCREMENT,
  `oai_repository_name` varchar(255) DEFAULT NULL,
  `oai_record_prefix` varchar(255) DEFAULT NULL,
  `oai_admin_email` varchar(255) DEFAULT NULL,
  `created_by` varchar(255) DEFAULT NULL,
  `last_modified_by` varchar(255) DEFAULT NULL,
  `create_time` datetime DEFAULT NULL,
  `system_mtime` datetime DEFAULT NULL,
  `user_mtime` datetime DEFAULT NULL,
  `lock_version` int DEFAULT '0',
  `repo_set_codes` text,
  `repo_set_description` varchar(255) DEFAULT NULL,
  `sponsor_set_names` text,
  `sponsor_set_description` varchar(255) DEFAULT NULL,
  `repo_set_name` varchar(255) DEFAULT NULL,
  `sponsor_set_name` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb3;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `oai_config`
--

LOCK TABLES `oai_config` WRITE;
/*!40000 ALTER TABLE `oai_config` DISABLE KEYS */;
INSERT INTO `oai_config` VALUES (1,'ArchivesSpace OAI Provider','oai:archivesspace','admin@example.com','admin',NULL,'2024-04-18 15:46:26','2024-04-18 15:46:26','2024-04-18 15:46:26',0,'[]','','[]','','repository_set','sponsor_set');
/*!40000 ALTER TABLE `oai_config` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `owner_repo_rlshp`
--

DROP TABLE IF EXISTS `owner_repo_rlshp`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `owner_repo_rlshp` (
  `id` int NOT NULL AUTO_INCREMENT,
  `location_id` int DEFAULT NULL,
  `repository_id` int DEFAULT NULL,
  `aspace_relationship_position` int DEFAULT NULL,
  `suppressed` int NOT NULL DEFAULT '0',
  `created_by` varchar(255) DEFAULT NULL,
  `last_modified_by` varchar(255) DEFAULT NULL,
  `system_mtime` datetime NOT NULL,
  `user_mtime` datetime NOT NULL,
  PRIMARY KEY (`id`),
  KEY `owner_repo_rlshp_system_mtime_index` (`system_mtime`),
  KEY `owner_repo_rlshp_user_mtime_index` (`user_mtime`),
  KEY `location_id` (`location_id`),
  KEY `repository_id` (`repository_id`),
  CONSTRAINT `owner_repo_rlshp_ibfk_1` FOREIGN KEY (`location_id`) REFERENCES `location` (`id`),
  CONSTRAINT `owner_repo_rlshp_ibfk_2` FOREIGN KEY (`repository_id`) REFERENCES `repository` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `owner_repo_rlshp`
--

LOCK TABLES `owner_repo_rlshp` WRITE;
/*!40000 ALTER TABLE `owner_repo_rlshp` DISABLE KEYS */;
/*!40000 ALTER TABLE `owner_repo_rlshp` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `parallel_name_corporate_entity`
--

DROP TABLE IF EXISTS `parallel_name_corporate_entity`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `parallel_name_corporate_entity` (
  `id` int NOT NULL AUTO_INCREMENT,
  `lock_version` int NOT NULL DEFAULT '0',
  `json_schema_version` int NOT NULL,
  `name_corporate_entity_id` int NOT NULL,
  `location` varchar(255) DEFAULT NULL,
  `jurisdiction` int DEFAULT '0',
  `conference_meeting` int DEFAULT '0',
  `language_id` int DEFAULT NULL,
  `script_id` int DEFAULT NULL,
  `transliteration_id` int DEFAULT NULL,
  `primary_name` text NOT NULL,
  `subordinate_name_1` text,
  `subordinate_name_2` text,
  `number` varchar(255) DEFAULT NULL,
  `dates` varchar(255) DEFAULT NULL,
  `qualifier` text,
  `source_id` int DEFAULT NULL,
  `rules_id` int DEFAULT NULL,
  `sort_name` text NOT NULL,
  `sort_name_auto_generate` int DEFAULT '1',
  `created_by` varchar(255) DEFAULT NULL,
  `last_modified_by` varchar(255) DEFAULT NULL,
  `create_time` datetime NOT NULL,
  `system_mtime` datetime NOT NULL,
  `user_mtime` datetime NOT NULL,
  PRIMARY KEY (`id`),
  KEY `source_id` (`source_id`),
  KEY `rules_id` (`rules_id`),
  KEY `parallel_name_corporate_entity_system_mtime_index` (`system_mtime`),
  KEY `parallel_name_corporate_entity_user_mtime_index` (`user_mtime`),
  KEY `name_corporate_entity_id` (`name_corporate_entity_id`),
  CONSTRAINT `parallel_name_corporate_entity_ibfk_1` FOREIGN KEY (`source_id`) REFERENCES `enumeration_value` (`id`),
  CONSTRAINT `parallel_name_corporate_entity_ibfk_2` FOREIGN KEY (`rules_id`) REFERENCES `enumeration_value` (`id`),
  CONSTRAINT `parallel_name_corporate_entity_ibfk_3` FOREIGN KEY (`name_corporate_entity_id`) REFERENCES `name_corporate_entity` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `parallel_name_corporate_entity`
--

LOCK TABLES `parallel_name_corporate_entity` WRITE;
/*!40000 ALTER TABLE `parallel_name_corporate_entity` DISABLE KEYS */;
/*!40000 ALTER TABLE `parallel_name_corporate_entity` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `parallel_name_family`
--

DROP TABLE IF EXISTS `parallel_name_family`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `parallel_name_family` (
  `id` int NOT NULL AUTO_INCREMENT,
  `lock_version` int NOT NULL DEFAULT '0',
  `json_schema_version` int NOT NULL,
  `name_family_id` int NOT NULL,
  `family_type` varchar(255) DEFAULT NULL,
  `location` varchar(255) DEFAULT NULL,
  `language_id` int DEFAULT NULL,
  `script_id` int DEFAULT NULL,
  `transliteration_id` int DEFAULT NULL,
  `family_name` text NOT NULL,
  `prefix` text,
  `dates` varchar(255) DEFAULT NULL,
  `qualifier` text,
  `source_id` int DEFAULT NULL,
  `rules_id` int DEFAULT NULL,
  `sort_name` text NOT NULL,
  `sort_name_auto_generate` int DEFAULT '1',
  `created_by` varchar(255) DEFAULT NULL,
  `last_modified_by` varchar(255) DEFAULT NULL,
  `create_time` datetime NOT NULL,
  `system_mtime` datetime NOT NULL,
  `user_mtime` datetime NOT NULL,
  PRIMARY KEY (`id`),
  KEY `source_id` (`source_id`),
  KEY `rules_id` (`rules_id`),
  KEY `parallel_name_family_system_mtime_index` (`system_mtime`),
  KEY `parallel_name_family_user_mtime_index` (`user_mtime`),
  KEY `name_family_id` (`name_family_id`),
  CONSTRAINT `parallel_name_family_ibfk_1` FOREIGN KEY (`source_id`) REFERENCES `enumeration_value` (`id`),
  CONSTRAINT `parallel_name_family_ibfk_2` FOREIGN KEY (`rules_id`) REFERENCES `enumeration_value` (`id`),
  CONSTRAINT `parallel_name_family_ibfk_3` FOREIGN KEY (`name_family_id`) REFERENCES `name_family` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `parallel_name_family`
--

LOCK TABLES `parallel_name_family` WRITE;
/*!40000 ALTER TABLE `parallel_name_family` DISABLE KEYS */;
/*!40000 ALTER TABLE `parallel_name_family` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `parallel_name_person`
--

DROP TABLE IF EXISTS `parallel_name_person`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `parallel_name_person` (
  `id` int NOT NULL AUTO_INCREMENT,
  `lock_version` int NOT NULL DEFAULT '0',
  `json_schema_version` int NOT NULL,
  `name_person_id` int NOT NULL,
  `primary_name` varchar(255) NOT NULL,
  `name_order_id` int NOT NULL,
  `language_id` int DEFAULT NULL,
  `script_id` int DEFAULT NULL,
  `transliteration_id` int DEFAULT NULL,
  `title` varchar(8704) DEFAULT NULL,
  `prefix` text,
  `rest_of_name` text,
  `suffix` text,
  `fuller_form` text,
  `number` varchar(255) DEFAULT NULL,
  `dates` varchar(255) DEFAULT NULL,
  `qualifier` text,
  `source_id` int DEFAULT NULL,
  `rules_id` int DEFAULT NULL,
  `sort_name` text NOT NULL,
  `sort_name_auto_generate` int DEFAULT '1',
  `created_by` varchar(255) DEFAULT NULL,
  `last_modified_by` varchar(255) DEFAULT NULL,
  `create_time` datetime NOT NULL,
  `system_mtime` datetime NOT NULL,
  `user_mtime` datetime NOT NULL,
  PRIMARY KEY (`id`),
  KEY `name_order_id` (`name_order_id`),
  KEY `source_id` (`source_id`),
  KEY `rules_id` (`rules_id`),
  KEY `parallel_name_person_system_mtime_index` (`system_mtime`),
  KEY `parallel_name_person_user_mtime_index` (`user_mtime`),
  KEY `name_person_id` (`name_person_id`),
  CONSTRAINT `parallel_name_person_ibfk_1` FOREIGN KEY (`name_order_id`) REFERENCES `enumeration_value` (`id`),
  CONSTRAINT `parallel_name_person_ibfk_2` FOREIGN KEY (`source_id`) REFERENCES `enumeration_value` (`id`),
  CONSTRAINT `parallel_name_person_ibfk_3` FOREIGN KEY (`rules_id`) REFERENCES `enumeration_value` (`id`),
  CONSTRAINT `parallel_name_person_ibfk_4` FOREIGN KEY (`name_person_id`) REFERENCES `name_person` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `parallel_name_person`
--

LOCK TABLES `parallel_name_person` WRITE;
/*!40000 ALTER TABLE `parallel_name_person` DISABLE KEYS */;
/*!40000 ALTER TABLE `parallel_name_person` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `parallel_name_software`
--

DROP TABLE IF EXISTS `parallel_name_software`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `parallel_name_software` (
  `id` int NOT NULL AUTO_INCREMENT,
  `lock_version` int NOT NULL DEFAULT '0',
  `json_schema_version` int NOT NULL,
  `name_software_id` int NOT NULL,
  `language_id` int DEFAULT NULL,
  `script_id` int DEFAULT NULL,
  `transliteration_id` int DEFAULT NULL,
  `software_name` text NOT NULL,
  `version` text,
  `manufacturer` text,
  `dates` varchar(255) DEFAULT NULL,
  `qualifier` text,
  `source_id` int DEFAULT NULL,
  `rules_id` int DEFAULT NULL,
  `sort_name` text NOT NULL,
  `sort_name_auto_generate` int DEFAULT '1',
  `created_by` varchar(255) DEFAULT NULL,
  `last_modified_by` varchar(255) DEFAULT NULL,
  `create_time` datetime NOT NULL,
  `system_mtime` datetime NOT NULL,
  `user_mtime` datetime NOT NULL,
  PRIMARY KEY (`id`),
  KEY `source_id` (`source_id`),
  KEY `rules_id` (`rules_id`),
  KEY `parallel_name_software_system_mtime_index` (`system_mtime`),
  KEY `parallel_name_software_user_mtime_index` (`user_mtime`),
  KEY `name_software_id` (`name_software_id`),
  CONSTRAINT `parallel_name_software_ibfk_1` FOREIGN KEY (`source_id`) REFERENCES `enumeration_value` (`id`),
  CONSTRAINT `parallel_name_software_ibfk_2` FOREIGN KEY (`rules_id`) REFERENCES `enumeration_value` (`id`),
  CONSTRAINT `parallel_name_software_ibfk_3` FOREIGN KEY (`name_software_id`) REFERENCES `name_software` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `parallel_name_software`
--

LOCK TABLES `parallel_name_software` WRITE;
/*!40000 ALTER TABLE `parallel_name_software` DISABLE KEYS */;
/*!40000 ALTER TABLE `parallel_name_software` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `permission`
--

DROP TABLE IF EXISTS `permission`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `permission` (
  `id` int NOT NULL AUTO_INCREMENT,
  `permission_code` varchar(255) DEFAULT NULL,
  `description` text NOT NULL,
  `level` varchar(255) DEFAULT 'repository',
  `system` int NOT NULL DEFAULT '0',
  `created_by` varchar(255) DEFAULT NULL,
  `last_modified_by` varchar(255) DEFAULT NULL,
  `create_time` datetime NOT NULL,
  `system_mtime` datetime NOT NULL,
  `user_mtime` datetime NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `permission_code` (`permission_code`),
  KEY `permission_system_mtime_index` (`system_mtime`),
  KEY `permission_user_mtime_index` (`user_mtime`)
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8mb3;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `permission`
--

LOCK TABLES `permission` WRITE;
/*!40000 ALTER TABLE `permission` DISABLE KEYS */;
INSERT INTO `permission` VALUES (1,'create_job','The ability to create background jobs','repository',0,'admin','admin','2024-04-18 15:46:01','2024-04-18 15:46:01','2024-04-18 15:46:01'),(2,'cancel_job','The ability to cancel background jobs','repository',0,'admin','admin','2024-04-18 15:46:01','2024-04-18 15:46:01','2024-04-18 15:46:01'),(3,'manage_enumeration_record','The ability to create, modify and delete a controlled vocabulary list record','repository',0,'admin','admin','2024-04-18 15:46:24','2024-04-18 15:46:24','2024-04-18 15:46:24'),(4,'view_agent_contact_record','The ability to view contact details for agent records','repository',0,'admin','admin','2024-04-18 15:46:34','2024-04-18 15:46:34','2024-04-18 15:46:34'),(5,'show_full_agents','The ability to add and edit extended agent attributes','repository',0,'admin','admin','2024-04-18 15:46:57','2024-04-18 15:46:57','2024-04-18 15:46:57');
/*!40000 ALTER TABLE `permission` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `preference`
--

DROP TABLE IF EXISTS `preference`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `preference` (
  `id` int NOT NULL AUTO_INCREMENT,
  `lock_version` int NOT NULL DEFAULT '0',
  `json_schema_version` int NOT NULL,
  `repo_id` int NOT NULL,
  `user_id` int DEFAULT NULL,
  `user_uniq` varchar(255) NOT NULL,
  `defaults` mediumblob NOT NULL,
  `created_by` varchar(255) DEFAULT NULL,
  `last_modified_by` varchar(255) DEFAULT NULL,
  `create_time` datetime NOT NULL,
  `system_mtime` datetime NOT NULL,
  `user_mtime` datetime NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `preference_uniq` (`repo_id`,`user_uniq`),
  KEY `preference_system_mtime_index` (`system_mtime`),
  KEY `preference_user_mtime_index` (`user_mtime`),
  KEY `preference_user_id_fk` (`user_id`),
  CONSTRAINT `preference_repo_id_fk` FOREIGN KEY (`repo_id`) REFERENCES `repository` (`id`) ON DELETE CASCADE,
  CONSTRAINT `preference_user_id_fk` FOREIGN KEY (`user_id`) REFERENCES `user` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `preference`
--

LOCK TABLES `preference` WRITE;
/*!40000 ALTER TABLE `preference` DISABLE KEYS */;
/*!40000 ALTER TABLE `preference` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `rde_template`
--

DROP TABLE IF EXISTS `rde_template`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `rde_template` (
  `id` int NOT NULL AUTO_INCREMENT,
  `record_type` varchar(255) NOT NULL,
  `name` varchar(255) NOT NULL,
  `order` blob,
  `visible` blob,
  `defaults` blob,
  `created_by` varchar(255) DEFAULT NULL,
  `last_modified_by` varchar(255) DEFAULT NULL,
  `create_time` datetime NOT NULL,
  `system_mtime` datetime NOT NULL,
  `user_mtime` datetime NOT NULL,
  PRIMARY KEY (`id`),
  KEY `rde_template_system_mtime_index` (`system_mtime`),
  KEY `rde_template_user_mtime_index` (`user_mtime`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `rde_template`
--

LOCK TABLES `rde_template` WRITE;
/*!40000 ALTER TABLE `rde_template` DISABLE KEYS */;
/*!40000 ALTER TABLE `rde_template` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `related_accession_rlshp`
--

DROP TABLE IF EXISTS `related_accession_rlshp`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `related_accession_rlshp` (
  `id` int NOT NULL AUTO_INCREMENT,
  `accession_id_0` int DEFAULT NULL,
  `accession_id_1` int DEFAULT NULL,
  `suppressed` int NOT NULL DEFAULT '0',
  `relator_id` int NOT NULL,
  `relator_type_id` int NOT NULL,
  `relationship_target_record_type` varchar(255) NOT NULL,
  `relationship_target_id` int NOT NULL,
  `jsonmodel_type` varchar(255) NOT NULL,
  `aspace_relationship_position` int DEFAULT NULL,
  `created_by` varchar(255) DEFAULT NULL,
  `last_modified_by` varchar(255) DEFAULT NULL,
  `system_mtime` datetime NOT NULL,
  `user_mtime` datetime NOT NULL,
  PRIMARY KEY (`id`),
  KEY `relator_id` (`relator_id`),
  KEY `relator_type_id` (`relator_type_id`),
  KEY `related_accession_rlshp_system_mtime_index` (`system_mtime`),
  KEY `related_accession_rlshp_user_mtime_index` (`user_mtime`),
  KEY `accession_id_0` (`accession_id_0`),
  KEY `accession_id_1` (`accession_id_1`),
  CONSTRAINT `related_accession_rlshp_ibfk_1` FOREIGN KEY (`relator_id`) REFERENCES `enumeration_value` (`id`),
  CONSTRAINT `related_accession_rlshp_ibfk_2` FOREIGN KEY (`relator_type_id`) REFERENCES `enumeration_value` (`id`),
  CONSTRAINT `related_accession_rlshp_ibfk_3` FOREIGN KEY (`accession_id_0`) REFERENCES `accession` (`id`),
  CONSTRAINT `related_accession_rlshp_ibfk_4` FOREIGN KEY (`accession_id_1`) REFERENCES `accession` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `related_accession_rlshp`
--

LOCK TABLES `related_accession_rlshp` WRITE;
/*!40000 ALTER TABLE `related_accession_rlshp` DISABLE KEYS */;
/*!40000 ALTER TABLE `related_accession_rlshp` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `related_agents_rlshp`
--

DROP TABLE IF EXISTS `related_agents_rlshp`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `related_agents_rlshp` (
  `id` int NOT NULL AUTO_INCREMENT,
  `agent_person_id_0` int DEFAULT NULL,
  `agent_person_id_1` int DEFAULT NULL,
  `agent_corporate_entity_id_0` int DEFAULT NULL,
  `agent_corporate_entity_id_1` int DEFAULT NULL,
  `agent_software_id_0` int DEFAULT NULL,
  `agent_software_id_1` int DEFAULT NULL,
  `agent_family_id_0` int DEFAULT NULL,
  `agent_family_id_1` int DEFAULT NULL,
  `jsonmodel_type` varchar(255) NOT NULL,
  `description` text,
  `aspace_relationship_position` int DEFAULT NULL,
  `created_by` varchar(255) DEFAULT NULL,
  `last_modified_by` varchar(255) DEFAULT NULL,
  `create_time` datetime NOT NULL,
  `system_mtime` datetime NOT NULL,
  `user_mtime` datetime NOT NULL,
  `suppressed` int NOT NULL DEFAULT '0',
  `relationship_target_record_type` varchar(255) NOT NULL,
  `relationship_target_id` int NOT NULL,
  `relator_id` int NOT NULL,
  `specific_relator_id` int DEFAULT NULL,
  `relationship_uri` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `related_agents_rlshp_system_mtime_index` (`system_mtime`),
  KEY `related_agents_rlshp_user_mtime_index` (`user_mtime`),
  KEY `agent_person_id_0` (`agent_person_id_0`),
  KEY `agent_person_id_1` (`agent_person_id_1`),
  KEY `agent_corporate_entity_id_0` (`agent_corporate_entity_id_0`),
  KEY `agent_corporate_entity_id_1` (`agent_corporate_entity_id_1`),
  KEY `agent_software_id_0` (`agent_software_id_0`),
  KEY `agent_software_id_1` (`agent_software_id_1`),
  KEY `agent_family_id_0` (`agent_family_id_0`),
  KEY `agent_family_id_1` (`agent_family_id_1`),
  KEY `relator_id` (`relator_id`),
  KEY `specific_relator_id` (`specific_relator_id`),
  CONSTRAINT `related_agents_rlshp_ibfk_1` FOREIGN KEY (`agent_person_id_0`) REFERENCES `agent_person` (`id`),
  CONSTRAINT `related_agents_rlshp_ibfk_10` FOREIGN KEY (`specific_relator_id`) REFERENCES `enumeration_value` (`id`),
  CONSTRAINT `related_agents_rlshp_ibfk_2` FOREIGN KEY (`agent_person_id_1`) REFERENCES `agent_person` (`id`),
  CONSTRAINT `related_agents_rlshp_ibfk_3` FOREIGN KEY (`agent_corporate_entity_id_0`) REFERENCES `agent_corporate_entity` (`id`),
  CONSTRAINT `related_agents_rlshp_ibfk_4` FOREIGN KEY (`agent_corporate_entity_id_1`) REFERENCES `agent_corporate_entity` (`id`),
  CONSTRAINT `related_agents_rlshp_ibfk_5` FOREIGN KEY (`agent_software_id_0`) REFERENCES `agent_software` (`id`),
  CONSTRAINT `related_agents_rlshp_ibfk_6` FOREIGN KEY (`agent_software_id_1`) REFERENCES `agent_software` (`id`),
  CONSTRAINT `related_agents_rlshp_ibfk_7` FOREIGN KEY (`agent_family_id_0`) REFERENCES `agent_family` (`id`),
  CONSTRAINT `related_agents_rlshp_ibfk_8` FOREIGN KEY (`agent_family_id_1`) REFERENCES `agent_family` (`id`),
  CONSTRAINT `related_agents_rlshp_ibfk_9` FOREIGN KEY (`relator_id`) REFERENCES `enumeration_value` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `related_agents_rlshp`
--

LOCK TABLES `related_agents_rlshp` WRITE;
/*!40000 ALTER TABLE `related_agents_rlshp` DISABLE KEYS */;
/*!40000 ALTER TABLE `related_agents_rlshp` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `repository`
--

DROP TABLE IF EXISTS `repository`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `repository` (
  `id` int NOT NULL AUTO_INCREMENT,
  `lock_version` int NOT NULL DEFAULT '0',
  `json_schema_version` int NOT NULL,
  `repo_code` varchar(255) NOT NULL,
  `name` varchar(255) NOT NULL,
  `org_code` varchar(255) DEFAULT NULL,
  `parent_institution_name` varchar(255) DEFAULT NULL,
  `url` varchar(255) DEFAULT NULL,
  `image_url` varchar(255) DEFAULT NULL,
  `contact_persons` text,
  `country_id` int DEFAULT NULL,
  `agent_representation_id` int DEFAULT NULL,
  `hidden` int DEFAULT '0',
  `created_by` varchar(255) DEFAULT NULL,
  `last_modified_by` varchar(255) DEFAULT NULL,
  `create_time` datetime NOT NULL,
  `system_mtime` datetime NOT NULL,
  `user_mtime` datetime NOT NULL,
  `publish` int DEFAULT NULL,
  `description` text,
  `oai_is_disabled` int DEFAULT '0',
  `oai_sets_available` text,
  `slug` varchar(255) DEFAULT NULL,
  `is_slug_auto` int DEFAULT '1',
  `ark_shoulder` varchar(255) DEFAULT NULL,
  `position` int NOT NULL DEFAULT '-1',
  PRIMARY KEY (`id`),
  UNIQUE KEY `repo_code` (`repo_code`),
  UNIQUE KEY `position` (`position`),
  KEY `country_id` (`country_id`),
  KEY `repository_system_mtime_index` (`system_mtime`),
  KEY `repository_user_mtime_index` (`user_mtime`),
  KEY `agent_representation_id` (`agent_representation_id`),
  CONSTRAINT `repository_ibfk_1` FOREIGN KEY (`country_id`) REFERENCES `enumeration_value` (`id`),
  CONSTRAINT `repository_ibfk_2` FOREIGN KEY (`agent_representation_id`) REFERENCES `agent_corporate_entity` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `repository`
--

LOCK TABLES `repository` WRITE;
/*!40000 ALTER TABLE `repository` DISABLE KEYS */;
/*!40000 ALTER TABLE `repository` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `required_fields`
--

DROP TABLE IF EXISTS `required_fields`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `required_fields` (
  `lock_version` int NOT NULL DEFAULT '0',
  `id` varchar(255) NOT NULL,
  `blob` blob NOT NULL,
  `repo_id` int NOT NULL,
  `record_type` varchar(255) NOT NULL,
  `created_by` varchar(255) DEFAULT NULL,
  `last_modified_by` varchar(255) DEFAULT NULL,
  `create_time` datetime NOT NULL,
  `system_mtime` datetime NOT NULL,
  `user_mtime` datetime NOT NULL,
  PRIMARY KEY (`id`),
  KEY `required_fields_system_mtime_index` (`system_mtime`),
  KEY `required_fields_user_mtime_index` (`user_mtime`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `required_fields`
--

LOCK TABLES `required_fields` WRITE;
/*!40000 ALTER TABLE `required_fields` DISABLE KEYS */;
/*!40000 ALTER TABLE `required_fields` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `resource`
--

DROP TABLE IF EXISTS `resource`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `resource` (
  `id` int NOT NULL AUTO_INCREMENT,
  `lock_version` int NOT NULL DEFAULT '0',
  `json_schema_version` int NOT NULL,
  `repo_id` int NOT NULL,
  `accession_id` int DEFAULT NULL,
  `title` varchar(8704) NOT NULL,
  `identifier` varchar(255) DEFAULT NULL,
  `level_id` int NOT NULL,
  `other_level` varchar(255) DEFAULT NULL,
  `resource_type_id` int DEFAULT NULL,
  `publish` int DEFAULT NULL,
  `restrictions` int DEFAULT NULL,
  `repository_processing_note` text,
  `ead_id` varchar(255) DEFAULT NULL,
  `ead_location` varchar(255) DEFAULT NULL,
  `finding_aid_title` text,
  `finding_aid_filing_title` text,
  `finding_aid_date` varchar(255) DEFAULT NULL,
  `finding_aid_author` text,
  `finding_aid_description_rules_id` int DEFAULT NULL,
  `finding_aid_language_note` varchar(255) DEFAULT NULL,
  `finding_aid_sponsor` text,
  `finding_aid_edition_statement` text,
  `finding_aid_series_statement` text,
  `finding_aid_status_id` int DEFAULT NULL,
  `finding_aid_note` text,
  `system_generated` int DEFAULT '0',
  `created_by` varchar(255) DEFAULT NULL,
  `last_modified_by` varchar(255) DEFAULT NULL,
  `create_time` datetime NOT NULL,
  `system_mtime` datetime NOT NULL,
  `user_mtime` datetime NOT NULL,
  `suppressed` int NOT NULL DEFAULT '0',
  `finding_aid_subtitle` text,
  `finding_aid_sponsor_sha1` varchar(255) DEFAULT NULL,
  `slug` varchar(255) DEFAULT NULL,
  `is_slug_auto` int DEFAULT '0',
  `finding_aid_language_id` int DEFAULT NULL,
  `finding_aid_script_id` int DEFAULT NULL,
  `is_finding_aid_status_published` int DEFAULT '1',
  PRIMARY KEY (`id`),
  UNIQUE KEY `resource_unique_identifier` (`repo_id`,`identifier`),
  UNIQUE KEY `resource_unique_ead_id` (`repo_id`,`ead_id`),
  KEY `level_id` (`level_id`),
  KEY `resource_type_id` (`resource_type_id`),
  KEY `finding_aid_description_rules_id` (`finding_aid_description_rules_id`),
  KEY `finding_aid_status_id` (`finding_aid_status_id`),
  KEY `resource_system_mtime_index` (`system_mtime`),
  KEY `resource_user_mtime_index` (`user_mtime`),
  KEY `accession_id` (`accession_id`),
  CONSTRAINT `resource_ibfk_2` FOREIGN KEY (`level_id`) REFERENCES `enumeration_value` (`id`),
  CONSTRAINT `resource_ibfk_3` FOREIGN KEY (`resource_type_id`) REFERENCES `enumeration_value` (`id`),
  CONSTRAINT `resource_ibfk_4` FOREIGN KEY (`finding_aid_description_rules_id`) REFERENCES `enumeration_value` (`id`),
  CONSTRAINT `resource_ibfk_5` FOREIGN KEY (`finding_aid_status_id`) REFERENCES `enumeration_value` (`id`),
  CONSTRAINT `resource_ibfk_6` FOREIGN KEY (`repo_id`) REFERENCES `repository` (`id`),
  CONSTRAINT `resource_ibfk_7` FOREIGN KEY (`accession_id`) REFERENCES `accession` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `resource`
--

LOCK TABLES `resource` WRITE;
/*!40000 ALTER TABLE `resource` DISABLE KEYS */;
/*!40000 ALTER TABLE `resource` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `revision_statement`
--

DROP TABLE IF EXISTS `revision_statement`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `revision_statement` (
  `id` int NOT NULL AUTO_INCREMENT,
  `resource_id` int DEFAULT NULL,
  `date` varchar(255) DEFAULT NULL,
  `description` text,
  `created_by` varchar(255) DEFAULT NULL,
  `last_modified_by` varchar(255) DEFAULT NULL,
  `create_time` datetime NOT NULL,
  `system_mtime` datetime NOT NULL,
  `user_mtime` datetime NOT NULL,
  `publish` int DEFAULT '0',
  PRIMARY KEY (`id`),
  KEY `revision_statement_system_mtime_index` (`system_mtime`),
  KEY `revision_statement_user_mtime_index` (`user_mtime`),
  KEY `resource_id` (`resource_id`),
  CONSTRAINT `revision_statement_ibfk_1` FOREIGN KEY (`resource_id`) REFERENCES `resource` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `revision_statement`
--

LOCK TABLES `revision_statement` WRITE;
/*!40000 ALTER TABLE `revision_statement` DISABLE KEYS */;
/*!40000 ALTER TABLE `revision_statement` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `rights_restriction`
--

DROP TABLE IF EXISTS `rights_restriction`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `rights_restriction` (
  `id` int NOT NULL AUTO_INCREMENT,
  `resource_id` int DEFAULT NULL,
  `archival_object_id` int DEFAULT NULL,
  `restriction_note_type` varchar(255) DEFAULT NULL,
  `begin` date DEFAULT NULL,
  `end` date DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `resource_id` (`resource_id`),
  KEY `archival_object_id` (`archival_object_id`),
  CONSTRAINT `rights_restriction_ibfk_1` FOREIGN KEY (`resource_id`) REFERENCES `resource` (`id`),
  CONSTRAINT `rights_restriction_ibfk_2` FOREIGN KEY (`archival_object_id`) REFERENCES `archival_object` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `rights_restriction`
--

LOCK TABLES `rights_restriction` WRITE;
/*!40000 ALTER TABLE `rights_restriction` DISABLE KEYS */;
/*!40000 ALTER TABLE `rights_restriction` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `rights_restriction_type`
--

DROP TABLE IF EXISTS `rights_restriction_type`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `rights_restriction_type` (
  `id` int NOT NULL AUTO_INCREMENT,
  `rights_restriction_id` int NOT NULL,
  `restriction_type_id` int NOT NULL,
  PRIMARY KEY (`id`),
  KEY `restriction_type_id` (`restriction_type_id`),
  KEY `rights_restriction_id` (`rights_restriction_id`),
  CONSTRAINT `rights_restriction_type_ibfk_1` FOREIGN KEY (`restriction_type_id`) REFERENCES `enumeration_value` (`id`),
  CONSTRAINT `rights_restriction_type_ibfk_2` FOREIGN KEY (`rights_restriction_id`) REFERENCES `rights_restriction` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `rights_restriction_type`
--

LOCK TABLES `rights_restriction_type` WRITE;
/*!40000 ALTER TABLE `rights_restriction_type` DISABLE KEYS */;
/*!40000 ALTER TABLE `rights_restriction_type` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `rights_statement`
--

DROP TABLE IF EXISTS `rights_statement`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `rights_statement` (
  `id` int NOT NULL AUTO_INCREMENT,
  `lock_version` int NOT NULL DEFAULT '0',
  `json_schema_version` int NOT NULL,
  `accession_id` int DEFAULT NULL,
  `archival_object_id` int DEFAULT NULL,
  `resource_id` int DEFAULT NULL,
  `digital_object_id` int DEFAULT NULL,
  `digital_object_component_id` int DEFAULT NULL,
  `repo_id` int DEFAULT NULL,
  `identifier` varchar(255) NOT NULL,
  `rights_type_id` int NOT NULL,
  `statute_citation` varchar(255) DEFAULT NULL,
  `jurisdiction_id` int DEFAULT NULL,
  `created_by` varchar(255) DEFAULT NULL,
  `last_modified_by` varchar(255) DEFAULT NULL,
  `create_time` datetime NOT NULL,
  `system_mtime` datetime NOT NULL,
  `user_mtime` datetime NOT NULL,
  `status_id` int DEFAULT NULL,
  `start_date` date DEFAULT NULL,
  `end_date` date DEFAULT NULL,
  `determination_date` date DEFAULT NULL,
  `license_terms` varchar(255) DEFAULT NULL,
  `other_rights_basis_id` int DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `rights_type_id` (`rights_type_id`),
  KEY `jurisdiction_id` (`jurisdiction_id`),
  KEY `rights_statement_system_mtime_index` (`system_mtime`),
  KEY `rights_statement_user_mtime_index` (`user_mtime`),
  KEY `accession_id` (`accession_id`),
  KEY `archival_object_id` (`archival_object_id`),
  KEY `resource_id` (`resource_id`),
  KEY `digital_object_id` (`digital_object_id`),
  KEY `digital_object_component_id` (`digital_object_component_id`),
  KEY `rights_statement_status_id_fk` (`status_id`),
  KEY `rights_statement_other_rights_basis_id_fk` (`other_rights_basis_id`),
  CONSTRAINT `rights_statement_ibfk_1` FOREIGN KEY (`rights_type_id`) REFERENCES `enumeration_value` (`id`),
  CONSTRAINT `rights_statement_ibfk_3` FOREIGN KEY (`jurisdiction_id`) REFERENCES `enumeration_value` (`id`),
  CONSTRAINT `rights_statement_ibfk_4` FOREIGN KEY (`accession_id`) REFERENCES `accession` (`id`),
  CONSTRAINT `rights_statement_ibfk_5` FOREIGN KEY (`archival_object_id`) REFERENCES `archival_object` (`id`),
  CONSTRAINT `rights_statement_ibfk_6` FOREIGN KEY (`resource_id`) REFERENCES `resource` (`id`),
  CONSTRAINT `rights_statement_ibfk_7` FOREIGN KEY (`digital_object_id`) REFERENCES `digital_object` (`id`),
  CONSTRAINT `rights_statement_ibfk_8` FOREIGN KEY (`digital_object_component_id`) REFERENCES `digital_object_component` (`id`),
  CONSTRAINT `rights_statement_other_rights_basis_id_fk` FOREIGN KEY (`other_rights_basis_id`) REFERENCES `enumeration_value` (`id`),
  CONSTRAINT `rights_statement_status_id_fk` FOREIGN KEY (`status_id`) REFERENCES `enumeration_value` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `rights_statement`
--

LOCK TABLES `rights_statement` WRITE;
/*!40000 ALTER TABLE `rights_statement` DISABLE KEYS */;
/*!40000 ALTER TABLE `rights_statement` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `rights_statement_act`
--

DROP TABLE IF EXISTS `rights_statement_act`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `rights_statement_act` (
  `id` int NOT NULL AUTO_INCREMENT,
  `rights_statement_id` int NOT NULL,
  `act_type_id` int NOT NULL,
  `restriction_id` int NOT NULL,
  `start_date` date NOT NULL,
  `end_date` date DEFAULT NULL,
  `created_by` varchar(255) DEFAULT NULL,
  `last_modified_by` varchar(255) DEFAULT NULL,
  `create_time` datetime NOT NULL,
  `system_mtime` datetime NOT NULL,
  `user_mtime` datetime NOT NULL,
  PRIMARY KEY (`id`),
  KEY `act_type_id` (`act_type_id`),
  KEY `restriction_id` (`restriction_id`),
  KEY `rights_statement_act_system_mtime_index` (`system_mtime`),
  KEY `rights_statement_act_user_mtime_index` (`user_mtime`),
  KEY `rights_statement_id` (`rights_statement_id`),
  CONSTRAINT `rights_statement_act_ibfk_1` FOREIGN KEY (`act_type_id`) REFERENCES `enumeration_value` (`id`),
  CONSTRAINT `rights_statement_act_ibfk_2` FOREIGN KEY (`restriction_id`) REFERENCES `enumeration_value` (`id`),
  CONSTRAINT `rights_statement_act_ibfk_3` FOREIGN KEY (`rights_statement_id`) REFERENCES `rights_statement` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `rights_statement_act`
--

LOCK TABLES `rights_statement_act` WRITE;
/*!40000 ALTER TABLE `rights_statement_act` DISABLE KEYS */;
/*!40000 ALTER TABLE `rights_statement_act` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `rights_statement_pre_088`
--

DROP TABLE IF EXISTS `rights_statement_pre_088`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `rights_statement_pre_088` (
  `id` int NOT NULL DEFAULT '0',
  `lock_version` int NOT NULL DEFAULT '0',
  `json_schema_version` int NOT NULL,
  `accession_id` int DEFAULT NULL,
  `archival_object_id` int DEFAULT NULL,
  `resource_id` int DEFAULT NULL,
  `digital_object_id` int DEFAULT NULL,
  `digital_object_component_id` int DEFAULT NULL,
  `repo_id` int DEFAULT NULL,
  `identifier` varchar(255) CHARACTER SET utf8mb3 NOT NULL,
  `rights_type_id` int NOT NULL,
  `active` int DEFAULT NULL,
  `materials` varchar(255) CHARACTER SET utf8mb3 DEFAULT NULL,
  `ip_status_id` int DEFAULT NULL,
  `ip_expiration_date` date DEFAULT NULL,
  `license_identifier_terms` varchar(255) CHARACTER SET utf8mb3 DEFAULT NULL,
  `statute_citation` varchar(255) CHARACTER SET utf8mb3 DEFAULT NULL,
  `jurisdiction_id` int DEFAULT NULL,
  `type_note` varchar(255) CHARACTER SET utf8mb3 DEFAULT NULL,
  `permissions` text CHARACTER SET utf8mb3,
  `restrictions` text CHARACTER SET utf8mb3,
  `restriction_start_date` date DEFAULT NULL,
  `restriction_end_date` date DEFAULT NULL,
  `granted_note` varchar(255) CHARACTER SET utf8mb3 DEFAULT NULL,
  `created_by` varchar(255) CHARACTER SET utf8mb3 DEFAULT NULL,
  `last_modified_by` varchar(255) CHARACTER SET utf8mb3 DEFAULT NULL,
  `create_time` datetime NOT NULL,
  `system_mtime` datetime NOT NULL,
  `user_mtime` datetime NOT NULL,
  `agent_person_id` int DEFAULT NULL,
  `agent_family_id` int DEFAULT NULL,
  `agent_corporate_entity_id` int DEFAULT NULL,
  `agent_software_id` int DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `rights_statement_pre_088`
--

LOCK TABLES `rights_statement_pre_088` WRITE;
/*!40000 ALTER TABLE `rights_statement_pre_088` DISABLE KEYS */;
/*!40000 ALTER TABLE `rights_statement_pre_088` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `schema_info`
--

DROP TABLE IF EXISTS `schema_info`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `schema_info` (
  `version` int NOT NULL DEFAULT '0'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `schema_info`
--

LOCK TABLES `schema_info` WRITE;
/*!40000 ALTER TABLE `schema_info` DISABLE KEYS */;
INSERT INTO `schema_info` VALUES (175);
/*!40000 ALTER TABLE `schema_info` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `sequence`
--

DROP TABLE IF EXISTS `sequence`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `sequence` (
  `sequence_name` varchar(255) NOT NULL,
  `value` int NOT NULL,
  PRIMARY KEY (`sequence_name`),
  KEY `sequence_namevalue_idx` (`sequence_name`,`value`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `sequence`
--

LOCK TABLES `sequence` WRITE;
/*!40000 ALTER TABLE `sequence` DISABLE KEYS */;
/*!40000 ALTER TABLE `sequence` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `session`
--

DROP TABLE IF EXISTS `session`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `session` (
  `id` int NOT NULL AUTO_INCREMENT,
  `session_id` varchar(255) NOT NULL,
  `system_mtime` datetime NOT NULL,
  `expirable` int DEFAULT '1',
  `session_data` blob,
  PRIMARY KEY (`id`),
  UNIQUE KEY `session_id` (`session_id`),
  KEY `session_system_mtime_index` (`system_mtime`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `session`
--

LOCK TABLES `session` WRITE;
/*!40000 ALTER TABLE `session` DISABLE KEYS */;
/*!40000 ALTER TABLE `session` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `spawned_rlshp`
--

DROP TABLE IF EXISTS `spawned_rlshp`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `spawned_rlshp` (
  `id` int NOT NULL AUTO_INCREMENT,
  `accession_id` int DEFAULT NULL,
  `resource_id` int DEFAULT NULL,
  `aspace_relationship_position` int DEFAULT NULL,
  `created_by` varchar(255) DEFAULT NULL,
  `last_modified_by` varchar(255) DEFAULT NULL,
  `system_mtime` datetime NOT NULL,
  `user_mtime` datetime NOT NULL,
  `suppressed` int NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`),
  KEY `spawned_rlshp_system_mtime_index` (`system_mtime`),
  KEY `spawned_rlshp_user_mtime_index` (`user_mtime`),
  KEY `accession_id` (`accession_id`),
  KEY `resource_id` (`resource_id`),
  CONSTRAINT `spawned_rlshp_ibfk_1` FOREIGN KEY (`accession_id`) REFERENCES `accession` (`id`),
  CONSTRAINT `spawned_rlshp_ibfk_2` FOREIGN KEY (`resource_id`) REFERENCES `resource` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `spawned_rlshp`
--

LOCK TABLES `spawned_rlshp` WRITE;
/*!40000 ALTER TABLE `spawned_rlshp` DISABLE KEYS */;
/*!40000 ALTER TABLE `spawned_rlshp` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `structured_date_label`
--

DROP TABLE IF EXISTS `structured_date_label`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `structured_date_label` (
  `id` int NOT NULL AUTO_INCREMENT,
  `date_label_id` int NOT NULL,
  `date_certainty_id` int DEFAULT NULL,
  `date_era_id` int DEFAULT NULL,
  `date_calendar_id` int DEFAULT NULL,
  `agent_person_id` int DEFAULT NULL,
  `agent_family_id` int DEFAULT NULL,
  `agent_corporate_entity_id` int DEFAULT NULL,
  `agent_software_id` int DEFAULT NULL,
  `name_person_id` int DEFAULT NULL,
  `name_family_id` int DEFAULT NULL,
  `name_corporate_entity_id` int DEFAULT NULL,
  `name_software_id` int DEFAULT NULL,
  `parallel_name_person_id` int DEFAULT NULL,
  `parallel_name_family_id` int DEFAULT NULL,
  `parallel_name_corporate_entity_id` int DEFAULT NULL,
  `parallel_name_software_id` int DEFAULT NULL,
  `related_agents_rlshp_id` int DEFAULT NULL,
  `agent_place_id` int DEFAULT NULL,
  `agent_occupation_id` int DEFAULT NULL,
  `agent_function_id` int DEFAULT NULL,
  `agent_topic_id` int DEFAULT NULL,
  `agent_gender_id` int DEFAULT NULL,
  `agent_resource_id` int DEFAULT NULL,
  `created_by` varchar(255) DEFAULT NULL,
  `last_modified_by` varchar(255) DEFAULT NULL,
  `create_time` datetime NOT NULL,
  `system_mtime` datetime NOT NULL,
  `user_mtime` datetime NOT NULL,
  `lock_version` int NOT NULL DEFAULT '0',
  `date_type_structured` varchar(255) NOT NULL DEFAULT 'none',
  PRIMARY KEY (`id`),
  KEY `structured_date_label_system_mtime_index` (`system_mtime`),
  KEY `structured_date_label_user_mtime_index` (`user_mtime`),
  KEY `agent_person_id` (`agent_person_id`),
  KEY `agent_family_id` (`agent_family_id`),
  KEY `agent_corporate_entity_id` (`agent_corporate_entity_id`),
  KEY `agent_software_id` (`agent_software_id`),
  CONSTRAINT `structured_date_label_ibfk_1` FOREIGN KEY (`agent_person_id`) REFERENCES `agent_person` (`id`),
  CONSTRAINT `structured_date_label_ibfk_2` FOREIGN KEY (`agent_family_id`) REFERENCES `agent_family` (`id`),
  CONSTRAINT `structured_date_label_ibfk_3` FOREIGN KEY (`agent_corporate_entity_id`) REFERENCES `agent_corporate_entity` (`id`),
  CONSTRAINT `structured_date_label_ibfk_4` FOREIGN KEY (`agent_software_id`) REFERENCES `agent_software` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `structured_date_label`
--

LOCK TABLES `structured_date_label` WRITE;
/*!40000 ALTER TABLE `structured_date_label` DISABLE KEYS */;
/*!40000 ALTER TABLE `structured_date_label` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `structured_date_range`
--

DROP TABLE IF EXISTS `structured_date_range`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `structured_date_range` (
  `id` int NOT NULL AUTO_INCREMENT,
  `structured_date_label_id` int NOT NULL,
  `begin_date_expression` varchar(255) DEFAULT NULL,
  `begin_date_standardized` varchar(255) DEFAULT NULL,
  `begin_date_standardized_type_id` int NOT NULL DEFAULT '1769',
  `end_date_expression` varchar(255) DEFAULT NULL,
  `end_date_standardized` varchar(255) DEFAULT NULL,
  `end_date_standardized_type_id` int NOT NULL DEFAULT '1769',
  `created_by` varchar(255) DEFAULT NULL,
  `last_modified_by` varchar(255) DEFAULT NULL,
  `create_time` datetime NOT NULL,
  `system_mtime` datetime NOT NULL,
  `user_mtime` datetime NOT NULL,
  `lock_version` int NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`),
  KEY `structured_date_range_system_mtime_index` (`system_mtime`),
  KEY `structured_date_range_user_mtime_index` (`user_mtime`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `structured_date_range`
--

LOCK TABLES `structured_date_range` WRITE;
/*!40000 ALTER TABLE `structured_date_range` DISABLE KEYS */;
/*!40000 ALTER TABLE `structured_date_range` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `structured_date_single`
--

DROP TABLE IF EXISTS `structured_date_single`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `structured_date_single` (
  `id` int NOT NULL AUTO_INCREMENT,
  `structured_date_label_id` int NOT NULL,
  `date_role_id` int NOT NULL,
  `date_expression` varchar(255) DEFAULT NULL,
  `date_standardized` varchar(255) DEFAULT NULL,
  `date_standardized_type_id` int NOT NULL DEFAULT '1769',
  `created_by` varchar(255) DEFAULT NULL,
  `last_modified_by` varchar(255) DEFAULT NULL,
  `create_time` datetime NOT NULL,
  `system_mtime` datetime NOT NULL,
  `user_mtime` datetime NOT NULL,
  `lock_version` int NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`),
  KEY `structured_date_single_system_mtime_index` (`system_mtime`),
  KEY `structured_date_single_user_mtime_index` (`user_mtime`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `structured_date_single`
--

LOCK TABLES `structured_date_single` WRITE;
/*!40000 ALTER TABLE `structured_date_single` DISABLE KEYS */;
/*!40000 ALTER TABLE `structured_date_single` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `sub_container`
--

DROP TABLE IF EXISTS `sub_container`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `sub_container` (
  `id` int NOT NULL AUTO_INCREMENT,
  `lock_version` int NOT NULL DEFAULT '0',
  `json_schema_version` int NOT NULL,
  `instance_id` int DEFAULT NULL,
  `type_2_id` int DEFAULT NULL,
  `indicator_2` varchar(255) DEFAULT NULL,
  `type_3_id` int DEFAULT NULL,
  `indicator_3` varchar(255) DEFAULT NULL,
  `created_by` varchar(255) DEFAULT NULL,
  `last_modified_by` varchar(255) DEFAULT NULL,
  `create_time` datetime NOT NULL,
  `system_mtime` datetime NOT NULL,
  `user_mtime` datetime NOT NULL,
  `barcode_2` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `type_2_id` (`type_2_id`),
  KEY `type_3_id` (`type_3_id`),
  KEY `sub_container_system_mtime_index` (`system_mtime`),
  KEY `sub_container_user_mtime_index` (`user_mtime`),
  KEY `instance_id` (`instance_id`),
  CONSTRAINT `sub_container_ibfk_1` FOREIGN KEY (`type_2_id`) REFERENCES `enumeration_value` (`id`),
  CONSTRAINT `sub_container_ibfk_2` FOREIGN KEY (`type_3_id`) REFERENCES `enumeration_value` (`id`),
  CONSTRAINT `sub_container_ibfk_3` FOREIGN KEY (`instance_id`) REFERENCES `instance` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `sub_container`
--

LOCK TABLES `sub_container` WRITE;
/*!40000 ALTER TABLE `sub_container` DISABLE KEYS */;
/*!40000 ALTER TABLE `sub_container` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `subject`
--

DROP TABLE IF EXISTS `subject`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `subject` (
  `id` int NOT NULL AUTO_INCREMENT,
  `lock_version` int NOT NULL DEFAULT '0',
  `json_schema_version` int NOT NULL,
  `vocab_id` int NOT NULL,
  `title` varchar(8704) DEFAULT NULL,
  `terms_sha1` varchar(255) NOT NULL,
  `authority_id` varchar(255) DEFAULT NULL,
  `scope_note` text,
  `source_id` int DEFAULT NULL,
  `created_by` varchar(255) DEFAULT NULL,
  `last_modified_by` varchar(255) DEFAULT NULL,
  `create_time` datetime NOT NULL,
  `system_mtime` datetime NOT NULL,
  `user_mtime` datetime NOT NULL,
  `slug` varchar(255) DEFAULT NULL,
  `is_slug_auto` int DEFAULT '0',
  PRIMARY KEY (`id`),
  UNIQUE KEY `subj_auth_source_uniq` (`vocab_id`,`authority_id`,`source_id`),
  UNIQUE KEY `subj_terms_uniq` (`vocab_id`,`terms_sha1`,`source_id`),
  KEY `source_id` (`source_id`),
  KEY `subject_terms_sha1_index` (`terms_sha1`),
  KEY `subject_system_mtime_index` (`system_mtime`),
  KEY `subject_user_mtime_index` (`user_mtime`),
  CONSTRAINT `subject_ibfk_1` FOREIGN KEY (`source_id`) REFERENCES `enumeration_value` (`id`),
  CONSTRAINT `subject_ibfk_2` FOREIGN KEY (`vocab_id`) REFERENCES `vocabulary` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `subject`
--

LOCK TABLES `subject` WRITE;
/*!40000 ALTER TABLE `subject` DISABLE KEYS */;
/*!40000 ALTER TABLE `subject` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `subject_agent_subrecord_place_rlshp`
--

DROP TABLE IF EXISTS `subject_agent_subrecord_place_rlshp`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `subject_agent_subrecord_place_rlshp` (
  `id` int NOT NULL AUTO_INCREMENT,
  `subject_id` int DEFAULT NULL,
  `agent_function_id` int DEFAULT NULL,
  `agent_occupation_id` int DEFAULT NULL,
  `agent_resource_id` int DEFAULT NULL,
  `agent_topic_id` int DEFAULT NULL,
  `aspace_relationship_position` int DEFAULT NULL,
  `suppressed` int NOT NULL DEFAULT '0',
  `created_by` varchar(255) DEFAULT NULL,
  `last_modified_by` varchar(255) DEFAULT NULL,
  `system_mtime` datetime NOT NULL,
  `user_mtime` datetime NOT NULL,
  PRIMARY KEY (`id`),
  KEY `subject_agent_subrecord_place_rlshp_system_mtime_index` (`system_mtime`),
  KEY `subject_agent_subrecord_place_rlshp_user_mtime_index` (`user_mtime`),
  KEY `subject_id` (`subject_id`),
  KEY `agent_function_id` (`agent_function_id`),
  KEY `agent_occupation_id` (`agent_occupation_id`),
  KEY `agent_topic_id` (`agent_topic_id`),
  CONSTRAINT `subject_agent_subrecord_place_rlshp_ibfk_1` FOREIGN KEY (`subject_id`) REFERENCES `subject` (`id`),
  CONSTRAINT `subject_agent_subrecord_place_rlshp_ibfk_2` FOREIGN KEY (`agent_function_id`) REFERENCES `agent_function` (`id`),
  CONSTRAINT `subject_agent_subrecord_place_rlshp_ibfk_3` FOREIGN KEY (`agent_occupation_id`) REFERENCES `agent_occupation` (`id`),
  CONSTRAINT `subject_agent_subrecord_place_rlshp_ibfk_4` FOREIGN KEY (`agent_topic_id`) REFERENCES `agent_topic` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `subject_agent_subrecord_place_rlshp`
--

LOCK TABLES `subject_agent_subrecord_place_rlshp` WRITE;
/*!40000 ALTER TABLE `subject_agent_subrecord_place_rlshp` DISABLE KEYS */;
/*!40000 ALTER TABLE `subject_agent_subrecord_place_rlshp` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `subject_agent_subrecord_rlshp`
--

DROP TABLE IF EXISTS `subject_agent_subrecord_rlshp`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `subject_agent_subrecord_rlshp` (
  `id` int NOT NULL AUTO_INCREMENT,
  `subject_id` int DEFAULT NULL,
  `agent_function_id` int DEFAULT NULL,
  `agent_occupation_id` int DEFAULT NULL,
  `agent_place_id` int DEFAULT NULL,
  `agent_topic_id` int DEFAULT NULL,
  `aspace_relationship_position` int DEFAULT NULL,
  `suppressed` int NOT NULL DEFAULT '0',
  `created_by` varchar(255) DEFAULT NULL,
  `last_modified_by` varchar(255) DEFAULT NULL,
  `system_mtime` datetime NOT NULL,
  `user_mtime` datetime NOT NULL,
  PRIMARY KEY (`id`),
  KEY `subject_agent_subrecord_rlshp_system_mtime_index` (`system_mtime`),
  KEY `subject_agent_subrecord_rlshp_user_mtime_index` (`user_mtime`),
  KEY `subject_id` (`subject_id`),
  KEY `agent_function_id` (`agent_function_id`),
  KEY `agent_occupation_id` (`agent_occupation_id`),
  KEY `agent_place_id` (`agent_place_id`),
  KEY `agent_topic_id` (`agent_topic_id`),
  CONSTRAINT `subject_agent_subrecord_rlshp_ibfk_1` FOREIGN KEY (`subject_id`) REFERENCES `subject` (`id`),
  CONSTRAINT `subject_agent_subrecord_rlshp_ibfk_2` FOREIGN KEY (`agent_function_id`) REFERENCES `agent_function` (`id`),
  CONSTRAINT `subject_agent_subrecord_rlshp_ibfk_3` FOREIGN KEY (`agent_occupation_id`) REFERENCES `agent_occupation` (`id`),
  CONSTRAINT `subject_agent_subrecord_rlshp_ibfk_4` FOREIGN KEY (`agent_place_id`) REFERENCES `agent_place` (`id`),
  CONSTRAINT `subject_agent_subrecord_rlshp_ibfk_5` FOREIGN KEY (`agent_topic_id`) REFERENCES `agent_topic` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `subject_agent_subrecord_rlshp`
--

LOCK TABLES `subject_agent_subrecord_rlshp` WRITE;
/*!40000 ALTER TABLE `subject_agent_subrecord_rlshp` DISABLE KEYS */;
/*!40000 ALTER TABLE `subject_agent_subrecord_rlshp` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `subject_rlshp`
--

DROP TABLE IF EXISTS `subject_rlshp`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `subject_rlshp` (
  `id` int NOT NULL AUTO_INCREMENT,
  `accession_id` int DEFAULT NULL,
  `archival_object_id` int DEFAULT NULL,
  `resource_id` int DEFAULT NULL,
  `digital_object_id` int DEFAULT NULL,
  `digital_object_component_id` int DEFAULT NULL,
  `subject_id` int DEFAULT NULL,
  `aspace_relationship_position` int DEFAULT NULL,
  `created_by` varchar(255) DEFAULT NULL,
  `last_modified_by` varchar(255) DEFAULT NULL,
  `system_mtime` datetime NOT NULL,
  `user_mtime` datetime NOT NULL,
  `suppressed` int NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`),
  KEY `subject_rlshp_system_mtime_index` (`system_mtime`),
  KEY `subject_rlshp_user_mtime_index` (`user_mtime`),
  KEY `accession_id` (`accession_id`),
  KEY `archival_object_id` (`archival_object_id`),
  KEY `resource_id` (`resource_id`),
  KEY `digital_object_id` (`digital_object_id`),
  KEY `digital_object_component_id` (`digital_object_component_id`),
  KEY `subject_id` (`subject_id`),
  CONSTRAINT `subject_rlshp_ibfk_1` FOREIGN KEY (`accession_id`) REFERENCES `accession` (`id`),
  CONSTRAINT `subject_rlshp_ibfk_2` FOREIGN KEY (`archival_object_id`) REFERENCES `archival_object` (`id`),
  CONSTRAINT `subject_rlshp_ibfk_3` FOREIGN KEY (`resource_id`) REFERENCES `resource` (`id`),
  CONSTRAINT `subject_rlshp_ibfk_4` FOREIGN KEY (`digital_object_id`) REFERENCES `digital_object` (`id`),
  CONSTRAINT `subject_rlshp_ibfk_5` FOREIGN KEY (`digital_object_component_id`) REFERENCES `digital_object_component` (`id`),
  CONSTRAINT `subject_rlshp_ibfk_6` FOREIGN KEY (`subject_id`) REFERENCES `subject` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `subject_rlshp`
--

LOCK TABLES `subject_rlshp` WRITE;
/*!40000 ALTER TABLE `subject_rlshp` DISABLE KEYS */;
/*!40000 ALTER TABLE `subject_rlshp` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `subject_term`
--

DROP TABLE IF EXISTS `subject_term`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `subject_term` (
  `id` int NOT NULL AUTO_INCREMENT,
  `subject_id` int NOT NULL,
  `term_id` int NOT NULL,
  PRIMARY KEY (`id`),
  KEY `term_id` (`term_id`),
  KEY `subject_term_idx` (`subject_id`,`term_id`),
  CONSTRAINT `subject_term_ibfk_1` FOREIGN KEY (`subject_id`) REFERENCES `subject` (`id`),
  CONSTRAINT `subject_term_ibfk_2` FOREIGN KEY (`term_id`) REFERENCES `term` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `subject_term`
--

LOCK TABLES `subject_term` WRITE;
/*!40000 ALTER TABLE `subject_term` DISABLE KEYS */;
/*!40000 ALTER TABLE `subject_term` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `subnote_metadata`
--

DROP TABLE IF EXISTS `subnote_metadata`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `subnote_metadata` (
  `id` int NOT NULL AUTO_INCREMENT,
  `note_id` int NOT NULL,
  `guid` varchar(255) NOT NULL,
  `publish` int DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `note_id` (`note_id`),
  CONSTRAINT `subnote_metadata_ibfk_1` FOREIGN KEY (`note_id`) REFERENCES `note` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `subnote_metadata`
--

LOCK TABLES `subnote_metadata` WRITE;
/*!40000 ALTER TABLE `subnote_metadata` DISABLE KEYS */;
/*!40000 ALTER TABLE `subnote_metadata` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `surveyed_by_rlshp`
--

DROP TABLE IF EXISTS `surveyed_by_rlshp`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `surveyed_by_rlshp` (
  `id` int NOT NULL AUTO_INCREMENT,
  `assessment_id` int NOT NULL,
  `agent_person_id` int DEFAULT NULL,
  `aspace_relationship_position` int DEFAULT NULL,
  `suppressed` int NOT NULL DEFAULT '0',
  `created_by` varchar(255) DEFAULT NULL,
  `last_modified_by` varchar(255) DEFAULT NULL,
  `system_mtime` datetime NOT NULL,
  `user_mtime` datetime NOT NULL,
  PRIMARY KEY (`id`),
  KEY `surveyed_by_rlshp_system_mtime_index` (`system_mtime`),
  KEY `surveyed_by_rlshp_user_mtime_index` (`user_mtime`),
  KEY `assessment_id` (`assessment_id`),
  KEY `agent_person_id` (`agent_person_id`),
  CONSTRAINT `surveyed_by_rlshp_ibfk_1` FOREIGN KEY (`assessment_id`) REFERENCES `assessment` (`id`),
  CONSTRAINT `surveyed_by_rlshp_ibfk_2` FOREIGN KEY (`agent_person_id`) REFERENCES `agent_person` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `surveyed_by_rlshp`
--

LOCK TABLES `surveyed_by_rlshp` WRITE;
/*!40000 ALTER TABLE `surveyed_by_rlshp` DISABLE KEYS */;
/*!40000 ALTER TABLE `surveyed_by_rlshp` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `system_event`
--

DROP TABLE IF EXISTS `system_event`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `system_event` (
  `id` int NOT NULL AUTO_INCREMENT,
  `title` varchar(255) DEFAULT NULL,
  `time` datetime NOT NULL,
  `message` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `system_event_time_index` (`time`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `system_event`
--

LOCK TABLES `system_event` WRITE;
/*!40000 ALTER TABLE `system_event` DISABLE KEYS */;
/*!40000 ALTER TABLE `system_event` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `telephone`
--

DROP TABLE IF EXISTS `telephone`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `telephone` (
  `id` int NOT NULL AUTO_INCREMENT,
  `agent_contact_id` int DEFAULT NULL,
  `number` text NOT NULL,
  `ext` text,
  `created_by` varchar(255) DEFAULT NULL,
  `last_modified_by` varchar(255) DEFAULT NULL,
  `create_time` datetime NOT NULL,
  `system_mtime` datetime NOT NULL,
  `user_mtime` datetime NOT NULL,
  `number_type_id` int DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `telephone_system_mtime_index` (`system_mtime`),
  KEY `telephone_user_mtime_index` (`user_mtime`),
  KEY `agent_contact_id` (`agent_contact_id`),
  KEY `number_type_id` (`number_type_id`),
  CONSTRAINT `telephone_ibfk_1` FOREIGN KEY (`agent_contact_id`) REFERENCES `agent_contact` (`id`),
  CONSTRAINT `telephone_ibfk_2` FOREIGN KEY (`number_type_id`) REFERENCES `enumeration_value` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `telephone`
--

LOCK TABLES `telephone` WRITE;
/*!40000 ALTER TABLE `telephone` DISABLE KEYS */;
/*!40000 ALTER TABLE `telephone` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `term`
--

DROP TABLE IF EXISTS `term`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `term` (
  `id` int NOT NULL AUTO_INCREMENT,
  `lock_version` int NOT NULL DEFAULT '0',
  `json_schema_version` int NOT NULL,
  `vocab_id` int NOT NULL,
  `term` varchar(255) NOT NULL,
  `term_type_id` int NOT NULL,
  `created_by` varchar(255) DEFAULT NULL,
  `last_modified_by` varchar(255) DEFAULT NULL,
  `create_time` datetime NOT NULL,
  `system_mtime` datetime NOT NULL,
  `user_mtime` datetime NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `term_vocab_id_term_term_type_id_index` (`vocab_id`,`term`,`term_type_id`),
  KEY `term_type_id` (`term_type_id`),
  KEY `term_system_mtime_index` (`system_mtime`),
  KEY `term_user_mtime_index` (`user_mtime`),
  CONSTRAINT `term_ibfk_1` FOREIGN KEY (`term_type_id`) REFERENCES `enumeration_value` (`id`),
  CONSTRAINT `term_ibfk_2` FOREIGN KEY (`vocab_id`) REFERENCES `vocabulary` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `term`
--

LOCK TABLES `term` WRITE;
/*!40000 ALTER TABLE `term` DISABLE KEYS */;
/*!40000 ALTER TABLE `term` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `top_container`
--

DROP TABLE IF EXISTS `top_container`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `top_container` (
  `id` int NOT NULL AUTO_INCREMENT,
  `repo_id` int NOT NULL,
  `lock_version` int NOT NULL DEFAULT '0',
  `json_schema_version` int NOT NULL,
  `barcode` varchar(255) DEFAULT NULL,
  `ils_holding_id` varchar(255) DEFAULT NULL,
  `ils_item_id` varchar(255) DEFAULT NULL,
  `exported_to_ils` datetime DEFAULT NULL,
  `indicator` varchar(255) NOT NULL,
  `created_by` varchar(255) DEFAULT NULL,
  `last_modified_by` varchar(255) DEFAULT NULL,
  `create_time` datetime NOT NULL,
  `system_mtime` datetime NOT NULL,
  `user_mtime` datetime NOT NULL,
  `type_id` int DEFAULT NULL,
  `created_for_collection` varchar(255) DEFAULT NULL,
  `internal_note` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `top_container_uniq_barcode` (`repo_id`,`barcode`),
  KEY `top_container_indicator_index` (`indicator`),
  KEY `top_container_system_mtime_index` (`system_mtime`),
  KEY `top_container_user_mtime_index` (`user_mtime`),
  KEY `top_container_type_fk` (`type_id`),
  CONSTRAINT `top_container_type_fk` FOREIGN KEY (`type_id`) REFERENCES `enumeration_value` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `top_container`
--

LOCK TABLES `top_container` WRITE;
/*!40000 ALTER TABLE `top_container` DISABLE KEYS */;
/*!40000 ALTER TABLE `top_container` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `top_container_housed_at_rlshp`
--

DROP TABLE IF EXISTS `top_container_housed_at_rlshp`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `top_container_housed_at_rlshp` (
  `id` int NOT NULL AUTO_INCREMENT,
  `top_container_id` int DEFAULT NULL,
  `location_id` int DEFAULT NULL,
  `aspace_relationship_position` int DEFAULT NULL,
  `suppressed` int NOT NULL DEFAULT '0',
  `jsonmodel_type` varchar(255) NOT NULL DEFAULT 'container_location',
  `status` varchar(255) DEFAULT NULL,
  `start_date` date DEFAULT NULL,
  `end_date` date DEFAULT NULL,
  `note` varchar(255) DEFAULT NULL,
  `created_by` varchar(255) DEFAULT NULL,
  `last_modified_by` varchar(255) DEFAULT NULL,
  `system_mtime` datetime NOT NULL,
  `user_mtime` datetime NOT NULL,
  PRIMARY KEY (`id`),
  KEY `top_container_housed_at_rlshp_system_mtime_index` (`system_mtime`),
  KEY `top_container_housed_at_rlshp_user_mtime_index` (`user_mtime`),
  KEY `top_container_id` (`top_container_id`),
  KEY `location_id` (`location_id`),
  CONSTRAINT `top_container_housed_at_rlshp_ibfk_1` FOREIGN KEY (`top_container_id`) REFERENCES `top_container` (`id`),
  CONSTRAINT `top_container_housed_at_rlshp_ibfk_2` FOREIGN KEY (`location_id`) REFERENCES `location` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `top_container_housed_at_rlshp`
--

LOCK TABLES `top_container_housed_at_rlshp` WRITE;
/*!40000 ALTER TABLE `top_container_housed_at_rlshp` DISABLE KEYS */;
/*!40000 ALTER TABLE `top_container_housed_at_rlshp` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `top_container_link_rlshp`
--

DROP TABLE IF EXISTS `top_container_link_rlshp`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `top_container_link_rlshp` (
  `id` int NOT NULL AUTO_INCREMENT,
  `top_container_id` int DEFAULT NULL,
  `sub_container_id` int DEFAULT NULL,
  `aspace_relationship_position` int DEFAULT NULL,
  `suppressed` int NOT NULL DEFAULT '0',
  `created_by` varchar(255) DEFAULT NULL,
  `last_modified_by` varchar(255) DEFAULT NULL,
  `system_mtime` datetime NOT NULL,
  `user_mtime` datetime NOT NULL,
  PRIMARY KEY (`id`),
  KEY `top_container_link_rlshp_system_mtime_index` (`system_mtime`),
  KEY `top_container_link_rlshp_user_mtime_index` (`user_mtime`),
  KEY `top_container_id` (`top_container_id`),
  KEY `sub_container_id` (`sub_container_id`),
  CONSTRAINT `top_container_link_rlshp_ibfk_1` FOREIGN KEY (`top_container_id`) REFERENCES `top_container` (`id`),
  CONSTRAINT `top_container_link_rlshp_ibfk_2` FOREIGN KEY (`sub_container_id`) REFERENCES `sub_container` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `top_container_link_rlshp`
--

LOCK TABLES `top_container_link_rlshp` WRITE;
/*!40000 ALTER TABLE `top_container_link_rlshp` DISABLE KEYS */;
/*!40000 ALTER TABLE `top_container_link_rlshp` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `top_container_profile_rlshp`
--

DROP TABLE IF EXISTS `top_container_profile_rlshp`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `top_container_profile_rlshp` (
  `id` int NOT NULL AUTO_INCREMENT,
  `top_container_id` int DEFAULT NULL,
  `container_profile_id` int DEFAULT NULL,
  `aspace_relationship_position` int DEFAULT NULL,
  `suppressed` int NOT NULL DEFAULT '0',
  `created_by` varchar(255) DEFAULT NULL,
  `last_modified_by` varchar(255) DEFAULT NULL,
  `system_mtime` datetime NOT NULL,
  `user_mtime` datetime NOT NULL,
  PRIMARY KEY (`id`),
  KEY `top_container_profile_rlshp_system_mtime_index` (`system_mtime`),
  KEY `top_container_profile_rlshp_user_mtime_index` (`user_mtime`),
  KEY `top_container_id` (`top_container_id`),
  KEY `container_profile_id` (`container_profile_id`),
  CONSTRAINT `top_container_profile_rlshp_ibfk_1` FOREIGN KEY (`top_container_id`) REFERENCES `top_container` (`id`),
  CONSTRAINT `top_container_profile_rlshp_ibfk_2` FOREIGN KEY (`container_profile_id`) REFERENCES `container_profile` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `top_container_profile_rlshp`
--

LOCK TABLES `top_container_profile_rlshp` WRITE;
/*!40000 ALTER TABLE `top_container_profile_rlshp` DISABLE KEYS */;
/*!40000 ALTER TABLE `top_container_profile_rlshp` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `used_language`
--

DROP TABLE IF EXISTS `used_language`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `used_language` (
  `id` int NOT NULL AUTO_INCREMENT,
  `language_id` int DEFAULT NULL,
  `script_id` int DEFAULT NULL,
  `agent_person_id` int DEFAULT NULL,
  `agent_family_id` int DEFAULT NULL,
  `agent_corporate_entity_id` int DEFAULT NULL,
  `agent_software_id` int DEFAULT NULL,
  `created_by` varchar(255) DEFAULT NULL,
  `last_modified_by` varchar(255) DEFAULT NULL,
  `create_time` datetime NOT NULL,
  `system_mtime` datetime NOT NULL,
  `user_mtime` datetime NOT NULL,
  `lock_version` int NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`),
  KEY `language_id` (`language_id`),
  KEY `script_id` (`script_id`),
  KEY `used_language_system_mtime_index` (`system_mtime`),
  KEY `used_language_user_mtime_index` (`user_mtime`),
  KEY `agent_person_id` (`agent_person_id`),
  KEY `agent_family_id` (`agent_family_id`),
  KEY `agent_corporate_entity_id` (`agent_corporate_entity_id`),
  KEY `agent_software_id` (`agent_software_id`),
  CONSTRAINT `used_language_ibfk_1` FOREIGN KEY (`language_id`) REFERENCES `enumeration_value` (`id`),
  CONSTRAINT `used_language_ibfk_2` FOREIGN KEY (`script_id`) REFERENCES `enumeration_value` (`id`),
  CONSTRAINT `used_language_ibfk_3` FOREIGN KEY (`agent_person_id`) REFERENCES `agent_person` (`id`),
  CONSTRAINT `used_language_ibfk_4` FOREIGN KEY (`agent_family_id`) REFERENCES `agent_family` (`id`),
  CONSTRAINT `used_language_ibfk_5` FOREIGN KEY (`agent_corporate_entity_id`) REFERENCES `agent_corporate_entity` (`id`),
  CONSTRAINT `used_language_ibfk_6` FOREIGN KEY (`agent_software_id`) REFERENCES `agent_software` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `used_language`
--

LOCK TABLES `used_language` WRITE;
/*!40000 ALTER TABLE `used_language` DISABLE KEYS */;
/*!40000 ALTER TABLE `used_language` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `user`
--

DROP TABLE IF EXISTS `user`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `user` (
  `id` int NOT NULL AUTO_INCREMENT,
  `lock_version` int NOT NULL DEFAULT '0',
  `json_schema_version` int NOT NULL,
  `username` varchar(255) NOT NULL,
  `name` varchar(255) NOT NULL,
  `source` varchar(255) DEFAULT NULL,
  `agent_record_id` int DEFAULT NULL,
  `agent_record_type` varchar(255) DEFAULT NULL,
  `is_system_user` int NOT NULL DEFAULT '0',
  `is_hidden_user` int NOT NULL DEFAULT '0',
  `email` varchar(255) DEFAULT NULL,
  `first_name` varchar(255) DEFAULT NULL,
  `last_name` varchar(255) DEFAULT NULL,
  `telephone` varchar(255) DEFAULT NULL,
  `title` varchar(255) DEFAULT NULL,
  `department` varchar(255) DEFAULT NULL,
  `additional_contact` text,
  `created_by` varchar(255) DEFAULT NULL,
  `last_modified_by` varchar(255) DEFAULT NULL,
  `create_time` datetime NOT NULL,
  `system_mtime` datetime NOT NULL,
  `user_mtime` datetime NOT NULL,
  `is_active_user` int DEFAULT '1',
  PRIMARY KEY (`id`),
  UNIQUE KEY `username` (`username`),
  KEY `user_system_mtime_index` (`system_mtime`),
  KEY `user_user_mtime_index` (`user_mtime`),
  KEY `agent_record_id` (`agent_record_id`),
  CONSTRAINT `user_ibfk_1` FOREIGN KEY (`agent_record_id`) REFERENCES `agent_person` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `user`
--

LOCK TABLES `user` WRITE;
/*!40000 ALTER TABLE `user` DISABLE KEYS */;
/*!40000 ALTER TABLE `user` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `user_defined`
--

DROP TABLE IF EXISTS `user_defined`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `user_defined` (
  `id` int NOT NULL AUTO_INCREMENT,
  `lock_version` int NOT NULL DEFAULT '0',
  `json_schema_version` int NOT NULL,
  `accession_id` int DEFAULT NULL,
  `resource_id` int DEFAULT NULL,
  `digital_object_id` int DEFAULT NULL,
  `boolean_1` int DEFAULT NULL,
  `boolean_2` int DEFAULT NULL,
  `boolean_3` int DEFAULT NULL,
  `integer_1` varchar(255) DEFAULT NULL,
  `integer_2` varchar(255) DEFAULT NULL,
  `integer_3` varchar(255) DEFAULT NULL,
  `real_1` varchar(255) DEFAULT NULL,
  `real_2` varchar(255) DEFAULT NULL,
  `real_3` varchar(255) DEFAULT NULL,
  `string_1` varchar(255) DEFAULT NULL,
  `string_2` varchar(255) DEFAULT NULL,
  `string_3` varchar(255) DEFAULT NULL,
  `string_4` varchar(255) DEFAULT NULL,
  `text_1` text,
  `text_2` text,
  `text_3` text,
  `text_4` text,
  `text_5` text,
  `date_1` date DEFAULT NULL,
  `date_2` date DEFAULT NULL,
  `date_3` date DEFAULT NULL,
  `created_by` varchar(255) DEFAULT NULL,
  `last_modified_by` varchar(255) DEFAULT NULL,
  `create_time` datetime NOT NULL,
  `system_mtime` datetime NOT NULL,
  `user_mtime` datetime NOT NULL,
  `enum_1_id` int DEFAULT NULL,
  `enum_2_id` int DEFAULT NULL,
  `enum_3_id` int DEFAULT NULL,
  `enum_4_id` int DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `user_defined_system_mtime_index` (`system_mtime`),
  KEY `user_defined_user_mtime_index` (`user_mtime`),
  KEY `accession_id` (`accession_id`),
  KEY `resource_id` (`resource_id`),
  KEY `digital_object_id` (`digital_object_id`),
  KEY `enum_1_id` (`enum_1_id`),
  KEY `enum_2_id` (`enum_2_id`),
  KEY `enum_3_id` (`enum_3_id`),
  KEY `enum_4_id` (`enum_4_id`),
  CONSTRAINT `user_defined_ibfk_1` FOREIGN KEY (`accession_id`) REFERENCES `accession` (`id`),
  CONSTRAINT `user_defined_ibfk_2` FOREIGN KEY (`resource_id`) REFERENCES `resource` (`id`),
  CONSTRAINT `user_defined_ibfk_3` FOREIGN KEY (`digital_object_id`) REFERENCES `digital_object` (`id`),
  CONSTRAINT `user_defined_ibfk_4` FOREIGN KEY (`enum_1_id`) REFERENCES `enumeration_value` (`id`),
  CONSTRAINT `user_defined_ibfk_5` FOREIGN KEY (`enum_2_id`) REFERENCES `enumeration_value` (`id`),
  CONSTRAINT `user_defined_ibfk_6` FOREIGN KEY (`enum_3_id`) REFERENCES `enumeration_value` (`id`),
  CONSTRAINT `user_defined_ibfk_7` FOREIGN KEY (`enum_4_id`) REFERENCES `enumeration_value` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `user_defined`
--

LOCK TABLES `user_defined` WRITE;
/*!40000 ALTER TABLE `user_defined` DISABLE KEYS */;
/*!40000 ALTER TABLE `user_defined` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `vocabulary`
--

DROP TABLE IF EXISTS `vocabulary`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `vocabulary` (
  `id` int NOT NULL AUTO_INCREMENT,
  `lock_version` int NOT NULL DEFAULT '0',
  `name` varchar(255) NOT NULL,
  `ref_id` varchar(255) NOT NULL,
  `created_by` varchar(255) DEFAULT NULL,
  `last_modified_by` varchar(255) DEFAULT NULL,
  `create_time` datetime NOT NULL,
  `system_mtime` datetime NOT NULL,
  `user_mtime` datetime NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `name` (`name`),
  UNIQUE KEY `ref_id` (`ref_id`),
  KEY `vocabulary_system_mtime_index` (`system_mtime`),
  KEY `vocabulary_user_mtime_index` (`user_mtime`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb3;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `vocabulary`
--

LOCK TABLES `vocabulary` WRITE;
/*!40000 ALTER TABLE `vocabulary` DISABLE KEYS */;
INSERT INTO `vocabulary` VALUES (1,0,'global','global',NULL,NULL,'2024-04-18 15:42:07','2024-04-18 15:46:13','2024-04-18 15:42:07');
/*!40000 ALTER TABLE `vocabulary` ENABLE KEYS */;
UNLOCK TABLES;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2024-04-18 19:32:46
