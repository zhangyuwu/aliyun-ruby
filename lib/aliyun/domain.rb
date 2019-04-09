# ============================================================================
# Aliyun Service for Ruby
#
# Copyright (c) zhangyuwu. All rights reserved.
# Licensed under the GPLv3 License.
# ============================================================================

require 'aliyun'

# ============================================================================
# class AliDomainService
# ============================================================================
class AliDomainService < AliyunService
    attr_reader :account_name
    
    # --------------------------------------------------
    # Funciton: initialize
    # --------------------------------------------------
    def initialize(access_key_id, access_secret, account_name = nil)
        super(access_key_id, access_secret)
        @api_url = 'http://domain.aliyuncs.com'
        @version = '2018-01-29'
        @account_name = account_name
    end
    
    # --------------------------------------------------
    # Funciton: default_profile_id
    # --------------------------------------------------
    def default_profile_id
        @profile_id = @profile_id || query_registrant_profiles['RegistrantProfiles']['RegistrantProfile'].first['RegistrantProfileId']
    end

    # --------------------------------------------------
    # Funciton: check_domain
    # 检查域名是否可以注册
    #
    # e.g.
    # {
    #   "DynamicCheck": false,
    #   "Avail": 0,
    #   "RequestId": "963BFBDB-A271-4903-AB58-B3EB7B14C7EA",
    #   "DomainName": "google.com",
    #   "Premium": false
    # }
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
    #
    # e.g.
    # {
    #   "Data": {
    #     "Domain": [
    #       {
    #         "RegistrationDateLong": 1553751185000,
    #         "InstanceId": "S20192F11M439850",
    #         "DomainStatus": "3",
    #         "ExpirationDateStatus": "1",
    #         "DomainAuditStatus": "SUCCEED",
    #         "ExpirationDateLong": 1585373585000,
    #         "Premium": false,
    #         "ProductId": "15201",
    #         "ExpirationDate": "2020-03-28 13:33:05",
    #         "RegistrantType": "1",
    #         "RegistrationDate": "2019-03-28 13:33:05",
    #         "DomainName": "abc.net",
    #         "DomainType": "gTLD",
    #         "ExpirationCurrDateDiff": 365
    #       },
    #       ...
    #     ]
    #   },
    #   "TotalItemNum": 3,
    #   "PageSize": 100,
    #   "CurrentPageNum": 1,
    #   "RequestId": "3FA2F7A3-20FB-48FB-946A-50733898796C",
    #   "PrePage": false,
    #   "TotalPageNum": 1,
    #   "NextPage": false
    # }
    # --------------------------------------------------
    def query_domain_list(page_num = 1, page_size = 100)
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
    #
    # e.g.
    # {
    #   "TotalItemNum": 1,
    #   "PageSize": 500,
    #   "CurrentPageNum": 1,
    #   "RequestId": "04CBCD9B-33C6-438D-BDFB-EE596050AE0E",
    #   "PrePage": false,
    #   "RegistrantProfiles": {
    #     "RegistrantProfile": [
    #       {
    #         "ZhCity": "",
    #         "ZhRegistrantOrganization": "Zhang Yuwu",
    #         "Telephone": "",
    #         "ZhProvince": "",
    #         "DefaultRegistrantProfile": false,
    #         "EmailVerificationStatus": 1,
    #         "UpdateTime": "2019-03-26 13:45:15",
    #         "RealNameStatus": "SUCCEED",
    #         "Country": "CN",
    #         "Province": "",
    #         "ZhRegistrantName": "Zhang Yuwu",
    #         "City": "",
    #         "TelArea": "86",
    #         "RegistrantProfileId": 12345678,
    #         "PostalCode": "",
    #         "RegistrantType": "1",
    #         "Email": "",
    #         "CreateTime": "2019-03-21 22:03:27",
    #         "Address": "",
    #         "RegistrantName": "Zhang Yuwu",
    #         "RegistrantOrganization": "Zhang Yuwu",
    #         "RegistrantProfileType": "common",
    #         "ZhAddress": ""
    #       }
    #     ]
    #   },
    #   "TotalPageNum": 1,
    #   "NextPage": false
    # }
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
    #
    # e.g.
    # {
    #   "TaskNo": "abdf6c13-1bfd-4079-8059-7d5d12b17a85",
    #   "RequestId": "45648D84-4EE3-47D0-987A-18DFB4EDD9FE"
    # }
    # --------------------------------------------------
    def create_order(domain_name, profile_id = nil, years = 1)
        param = {
            'Action'                => 'SaveSingleTaskForCreatingOrderActivate',
            'DomainName'            => domain_name,                         # 域名
            'SubscriptionDuration'  => years,                               # 购买周期，单位：年。默认为一年
            'RegistrantProfileId'   => profile_id || default_profile_id,    # 域名信息模板编号，推荐使用域名信息模板来进行域名注册
        }
        uri = create_uri(param.merge(base_param))
        return http_get(uri)
    end

    # --------------------------------------------------
    # Funciton: query_task_list
    # 分页查询自己账户下的域名任务列表
    #
    # e.g.
    # {
    #  "Data": {
    #     "TaskInfo": [
    #       {
    #         "Clientip": "47.1.2.3",
    #         "TaskNo": "ebf1f3e8-ca04-41c7-8fa6-6a8483cdee28",
    #         "CreateTime": "2019-03-26 13:46:03",
    #         "TaskStatus": "COMPLETE",
    #         "TaskNum": 3,
    #         "TaskTypeDescription": "Tech Contact Modification",
    #         "TaskStatusCode": 3,
    #         "TaskType": "UPDATE_TECH_CONTACT"
    #       },
    #       ...
    #     ]
    #   },
    #   "TotalItemNum": 2,
    #   "PageSize": 100,
    #   "CurrentPageNum": 1,
    #   "RequestId": "7CA91543-C044-4387-AD62-9DCB3065B5E8",
    #   "PrePage": false,
    #   "TotalPageNum": 1,
    #   "NextPage": false
    # }
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
    #
    # e.g.
    # {
    #   "Data": {
    #     "TaskDetail": [
    #       {
    #         "TryCount": 5,
    #         "TaskDetailNo": "d70845026faa4f7597bde86d75c809db",
    #         "TaskNo": "ebf1f3e8-ca04-41c7-8fa6-6a8483cdee28",
    #         "CreateTime": "2019-03-26 13:46:03",
    #         "InstanceId": "S20192714MI30441",
    #         "UpdateTime": "2019-03-26 13:46:24",
    #         "TaskStatus": "EXECUTE_FAILURE",
    #         "DomainName": "xxx.net",
    #         "TaskTypeDescription": "Tech Contact Modification",
    #         "TaskStatusCode": 3,
    #         "ErrorMsg": "When transferring domain names to Alibaba Cloud...",
    #         "TaskType": "UPDATE_TECH_CONTACT"
    #       },
    #       ...
    #     ]
    #   },
    #   "TotalItemNum": 3,
    #   "PageSize": 100,
    #   "CurrentPageNum": 1,
    #   "RequestId": "F26FD175-6730-4173-9CA0-CF0FD7C9C19A",
    #   "PrePage": false,
    #   "TotalPageNum": 1,
    #   "NextPage": false
    # }
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
