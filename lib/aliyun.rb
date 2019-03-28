# ============================================================================
# Aliyun Service for Ruby
#
# Copyright (c) zhangyuwu. All rights reserved.
# Licensed under the GPLv3 License.
# ============================================================================

require 'securerandom'
require 'json'
require 'base64'
require 'openssl'
require 'cgi'
require 'logger'
require 'net/http'

class AliyunError < Exception
    attr_reader :detail
    
    def initialize(msg, detail)
        super(msg)
        @detail = detail
    end
end

class AliyunService
    attr_reader :api_url
    attr_reader :access_key_id
    attr_reader :access_secret
    attr_reader :version
    
    def initialize(access_key_id, access_secret)
        @access_key_id = access_key_id
        @access_secret = access_secret
        @logger = Logger.new(STDERR)
    end
    
    # --------------------------------------------------
    # Funciton: base_param
    # 公共参数
    # --------------------------------------------------
    def base_param
        h = {
            'AccessKeyId'           => access_key_id,
            'Timestamp'             => Time.now.gmtime.strftime('%FT%TZ'),  # 格式为：yyyy-MM-dd’T’HH:mm:ss’Z’；时区为：GMT
            'Format'                => 'JSON',                              # 返回值的类型，支持JSON与XML。默认为XML。
            'Version'               => version,                             # API版本号，为日期形式：YYYY-MM-DD
            'SignatureMethod'       => 'HMAC-SHA1',                         # 建议固定值：HMAC-SHA1
            'SignatureVersion'      => '1.0',                               # 建议固定值：1.0
            'SignatureNonce'        => SecureRandom.uuid,                   # 用于请求的防重放攻击，每次请求唯一
        }
    end
    
    # --------------------------------------------------
    # Funciton: http_get
    # --------------------------------------------------
    def http_get(uri)
        req = Net::HTTP::Get.new(uri)
        res = Net::HTTP.start(uri.hostname, uri.port) { |http|
            http.request(req)
        }        
        if res.is_a?(Net::HTTPOK)
            return JSON.parse(res.body)
        else
            errmsg = "Failed to request with URL: #{uri}"
            @logger.error errmsg
            @logger.debug res.body
            raise AliyunError.new(errmsg, res.body)
        end
    end

    # --------------------------------------------------
    # Funciton: create_uri
    # 根据传入对象创建待请求的URI
    # --------------------------------------------------
    def create_uri(hash)
        str1 = hash.keys.sort.map { |k| "#{encode(k)}=#{encode(hash[k])}" }.join('&')
        str2 = [ 'GET', '/', str1 ].map { |s| encode(s) }.join('&')
        sign = create_sign(access_secret + '&', str2)
        return URI("#{api_url}/?#{str1}&Signature=#{encode(sign)}")
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
end
