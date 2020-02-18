SELECT
				transaction_date,
				month,
				year,
				userid,
				reg_dt,
				amount,
				amount_running_total,
				transaction_ranked,
				previous_transaction_date,
				day_diff_perv_transaction,
				number_of_transactions,
				CASE WHEN transaction_ranked = number_of_transactions THEN 1 ELSE 0 END AS is_last_transaction
			
	FROM		
			(SELECT
				transaction_date,
				month,
				year,
				userid,
				reg_dt,
				amount,
				amount_running_total,
				transaction_ranked,
				previous_transaction_date,
				day_diff_perv_transaction,
				MAX(transaction_ranked) OVER (PARTITION BY userid) number_of_transactions

			FROM


					(SELECT
									transaction_date,
									transactions.month,
									transactions.year,
									transactions.userid,
									CONVERT(date,reg_dt) AS reg_dt,
									amount,
									SUM(amount) OVER (PARTITION BY transactions.userid order by transaction_date) AS amount_running_total,
									RANK() OVER (PARTITION BY transactions.userid ORDER BY transaction_date ASC) AS transaction_ranked,
									LAG(transaction_date,1) OVER (PARTITION BY transactions.userid ORDER BY transaction_date ASC) previous_transaction_date,
									DATEDIFF(day,LAG(transaction_date,1) OVER (PARTITION BY transactions.userid ORDER BY transaction_date ASC),transaction_date) day_diff_perv_transaction,

									COUNT(*) AS duplicate

									FROM

										(SELECT 
											transaction_date,
											month,
											year,
											userid,
											SUM(amount) AS amount

										FROM

											(SELECT

													CONVERT(date,transaction_dt) AS transaction_date,
													MONTH(transaction_dt) AS 'month',
													YEAR(transaction_dt) AS 'year',
													--RANK() OVER (PARTITION BY userid ORDER BY transaction_dt ASC) AS transaction_ranked,
													userid,
													amount

											FROM dbo.[jubiter-transaction-report] 
					
											WHERE amount > 0) AS convereted_date_and_buy_transactions

									GROUP BY 
										transaction_date,
										month,
										year,
										userid) AS transactions

									LEFT JOIN (

											SELECT

												reg_dt,
												userid 

											FROM 
												dbo.[jubiter-reg-report]) AS reg_dt_with_userid

								ON transactions.userid = reg_dt_with_userid.userid


								GROUP BY transaction_date,
									transactions.month,
									transactions.year,
									transactions.userid,
									amount,
				
									reg_dt) all_transaction_ranked_with_date_diff_between_each_transaction

			GROUP BY
				transaction_date,
				month,
				year,
				userid,
				reg_dt,
				amount,
				amount_running_total,
				transaction_ranked,
				previous_transaction_date,
				day_diff_perv_transaction) all_transaction_ranked_with_date_diff_between_each_transaction_and_user_number_of_transactions
