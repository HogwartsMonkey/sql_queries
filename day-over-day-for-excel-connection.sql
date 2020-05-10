SELECT
	performance_by_date.Day AS 'date',
	YEAR(performance_by_date.[Day]) AS 'year',
	MONTH(performance_by_date.[Day]) AS 'month',
    CASE WHEN DATEDIFF(month,[Day],GETDATE())<=3 THEN 'TRUE' ELSE 'FALSE' END AS current_month_and_previous_month,
    CASE WHEN day_number < DATEPART(day,GETDATE()) THEN 'TRUE' ELSE 'FALSE' END AS is_day_in_timeframe,
    CASE WHEN datediff(day,[Day],GETDATE())=1 THEN 'TRUE' ELSE 'FALSE' END AS isYesterday,
     CASE WHEN datediff(month,[Day],GETDATE())=0 THEN 'TRUE' ELSE 'FALSE' END AS isCurrentMonth,
    SUM(cost) OVER (partition by YEAR(performance_by_date.[Day]) ,MONTH(performance_by_date.[Day]) ORDER BY [Day] ASC) AS running_total_cost,
    SUM(signups) OVER (partition by YEAR(performance_by_date.[Day]) ,MONTH(performance_by_date.[Day]) ORDER BY [Day] ASC)  AS running_total_signups,
    SUM(conversions) OVER (partition by YEAR(performance_by_date.[Day]) ,MONTH(performance_by_date.[Day]) ORDER BY [Day] ASC) AS running_total__analytics_signups,
    SUM(full_signups) OVER (partition by YEAR(performance_by_date.[Day]) ,MONTH(performance_by_date.[Day]) ORDER BY [Day] ASC)  AS running_total__full_signups,
    SUM(FTDs_Same_Month.FTD) OVER (partition by YEAR(performance_by_date.[Day]) ,MONTH(performance_by_date.[Day]) ORDER BY [Day] ASC)  AS running_total_same_month_ftd,
    SUM(FTDs_Previous_Month.FTD) OVER (partition by YEAR(performance_by_date.[Day]) ,MONTH(performance_by_date.[Day]) ORDER BY [Day] ASC)  AS running_total_previous_month_ftd,
	SUM(first_purchase_same_month.FirstDeposit) OVER (partition by YEAR(performance_by_date.[Day]) ,MONTH(performance_by_date.[Day]) ORDER BY [Day] ASC)  AS running_total_first_deposit_same_month,
    SUM(first_deposit_previous_month.FirstDeposit) OVER (partition by YEAR(performance_by_date.[Day]) ,MONTH(performance_by_date.[Day]) ORDER BY [Day] ASC)  AS running_total_first_deposit_previous_month,
    SUM(new_deposit_same_month.Deposit) OVER (partition by YEAR(performance_by_date.[Day]) ,MONTH(performance_by_date.[Day]) ORDER BY [Day] ASC)  AS running_total_new_deposit_same_month,
    SUM(new_deposit_previous_month.Deposit) OVER (partition by YEAR(performance_by_date.[Day]) ,MONTH(performance_by_date.[Day]) ORDER BY [Day] ASC)  AS running_total_new_deposit_previous_month,
    day_number,
	performance_by_date.cost,
	performance_by_date.impressions,
	performance_by_date.clicks,
	performance_by_date.conversions as 'analytics_signups',
	signups_by_date.signups,
	signups_by_date.full_signups,
	FTDs_Same_Month.FTD AS 'Same_Month_FTD',
	FTDs_Previous_Month.FTD AS 'Previous_Months_FTD',
	first_purchase_same_month.FirstDeposit AS first_deposit_same_month,
	first_deposit_previous_month.FirstDeposit AS first_deposit_previous_month,
	new_deposit_same_month.Deposit AS new_deposit_same_month,
	new_deposit_previous_month.Deposit AS new_deposit_previous_month

FROM


(SELECT
	[Day],
	day([Day]) AS day_number,
	SUM([cost]) AS cost,
	SUM([Impressions]) AS impressions,
	SUM([Clicks]) as clicks,
	SUM([Conversions]) AS conversions

FROM dbo.[jubiter-adgroup-report]

--WHERE Campaign  NOT IN ('US - Generics - Bitcoin - Dynamic Search Ads - DSA_Desktop','US - Generics - Bitcoin - Dynamic Search Ads - DSA_Mobile')

GROUP BY [Day]) AS performance_by_date

LEFT JOIN (SELECT
			transaction_date,
			SUM(transaction_ranked) AS FTD
		FROM

			(SELECT
				transaction_date,
				month,
				year,
				userid,
				amount,
				transaction_ranked,
				COUNT(*) AS duplicate

				FROM

					(SELECT 
								CONVERT(date,transaction_dt) AS transaction_date,
								MONTH(transaction_dt) AS 'month',
								YEAR(transaction_dt) AS 'year',
								userid,
								SUM(amount) AS amount,
								RANK() OVER (PARTITION BY userid ORDER BY transaction_dt ASC) AS transaction_ranked

					FROM dbo.[jubiter-transaction-report] 

					WHERE transaction_type = 'Buy'
					GROUP BY transaction_dt,userid) AS i

				GROUP BY
					transaction_date,
				userid,
				amount,
				transaction_ranked,
				month,
				year) AS B

				LEFT JOIN (
						SELECT
							reg_dt,
							MONTH(reg_dt) AS 'month',
							YEAR(reg_dt) AS 'year',
							userid 
							FROM 
							dbo.[jubiter-reg-report]) AS month_of_reg

			ON b.userid = month_of_reg.userid

		WHERE transaction_ranked= 1
		AND b.month != month_of_reg.month
		AND b.year >= month_of_reg.year
	
		GROUP BY transaction_date) AS FTDs_Previous_Month 

	ON performance_by_date.Day = FTDs_Previous_Month.transaction_date

LEFT JOIN (SELECT
			transaction_date,
			SUM(transaction_ranked) AS FTD
		FROM

			(SELECT
				transaction_date,
				month,
				year,
				userid,
				amount,
				transaction_ranked,
				COUNT(*) AS duplicate

				FROM

					(SELECT 
								CONVERT(date,transaction_dt) AS transaction_date,
								MONTH(transaction_dt) AS 'month',
								YEAR(transaction_dt) AS 'year',
								userid,
								SUM(amount) AS amount,
								RANK() OVER (PARTITION BY userid ORDER BY transaction_dt ASC) AS transaction_ranked

					FROM dbo.[jubiter-transaction-report] 
				
					WHERE transaction_type = 'Buy'

					GROUP BY transaction_dt,userid) AS i

				GROUP BY
					transaction_date,
				userid,
				amount,
				transaction_ranked,
				month,
				year) AS B

				LEFT JOIN (
						SELECT
							reg_dt,
							MONTH(reg_dt) AS 'month',
							YEAR(reg_dt) AS 'year',
							userid 
							FROM 
							dbo.[jubiter-reg-report]) AS month_of_reg

			ON b.userid = month_of_reg.userid


		WHERE transaction_ranked= 1
		AND b.month = month_of_reg.month
		AND b.year = month_of_reg.year
	
		GROUP BY transaction_date) AS FTDs_Same_Month 

	ON performance_by_date.Day = FTDs_Same_Month.transaction_date

LEFT JOIN ( 
	SELECT 
	reg_dt,
	SUM(isreg) AS signups,
	SUM(full_reg) AS full_signups

	FROM

		(SELECT

			CONVERT(date,reg_dt) AS reg_dt,
			userid,
			COUNT(*) AS isreg

		FROM dbo.[jubiter-reg-report]
		GROUP BY reg_dt,userid) AS date_converted

	LEFT JOIN 

		(SELECT 

			userid,
			fullname,
			COUNT(*) AS full_reg 

		FROM dbo.[jubiter-reg-report]

		WHERE fullname != ''

		GROUP BY userid,fullname) AS fullname_table

	ON date_converted.userid = fullname_table.userid
	GROUP BY reg_dt

			 ) AS signups_by_date

ON  performance_by_date.[day] = signups_by_date.reg_dt

/*1st deposit  transaction month = reg month */


LEFT JOIN (
			SELECT
				 transaction_date,
				 SUM(amount) AS FirstDeposit

				FROM

					(SELECT
							CONVERT(date,transaction_dt) AS transaction_date,
							MONTH(transaction_dt) AS transaction_month,
							userid,
							amount,
							RANK() OVER (PARTITION BY userid ORDER BY transaction_dt ASC) AS transaction_ranked

						FROM dbo.[jubiter-transaction-report] WHERE transaction_type = 'Buy')  AS all_transactions_ranked

				LEFT JOIN

				(SELECT
					CONVERT(date,reg_dt) AS reg_dt,
					MONTH(reg_dt) AS reg_month,
					userid
				FROM dbo.[jubiter-reg-report] ) AS reg_report

			ON 	all_transactions_ranked.userid = reg_report.userid
			WHERE transaction_ranked = 1
			AND transaction_month = reg_month
			GROUP BY transaction_date) AS first_purchase_same_month

			ON  performance_by_date.[day] = first_purchase_same_month.transaction_date

/*1st deposit  transaction month != reg month */

LEFT JOIN ( SELECT
			 transaction_date,
			 SUM(amount) AS FirstDeposit

			FROM

				(SELECT
					CONVERT(date,transaction_dt) AS transaction_date,
					MONTH(transaction_dt) AS transaction_month,
					userid,
					amount,
					RANK() OVER (PARTITION BY userid ORDER BY transaction_dt ASC) AS transaction_ranked

				FROM dbo.[jubiter-transaction-report] WHERE transaction_type = 'Buy')  AS all_transactions_ranked

				LEFT JOIN

				(SELECT
					CONVERT(date,reg_dt) AS reg_dt,
					MONTH(reg_dt) AS reg_month,
					userid
				FROM dbo.[jubiter-reg-report] ) AS reg_report

			ON 	all_transactions_ranked.userid = reg_report.userid
			WHERE transaction_ranked = 1
			AND transaction_month != reg_month
			GROUP BY transaction_date) AS first_deposit_previous_month

ON performance_by_date.Day = first_deposit_previous_month.transaction_date

/*2nd deposit and on transaction month = reg month */

LEFT JOIN (SELECT
 transaction_date,
 SUM(amount) AS Deposit

FROM

	(SELECT
			CONVERT(date,transaction_dt) AS transaction_date,
			MONTH(transaction_dt) AS transaction_month,
			userid,
			amount,
			RANK() OVER (PARTITION BY userid ORDER BY transaction_dt ASC) AS transaction_ranked

		FROM dbo.[jubiter-transaction-report] WHERE transaction_type = 'Buy')  AS all_transactions_ranked

	LEFT JOIN

		(SELECT
			CONVERT(date,reg_dt) AS reg_dt,
			MONTH(reg_dt) AS reg_month,
			userid
		FROM dbo.[jubiter-reg-report] ) AS reg_report

	ON 	all_transactions_ranked.userid = reg_report.userid
	WHERE transaction_ranked != 1
	AND transaction_month = reg_month
	GROUP BY transaction_date) AS new_deposit_same_month

ON performance_by_date.Day = new_deposit_same_month.transaction_date

/*2nd deposit and on transaction month != reg month */

LEFT JOIN (SELECT
 transaction_date,
 SUM(amount) AS Deposit

FROM

	(SELECT
			CONVERT(date,transaction_dt) AS transaction_date,
			MONTH(transaction_dt) AS transaction_month,
			userid,
			amount,
			RANK() OVER (PARTITION BY userid ORDER BY transaction_dt ASC) AS transaction_ranked

		FROM dbo.[jubiter-transaction-report] WHERE transaction_type = 'Buy')  AS all_transactions_ranked

	LEFT JOIN

		(SELECT
			CONVERT(date,reg_dt) AS reg_dt,
			MONTH(reg_dt) AS reg_month,
			userid
		FROM dbo.[jubiter-reg-report] ) AS reg_report

	ON 	all_transactions_ranked.userid = reg_report.userid
	WHERE transaction_ranked != 1
	AND transaction_month != reg_month
	GROUP BY transaction_date) AS new_deposit_previous_month

ON performance_by_date.Day = new_deposit_previous_month.transaction_date

WHERE [Day] BETWEEN '20200401'AND '20200430'

