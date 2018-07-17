<template>
  <el-card>
    <h2 slot="header">Network</h2>
    <div class="card-body">
      <template v-if="network.ok">
        <ul class="progress-bars">
          <li class="iface" v-for="iface in network.interfaces" :key="iface.name">
            <label>{{ iface.name }}</label>
            <ul>
              <li>
                <i class="el-icon-upload2"/>Tx: {{ iface.tx }}
              </li>
              <li>
                <i class="el-icon-download"/>Rx: {{ iface.rx }}
              </li>
            </ul>
          </li>
        </ul>
      </template>
    </div>
  </el-card>
</template>

<script>
function fileSize(byte) {
  var i = byte < 1 ? 0 : Math.floor( Math.log(byte) / Math.log(1024) );
  return ( byte / Math.pow(1024, i) ).toFixed(2) * 1 + ' ' + ['B', 'KB', 'MB', 'GB', 'TB'][i];
};

export default {
  props: ['metric'],

  computed: {
    network() {
      let networkInfo = this.metric
      let ret = {}
      ret.ok = networkInfo.status === 'ok'
      ret.interfaces = networkInfo.data.filter(d => d.name !== 'lo').map(d => {
        return {
          name: d.name,
          tx: fileSize(d.tx_speed * 1000) + '/s',
          rx: fileSize(d.rx_speed * 1000) + '/s'
        }
      })
      return ret
    }
  }
}
</script>
