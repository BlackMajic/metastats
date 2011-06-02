-- MySQL dump 10.11
--
-- Host: localhost    Database: metastats
-- ------------------------------------------------------
-- Server version	5.0.45

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `ms_core_clantags`
--

DROP TABLE IF EXISTS `ms_core_clantags`;
CREATE TABLE `ms_core_clantags` (
  `id` int(10) unsigned NOT NULL auto_increment,
  `pattern` varchar(64) collate utf8_unicode_ci NOT NULL,
  `position` enum('EITHER','START','END') collate utf8_unicode_ci NOT NULL default 'EITHER',
  PRIMARY KEY  (`id`),
  UNIQUE KEY `pattern` (`pattern`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

--
-- Dumping data for table `ms_core_clantags`
--

LOCK TABLES `ms_core_clantags` WRITE;
/*!40000 ALTER TABLE `ms_core_clantags` DISABLE KEYS */;
/*!40000 ALTER TABLE `ms_core_clantags` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `ms_core_config`
--

DROP TABLE IF EXISTS `ms_core_config`;
CREATE TABLE `ms_core_config` (
  `ext` varchar(32) collate utf8_unicode_ci NOT NULL default 'core',
  `keyname` varchar(32) collate utf8_unicode_ci NOT NULL,
  `value` varchar(128) collate utf8_unicode_ci NOT NULL,
  PRIMARY KEY  (`ext`,`keyname`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

--
-- Dumping data for table `ms_core_config`
--

LOCK TABLES `ms_core_config` WRITE;
/*!40000 ALTER TABLE `ms_core_config` DISABLE KEYS */;
INSERT INTO `ms_core_config` VALUES ('core','Mode','normal'),('core','UseTimestamp','0'),('core','LogLevel','6'),('core','LogEcho','1'),('core','LogCloneDir','./logClone'),('core','LogForward',''),('core','CrashReport','./crash.txt'),('core','CrashNotify','example@example.com'),('core','Update','skip'),('core','Learn','1');
/*!40000 ALTER TABLE `ms_core_config` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `ms_core_extensions`
--

DROP TABLE IF EXISTS `ms_core_extensions`;
CREATE TABLE `ms_core_extensions` (
  `module` varchar(16) collate utf8_unicode_ci NOT NULL,
  `ext_short` varchar(16) collate utf8_unicode_ci NOT NULL,
  `ext_long` varchar(255) collate utf8_unicode_ci NOT NULL,
  KEY `ext_short` (`ext_short`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

--
-- Dumping data for table `ms_core_extensions`
--

LOCK TABLES `ms_core_extensions` WRITE;
/*!40000 ALTER TABLE `ms_core_extensions` DISABLE KEYS */;
INSERT INTO `ms_core_extensions` VALUES ('halflife','tfc','Team Fortress Classic'),('halflife','cstrike','Counter-Strike'),('halflife2','ctf','Capture the Flag');
/*!40000 ALTER TABLE `ms_core_extensions` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `ms_core_hostgroups`
--

DROP TABLE IF EXISTS `ms_core_hostgroups`;
CREATE TABLE `ms_core_hostgroups` (
  `id` int(10) unsigned NOT NULL auto_increment,
  `pattern` varchar(128) collate utf8_unicode_ci NOT NULL,
  `name` varchar(128) collate utf8_unicode_ci NOT NULL,
  PRIMARY KEY  (`id`)
) ENGINE=MyISAM AUTO_INCREMENT=2 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

--
-- Dumping data for table `ms_core_hostgroups`
--

LOCK TABLES `ms_core_hostgroups` WRITE;
/*!40000 ALTER TABLE `ms_core_hostgroups` DISABLE KEYS */;
/*!40000 ALTER TABLE `ms_core_hostgroups` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `ms_core_modules`
--

DROP TABLE IF EXISTS `ms_core_modules`;
CREATE TABLE `ms_core_modules` (
  `mod_short` varchar(16) collate utf8_unicode_ci NOT NULL,
  `mod_long` varchar(255) collate utf8_unicode_ci NOT NULL,
  PRIMARY KEY  (`mod_short`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

--
-- Dumping data for table `ms_core_modules`
--

LOCK TABLES `ms_core_modules` WRITE;
/*!40000 ALTER TABLE `ms_core_modules` DISABLE KEYS */;
INSERT INTO `ms_core_modules` VALUES ('halflife','Half-Life'),('halflife2','Half-Life 2'),('doom3','DOOM 3');
/*!40000 ALTER TABLE `ms_core_modules` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `ms_core_servers`
--

DROP TABLE IF EXISTS `ms_core_servers`;
CREATE TABLE `ms_core_servers` (
  `server_id` tinyint(3) unsigned NOT NULL auto_increment,
  `server_mod` varchar(16) collate utf8_unicode_ci NOT NULL,
  `server_ext` varchar(16) collate utf8_unicode_ci NOT NULL,
  `server_ip` varchar(15) collate utf8_unicode_ci NOT NULL,
  `server_port` smallint(5) unsigned NOT NULL default '0',
  `server_publicip` varchar(64) collate utf8_unicode_ci NOT NULL,
  `server_name` varchar(128) collate utf8_unicode_ci NOT NULL,
  `server_rcon` varchar(48) collate utf8_unicode_ci NOT NULL,
  `server_feedback` enum('0','1') collate utf8_unicode_ci NOT NULL default '0',
  `server_hidden` enum('0','1') collate utf8_unicode_ci NOT NULL default '0',
  PRIMARY KEY  (`server_id`)
) ENGINE=MyISAM AUTO_INCREMENT=2 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

--
-- Dumping data for table `ms_core_servers`
--

LOCK TABLES `ms_core_servers` WRITE;
/*!40000 ALTER TABLE `ms_core_servers` DISABLE KEYS */;
/*!40000 ALTER TABLE `ms_core_servers` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `ms_halflife_actions`
--

DROP TABLE IF EXISTS `ms_halflife_actions`;
CREATE TABLE `ms_halflife_actions` (
  `id` int(10) unsigned NOT NULL auto_increment,
  `module` smallint(5) unsigned NOT NULL default '0',
  `code` varchar(64) collate utf8_unicode_ci NOT NULL,
  `reward_player` int(10) NOT NULL default '10',
  `reward_team` int(10) NOT NULL default '0',
  `team` varchar(32) collate utf8_unicode_ci NOT NULL,
  `description` varchar(128) collate utf8_unicode_ci default NULL,
  `for_player_actions` tinyint(1) unsigned NOT NULL default '0',
  `for_player_player_actions` tinyint(1) unsigned NOT NULL default '0',
  `for_team_actions` tinyint(1) unsigned NOT NULL default '0',
  `for_world_actions` tinyint(1) unsigned NOT NULL default '0',
  PRIMARY KEY  (`id`),
  UNIQUE KEY `gamecode` (`module`,`code`),
  KEY `code` (`code`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

--
-- Dumping data for table `ms_halflife_actions`
--

LOCK TABLES `ms_halflife_actions` WRITE;
/*!40000 ALTER TABLE `ms_halflife_actions` DISABLE KEYS */;
/*!40000 ALTER TABLE `ms_halflife_actions` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `ms_halflife_awards`
--

DROP TABLE IF EXISTS `ms_halflife_awards`;
CREATE TABLE `ms_halflife_awards` (
  `award_id` int(10) unsigned NOT NULL auto_increment,
  `award_type` enum('W','O') collate utf8_unicode_ci NOT NULL default 'W',
  `game` varchar(32) collate utf8_unicode_ci NOT NULL default 'valve',
  `code` varchar(128) collate utf8_unicode_ci NOT NULL,
  `name` varchar(128) collate utf8_unicode_ci NOT NULL,
  `verb` varchar(64) collate utf8_unicode_ci NOT NULL,
  `d_winner_id` int(10) unsigned default NULL,
  `d_winner_count` int(10) unsigned default NULL,
  PRIMARY KEY  (`award_id`),
  UNIQUE KEY `code` (`game`,`award_type`,`code`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

--
-- Dumping data for table `ms_halflife_awards`
--

LOCK TABLES `ms_halflife_awards` WRITE;
/*!40000 ALTER TABLE `ms_halflife_awards` DISABLE KEYS */;
/*!40000 ALTER TABLE `ms_halflife_awards` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `ms_halflife_clans`
--

DROP TABLE IF EXISTS `ms_halflife_clans`;
CREATE TABLE `ms_halflife_clans` (
  `clan_id` int(10) unsigned NOT NULL auto_increment,
  `tag` varchar(32) collate utf8_unicode_ci NOT NULL,
  `name` varchar(128) collate utf8_unicode_ci NOT NULL,
  `homepage` varchar(64) collate utf8_unicode_ci NOT NULL,
  `module` smallint(5) unsigned NOT NULL default '0',
  PRIMARY KEY  (`clan_id`),
  UNIQUE KEY `tag` (`module`,`tag`),
  KEY `game` (`module`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

--
-- Dumping data for table `ms_halflife_clans`
--

LOCK TABLES `ms_halflife_clans` WRITE;
/*!40000 ALTER TABLE `ms_halflife_clans` DISABLE KEYS */;
/*!40000 ALTER TABLE `ms_halflife_clans` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `ms_halflife_events_admin`
--

DROP TABLE IF EXISTS `ms_halflife_events_admin`;
CREATE TABLE `ms_halflife_events_admin` (
  `id` int(10) unsigned NOT NULL auto_increment,
  `event_time` int(10) unsigned NOT NULL default '0',
  `server_id` int(10) unsigned NOT NULL default '0',
  `map` varchar(32) collate utf8_unicode_ci NOT NULL,
  `type` varchar(32) collate utf8_unicode_ci NOT NULL default 'Unknown',
  `message` varchar(128) collate utf8_unicode_ci NOT NULL,
  `player_name` varchar(128) collate utf8_unicode_ci NOT NULL,
  PRIMARY KEY  (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

--
-- Dumping data for table `ms_halflife_events_admin`
--

LOCK TABLES `ms_halflife_events_admin` WRITE;
/*!40000 ALTER TABLE `ms_halflife_events_admin` DISABLE KEYS */;
/*!40000 ALTER TABLE `ms_halflife_events_admin` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `ms_halflife_events_changename`
--

DROP TABLE IF EXISTS `ms_halflife_events_changename`;
CREATE TABLE `ms_halflife_events_changename` (
  `id` int(10) unsigned NOT NULL auto_increment,
  `event_time` int(10) unsigned NOT NULL default '0',
  `server_id` int(10) unsigned NOT NULL default '0',
  `map` varchar(20) collate utf8_unicode_ci NOT NULL,
  `player_id` int(10) unsigned NOT NULL default '0',
  `old_name` varchar(64) collate utf8_unicode_ci NOT NULL,
  `new_name` varchar(64) collate utf8_unicode_ci NOT NULL,
  PRIMARY KEY  (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

--
-- Dumping data for table `ms_halflife_events_changename`
--

LOCK TABLES `ms_halflife_events_changename` WRITE;
/*!40000 ALTER TABLE `ms_halflife_events_changename` DISABLE KEYS */;
/*!40000 ALTER TABLE `ms_halflife_events_changename` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `ms_halflife_events_changerole`
--

DROP TABLE IF EXISTS `ms_halflife_events_changerole`;
CREATE TABLE `ms_halflife_events_changerole` (
  `id` int(10) unsigned NOT NULL auto_increment,
  `event_time` int(10) unsigned NOT NULL default '0',
  `server_id` int(10) unsigned NOT NULL default '0',
  `map` varchar(20) collate utf8_unicode_ci NOT NULL,
  `player_id` int(10) unsigned NOT NULL default '0',
  `role` varchar(32) collate utf8_unicode_ci NOT NULL,
  PRIMARY KEY  (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

--
-- Dumping data for table `ms_halflife_events_changerole`
--

LOCK TABLES `ms_halflife_events_changerole` WRITE;
/*!40000 ALTER TABLE `ms_halflife_events_changerole` DISABLE KEYS */;
/*!40000 ALTER TABLE `ms_halflife_events_changerole` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `ms_halflife_events_changeteam`
--

DROP TABLE IF EXISTS `ms_halflife_events_changeteam`;
CREATE TABLE `ms_halflife_events_changeteam` (
  `id` int(10) unsigned NOT NULL auto_increment,
  `event_time` int(10) unsigned NOT NULL default '0',
  `server_id` int(10) unsigned NOT NULL default '0',
  `map` varchar(20) collate utf8_unicode_ci NOT NULL,
  `player_id` int(10) unsigned NOT NULL default '0',
  `team` varchar(32) collate utf8_unicode_ci NOT NULL,
  PRIMARY KEY  (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

--
-- Dumping data for table `ms_halflife_events_changeteam`
--

LOCK TABLES `ms_halflife_events_changeteam` WRITE;
/*!40000 ALTER TABLE `ms_halflife_events_changeteam` DISABLE KEYS */;
/*!40000 ALTER TABLE `ms_halflife_events_changeteam` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `ms_halflife_events_connects`
--

DROP TABLE IF EXISTS `ms_halflife_events_connects`;
CREATE TABLE `ms_halflife_events_connects` (
  `id` int(10) unsigned NOT NULL auto_increment,
  `event_time` int(10) unsigned NOT NULL default '0',
  `server_id` int(10) unsigned NOT NULL default '0',
  `map` varchar(32) collate utf8_unicode_ci NOT NULL,
  `player_id` int(10) unsigned NOT NULL default '0',
  `ip` varchar(15) collate utf8_unicode_ci NOT NULL,
  `hostname` varchar(128) collate utf8_unicode_ci NOT NULL,
  `hostgroup` varchar(128) collate utf8_unicode_ci NOT NULL,
  PRIMARY KEY  (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

--
-- Dumping data for table `ms_halflife_events_connects`
--

LOCK TABLES `ms_halflife_events_connects` WRITE;
/*!40000 ALTER TABLE `ms_halflife_events_connects` DISABLE KEYS */;
/*!40000 ALTER TABLE `ms_halflife_events_connects` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `ms_halflife_events_disconnects`
--

DROP TABLE IF EXISTS `ms_halflife_events_disconnects`;
CREATE TABLE `ms_halflife_events_disconnects` (
  `id` int(10) unsigned NOT NULL auto_increment,
  `event_time` int(10) NOT NULL default '0',
  `server_id` int(10) unsigned NOT NULL default '0',
  `map` varchar(20) collate utf8_unicode_ci NOT NULL,
  `player_id` int(10) unsigned NOT NULL default '0',
  PRIMARY KEY  (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

--
-- Dumping data for table `ms_halflife_events_disconnects`
--

LOCK TABLES `ms_halflife_events_disconnects` WRITE;
/*!40000 ALTER TABLE `ms_halflife_events_disconnects` DISABLE KEYS */;
/*!40000 ALTER TABLE `ms_halflife_events_disconnects` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `ms_halflife_events_entries`
--

DROP TABLE IF EXISTS `ms_halflife_events_entries`;
CREATE TABLE `ms_halflife_events_entries` (
  `id` int(10) unsigned NOT NULL auto_increment,
  `event_time` int(10) unsigned NOT NULL default '0',
  `server_id` int(10) unsigned NOT NULL default '0',
  `map` varchar(20) collate utf8_unicode_ci NOT NULL,
  `player_id` int(10) unsigned NOT NULL default '0',
  PRIMARY KEY  (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

--
-- Dumping data for table `ms_halflife_events_entries`
--

LOCK TABLES `ms_halflife_events_entries` WRITE;
/*!40000 ALTER TABLE `ms_halflife_events_entries` DISABLE KEYS */;
/*!40000 ALTER TABLE `ms_halflife_events_entries` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `ms_halflife_events_frags`
--

DROP TABLE IF EXISTS `ms_halflife_events_frags`;
CREATE TABLE `ms_halflife_events_frags` (
  `id` int(10) unsigned NOT NULL auto_increment,
  `event_time` int(10) unsigned NOT NULL default '0',
  `server_id` int(10) unsigned NOT NULL default '0',
  `map` varchar(20) collate utf8_unicode_ci NOT NULL,
  `killer_id` int(10) unsigned NOT NULL default '0',
  `victim_id` int(10) unsigned NOT NULL default '0',
  `weapon` varchar(20) collate utf8_unicode_ci NOT NULL,
  PRIMARY KEY  (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

--
-- Dumping data for table `ms_halflife_events_frags`
--

LOCK TABLES `ms_halflife_events_frags` WRITE;
/*!40000 ALTER TABLE `ms_halflife_events_frags` DISABLE KEYS */;
/*!40000 ALTER TABLE `ms_halflife_events_frags` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `ms_halflife_events_playeractions`
--

DROP TABLE IF EXISTS `ms_halflife_events_playeractions`;
CREATE TABLE `ms_halflife_events_playeractions` (
  `id` int(10) unsigned NOT NULL auto_increment,
  `event_time` int(10) unsigned NOT NULL default '0',
  `server_id` int(10) unsigned NOT NULL default '0',
  `map` varchar(20) collate utf8_unicode_ci NOT NULL,
  `player_id` int(10) unsigned NOT NULL default '0',
  `action_id` int(10) unsigned NOT NULL default '0',
  `bonus` int(10) NOT NULL default '0',
  PRIMARY KEY  (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

--
-- Dumping data for table `ms_halflife_events_playeractions`
--

LOCK TABLES `ms_halflife_events_playeractions` WRITE;
/*!40000 ALTER TABLE `ms_halflife_events_playeractions` DISABLE KEYS */;
/*!40000 ALTER TABLE `ms_halflife_events_playeractions` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `ms_halflife_events_playerplayeractions`
--

DROP TABLE IF EXISTS `ms_halflife_events_playerplayeractions`;
CREATE TABLE `ms_halflife_events_playerplayeractions` (
  `id` int(10) unsigned NOT NULL auto_increment,
  `event_time` int(10) unsigned NOT NULL default '0',
  `server_id` int(10) unsigned NOT NULL default '0',
  `map` varchar(20) collate utf8_unicode_ci NOT NULL,
  `player_id` int(10) unsigned NOT NULL default '0',
  `victim_id` int(10) unsigned NOT NULL default '0',
  `action_id` int(10) unsigned NOT NULL default '0',
  `bonus` int(10) NOT NULL default '0',
  PRIMARY KEY  (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

--
-- Dumping data for table `ms_halflife_events_playerplayeractions`
--

LOCK TABLES `ms_halflife_events_playerplayeractions` WRITE;
/*!40000 ALTER TABLE `ms_halflife_events_playerplayeractions` DISABLE KEYS */;
/*!40000 ALTER TABLE `ms_halflife_events_playerplayeractions` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `ms_halflife_events_rcon`
--

DROP TABLE IF EXISTS `ms_halflife_events_rcon`;
CREATE TABLE `ms_halflife_events_rcon` (
  `id` int(10) unsigned NOT NULL auto_increment,
  `event_time` int(10) unsigned NOT NULL default '0',
  `server_id` int(10) unsigned NOT NULL default '0',
  `map` varchar(32) collate utf8_unicode_ci NOT NULL,
  `type` varchar(8) collate utf8_unicode_ci NOT NULL default 'Bad Rcon',
  `remote_ip` varchar(15) collate utf8_unicode_ci NOT NULL,
  `password` varchar(32) collate utf8_unicode_ci NOT NULL,
  `command` varchar(128) collate utf8_unicode_ci NOT NULL,
  PRIMARY KEY  (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

--
-- Dumping data for table `ms_halflife_events_rcon`
--

LOCK TABLES `ms_halflife_events_rcon` WRITE;
/*!40000 ALTER TABLE `ms_halflife_events_rcon` DISABLE KEYS */;
/*!40000 ALTER TABLE `ms_halflife_events_rcon` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `ms_halflife_events_suicides`
--

DROP TABLE IF EXISTS `ms_halflife_events_suicides`;
CREATE TABLE `ms_halflife_events_suicides` (
  `id` int(10) unsigned NOT NULL auto_increment,
  `event_time` int(10) unsigned NOT NULL default '0',
  `server_id` int(10) unsigned NOT NULL default '0',
  `map` varchar(20) collate utf8_unicode_ci NOT NULL,
  `player_id` int(10) unsigned NOT NULL default '0',
  `weapon` varchar(20) collate utf8_unicode_ci NOT NULL,
  PRIMARY KEY  (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

--
-- Dumping data for table `ms_halflife_events_suicides`
--

LOCK TABLES `ms_halflife_events_suicides` WRITE;
/*!40000 ALTER TABLE `ms_halflife_events_suicides` DISABLE KEYS */;
/*!40000 ALTER TABLE `ms_halflife_events_suicides` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `ms_halflife_events_teambonuses`
--

DROP TABLE IF EXISTS `ms_halflife_events_teambonuses`;
CREATE TABLE `ms_halflife_events_teambonuses` (
  `id` int(10) unsigned NOT NULL auto_increment,
  `event_time` int(10) unsigned NOT NULL default '0',
  `serverId` int(10) unsigned NOT NULL default '0',
  `map` varchar(32) collate utf8_unicode_ci NOT NULL,
  `player_id` int(10) unsigned NOT NULL default '0',
  `action_id` int(10) unsigned NOT NULL default '0',
  `bonus` int(10) NOT NULL default '0',
  PRIMARY KEY  (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

--
-- Dumping data for table `ms_halflife_events_teambonuses`
--

LOCK TABLES `ms_halflife_events_teambonuses` WRITE;
/*!40000 ALTER TABLE `ms_halflife_events_teambonuses` DISABLE KEYS */;
/*!40000 ALTER TABLE `ms_halflife_events_teambonuses` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `ms_halflife_events_teamkills`
--

DROP TABLE IF EXISTS `ms_halflife_events_teamkills`;
CREATE TABLE `ms_halflife_events_teamkills` (
  `id` int(10) unsigned NOT NULL auto_increment,
  `event_time` int(10) unsigned NOT NULL default '0',
  `server_id` int(10) unsigned NOT NULL default '0',
  `map` varchar(20) collate utf8_unicode_ci NOT NULL,
  `killer_id` int(10) unsigned NOT NULL default '0',
  `victim_Id` int(10) unsigned NOT NULL default '0',
  `weapon` varchar(20) collate utf8_unicode_ci NOT NULL,
  PRIMARY KEY  (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

--
-- Dumping data for table `ms_halflife_events_teamkills`
--

LOCK TABLES `ms_halflife_events_teamkills` WRITE;
/*!40000 ALTER TABLE `ms_halflife_events_teamkills` DISABLE KEYS */;
/*!40000 ALTER TABLE `ms_halflife_events_teamkills` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `ms_halflife_playerinfo`
--

DROP TABLE IF EXISTS `ms_halflife_playerinfo`;
CREATE TABLE `ms_halflife_playerinfo` (
  `id` int(10) unsigned NOT NULL,
  `keyname` varchar(24) collate utf8_unicode_ci NOT NULL,
  `value` varchar(128) collate utf8_unicode_ci NOT NULL,
  KEY `id` (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

--
-- Dumping data for table `ms_halflife_playerinfo`
--

LOCK TABLES `ms_halflife_playerinfo` WRITE;
/*!40000 ALTER TABLE `ms_halflife_playerinfo` DISABLE KEYS */;
/*!40000 ALTER TABLE `ms_halflife_playerinfo` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `ms_halflife_playernames`
--

DROP TABLE IF EXISTS `ms_halflife_playernames`;
CREATE TABLE `ms_halflife_playernames` (
  `player_id` int(10) unsigned NOT NULL default '0',
  `name` varchar(64) collate utf8_unicode_ci NOT NULL,
  `lastuse` int(10) unsigned NOT NULL default '0',
  `numuses` int(10) unsigned NOT NULL default '0',
  `kills` int(10) NOT NULL default '0',
  `deaths` int(10) NOT NULL default '0',
  `suicides` int(10) NOT NULL default '0',
  PRIMARY KEY  (`player_id`,`name`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

--
-- Dumping data for table `ms_halflife_playernames`
--

LOCK TABLES `ms_halflife_playernames` WRITE;
/*!40000 ALTER TABLE `ms_halflife_playernames` DISABLE KEYS */;
/*!40000 ALTER TABLE `ms_halflife_playernames` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `ms_halflife_players`
--

DROP TABLE IF EXISTS `ms_halflife_players`;
CREATE TABLE `ms_halflife_players` (
  `id` int(10) unsigned NOT NULL auto_increment,
  `last_name` varchar(64) collate utf8_unicode_ci NOT NULL,
  `clan` int(10) unsigned NOT NULL default '0',
  `kills` int(10) NOT NULL default '0',
  `deaths` int(10) NOT NULL default '0',
  `suicides` int(10) NOT NULL default '0',
  `skill` int(10) NOT NULL default '1000',
  `module` smallint(5) unsigned NOT NULL default '0',
  `hideranking` tinyint(1) unsigned NOT NULL default '0',
  PRIMARY KEY  (`id`),
  KEY `clan` (`clan`),
  KEY `game` (`module`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

--
-- Dumping data for table `ms_halflife_players`
--

LOCK TABLES `ms_halflife_players` WRITE;
/*!40000 ALTER TABLE `ms_halflife_players` DISABLE KEYS */;
/*!40000 ALTER TABLE `ms_halflife_players` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `ms_halflife_playeruniqueids`
--

DROP TABLE IF EXISTS `ms_halflife_playeruniqueids`;
CREATE TABLE `ms_halflife_playeruniqueids` (
  `player_id` int(10) unsigned NOT NULL default '0',
  `unique_id` varchar(64) collate utf8_unicode_ci NOT NULL,
  `module` varchar(16) collate utf8_unicode_ci NOT NULL,
  `merge` int(10) unsigned default NULL,
  PRIMARY KEY  (`unique_id`),
  KEY `mod` (`module`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

--
-- Dumping data for table `ms_halflife_playeruniqueids`
--

LOCK TABLES `ms_halflife_playeruniqueids` WRITE;
/*!40000 ALTER TABLE `ms_halflife_playeruniqueids` DISABLE KEYS */;
/*!40000 ALTER TABLE `ms_halflife_playeruniqueids` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `ms_halflife_roles`
--

DROP TABLE IF EXISTS `ms_halflife_roles`;
CREATE TABLE `ms_halflife_roles` (
  `role_id` int(10) unsigned NOT NULL auto_increment,
  `module` smallint(5) unsigned NOT NULL default '0',
  `code` varchar(32) collate utf8_unicode_ci NOT NULL,
  `name` varchar(64) collate utf8_unicode_ci NOT NULL,
  `hidden` tinyint(1) unsigned NOT NULL default '0',
  PRIMARY KEY  (`role_id`),
  UNIQUE KEY `gamecode` (`module`,`code`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

--
-- Dumping data for table `ms_halflife_roles`
--

LOCK TABLES `ms_halflife_roles` WRITE;
/*!40000 ALTER TABLE `ms_halflife_roles` DISABLE KEYS */;
/*!40000 ALTER TABLE `ms_halflife_roles` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `ms_halflife_teams`
--

DROP TABLE IF EXISTS `ms_halflife_teams`;
CREATE TABLE `ms_halflife_teams` (
  `team_id` int(10) unsigned NOT NULL auto_increment,
  `module` smallint(5) unsigned NOT NULL default '0',
  `code` varchar(32) collate utf8_unicode_ci NOT NULL,
  `name` varchar(64) collate utf8_unicode_ci NOT NULL,
  `hidden` tinyint(1) unsigned NOT NULL default '0',
  PRIMARY KEY  (`team_id`),
  UNIQUE KEY `gamecode` (`module`,`code`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

--
-- Dumping data for table `ms_halflife_teams`
--

LOCK TABLES `ms_halflife_teams` WRITE;
/*!40000 ALTER TABLE `ms_halflife_teams` DISABLE KEYS */;
/*!40000 ALTER TABLE `ms_halflife_teams` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `ms_halflife_weapons`
--

DROP TABLE IF EXISTS `ms_halflife_weapons`;
CREATE TABLE `ms_halflife_weapons` (
  `weapon_id` int(10) unsigned NOT NULL auto_increment,
  `module` smallint(5) unsigned NOT NULL default '0',
  `code` varchar(32) collate utf8_unicode_ci NOT NULL,
  `name` varchar(64) collate utf8_unicode_ci NOT NULL,
  `modifier` float(10,2) NOT NULL default '1.00',
  PRIMARY KEY  (`weapon_id`),
  UNIQUE KEY `gamecode` (`module`,`code`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

--
-- Dumping data for table `ms_halflife_weapons`
--

LOCK TABLES `ms_halflife_weapons` WRITE;
/*!40000 ALTER TABLE `ms_halflife_weapons` DISABLE KEYS */;
/*!40000 ALTER TABLE `ms_halflife_weapons` ENABLE KEYS */;
UNLOCK TABLES;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2011-06-02  4:21:39
