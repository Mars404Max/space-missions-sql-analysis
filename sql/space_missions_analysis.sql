/*
===============================================================================
ABSCHLUSSPROJEKT – DATENBANKEN UND SQL
Projekt B: Analyse historischer Raumfahrtmissionen (1957–2022)

ZIEL:
1. Entwicklung der Raumfahrtaktivität im Zeitverlauf untersuchen.
2. Organisationen und Raketen nach Aktivität und Zuverlässigkeit vergleichen.
3. Startorte analysieren.
4. Datenqualität und Grenzen des Datensatzes sichtbar machen.

DATEN:
Maven Analytics – Space Missions
Ursprungsquelle: Next Spaceflight

HINWEIS:
Der Dateipfad im LOAD DATA-Befehl muss zum eigenen Mac passen.
===============================================================================
*/

-- ===========================================================================
-- 1. DATENBANK ERSTELLEN
-- ===========================================================================

DROP DATABASE IF EXISTS space_missions_project;

CREATE DATABASE space_missions_project
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

USE space_missions_project;


-- ===========================================================================
-- 2. RAW-TABELLE
-- CSV wird zuerst möglichst unverändert importiert.
-- Problematische Felder bleiben zunächst VARCHAR.
-- ===========================================================================

CREATE TABLE space_missions_raw (
    raw_id INT AUTO_INCREMENT PRIMARY KEY,
    company VARCHAR(120),
    location VARCHAR(300),
    launch_date_raw VARCHAR(20),
    launch_time_raw VARCHAR(20),
    rocket VARCHAR(180),
    mission VARCHAR(300),
    rocket_status VARCHAR(30),
    price_raw VARCHAR(50),
    mission_status VARCHAR(40)
);


-- ===========================================================================
-- 3. CSV IMPORTIEREN
-- ===========================================================================

LOAD DATA LOCAL INFILE '/Users/mars404/Downloads/space_missions.csv'
INTO TABLE space_missions_raw
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(
    @company,
    @location,
    @date,
    @time,
    @rocket,
    @mission,
    @rocket_status,
    @price,
    @mission_status
)
SET
    company         = NULLIF(TRIM(@company), ''),
    location        = NULLIF(TRIM(@location), ''),
    launch_date_raw = NULLIF(TRIM(@date), ''),
    launch_time_raw = NULLIF(TRIM(@time), ''),
    rocket          = NULLIF(TRIM(@rocket), ''),
    mission         = NULLIF(TRIM(@mission), ''),
    rocket_status   = NULLIF(TRIM(@rocket_status), ''),
    price_raw       = NULLIF(TRIM(@price), ''),
    mission_status  = NULLIF(TRIM(TRAILING '\r' FROM TRIM(@mission_status)), '');


-- Kontrolle: Im Rohdatensatz werden 4.630 Zeilen erwartet.
SELECT COUNT(*) AS raw_rows
FROM space_missions_raw;


-- ===========================================================================
-- 4. DATENQUALITÄT PRÜFEN
-- ===========================================================================

-- 4.1 Fehlende Werte
SELECT
    COUNT(*) AS total_rows,
    SUM(company IS NULL) AS missing_company,
    SUM(location IS NULL) AS missing_location,
    SUM(launch_date_raw IS NULL) AS missing_date,
    SUM(launch_time_raw IS NULL) AS missing_time,
    SUM(rocket IS NULL) AS missing_rocket,
    SUM(mission IS NULL) AS missing_mission,
    SUM(rocket_status IS NULL) AS missing_rocket_status,
    SUM(price_raw IS NULL) AS missing_price,
    SUM(mission_status IS NULL) AS missing_mission_status
FROM space_missions_raw;

-- Erwartete wichtige Werte:
-- missing_time  = 127
-- missing_price = 3365  (~72,7 %)


-- 4.2 Vollständige Duplikate
SELECT
    company,
    location,
    launch_date_raw,
    launch_time_raw,
    rocket,
    mission,
    rocket_status,
    price_raw,
    mission_status,
    COUNT(*) AS duplicate_count
FROM space_missions_raw
GROUP BY
    company,
    location,
    launch_date_raw,
    launch_time_raw,
    rocket,
    mission,
    rocket_status,
    price_raw,
    mission_status
HAVING COUNT(*) > 1;


-- 4.3 Kategorien kontrollieren
SELECT
    mission_status,
    COUNT(*) AS amount
FROM space_missions_raw
GROUP BY mission_status
ORDER BY amount DESC;

SELECT
    rocket_status,
    COUNT(*) AS amount
FROM space_missions_raw
GROUP BY rocket_status
ORDER BY amount DESC;


-- ===========================================================================
-- 5. CLEAN-TABELLE
-- Jetzt werden passende Datentypen verwendet.
-- ===========================================================================

CREATE TABLE space_missions_clean (
    clean_id INT AUTO_INCREMENT PRIMARY KEY,
    company VARCHAR(120) NOT NULL,
    location VARCHAR(300) NOT NULL,
    launch_date DATE NOT NULL,
    launch_time TIME NULL,
    rocket VARCHAR(180) NOT NULL,
    mission VARCHAR(300) NOT NULL,
    rocket_status VARCHAR(30) NOT NULL,
    price_musd DECIMAL(12,2) NULL,
    mission_status VARCHAR(40) NOT NULL
);


-- RAW -> CLEAN
-- DISTINCT entfernt das vollständige Duplikat.
INSERT INTO space_missions_clean (
    company,
    location,
    launch_date,
    launch_time,
    rocket,
    mission,
    rocket_status,
    price_musd,
    mission_status
)
SELECT DISTINCT
    company,
    location,
    STR_TO_DATE(launch_date_raw, '%Y-%m-%d'),

    CASE
        WHEN launch_time_raw IS NULL THEN NULL
        ELSE STR_TO_DATE(launch_time_raw, '%H:%i:%s')
    END,

    rocket,
    mission,
    rocket_status,

    CASE
        WHEN price_raw IS NULL THEN NULL
        ELSE CAST(REPLACE(price_raw, ',', '') AS DECIMAL(12,2))
    END,

    mission_status
FROM space_missions_raw
WHERE company IS NOT NULL
  AND location IS NOT NULL
  AND launch_date_raw IS NOT NULL
  AND rocket IS NOT NULL
  AND mission IS NOT NULL
  AND rocket_status IS NOT NULL
  AND mission_status IS NOT NULL;


-- Kontrolle: Nach der Duplikatbereinigung werden 4.629 Missionen erwartet.
SELECT COUNT(*) AS cleaned_rows
FROM space_missions_clean;

SELECT
    MIN(launch_date) AS first_launch,
    MAX(launch_date) AS last_launch
FROM space_missions_clean;


-- ===========================================================================
-- 6. RELATIONALES DATENMODELL / NORMALISIERUNG
-- Eine flache CSV wird in logisch getrennte Tabellen aufgeteilt.
-- ===========================================================================

CREATE TABLE companies (
    company_id INT AUTO_INCREMENT PRIMARY KEY,
    company_name VARCHAR(120) NOT NULL UNIQUE
);

CREATE TABLE rockets (
    rocket_id INT AUTO_INCREMENT PRIMARY KEY,
    rocket_name VARCHAR(180) NOT NULL,
    rocket_status VARCHAR(30) NOT NULL,
    CONSTRAINT uq_rocket UNIQUE (rocket_name, rocket_status)
);

CREATE TABLE launch_sites (
    site_id INT AUTO_INCREMENT PRIMARY KEY,
    location VARCHAR(300) NOT NULL UNIQUE
);

CREATE TABLE missions (
    mission_id INT AUTO_INCREMENT PRIMARY KEY,
    company_id INT NOT NULL,
    rocket_id INT NOT NULL,
    site_id INT NOT NULL,
    mission_name VARCHAR(300) NOT NULL,
    launch_date DATE NOT NULL,
    launch_time TIME NULL,
    price_musd DECIMAL(12,2) NULL,
    mission_status VARCHAR(40) NOT NULL,

    CONSTRAINT fk_mission_company
        FOREIGN KEY (company_id) REFERENCES companies(company_id),

    CONSTRAINT fk_mission_rocket
        FOREIGN KEY (rocket_id) REFERENCES rockets(rocket_id),

    CONSTRAINT fk_mission_site
        FOREIGN KEY (site_id) REFERENCES launch_sites(site_id),

    INDEX idx_launch_date (launch_date),
    INDEX idx_mission_status (mission_status),
    INDEX idx_company (company_id),
    INDEX idx_rocket (rocket_id),
    INDEX idx_site (site_id)
);


-- Stammdaten übernehmen
INSERT INTO companies (company_name)
SELECT DISTINCT company
FROM space_missions_clean;

INSERT INTO rockets (rocket_name, rocket_status)
SELECT DISTINCT rocket, rocket_status
FROM space_missions_clean;

INSERT INTO launch_sites (location)
SELECT DISTINCT location
FROM space_missions_clean;


-- Zentrale Missions-Tabelle füllen.
-- JOIN liefert die passenden IDs aus den Stammdatentabellen.
INSERT INTO missions (
    company_id,
    rocket_id,
    site_id,
    mission_name,
    launch_date,
    launch_time,
    price_musd,
    mission_status
)
SELECT
    c.company_id,
    r.rocket_id,
    s.site_id,
    sm.mission,
    sm.launch_date,
    sm.launch_time,
    sm.price_musd,
    sm.mission_status
FROM space_missions_clean sm
JOIN companies c
    ON c.company_name = sm.company
JOIN rockets r
    ON r.rocket_name = sm.rocket
   AND r.rocket_status = sm.rocket_status
JOIN launch_sites s
    ON s.location = sm.location;


-- Diese Zahl muss mit der Clean-Tabelle übereinstimmen.
SELECT COUNT(*) AS missions_in_model
FROM missions;


-- ===========================================================================
-- 7. ANALYSE-VIEW
-- Die View enthält die JOINs bereits und vereinfacht alle folgenden Analysen.
-- ===========================================================================

CREATE OR REPLACE VIEW vw_mission_analysis AS
SELECT
    m.mission_id,
    c.company_name,
    r.rocket_name,
    r.rocket_status,
    s.location,
    m.mission_name,
    m.launch_date,
    YEAR(m.launch_date) AS launch_year,
    FLOOR(YEAR(m.launch_date) / 10) * 10 AS launch_decade,
    MONTH(m.launch_date) AS launch_month,
    m.launch_time,
    m.price_musd,
    m.mission_status
FROM missions m
JOIN companies c
    ON c.company_id = m.company_id
JOIN rockets r
    ON r.rocket_id = m.rocket_id
JOIN launch_sites s
    ON s.site_id = m.site_id;


-- Kontrollabfrage
SELECT COUNT(*) AS rows_in_analysis_view
FROM vw_mission_analysis;


-- ===========================================================================
-- 8. GESAMTÜBERBLICK
-- ===========================================================================

SELECT
    COUNT(*) AS total_missions,
    SUM(mission_status = 'Success') AS successful_missions,
    SUM(mission_status = 'Failure') AS failures,
    SUM(mission_status = 'Partial Failure') AS partial_failures,
    SUM(mission_status = 'Prelaunch Failure') AS prelaunch_failures,

    ROUND(
        100.0 * SUM(mission_status = 'Success') / COUNT(*),
        2
    ) AS success_rate_pct

FROM vw_mission_analysis;

-- Erwartete Werte:
-- 4.629 Missionen
-- 4.161 Success
-- 357 Failure
-- 107 Partial Failure
-- 4 Prelaunch Failure
-- Success Rate ca. 89,89 %


-- ===========================================================================
-- 9. ANALYSE 1 – ENTWICKLUNG IM ZEITVERLAUF
-- ===========================================================================

-- 9.1 Starts und Erfolgsquote pro Jahr
SELECT
    launch_year,
    COUNT(*) AS launches,
    SUM(mission_status = 'Success') AS successes,
    COUNT(*) - SUM(mission_status = 'Success') AS not_fully_successful,

    ROUND(
        100.0 * SUM(mission_status = 'Success') / COUNT(*),
        2
    ) AS success_rate_pct

FROM vw_mission_analysis
GROUP BY launch_year
ORDER BY launch_year;


-- 9.2 Jahr mit den meisten Missionen
SELECT
    launch_year,
    COUNT(*) AS launches
FROM vw_mission_analysis
GROUP BY launch_year
ORDER BY launches DESC
LIMIT 1;

-- Erwarteter Kontrollwert:
-- 2021 -> 157 Missionen


-- 9.3 Analyse nach Jahrzehnten
SELECT
    CONCAT(launch_decade, 'er') AS decade,
    COUNT(*) AS launches,
    SUM(mission_status = 'Success') AS successes,

    ROUND(
        100.0 * SUM(mission_status = 'Success') / COUNT(*),
        2
    ) AS success_rate_pct

FROM vw_mission_analysis
GROUP BY launch_decade
ORDER BY launch_decade;


-- 9.4 Größere historische Phasen
SELECT
    CASE
        WHEN launch_year < 1980 THEN '1957–1979'
        WHEN launch_year < 2000 THEN '1980–1999'
        WHEN launch_year < 2010 THEN '2000–2009'
        ELSE '2010–2022'
    END AS era,

    COUNT(*) AS launches,

    ROUND(
        100.0 * SUM(mission_status = 'Success') / COUNT(*),
        2
    ) AS success_rate_pct

FROM vw_mission_analysis
GROUP BY era
ORDER BY MIN(launch_year);


-- ===========================================================================
-- 10. ANALYSE 2 – ORGANISATIONEN / UNTERNEHMEN
-- Dieser Abschnitt wurde erweitert, damit nicht nur ein einzelner "Top-Wert"
-- gezeigt wird, sondern Aktivität UND Zuverlässigkeit verglichen werden.
-- ===========================================================================

-- 10.1 Top 10 Organisationen nach Anzahl der Missionen
SELECT
    company_name,
    COUNT(*) AS launches,
    SUM(mission_status = 'Success') AS successes,
    COUNT(*) - SUM(mission_status = 'Success') AS not_fully_successful,

    ROUND(
        100.0 * SUM(mission_status = 'Success') / COUNT(*),
        2
    ) AS success_rate_pct

FROM vw_mission_analysis
GROUP BY company_name
ORDER BY launches DESC
LIMIT 10;


-- 10.2 Erfolgsquote aller Organisationen mit mindestens 20 Missionen
-- Kleine Gruppen werden ausgeschlossen, damit 1–2 Missionen den Vergleich
-- nicht irreführend machen.
SELECT
    company_name,
    COUNT(*) AS launches,
    SUM(mission_status = 'Success') AS successes,

    ROUND(
        100.0 * SUM(mission_status = 'Success') / COUNT(*),
        2
    ) AS success_rate_pct

FROM vw_mission_analysis
GROUP BY company_name
HAVING COUNT(*) >= 20
ORDER BY success_rate_pct DESC, launches DESC;


-- 10.3 Größere bekannte Organisationen direkt miteinander vergleichen
SELECT
    company_name,
    COUNT(*) AS launches,
    SUM(mission_status = 'Success') AS successes,
    SUM(mission_status <> 'Success') AS not_fully_successful,

    ROUND(
        100.0 * SUM(mission_status = 'Success') / COUNT(*),
        2
    ) AS success_rate_pct

FROM vw_mission_analysis
WHERE company_name IN (
    'RVSN USSR',
    'CASC',
    'Arianespace',
    'NASA',
    'SpaceX',
    'ULA',
    'General Dynamics',
    'VKS RF',
    'ILS'
)
GROUP BY company_name
ORDER BY launches DESC;


-- 10.4 Organisationen über der globalen Erfolgsquote
SELECT
    company_name,
    launches,
    success_rate_pct
FROM (
    SELECT
        company_name,
        COUNT(*) AS launches,

        ROUND(
            100.0 * SUM(mission_status = 'Success') / COUNT(*),
            2
        ) AS success_rate_pct

    FROM vw_mission_analysis
    GROUP BY company_name
    HAVING COUNT(*) >= 20
) AS company_stats

WHERE success_rate_pct > (
    SELECT
        100.0 * SUM(mission_status = 'Success') / COUNT(*)
    FROM vw_mission_analysis
)

ORDER BY success_rate_pct DESC, launches DESC;


-- 10.5 Organisationen mit den meisten nicht vollständig erfolgreichen Missionen
SELECT
    company_name,
    COUNT(*) AS launches,
    SUM(mission_status <> 'Success') AS not_fully_successful,

    ROUND(
        100.0 * SUM(mission_status <> 'Success') / COUNT(*),
        2
    ) AS non_success_rate_pct

FROM vw_mission_analysis
GROUP BY company_name
HAVING COUNT(*) >= 20
ORDER BY not_fully_successful DESC
LIMIT 10;


-- ===========================================================================
-- 11. ANALYSE 3 – RAKETEN
-- ===========================================================================

-- 11.1 Top 12 meistgenutzte Raketen
SELECT
    rocket_name,
    rocket_status,
    COUNT(*) AS launches,
    SUM(mission_status = 'Success') AS successes,
    SUM(mission_status <> 'Success') AS not_fully_successful,

    ROUND(
        100.0 * SUM(mission_status = 'Success') / COUNT(*),
        2
    ) AS success_rate_pct

FROM vw_mission_analysis
GROUP BY rocket_name, rocket_status
ORDER BY launches DESC
LIMIT 12;


-- 11.2 Ausgewählte häufig verwendete Raketen direkt vergleichen
SELECT
    rocket_name,
    rocket_status,
    COUNT(*) AS launches,
    SUM(mission_status = 'Success') AS successes,
    SUM(mission_status <> 'Success') AS not_fully_successful,

    ROUND(
        100.0 * SUM(mission_status = 'Success') / COUNT(*),
        2
    ) AS success_rate_pct

FROM vw_mission_analysis
WHERE rocket_name IN (
    'Cosmos-3M (11K65M)',
    'Voskhod',
    'Molniya-M /Block ML',
    'Cosmos-2I (63SM)',
    'Soyuz U',
    'Tsyklon-3',
    'Falcon 9 Block 5',
    'Tsyklon-2',
    'Vostok-2M',
    'Molniya-M /Block 2BL',
    'Ariane 5 ECA',
    'Long March 2C'
)
GROUP BY rocket_name, rocket_status
ORDER BY launches DESC;


-- 11.3 Zuverlässigste häufig eingesetzte Raketen
SELECT
    rocket_name,
    rocket_status,
    COUNT(*) AS launches,
    SUM(mission_status = 'Success') AS successes,

    ROUND(
        100.0 * SUM(mission_status = 'Success') / COUNT(*),
        2
    ) AS success_rate_pct

FROM vw_mission_analysis
GROUP BY rocket_name, rocket_status
HAVING COUNT(*) >= 20
ORDER BY success_rate_pct DESC, launches DESC
LIMIT 15;


-- 11.4 Nur im Datensatz als Active gekennzeichnete Raketen
SELECT
    rocket_name,
    COUNT(*) AS launches,
    SUM(mission_status = 'Success') AS successes,

    ROUND(
        100.0 * SUM(mission_status = 'Success') / COUNT(*),
        2
    ) AS success_rate_pct

FROM vw_mission_analysis
WHERE rocket_status = 'Active'
GROUP BY rocket_name
HAVING COUNT(*) >= 10
ORDER BY launches DESC;


-- 11.5 Erfahrung vs. Erfolgsquote
SELECT
    CASE
        WHEN launches < 5 THEN '1–4 Missionen'
        WHEN launches < 20 THEN '5–19 Missionen'
        WHEN launches < 100 THEN '20–99 Missionen'
        ELSE '100+ Missionen'
    END AS experience_group,

    COUNT(*) AS number_of_rockets,
    ROUND(AVG(success_rate_pct), 2) AS avg_success_rate_pct

FROM (
    SELECT
        rocket_name,
        rocket_status,
        COUNT(*) AS launches,

        100.0 * SUM(mission_status = 'Success') / COUNT(*) AS success_rate_pct

    FROM vw_mission_analysis
    GROUP BY rocket_name, rocket_status
) AS rocket_stats

GROUP BY experience_group
ORDER BY MIN(launches);


-- ===========================================================================
-- 12. ANALYSE 4 – STARTORTE
-- ===========================================================================

-- 12.1 Häufigste Startorte
SELECT
    location,
    COUNT(*) AS launches,
    SUM(mission_status = 'Success') AS successes,

    ROUND(
        100.0 * SUM(mission_status = 'Success') / COUNT(*),
        2
    ) AS success_rate_pct

FROM vw_mission_analysis
GROUP BY location
ORDER BY launches DESC
LIMIT 10;


-- 12.2 Erfolgsquote bei Startorten mit mindestens 20 Missionen
SELECT
    location,
    COUNT(*) AS launches,

    ROUND(
        100.0 * SUM(mission_status = 'Success') / COUNT(*),
        2
    ) AS success_rate_pct

FROM vw_mission_analysis
GROUP BY location
HAVING COUNT(*) >= 20
ORDER BY success_rate_pct DESC, launches DESC
LIMIT 15;


-- ===========================================================================
-- 13. DATENQUALITÄT – PREIS
-- Preis ist KEIN Hauptteil der Analyse, weil viele Werte fehlen.
-- ===========================================================================

SELECT
    COUNT(*) AS total_missions,
    COUNT(price_musd) AS missions_with_price,
    SUM(price_musd IS NULL) AS missions_without_price,

    ROUND(
        100.0 * SUM(price_musd IS NULL) / COUNT(*),
        2
    ) AS missing_price_pct,

    ROUND(AVG(price_musd), 2) AS avg_known_price_musd

FROM vw_mission_analysis;


-- Nur ergänzend
SELECT
    company_name,
    COUNT(price_musd) AS known_prices,
    ROUND(AVG(price_musd), 2) AS avg_price_musd,
    ROUND(MIN(price_musd), 2) AS min_price_musd,
    ROUND(MAX(price_musd), 2) AS max_price_musd

FROM vw_mission_analysis
WHERE price_musd IS NOT NULL
GROUP BY company_name
HAVING COUNT(price_musd) >= 10
ORDER BY known_prices DESC;


-- ===========================================================================
-- 14. WEITERE SQL-INHALTE AUS DEM KURS
-- ===========================================================================

-- DISTINCT
SELECT
    COUNT(DISTINCT company_name) AS different_companies,
    COUNT(DISTINCT rocket_name) AS different_rockets,
    COUNT(DISTINCT location) AS different_launch_sites
FROM vw_mission_analysis;


-- COALESCE
SELECT
    mission_name,
    company_name,
    COALESCE(CAST(price_musd AS CHAR), 'keine Angabe') AS price_information
FROM vw_mission_analysis
LIMIT 20;


-- UNION ALL
SELECT
    'Active' AS rocket_group,
    COUNT(DISTINCT rocket_name) AS rockets
FROM vw_mission_analysis
WHERE rocket_status = 'Active'

UNION ALL

SELECT
    'Retired',
    COUNT(DISTINCT rocket_name)
FROM vw_mission_analysis
WHERE rocket_status = 'Retired';


-- ===========================================================================
-- 15. KOMPAKTE ABFRAGEN FÜR DIE PRÄSENTATION
-- ===========================================================================

-- A) Statusverteilung
SELECT
    mission_status,
    COUNT(*) AS missions
FROM vw_mission_analysis
GROUP BY mission_status
ORDER BY missions DESC;


-- B) Top 10 Unternehmen
SELECT
    company_name,
    COUNT(*) AS launches,

    ROUND(
        100.0 * SUM(mission_status = 'Success') / COUNT(*),
        2
    ) AS success_rate_pct

FROM vw_mission_analysis
GROUP BY company_name
ORDER BY launches DESC
LIMIT 10;


-- C) Top 10 Raketen
SELECT
    rocket_name,
    COUNT(*) AS launches,

    ROUND(
        100.0 * SUM(mission_status = 'Success') / COUNT(*),
        2
    ) AS success_rate_pct

FROM vw_mission_analysis
GROUP BY rocket_name
ORDER BY launches DESC
LIMIT 10;


-- D) Zuverlässige Unternehmen mit mindestens 20 Missionen
SELECT
    company_name,
    COUNT(*) AS launches,

    ROUND(
        100.0 * SUM(mission_status = 'Success') / COUNT(*),
        2
    ) AS success_rate_pct

FROM vw_mission_analysis
GROUP BY company_name
HAVING COUNT(*) >= 20
ORDER BY success_rate_pct DESC, launches DESC
LIMIT 10;


-- E) Zuverlässige Raketen mit mindestens 20 Missionen
SELECT
    rocket_name,
    COUNT(*) AS launches,

    ROUND(
        100.0 * SUM(mission_status = 'Success') / COUNT(*),
        2
    ) AS success_rate_pct

FROM vw_mission_analysis
GROUP BY rocket_name
HAVING COUNT(*) >= 20
ORDER BY success_rate_pct DESC, launches DESC
LIMIT 10;


-- F) Rekordjahr
SELECT
    launch_year,
    COUNT(*) AS launches
FROM vw_mission_analysis
GROUP BY launch_year
ORDER BY launches DESC
LIMIT 1;


-- G) Top-Startort
SELECT
    location,
    COUNT(*) AS launches
FROM vw_mission_analysis
GROUP BY location
ORDER BY launches DESC
LIMIT 1;


/*
===============================================================================
KURZES FAZIT ZUM CODE

CSV
 -> Raw-Tabelle
 -> Datenqualität
 -> Clean-Tabelle
 -> Normalisierung
 -> PK/FK
 -> JOINs
 -> View
 -> Zeit-, Unternehmens-, Raketen- und Startortanalyse

WICHTIG:
- Aktivität und Zuverlässigkeit sind unterschiedliche Kennzahlen.
- Hohe Erfolgsquote bei sehr wenigen Missionen ist wenig aussagekräftig.
- Historische Daten helfen bei Vergleichen, ersetzen aber keine aktuelle
  technische Sicherheits- oder Marktanalyse.
- Der Datensatz endet 2022.
===============================================================================
*/