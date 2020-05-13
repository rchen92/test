
--��ѯʹ��˵����
--��ѯ���1��14 ʹ��query �û���½���߿�(sgehis)�����в�ѯ
--��ѯ���15��16 �ǹ��ʰ���ز�ѯ��ʹ��query�û��ǹ��ʰ��(sgeint)�����в�ѯ

--query �û���½���߿�(sgehis)
--1.���嵱�ձ�������
select sum(num) "���嵱�ձ�������" from (
select count(*) num from HIS.T_HIS_SPOT_ORDER t where F_APPLY_DATE=(select to_char(sysdate,'yyyymmdd') from dual) 
union all
select count(*) num from HIS.T_HIS_FWD_ORDER t where F_APPLY_DATE=(select to_char(sysdate,'yyyymmdd') from dual)
union all
select count(*) num from HIS.t_his_defer_order t where F_APPLY_DATE=(select to_char(sysdate,'yyyymmdd') from dual)
);

--2.���嵱�ճɽ�����
select sum(num) "���嵱�ճɽ�����" from (
select count(*) num from HIS.T_HIS_SPOT_MATCH t where t.f_match_date=(select to_char(sysdate,'yyyymmdd') from dual)
union all
select count(*) num from HIS.T_HIS_FWD_MATCH t where f_match_date=(select to_char(sysdate,'yyyymmdd') from dual) 
union all
select count(*) num from HIS.T_HIS_DEFER_MATCH t where f_match_date=(select to_char(sysdate,'yyyymmdd') from dual) 
union all
select count(*) num from HIS.T_HIS_LARGE_AMOUNT_MATCH t where f_match_date=(select to_char(sysdate,'yyyymmdd') from dual)
);


--3.���������� ת�ʽ��
select round(substr(sum(f_amount), 0, 30) / 10000000000, 2) || '��' "�������������ڣ�"
  from reg_user.t_reg_capital_trans_flow t
 where f_return_flag = '0000';
 
--4.��ת���� F_PAY_FLAG ������_�ո���־
--select count(*) "��ת����" from reg_user.t_reg_capital_trans_flow where f_return_flag ='0000';

select count(*) "��ת����"
  from reg_user.T_REG_CURR_ACCT_DTL
 where F_PAY_FLAG in ('1','2')
   and f_account_date = (select to_char(sysdate, 'yyyymmdd') from dual);

--5.����ʱ��
select to_char(max(t.f_update_timestamp) - min(t.f_create_timestamp),
               'mi:ss') "����ʱ��"
  from cln_user.t_cln_run_log t
 where f_log_id =
       (select max(f_log_id) from cln_user.t_cln_run_log where f_step = 20);
	
--6.�ۼƿ�����
select count(*) "�ۼƿ�����"
   from reg_user.t_reg_client_seat ts, reg_user.t_reg_client tc
  where ts.f_client_id = tc.f_client_id
    and ts.f_destroy_flag = 1;

--7.���տ�����       ���쿪�ͻ��ţ������ϯλ    ���쿪�ͻ��ţ��Ժ��ϯλ
select
       count(*) "���տ�����"
  From reg_user.t_reg_client_seat trc,
       reg_user.t_reg_client      tc
 where trc.f_destroy_flag='1'
   and trc.f_client_id = tc.f_client_id
   and trc.f_bind_date = (select to_char(sysdate,'yyyymmdd') from dual);

--8.����������
select
        count(*) "����������"
   From reg_user.t_reg_client_seat trc,
        reg_user.t_reg_client      tc
  where 
    trc.f_client_id = tc.f_client_id
    and trc.f_destroy_flag = '2'
    and trc.f_destroy_date = (select to_char(sysdate,'yyyymmdd') from dual);

--9.�׽�ͨ���ձ�������
select sum(num) "�׽�ͨ���ձ�������"
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

--10.�׽�ͨ���ձ��ɽ�����
select sum(num) "�׽�ͨ���ճɽ�����"
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

--11.ѯ�۵��ձ���
select  count(*) "ѯ�۵��ձ���" from otcport.t_otc_enquiry_price_mst t;

--12.��Զ���ɽ�����--����
select count(*) "ѯ�۵��ճɽ�����" from otcport.T_OTC_TICKET_PRICE t
left join otcport.T_OTC_TICKET_PRICE_CHNG_RCRD rc on  t.f_ticket_id =rc.f_ticket_id and rc.f_oprt_type='P01'
where to_char(rc.f_trade_date,'yyyymmdd')=(select to_char(sysdate,'yyyymmdd') from dual);

--13.���ն��۱���
select count(*) "���۵��ձ���" from fpuser.t_fp_entr_flow;

select count(*) "dj���ձ���.offline" 
  from fpuser.t_fp_his_entr_flow t 
 where f_exch_date=(select to_char(sysdate-5, 'yyyymmdd') from dual);
 
--14.���տռ۳ɽ���
select count(*) "���۵��ճɽ�" from fpuser.t_fp_match_flow;

select count(*) "dj���ճɽ�.offline" 
  from fpuser.t_fp_his_match_flow  
 where f_exch_date=(select to_char(sysdate-5, 'yyyymmdd') from dual);










