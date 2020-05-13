--query 用户登陆国际板(sgeint)
--query 用户登陆国际板(sgeint)
--15.盘中 当日报单数
select sum(num) "国际板当日报单数"
  from (select count(*) num
          from gesssigex.entr_flow
        union all
        select count(*) num
          from gesssigex.his_entr_flow t
         where t.exch_date = (select to_char(sysdate, 'yyyymmdd') from dual));

--16.盘中 当日成交单数
select sum(num) "国际板当日成交单数"
  from (select count(*) num
          from gesssigex.busi_back_flow
        union all
        select count(*) num
          from gesssigex.his_m_match_flow t
         where t.exch_date = (select to_char(sysdate, 'yyyymmdd') from dual));

