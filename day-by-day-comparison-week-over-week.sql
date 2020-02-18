DECLARE @Today DATE = GETDATE()
DECLARE @Yesterday DATE = DATEADD(day,-1,@Today)
DECLARE @_7daysAgo DATE = DATEADD(day,-7,@Today)
DECLARE @_14daysago DATE = DATEADD(day,-14,@Today)
DECLARE @_21daysago DATE = DATEADD(day,-21,@Today)
DECLARE @_28daysago DATE = DATEADD(day,-28,@Today)

DECLARE @LastWeek TABLE 
	(
		
		_day DATE,
		_weekday VARCHAR(50),
		cost FLOAT,
		impressions FLOAT,
		clicks FLOAT,
		conversions FLOAT 
	)

INSERT INTO @LastWeek (_day,_weekday,cost,impressions,clicks,conversions)
SELECT 
		day,
		DATENAME(WEEKDAY,day) AS _weekday,
		SUM(cost) AS cost,
		SUM(impressions) AS impressions,
		SUM(clicks) AS clicks,
		SUM(conversions) AS conversions



	 FROM dbo.[fq-day-by-day-match-device-week-on-week-with-value] 
	 
	 WHERE day < @Today
	 AND day >= @_7daysAgo
		GROUP BY day
		

	DECLARE @Twoweeksago TABLE 
	(
		
		_day DATE,
		_weekday VARCHAR(50),
		cost FLOAT,
		impressions FLOAT,
		clicks FLOAT,
		conversions FLOAT 
	)

INSERT INTO @Twoweeksago (_day,_weekday,cost,impressions,clicks,conversions)
SELECT 
		day,
		DATENAME(WEEKDAY,day) AS _weekday,
		SUM(cost) AS cost,
		SUM(impressions) AS impressions,
		SUM(clicks) AS clicks,
		SUM(conversions) AS conversions



	 FROM dbo.[fq-day-by-day-match-device-week-on-week-with-value] 
	 
	 WHERE day < @_7daysAgo
	 AND day >= @_14daysago
		GROUP BY day


	DECLARE @Threeweeksago TABLE 
	(
		
		_day DATE,
		_weekday VARCHAR(50),
		cost FLOAT,
		impressions FLOAT,
		clicks FLOAT,
		conversions FLOAT 
	)

INSERT INTO @Threeweeksago (_day,_weekday,cost,impressions,clicks,conversions)
SELECT 
		day,
		DATENAME(WEEKDAY,day) AS _weekday,
		SUM(cost) AS cost,
		SUM(impressions) AS impressions,
		SUM(clicks) AS clicks,
		SUM(conversions) AS conversions



	 FROM dbo.[fq-day-by-day-match-device-week-on-week-with-value] 
	 
	 WHERE day < @_14daysAgo
	 AND day >= @_21daysago
		GROUP BY day	


	DECLARE @Fourweeksago TABLE 
	(
		
		_day DATE,
		_weekday VARCHAR(50),
		cost FLOAT,
		impressions FLOAT,
		clicks FLOAT,
		conversions FLOAT 
	)

INSERT INTO @Fourweeksago (_day,_weekday,cost,impressions,clicks,conversions)
SELECT 
		day,
		DATENAME(WEEKDAY,day) AS _weekday,
		SUM(cost) AS cost,
		SUM(impressions) AS impressions,
		SUM(clicks) AS clicks,
		SUM(conversions) AS conversions



	 FROM dbo.[fq-day-by-day-match-device-week-on-week-with-value] 
	 
	 WHERE day < @_21daysago
	 AND day >= @_28daysago
		GROUP BY day	
	

	SELECT 
		weekday_table._weekday,
		past_7_days._day,
		_2_weeks_ago._day,
		_3_weeks_ago._day,
		_4_weeks_ago._day,

		past_7_days.cost AS past_7_days_cost ,
		_2_weeks_ago.cost AS _2_weeks_ago_cost ,
		_3_weeks_ago.cost AS _3_weeks_ago_cost ,
		_4_weeks_ago.cost AS _4_weeks_ago_cost ,

		past_7_days.clicks AS past_7_days_clicks,
		_2_weeks_ago.clicks AS _2_weeks_ago_clicks,
		_3_weeks_ago.clicks AS _3_weeks_ago_clicks,
		_4_weeks_ago.clicks AS _4_weeks_ago_clicks,

		past_7_days.cost/NULLIF(past_7_days.clicks,0) AS past_7_days_cpc,
		_2_weeks_ago.cost/NULLIF(_2_weeks_ago.clicks,0) AS _2_weeks_ago_cpc,
		_3_weeks_ago.cost/NULLIF(_3_weeks_ago.clicks,0) AS _3_weeks_ago_cpc,
		_4_weeks_ago.cost/NULLIF(_4_weeks_ago.clicks,0) AS _4_weeks_ago_cpc,

		past_7_days.conversions AS past_7_days_conversions,
		_2_weeks_ago.conversions AS _2_weeks_ago_conversions,
		_3_weeks_ago.conversions AS _3_weeks_ago_conversions,
		_4_weeks_ago.conversions AS _4_weeks_ago_conversions

	
	 FROM


	(SELECT DISTINCT
		DATENAME(WEEKDAY,day) AS _weekday
	FROM
		dbo.[fq-day-by-day-match-device-week-on-week-with-value]) AS weekday_table

	LEFT JOIN
	(
		SELECT * FROM

		@LastWeek) AS past_7_days

	ON weekday_table._weekday = past_7_days._weekday

	LEFT JOIN
	(
		SELECT * FROM

		@Twoweeksago) AS _2_weeks_ago	

	ON weekday_table._weekday = _2_weeks_ago._weekday

	LEFT JOIN
	(
		SELECT * FROM

		@Threeweeksago) AS _3_weeks_ago	

	ON weekday_table._weekday = _3_weeks_ago._weekday

	LEFT JOIN
	(
		SELECT * FROM

		@Fourweeksago) AS _4_weeks_ago	

	ON weekday_table._weekday = _4_weeks_ago._weekday

	ORDER BY _weekday


		