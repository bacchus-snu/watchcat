<template>
  <el-card>
    <h2 slot="header">CPU</h2>
    <div class="card-body">
      <template v-if="cpu.ok">
        <el-progress type="circle" :percentage="Number(cpu.total.toFixed(2))"/>
        <ul class="progress-bars">
          <li v-for="core in cpu.cores" :key="core.name">
            <label>{{ core.name }}</label>
            <el-progress :stroke-width=14 :text-inside=true :percentage="Number(core.usage.toFixed(2))"/>
          </li>
        </ul>
      </template>
      <template v-else>
        <p>{{ cpu.reason }}</p>
      </template>
    </div>
  </el-card>
</template>

<script>
export default {
  props: ["metric"],

  computed: {
    cpu () {
      let cpuInfo = this.metric
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
  }
}
</script>

<style>
ul.progress-bars {
  padding: 0px 0px 0px 20px
}
</style>
