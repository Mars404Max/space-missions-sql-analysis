# Space Missions SQL Analysis

A MySQL data-analysis project exploring historical space missions from **1957 to 2022**.

## Project goals

1. Analyze how launch activity and mission success rates changed over time.
2. Compare organizations and rockets by activity, experience, and historical reliability.
3. Analyze launch sites and identify important data-quality limitations.

## Dataset

The project uses the **Space Missions** dataset published through Maven Analytics, based on data from Next Spaceflight.

Main fields:
- Company
- Location
- Date
- Time
- Rocket
- Mission
- RocketStatus
- Price
- MissionStatus

CSV source used for the project:
https://github.com/vm8181/Space-Mission-Analysis/blob/main/space_missions.csv

The CSV is not redistributed here. Download it from the source above before running the SQL script.

## Database workflow

```text
CSV
  ↓
Raw table
  ↓
Data-quality checks
  ↓
Clean table
  ↓
Normalization
  ↓
Primary / Foreign Keys
  ↓
JOINs
  ↓
Analysis View
  ↓
Time / Company / Rocket / Launch-site analysis
```

## Relational model

The flat CSV is transformed into:
- `companies`
- `rockets`
- `launch_sites`
- `missions`

The central `missions` table references the other entities through foreign keys.

## Key analysis logic

Historical success rate:

```sql
ROUND(
    100.0 * SUM(mission_status = 'Success') / COUNT(*),
    2
) AS success_rate_pct
```

For reliability comparisons, very small groups are excluded:

```sql
HAVING COUNT(*) >= 20
```

This avoids treating a rocket with only one or two successful missions as automatically more reliable than a rocket with a much larger mission history.

## Data-quality findings

- 4,630 raw rows
- 1 full duplicate
- 4,629 rows after duplicate removal
- 127 missing time values
- 3,365 missing price values

Because price data is highly incomplete, cost analysis is treated only as supplementary.

## Historical findings

- 2021 is the busiest year in this dataset with 157 missions.
- Cosmos-3M (11K65M) is the most frequently used rocket in the dataset.
- Mission volume and reliability are different metrics and should be evaluated separately.
- The dataset ends in 2022, so the project is a historical snapshot rather than a current market or safety assessment.

## Repository structure

```text
.
├── README.md
├── sql/
│   └── space_missions_analysis.sql
├── presentation/
│   └── space_missions_sql_analysis.pptx
└── docs/
    └── presentation_script_de.md
```

## How to run

1. Install MySQL Server and MySQL Workbench.
2. Download `space_missions.csv`.
3. Open `sql/space_missions_analysis.sql`.
4. Replace the local path in `LOAD DATA LOCAL INFILE`.
5. Enable `LOCAL INFILE` if required.
6. Run the script section by section.

## SQL concepts used

`CREATE DATABASE`, `CREATE TABLE`, `PRIMARY KEY`, `FOREIGN KEY`, `INDEX`, `INSERT INTO ... SELECT`, `JOIN`, `GROUP BY`, `HAVING`, `CASE`, `COUNT`, `SUM`, `AVG`, `MIN`, `MAX`, `DISTINCT`, `COALESCE`, `UNION ALL`, subqueries and views.

## Limitations

Historical success rates do not guarantee future mission outcomes. A real operational decision would require current technical, safety, financial, and regulatory information.

## Author

**Maria Schulz**

SQL / Data Analysis coursework project.
