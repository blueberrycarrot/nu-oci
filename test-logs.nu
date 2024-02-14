use common.nu *
use oci-rest-api.nu *

def main [] {
  let ingestion_host = 'https://ingestion.logging.eu-frankfurt-1.oci.oraclecloud.com'
  let log_id = 'ocid1.log.oc1.eu-frankfurt-1.amaaaaaad2zjmiaagyspo2rxlue5znkxylfte6463wnw6fa4ry6txx6dsrpa'
  'hello, world' | log-entry | oci-post ($ingestion_host + '/20200831/logs/' + $log_id + '/actions/push')
}

def log-entry [] {
  {
    logEntryBatches: [
      {
        defaultlogentrytime: (date now | format date '%+')
        entries: [
          {
            data: $in
            id: (random uuid)
          }
        ]
        source: 'test-script'
        type: 'test'
      }
    ]
    specversion: '1.0'
  }
}
