--query �û���½���ʰ�(sgeint)
--query �û���½���ʰ�(sgeint)
--15.���� ���ձ�����
SELECT COUNT(*) "int����"
  FROM (SELECT F_SEAT_ID,F_LOCAL_ORDER_NO 
          FROM ITL_USER.T_ITL_ORDER
        UNION 
        SELECT F_SEAT_ID,F_LOCAL_ORDER_NO 
          FROM ITL_USER.T_IHIS_ORDER T
         WHERE T.F_TRADE_DATE =
               (SELECT TO_CHAR(sysdate-5, 'YYYYMMDD') FROM DUAL));

--16.���е��ճɽ�����

SELECT COUNT(*) "int���ճɽ�����"
  FROM (SELECT F_MATCH_NO,F_ORDER_NO NUM
          FROM ITL_USER.T_ITL_MATCH_FLOW
        UNION 
        SELECT F_MATCH_NO,F_ORDER_NO NUM
          FROM ITL_USER.T_IHIS_CLN_MATCH_FLOW T
         WHERE T.F_MATCH_DATE =
               (SELECT TO_CHAR(sysdate-5, 'YYYYMMDD') FROM DUAL));

