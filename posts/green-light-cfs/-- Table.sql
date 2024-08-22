-- Table 
DESCRIBE SELECT * FROM read_csv("C:\Users\gioc4\Documents\blog\data\green_light\calls_all.csv");

-- Priority by year
SELECT
    COUNT(strftime(call_timestamp, '%Y')) AS N,
    strftime(call_timestamp, '%Y') AS year,
    priority
FROM read_csv("C:\Users\gioc4\Documents\blog\data\green_light\calls_all.csv")
WHERE CAST(strftime(call_timestamp, '%Y') AS INT) > 2016
GROUP BY year, priority
ORDER BY year, priority;

-- Call category, by year
SELECT
    COUNT(strftime(call_timestamp, '%Y')) AS N,
    strftime(call_timestamp, '%Y') AS year,
    category
FROM read_csv("C:\Users\gioc4\Documents\blog\data\green_light\calls_all.csv")
WHERE CAST(strftime(call_timestamp, '%Y') AS INT) > 2016
GROUP BY year, category
ORDER BY year, category;
S
-- Call code, by year
SELECT
    COUNT(strftime(call_timestamp, '%Y')) AS N,
    strftime(call_timestamp, '%Y') AS year,
     calldescription 
FROM read_csv("C:\Users\gioc4\Documents\blog\data\green_light\calls_all.csv")
WHERE CAST(strftime(call_timestamp, '%Y') AS INT) > 2016
GROUP BY year,  calldescription
ORDER BY N DESC ;
