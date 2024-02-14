use common.nu *
use oci-rest-api.nu *

def main [] {
  oci-get 'https://iaas.eu-frankfurt-1.oraclecloud.com/20160918/vcns?compartmentId=ocid1.compartment.oc1..aaaaaaaauni3xtlrglv5kdh4dgvhlnooslb6ezym3idkbi7d6bw5kbjr374a'
}
