#!/usr/bin/python
#-*-coding:utf-8-*-

import sys, time
import os, logging

import string
import multiprocessing

__abs_file__ = os.path.abspath(__file__)
code_dir = os.path.dirname(os.path.dirname(__abs_file__))
sys.path.append(code_dir)

import flows

import lib

from lib.dbmapping import *

from lib.fdpool import FDPool

from lib.logger import *

from lib.tpl_util import *

from lib import util

from dbio import dbio

import datafile_conf

from config import ip_conf

import hashlib

template_dir = os.path.dirname(os.path.abspath(__file__))+"/template"
sys.path.append(template_dir)

def wrap_process(s, a, b):
    try:
        s.process(a, b)
        return 0
    except Exception, e:
        LOG_WARNING('Process[%s] got error:%s' % (b[0], str(e)))
        logging.error('Process[%s] got error:%s' % (b[0], str(e)))
        import traceback
        traceback.print_exc()
        raise e

class DZMain:

    def __init__(self, cur_date):
        #self._argv = argv
        self._cur_date      = cur_date
        self.output_path    = util.datafile_output_path() + '/'
        self._last_date     = None
        self._helper_data_cache = {}

        self.filetransfer   = ip_conf.ip_conf["filetransfer"]

        self.secret         = datafile_conf.secret
        self.sub_process_count  = datafile_conf.sub_process_count

    def get_settle_date(self):
        sql_sd = "select Max(F_SETTLE_DATE) from T_PAR_SETTLE_DATE where F_SETTLE_DATE < '%s'"%self._cur_date
        print sql_sd
        conn = dbio.get_cx_connection("par")
        cursor_sd = conn.cursor()
        cursor_sd.execute(sql_sd)
        sd =cursor_sd.fetchall();
        conn.close()
        return sd[0][0]

    def replace_vars(self, s, item):

        d = {
            'date' : self._cur_date,
            'date2' : self._cur_date[2:]
        }
        if item.has_key("F_SEAT_ID"):
            d["seatid"] = item["F_SEAT_ID"]
        if item.has_key("F_MEMBER_ID"):
            d["memberid"] = item["F_MEMBER_ID"]
        tpl = string.Template(s)
        return tpl.substitute(d)


    def init_template(self, tpl):
        # preprocess 'fields' config, if fmt='%...d' or '%...f' then Add RightAlign decorator
        elem = set(dir(tpl))
        if not 'seperator' in elem:
            tpl.seperator = '|'
        if not 'line_seperator' in elem:
            tpl.line_seperator = '\n'
        if not 'line_filter' in elem:
            tpl.line_filter = None
        if not 'process' in elem:
            tpl.process = None
        if not 'line_process' in elem:
            tpl.line_process = None
        if not 'final_process' in elem:
            tpl.final_process = None

    def load_helper_data_map(self, helper_data_name):
        logging.debug("to attach:%s"%helper_data_name)
        if helper_data_name not in self._helper_data_cache :
            logging.debug("to attach:%s first"%helper_data_name)
            self._helper_data_cache[helper_data_name] = shm_cache.attach(helper_data_name, "DF_")
        return self._helper_data_cache[helper_data_name]

    def load_helper_data_maps(self, helper_data_list):
        maps = {}
        for name in helper_data_list:
            maps[name]  = self.load_helper_data_map(name)
        return maps

    def process(self,  flow_name, flow_param):
        job = flow_param[0]
        logging.info('inside process param:%s'%job)

        f_out_pool = FDPool(output_prefix = self.output_path, mode = 'w')
        time_start = time.time()
        tpl = __import__(job)
        tpl.name        = job
        tpl._cur_date   = self._cur_date
        self.init_template(tpl)

        if not tpl.process is None:
            logging.info("run tpl process name:%s"%job)
            ret = tpl.process(self, tpl, flow_name, flow_param, f_out_pool)
            f_out_pool.clear()
            logging.info('inside process name:%s param:%s handled time cost:%d'%(job, str(flow_param), time.time() - time_start))
            return ret

        helper_data_maps = self.load_helper_data_maps(flow_param[2])
        
        f = util.datafile_open_cursor(self._cur_date, flow_param[1], tpl.line_filter)

        cnt = 0
        for item in f:
            line = None
            if not tpl.line_process is None:
                line = tpl.line_process(tpl, item, helper_data_maps, f_out_pool)
            else:
                line = make_line(tpl, item, helper_data_maps)

            if line is None:
                continue
            cnt += 1
            filename = self.replace_vars(flow_name, item)
            #logging.debug("filename:"+filename)

            f_out = f_out_pool.getfd(filename)
            f_out.write(line)
            f_out.write(tpl.line_seperator)

        if not tpl.final_process is None:
            logging.info("run tpl final_process name:%s"%job)
            tpl.final_process(self, tpl, flow_name, helper_data_maps, f_out_pool)
        f_out_pool.clear()
        f.close()
        logging.info('module %s processed. line handled:%d time cost: %d' % ( job, cnt, time.time() - time_start ) )
        return True

    def makedirs(self):
        logging.debug("to makedirs")
        par_seats   = self.load_helper_data_map("T_REG_SEAT")
        for key, item in par_seats.to_dict().items():
            seatid  = item["F_SEAT_ID"]
            membid  = item["F_MEMBER_ID"]
            f_dir =  "%s/%s/%s/%s"%(self.output_path, self._cur_date, seatid, self._cur_date)
            #logging.debug("mkdir: %s"%f_dir)
            if not os.path.isdir(f_dir):
                os.makedirs(f_dir)
        logging.debug("makedirs over")
        return True

    def check_otc_status(self):
        logging.debug("check_otc_status...")
        return True
        f = util.datafile_open_cursor(self._cur_date, "DF_T_OTC_BASE_MARKET_STATUS")
        ret = False
        for item in f:
            logging.debug("item: %s"%str(item))
            if item["F_MARKET_STATUS"] != '2':
                logging.error("Bad F_TRADE_DATE:%(F_MARKET_STATUS)s"%item)
                break
            ret = True
            break
        return ret

    def main(self):
        time_start= time.time()
        self._last_date = self.get_settle_date()
        cmd = "./main datafile/export_mp %s 0"%self._cur_date
        logging.debug("os system: %s"%cmd)
        if 0 != os.system(cmd):
            logging.error("cmd failed: %s"%cmd)
            return 1

        if not self.check_otc_status():
            logging.error("check_otc_status failed!")
            return 2

        self.makedirs()             #创建所有目录

        proc_pool = multiprocessing.Pool(processes=self.sub_process_count)

        result_list = []
        for r_name in flows.flows:
            job = flows.flows[r_name][0]
            #if len(sys.argv) > 2 and sys.argv[2]!= job:
            #    continue
            logging.info("apply_async %s"%job)
            rst = proc_pool.apply_async( wrap_process, (self, r_name, flows.flows[r_name]))
            result_list.append(rst)

        proc_pool.close()
        proc_pool.join()
        for rst in result_list:
            if not rst.successful():
                return -1
            r = rst.get()
            if r < 0:
                return r


        if not self.create_blank_files():   #为其他席位创建空文件
            return -2
        if not self.copy_common_files():    #拷贝公共文件
            return -3
        if not self.create_flag_files():    #为所有文件创建flag标志文件
            return -4
        if not self.scp_files():            #将所有文件打包传送至文件前置服务器
            logging.error("scp_files failed.")
            return -4
        time_cost = time.time() - time_start
        logging.debug("run success! time cost:%d seconds"%time_cost)
        print >> sys.stderr, "run success! time cost:%d seconds"%time_cost
        return 0

    def create_blank_files(self):
        logging.debug("to makedirs")
        par_seats   = self.load_helper_data_map("T_REG_SEAT")
        for key, item in par_seats.to_dict().items():
            for flow_name in flows.flows:
                filename    = "%s/%s"%(self.output_path, self.replace_vars(flow_name, item) )
                if os.path.isfile(filename):
                    continue
                file(filename, "w").close()
        logging.debug("to makedirs over")
        return True

    def copy_common_files(self):
        logging.debug("to copy_common_files")
        par_seats   = self.load_helper_data_map("T_REG_SEAT")
        for src, dest in flows.common_files.items():
            srcname    = "%s/%s"%(self.output_path, self.replace_vars(src, {}) )
            if not os.path.isfile(srcname):
                logging.error("file %s not exists!"%srcname)
                print >>sys.stderr, "file", srcname, "not exists"
                continue
            for key, item in par_seats.to_dict().items():
                destname    = "%s/%s"%(self.output_path, self.replace_vars(dest, item) )
                cmd = "cp %s %s"%(srcname, destname)
                if 0!= os.system(cmd):
                    logging.error("Exec Failed. %s"%cmd)
                    return False
        logging.debug("copy_common_files over")

        return True

    def create_flag_file(self, filename):

        def get_md5(fname):
            m = hashlib.md5()
            with open(fname, "rb") as fh:  
                chunk = fh.read(1024)  
                while chunk:
                    m.update(chunk)
                    chunk = fh.read(1024)  
            return m.hexdigest()

        def get_md5_with_secret(src_str, secret):
            m = hashlib.md5()
            m.update(src_str + secret)
            return m.hexdigest()


        def get_linelfnum(fname):
            cnt = 0
            with open(fname, "r") as fh:
                line = fh.readline()
                while line:
                    cnt += 1
                    line = fh.readline()
            return cnt

        raw_md5     = get_md5(filename)
        fstat       = os.stat(filename)

        f_info      = {}
        f_info["fname"]     = os.path.split(filename)[-1]
        f_info["md5_sum"]   = get_md5_with_secret(raw_md5, self.secret)
        #logging.debug("raw_md5: %s secret: %s result: %s"%(raw_md5, self.secret, f_info["md5_sum"]))
        f_info["size"]      = fstat.st_size
        f_info["ctime"]     = time.strftime("%H%M%S", time.localtime(fstat.st_ctime))
        f_info["cdate"]     = time.strftime("%Y%m%d", time.localtime(fstat.st_ctime))
        f_info["line_count"]= get_linelfnum(filename)
        f_info["reserved"]  = ""
        line = "%(fname)60s|%(size)16d|%(cdate)8s|%(ctime)6s|%(line_count)12d|%(md5_sum)64s|%(reserved)64s"%f_info
        flg_file_name = filename[:-3]+"flg"
        wf   = file(flg_file_name, "w")
        wf.write(line)
        wf.close()
        #logging.debug("flag file %s created."%flg_file_name)
        #logging.debug(line)
        return True

    def create_flag_files(self):
        logging.debug("to create_flag_files")
        par_seats   = self.load_helper_data_map("T_REG_SEAT")
        mid_path    = "${date}/${seatid}/${date}"
        for key, item in par_seats.to_dict().items():
            seat_path    = "%s%s"%(self.output_path, self.replace_vars(mid_path, item) )
            for fname in os.listdir(seat_path):
                filename = os.path.join(seat_path, fname)
                #logging.debug("create flag file: %s"%filename)
                if filename.endswith('flg'):
                    continue
                self.create_flag_file(filename)
        logging.debug("create_flag_files over")
        return True

    def scp_files(self):
        logging.debug("to scp_files")
        cmd = "cd %s && zip -r %s.zip %s > /dev/null "%(self.output_path, self._cur_date, self._cur_date)
        logging.debug("system cmd: %s"%cmd)
        if 0!=os.system(cmd):
            logging.error("SYSTEM ERROR: %s"%cmd)
            return False

        if len(sys.argv) <= 2:
            cmd = 'scp -o ConnectTimeout=10 -o BatchMode=yes -P %s -r %s/%s.zip %s@%s:~/ ' % (self.filetransfer["port"], self.output_path, self._cur_date, self.filetransfer["user"], self.filetransfer["host"])
            logging.debug("system cmd: %s"%cmd)
            if 0!=os.system(cmd):
                logging.error("SYSTEM ERROR: %s"%cmd)
                return False
            cmd = 'scp -o ConnectTimeout=10 -o BatchMode=yes -P %s -r %s/datafile/*.sh %s@%s:~/ ' % (self.filetransfer["port"], code_dir, self.filetransfer["user"], self.filetransfer["host"])
            logging.debug("system cmd: %s"%cmd)
            if 0!=os.system(cmd):
                logging.error("SYSTEM ERROR: %s"%cmd)
                return False
            cmd = 'ssh %s@%s "sh unzip.sh %s"'%( self.filetransfer["user"], self.filetransfer["host"], self._cur_date)
            logging.debug("system cmd: %s"%cmd)
            if 0!=os.system(cmd):
                logging.error("SYSTEM ERROR: %s"%cmd)
                return False
            cmd = 'scp -o ConnectTimeout=10 -o BatchMode=yes -P %s -r %s %s@%s:~/ ' % (self.filetransfer["port"], util.datafile_table_path(self._cur_date, "seat"), self.filetransfer["user"], self.filetransfer["host"])
            logging.debug("system cmd: %s"%cmd)
            if 0!=os.system(cmd):
                logging.error("SYSTEM ERROR: %s"%cmd)
                return False

        logging.debug("scp_files over")
        return True


if __name__ == '__main__':
    logging.basicConfig(level=logging.DEBUG,
            format='%(asctime)s %(filename)s[line:%(lineno)d] %(levelname)s %(message)s',
            datefmt='%Y-%m-%d %H:%M:%S',
            #stream=sys.stderr)
            stream=sys.stdout)

    if len(sys.argv) <= 1:
        print >> sys.stderr, 'usage: main [date]'
        logging.error("usage: %s [date]"%sys.argv[0])
        sys.exit(1)
    time_start = time.time()
    dz = DZMain(sys.argv[1])
    r = dz.main()
    if r != 0:
        sys.exit(1)
    time_cost = time.time() - time_start
    logging.debug("run success! time cost:%d seconds"%time_cost)
    logging.debug("All is Over")

