set echo off 
set feedback off 
set colsep |  
set linesize 200
set pagesize 3
--set heading off
set term off 
set trimspool on 
set trimout on 

spool /tmp/zb_daily_data/daily_yesterday.data
select to_char(sysdate-1,'yyyy-mm-dd hh24:mi:ss') sysd from dual;

--1.主板当日报单笔数
select sum(num) "主板当日报单笔数" from (
select count(*) num from HIS.T_HIS_SPOT_ORDER t where F_APPLY_DATE=(select to_char(sysdate-1,'yyyymmdd') from dual) 
union all
select count(*) num from HIS.T_HIS_FWD_ORDER t where F_APPLY_DATE=(select to_char(sysdate-1,'yyyymmdd') from dual)
union all
select count(*) num from HIS.t_his_defer_order t where F_APPLY_DATE=(select to_char(sysdate-1,'yyyymmdd') from dual)
);

--2.主板当日成交笔数
select sum(num) "主板当日成交笔数" from (
select count(*) num from HIS.T_HIS_SPOT_MATCH t where t.f_match_date=(select to_char(sysdate-1,'yyyymmdd') from dual)
union all
select count(*) num from HIS.T_HIS_FWD_MATCH t where f_match_date=(select to_char(sysdate-1,'yyyymmdd') from dual) 
union all
select count(*) num from HIS.T_HIS_DEFER_MATCH t where f_match_date=(select to_char(sysdate-1,'yyyymmdd') from dual) 
union all
select count(*) num from HIS.T_HIS_LARGE_AMOUNT_MATCH t where f_match_date=(select to_char(sysdate-1,'yyyymmdd') from dual)
);


--3.当日清算量(yi) 转帐金额
select round(substr(sum(f_amount), 0, 30) / 10000000000, 2) || '(亿)' "当日清算量(亿)"
  from reg_user.t_reg_capital_trans_flow t
 where f_return_flag = '0000';
 
--4.划转笔数 F_PAY_FLAG 往来帐_收付标志
--select count(*) "划转笔数" from reg_user.t_reg_capital_trans_flow where f_return_flag ='0000';

select count(*) "划转笔数"
  from reg_user.T_REG_CURR_ACCT_DTL
 where F_PAY_FLAG in ('1','2')
   and f_account_date = (select to_char(sysdate-1, 'yyyymmdd') from dual);

--5.清算时间
select to_char(max(t.f_update_timestamp) - min(t.f_create_timestamp),
               'mi:ss') "清算时间"
  from cln_user.t_cln_run_log t
 where f_log_id =
       (select max(f_log_id) from cln_user.t_cln_run_log where f_step = 20);
	

--11.询价当日报单
select  count(*) "询价当日报单" from otcport.t_otc_enquiry_price_mst t;

--12.即远掉成交单数--单边
--select count(*) "询价当日成交单数" from otcport.T_OTC_TICKET_PRICE t
--left join otcport.T_OTC_TICKET_PRICE_CHNG_RCRD rc on  t.f_ticket_id =rc.f_ticket_id and rc.f_oprt_type='P01'
--where to_char(rc.f_trade_date,'yyyymmdd')=(select to_char(sysdate-1,'yyyymmdd') from dual);
select a.jyd + b.lend + c.optn "询价当日成交单数" from (
select count(*) jyd from otcport.T_OTC_TICKET_PRICE t
left join otcport.T_OTC_TICKET_PRICE_CHNG_RCRD rc on  t.f_ticket_id =rc.f_ticket_id and rc.f_oprt_type='P01'
where to_char(rc.f_trade_date,'yyyymmdd')=(select to_char(sysdate-1,'yyyymmdd') from dual))a,
(select count(*) lend from otcport.t_otc_ticket_lend ld where ld.f_ticket_status='1'and  to_char(ld.f_trade_date,'yyyymmdd')=(select to_char(sysdate-1,'yyyymmdd') from dual))b,
(select count(*) optn from otcport.t_otc_ticket_optn ot where ot.f_ticket_status='1' and to_char(ot.f_trade_date,'yyyymmdd')=(select to_char(sysdate-1,'yyyymmdd') from dual))c;

spool off
