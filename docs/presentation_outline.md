# Presentation outline

## 1. Topic
Historical analysis of space missions from 1957 to 2022.

## 2. Research questions
- How did launch activity and success rates evolve over time?
- Which organizations were most active?
- Which organizations and rockets combine experience with high historical reliability?
- Which launch sites were used most frequently?
- How does data quality limit the conclusions?

## 3. Data quality
- 4,630 raw rows
- 1 full duplicate
- 4,629 cleaned rows
- 127 missing time values
- 3,365 missing price values

## 4. Database model
The flat CSV is normalized into:
- Companies
- Rockets
- Launch Sites
- Missions

## 5. Time analysis
Mission count and historical success rate are analyzed by year and decade.

## 6. Organization analysis
Organizations are compared by:
- mission volume
- successful missions
- historical success rate
- minimum sample-size filters

## 7. Rocket analysis
Rockets are compared by:
- historical mission count
- success rate
- Active / Retired status
- experience groups

## 8. Launch-site analysis
Launch sites are compared by usage and historical success rate.

## 9. Limitations
- price data is highly incomplete
- the dataset ends in 2022
- historical success does not guarantee future success

## 10. Conclusion
The project demonstrates how SQL can be used not only to count records but also to prepare, normalize, compare, and interpret historical data in a structured way.
