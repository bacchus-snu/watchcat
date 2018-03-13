<template>
  <div>
    <el-col :span="24">
      <div>Name: {{ machine.name }}</div>
      <div>Host: {{ machine.host }}</div>
    </el-col>
    <template v-if="metric.status === 'ok'">
      <el-col :span="6">
        <cpu-card :metric="metric.data.cpu"/>
      </el-col>
    </template>
    <template v-else>
      <p>Metric is not available</p>
    </template>
  </div>
</template>

<script>
import CpuCard from '~/components/CpuCard.vue'

export default {
  data () {
    return {
      machine: null,
      metric: null
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
  },

  components: {
    CpuCard
  }
}
</script>
