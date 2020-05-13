set echo off 
set feedback off 
set colsep |  
set linesize 200
set pagesize 3
--set heading off
set term off 
set trimspool on 
set trimout on 

spool /tmp/zb_daily_data/daily.data
select to_char(sysdate,'yyyy-mm-dd hh24:mi:ss') sysd from dual;

--1.主板当日报单笔数
select sum(num) "主板当日报单笔数" from (
select count(*) num from HIS.T_HIS_SPOT_ORDER t where F_APPLY_DATE=(select to_char(sysdate,'yyyymmdd') from dual) 
union all
select count(*) num from HIS.T_HIS_FWD_ORDER t where F_APPLY_DATE=(select to_char(sysdate,'yyyymmdd') from dual)
union all
select count(*) num from HIS.t_his_defer_order t where F_APPLY_DATE=(select to_char(sysdate,'yyyymmdd') from dual)
);

--2.主板当日成交笔数
select sum(num) "主板当日成交笔数" from (
select count(*) num from HIS.T_HIS_SPOT_MATCH t where t.f_match_date=(select to_char(sysdate,'yyyymmdd') from dual)
union all
select count(*) num from HIS.T_HIS_FWD_MATCH t where f_match_date=(select to_char(sysdate,'yyyymmdd') from dual) 
union all
select count(*) num from HIS.T_HIS_DEFER_MATCH t where f_match_date=(select to_char(sysdate,'yyyymmdd') from dual) 
union all
select count(*) num from HIS.T_HIS_LARGE_AMOUNT_MATCH t where f_match_date=(select to_char(sysdate,'yyyymmdd') from dual)
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
   and f_account_date = (select to_char(sysdate, 'yyyymmdd') from dual);

--5.清算时间
select to_char(max(t.f_update_timestamp) - min(t.f_create_timestamp),
               'mi:ss') "清算时间"
  from cln_user.t_cln_run_log t
 where f_log_id =
       (select max(f_log_id) from cln_user.t_cln_run_log where f_step = 20);
	
--6.累计开户数
select count(*) "累计开户数"
   from reg_user.t_reg_client_seat ts, reg_user.t_reg_client tc
  where ts.f_client_id = tc.f_client_id
    and ts.f_destroy_flag = 1;

--7.当日开户数       当天开客户号，当天绑定席位    当天开客户号，以后绑定席位
select
       count(*) "当日开户数"
  From reg_user.t_reg_client_seat trc,
       reg_user.t_reg_client      tc
 where trc.f_destroy_flag='1'
   and trc.f_client_id = tc.f_client_id
   and trc.f_bind_date = (select to_char(sysdate,'yyyymmdd') from dual);

--8.当日销户数
select
        count(*) "当日销户数"
   From reg_user.t_reg_client_seat trc,
        reg_user.t_reg_client      tc
  where 
    trc.f_client_id = tc.f_client_id
    and trc.f_destroy_flag = '2'
    and trc.f_destroy_date = (select to_char(sysdate,'yyyymmdd') from dual);

select sum(num) "易金通当日报单笔shu"
  from (select count(*) num
          from HIS.T_HIS_SPOT_ORDER t
         where t.f_source_id = 'a'
           and F_APPLY_DATE =
               (select to_char(sysdate, 'yyyymmdd') from dual)
        union all
        select count(*) num
          from HIS.T_HIS_FWD_ORDER t
         where t.f_source_id = 'a'
           and F_APPLY_DATE =
               (select to_char(sysdate, 'yyyymmdd') from dual)
        union all
        select count(*) num
          from HIS.t_his_defer_order t
         where t.f_source_id = 'a'
           and F_APPLY_DATE =
               (select to_char(sysdate, 'yyyymmdd') from dual));

select sum(num) "易金通当日成交笔shu"
  from (select count(*) num
          from HIS.T_HIS_SPOT_MATCH a
          left join his.t_his_spot_order b
            on (a.f_order_no = b.f_order_no and
               a.f_match_date = b.f_apply_date)
         where b.f_source_id = 'a'
           and a.f_match_date =
               (select to_char(sysdate, 'yyyymmdd') from dual)
        union all
        select count(*) num
          from HIS.T_HIS_FWD_MATCH a
          left join his.t_his_fwd_order b
            on (a.f_order_no = b.f_order_no and
               a.f_match_date = b.f_apply_date)
         where b.f_source_id = 'a'
           and a.f_match_date =
               (select to_char(sysdate, 'yyyymmdd') from dual)
        union all
        select count(*) num
          from HIS.T_HIS_DEFER_MATCH a
          left join his.t_his_defer_order b
            on (a.f_order_no = b.f_order_no and
               a.f_match_date = b.f_apply_date)
         where b.f_source_id = 'a'
           and a.f_match_date =
               (select to_char(sysdate, 'yyyymmdd') from dual));

--11.询价当日报单
select  count(*) "询价当日报单" from otcport.t_otc_enquiry_price_mst t;

--12.即远掉成交单数--单边
--select count(*) "询价当日成交单数" from otcport.T_OTC_TICKET_PRICE t
--left join otcport.T_OTC_TICKET_PRICE_CHNG_RCRD rc on  t.f_ticket_id =rc.f_ticket_id and rc.f_oprt_type='P01'
--where to_char(rc.f_trade_date,'yyyymmdd')=(select to_char(sysdate,'yyyymmdd') from dual);
select a.jyd + b.lend + c.optn "询价当日成交单数" from (
select count(*) jyd from otcport.T_OTC_TICKET_PRICE t
left join otcport.T_OTC_TICKET_PRICE_CHNG_RCRD rc on  t.f_ticket_id =rc.f_ticket_id and rc.f_oprt_type='P01'
where to_char(rc.f_trade_date,'yyyymmdd')=(select to_char(sysdate,'yyyymmdd') from dual))a,
(select count(*) lend from otcport.t_otc_ticket_lend ld where ld.f_ticket_status='1'and  to_char(ld.f_trade_date,'yyyymmdd')=(select to_char(sysdate,'yyyymmdd') from dual))b,
(select count(*) optn from otcport.t_otc_ticket_optn ot where ot.f_ticket_status='1' and to_char(ot.f_trade_date,'yyyymmdd')=(select to_char(sysdate,'yyyymmdd') from dual))c;


--11.当日上海金报单 
select count(*) "上海金当日baodan" from bpt_user.t_bpt_order_flow  where f_inst_id='SHAU';

--12.当日上海金成交单 
select count(*) "上海金当日chengjiao" from bpt_user.t_bpt_match  where f_inst_id='SHAU';

--15.当日上海银报单 
select count(*) "上海银当日baodan" from bpt_user.t_bpt_order_flow where f_inst_id='SHAG';

--16.当日上海银成交单 
select count(*) "上海银当日chengjiao" from bpt_user.t_bpt_match where f_inst_id='SHAG';



spool off
