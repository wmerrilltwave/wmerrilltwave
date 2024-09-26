create or replace view JIVRO_TEST.JIVRO_OUTPUT.VW_JIVRO_CUST(
	FIRSTNAME,
	LASTNAME,
	NAME,
	EMAIL,
	MAINPHONE,
	ADDRESS1,
	ADDRESS2,
	CITY,
	STATE,
	ZIPCODE,
	COUNTRY,
	FIRSTSALESITE,
	LEGACY_CUSTOMER_ID,
	LEGACY_CUSTOMER_HUB,
	LVLELIGIBLE,
	LVLUPLASTOFFER,
	ENABLED,
	EFFECTIVE_FROM_DATE,
	EFFECTIVE_TO_DATE
) as 
WITH  RankedSales AS
	(
	SELECT distinct a.customer
		, a.status
		, a.saleid
        , b.logdate
        , a.record_source
        , ROW_NUMBER() OVER (PARTITION BY a.customer ORDER BY b.logdate DESC) AS rn
     FROM JIVRO_TEST.JIVRO_OUTPUT.v_salepasses a
     INNER JOIN JIVRO_TEST.JIVRO_OUTPUT.v_sale b 
        ON a.site = b.site 
        AND a.saleid = b.objid 
        AND a.record_source = b.record_source
        and a.effective_to_date is null
        and b.effective_to_date is null
      WHERE 1=1
        --AND a.customer = 388900256  --Testing purposes
        AND a.status NOT IN (29,27,21)  --Terminated,Discontinued,Plan Expired
        --AND b.logdate >= DATEADD(YEAR, -2, CURRENT_DATE())  -- Look at only the last two years Will need to update to only looking for data after 08/25
        -- AND b.logdate >= '2024-08-01'
        AND DATEADD(day, 14, a.expires) >= CURRENT_DATE()
     )

-----------------------------main query -----------------------------------------------------------------------
                    
SELECT distinct c.FIRSTNAME AS FIRSTNAME
	, c.LASTNAME AS LASTNAME
    , c.name  --Testing purpose
    , c.EMAIL AS EMAIL
    , c.MAINPHONE AS MAINPHONE
--    , c.COMPANY AS LEGALENTITYNAME
    , c.ADDRESS1 AS ADDRESS1
    , c.ADDRESS2 AS ADDRESS2
    , c.CITY AS CITY
    , c.STATE AS STATE
    , c.ZIPCODE AS ZIPCODE
    , 'United States Of America'  AS COUNTRY
    , FirstSaleSite.sitename AS FIRSTSALESITE
    , c.OBJID AS LEGACY_CUSTOMER_ID
    , CASE
	    WHEN c.record_source ='JIVRO_1' THEN 1
	    WHEN c.record_source = 'JIVRO_2' THEN 2
	    ELSE 0
      END AS LEGACY_CUSTOMER_HUB
    , c.SKIPXPTUPSELL AS LVLELIGIBLE
    , c.CUSTOM02 AS LVLUPLASTOFFER
    , c.ENABLED AS ENABLED
    , c.EFFECTIVE_FROM_DATE
    , c.EFFECTIVE_TO_DATE

FROM JIVRO_TEST.JIVRO_OUTPUT.V_CUSTOMER c
left outer JOIN JIVRO_TEST.JIVRO_OUTPUT.V_SALEPASSES sp
    ON c.OBJID = sp.CUSTOMER
    AND c.record_source = sp.record_source
    and c.EFFECTIVE_TO_DATE is null
    and sp.EFFECTIVE_TO_DATE is null
                    
INNER JOIN
	(
	SELECT customer
	     , saleid
         , logdate
         , record_source
    FROM RankedSales
    WHERE rn = 1
    ) CTE
    
ON c.objid = CTE.customer
and sp.record_source = CTE.record_source
AND sp.saleid = CTE.saleid
                    
left outer JOIN JIVRO_TEST.JIVRO_OUTPUT.V_SITE s
	on sp.site = s.id
    AND sp.record_source = s.record_source
                    
left outer JOIN JIVRO_TEST.JIVRO_OUTPUT.v_site FirstSaleSite
    ON FirstSaleSite.id = sp.firstsalesite
    AND FirstSaleSite.record_source = sp.record_source
   
left outer JOIN JIVRO_TEST.JIVRO_OUTPUT.V_SALEITEMS sit
    on sit.SITE = s.ID
    and sit.SALEID= CTE.saleid
    AND cte.record_source  = sit.record_source

left outer JOIN JIVRO_TEST.JIVRO_OUTPUT.V_ITEM it
    on it.OBJID = sit.ITEM
    AND it.record_source = sit.record_source

left outer join  JIVRO_TEST.JIVRO_OUTPUT.V_PLANTYPE pt
    on  pt.objid = it.plantype
    and pt.record_source = it.record_source 

Where 1=1 
--and c.LASTNAME <> 'JIVRO'
and s.EFFECTIVE_TO_DATE is NULL
and FirstSaleSite.EFFECTIVE_TO_DATE is NULL
and sit.EFFECTIVE_TO_DATE is NULL
and it.EFFECTIVE_TO_DATE is NULL
and pt.EFFECTIVE_TO_DATE is null
order by 13