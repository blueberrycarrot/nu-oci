use common.nu *

export def oci-post [
  url: string
] {
  let content = $in
  oci-request 'post' $url --content $content
}

export def oci-get [
  url: string
] {
  oci-request 'get' $url
}

def oci-put [] {}
def oci-delete [] {}
def oci-storage-put [] {}

def oci-request [
  method: string
  url: string
  --content: any = null
] {
  let is_postput = $method =~ '^(post|put)$'

  let content_string = if ($content | non-empty) {
    $content | to json #| str replace "\n" '' --all
  } | default ''

  let oci_headers = do {
    let oci_config = open 'oci-rest-api.toml'
    let parsedurl = $url | parse -r '^[^:]+://(?<host>[^/]+)(?<requesttarget>/.+)$' | first
    let date = date now | date to-timezone 'GMT' | format date '%a, %d %b %Y %T' | ($in + ' GMT')
    let key_id = $'($oci_config.tenancy)/($oci_config.user)/($oci_config.fingerprint)'
    let algorithm = 'rsa-sha256'

    let unsigned_headers = {
      'date': $date
      'host': $parsedurl.host
    } | merge (
      if $is_postput {
        {
          'content-type': 'application/json'
          'content-length': ($content_string | str length | into string)
          'x-content-sha256': ($content_string | openssl dgst -sha256 -binary | encode base64)
        }
      } | default {}
    )

    let signing_string_components = $unsigned_headers | merge {
      '(request-target)': $'($method | str downcase) ($parsedurl.requesttarget)'
    }
    let signing_string = $signing_string_components
      | items { |k,v| $'($k): ($v)' }
      | str join "\n"

    let signature = $signing_string | openssl dgst -sha256 -sign $oci_config.key_file | encode base64
    let auth_params = {
      'version': '1'
      'keyId': $key_id
      'algorithm': $algorithm
      'headers': ($signing_string_components | items { |key| $key })
      'signature': $signature
    }

    let auth_header = $'Signature ($auth_params | oci-auth-params-to-string)'
    let date_header = $date
    let all_headers = $unsigned_headers | merge {
      'authorization': $auth_header
    }

    $all_headers
  }

  let nu_headers = $oci_headers | items { |k,v| [$k $v] } | flatten

  if ($method == 'get') {
    http get -fe -H $nu_headers $url
  } else if ($method == 'post') {
    #let curl_headers = $oci_headers | items { |k,v| ['-H' $'($k): ($v)'] } | flatten | xray "curl_headers"
    # `--data-binary` is needed for Curl to properly calculate content-length
    #let curl_args = $curl_headers | append [-v -X POST --data-binary @- $url]
    #$curl_args | xray "curl args"
    #$content_string | ^curl ...$curl_args
    http post -fe $url -H $nu_headers $content_string
  } else {
    error make -u { msg: $'Unhandled http method `($method)`' }
  }
}

def oci-auth-params-to-string [] {
  items { |key, value|
    if ($value | describe) =~ '^list' {
      $'($key)="($value | str join ` `)"'
    } else {
      $'($key)="($value)"'
    }
  } | str join ','
}

def setup [
  --private-key-file = 'private_key.pem'
  --public-key-file = 'public_key.pem'
] {
  if ($private_key_file | path exists) {
    error make -u { msg: $'Private key file `($private_key_file)` already exists' }
  }
  if ($public_key_file | path exists) {
    error make -u { msg: $'Public key file `($public_key_file)` already exists' }
  }
  openssl genpkey -algorithm RSA -out $private_key_file -pkeyopt rsa_keygen_bits:2048
  openssl rsa -pubout -in $private_key_file -out $public_key_file
}

def --wrapped openssl [...args] {
  ^openssl/x64/bin/openssl.exe ...$args
}
