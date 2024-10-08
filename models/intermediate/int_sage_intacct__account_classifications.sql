with gl_account as (
    select *
    from {{ ref('stg_sage_intacct__gl_account') }}
), 

final as (
    select
        account_no,
        account_type,
        category,
        closing_account_title,
        case
            when category in {{ var('sage_intacct_category_asset') }} then 'Asset'
            when category in {{ var('sage_intacct_category_equity') }} then 'Equity'
            when category in {{ var('sage_intacct_category_expense') }} then 'Expense'
            when category in {{ var('sage_intacct_category_liability') }} then 'Liability'
            when category in {{ var('sage_intacct_category_revenue') }} then 'Revenue'
            when (normal_balance = 'debit' and account_type = 'balancesheet') and category not in {{ var('sage_intacct_category_asset') }} then 'Asset'
            when (normal_balance = 'debit' and account_type = 'incomestatement') and category not in {{ var('sage_intacct_category_expense') }} then 'Expense'
            when (normal_balance = 'credit' and account_type = 'balancesheet' and category not in {{ var('sage_intacct_category_liability') }} or category not in ('Partners Equity','Retained Earnings','Dividend Paid')) then 'Liability'
            when (normal_balance = 'credit' and account_type = 'incomestatement') and category not in {{ var('sage_intacct_category_revenue') }} then 'Revenue'
        end as classification,
        normal_balance, 
        title as account_title

        --The below script allows for pass through columns.
        {% if var('sage_account_pass_through_columns') %} 
        ,
        {{ var('sage_account_pass_through_columns') | join (", ")}}

        {% endif %}
    from gl_account
),

additional_sta_acc as (
    select
        'STA-4010' as account_no,
        'incomestatement' as account_type,
        'Current Month Collection Adjustment' as category,
        '' as closing_account_title,
        'Expense' as classification,
        'debit' as normal_balance, 
        'Current Month Collection Adjustment' as account_title
    union
    select
        'STA-4025',
        'incomestatement',
        'FSBO' as category,
        '' as closing_account_title,
        'Expense' as classification,
        'debit' as normal_balance, 
        'FSBO' as account_title
)

select *
from final
union 
select *
from additional_sta_acc
