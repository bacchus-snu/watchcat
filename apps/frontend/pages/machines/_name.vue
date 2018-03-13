<template>
  <div>
    <el-col :span="24">
      <div>Name: {{ machine.name }}</div>
      <div>Host: {{ machine.host }}</div>
    </el-col>
    <template v-if="metric.status === 'ok'">
      <el-col :span="8">
        <el-card>
          <h2 slot="header">CPU</h2>
          <div id="cpu-body">
            <template v-if="cpu.ok">
              <el-progress type="circle" :percentage="cpu.total.toFixed(2)"></el-progress>
              <ul>
                <li v-for="core in cpu.cores" :key="core.name">
                  <label>{{ core.name }}</label>
                  <el-progress :percentage="core.usage.toFixed(2)"/>
                </li>
              </ul>
            </template>
            <template v-else>
              <p>{{ cpu.reason }}</p>
            </template>
          </div>
        </el-card>
      </el-col>
    </template>
    <template v-else>
      <div></div>
    </template>
  </div>
</template>

<script>
export default {
  data () {
    return {
      machine: null,
      metric: null
    }
  },

  computed: {
    cpu () {
      if (this.metric.status == "error") {
        return {}
      }
      let cpuInfo = this.metric.data.cpu
      let ret = {}
      ret.ok = cpuInfo.status === "ok"
      if (ret.ok) {
        ret.total = cpuInfo.data[0].usage
        ret.cores = cpuInfo.data.slice(1)
      } else {
        ret.reason = cpuInfo.reason
      }

      return ret
    }
  },

  async asyncData ({ app, params, error }) {
    try {
      let machine, metric
      [machine, metric] = await Promise.all([
        app.$axios.$get('/api/machines/' + params.name),
        app.$axios.$get('/api/metric/' + params.name)
      ])

      return {
        machine,
        metric
      }
    }
    catch (err) {
      error({ statusCode: 404, message: 'Machine not found'})
    }
  }
}
</script>
