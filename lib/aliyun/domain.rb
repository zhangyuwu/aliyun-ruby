# ============================================================================
# Aliyun Service for Ruby
#
# Copyright (c) zhangyuwu. All rights reserved.
# Licensed under the GPLv3 License.
# ============================================================================

require 'aliyun'

class AliDomain < AliyunService
    # --------------------------------------------------
    # Funciton: initialize
    # --------------------------------------------------    
    def initialize(access_key_id, access_secret)
        super(access_key_id, access_secret)
        @api_url = 'http://domain.aliyuncs.com'
        @version = '2018-01-29'
    end
    
    # --------------------------------------------------
    # Funciton: check_domain
    # 检查域名是否可以注册
    # --------------------------------------------------
    def check_domain(domain_name)
        param = {
            'Action'                => 'CheckDomain',                       # 操作接口名，系统规定参数，取值：CheckDomain
            'DomainName'            => domain_name,                         # 域名名称
            'FeeCommand'            => 'create',                            # 操作命令，取值：create 新购；renew 续费；transfer 转移；restore 赎回。
            'FeeCurrency'           => 'CNY',                               # 货币类型，取值：CNY 人民币；USD 美元。
            'FeePeriod'             => 1,                                   # 购买周期，单位：年
        }
        uri = create_uri(param.merge(base_param))
        return http_get(uri)
    end
    
    # --------------------------------------------------
    # Funciton: query_domain_list
    # 查询域名列表
    # --------------------------------------------------
    def query_domain_list(page_num, page_size)
        param = {
            'Action'                => 'QueryDomainList',                   # 操作接口名，系统规定参数，取值：QueryDomainList
            'PageNum'               => page_num,                            # 分页页码
            'PageSize'              => page_size,                           # 分页大小
        }
        uri = create_uri(param.merge(base_param))
        return http_get(uri)
    end
    
    # --------------------------------------------------
    # Funciton: query_registrant_profiles
    # 查询信息模板
    # --------------------------------------------------
    def query_registrant_profiles
        param = {
            'Action'                => 'QueryRegistrantProfiles',           # 操作接口名，系统规定参数，取值：QueryRegistrantProfiles
        }
        uri = create_uri(param.merge(base_param))
        return http_get(uri)
    end
    
    # --------------------------------------------------
    # Funciton: create_order
    # 查询信息模板
    # --------------------------------------------------
    def create_order(domain_name, profile_id, years = 1)
        param = {
            'Action'                => 'SaveSingleTaskForCreatingOrderActivate',
            'DomainName'            => domain_name,                         # 域名
            'SubscriptionDuration'  => years,                               # 购买周期，单位：年。默认为一年
            'RegistrantProfileId'   => profile_id,                          # 域名信息模板编号，推荐使用域名信息模板来进行域名注册
        }
        uri = create_uri(param.merge(base_param))
        return http_get(uri)
    end
    
    # --------------------------------------------------
    # Funciton: query_task_list
    # 分页查询自己账户下的域名任务列表
    # --------------------------------------------------
    def query_task_list(page_num = 1, page_size = 100)
        param = {
            'Action'                => 'QueryTaskList',                     # 操作接口名，系统规定参数，取值：QueryTaskDetailList
            'PageNum'               => page_num,                            # 分页页码
            'PageSize'              => page_size,                           # 分页大小
        }
        uri = create_uri(param.merge(base_param))
        return http_get(uri)
    end

    # --------------------------------------------------
    # Funciton: query_task_detail
    # 分页查询指定域名任务的详情列表
    # --------------------------------------------------
    def query_task_detail(task_no, page_num = 1, page_size = 100)
        param = {
            'Action'                => 'QueryTaskDetailList',               # 操作接口名，系统规定参数，取值：QueryTaskDetailList
            'PageNum'               => page_num,                            # 分页页码
            'PageSize'              => page_size,                           # 分页大小
            'TaskNo'                => task_no,                             # 任务编号
        }
        uri = create_uri(param.merge(base_param))
        return http_get(uri)
    end
end
