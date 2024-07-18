USE preppin_data;

CREATE TABLE `pd_week3_2023` (
  `Online or In-Person` VARCHAR(1024),
  `Q1` BIGINT,
  `Q2` BIGINT,
  `Q3` BIGINT,
  `Q4` BIGINT
);

INSERT INTO `pd_week3_2023` (`Online or In-Person`,`Q1`,`Q2`,`Q3`,`Q4`)
VALUES
('Online',72500,70000,60000,60000),
('In-Person',75000,70000,70000,60000);

/*other used is week1