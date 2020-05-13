--query 用户登陆后线库(sgehis)
--15.盘中 当日报单数
SELECT COUNT(*) "国际板当日报单数"
  FROM (SELECT F_SEAT_ID,F_LOCAL_ORDER_NO 
          FROM ITL_USER.T_ITL_ORDER
        UNION 
        SELECT F_SEAT_ID,F_LOCAL_ORDER_NO 
          FROM ITL_USER.T_IHIS_ORDER T
         WHERE T.F_TRADE_DATE =
               (SELECT TO_CHAR(SYSDATE, 'YYYYMMDD') FROM DUAL));

--16.盘中 当日成交单数
SELECT COUNT(*) "国际板当日成交单数"
  FROM (SELECT F_MATCH_NO,F_ORDER_NO NUM
          FROM ITL_USER.T_ITL_MATCH_FLOW
        UNION 
        SELECT F_MATCH_NO,F_ORDER_NO NUM
          FROM ITL_USER.T_IHIS_CLN_MATCH_FLOW T
         WHERE T.F_MATCH_DATE =
               (SELECT TO_CHAR(SYSDATE, 'YYYYMMDD') FROM DUAL));
