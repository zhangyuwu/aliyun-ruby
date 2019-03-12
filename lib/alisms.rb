# ============================================================================
# AliSMS for Ruby
#
# Copyright (c) zhangyuwu. All rights reserved.
# Licensed under the MIT License.
# ============================================================================

require 'securerandom'
require 'json'
require 'base64'
require 'openssl'
require 'cgi'
require 'logger'
require 'net/http'

# ------------------------------------------------------------------------
# class: AliSMS
# 阿里云短信接口
# 参考：
# 1. https://help.aliyun.com/document_detail/55284.html?spm=a2c4g.11186623.2.13.79f6452cUjgkyn
# 2. https://help.aliyun.com/document_detail/56189.html?spm=5176.doc55501.6.562.WCtBcB
# ------------------------------------------------------------------------

class AliSMS
    API_URL = 'http://dysmsapi.aliyuncs.com'
    
    attr_accessor :access_key_id
    attr_accessor :access_secret
    attr_accessor :template
    attr_accessor :sign_name
    
    def initialize(key, secret, template, sign_name, logger = nil)
        @access_key_id = key
        @access_secret = secret
        @template = template
        @sign_name = sign_name
        @logger = logger || Logger.new(STDERR)
    end
    
    # --------------------------------------------------
    # Funciton: send
    #   发送短信
    # 入参：
    #   phone_number:   手机号码，多个号码用逗号分隔
    #   param:          消息参数，Hash对象，内容必须匹配模板
    # 出参：
    #   RequestId:      请求ID
    #   Code:           状态码-返回OK代表请求成功,其他错误码详见错误码列表
    #                   https://error-center.aliyun.com/status/product/smsa
    #   Message:        状态码的描述
    #   BizId:          发送回执ID,可根据该ID查询具体的发送状态
    # --------------------------------------------------
    def send(phone_number, param)
        h = {
            'AccessKeyId'       => @access_key_id,
            'Timestamp'         => Time.now.gmtime.strftime('%FT%TZ'),  # 格式为：yyyy-MM-dd’T’HH:mm:ss’Z’；时区为：GMT
            'SignatureMethod'   => 'HMAC-SHA1',                         # 建议固定值：HMAC-SHA1
            'SignatureVersion'  => '1.0',                               # 建议固定值：1.0
            'SignatureNonce'    => SecureRandom.uuid,                   # 用于请求的防重放攻击，每次请求唯一
            'Format'            => 'JSON',                              # 没传默认为JSON，可选填值：XML
            'Action'            => 'SendSms',                           # API的命名，固定值，如发送短信API的值为：SendSms
            'Version'           => '2017-05-25',                        # API的版本，固定值，如短信API的值为：2017-05-25
            'RegionId'          => 'cn-hangzhou',                       # API支持的RegionID，如短信API的值为：cn-hangzhou
            'PhoneNumbers'      => phone_number,                        # 短信接收号码，支持以逗号分隔批量调用，上限为1000个手机号
            'SignName'          => sign_name,                           # 短信签名，必须在阿里云申请签名（个人用网站备案截图申请）
            'TemplateCode'      => template,                            # 短信模板ID，通过模板+参数发送，需经阿里云审核方可使用
            'TemplateParam'     => param.to_json                        # 短信模板变量替换JSON串（支持多个参数）
        }
        
        uri = create_uri(h)
        req = Net::HTTP::Get.new(uri)
        res = Net::HTTP.start(uri.hostname, uri.port) { |http|
            http.request(req)
        }        
        if res.is_a?(Net::HTTPOK)
            @logger.info "Send SMS OK."
            @logger.debug res.body
            return JSON.parse(res.body)
        else
            errmsg = "Failed to send SMS with URL: #{uri}"
            @logger.error errmsg
            @logger.debug res.body
            raise errmsg
        end
    end

    # --------------------------------------------------
    # Funciton: Query
    #   查询短信发送明细
    # 入参：
    #   phone_number:   接收短信手机号码
    #   send_date:      发送的日期
    #   biz_id:         回执ID（在send的返回参数中）
    # 出参：
    #   PhoneNum:       手机号码
    #   SendDate:       发送时间
    #   SendStatus:     发送状态 1：等待回执，2：发送失败，3：发送成功
    #   ErrCode:        运营商短信错误码
    #                   https://help.aliyun.com/document_detail/55323.html?spm=a2c4g.11186623.6.595.158cbf0btzQx9p
    #   TemplateCode:   所用短信模板
    #   Content:        短信内容
    #
    # e.g.
    #   {
    #     "TotalCount": 14, 
    #     "Code": "OK"
    #     "Message": "OK", 
    #     "RequestId": "EADC3A1E-91E3...", 
    #     "SmsSendDetailDTOs": {
    #         "SmsSendDetailDTO": [
    #             {
    #                 "SendDate": "2018-11-10 19:59:26", 
    #                 "SendStatus": 3, 
    #                 "ReceiveDate": "2018-11-10 19:59:35", 
    #                 "ErrCode": "DELIVRD", 
    #                 "TemplateCode": "SMS_150123456", 
    #                 "Content": "尊敬的用户...", 
    #                 "PhoneNum": "18012345678"
    #             }, 
    #             ...
    #         ]
    #     }, 
    #   }    
    # --------------------------------------------------
    def query(phone_number, send_date, biz_id = nil, page_size = 10, current_page = 1)
        h = {
            'AccessKeyId'       => @access_key_id,
            'Timestamp'         => Time.now.gmtime.strftime('%FT%TZ'),  # 格式为：yyyy-MM-dd’T’HH:mm:ss’Z’；时区为：GMT
            'SignatureMethod'   => 'HMAC-SHA1',                         # 建议固定值：HMAC-SHA1
            'SignatureVersion'  => '1.0',                               # 建议固定值：1.0
            'SignatureNonce'    => SecureRandom.uuid,                   # 用于请求的防重放攻击，每次请求唯一
            'Format'            => 'JSON',                              # 没传默认为JSON，可选填值：XML
            'Action'            => 'QuerySendDetails',                  # API的命名，固定值，如发送短信API的值为：SendSms
            'Version'           => '2017-05-25',                        # API的版本，固定值，如短信API的值为：2017-05-25
            'RegionId'          => 'cn-hangzhou',                       # API支持的RegionID，如短信API的值为：cn-hangzhou
            'PhoneNumber'       => phone_number,                        # 短信接收号码
            'BizId'             => biz_id,                              # 发送流水号,从调用发送接口返回值中获取
            'SendDate'          => send_date.strftime('%Y%m%d'),        # 短信发送日期格式yyyyMMdd,支持最近30天记录查询
            'PageSize'          => page_size,                           # 页大小Max=50
            'CurrentPage'       => current_page                         # 当前页码
        }
        
        uri = create_uri(h)
        req = Net::HTTP::Get.new(uri)
        res = Net::HTTP.start(uri.hostname, uri.port) { |http|
            http.request(req)
        }        
        if res.is_a?(Net::HTTPOK)
            @logger.info "Query SMS OK."
            @logger.debug res.body
            return JSON.parse(res.body)
        else
            errmsg = "Failed to send SMS with URL: #{uri}"
            @logger.error errmsg
            @logger.debug res.body
            raise errmsg
        end
    end
    
    # --------------------------------------------------
    # Funciton: encode
    # 对字符串进行编码
    # --------------------------------------------------
    def encode(str)
        s = URI.encode_www_form_component(str)
        map = { '+' => '%20', '*' => '%2A', '%7E' => '~' }
        map.each { |k,v| s = s.gsub(k, v) }
        return s
    end
    
    # --------------------------------------------------
    # Funciton: create_sign
    # 创建签名
    # --------------------------------------------------
    def create_sign(key, str_to_sign)
        sign = OpenSSL::HMAC.digest('sha1', key, str_to_sign)
        return Base64.encode64(sign).strip
    end
    
    # --------------------------------------------------
    # Funciton: create_uri
    # 根据传入对象创建待请求的URI
    # --------------------------------------------------
    def create_uri(hash)
        str1 = hash.keys.sort.map { |k| "#{encode(k)}=#{encode(hash[k])}" }.join('&')
        str2 = [ 'GET', '/', str1 ].map { |s| encode(s) }.join('&')
        sign = create_sign(access_secret + '&', str2)
        return URI("#{API_URL}/?Signature=#{encode(sign)}&#{str1}")
    end
end
