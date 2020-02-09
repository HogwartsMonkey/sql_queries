
DECLARE @SelectedDate DATE = GETDATE()
DECLARE @DayBefore DATE = DATEADD(day,-1,@SelectedDate)
DECLARE @OneWeekAgo DATE = DATEADD(day,-7,@SelectedDate)
DECLARE @TwoWeekAgo DATE = DATEADD(day,-14,@SelectedDate)
DECLARE @ThreeWeekAgo DATE = DATEADD(day,-21,@SelectedDate)




SELECT
	
	day_table.hour_of_day,
	today.running_cost AS today_running_cost,
	_1weekago.running_cost AS _1weekago_running_cost,
	_2weeksago.running_cost AS _2weeksago_running_cost,
	_3weeksago.running_cost AS _3weeksago_running_cost,
	today.cost/NULLIF(today.clicks,0) AS today_cpc,
	_1weekago.cost/NULLIF(_1weekago.clicks,0) AS _1weekago_cpc,
	_2weeksago.cost/NULLIF(_2weeksago.clicks,0) AS _2weeksago_cpc,
	_3weeksago.cost/NULLIF(_3weeksago.clicks,0) AS _3weeksago_cpc,
	today.running_clicks AS today_running_clicks,
	_1weekago.running_clicks AS _1weekago_running_clicks,
	_2weeksago.running_clicks AS _2weeksago_running_clicks,
	_3weeksago.running_clicks AS _3weeksago_running_clicks,
	today.running_impressions AS today_running_impressions,
	_1weekago.running_impressions AS _1weekago_running_impressions,
	_2weeksago.running_impressions AS _2weeksago_running_impressions,
	_3weeksago.running_impressions AS _3weeksago_running_impressions,
	today.running_conversions AS today_running_conversions,
	_1weekago.running_conversions AS _1weekago_running_conversions,
	_2weeksago.running_conversions AS _2weeksago_running_conversions,
	_3weeksago.running_conversions AS _3weeksago_running_conversions


	

FROM

	(SELECT DISTINCT
		hour_of_day

	 FROM [master].[dbo].[fq-day-by-day-match-device-week-on-week] ) AS day_table

	LEFT JOIN
	 
	 (SELECT

		i.hour_of_day,
		i.cost,
		SUM(cost) OVER (ORDER BY hour_of_day) AS running_cost,
		i.clicks,
		SUM(clicks) OVER (ORDER BY hour_of_day) AS running_clicks,
		i.impressions,
		SUM(impressions) OVER (ORDER BY hour_of_day) AS running_impressions,
		i.conversions,
		SUM(conversions) OVER (ORDER BY hour_of_day) AS running_conversions

		FROM

	( SELECT
		hour_of_day,
		SUM(cost) AS cost,
		sum(impressions) AS impressions,
		SUM(clicks) AS clicks,
		SUM(conversions) AS conversions


		FROM [master].[dbo].[fq-day-by-day-match-device-week-on-week] 

		WHERE day = @SelectedDate
		
		GROUP BY hour_of_day) AS i)

		AS today


		ON day_table.hour_of_day = today.hour_of_day

	LEFT JOIN

	 (SELECT

		j.hour_of_day,
		j.cost,
		SUM(cost) OVER (ORDER BY hour_of_day) AS running_cost,
		j.clicks,
		SUM(clicks) OVER (ORDER BY hour_of_day) AS running_clicks,
		j.impressions,
		SUM(impressions) OVER (ORDER BY hour_of_day) AS running_impressions,
		j.conversions,
		SUM(conversions) OVER (ORDER BY hour_of_day) AS running_conversions

		FROM
	(SELECT
		hour_of_day,
		SUM(cost) AS cost,
		sum(impressions) AS impressions,
		SUM(clicks) AS clicks,
		
		SUM(conversions) AS conversions

		FROM [master].[dbo].[fq-day-by-day-match-device-week-on-week] 

		WHERE day = @DayBefore
		
		GROUP BY hour_of_day) AS j) as yesterday

		ON day_table.hour_of_day = yesterday.hour_of_day

		LEFT JOIN

		 (SELECT

		b.hour_of_day,
		b.cost,
		SUM(cost) OVER (ORDER BY hour_of_day) AS running_cost,
		b.clicks,
		SUM(clicks) OVER (ORDER BY hour_of_day) AS running_clicks,
		b.impressions,
		SUM(impressions) OVER (ORDER BY hour_of_day) AS running_impressions,
		b.conversions,
		SUM(conversions) OVER (ORDER BY hour_of_day) AS running_conversions

		FROM

	(SELECT
		hour_of_day,
		SUM(cost) AS cost,
		sum(impressions) AS impressions,
		SUM(clicks) AS clicks,
		
		SUM(conversions) AS conversions

		FROM [master].[dbo].[fq-day-by-day-match-device-week-on-week] 

		WHERE day = @OneWeekAgo
		
		GROUP BY hour_of_day) AS b) AS _1weekago

		ON day_table.hour_of_day = _1weekago.hour_of_day

		LEFT JOIN
	 (SELECT

		g.hour_of_day,
		g.cost,
		SUM(cost) OVER (ORDER BY hour_of_day) AS running_cost,
		g.clicks,
		SUM(clicks) OVER (ORDER BY hour_of_day) AS running_clicks,
		g.impressions,
		SUM(impressions) OVER (ORDER BY hour_of_day) AS running_impressions,
		g.conversions,
		SUM(conversions) OVER (ORDER BY hour_of_day) AS running_conversions

		FROM
	(SELECT
		hour_of_day,
		SUM(cost) AS cost,
		sum(impressions) AS impressions,
		SUM(clicks) AS clicks,
		
		SUM(conversions) AS conversions

		FROM [master].[dbo].[fq-day-by-day-match-device-week-on-week] 

		WHERE day = @TwoWeekAgo
		
		GROUP BY hour_of_day) AS g) AS _2weeksago

		ON day_table.hour_of_day = _2weeksago.hour_of_day

			LEFT JOIN

	 (SELECT

		t.hour_of_day,
		t.cost,
		SUM(cost) OVER (ORDER BY hour_of_day) AS running_cost,
		t.clicks,
		SUM(clicks) OVER (ORDER BY hour_of_day) AS running_clicks,
		t.impressions,
		SUM(impressions) OVER (ORDER BY hour_of_day) AS running_impressions,
		t.conversions,
		SUM(conversions) OVER (ORDER BY hour_of_day) AS running_conversions

		FROM

	(SELECT
		hour_of_day,
		SUM(cost) AS cost,
		sum(impressions) AS impressions,
		SUM(clicks) AS clicks,
		
		SUM(conversions) AS conversions

		FROM [master].[dbo].[fq-day-by-day-match-device-week-on-week] 

		WHERE day = @ThreeWeekAgo
		
		GROUP BY hour_of_day) AS t) AS _3weeksago

		ON day_table.hour_of_day = _3weeksago.hour_of_day

		ORDER BY hour_of_day