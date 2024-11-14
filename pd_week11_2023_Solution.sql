WITH CTE AS (
    SELECT *,
        `Address Long` / (180/PI()) AS'Address_long_rad',
        `Address Lat` / (180/PI()) AS'Address_lat_rad',
        `Branch Long` / (180/PI()) AS 'Branch_long_rad',
        `Branch Lat` / (180/PI()) AS 'Branch_lat_rad',
        `Branch Long`/(180/PI()) - `Address Long`/(180/PI()) as 'Diff'
    FROM `preppin_data`.`pd_week11_loc`
    CROSS JOIN `preppin_data`.`pd_week11_bran`
),
Closest_Branch AS (
    SELECT 
        `Branch`,
        `Branch Long`,
        `Branch Lat`,
        ROUND(3963 * acos(sin(`Address_lat_rad`) * sin(`Branch_lat_rad`) +cos(`Address_lat_rad`) * cos(`Branch_lat_rad`) * cos(`Diff`)), 2) AS 'Distance',
        ROW_NUMBER() OVER(PARTITION BY `Customer` ORDER BY 'Distance' ASC) AS 'Closest Branch',
        ROW_NUMBER() OVER(PARTITION BY `Branch` ORDER BY 'Distance' ASC) AS 'Customer Priority',
        `Customer`,
        `Address Long`,
        `Address Lat` 
    FROM CTE
)
SELECT `Branch`,
`Branch Long`,
`Branch Lat`,
`Distance`,
`Customer Priority`,
`Customer`,
`Address Long`,
`Address Lat`
FROM Closest_Branch
WHERE `Closest Branch` = 1;