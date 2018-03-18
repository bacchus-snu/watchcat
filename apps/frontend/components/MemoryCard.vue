<template>
  <el-card>
    <h2 slot="header">Memory</h2>
    <div class="card-body">
      <template v-if="memory.ok">
        <el-progress type="circle" :percentage="memory.usage.toFixed(2)"/>
        <div class="line"/>
        <h3>Swap</h3>
        <el-progress type="circle" :percentage="memory.swapUsage.toFixed(2)"/>
      </template>
      <template v-else>
        <div/>
      </template>
    </div>
  </el-card>
</template>

<script>
export default {
  props: ["metric"],

  computed: {
    memory () {
      let memoryInfo = this.metric
      let ret = {}
      ret.ok = memoryInfo.status === "ok"
      if (ret.ok) {
        let data = memoryInfo.data

        ret.usage = (data.total - data.available) / data.total * 100
        ret.swapUsage = data.swap_total ? (data.swap_total - data.swap_free) / data.swap_total * 100 : 0
      } else {
        ret.reason = memoryInfo.reason
      }

      return ret
    }
  }
}
</script>
