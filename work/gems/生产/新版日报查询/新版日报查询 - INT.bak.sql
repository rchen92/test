--query �û���½���ʰ�(sgeint)
--query �û���½���ʰ�(sgeint)
--15.���� ���ձ�����
select sum(num) "���ʰ嵱�ձ�����"
  from (select count(*) num
          from gesssigex.entr_flow
        union all
        select count(*) num
          from gesssigex.his_entr_flow t
         where t.exch_date = (select to_char(sysdate, 'yyyymmdd') from dual));

--16.���� ���ճɽ�����
select sum(num) "���ʰ嵱�ճɽ�����"
  from (select count(*) num
          from gesssigex.busi_back_flow
        union all
        select count(*) num
          from gesssigex.his_m_match_flow t
         where t.exch_date = (select to_char(sysdate, 'yyyymmdd') from dual));

