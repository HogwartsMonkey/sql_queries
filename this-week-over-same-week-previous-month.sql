DECLARE @Today INT = DATEPART(DAY,getdate())
DECLARE @Current_Month INT = DATEPART(month,getdate())
DECLARE @Previous_Month INT =DATEPART(MONTH,DATEADD(MONTH,-1,GETDATE()))
--DECLARE @Previous_Year INT =DATEPART(YEAR,DATEADD(YEAR,-1,GETDATE()))
DECLARE @_7daysAgo INT = DATEPART(DAY,DATEADD(day,-7,GETDATE()))


Declare @ThisWeek TABLE(
		_year INT,
		_month INT,
		ranking INT,
		cost  FLOAT,
		impressions FLOAT,
		clicks FLOAT,
		signups FLOAT,
		full_signups FLOAT,
		Same_Month_FTD FLOAT,
		Previous_Months_FTD FLOAT,
		first_deposit_same_month FLOAT,
		first_deposit_previous_month FLOAT,
		new_deposit_same_month FLOAT,
		new_deposit_previous_month FLOAT
)



;WITH performance_by_date AS(
SELECT
	CONVERT(varchar,performance_by_date.Day,101) AS 'date',
	YEAR(performance_by_date.[Day]) AS 'year',
	MONTH(performance_by_date.[Day]) AS 'month',
	day_number,
	performance_by_date.cost,
	performance_by_date.impressions,
	performance_by_date.clicks,
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
	SUM([Clicks]) as clicks

FROM dbo.[jubiter-adgroup-report]

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

ON performance_by_date.Day = new_deposit_previous_month.transaction_date)

INSERT INTO @ThisWeek (_year,_month,ranking,cost,impressions,clicks,signups,full_signups,Same_Month_FTD,Previous_Months_FTD,first_deposit_same_month,
		first_deposit_previous_month,
		new_deposit_same_month,
		new_deposit_previous_month)
		
		SELECT
			year,
			month,
			RANK() OVER (PARTITION BY month ORDER BY year DESC) AS ranking,
			SUM(cost),
			SUM(impressions),
			SUM(clicks),
			SUM(signups),
			SUM(full_signups),
			SUM(Same_Month_FTD),
			SUM(Previous_Months_FTD),
			SUM(first_deposit_same_month),
			SUM(first_deposit_previous_month),
			SUM(new_deposit_same_month),
			SUM(new_deposit_previous_month)
			FROM performance_by_date

			WHERE day_number < @Today
			AND day_number >= @_7daysago
			AND month in (@Current_Month,@Previous_Month)
		
			
			GROUP BY year,month 
			

SELECT 
	_year,
	_month,
	cost,
	clicks,
	ROUND(cost/clicks,2) AS avg_cpc,
	signups,
	ROUND(cost/signups,2) AS avg_reg_cost,
	full_signups,
	ROUND(cost/full_signups,2) AS avg_full_signups_cost,
	Same_Month_FTD,
	Previous_Months_FTD,
	(Same_Month_FTD+Previous_Months_FTD) AS 'Total FTD',
	ROUND(cost/(Same_Month_FTD+Previous_Months_FTD),2) AS avg_firstimepurchaser_cost,
	first_deposit_same_month,
	first_deposit_previous_month,
	new_deposit_same_month,
	new_deposit_previous_month




 from @ThisWeek WHERE ranking = 1 ORDER BY _year,_month ASC